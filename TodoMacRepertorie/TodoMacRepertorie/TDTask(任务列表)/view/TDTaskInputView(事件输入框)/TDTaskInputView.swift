//
//  TDTaskInputView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/21.
//

import SwiftUI

struct TDTaskInputView: View {
    @StateObject private var themeManager = TDThemeManager.shared
    @StateObject private var settingManager = TDSettingManager.shared
    @StateObject private var sliderViewModel = TDSliderBarViewModel.shared
    @StateObject private var userManager = TDUserManager.shared
    @ObservedObject private var mainViewModel = TDMainViewModel.shared
    @Environment(\.modelContext) private var modelContext

    /// 固定写入的 todoTime（毫秒）
    /// - nil：沿用默认逻辑（今天）
    /// - 0：无日期
    /// - >0：指定日期（当天 00:00 的时间戳）
    private let todoTimeOverride: Int64?
    
    /// 是否显示右侧“更多”菜单
    private let showMoreMenu: Bool

    /// 输入框当前选中的“目标清单 id”
    /// - 0：未分类
    /// - >0：分类清单 id
    @State private var inputSelectedCategory: TDSliderBarModel?

    @State private var taskContent: String = ""
    @State private var offset: CGFloat = 0
    @State private var isShaking = false

    init(todoTimeOverride: Int64? = nil, showMoreMenu: Bool = true) {
        self.todoTimeOverride = todoTimeOverride
        self.showMoreMenu = showMoreMenu
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
                focusRequestId: $mainViewModel.pendingInputFocusRequestId,
                placeholder: "task_input_placeholder".localized,
                fontSize: 13,
                onCommit: {
                    createTaskIfNeeded()
                }
            )
            .environmentObject(themeManager)
            // 让鼠标放上去时稳定显示输入光标（解决 DayTodo 的 List 叠层导致光标不切换问题）
            .iBeamCursor()

            // 右侧：更多菜单（替换 + 号）
            if showMoreMenu {
                TDTaskListMoreMenu()
            }
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
        // 选择变更：根据“是否记忆上次分类选择”决定是否落盘
        .onChange(of: inputSelectedCategory) { _, newValue in
            inputSelectedCategory = TDDataOperationManager.shared.validateSelectedCategory(inputSelectedCategory)
        }
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
        // 1) 输入内容清洗（开头去空白；结尾按“标签空格”规则保留/去除）
        let sanitized = taskContent.tdSanitizedTaskInputTitle()
        if sanitized.isEmpty {
            isShaking = true
            return
        }

        TDDataOperationManager.shared.createTask(
            content: taskContent,
            category: inputSelectedCategory,
            todoTime: todoTimeOverride, // nil=今天；0=无日期；>0=指定日期
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
    TDTaskInputView()
}
