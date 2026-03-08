//
//  TDTaskTitleTextKitView.swift
//  TodoMacRepertorie
//
//  事件列表标题（第二栏）- TextKit 渲染版
//  目的：
//  - 保留系统原生的：行数限制 + 尾部省略号（...）
//  - 支持“#标签胶囊”：背景色 + 圆角 + 内边距（h=5, v=3），且可点击
//  - 支持“链接”：千草蓝 5 级，可点击打开
//

import SwiftUI
import AppKit

/// 使用 TextKit（NSTextView）渲染“标题富文本”
struct TDTaskTitleTextKitView: NSViewRepresentable {
    typealias NSViewType = NSView

    // MARK: - Inputs（由 SwiftUI 传入）
    let segments: [TDTaskTitleParser.Segment]
    let baseTextColor: NSColor
    let linkColor: NSColor
    let hashtagTint: NSColor
    let fontSize: CGFloat
    let lineLimit: Int
    /// 是否显示删除线（完成状态）
    let isStrikethrough: Bool
    /// 由 TextKit 计算出的实际高度（用于 SwiftUI frame 约束，保证稳定显示 2 行）
    @Binding var measuredHeight: CGFloat

    /// 点击标签回调（让 SwiftUI 决定弹窗/跳转）
    let onTapHashtag: (String) -> Void
    /// 点击链接回调（让 SwiftUI 决定 openURL）
    let onTapLink: (URL) -> Void
    /// 点击“普通文字区域”回调（用于把点击交还给整行，触发选中/打开详情）
    let onTapPlain: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTapHashtag: onTapHashtag, onTapLink: onTapLink, onTapPlain: onTapPlain)
    }

    func makeNSView(context: Context) -> NSView {
        // 说明：用自定义容器 view 计算“真实高度”，保证 lineLimit=2 时稳定显示 2 行
        // 否则 SwiftUI 可能按 1 行高度布局，导致你截图里“有时只显示 1 行”
        let container = TDTextKitSizingContainerView()

        // 1) 显式构建 TextKit 组件（TextStorage/LayoutManager/TextContainer）
        // 说明：直接用 NSTextView() 在 SwiftUI 里有概率出现 attachment 渲染异常（黄条+禁止符号）。
        // 这里用“完整 TextKit 链路”初始化，能显著提升稳定性。
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // 2) 使用自定义 NSTextView：
        // - 识别“点击了哪个标签胶囊/链接”
        // - 注册鼠标手型光标区域（hover 到标签/链接时显示手指）
        let textView = TDHashtagClickableTextView(frame: .zero, textContainer: textContainer)
        textView.isEditable = false
        // 说明：不需要选择文本；我们会自己处理 link/hashtag 点击，其它点击交还给父视图
        textView.isSelectable = false
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0

        // 3) 关键：
        // - 换行由段落样式控制（我们用 .byCharWrapping，适配中文）
        // - 截断与省略号由 TextContainer 控制（.byTruncatingTail + maximumNumberOfLines）
        textView.textContainer?.maximumNumberOfLines = max(1, lineLimit)
        textView.textContainer?.lineBreakMode = .byTruncatingTail

        // 4) 让宽度跟随 SwiftUI 容器变化
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = false
        // containerSize 会在容器里按“真实宽度”动态更新，这里先给一个兜底
        textView.textContainer?.containerSize = NSSize(width: 1000, height: CGFloat.greatestFiniteMagnitude)

        // 5) 链接默认样式（只变色，不强制下划线）
        // 关键：显式设置 font/baselineOffset，避免系统用默认 link 样式导致基线不对齐
        let linkFont = NSFont.systemFont(ofSize: fontSize)
        textView.linkTextAttributes = [
            .foregroundColor: linkColor,
            .underlineStyle: 0,
            .font: linkFont,
            .baselineOffset: 0
        ]

        // 6) 注入点击回调（标签/链接）
        textView.onTapHashtag = { key in
            context.coordinator.onTapHashtag(key)
        }
        textView.onTapLink = { url in
            context.coordinator.onTapLink(url)
        }
        textView.onTapPlain = {
            context.coordinator.onTapPlain()
        }

        // 7) 初次赋值文本
        textView.textStorage?.setAttributedString(
            buildAttributedString()
        )
        // 7.1) 初次测量高度（保证默认 2 行时不会被压成 1 行）
        container.updateMeasuredHeight(
            textView: textView,
            fontSize: fontSize,
            lineLimit: lineLimit,
            width: 0
        )
        DispatchQueue.main.async {
            self.measuredHeight = container.currentMeasuredHeight
        }

        container.install(textView: textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textView.topAnchor.constraint(equalTo: container.topAnchor),
            textView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        context.coordinator.textView = textView
        context.coordinator.sizingContainer = container
        container.onBoundsWidthDidChange = { [weak textView, weak container] newWidth in
            guard let textView, let container else { return }
            container.updateMeasuredHeight(
                textView: textView,
                fontSize: fontSize,
                lineLimit: lineLimit,
                width: newWidth
            )
            // 宽度变化后：更新手型命中逻辑
            textView.invalidateTracking()
            DispatchQueue.main.async {
                self.measuredHeight = container.currentMeasuredHeight
            }
        }
        // 初次计算高度
        container.updateMeasuredHeight(
            textView: textView,
            fontSize: fontSize,
            lineLimit: lineLimit,
            width: 0
        )
        DispatchQueue.main.async {
            self.measuredHeight = container.currentMeasuredHeight
        }
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onTapHashtag = onTapHashtag
        context.coordinator.onTapLink = onTapLink
        context.coordinator.onTapPlain = onTapPlain

        guard let textView = context.coordinator.textView,
              let container = context.coordinator.sizingContainer else { return }

        // 1) 行数设置变化：更新 TextContainer（保证与设置一致）
        textView.textContainer?.maximumNumberOfLines = max(1, lineLimit)
        textView.textContainer?.lineBreakMode = .byTruncatingTail

        // 2) 主题/颜色变化：更新链接样式
        let linkFont = NSFont.systemFont(ofSize: fontSize)
        textView.linkTextAttributes = [
            .foregroundColor: linkColor,
            .underlineStyle: 0,
            .font: linkFont,
            .baselineOffset: 0
        ]

        // 3) 内容变化：重建 attributed string
        let newAttr = buildAttributedString()
        if textView.attributedString() != newAttr {
            textView.textStorage?.setAttributedString(newAttr)
            // 内容变化后，重新计算高度（确保最多显示 lineLimit 行）
            container.updateMeasuredHeight(
                textView: textView,
                fontSize: fontSize,
                lineLimit: lineLimit,
                width: container.bounds.width
            )
            // 内容变化后，更新 hover 手型命中逻辑
            textView.invalidateTracking()
            DispatchQueue.main.async {
                self.measuredHeight = container.currentMeasuredHeight
            }
        }
    }

    // MARK: - 构建 NSAttributedString（按 segments 顺序）

    private func buildAttributedString() -> NSAttributedString {
        let result = NSMutableAttributedString()

        // 1) 统一基础样式：字体/文字颜色
        let baseFont = NSFont.systemFont(ofSize: fontSize)
        let paragraph = NSMutableParagraphStyle()
        // 说明：行高/对齐尽量对齐 SwiftUI Text 的默认表现
        // 关键：段落负责“怎么换行”，用按字符换行更贴近你截图的中文排版
        paragraph.lineBreakMode = .byCharWrapping
        paragraph.alignment = .left

        var baseAttrs: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: baseTextColor,
            .paragraphStyle: paragraph,
            .baselineOffset: 0
        ]
        if isStrikethrough {
            // 说明：SwiftUI 的 .strikethrough 对 NSViewRepresentable 不生效，所以要在 attributed string 里做
            baseAttrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            baseAttrs[.strikethroughColor] = baseTextColor
        }

        // 2) 逐段拼接：plain / link / hashtag(attachment)
        for seg in segments {
            switch seg {
            case .plain(let text):
                result.append(NSAttributedString(string: text, attributes: baseAttrs))

            case .link(let displayText, let url):
                var attrs = baseAttrs
                attrs[.foregroundColor] = linkColor
                attrs[.link] = url
                result.append(NSAttributedString(string: displayText, attributes: attrs))

            case .hashtag(let tagKey):
                // 2.1) 用 attachment 实现“胶囊”：用 NSImage 生成（避免出现黄条/占位符的渲染异常）
                let att = TDHashtagAttachment(tagKey: tagKey, tint: hashtagTint, lineFontSize: fontSize)
                result.append(NSAttributedString(attachment: att))
            }
        }

        return result
    }

    // MARK: - Coordinator（处理链接点击）

    final class Coordinator: NSObject, NSTextViewDelegate {
        weak var textView: TDHashtagClickableTextView?
        weak var sizingContainer: TDTextKitSizingContainerView?

        var onTapHashtag: (String) -> Void
        var onTapLink: (URL) -> Void
        var onTapPlain: () -> Void

        init(onTapHashtag: @escaping (String) -> Void, onTapLink: @escaping (URL) -> Void, onTapPlain: @escaping () -> Void) {
            self.onTapHashtag = onTapHashtag
            self.onTapLink = onTapLink
            self.onTapPlain = onTapPlain
        }

        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            // 说明：统一由 SwiftUI 的 openURL 处理（避免 NSTextView 默认行为不一致）
            if let url = link as? URL {
                onTapLink(url)
                return true
            }
            return false
        }
    }
}

