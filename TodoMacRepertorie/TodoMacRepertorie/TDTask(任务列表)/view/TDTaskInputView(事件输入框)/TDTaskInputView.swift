//
//  TDTaskInputView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/21.
//

import SwiftUI

struct TDTaskInputView: View {
    @StateObject private var mainViewModel = TDMainViewModel.shared
    @StateObject private var themeManager = TDThemeManager.shared
    @StateObject private var settingManager = TDSettingManager.shared

    @State private var taskContent: String = ""
    @State private var offset: CGFloat = 0
    @State private var isShaking = false

    var body: some View {
        HStack(spacing: 12) {
            // 左侧分类标识
            if let category = mainViewModel.selectedCategory, category.categoryId > 0 {
                // 显示分类颜色圆圈
                Circle()
                    .fill(Color.fromHex(category.categoryColor ?? ""))
                    .frame(width: 16, height: 16)
            } else {
                // 显示未分类文字
                Text("uncategorized".localized)
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.descriptionTextColor)
            }
            
            // 输入框
            TDHashtagEditor(
                text: $taskContent,
                placeholder: "task_input_placeholder".localized,
                fontSize: 13,
                onCommit: {
                    createTaskIfNeeded()
                }
            )
            .environmentObject(themeManager)
            
            // 添加按钮
            Button(action: {
                createTaskIfNeeded()
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(themeManager.color(level: 5))
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        // 注意：这里不能用 clipShape 去裁剪整个输入框容器，
        // 否则 `#标签弹窗` 会被裁剪掉看不见。用圆角背景即可。
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.backgroundColor)
        )
        .shadow(color: themeManager.titleTextColor.opacity(0.2), radius: 4, x: 0, y: 2)
        .offset(x: offset)
        .onChange(of: isShaking) { oldValue, newValue in
            guard newValue else { return }
            withAnimation(.linear(duration: 0.1).repeatCount(3)) {
                offset = offset == 0 ? 5 : 0
            }
            // 动画结束后重置状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    offset = 0
                    isShaking = false
                }
            }
        }

    }
    
    private func createTaskIfNeeded() {
        if taskContent.isEmpty {
            isShaking = true
        } else {
            Task {
//                await mainViewModel.createTask(content: taskContent)
                taskContent = ""
            }
        }
    }
}

#Preview {
    TDTaskInputView()
}
