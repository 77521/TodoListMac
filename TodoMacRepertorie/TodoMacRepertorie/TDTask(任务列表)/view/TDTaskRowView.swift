//
//  TDTaskRowView.swift
//  TodoMacRepertorie
//
//  Created by Assistant on 2025/1/20.
//

import SwiftUI
import SwiftData



/// 副本创建类型枚举
enum CopyType {
    case normal          // 创建副本（保持原日期）
    case toToday         // 创建副本到今天
    case toSpecificDate  // 创建副本到指定日期
}

/// 通用任务行视图组件
struct TDTaskRowView: View , Equatable{
    let task: TDMacSwiftDataListModel
    let category: TDSliderBarModel?
    let orderNumber: Int?
    
    let isFirstRow: Bool
    let isLastRow: Bool
    // 计算属性：是否显示置顶按钮
    private var shouldShowPinToTop: Bool {
        return !isFirstRow
    }
    
    // 计算属性：是否显示置底按钮
    private var shouldShowPinToBottom: Bool {
        return !isLastRow
    }
    @State private var isHovered: Bool = false

    // 监听多选模式状态变化
    @ObservedObject private var mainViewModel = TDMainViewModel.shared
    
    
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var showDatePickerForCopy: Bool = false  // 控制创建副本的日期选择器显示
    @State private var selectedCopyDate: Date = Date()  // 创建副本时选择的日期
    @State private var showCopySuccessToast: Bool = false  // 控制复制成功Toast的显示
    // 复制成功回调
    var onCopySuccess: (() -> Void)?
    // 进入多选模式回调
    var onEnterMultiSelect: (() -> Void)?

    // 判断是否显示顺序数字
    private var shouldShowOrderNumber: Bool {
        return category?.categoryId == -100 && task.shouldShowOrderNumber && orderNumber != nil
    }
    