// MARK: - SwiftUI 下的“自适应高度容器”（稳定 lineLimit 行数）

final class TDTextKitSizingContainerView: NSView {
    /// 当 bounds.width 变化时回调（用于重算高度）
    var onBoundsWidthDidChange: ((CGFloat) -> Void)?

    private var lastWidth: CGFloat = 0
    private var measuredHeight: CGFloat = 0
    var currentMeasuredHeight: CGFloat { measuredHeight }

    override var isFlipped: Bool { true }

    func install(textView: NSView) {
        addSubview(textView)
        // 让容器使用 intrinsic height
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    override func layout() {
        super.layout()
        let w = bounds.width
        if abs(w - lastWidth) > 0.5 {
            lastWidth = w
            onBoundsWidthDidChange?(w)
        }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: measuredHeight > 0 ? measuredHeight : NSView.noIntrinsicMetric)
    }

    /// 根据当前宽度计算“最多 lineLimit 行”的高度
    func updateMeasuredHeight(textView: NSTextView, fontSize: CGFloat, lineLimit: Int, width: CGFloat) {
        // 1) 只有拿到有效宽度才能正确排版；宽度为 0 时先用当前 bounds
        let w = width > 1 ? width : max(1, bounds.width)
        guard let tc = textView.textContainer, let lm = textView.layoutManager else { return }

        // 2) 强制 TextKit 按当前宽度重新排版
        tc.containerSize = NSSize(width: w, height: CGFloat.greatestFiniteMagnitude)
        lm.ensureLayout(for: tc)

        // 3) 计算高度：用 usedRect（已考虑 maximumNumberOfLines + truncation）
        let used = lm.usedRect(for: tc)
        let baseFont = NSFont.systemFont(ofSize: fontSize)
        let lineHeight = lm.defaultLineHeight(for: baseFont)
        let maxHeight = CGFloat(max(1, lineLimit)) * lineHeight

        // 4) 关键：至少给 1 行高度；最多给 lineLimit 行高度；中间用 TextKit 的 usedRect
        let h = ceil(min(maxHeight, max(lineHeight, used.height)))
        if abs(measuredHeight - h) > 0.5 {
            measuredHeight = max(ceil(lineHeight), h)
            invalidateIntrinsicContentSize()
        }
    }
}

