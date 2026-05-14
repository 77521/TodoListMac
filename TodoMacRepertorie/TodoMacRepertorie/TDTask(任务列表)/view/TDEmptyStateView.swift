//
//  TDEmptyStateView.swift
//  TodoMacRepertorie
//
//  通用空状态占位视图，供 TDDayTodoView、TDTaskListView 等列表界面复用

import SwiftUI

/// 通用空状态视图
/// - icon：SF Symbol 名称
/// - title：主提示文字
/// - subtitle：次级提示文字（可选）
struct TDEmptyStateView: View {
    @EnvironmentObject private var themeManager: TDThemeManager

    let icon: String
    let title: String
    var subtitle: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(themeManager.color(level: 3))

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(themeManager.titleTextColor)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.descriptionTextColor)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
    }
}

#Preview {
    TDEmptyStateView(
        icon: "checkmark.circle",
        title: "今天没有任务",
        subtitle: "点击上方输入框添加新任务"
    )
    .environmentObject(TDThemeManager.shared)
    .frame(width: 320, height: 400)
}