    var body: some View {
        HStack(spacing: 0) {
            
            // 1. 难度指示条（左边）
            RoundedRectangle(cornerRadius: 1.5)
                .fill(task.difficultyColor)
                .frame(width: 3)
                .padding(.vertical, 2)
                .padding(.leading, 1)
                .frame(maxHeight: .infinity)
            
            // 2. 主要内容区域
            VStack(alignment: .center, spacing: 8) {
                HStack(alignment: .center, spacing: 12) {
                    
                    HStack(alignment: .top, spacing: 12) {
                        // 完成状态复选框
                        // 完成状态复选框/多选圆圈
                        Button(action: {
                            if mainViewModel.isMultiSelectMode {
                                toggleSelection()
                            } else {
                                toggleTaskCompletion()
                            }
                        }) {
                            ZStack {
                                if mainViewModel.isMultiSelectMode {
                                    // 多选模式：显示圆圈
                                    Circle()
                                        .stroke(themeManager.color(level: 5), lineWidth: 1.5)
                                        .frame(width: 18, height: 18)
                                    
                                    if mainViewModel.selectedTasks.contains(where: { $0.taskId == task.taskId }) {
                                        Circle()
                                            .fill(themeManager.color(level: 5))
                                            .frame(width: 18, height: 18)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    
                                    
                                } else {
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(task.checkboxColor, lineWidth: 1.5)
                                        .frame(width: 18, height: 18)
                                    
                                    if task.complete {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(task.checkboxColor)
                                            .frame(width: 18, height: 18)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    } else if shouldShowOrderNumber {
                                        // DayTodo 且设置显示顺序数字时，显示数字
                                        Text("\(orderNumber!)")
                                            .font(.system(size: 8, weight: .medium))
                                            .foregroundColor(task.checkboxColor)
                                    }
                                    
                                }
                            }
                            .contentShape(Rectangle())
                            
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 任务内容
                        VStack(alignment: .leading, spacing: 6) {
                            // 任务标题
                            Text(task.taskContent)
                                .font(.system(size: 14))
                                .foregroundColor(task.taskTitleColor)
                                .strikethrough(task.taskTitleStrikethrough)
                                .opacity(task.complete ? 0.6 : 1.0)
                                .lineLimit(TDSettingManager.shared.taskTitleLines)
                            
                            // 任务描述（根据设置和内容决定是否显示）
                            if task.shouldShowTaskDescription {
                                Text(task.taskDescribe ?? "")
                                    .font(.system(size: 13))
                                    .foregroundColor(themeManager.descriptionTextColor)
                                    .lineLimit(TDSettingManager.shared.taskDescriptionLines)
                            }
                            
                            // 任务日期（今天、明天、后天显示文字，其他显示日期）
                            // 在 DayTodo 分类下不显示日期
                            if category?.categoryId != -100 && !task.taskDateConditionalString.isEmpty {
                                Text(task.taskDateConditionalString)
                                    .font(.system(size: 10))
                                    .foregroundColor(task.taskDateColor)
                            }
                            
                            // 底部信息栏
                            if task.hasReminder || task.hasRepeat || !task.attachmentList.isEmpty {
                                HStack(spacing: 12) {
                                    // 5. 提醒时间
                                    if task.hasReminder {
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(themeManager.color(level: 4))
                                            Text(task.reminderTimeString)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(themeManager.color(level: 4))
                                        }
                                    }
                                    
                                    // 6. 重复事件
                                    if task.hasRepeat {
                                        Image(systemName: "repeat")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(themeManager.color(level: 4))
                                    }
                                    
                                    // 7. 附件
                                    if task.hasAttachment {
                                        Image(systemName: "paperclip")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(themeManager.color(level: 4))
                                    }
                                    
                                    Spacer()
                                }
                            }
                            
                            // 8&9. 子任务
                            if !task.subTaskList.isEmpty {
                                // 展开/收起按钮
                                Button(action: {
                                    task.isSubOpen.toggle()
                                    // 保存到数据库
                                    do {
                                        try modelContext.save()
                                    } catch {
                                        print("保存子任务展开状态失败: \(error)")
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 8))
                                            .foregroundColor(themeManager.descriptionTextColor)
                                            .rotationEffect(.degrees(task.isSubOpen ? 180 : 0))
                                        
                                        Text(task.isSubOpen ? "收起" : "展开")
                                            .font(.system(size: 10))
                                            .foregroundColor(themeManager.descriptionTextColor)
                                    }
                                    .frame(width: 55, height: 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(themeManager.secondaryBackgroundColor)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contentShape(Rectangle())
                                
                                // 子任务列表
                                if task.isSubOpen {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(Array(task.subTaskList.enumerated()), id: \.offset) { index, subTask in
                                            HStack(spacing: 6) {
                                                if task.complete {
                                                    // 当前任务完成时，所有子任务显示圆点（不可点击）
                                                    Circle()
                                                        .fill(themeManager.color(level: 5))
                                                        .frame(width: 8, height: 8)
                                                } else {
                                                    // 当前任务未完成时，根据子任务状态显示（可点击）
                                                    Button(action: {
                                                        toggleSubTaskCompletion(subTaskIndex: index)
                                                    }) {
                                                        ZStack {
                                                            // 边框
                                                            Circle()
                                                                .stroke(themeManager.color(level: 5), lineWidth: 1)
                                                                .frame(width: 12, height: 12)
                                                            
                                                            if subTask.isComplete {
                                                                // 已完成：显示实心圆圈加对号
                                                                Circle()
                                                                    .fill(themeManager.color(level: 5))
                                                                    .frame(width: 12, height: 12)
                                                                
                                                                Image(systemName: "checkmark")
                                                                    .font(.system(size: 8, weight: .medium))
                                                                    .foregroundColor(.white)
                                                            }
                                                        }
                                                        .contentShape(Rectangle())
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                                
                                                Text(subTask.content)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(themeManager.subtaskTextColor)
                                                    .strikethrough(subTask.isComplete)
                                                    .opacity(subTask.isComplete ? 0.6 : 1.0)
                                            }
                                        }
                                    }
                                    .padding(.leading, 8)
                                }
                            }
                            
                        }
                        
                        Spacer()
                    }
                    // 专注按钮（右边居中）
                    Button(action: startFocus) {
                        Image(systemName: "timer")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.color(level: 5))
                            .frame(width: 32, height: 32)
                            .background(themeManager.color(level: 5).opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
//        .frame(maxWidth: .infinity) // 横向铺满
        .background(
            Group {
                if mainViewModel.selectedTask?.taskId == task.taskId || mainViewModel.selectedTasks.contains(where: { $0.taskId == task.taskId }) {
                    // 选中状态（单选或多选）：毛玻璃背景
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .background(themeManager.color(level: 4).opacity(0.1))
                } else if isHovered {
                    // 悬停状态：主题颜色二级背景色
                    themeManager.secondaryBackgroundColor
                } else {
                    // 默认状态：主题背景色
                    themeManager.backgroundColor
                }
            }        )
//        .onHover { hovering in
//            // 使用防抖，避免频繁更新
//            isHovered = hovering
//
//        }
        .overlay(
            Rectangle()
                .fill(themeManager.separatorColor)
                .frame(height: 1.0)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity, alignment: .bottom)
        )
        .onTapGesture {
            if mainViewModel.isMultiSelectMode {
                // 多选模式下，点击整行也可以选中/取消选中
                toggleSelection()
            } else {
                // 单选模式下，选择任务并传递完整数据模型
                mainViewModel.selectTask(task)
            }
        }
        .contextMenu {
            if !mainViewModel.isMultiSelectMode {
                
                // 任务操作菜单
                Button("选择事件") {
                    // TODO: 实现选择事件功能
                    print("选择事件: \(task.taskContent)")
                    mainViewModel.enterMultiSelectMode()
                    mainViewModel.updateSelectedTask(task: task, isSelected: true)
                    // 调用进入多选模式回调，通知父视图更新任务列表
                    onEnterMultiSelect?()

                }
                
                Divider()
                
                Button("复制内容") {
                    // 使用数据操作管理器复制单个任务内容
                    // 使用数据操作管理器复制单个任务内容
                    let singleTaskArray = [task]
                    let success = TDDataOperationManager.shared.copyTasksToClipboard(singleTaskArray)
                    
                    if success {
                        // 触发复制成功回调
                        onCopySuccess?()
                    }
                }
                
                Menu("创建副本") {
                    Button("创建副本") {
                        // TODO: 实现创建副本功能
                        // 创建副本 - 保持原日期
                        handleCreateCopy(copyType: .normal)
                    }
                    
                    // 根据当前任务的日期判断是否显示"创建到今天"
                    if !task.isToday {
                        Button("创建到今天") {
                            // TODO: 实现创建到今天功能
                            // 创建副本到今天
                            handleCreateCopy(copyType: .toToday)
                        }
                    }
                    
                    Button("创建到指定日期") {
                        // TODO: 实现创建到指定日期功能
                        // 创建副本到指定日期 - 显示日期选择器
                        showDatePickerForCopy = true
                    }
                }
                
                Button("移到最前") {
                    handleMoveTask(isToTop: true)
                }
                .disabled(category?.categoryId != -100 || isFirstRow)
                
                Button("移到最后") {
                    handleMoveTask(isToTop: false)
                }
                .disabled(category?.categoryId != -100 || isLastRow)
                
                Button("删除", role: .destructive) {
                    deleteTask()
                }
            }
        }
        // 左滑功能
//        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
//            if !mainViewModel.isMultiSelectMode {
//                // 删除按钮 - 永远显示
//                Button(role: .destructive, action: deleteTask) {
//                    Image(systemName: "trash.fill")
//                        .font(.system(size: 16, weight: .medium))
//                        .foregroundColor(.white)
//                }
//                .tint(TDThemeManager.shared.fixedColor(themeId: "new_year_red", level: 5))
//                
//                // 置底按钮 - 只在 DayTodo 且不是最后一行时显示
//                if category?.categoryId == -100 && !isLastRow {
//                    Button(action: moveToBottom) {
//                        Image(systemName: "arrowshape.down.fill")
//                            .font(.system(size: 16, weight: .medium))
//                            .foregroundColor(.white)
//                    }
//                    .tint(TDThemeManager.shared.fixedColor(themeId: "wish_orange", level: 5))
//                }
//                
//                // 置顶按钮 - 只在 DayTodo 且不是第一行时显示
//                if category?.categoryId == -100 && !isFirstRow {
//                    Button(action: moveToTop) {
//                        Image(systemName: "arrowshape.up.fill")
//                            .font(.system(size: 16, weight: .medium))
//                            .foregroundColor(.white)
//                    }
//                    .tint(Color.fromHex("#404040"))
//                }
//            }
//            
//            
//        }
        
        // Performance optimizations
//        .equatable()
        .drawingGroup()
        .animation(.none, value: task.complete)
        // 创建副本的日期选择器弹窗 - 使用自定义日期选择器（支持农历显示）
        .popover(isPresented: $showDatePickerForCopy) {
            TDCustomDatePickerView(
                selectedDate: $selectedCopyDate,
                isPresented: $showDatePickerForCopy,
                onDateSelected: { date in
                    // 日期选择完成后的回调函数
                    print("📅 选择创建副本的日期: \(date)")
                    // 创建副本到指定日期
                    handleCreateCopy(copyType: .toSpecificDate)
                }
            )
            .frame(width: 280, height: 320) // 设置弹窗尺寸，与多选模式保持一致
        }

    }
    
    // MARK: - Private Methods
    
    private func toggleTaskCompletion() {
        print("切换任务完成状态: \(task.taskContent)")
        Task {
            // 如果任务即将变为已完成状态，先播放完成音效
            if !task.complete {
                TDAudioManager.shared.playCompletionSound()
            }
            do {
                let updatedTask = task
                updatedTask.complete = !task.complete // 切换状态
                
                // 2. 调用通用更新方法
                let queryManager = TDQueryConditionManager()
                let result = try await queryManager.updateLocalTaskWithModel(
                    updatedTask: updatedTask,
                    context: modelContext
                )
                
                if result == .updated {
                    print("切换任务状态成功: \(task.taskContent)")
                    
                    // 3. 调用同步方法
                    await TDMainViewModel.shared.performSyncSeparately()
                } else {
                    print("切换任务状态失败: 更新结果异常")
                }

            } catch {
                print("切换任务状态失败: \(error)")
            }
        }
    }
    private func toggleSubTaskCompletion(subTaskIndex: Int) {
        print("切换子任务完成状态: \(task.subTaskList[subTaskIndex].content)")
        
        Task {
            do {

                // 1. 创建更新后的任务模型
                let updatedTask = task
                let newCompletionState = !task.subTaskList[subTaskIndex].isComplete
                
                // 2. 更新子任务状态
                updatedTask.subTaskList[subTaskIndex].isComplete = newCompletionState
                
                // 3. 重新生成 standbyStr2 字符串
                let newSubTasksString = updatedTask.generateSubTasksString()
                updatedTask.standbyStr2 = newSubTasksString.isEmpty ? nil : newSubTasksString
                
                // 4. 检查是否需要自动完成父任务
                if updatedTask.allSubTasksCompleted {
                    // 根据设置决定是否自动完成父任务
                    // TODO: 这里需要添加设置项，暂时默认自动完成
                    let shouldAutoCompleteParent = true // TDSettingManager.shared.autoCompleteParentWhenAllSubTasksDone
                    
                    if shouldAutoCompleteParent && !updatedTask.complete {
                        updatedTask.complete = true
                        print("🔍 所有子任务完成，自动完成父任务: \(updatedTask.taskContent)")
                    }
                }
                
                // 5. 调用通用更新方法
                let queryManager = TDQueryConditionManager()
                let result = try await queryManager.updateLocalTaskWithModel(
                    updatedTask: updatedTask,
                    context: modelContext
                )
                
                if result == .updated {
                    print("切换子任务状态成功: \(task.subTaskList[subTaskIndex].content)")
                    
                    // 6. 调用同步方法
                    await TDMainViewModel.shared.performSyncSeparately()
                } else {
                    print("切换子任务状态失败: 更新结果异常")
                }

            } catch {
                print("切换子任务状态失败: \(error)")
            }
        }
    }
    
    private func toggleSelection() {
        let isSelected = mainViewModel.selectedTasks.contains { $0.taskId == task.taskId }
        mainViewModel.updateSelectedTask(task: task, isSelected: !isSelected)
    }
    
    
    private func startFocus() {
        mainViewModel.exitMultiSelectMode()
        // TODO: 启动专注计时器
        print("启动专注计时器: \(task.taskContent)")
    }
    
    
    /// 置顶任务
    private func moveToTop() {
        print("置顶任务: \(task.taskContent)")
        // TODO: 实现置顶逻辑
        handleMoveTask(isToTop: true)
        
    }
    
    /// 置底任务
    private func moveToBottom() {
        print("置底任务: \(task.taskContent)")
        // TODO: 实现置底逻辑
        handleMoveTask(isToTop: false)
        
    }
    
    /// 删除任务
    private func deleteTask() {
        print("删除任务: \(task.taskContent)")
        
        Task {
            do {
                // 1. 创建更新后的任务模型
                let updatedTask = task
                updatedTask.delete = true
                updatedTask.status = "delete"

                // 2. 调用通用更新方法
                let queryManager = TDQueryConditionManager()
                let result = try await queryManager.updateLocalTaskWithModel(
                    updatedTask: updatedTask,
                    context: modelContext
                )
                
                print("删除任务成功，结果: \(result)")
                
                // 3. 调用同步方法
                await TDMainViewModel.shared.performSyncSeparately()

            } catch {
                print("删除任务失败: \(error)")
            }
        }
    }
    
    /// 处理任务移动（置顶或置底）
    /// - Parameter isToTop: true 表示置顶，false 表示置底
    private func handleMoveTask(isToTop: Bool) {
        // 检查是否为重复事件
        if let repeatId = task.standbyStr1, !repeatId.isEmpty {
            // 是重复事件，先获取重复事件数组，再显示弹窗
            Task {
                await showRepeatTaskAlertWithCount(isToTop: isToTop, repeatId: repeatId)
            }
        } else {
            // 不是重复事件，直接执行操作
            performMoveTask(isToTop: isToTop, isRepeatGroup: false)
        }
    }
    
    /// 显示重复事件操作弹窗（带数量）
    /// - Parameters:
    ///   - isToTop: true 表示置顶，false 表示置底
    ///   - repeatId: 重复事件ID
    @MainActor
    private func showRepeatTaskAlertWithCount(isToTop: Bool, repeatId: String) async {
        do {
            // 先获取重复事件数组
            let queryManager = TDQueryConditionManager()
            let duplicateTasks = try await queryManager.getDuplicateTasks(
                standbyStr1: repeatId,
                onlyUncompleted: false,
                context: modelContext
            )
            
            let action = isToTop ? "置顶" : "置底"
            let alert = NSAlert()
            alert.messageText = "重复事件操作"
            alert.informativeText = "是否对该重复组的\(duplicateTasks.count)个事件进行批量\(action)操作？"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "仅该事件")
            alert.addButton(withTitle: "确定")
            alert.addButton(withTitle: "取消")
            
            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn:
                // 仅该事件
                performMoveTask(isToTop: isToTop, isRepeatGroup: false)
            case .alertSecondButtonReturn:
                // 确定（批量操作）
                performMoveTask(isToTop: isToTop, isRepeatGroup: true, duplicateTasks: duplicateTasks)
            case .alertThirdButtonReturn:
                // 取消
                break
            default:
                break
            }
            
        } catch {
            print("获取重复事件失败: \(error)")
            // 如果获取失败，直接执行单个任务操作
            performMoveTask(isToTop: isToTop, isRepeatGroup: false)
        }
    }
    /// 执行任务移动操作
    /// - Parameters:
    ///   - isToTop: true 表示置顶，false 表示置底
    ///   - isRepeatGroup: 是否为重复组批量操作
    ///   - duplicateTasks: 重复事件数组（仅在批量操作时需要）
    private func performMoveTask(isToTop: Bool, isRepeatGroup: Bool, duplicateTasks: [TDMacSwiftDataListModel]? = nil) {
        let action = isToTop ? "置顶" : "置底"
        let scope = isRepeatGroup ? "重复组" : "单个"
        
        print("\(action)任务: \(task.taskContent) (\(scope))")
        
        Task {
            if isRepeatGroup, let duplicateTasks = duplicateTasks {
                // 批量操作重复组
                print("开始批量\(action) \(duplicateTasks.count) 个重复事件")
                await performBatchMove(duplicateTasks: duplicateTasks, isToTop: isToTop)
                
            } else {
                // 单个任务操作
                await performSingleMove(task: task, isToTop: isToTop)
            }
        }
    }
    
    // MARK: - 移动操作实现
    
    /// 执行批量移动操作
    /// - Parameters:
    ///   - duplicateTasks: 重复事件数组
    ///   - isToTop: true 表示置顶，false 表示置底
    private func performBatchMove(duplicateTasks: [TDMacSwiftDataListModel], isToTop: Bool) async {
        let action = isToTop ? "置顶" : "置底"
        
        do {
            // 遍历每个重复事件
            for task in duplicateTasks {
                await moveSingleTask(task: task, isToTop: isToTop)
            }
            
            // 保存所有更改
            try modelContext.save()
            print("批量\(action)完成，共处理 \(duplicateTasks.count) 个任务")
            
        } catch {
            print("批量\(action)失败: \(error)")
        }
    }
    
    /// 执行单个任务移动操作
    /// - Parameters:
    ///   - task: 要移动的任务
    ///   - isToTop: true 表示置顶，false 表示置底
    private func performSingleMove(task: TDMacSwiftDataListModel, isToTop: Bool) async {
        do {
            await moveSingleTask(task: task, isToTop: isToTop)
            // 保存更改
            try modelContext.save()
        } catch {
            print("移动任务失败: \(error)")
        }
    }
    
    /// 移动单个任务的核心逻辑
    /// - Parameters:
    ///   - task: 要移动的任务
    ///   - isToTop: true 表示置顶，false 表示置底
    private func moveSingleTask(task: TDMacSwiftDataListModel, isToTop: Bool) async {
        let queryManager = TDQueryConditionManager()
        let action = isToTop ? "置顶" : "置底"
        
        do {
            // 计算新的 taskSort 值
            let newTaskSort: Decimal
            let randomValue = TDAppConfig.randomTaskSort()
            
            if isToTop {
                // 置顶：获取最小值并计算
                let minTaskSort = try await queryManager.getMinTaskSortForDate(
                    todoTime: task.todoTime,
                    context: modelContext
                )
                
                if minTaskSort == 0 {
                    // 如果最小值为 0，使用默认值
                    newTaskSort = TDAppConfig.defaultTaskSort
                } else if minTaskSort > TDAppConfig.maxTaskSort * 2.0 {
                    // 最小值减去随机区间值
                    newTaskSort = minTaskSort - randomValue
                } else {
                    // 否则用最小值除以2.0
                    newTaskSort = minTaskSort / 2.0
                }
            } else {
                // 置底：获取最大值并计算
                let maxTaskSort = try await queryManager.getMaxTaskSortForDate(
                    todoTime: task.todoTime,
                    context: modelContext
                )
                // 用最大值加上随机区间值
                newTaskSort = maxTaskSort + randomValue
            }
            
            // 更新任务的 taskSort 值
            let updatedTask = task
            updatedTask.taskSort = newTaskSort
            
            let queryManager = TDQueryConditionManager()
            let result = try await queryManager.updateLocalTaskWithModel(
                updatedTask: updatedTask,
                context: modelContext
            )
            
            if result == .updated {
                print("\(action)任务成功: \(task.taskContent), 新 taskSort: \(newTaskSort)")
                
                // 调用同步方法
                await TDMainViewModel.shared.performSyncSeparately()
            } else {
                print("\(action)任务失败: 更新结果异常")
            }
            
        } catch {
            print("\(action)任务失败: \(error)")
        }
        
    }
    
    /// 处理创建副本的逻辑
    /// - Parameter copyType: 副本创建类型（普通副本、到今天、到指定日期）
    private func handleCreateCopy(copyType: CopyType) {
        print("📋 开始创建副本，类型: \(copyType)，任务: \(task.taskContent)")
        
        Task {
            do {
                // 1. 将当前任务转换为 TDTaskModel
                let taskModel = TDTaskModel(from: task)
                
                // 2. 将 TDTaskModel 转换回新的 TDMacSwiftDataListModel 对象
                let copiedTask = taskModel.toSwiftDataModel()

                // 2. 重置副本的基本信息
                copiedTask.standbyStr1 = ""  // 清空重复事件ID
                
                // 3. 根据副本类型设置日期
                switch copyType {
                case .normal:
                    // 保持原日期，不做修改
                    print("📅 创建副本 - 保持原日期: \(task.todoTime)")
                    
                case .toToday:
                    // 设置为今天开始时间
                    let todayStartTime = Date().startOfDayTimestamp
                    copiedTask.todoTime = todayStartTime
                    print("📅 创建副本到今天: \(todayStartTime)")
                    
                case .toSpecificDate:
                    // 设置为指定日期开始时间
                    let specificDateStartTime = selectedCopyDate.startOfDayTimestamp
                    copiedTask.todoTime = specificDateStartTime
                    print("📅 创建副本到指定日期: \(specificDateStartTime)")
                }
                
                // 4. 调用添加本地数据方法（会自动计算 taskSort）
                let queryManager = TDQueryConditionManager()
                let result = try await queryManager.addLocalTask(copiedTask, context: modelContext)
                
                if result == .added {
                    // 5. 执行数据同步
                    await TDMainViewModel.shared.performSyncSeparately()
                    
                    print("✅ 创建副本成功，新任务ID: \(copiedTask.taskId)")
                } else {
                    print("❌ 创建副本失败，结果: \(result)")
                }
                
            } catch {
                print("❌ 创建副本失败: \(error)")
            }
        }
    }

    // MARK: - Equatable 实现（性能优化关键）
        
        static func == (lhs: TDTaskRowView, rhs: TDTaskRowView) -> Bool {
            // 只比较关键属性，避免不必要的重新渲染
            let lhsIsSelected = lhs.mainViewModel.selectedTasks.contains(where: { $0.taskId == lhs.task.taskId })
            let rhsIsSelected = rhs.mainViewModel.selectedTasks.contains(where: { $0.taskId == rhs.task.taskId })

            // 只比较关键属性，避免不必要的重新渲染
            return lhs.task.taskId == rhs.task.taskId &&
                   lhs.task.complete == rhs.task.complete &&
                   lhs.task.taskContent == rhs.task.taskContent &&
                   lhs.task.taskDescribe == rhs.task.taskDescribe &&
                   lhs.task.isSubOpen == rhs.task.isSubOpen &&
                   lhs.task.subTaskList == rhs.task.subTaskList &&
                   lhs.isHovered == rhs.isHovered &&
                   lhs.mainViewModel.isMultiSelectMode == rhs.mainViewModel.isMultiSelectMode &&
                   lhs.mainViewModel.selectedTasks.contains(where: { $0.taskId == lhs.task.taskId }) ==
                   rhs.mainViewModel.selectedTasks.contains(where: { $0.taskId == rhs.task.taskId })
        }
    
}

#Preview {
    let testTask = TDMacSwiftDataListModel(
        id: 1,
        taskId: "test",
        taskContent: "这是一个测试任务，内容比较长，用来测试多行显示效果",
        taskDescribe: "这是任务的详细描述，用来测试描述显示功能",
        complete: false,
        createTime: Date.currentTimestamp,
        delete: false,
        reminderTime: Date.currentTimestamp,
        snowAdd: 0,
        snowAssess: 7,
        standbyInt1: 0,
        standbyStr1: "每天",
        standbyStr2: "[{\"isComplete\":false,\"content\":\"子任务1\"},{\"isComplete\":true,\"content\":\"子任务2\"}]",
        standbyStr3: nil,
        standbyStr4: "[{\"downloading\":false,\"name\":\"附件1.pdf\",\"size\":\"1.2MB\",\"suffix\":\"pdf\",\"url\":\"http://example.com\"}]",
        syncTime: Date.currentTimestamp,
        taskSort: 1000,
        todoTime: Date.currentTimestamp,
        userId: 1,
        version: 1
    )
    
    // 设置子任务和附件列表
    testTask.subTaskList = [
        TDMacSwiftDataListModel.SubTask(isComplete: false, content: "子任务1"),
        TDMacSwiftDataListModel.SubTask(isComplete: true, content: "子任务2")
    ]
    
    testTask.attachmentList = [
        TDMacSwiftDataListModel.Attachment(
            name: "附件1.pdf",
            size: "1.2MB",
            suffix: "pdf",
            url: "http://example.com"
        )
    ]
    
    return TDTaskRowView(task: testTask, category: nil, orderNumber: nil, isFirstRow: true, isLastRow: true)
        .environmentObject(TDThemeManager.shared)
}

//
////
////  TDTaskRowView.swift
////  TodoMacRepertorie
////
////  Created by Assistant on 2025/1/20.
////
//
//import SwiftUI
//import SwiftData
//
///// 副本创建类型枚举
//enum CopyType {
//    case normal          // 创建副本（保持原日期）
//    case toToday         // 创建副本到今天
//    case toSpecificDate  // 创建副本到指定日期
//}
//
//struct CustomDisclosureGroupStyle: DisclosureGroupStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        VStack(alignment: .leading, spacing: 0) {
//            configuration.label
//            if configuration.isExpanded {
//                configuration.content
//                    .transition(.asymmetric(
//                        insertion: .opacity.combined(with: .move(edge: .top)).animation(.easeOut(duration: 0.3)),
//                        removal: .opacity.combined(with: .move(edge: .top)).animation(.easeIn(duration: 0.25))
//                    ))
//            }
//        }
//        .animation(.easeInOut(duration: 0.4), value: configuration.isExpanded)
//    }
//}
//
//// MARK: - 独立视图组件
//
///// 难度指示条组件
//struct DifficultyIndicatorView: View {
//    let difficultyColor: Color
//    
//    var body: some View {
//        RoundedRectangle(cornerRadius: 2)
//            .fill(difficultyColor)
//            .frame(width: 4)
//            .padding(.vertical, 2)
//            .padding(.leading, 1)
//            .frame(maxHeight: .infinity)
//    }
//}
//
///// 复选框/多选圆圈组件
//struct TaskCheckboxView: View {
//    let task: TDMacSwiftDataListModel
//    let isMultiSelectMode: Bool
//    let isSelected: Bool
//    let shouldShowOrderNumber: Bool
//    let orderNumber: Int?
//    let onToggle: () -> Void
//    
//    @EnvironmentObject private var themeManager: TDThemeManager
//    
//    var body: some View {
//        Button(action: onToggle) {
//            ZStack {
//                if isMultiSelectMode {
//                    // 多选模式：显示圆圈
//                    Circle()
//                        .stroke(themeManager.color(level: 5), lineWidth: 1.5)
//                        .frame(width: 18, height: 18)
//                    
//                    if isSelected {
//                        Circle()
//                            .fill(themeManager.color(level: 5))
//                            .frame(width: 18, height: 18)
//                        
//                        Image(systemName: "checkmark")
//                            .font(.system(size: 10, weight: .medium))
//                            .foregroundColor(.white)
//                    }
//                } else {
//                    RoundedRectangle(cornerRadius: 3)
//                        .stroke(task.checkboxColor, lineWidth: 1.5)
//                        .frame(width: 18, height: 18)
//                    
//                    if task.complete {
//                        RoundedRectangle(cornerRadius: 3)
//                            .fill(task.checkboxColor)
//                            .frame(width: 18, height: 18)
//                        
//                        Image(systemName: "checkmark")
//                            .font(.system(size: 10, weight: .bold))
//                            .foregroundColor(.white)
//                    } else if shouldShowOrderNumber {
//                        Text("\(orderNumber!)")
//                            .font(.system(size: 8, weight: .medium))
//                            .foregroundColor(task.checkboxColor)
//                    }
//                }
//            }
//            .contentShape(Rectangle())
//        }
//        .buttonStyle(PlainButtonStyle())
//    }
//}
//
///// 任务内容组件
//struct TaskContentView: View {
//    let task: TDMacSwiftDataListModel
//    let category: TDSliderBarModel?
//    
//    @EnvironmentObject private var themeManager: TDThemeManager
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            // 任务标题
//            Text(task.taskContent)
//                .font(.system(size: 14))
//                .foregroundColor(task.taskTitleColor)
//                .strikethrough(task.taskTitleStrikethrough)
//                .opacity(task.complete ? 0.6 : 1.0)
//                .lineLimit(TDSettingManager.shared.taskTitleLines)
//            
//            // 任务描述
//            if task.shouldShowTaskDescription {
//                Text(task.taskDescribe ?? "")
//                    .font(.system(size: 13))
//                    .foregroundColor(themeManager.descriptionTextColor)
//                    .lineLimit(TDSettingManager.shared.taskDescriptionLines)
//            }
//            
//            // 任务日期
//            if category?.categoryId != -100 && !task.taskDateConditionalString.isEmpty {
//                Text(task.taskDateConditionalString)
//                    .font(.system(size: 10))
//                    .foregroundColor(task.taskDateColor)
//            }
//            
//            // 底部信息栏
//            TaskInfoBarView(task: task)
//            
//            // 子任务
//            if !task.subTaskList.isEmpty {
//                SubTaskView(task: task)
//            }
//        }
//    }
//}
//
///// 任务信息栏组件
//struct TaskInfoBarView: View {
//    let task: TDMacSwiftDataListModel
//    
//    @EnvironmentObject private var themeManager: TDThemeManager
//    
//    var body: some View {
//        if task.hasReminder || task.hasRepeat || !task.attachmentList.isEmpty {
//            HStack(spacing: 12) {
//                // 提醒时间
//                if task.hasReminder {
//                    HStack(spacing: 4) {
//                        Image(systemName: "clock")
//                            .font(.system(size: 12, weight: .medium))
//                            .foregroundColor(themeManager.color(level: 4))
//                        Text(task.reminderTimeString)
//                            .font(.system(size: 12, weight: .medium))
//                            .foregroundColor(themeManager.color(level: 4))
//                    }
//                }
//                
//                // 重复事件
//                if task.hasRepeat {
//                    Image(systemName: "repeat")
//                        .font(.system(size: 12, weight: .medium))
//                        .foregroundColor(themeManager.color(level: 4))
//                }
//                
//                // 附件
//                if !task.attachmentList.isEmpty {
//                    Image(systemName: "paperclip")
//                        .font(.system(size: 12, weight: .medium))
//                        .foregroundColor(themeManager.color(level: 4))
//                }
//                
//                Spacer()
//            }
//        }
//    }
//}
//
///// 子任务组件
//struct SubTaskView: View {
//    let task: TDMacSwiftDataListModel
//    
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @Environment(\.modelContext) private var modelContext
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            // 展开/收起按钮
//            SubTaskToggleButton(task: task)
//            
//            // 子任务列表
//            if task.isSubOpen {
//                SubTaskListView(task: task)
//            }
//        }
//    }
//}
//
///// 子任务切换按钮
//struct SubTaskToggleButton: View {
//    let task: TDMacSwiftDataListModel
//    
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @Environment(\.modelContext) private var modelContext
//    
//    var body: some View {
//        Button(action: {
//            task.isSubOpen.toggle()
//            do {
//                try modelContext.save()
//            } catch {
//                print("保存子任务展开状态失败: \(error)")
//            }
//        }) {
//            HStack(spacing: 4) {
//                Image(systemName: "chevron.down")
//                    .font(.system(size: 8))
//                    .foregroundColor(themeManager.descriptionTextColor)
//                    .rotationEffect(.degrees(task.isSubOpen ? 180 : 0))
//                
//                Text(task.isSubOpen ? "收起" : "展开")
//                    .font(.system(size: 10))
//                    .foregroundColor(themeManager.descriptionTextColor)
//            }
//            .frame(width: 55, height: 20)
//            .background(
//                RoundedRectangle(cornerRadius: 6)
//                    .fill(themeManager.secondaryBackgroundColor)
//            )
//        }
//        .buttonStyle(PlainButtonStyle())
//        .contentShape(Rectangle())
//    }
//}
//
///// 子任务列表
//struct SubTaskListView: View {
//    let task: TDMacSwiftDataListModel
//    
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @Environment(\.modelContext) private var modelContext
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            ForEach(Array(task.subTaskList.enumerated()), id: \.offset) { index, subTask in
//                SubTaskRowView(
//                    task: task,
//                    subTask: subTask,
//                    subTaskIndex: index
//                )
//            }
//        }
//        .padding(.leading, 8)
//    }
//}
//
///// 单个子任务行
//struct SubTaskRowView: View {
//    let task: TDMacSwiftDataListModel
//    let subTask: TDMacSwiftDataListModel.SubTask
//    let subTaskIndex: Int
//    
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @Environment(\.modelContext) private var modelContext
//    
//    var body: some View {
//        HStack(spacing: 6) {
//            if task.complete {
//                // 当前任务完成时，所有子任务显示圆点（不可点击）
//                Circle()
//                    .fill(themeManager.color(level: 5))
//                    .frame(width: 8, height: 8)
//            } else {
//                // 当前任务未完成时，根据子任务状态显示（可点击）
//                Button(action: {
//                    toggleSubTaskCompletion(subTaskIndex: subTaskIndex)
//                }) {
//                    ZStack {
//                        Circle()
//                            .stroke(themeManager.color(level: 5), lineWidth: 1)
//                            .frame(width: 12, height: 12)
//                        
//                        if subTask.isComplete {
//                            Circle()
//                                .fill(themeManager.color(level: 5))
//                                .frame(width: 12, height: 12)
//                            
//                            Image(systemName: "checkmark")
//                                .font(.system(size: 8, weight: .medium))
//                                .foregroundColor(.white)
//                        }
//                    }
//                    .contentShape(Rectangle())
//                }
//                .buttonStyle(PlainButtonStyle())
//            }
//            
//            Text(subTask.content)
//                .font(.system(size: 11))
//                .foregroundColor(themeManager.subtaskTextColor)
//                .strikethrough(subTask.isComplete)
//                .opacity(subTask.isComplete ? 0.6 : 1.0)
//        }
//    }
//    
//    private func toggleSubTaskCompletion(subTaskIndex: Int) {
//        Task {
//            do {
//                let updatedTask = task
//                let newCompletionState = !task.subTaskList[subTaskIndex].isComplete
//                
//                updatedTask.subTaskList[subTaskIndex].isComplete = newCompletionState
//                
//                let newSubTasksString = updatedTask.generateSubTasksString()
//                updatedTask.standbyStr2 = newSubTasksString.isEmpty ? nil : newSubTasksString
//                
//                if updatedTask.allSubTasksCompleted {
//                    let shouldAutoCompleteParent = true
//                    
//                    if shouldAutoCompleteParent && !updatedTask.complete {
//                        updatedTask.complete = true
//                    }
//                }
//                
//                let queryManager = TDQueryConditionManager()
//                let result = try await queryManager.updateLocalTaskWithModel(
//                    updatedTask: updatedTask,
//                    context: modelContext
//                )
//                
//                if result == .updated {
//                    await TDMainViewModel.shared.performSyncSeparately()
//                }
//            } catch {
//                print("切换子任务状态失败: \(error)")
//            }
//        }
//    }
//}
//
///// 专注按钮组件
//struct FocusButtonView: View {
//    let onFocus: () -> Void
//    
//    @EnvironmentObject private var themeManager: TDThemeManager
//    
//    var body: some View {
//        Button(action: onFocus) {
//            Image(systemName: "timer")
//                .font(.system(size: 14))
//                .foregroundColor(themeManager.color(level: 5))
//                .frame(width: 32, height: 32)
//                .background(themeManager.color(level: 5).opacity(0.1))
//                .clipShape(Circle())
//        }
//        .buttonStyle(PlainButtonStyle())
//    }
//}
//
///// 任务行背景组件
//struct TaskRowBackgroundView: View {
//    let isSelected: Bool
//    let isHovered: Bool
//    
//    @EnvironmentObject private var themeManager: TDThemeManager
//    
//    var body: some View {
//        Group {
//            if isSelected {
//                Rectangle()
//                    .fill(.ultraThinMaterial)
//                    .background(themeManager.color(level: 4).opacity(0.1))
//            } else if isHovered {
//                themeManager.secondaryBackgroundColor
//            } else {
//                themeManager.backgroundColor
//            }
//        }
//    }
//}
//
//// MARK: - 主任务行视图
//
///// 通用任务行视图组件 - 深度性能优化版本
//struct TDTaskRowView: View, Equatable {
//    let task: TDMacSwiftDataListModel
//    let category: TDSliderBarModel?
//    let orderNumber: Int?
//    
//    let isFirstRow: Bool
//    let isLastRow: Bool
//    
//    // 状态管理优化：使用 @State 而不是 @ObservedObject 来减少重绘
//    @State private var isHovered: Bool = false
//    @State private var showDatePickerForCopy: Bool = false
//    @State private var selectedCopyDate: Date = Date()
//    
//    // 回调函数
//    var onCopySuccess: (() -> Void)?
//    var onEnterMultiSelect: (() -> Void)?
//    
//    // 环境对象
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @Environment(\.modelContext) private var modelContext
//    
//    // 计算属性
//    private var shouldShowOrderNumber: Bool {
//        category?.categoryId == -100 && task.shouldShowOrderNumber && orderNumber != nil
//    }
//    
//    private var shouldShowPinToTop: Bool {
//        !isFirstRow
//    }
//    
//    private var shouldShowPinToBottom: Bool {
//        !isLastRow
//    }
//    
//    // 优化：缓存选中状态，避免重复计算
//    private var isSelected: Bool {
//        let mainViewModel = TDMainViewModel.shared
//        if let selectedTask = mainViewModel.selectedTask, selectedTask.taskId == task.taskId {
//            return true
//        }
//        return mainViewModel.selectedTasks.contains { $0.taskId == task.taskId }
//    }
//    
//    // 优化：缓存多选模式状态
//    private var isMultiSelectMode: Bool {
//        TDMainViewModel.shared.isMultiSelectMode
//    }
//    
//    var body: some View {
//        HStack(spacing: 0) {
//            // 1. 难度指示条
//            DifficultyIndicatorView(difficultyColor: task.difficultyColor)
//            
//            // 2. 主要内容区域
//            VStack(alignment: .center, spacing: 8) {
//                HStack(alignment: .center, spacing: 12) {
//                    HStack(alignment: .top, spacing: 12) {
//                        // 复选框/多选圆圈
//                        TaskCheckboxView(
//                            task: task,
//                            isMultiSelectMode: isMultiSelectMode,
//                            isSelected: isSelected,
//                            shouldShowOrderNumber: shouldShowOrderNumber,
//                            orderNumber: orderNumber,
//                            onToggle: handleCheckboxToggle
//                        )
//                        
//                        // 任务内容
//                        TaskContentView(task: task, category: category)
//                        
//                        Spacer()
//                    }
//                    
//                    // 专注按钮
//                    FocusButtonView(onFocus: startFocus)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 12)
//        }
//        .background(TaskRowBackgroundView(isSelected: isSelected, isHovered: isHovered))
//        .onHover { hovering in
//            // 防抖处理
//            if hovering != isHovered {
//                isHovered = hovering
//            }
//        }
//        .overlay(
//            Rectangle()
//                .fill(themeManager.separatorColor)
//                .frame(height: 1.0)
//                .frame(maxWidth: .infinity)
//                .frame(maxHeight: .infinity, alignment: .bottom)
//        )
//        .onTapGesture {
//            handleRowTap()
//        }
//        .contextMenu {
//            if !isMultiSelectMode {
//                buildContextMenu()
//            }
//        }
//        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
//            if !isMultiSelectMode {
//                buildSwipeActions()
//            }
//        }
//        // 性能优化修饰符
//        .drawingGroup(opaque: true)
//        .fixedSize(horizontal: false, vertical: true)
//        .animation(.none, value: task.complete)
//        .popover(isPresented: $showDatePickerForCopy) {
//            TDCustomDatePickerView(
//                selectedDate: $selectedCopyDate,
//                isPresented: $showDatePickerForCopy,
//                onDateSelected: { date in
//                    handleCreateCopy(copyType: .toSpecificDate)
//                }
//            )
//            .frame(width: 280, height: 320)
//        }
//    }
//    
//    // MARK: - 事件处理方法
//    
//    private func handleCheckboxToggle() {
//        if isMultiSelectMode {
//            let mainViewModel = TDMainViewModel.shared
//            let isSelected = mainViewModel.selectedTasks.contains { $0.taskId == task.taskId }
//            mainViewModel.updateSelectedTask(task: task, isSelected: !isSelected)
//        } else {
//            toggleTaskCompletion()
//        }
//    }
//    
//    private func handleRowTap() {
//        if isMultiSelectMode {
//            let mainViewModel = TDMainViewModel.shared
//            let isSelected = mainViewModel.selectedTasks.contains { $0.taskId == task.taskId }
//            mainViewModel.updateSelectedTask(task: task, isSelected: !isSelected)
//        } else {
//            TDMainViewModel.shared.selectTask(task)
//        }
//    }
//    
//    private func startFocus() {
//        TDMainViewModel.shared.exitMultiSelectMode()
//    }
//    
//    // MARK: - 上下文菜单构建
//    
//    @ViewBuilder
//    private func buildContextMenu() -> some View {
//        Button("选择事件") {
//            let mainViewModel = TDMainViewModel.shared
//            mainViewModel.enterMultiSelectMode()
//            mainViewModel.updateSelectedTask(task: task, isSelected: true)
//            onEnterMultiSelect?()
//        }
//        
//        Divider()
//        
//        Button("复制内容") {
//            let singleTaskArray = [task]
//            let success = TDDataOperationManager.shared.copyTasksToClipboard(singleTaskArray)
//            if success {
//                onCopySuccess?()
//            }
//        }
//        
//        Menu("创建副本") {
//            Button("创建副本") {
//                handleCreateCopy(copyType: .normal)
//            }
//            
//            if !task.isToday {
//                Button("创建到今天") {
//                    handleCreateCopy(copyType: .toToday)
//                }
//            }
//            
//            Button("创建到指定日期") {
//                showDatePickerForCopy = true
//            }
//        }
//        
//        Button("移到最前") {
//            handleMoveTask(isToTop: true)
//        }
//        .disabled(category?.categoryId != -100 || isFirstRow)
//        
//        Button("移到最后") {
//            handleMoveTask(isToTop: false)
//        }
//        .disabled(category?.categoryId != -100 || isLastRow)
//        
//        Button("删除", role: .destructive) {
//            deleteTask()
//        }
//    }
//    
//    // MARK: - 滑动操作构建
//    
//    @ViewBuilder
//    private func buildSwipeActions() -> some View {
//        Button(role: .destructive, action: deleteTask) {
//            Image(systemName: "trash.fill")
//                .font(.system(size: 16, weight: .medium))
//                .foregroundColor(.white)
//        }
//        .tint(TDThemeManager.shared.fixedColor(themeId: "new_year_red", level: 5))
//        
//        if category?.categoryId == -100 && !isLastRow {
//            Button(action: moveToBottom) {
//                Image(systemName: "arrowshape.down.fill")
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundColor(.white)
//            }
//            .tint(TDThemeManager.shared.fixedColor(themeId: "wish_orange", level: 5))
//        }
//        
//        if category?.categoryId == -100 && !isFirstRow {
//            Button(action: moveToTop) {
//                Image(systemName: "arrowshape.up.fill")
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundColor(.white)
//            }
//            .tint(Color.fromHex("#404040"))
//        }
//    }
//    
//    // MARK: - 任务操作方法
//    
//    private func toggleTaskCompletion() {
//        print("切换任务完成状态: \(task.taskContent)")
//        Task {
//            if !task.complete {
//                TDAudioManager.shared.playCompletionSound()
//            }
//            do {
//                let updatedTask = task
//                updatedTask.complete = !task.complete
//                
//                let queryManager = TDQueryConditionManager()
//                let result = try await queryManager.updateLocalTaskWithModel(
//                    updatedTask: updatedTask,
//                    context: modelContext
//                )
//                
//                if result == .updated {
//                    print("切换任务状态成功: \(task.taskContent)")
//                    await TDMainViewModel.shared.performSyncSeparately()
//                } else {
//                    print("切换任务状态失败: 更新结果异常")
//                }
//            } catch {
//                print("切换任务状态失败: \(error)")
//            }
//        }
//    }
//    
//    /// 置顶任务
//    private func moveToTop() {
//        print("置顶任务: \(task.taskContent)")
//        handleMoveTask(isToTop: true)
//    }
//    
//    /// 置底任务
//    private func moveToBottom() {
//        print("置底任务: \(task.taskContent)")
//        handleMoveTask(isToTop: false)
//    }
//    
//    /// 删除任务
//    private func deleteTask() {
//        print("删除任务: \(task.taskContent)")
//        
//        Task {
//            do {
//                let updatedTask = task
//                updatedTask.delete = true
//                
//                let queryManager = TDQueryConditionManager()
//                let result = try await queryManager.updateLocalTaskWithModel(
//                    updatedTask: updatedTask,
//                    context: modelContext
//                )
//                
//                print("删除任务成功，结果: \(result)")
//                await TDMainViewModel.shared.performSyncSeparately()
//            } catch {
//                print("删除任务失败: \(error)")
//            }
//        }
//    }
//    
//    /// 处理任务移动（置顶或置底）
//    private func handleMoveTask(isToTop: Bool) {
//        if let repeatId = task.standbyStr1, !repeatId.isEmpty {
//            Task {
//                await showRepeatTaskAlertWithCount(isToTop: isToTop, repeatId: repeatId)
//            }
//        } else {
//            performMoveTask(isToTop: isToTop, isRepeatGroup: false)
//        }
//    }
//    
//    /// 显示重复事件操作弹窗（带数量）
//    @MainActor
//    private func showRepeatTaskAlertWithCount(isToTop: Bool, repeatId: String) async {
//        do {
//            let queryManager = TDQueryConditionManager()
//            let duplicateTasks = try await queryManager.getDuplicateTasks(
//                standbyStr1: repeatId,
//                onlyUncompleted: false,
//                context: modelContext
//            )
//            
//            let action = isToTop ? "置顶" : "置底"
//            let alert = NSAlert()
//            alert.messageText = "重复事件操作"
//            alert.informativeText = "是否对该重复组的\(duplicateTasks.count)个事件进行批量\(action)操作？"
//            alert.alertStyle = .informational
//            alert.addButton(withTitle: "仅该事件")
//            alert.addButton(withTitle: "确定")
//            alert.addButton(withTitle: "取消")
//            
//            let response = alert.runModal()
//            switch response {
//            case .alertFirstButtonReturn:
//                performMoveTask(isToTop: isToTop, isRepeatGroup: false)
//            case .alertSecondButtonReturn:
//                performMoveTask(isToTop: isToTop, isRepeatGroup: true, duplicateTasks: duplicateTasks)
//            case .alertThirdButtonReturn:
//                break
//            default:
//                break
//            }
//        } catch {
//            print("获取重复事件失败: \(error)")
//            performMoveTask(isToTop: isToTop, isRepeatGroup: false)
//        }
//    }
//    
//    /// 执行任务移动操作
//    private func performMoveTask(isToTop: Bool, isRepeatGroup: Bool, duplicateTasks: [TDMacSwiftDataListModel]? = nil) {
//        let action = isToTop ? "置顶" : "置底"
//        let scope = isRepeatGroup ? "重复组" : "单个"
//        
//        print("\(action)任务: \(task.taskContent) (\(scope))")
//        
//        Task {
//            if isRepeatGroup, let duplicateTasks = duplicateTasks {
//                print("开始批量\(action) \(duplicateTasks.count) 个重复事件")
//                await performBatchMove(duplicateTasks: duplicateTasks, isToTop: isToTop)
//            } else {
//                await performSingleMove(task: task, isToTop: isToTop)
//            }
//        }
//    }
//    
//    // MARK: - 移动操作实现
//    
//    /// 执行批量移动操作
//    private func performBatchMove(duplicateTasks: [TDMacSwiftDataListModel], isToTop: Bool) async {
//        let action = isToTop ? "置顶" : "置底"
//        
//        do {
//            for task in duplicateTasks {
//                await moveSingleTask(task: task, isToTop: isToTop)
//            }
//            
//            try modelContext.save()
//            print("批量\(action)完成，共处理 \(duplicateTasks.count) 个任务")
//        } catch {
//            print("批量\(action)失败: \(error)")
//        }
//    }
//    
//    /// 执行单个任务移动操作
//    private func performSingleMove(task: TDMacSwiftDataListModel, isToTop: Bool) async {
//        do {
//            await moveSingleTask(task: task, isToTop: isToTop)
//            try modelContext.save()
//        } catch {
//            print("移动任务失败: \(error)")
//        }
//    }
//    
//    /// 移动单个任务的核心逻辑
//    private func moveSingleTask(task: TDMacSwiftDataListModel, isToTop: Bool) async {
//        let queryManager = TDQueryConditionManager()
//        let action = isToTop ? "置顶" : "置底"
//        
//        do {
//            let newTaskSort: Decimal
//            let randomValue = TDAppConfig.randomTaskSort()
//            
//            if isToTop {
//                let minTaskSort = try await queryManager.getMinTaskSortForDate(
//                    todoTime: task.todoTime,
//                    context: modelContext
//                )
//                
//                if minTaskSort == 0 {
//                    newTaskSort = TDAppConfig.defaultTaskSort
//                } else if minTaskSort > TDAppConfig.maxTaskSort * 2.0 {
//                    newTaskSort = minTaskSort - randomValue
//                } else {
//                    newTaskSort = minTaskSort / 2.0
//                }
//            } else {
//                let maxTaskSort = try await queryManager.getMaxTaskSortForDate(
//                    todoTime: task.todoTime,
//                    context: modelContext
//                )
//                newTaskSort = maxTaskSort + randomValue
//            }
//            
//            let updatedTask = task
//            updatedTask.taskSort = newTaskSort
//            
//            let result = try await queryManager.updateLocalTaskWithModel(
//                updatedTask: updatedTask,
//                context: modelContext
//            )
//            
//            if result == .updated {
//                print("\(action)任务成功: \(task.taskContent), 新 taskSort: \(newTaskSort)")
//                await TDMainViewModel.shared.performSyncSeparately()
//            } else {
//                print("\(action)任务失败: 更新结果异常")
//            }
//        } catch {
//            print("\(action)任务失败: \(error)")
//        }
//    }
//    
//    /// 处理创建副本的逻辑
//    private func handleCreateCopy(copyType: CopyType) {
//        print("📋 开始创建副本，类型: \(copyType)，任务: \(task.taskContent)")
//        
//        Task {
//            do {
//                let copiedTask = task
//                copiedTask.taskId = TDAppConfig.generateTaskId()
//                copiedTask.standbyStr1 = ""
//                
//                switch copyType {
//                case .normal:
//                    print("📅 创建副本 - 保持原日期: \(task.todoTime)")
//                case .toToday:
//                    copiedTask.todoTime = Date().startOfDayTimestamp
//                case .toSpecificDate:
//                    copiedTask.todoTime = selectedCopyDate.startOfDayTimestamp
//                }
//                
//                let queryManager = TDQueryConditionManager()
//                let result = try await queryManager.addLocalTask(copiedTask, context: modelContext)
//                
//                if result == .added {
//                    await TDMainViewModel.shared.performSyncSeparately()
//                    print("✅ 创建副本成功，新任务ID: \(copiedTask.taskId)")
//                } else {
//                    print("❌ 创建副本失败，结果: \(result)")
//                }
//            } catch {
//                print("❌ 创建副本失败: \(error)")
//            }
//        }
//    }
//    
//    // MARK: - Equatable 实现（深度优化）
//    
//    static func == (lhs: TDTaskRowView, rhs: TDTaskRowView) -> Bool {
//        // 深度优化：只比较真正影响渲染的关键属性，按重要性排序
//        guard lhs.task.taskId == rhs.task.taskId else { return false }
//        guard lhs.task.complete == rhs.task.complete else { return false }
//        guard lhs.task.taskContent == rhs.task.taskContent else { return false }
//        guard lhs.task.isSubOpen == rhs.task.isSubOpen else { return false }
//        guard lhs.isHovered == rhs.isHovered else { return false }
//        guard lhs.isSelected == rhs.isSelected else { return false }
//        guard lhs.isMultiSelectMode == rhs.isMultiSelectMode else { return false }
//        
//        // 只在必要时比较复杂属性
//        if lhs.task.taskDescribe != rhs.task.taskDescribe { return false }
//        if lhs.task.subTaskList != rhs.task.subTaskList { return false }
//        
//        return true
//    }
//}
//
//#Preview {
//    let testTask = TDMacSwiftDataListModel(
//        id: 1,
//        taskId: "test",
//        taskContent: "这是一个测试任务，内容比较长，用来测试多行显示效果",
//        taskDescribe: "这是任务的详细描述，用来测试描述显示功能",
//        complete: false,
//        createTime: Date.currentTimestamp,
//        delete: false,
//        reminderTime: Date.currentTimestamp,
//        snowAdd: 0,
//        snowAssess: 7,
//        standbyInt1: 0,
//        standbyStr1: "每天",
//        standbyStr2: "[{\"isComplete\":false,\"content\":\"子任务1\"},{\"isComplete\":true,\"content\":\"子任务2\"}]",
//        standbyStr3: nil,
//        standbyStr4: "[{\"downloading\":false,\"name\":\"附件1.pdf\",\"size\":\"1.2MB\",\"suffix\":\"pdf\",\"url\":\"http://example.com\"}]",
//        syncTime: Date.currentTimestamp,
//        taskSort: 1000,
//        todoTime: Date.currentTimestamp,
//        userId: 1,
//        version: 1
//    )
//    
//    // 设置子任务和附件列表
//    testTask.subTaskList = [
//        TDMacSwiftDataListModel.SubTask(isComplete: false, content: "子任务1"),
//        TDMacSwiftDataListModel.SubTask(isComplete: true, content: "子任务2")
//    ]
//    
//    testTask.attachmentList = [
//        TDMacSwiftDataListModel.Attachment(
//            downloading: false,
//            name: "附件1.pdf",
//            size: "1.2MB",
//            suffix: "pdf",
//            url: "http://example.com"
//        )
//    ]
//    
//    return TDTaskRowView(task: testTask, category: nil, orderNumber: nil, isFirstRow: true, isLastRow: true)
//        .environmentObject(TDThemeManager.shared)
//}
