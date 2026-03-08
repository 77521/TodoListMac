//
//  TDTaskTitleRichTextView.swift
//  TodoMacRepertorie
//
//  第二栏事件列表：标题富文本渲染（标签胶囊 + 链接高亮）
//  - 标签：主题色 5 级（背景/分割线/文字），可点击弹窗确认后进入“标签模式”
//  - 链接：千草蓝 5 级，无背景，可点击打开链接
//

import SwiftUI
import Foundation

/// 第二栏事件列表：标题富文本渲染组件
struct TDTaskTitleRichTextView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.openURL) private var openURL

    // MARK: - Inputs
    let rawTitle: String
    let baseTextColor: Color
    let fontSize: CGFloat
    let lineLimit: Int
    let isStrikethrough: Bool
    let opacity: Double
    /// 点击标题的“普通区域”（非标签/链接）时回调：用于触发行选中/打开详情
    let onTapPlain: () -> Void

    // MARK: - UI State
    @State private var isShowingTagAlert: Bool = false
    @State private var pendingTagKey: String = ""
    @State private var measuredHeight: CGFloat = 0

    var body: some View {
        // 目标：按「图1」逻辑显示（并且“显示不完时自动 ...”）
        // - 保持原文顺序：#标签/链接 出现在标题哪里，就在哪里变色/变胶囊
        // - 链接仅变色（千草蓝 5 级），不强制下划线
        // - 行数限制与省略号：交给系统 TextKit（NSTextView）处理，效果最稳定

        let segments = TDTaskTitleParser.parseSegments(from: rawTitle)

        // 关键：由 TextKit 承担排版（lineLimit + truncation + 省略号）
        TDTaskTitleTextKitView(
            segments: segments,
            baseTextColor: NSColor(baseTextColor),
            linkColor: NSColor(themeManager.fixedColor(themeId: "grass_blue", level: 5)),
            hashtagTint: NSColor(themeManager.primaryTintColor()),
            fontSize: fontSize,
            lineLimit: lineLimit,
            isStrikethrough: isStrikethrough,
            measuredHeight: $measuredHeight,
            onTapHashtag: { tagKey in
                // 点击标签：复用你现有弹窗逻辑
                pendingTagKey = tagKey
                isShowingTagAlert = true
            },
            onTapLink: { url in
                // 点击链接：复用 openURL（不影响列表选中）
                openURL(url)
            },
            onTapPlain: {
                // 点击普通文字区域：交还给整行（打开第三列详情）
                onTapPlain()
            }
        )
        // 关键：给 NSViewRepresentable 一个“确定的高度”，才能稳定显示 2 行（否则 SwiftUI 有时只给 1 行高度）
        .frame(height: measuredHeight > 0 ? measuredHeight : nil)
        .opacity(opacity)
        // 6) 弹窗：点击“查看”进入标签筛选（第二栏切到“标签模式”，侧栏也会同步选中）
        .alert("tag.alert.view_title".localized, isPresented: $isShowingTagAlert) {
            Button("common.view".localized) {
                // 6.1) 进入标签模式（复用侧栏已有的“从弹窗选择标签”逻辑，确保选中态同步）
                TDSliderBarViewModel.shared.selectTagFromSheet(tagKey: pendingTagKey)
                // 6.2) 清理临时状态，避免下次误用
                pendingTagKey = ""
            }
            Button("common.cancel".localized, role: .cancel) {
                // 6.3) 取消：只关闭弹窗，不改变当前筛选状态
                pendingTagKey = ""
            }
        } message: {
            Text("tag.alert.view_message".localized)
        }
    }

}

// MARK: - 解析器：提取标签 & 构建链接富文本

enum TDTaskTitleParser {
    enum Segment: Equatable {
        case plain(String)
        case hashtag(String)              // "#按时"
        case link(displayText: String, url: URL)
    }

    /// 把标题解析成片段数组（按原文顺序输出），用于图1样式的“就地渲染”
    static func parseSegments(from raw: String) -> [Segment] {
        // 1) 先检测链接（更可靠）：用 detector 找出 URL 的 range
        let linkMatches: [NSTextCheckingResult] = {
            guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return [] }
            let ns = raw as NSString
            return detector.matches(in: raw, options: [], range: NSRange(location: 0, length: ns.length))
        }()

        // 2) 再用正则检测标签（#xxx）
        let hashtagMatches: [NSTextCheckingResult] = {
            let pattern = #"#[^\s#]+"#
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
            let ns = raw as NSString
            return regex.matches(in: raw, options: [], range: NSRange(location: 0, length: ns.length))
        }()

        // 3) 合并为一个“高亮区间列表”，并按 location 排序（保证输出顺序正确）
        struct Mark {
            enum Kind { case link(URL), hashtag(String) }
            let range: NSRange
            let kind: Kind
        }

        var marks: [Mark] = []
        let ns = raw as NSString

        for m in linkMatches {
            guard let url = m.url else { continue }
            marks.append(Mark(range: m.range, kind: .link(url)))
        }
        for m in hashtagMatches {
            let tag = ns.substring(with: m.range)
            marks.append(Mark(range: m.range, kind: .hashtag(tag)))
        }

