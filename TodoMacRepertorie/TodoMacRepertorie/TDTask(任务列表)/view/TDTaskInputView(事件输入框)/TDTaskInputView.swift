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
    @Environment(\.modelContext) private var modelContext

    /// 输入框当前选中的“目标清单 id”
    /// - 0：未分类
    /// - >0：分类清单 id
    @State private var inputSelectedCategoryId: Int = 0

    @State private var taskContent: String = ""
    @State private var offset: CGFloat = 0
    @State private var isShaking = false

    init() {
        // 初始化入口：
        // - 未登录：默认未分类
        // - 已登录 + 开启记忆：优先使用“记忆的分类清单 id”
        // - 未开启记忆：默认未分类
        let userId = TDUserManager.shared.userId
        guard userId > 0 else {
            _inputSelectedCategoryId = State(initialValue: 0)
            return
        }

        let settingManager = TDSettingManager.shared
        if settingManager.rememberLastCategory {
            let rememberedId = settingManager.getLastSelectedCategoryId(for: userId)
            _inputSelectedCategoryId = State(initialValue: max(0, rememberedId))
        } else {
            _inputSelectedCategoryId = State(initialValue: 0)
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            // 左侧：分类清单 Menu
            TDCategoryPickerMenu(
                selectedCategoryId: $inputSelectedCategoryId,
                showCreateItem: true,
                showUncategorizedItem: true,
                onCreate: {
                    sliderViewModel.showAddCategorySheet()
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

            // 右侧：更多菜单（替换 + 号）
            TDTaskListMoreMenu()
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
        .onChange(of: inputSelectedCategoryId) { _, newValue in
            persistSelectedCategoryIfNeeded(categoryId: newValue)
        }
        // 分类清单变更（删除/编辑颜色等）：校验当前选择是否仍有效
        .onChange(of: sliderViewModel.items) { _, _ in
            validateSelectedCategoryId()
        }
        // 退出登录：不管是否记忆，强制回到未分类
        .onChange(of: userManager.isLoggedIn) { _, newValue in
            if !newValue {
                inputSelectedCategoryId = 0
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

        // 2) 构建最小任务模型（其他字段由 addLocalTask 自动赋值）
        let newTask = makeNewLocalTask(content: sanitized, categoryId: inputSelectedCategoryId)

        Task {
            do {
                _ = try await TDQueryConditionManager.shared.addLocalTask(newTask, context: modelContext)
                // 3) 触发同步（保持与其它本地增删改一致）
                await TDMainViewModel.shared.performSyncSeparately()
                // 4) 清空输入框
                taskContent = ""
            } catch {
                // 写入失败：触发抖动反馈（避免静默失败）
                isShaking = true
            }
        }
    }

    /// 构建“最小可用”的本地任务模型：
    /// - 只需要把 taskContent / todoTime / 分类相关字段填好
    /// - version/taskSort/taskId/createTime/syncTime/userId 等由 addLocalTask 统一赋值
    private func makeNewLocalTask(content: String, categoryId: Int) -> TDMacSwiftDataListModel {
        let now = Date.currentTimestamp
        let userId = TDUserManager.shared.userId
        let todoTime = Date().startOfDayTimestamp

        // 分类信息（用于：勾选框跟随清单颜色等 UI 展示）
        let category = (categoryId > 0) ? TDCategoryManager.shared.getCategory(id: categoryId) : nil
        let standbyIntColor = category?.categoryColor ?? ""
        let standbyIntName = category?.categoryName ?? "uncategorized".localized

        return TDMacSwiftDataListModel(
            id: now,                    // 用时间戳保证唯一（服务器 id 之后会覆盖/同步）
            taskId: "",                 // addLocalTask 内会生成
            taskContent: content,
            taskDescribe: nil,
            complete: false,
            createTime: now,            // addLocalTask 内会覆盖
            delete: false,
            reminderTime: 0,
            snowAdd: 0,
            snowAssess: 0,
            standbyInt1: max(0, categoryId),
            standbyStr1: nil,
            standbyStr2: nil,
            standbyStr3: nil,
            standbyStr4: nil,
            syncTime: now,              // addLocalTask 内会覆盖
            taskSort: 0,                // addLocalTask 内会覆盖
            todoTime: todoTime,
            userId: userId,             // addLocalTask 内会覆盖，但这里先填上，便于 indexTask
            version: 0,
            status: "add",
            isSubOpen: true,
            standbyIntColor: standbyIntColor,
            standbyIntName: standbyIntName,
            reminderTimeString: "",
            subTaskList: [],
            attachmentList: []
        )
    }

    /// 根据“是否记忆上次分类选择”决定是否持久化
    private func persistSelectedCategoryIfNeeded(categoryId: Int) {
        let userId = userManager.userId
        guard userId > 0 else { return }

        if settingManager.rememberLastCategory {
            settingManager.setLastSelectedCategoryId(max(0, categoryId), for: userId)
        } else {
            // 不记忆：确保杀 App 后还是默认未分类
            settingManager.setLastSelectedCategoryId(0, for: userId)
        }
    }

    /// 校验当前选择的分类 id 是否仍然有效（被删除/不存在则回到未分类）
    private func validateSelectedCategoryId() {
        let userId = userManager.userId
        guard userId > 0 else {
            inputSelectedCategoryId = 0
            return
        }
        guard inputSelectedCategoryId > 0 else { return }

        let all = TDCategoryManager.shared.loadLocalCategories()
        let exists = all.contains { item in
            item.categoryId == inputSelectedCategoryId &&
            (item.delete == false || item.delete == nil) &&
            item.folderIs != true
        }
        if !exists {
            inputSelectedCategoryId = 0
            settingManager.setLastSelectedCategoryId(0, for: userId)
        }
    }
}

#Preview {
    TDTaskInputView()
}
