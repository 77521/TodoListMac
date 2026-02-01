//
//  TDHashtagEditor.swift
//  TodoMacRepertorie
//
//  统一的 #标签输入框（macOS）：
//  - 自动换行，输入框高度随内容增高
//  - 输入 `#` 且本地有标签数据时，弹出联想弹窗（位置跟随光标）
//  - 输入 `#xxx `（后跟空格）时，高亮 `#xxx` 为主题色 5 级
//  - 占位符：开始编辑立即隐藏；编辑结束且内容为空时显示；中文拼音输入时也应隐藏
//  - 联想弹窗：默认选中第一个，上下键切换，Enter 确认插入；鼠标点击也可插入
//
//  Created by 孬孬 on 2026/2/1.
//

import SwiftUI

/// #标签输入框（SwiftUI 包装层）
struct TDHashtagEditor: View {
    @EnvironmentObject private var themeManager: TDThemeManager

    @Binding var text: String

    /// 占位符文案
    let placeholder: String
    
    /// 字体大小（输入内容与占位符共用）
    /// - 默认 13（你要求的尺寸）
    let fontSize: CGFloat

    /// Enter（不在弹窗选择时）触发的提交回调
    let onCommit: (() -> Void)?

    /// 主题色 5 级（用于标签高亮）
    private var tagColor: Color { themeManager.color(level: 5) }

    // MARK: - 编辑状态
    @State private var measuredHeight: CGFloat = 22
    @State private var isEditing: Bool = false
    @State private var hasMarkedText: Bool = false
    @State private var caretPoint: CGPoint = .zero
    @State private var caretScreenRect: CGRect = .zero
    @State private var caretLocation: Int = 0 // UTF-16 location
    @State private var cursorRequest: Int? = nil
    
    /// 当前一次聚焦编辑期间，是否曾经输入过真实内容
    /// - 用于实现：刚开始聚焦时 placeholder 隐藏；但“输入后又删空”时 placeholder 再出现
    @State private var didEditSinceFocus: Bool = false

    // MARK: - 标签数据与联想
    @State private var allTags: [TDTagModel] = []
    @State private var suggestions: [TDTagModel] = []
    @State private var showSuggestions: Bool = false
    @State private var selectedIndex: Int = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            TDHashtagTextView(
                text: $text,
                measuredHeight: $measuredHeight,
                isEditing: $isEditing,
                hasMarkedText: $hasMarkedText,
                caretPoint: $caretPoint,
                caretScreenRect: $caretScreenRect,
                caretLocation: $caretLocation,
                cursorLocationRequest: $cursorRequest,
                isSuggestionVisible: showSuggestions,
                suggestionCount: suggestions.count,
                selectedSuggestionIndex: $selectedIndex,
                onCommit: onCommit,
                onConfirmSuggestion: {
                    confirmCurrentSuggestion()
                },
                // 主题
                baseTextColor: themeManager.titleTextColor,
                hashtagColor: tagColor,
                fontSize: fontSize
            )
            .frame(height: measuredHeight)

