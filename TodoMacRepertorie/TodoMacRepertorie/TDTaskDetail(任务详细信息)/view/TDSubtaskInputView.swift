//
//  TDSubtaskInputView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI

/// 子任务输入框视图
struct TDSubtaskInputView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    
    // 输入状态
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    
    // 当前子任务数量
    let currentCount: Int
    let maxCount: Int = 20
    
    // 回调
    let onAddSubtask: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 子任务图标
                Image(systemName: "slider.horizontal.2.square")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.titleTextColor)
                
                // 输入框
                TextField(placeholderText, text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.titleTextColor)
                    .focused($isInputFocused)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())  // 扩大点击区域到整个 frame
                    .onChange(of: inputText) { _, newValue in
                        if newValue.count > 80 {
                            inputText = String(newValue.prefix(80))
                        }
                    }
                    .onSubmit {
                        addSubtask()
                    }
                
                // 添加按钮
                Button(action: {
                    addSubtask()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(canAddSubtask ? themeManager.color(level: 5) : themeManager.descriptionTextColor)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!canAddSubtask)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.white)
            
            // 分割线
            Rectangle()
                .fill(themeManager.descriptionTextColor.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 计算属性
    
    /// 占位文字
    private var placeholderText: String {
        return "\(currentCount + 1)/\(maxCount)"
    }
    
    /// 是否可以添加子任务
    private var canAddSubtask: Bool {
        return currentCount < maxCount && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - 私有方法
    
    /// 添加子任务
    private func addSubtask() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty && currentCount < maxCount else { return }
        
        onAddSubtask(trimmedText)
        inputText = ""
        isInputFocused = true
    }
}

#Preview {
    TDSubtaskInputView(
        currentCount: 3,
        onAddSubtask: { content in
            print("添加子任务: \(content)")
        }
    )
    .padding()
    .environmentObject(TDThemeManager.shared)
}
