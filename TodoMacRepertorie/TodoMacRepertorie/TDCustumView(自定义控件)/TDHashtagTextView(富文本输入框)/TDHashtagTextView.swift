//
//  TDHashtagTextView.swift
//  TodoMacRepertorie
//
//  NSTextView 封装（对齐你要求的“备忘录”体验）：
//  - 自动换行 + 自适应高度
//  - 提供 caret 位置，用于联想弹窗跟随
//  - 支持 IME（中文拼音）时的 placeholder 隐藏判断（hasMarkedText）
//  - 联想弹窗键盘控制：上下键切换、Enter 确认插入
//
//  Created by 孬孬 on 2026/2/1.
//

import SwiftUI
import AppKit
//import RichTextKit

/// 原生文本编辑器（macOS），用于实现稳定的输入体验
struct TDHashtagTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var measuredHeight: CGFloat

    @Binding var isEditing: Bool
    @Binding var hasMarkedText: Bool

    /// 光标位置（用于弹窗定位，坐标系：本 view 左上角为原点，y 向下）
    @Binding var caretPoint: CGPoint
    
    /// 光标的屏幕坐标 rect（用于把联想弹窗放到 window 最外层）
    @Binding var caretScreenRect: CGRect

    /// 光标位置（UTF-16 location）
    @Binding var caretLocation: Int

    /// 请求把光标移动到指定位置（UTF-16 location）
    @Binding var cursorLocationRequest: Int?

    /// 联想弹窗状态（用于拦截上下键/Enter）
    let isSuggestionVisible: Bool
    let suggestionCount: Int
    @Binding var selectedSuggestionIndex: Int

    /// 回车提交（弹窗未显示时）
    let onCommit: (() -> Void)?
    /// 回车确认联想（弹窗显示时）
    let onConfirmSuggestion: () -> Void

    /// 主题：普通文字颜色与标签高亮色
    let baseTextColor: Color
    let hashtagColor: Color
    
    /// 字体大小（输入内容与高亮共用）
    let fontSize: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSView {
        let container = NSView()

        // 使用原生 NSTextView（不依赖第三方 TextView 封装）
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
//        textView.configuration.isScrollingEnabled = false

        // 样式
        textView.font = NSFont.systemFont(ofSize: fontSize)
        textView.textColor = NSColor(baseTextColor)
        textView.textContainerInset = NSSize(width: 8, height: 4)
        textView.textContainer?.lineFragmentPadding = 0

        // 自动换行 + 自适应高度
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.maximumNumberOfLines = 0
        textView.textContainer?.lineBreakMode = .byWordWrapping
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )

        // 初始文本
        textView.string = text
        context.coordinator.textView = textView

        // 监听宽度/布局变化：用于切换任务时重新计算高度（避免“有时高度不对”）
        textView.postsFrameChangedNotifications = true
        context.coordinator.installFrameObserver(for: textView)

        container.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textView.topAnchor.constraint(equalTo: container.topAnchor),
            textView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // 初次计算
        context.coordinator.applyHighlighting()
        context.coordinator.updateMeasuredHeight()
        context.coordinator.updateCaretInfo()
        context.coordinator.updateMarkedTextState()

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.parent = self
        guard let textView = context.coordinator.textView else { return }

        // 关键：中文拼音等输入法组合态（markedText）期间，不能去强行同步 string/属性，
        // 否则会打断输入法的组合流程，出现“不断刷新、无法输入”的问题。
        if textView.hasMarkedText() {
            context.coordinator.updateMarkedTextState()
            context.coordinator.updateCaretInfo()
            context.coordinator.updateMeasuredHeight()
            return
        }

        // SwiftUI 外部写入时，同步到 NSTextView（尽量不打断输入）
        if textView.string != text {
            textView.string = text
            let len = (text as NSString).length
            // 规则：切换任务/外部刷新时，默认把光标放到文本末尾（更符合你第2条）
            // 如果后续有 cursorLocationRequest，会在下面覆盖到指定位置。
            let target = isEditing ? min(textView.selectedRange().location, len) : len
            textView.setSelectedRange(NSRange(location: target, length: 0))
            context.coordinator.applyHighlighting()
            context.coordinator.updateMeasuredHeight()
            context.coordinator.updateCaretInfo()
            context.coordinator.updateMarkedTextState()
        }

        // 请求移动光标（用于插入标签后把光标放到标签后）
        if let req = cursorLocationRequest {
            let len = (textView.string as NSString).length
            let safe = max(0, min(req, len))
            textView.setSelectedRange(NSRange(location: safe, length: 0))
            DispatchQueue.main.async { self.cursorLocationRequest = nil }
            context.coordinator.updateCaretInfo()
        }

        // 主题色可能变化：同步颜色
        if textView.textColor != NSColor(baseTextColor) {
            textView.textColor = NSColor(baseTextColor)
            context.coordinator.applyHighlighting()
        }
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TDHashtagTextView
        weak var textView: NSTextView?
        private var isApplyingAttributes: Bool = false
        private var frameObserver: NSObjectProtocol?

        init(parent: TDHashtagTextView) {
            self.parent = parent
        }
        
        deinit {
            if let obs = frameObserver {
                NotificationCenter.default.removeObserver(obs)
            }
        }

        /// 安装 frame 变化监听，解决“切换任务时高度偶发不对”
        func installFrameObserver(for view: NSTextView) {
            frameObserver = NotificationCenter.default.addObserver(
                forName: NSView.frameDidChangeNotification,
                object: view,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                self.updateMeasuredHeight()
                self.updateCaretInfo()
            }
        }

        func textDidBeginEditing(_ notification: Notification) {
            DispatchQueue.main.async {
                self.parent.isEditing = true
            }
            updateMarkedTextState()
            updateCaretInfo()
        }

        func textDidEndEditing(_ notification: Notification) {
            DispatchQueue.main.async {
                self.parent.isEditing = false
            }
            updateMarkedTextState()
        }

        func textDidChange(_ notification: Notification) {
            guard !isApplyingAttributes else { return }
            guard let tv = textView else { return }

            // IME 组合态：先更新标记状态，但不要改属性/不要回写 SwiftUI 文本（避免循环刷新）
            let composing = tv.hasMarkedText()
            if parent.hasMarkedText != composing {
                DispatchQueue.main.async { self.parent.hasMarkedText = composing }
            }

            let newValue = tv.string
            if !composing {
                // 只有在非组合态时才回写 SwiftUI 文本，并执行高亮
                if parent.text != newValue {
                    DispatchQueue.main.async {
                        self.parent.text = newValue
                    }
                }
                applyHighlighting()
            }

            // 高度/光标信息仍然可以更新（不影响输入法）
            updateMeasuredHeight()
            updateCaretInfo()
            updateMarkedTextState()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            updateCaretInfo()
            updateMarkedTextState()
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // 弹窗显示时：上下键切换、Enter 确认
            if parent.isSuggestionVisible, parent.suggestionCount > 0 {
                if commandSelector == #selector(NSResponder.moveDown(_:)) {
                    let next = min(parent.suggestionCount - 1, parent.selectedSuggestionIndex + 1)
                    DispatchQueue.main.async { self.parent.selectedSuggestionIndex = next }
                    return true
                }
                if commandSelector == #selector(NSResponder.moveUp(_:)) {
                    let prev = max(0, parent.selectedSuggestionIndex - 1)
                    DispatchQueue.main.async { self.parent.selectedSuggestionIndex = prev }
                    return true
                }
                if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                    parent.onConfirmSuggestion()
                    return true
                }
            }

            // 弹窗未显示：Enter 走提交（保持你原来“按回车创建事件/同步标题”的习惯）
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onCommit?()
                return true
            }

            return false
        }

        /// 高亮规则：`#标签` 后面紧跟空格/空白时，高亮 `#标签`（不包含空格）
        func applyHighlighting() {
            guard let tv = textView, let storage = tv.textStorage else { return }
            // IME 组合态不做高亮（避免干扰输入法标记文本）
            if tv.hasMarkedText() { return }
            let full = storage.string as NSString
            let fullRange = NSRange(location: 0, length: full.length)

            isApplyingAttributes = true
            defer { isApplyingAttributes = false }

            storage.beginEditing()
            storage.setAttributes(
                [
                    .font: NSFont.systemFont(ofSize: parent.fontSize),
                    .foregroundColor: NSColor(parent.baseTextColor)
                ],
                range: fullRange
            )

            // 只在后面有空白时才高亮（符合你第3条）
            let pattern = #"#[^\s]{1,20}(?=\s)"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: full as String, options: [], range: fullRange)
                for m in matches {
                    storage.addAttributes(
                        [.foregroundColor: NSColor(parent.hashtagColor)],
                        range: m.range
                    )
                }
            }

            storage.endEditing()
        }

        /// 更新高度（自动增高）
        func updateMeasuredHeight() {
            guard let tv = textView,
                  let layoutManager = tv.layoutManager,
                  let textContainer = tv.textContainer else { return }
            layoutManager.ensureLayout(for: textContainer)
            let used = layoutManager.usedRect(for: textContainer)
            let raw = ceil(used.height + tv.textContainerInset.height * 2)
            let final = max(22, raw)
            if abs(parent.measuredHeight - final) > 0.5 {
                DispatchQueue.main.async {
                    self.parent.measuredHeight = final
                }
            }
        }

        /// 更新光标位置（用于弹窗定位）
        func updateCaretInfo() {
            guard let tv = textView,
                  let layoutManager = tv.layoutManager,
                  let textContainer = tv.textContainer else { return }

            layoutManager.ensureLayout(for: textContainer)
            let len = (tv.string as NSString).length
            let caret = max(0, min(tv.selectedRange().location, len))

            // caretLocation（UTF-16）
            if parent.caretLocation != caret {
                DispatchQueue.main.async { self.parent.caretLocation = caret }
            }

            // caretPoint：使用插入点的 rect
            let origin = tv.textContainerOrigin
            if len == 0 {
                let p = CGPoint(x: origin.x, y: origin.y)
                DispatchQueue.main.async { self.parent.caretPoint = p }
                return
            }

            let charIndex = (caret == 0) ? 0 : min(caret - 1, max(0, len - 1))
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: charIndex)
            let rect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textContainer)

            // x：插入点（用 rect.maxX）；y：当前行底部（用 rect.maxY）
            let x = rect.maxX + origin.x
            let y = rect.maxY + origin.y

            let p = CGPoint(x: max(0, x), y: max(0, y))
            if abs(parent.caretPoint.x - p.x) > 0.5 || abs(parent.caretPoint.y - p.y) > 0.5 {
                DispatchQueue.main.async { self.parent.caretPoint = p }
            }

            // 同步屏幕坐标（用于 window 级弹窗）
            var actual = NSRange(location: 0, length: 0)
            let screenRect = tv.firstRect(forCharacterRange: NSRange(location: caret, length: 0), actualRange: &actual)
            if abs(parent.caretScreenRect.minX - screenRect.minX) > 0.5 ||
                abs(parent.caretScreenRect.minY - screenRect.minY) > 0.5 {
                DispatchQueue.main.async { self.parent.caretScreenRect = screenRect }
            }
        }

        func updateMarkedTextState() {
            guard let tv = textView else { return }
            let marked = tv.hasMarkedText()
            if parent.hasMarkedText != marked {
                DispatchQueue.main.async { self.parent.hasMarkedText = marked }
            }
        }
    }
}

