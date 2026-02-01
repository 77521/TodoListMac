//
//  TDPlainTextEditor.swift
//  TodoMacRepertorie
//
//  描述输入框（macOS）：
//  - 使用与标题相同的 NSTextView 方案（自动换行 + 自适应高度）
//  - 不需要 #标签联想弹窗，也不需要标签高亮
//  - placeholder 规则与标题保持一致（聚焦时隐藏、删空后再显示）
//
//  Created by Cursor on 2026/2/1.
//

import SwiftUI

/// 纯文本输入框（无 #标签联想/高亮），但体验与 `TDHashtagEditor` 一致
struct TDPlainTextEditor: View {
    @EnvironmentObject private var themeManager: TDThemeManager

    @Binding var text: String

    /// 占位符文案
    let placeholder: String

    /// 字体大小
    let fontSize: CGFloat

    /// Enter（不在联想弹窗选择时）触发的提交回调
    let onCommit: (() -> Void)?

    /// 编辑状态变化回调（用于失焦同步）
    let onEditingChanged: ((Bool) -> Void)?

    // MARK: - 编辑状态（复用 TDHashtagTextView 的稳定输入能力）
    @State private var measuredHeight: CGFloat = 22
    @State private var isEditing: Bool = false
    @State private var hasMarkedText: Bool = false
    @State private var caretPoint: CGPoint = .zero
    @State private var caretScreenRect: CGRect = .zero
    @State private var caretLocation: Int = 0
    @State private var cursorRequest: Int? = nil

    /// 本次聚焦期间是否输入过内容（用于 placeholder 逻辑）
    @State private var didEditSinceFocus: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 输入区域：使用与标题同款的 NSTextView 封装
            TDHashtagTextView(
                text: $text,
                measuredHeight: $measuredHeight,
                isEditing: $isEditing,
                hasMarkedText: $hasMarkedText,
                caretPoint: $caretPoint,
                caretScreenRect: $caretScreenRect,
                caretLocation: $caretLocation,
                cursorLocationRequest: $cursorRequest,
                // 关键：禁用联想弹窗相关参数
                isSuggestionVisible: false,
                suggestionCount: 0,
                selectedSuggestionIndex: .constant(0),
                // Enter：直接提交
                onCommit: onCommit,
                // 不存在联想确认
                onConfirmSuggestion: {},
                // 主题：描述区使用描述文字色；同时把 hashtagColor 设为同色，达到“无高亮”效果
                baseTextColor: themeManager.descriptionTextColor,
                hashtagColor: themeManager.descriptionTextColor,
                fontSize: fontSize
            )
            .frame(height: measuredHeight)
            .iBeamCursor()

            // placeholder：聚焦隐藏；输入后删空再显示；IME 组合态隐藏
            if shouldShowPlaceholder {
                Text(placeholder)
                    .font(.system(size: fontSize))
                    .foregroundColor(themeManager.descriptionTextColor.opacity(0.9))
                    .padding(.leading, 14)
                    .padding(.top, 4)
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: text) { _, _ in
            // 只要在本次聚焦期间出现过非空内容，就认为“编辑过”
            if isEditing && !hasMarkedText && !text.isEmpty {
                didEditSinceFocus = true
            }
        }
        .onChange(of: isEditing) { _, newValue in
            // 失焦时重置“编辑过”状态
            if !newValue {
                didEditSinceFocus = false
            }
            onEditingChanged?(newValue)
        }
    }

    private var shouldShowPlaceholder: Bool {
        if hasMarkedText { return false }
        if !text.isEmpty { return false }
        if !isEditing { return true }
        return didEditSinceFocus
    }
}