// MARK: - 可点击标签的 NSTextView
// 说明：不能是 private，否则 Coordinator 的属性无法引用（访问级别不匹配）

final class TDHashtagClickableTextView: NSTextView {
    var onTapHashtag: ((String) -> Void)?
    var onTapLink: ((URL) -> Void)?
    var onTapPlain: (() -> Void)?

    // MARK: - 手型光标（稳定版）：用 trackingArea + cursorUpdate 实时命中判断

    private var tracking: NSTrackingArea?

    func invalidateTracking() {
        if let tracking {
            removeTrackingArea(tracking)
            self.tracking = nil
        }
        updateTrackingAreas()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking {
            removeTrackingArea(tracking)
        }
        let options: NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseMoved, .cursorUpdate]
        let ta = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(ta)
        tracking = ta
    }

    override func cursorUpdate(with event: NSEvent) {
        // 说明：鼠标放到“标签/链接”上显示手指；否则箭头
        if isPointingHand(at: event.locationInWindow) {
            NSCursor.pointingHand.set()
        } else {
            NSCursor.arrow.set()
        }
    }

    override func mouseMoved(with event: NSEvent) {
        // 说明：随着鼠标移动刷新 cursor（有些窗口 cursorUpdate 触发频率低）
        cursorUpdate(with: event)
    }

    private func isPointingHand(at windowPoint: NSPoint) -> Bool {
        let p = convert(windowPoint, from: nil)
        guard let lm = layoutManager, let tc = textContainer, let storage = textStorage else { return false }
        let origin = textContainerOrigin
        let local = CGPoint(x: p.x - origin.x, y: p.y - origin.y)
        let glyphIndex = lm.glyphIndex(for: local, in: tc)
        let charIndex = lm.characterIndexForGlyph(at: glyphIndex)
        if charIndex >= storage.length { return false }
        if storage.attribute(.attachment, at: charIndex, effectiveRange: nil) != nil { return true }
        if storage.attribute(.link, at: charIndex, effectiveRange: nil) != nil { return true }
        return false
    }

    override func mouseDown(with event: NSEvent) {
        // 1) 先把点击点转换到本 view 坐标
        let p = convert(event.locationInWindow, from: nil)
        guard let lm = layoutManager, let tc = textContainer else {
            super.mouseDown(with: event)
            return
        }

        // 2) 找到点击位置对应的 glyph/character
        let textContainerOrigin = self.textContainerOrigin
        let point = CGPoint(x: p.x - textContainerOrigin.x, y: p.y - textContainerOrigin.y)
        let glyphIndex = lm.glyphIndex(for: point, in: tc)
        let charIndex = lm.characterIndexForGlyph(at: glyphIndex)

        // 3) 如果点到标签胶囊（attachment），走标签点击
        if charIndex < (textStorage?.length ?? 0),
           let att = textStorage?.attribute(.attachment, at: charIndex, effectiveRange: nil) as? TDHashtagAttachment {
            onTapHashtag?(att.tagKey)
            return
        }

        // 4) 如果点到链接（.link attribute），走链接点击
        if charIndex < (textStorage?.length ?? 0),
           let link = textStorage?.attribute(.link, at: charIndex, effectiveRange: nil) as? URL {
            onTapLink?(link)
            return
        }

        // 5) 其它区域：把点击交还给“整行”（触发选中/打开第三列详情）
        onTapPlain?()
    }
}