        marks.sort { a, b in
            if a.range.location != b.range.location { return a.range.location < b.range.location }
            // 同位置：优先链接（避免 “#” 被当作 URL 的一部分时打架）
            switch (a.kind, b.kind) {
            case (.link, .hashtag): return true
            case (.hashtag, .link): return false
            default: return a.range.length > b.range.length
            }
        }

        // 4) 逐段切片：非高亮部分拆成“可换行的小块”（按空白分割并保留空白）
        var segments: [Segment] = []
        var cursor = 0

        func appendPlainSlice(_ slice: String) {
            guard !slice.isEmpty else { return }
            // 让换行/空格也能自然参与布局：按空白分割，但把空白保留下来
            let parts = slice.split(separator: " ", omittingEmptySubsequences: false)
            for (idx, p) in parts.enumerated() {
                let s = String(p)
                if !s.isEmpty { segments.append(.plain(s)) }
                // 复原被 split 吃掉的空格（除了最后一个）
                if idx != parts.count - 1 { segments.append(.plain(" ")) }
            }
        }

        for mark in marks {
            // 4.1) 跳过与上一个 mark 重叠的部分（优先保留更靠前/更长的 mark）
            if mark.range.location < cursor { continue }

            // 4.2) 先加入 mark 前面的普通文本
            let prefixRange = NSRange(location: cursor, length: mark.range.location - cursor)
            if prefixRange.length > 0 {
                appendPlainSlice(ns.substring(with: prefixRange))
            }

            // 4.3) 再加入高亮片段
            switch mark.kind {
            case .hashtag(let tag):
                segments.append(.hashtag(tag))
            case .link(let url):
                let displayText = ns.substring(with: mark.range)
                segments.append(.link(displayText: displayText, url: url))
            }

            cursor = mark.range.location + mark.range.length
        }

        // 4.4) 最后尾巴
        if cursor < ns.length {
            appendPlainSlice(ns.substring(from: cursor))
        }

        // 5) 间距规则（按你的截图）：
        // - 链接后面最多 1 个空格
        // - 标签后面最多 1 个空格
        // - 连续空格整体压缩为 1 个空格（避免视觉空洞）
        return normalizeSpacing(segments)
    }

    /// 统一压缩空格间距（让视觉更贴近图示）
    private static func normalizeSpacing(_ input: [Segment]) -> [Segment] {
        // 1) 先把连续空格压成 1 个
        var collapsed: [Segment] = []
        collapsed.reserveCapacity(input.count)
        var pendingSpace = false

        for seg in input {
            switch seg {
            case .plain(let s) where s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty:
                // 只把纯空白（空格/换行）统一当成“间隔”，最终只保留一个空格
                pendingSpace = true
            default:
                if pendingSpace {
                    collapsed.append(.plain(" "))
                    pendingSpace = false
                }
                collapsed.append(seg)
            }
        }
        if pendingSpace {
            collapsed.append(.plain(" "))
        }

        // 2) 再确保 hashtag/link 前后“最多 1 个空格”，并且夹在文字中间时左右间距一致
        // 说明：
        // - 如果标签/链接前面紧挨着文字：补 1 个空格
        // - 如果标签/链接后面紧挨着文字：补 1 个空格
        // - 连续空格已在上一步被压缩为 1 个
        var out: [Segment] = []
        out.reserveCapacity(collapsed.count + 8)

        func isSingleSpace(_ seg: Segment) -> Bool {
            if case .plain(let s) = seg { return s == " " }
            return false
        }
        func isWhitespaceLike(_ seg: Segment) -> Bool {
            if case .plain(let s) = seg { return s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            return false
        }

        for i in collapsed.indices {
            let current = collapsed[i]

            // 2.1) 标签/链接如果夹在文字中间：确保前面有 1 个空格（与后面一致）
            let isSpecial: Bool
            switch current {
            case .hashtag, .link:
                isSpecial = true
            default:
                isSpecial = false
            }
            if isSpecial {
                if let prev = out.last, !isSingleSpace(prev) {
                    // 说明：如果前面已经是空格就不加；否则补 1 个空格，让左右间距一致
                    // 注意：这里不区分中文/英文标点，按你截图的“统一视觉间距”规则处理
                    out.append(.plain(" "))
                }
            }

            out.append(current)

            guard isSpecial else { continue }

            // 若已经是最后一个，就不补空格
            if i == collapsed.count - 1 { continue }

            let next = collapsed[i + 1]
            switch next {
            case .plain(let s) where s == " ":
                // 已经有 1 个空格，符合要求
                break
            case _ where isWhitespaceLike(next):
                // 理论上不会出现（已压缩），兜底不处理
                break
            default:
                // 后面直接是内容：补 1 个空格，让间距更舒适
                out.append(.plain(" "))
            }
        }

        // 2.2) 清理：移除开头/结尾的空格（避免标题一开始/结束时多出空白）
        while let first = out.first, isSingleSpace(first) {
            out.removeFirst()
        }
        while let last = out.last, isSingleSpace(last) {
            out.removeLast()
        }
        return out
    }
}