            // 占位符：开始编辑立即消失；中文拼音输入(有 markedText)也隐藏
            if shouldShowPlaceholder {
                Text(placeholder)
                    .font(.system(size: fontSize))
                    .foregroundColor(themeManager.descriptionTextColor.opacity(0.9))
                    // 注意：placeholder 需要比插入点稍微靠右一点，
                    // 这样“删空后显示 placeholder”时，光标不会压在占位文字上面。
                    .padding(.leading, 14)
                    // 向上微调 1-2pt（更贴近系统输入框观感）
                    .padding(.top, 4)
                    .allowsHitTesting(false)
            }
        }
        // 弹窗：挂到 window 最外层（NSPanel），避免被裁剪/遮挡
        .background(
            TDHashtagSuggestionPanelPresenter(
                isPresented: $showSuggestions,
                anchorScreenRect: caretScreenRect,
                tags: suggestions.map { $0.display.isEmpty ? $0.key : $0.display },
                selectedIndex: $selectedIndex,
                onSelectIndex: { idx in
                    selectedIndex = idx
                    confirmCurrentSuggestion()
                },
                width: 180,
                maxVisibleRows: 10
            )
            .environmentObject(themeManager)
        )
        .onAppear {
            // 只要本地有标签数据才会弹联想
            allTags = TDTagManager.shared.fetchAllTags()
            recalcSuggestions()
        }
        .onChange(of: text) { _, _ in
            // 只要在本次聚焦期间出现过非空内容，就认为“编辑过”
            if isEditing && !hasMarkedText && !text.isEmpty {
                didEditSinceFocus = true
            }
            recalcSuggestions()
        }
        .onChange(of: caretLocation) { _, _ in
            recalcSuggestions()
        }
        .onChange(of: isEditing) { _, _ in
            // 编辑状态变化时也刷新（占位符与联想显示逻辑）
            if !isEditing {
                didEditSinceFocus = false
            }
            recalcSuggestions()
        }
    }

    private var shouldShowPlaceholder: Bool {
        // 规则（对齐你的要求）：
        // - 中文拼音组合态：隐藏
        // - 文本非空：隐藏
        // - 未聚焦：空文本时显示
        // - 聚焦中：
        //   - 刚开始聚焦且没输入过内容：隐藏（像 TextField 一样）
        //   - 输入过内容后又删空：显示
        if hasMarkedText { return false }
        if !text.isEmpty { return false }
        if !isEditing { return true }
        return didEditSinceFocus
    }

    /// 计算当前是否处于 `#标签` 输入态，以及联想列表
    private func recalcSuggestions() {
        // 没有标签数据就不显示弹窗
        guard !allTags.isEmpty else {
            showSuggestions = false
            suggestions = []
            selectedIndex = 0
            return
        }

        // 未开始编辑时不显示
        guard isEditing else {
            showSuggestions = false
            suggestions = []
            selectedIndex = 0
            return
        }
        
        // 中文拼音输入（IME 组合态）不弹联想，避免干扰输入
        if hasMarkedText {
            showSuggestions = false
            suggestions = []
            selectedIndex = 0
            return
        }

        // 基于 caretLocation（UTF-16）计算 # 上下文
        guard let ctx = TDHashtagSuggestionLogic.context(in: text, caretLocation: caretLocation) else {
            showSuggestions = false
            suggestions = []
            selectedIndex = 0
            return
        }

        let q = ctx.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty {
            suggestions = Array(allTags.prefix(30))
        } else {
            let lowered = q.lowercased()
            suggestions = allTags.filter { tag in
                let text = TDHashtagSuggestionLogic.normalizeTagText(tag.display.isEmpty ? tag.key : tag.display)
                return text.lowercased().contains(lowered)
            }
            suggestions = Array(suggestions.prefix(30))
        }

        // 没有匹配就不弹
        if suggestions.isEmpty {
            showSuggestions = false
            selectedIndex = 0
        } else {
            // 第一次显示时默认选中第一个
            if !showSuggestions { selectedIndex = 0 }
            showSuggestions = true
            // 修正越界
            selectedIndex = min(max(0, selectedIndex), suggestions.count - 1)
        }
    }

    /// 确认当前选中的联想项，插入到输入框并把光标放到标签后面
    private func confirmCurrentSuggestion() {
        guard showSuggestions, !suggestions.isEmpty else { return }
        let idx = min(max(0, selectedIndex), suggestions.count - 1)
        let raw = suggestions[idx].display.isEmpty ? suggestions[idx].key : suggestions[idx].display
        var tag = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if tag.isEmpty { return }
        if !tag.hasPrefix("#") { tag = "#\(tag)" }
        tag += " "

        guard let ctx = TDHashtagSuggestionLogic.context(in: text, caretLocation: caretLocation) else {
            showSuggestions = false
            return
        }

        // 用 NSString 做 UTF-16 range 替换，避免中文/emoji 下标错乱
        let ns = text as NSString
        let before = ns.substring(to: ctx.replaceRange.location)
        let after = ns.substring(from: ctx.replaceRange.location + ctx.replaceRange.length)
        let newText = before + tag + after
        text = newText

        // 设置光标到插入内容后面（UTF-16 location）
        cursorRequest = (before as NSString).length + (tag as NSString).length
        showSuggestions = false
    }
}

//// MARK: - 便捷初始化
//
//extension TDHashtagEditor {
//    init(
//        text: Binding<String>,
//        placeholder: String,
//        fontSize: CGFloat = 13,
//        onCommit: (() -> Void)? = nil
//    ) {
//        self._text = text
//        self.placeholder = placeholder
//        self.fontSize = fontSize
//        self.onCommit = onCommit
//    }
//}

// MARK: - 联想上下文解析（UTF-16 安全）

enum TDHashtagSuggestionLogic {
    struct Context {
        /// 需要替换的范围：从最后一个 `#` 到 caret 之间
        let replaceRange: NSRange
        /// `#` 后面的 query（去掉前导空格）
        let query: String
    }

    /// 根据当前 caretLocation（UTF-16）判断是否处于 `#标签` 编辑态
    static func context(in text: String, caretLocation: Int) -> Context? {
        let ns = text as NSString
        let len = ns.length
        let caret = max(0, min(caretLocation, len))
        let prefix = ns.substring(to: caret)

        // 找最后一个 '#'
        guard let hashRange = prefix.range(of: "#", options: .backwards) else { return nil }
        let hashIndex = prefix.distance(from: prefix.startIndex, to: hashRange.lowerBound)

        // hashIndex 是 Swift 字符偏移，但我们需要 UTF-16 location：
        // 用 NSString 再求一次更稳妥
        let hashUtf16Location = (prefix as NSString).range(of: "#", options: .backwards).location
        if hashUtf16Location == NSNotFound { return nil }

        let afterHash = ns.substring(with: NSRange(location: hashUtf16Location + 1, length: caret - (hashUtf16Location + 1)))

        // 换行直接结束
        if afterHash.contains("\n") { return nil }

        // 允许 # 后面先输入空格，但 query 自己会去掉前导空格
        let trimmedLeading = afterHash.drop { $0.isWhitespace }
        // 如果去掉前导空格后还包含空白，说明标签输入已结束（例如 #abc 继续写别的）
        if trimmedLeading.contains(where: { $0.isWhitespace }) { return nil }

        let query = String(trimmedLeading)
        let replace = NSRange(location: hashUtf16Location, length: caret - hashUtf16Location)
        return Context(replaceRange: replace, query: query)
    }

    /// 统一把标签文本标准化为“无#前缀”的可搜索文本
    static func normalizeTagText(_ tagText: String) -> String {
        let t = tagText.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("#") { return String(t.dropFirst()) }
        return t
    }
}