// MARK: - 标签胶囊 Attachment（圆角 + 内边距）

private final class TDHashtagAttachment: NSTextAttachment {
    let tagKey: String
    let tint: NSColor
    let lineFontSize: CGFloat

    init(tagKey: String, tint: NSColor, lineFontSize: CGFloat) {
        self.tagKey = tagKey
        self.tint = tint
        self.lineFontSize = lineFontSize
        super.init(data: nil, ofType: nil)
        let img = Self.makePillImage(tagKey: tagKey, tint: tint)
        self.image = img
        // 关键：显式设置 attachmentCell，避免系统回退到“缺省占位（黄色+禁止符号）”
        self.attachmentCell = NSTextAttachmentCell(imageCell: img)
    }

    required init?(coder: NSCoder) {
        // 说明：正常不会走到这里（我们不是从 nib/storyboard 解码）
        // 但必须实现以满足父类协议
        self.tagKey = ""
        self.tint = .labelColor
        self.lineFontSize = 14
        super.init(coder: coder)
    }

    /// 关键：告诉 TextKit 这个 attachment 的真实尺寸（避免系统用整行 rect 来绘制）
    override func attachmentBounds(
        for textContainer: NSTextContainer?,
        proposedLineFragment lineFrag: CGRect,
        glyphPosition position: CGPoint,
        characterIndex charIndex: Int
    ) -> CGRect {
        let size = image?.size ?? CGSize(width: 0, height: 0)
        // 垂直居中：attachmentBounds 的 y 是“相对基线”的偏移，不是相对 lineFrag。
        // 这里按“行字体”的 ascender/descender 计算，使胶囊与同一行文字中心对齐。
        let lineFont = NSFont.systemFont(ofSize: lineFontSize)
        let y = ((lineFont.ascender + lineFont.descender) - size.height) / 2
        return CGRect(x: 0, y: y, width: size.width, height: size.height)
    }

    // MARK: - 生成胶囊图

    /// 按你的要求：h=5, v=3
    private static func makePillImage(tagKey: String, tint: NSColor) -> NSImage {
        let hp: CGFloat = 5
        let vp: CGFloat = 3
        let corner: CGFloat = 6
        let font = NSFont.systemFont(ofSize: 12, weight: .medium)

        let textSize = (tagKey as NSString).size(withAttributes: [.font: font])
        let size = NSSize(width: ceil(textSize.width + hp * 2), height: ceil(textSize.height + vp * 2))

        // 说明：不要用 lockFocus()，它在某些场景会生成“无有效位图表示”的 image，
        // NSTextAttachment 就会渲染成黄色占位符。这里改用 NSBitmapImageRep 更稳定。
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return NSImage(size: size)
        }

        rep.size = size
        let ctx = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        defer {
            NSGraphicsContext.restoreGraphicsState()
        }

        // 1) 背景：主题色 5 级 + 透明度
        let bg = tint.withAlphaComponent(0.14)
        bg.setFill()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: corner, yRadius: corner).fill()

        // 2) 文字：主题色 5 级
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: tint
        ]
        let x = (size.width - textSize.width) / 2
        let y = (size.height - textSize.height) / 2
        (tagKey as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: attrs)

        let img = NSImage(size: size)
        img.addRepresentation(rep)
        return img
    }
}

