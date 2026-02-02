//
//  TDScheduleTaskInputView.swift
//  TodoMacRepertorie
//
//  Created by Cursor on 2026/2/2.
//

import SwiftUI

/// 日程概览专用输入框组件
/// 基于 TDTaskInputView，但使用 TDScheduleMoreMenu 和当前选中日期
struct TDScheduleTaskInputView: View {
    @StateObject private var themeManager = TDThemeManager.shared
    @StateObject private var settingManager = TDSettingManager.shared
    @StateObject private var sliderViewModel = TDSliderBarViewModel.shared
    @StateObject private var userManager = TDUserManager.shared
    @Environment(\.modelContext) private var modelContext

    /// 当前选中的日期（用于创建任务时的日期）
    let selectedDate: Date
    
    /// 输入框当前选中的分类模型（nil 表示未分类）
    @State private var inputSelectedCategory: TDSliderBarModel? = nil

    @State private var taskContent: String = ""
    @State private var offset: CGFloat = 0
    @State private var isShaking = false

    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        // 初始化入口：
        // - 未登录：默认未分类
        // - 已登录 + 开启记忆：直接使用“记忆的分类清单完整数据（TDSliderBarModel）”
        // - 未开启记忆：默认未分类
        let userId = TDUserManager.shared.userId
        guard userId > 0 else {
            _inputSelectedCategory = State(initialValue: nil)
            return
        }
        let settingManager = TDSettingManager.shared

        if settingManager.rememberLastCategory {
            // 直接获取保存的分类模型
            let rememberedCategory = settingManager.getLastSelectedCategory(for: userId)
            _inputSelectedCategory = State(initialValue: rememberedCategory)
        } else {
            _inputSelectedCategory = State(initialValue: nil)
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            // 左侧：分类清单 Menu
            TDCategoryPickerMenu(
                selectedCategory: inputSelectedCategory,
                showAllItem: false,
                showCreateItem: true,
                showUncategorizedItem: true,
                labelStyle: .iconOnly,
                onAllSelected: {
                    
                },
                onCreate: {
                    sliderViewModel.showAddCategorySheet()
                },
                onUncategorizedSelected: {
                    // 未分类选择回调
                    inputSelectedCategory = nil
                    TDDataOperationManager.shared.persistSelectedCategoryIfNeeded(category: nil)
                },
                onCategorySelected: { category in
                    // 分类选择回调：保存分类模型数据
                    inputSelectedCategory = category
                    TDDataOperationManager.shared.persistSelectedCategoryIfNeeded(category: category)
                }
            )
            
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
            // 让鼠标放上去时稳定显示输入光标（解决 DayTodo 的 List 叠层导致光标不切换问题）
            .iBeamCursor()

            // 右侧：更多菜单（日程概览专用）
            TDScheduleMoreMenu()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8) // 调整 padding 使总高度为 40
        .frame(height: 40) // 固定高度为 40
        // 注意：这里不能用 clipShape 去裁剪整个输入框容器，
        // 否则 `#标签弹窗` 会被裁剪掉看不见。用圆角背景即可。
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.backgroundColor)
        )
        .shadow(color: themeManager.titleTextColor.opacity(0.2), radius: 4, x: 0, y: 2)
        .offset(x: offset)
        // 分类清单变更（删除/编辑颜色等）：校验当前选择是否仍有效
        .onChange(of: sliderViewModel.items) { _, _ in
            inputSelectedCategory = TDDataOperationManager.shared.validateSelectedCategory(inputSelectedCategory)
        }
        // 退出登录：不管是否记忆，强制回到未分类
        .onChange(of: userManager.isLoggedIn) { _, newValue in
            if !newValue {
                inputSelectedCategory = nil
            }
        }
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
        // 使用当前选中的日期作为任务的日期（而不是今天）
        let todoTime = selectedDate.startOfDayTimestamp
        
        TDDataOperationManager.shared.createTask(
            content: taskContent,
            category: inputSelectedCategory,
            todoTime: todoTime,
            modelContext: modelContext,
            onSuccess: {
                // 清空输入框
                taskContent = ""
            },
            onError: {
                // 写入失败：触发抖动反馈（避免静默失败）
                isShaking = true
            }
        )
    }
}

#Preview {
    TDScheduleTaskInputView(selectedDate: Date())
}
