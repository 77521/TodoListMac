//
//  TDMoreOptionsButtonView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//



import SwiftUI
import SwiftData

/// 更多选项按钮组件
/// 用于显示任务的更多操作选项
struct TDMoreOptionsButtonView: View {
    
    // MARK: - 数据绑定
    @Bindable var task: TDMacSwiftDataListModel  // 当前任务数据（可绑定修改）
    @EnvironmentObject private var themeManager: TDThemeManager  // 主题管理器
    @Environment(\.modelContext) private var modelContext  // SwiftData 数据上下文
    
    // MARK: - 状态变量
    @State private var showDatePickerForCopy = false  // 控制复制日期选择器显示
    @State private var showDeleteAlert = false  // 控制删除确认弹窗显示
    @State private var pendingDeleteType: TDDataOperationManager.DeleteType? = nil  // 待删除类型
    @State private var selectedCopyDate = Date()  // 选中的复制日期
    
    // MARK: - 计算属性
    /// 判断当前任务是否为今天
    private var isToday: Bool {
        let today = Date()
        let taskDate = Date.fromTimestamp(task.todoTime)
        return Calendar.current.isDate(today, inSameDayAs: taskDate)
    }
    
    // MARK: - 回调
    let onMoreOptionsSet: () -> Void  // 更多选项操作完成回调（仅用于同步数据）
    let onShowToast: (String) -> Void  // 显示Toast回调
    
    // MARK: - 主视图
    var body: some View {
        Menu {
            // 复制内容功能
            Button("复制内容") {
                handleCopyContent()  // 复制任务内容到剪贴板
            }
            
            // 创建副本子菜单
            Menu("创建副本") {
                // 创建副本 - 保持原日期
                Button("创建副本") {
                    handleCreateCopy(copyType: .normal)
                }
                
                // 根据当前任务的日期判断是否显示"创建到今天"
                if !isToday {
                    Button("创建到今天") {
                        handleCreateCopy(copyType: .toToday)
                    }
                }
                
                // 创建副本到指定日期
                Button("创建到指定日期") {
                    showDatePickerForCopy = true  // 显示日期选择器
                }
            }
            
            // 描述转为子任务功能
            if !(task.taskDescribe?.isEmpty ?? true) {
                Button("描述转为子任务") {
                    // TODO: 实现描述转为子任务功能
                    print("描述转为子任务")
                    handleDescriptionToSubtasks()
                }
            }
            
            // 子任务转为描述功能
            if task.hasSubTasks {
                Button("子任务转为描述") {
                    // TODO: 实现子任务转为描述功能
                    print("子任务转为描述")
                    handleSubtasksToDescription()
                }
            }
            
            // 重复事件修改功能
            if task.hasRepeat {
                Button("修改该重复事件组的全部事件") {
                    // TODO: 实现修改该重复事件组的全部事件功能
                    print("修改该重复事件组的全部事件")
                    handleModifyRepeatTasks(modifyType: .all)
                }
                
                Button("修改该重复事件组的全部未达成事件") {
                    // TODO: 实现修改该重复事件组的全部未达成事件功能
                    print("修改该重复事件组的全部未达成事件")
                    handleModifyRepeatTasks(modifyType: .incomplete)
                }
            }

            
            Divider()  // 分割线
            
            // 删除任务功能
            if task.hasRepeat {
                // 重复事件：显示多级删除选项
                
                Menu("删除") {
                    Button("仅删除该事件") {
                        showDeleteConfirmation(deleteType: .single)
                    }
                    
                    Button("删除该重复事件组的全部事件") {
                        showDeleteConfirmation(deleteType: .all)
                    }
                    
                    Button("删除该重复事件组的全部未达成事件") {
                        showDeleteConfirmation(deleteType: .incomplete)
                    }
                }
                .foregroundColor(.red)  // 删除按钮使用红色
            } else {
                // 非重复事件：直接删除
            Button("删除",role: .destructive) {
                    showDeleteConfirmation(deleteType: .single)
                }
                .foregroundColor(.red)  // 删除按钮使用红色
            }

        } label: {
            // 更多按钮图标（三个点）
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.subtaskTextColor)
                .padding(.all, 11)
                .background(
                    Circle()
                        .fill(themeManager.secondaryBackgroundColor)
                )
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)  // 隐藏菜单指示器
        .buttonStyle(PlainButtonStyle())
        .help("更多选项")  // 鼠标悬停提示
        // 副本日期选择器弹窗
        .popover(isPresented: $showDatePickerForCopy) {
            VStack(spacing: 16) {
                Text("选择日期")
                    .font(.headline)
                
                // 图形化日期选择器
                DatePicker("选择日期", selection: $selectedCopyDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                
                // 操作按钮
                HStack(spacing: 12) {
                    Button("取消") {
                        showDatePickerForCopy = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("确定") {
                        handleCreateCopy(copyType: .toSpecificDate)
                        showDatePickerForCopy = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(width: 300, height: 400)
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {
                pendingDeleteType = nil
            }
            Button("删除", role: .destructive) {
                if let deleteType = pendingDeleteType {
                    handleDeleteTask(deleteType: deleteType)
                }
                pendingDeleteType = nil
            }
        } message: {
            if let deleteType = pendingDeleteType {
                switch deleteType {
                case .single:
                    Text("确定要删除这个任务吗？")
                case .all:
                    Text("确定要删除该重复事件组的全部事件吗？")
                case .incomplete:
                    Text("确定要删除该重复事件组的全部未达成事件吗？")
                }
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 复制任务内容到剪贴板
    private func handleCopyContent() {
        // 使用 TDDataOperationManager 复制任务内容到剪贴板
        let success = TDDataOperationManager.shared.copyTasksToClipboard([task])
        
        if success {
            // 显示复制成功提示
            onShowToast("copy_success_simple".localized)
        } else {
            onShowToast("复制任务内容失败")
        }
    }
    
    /// 处理创建副本的逻辑 - 根据不同类型创建任务副本
    /// - Parameter copyType: 副本创建类型（普通副本、到今天、到指定日期）
    private func handleCreateCopy(copyType: TDDataOperationManager.CopyType) {
        print("📋 开始创建副本，类型: \(copyType)，任务: \(task.taskContent)")
        
        Task {
            do {
                // 1. 将当前任务转换为 TDTaskModel（用于数据转换）
                let taskModel = TDTaskModel(from: task)
                
                // 2. 将 TDTaskModel 转换回新的 TDMacSwiftDataListModel 对象
                let newTask = taskModel.toSwiftDataModel()
                
                // 3. 修改副本的必要字段
                newTask.standbyStr1 = ""  // 清空重复事件ID（副本不继承重复设置）
                newTask.complete = false  // 副本默认未完成
                newTask.todoTime = getCopyTodoTime(for: copyType) // 根据类型设置日期
                
                // 4. 调用添加本地数据方法（会自动计算 taskSort、version、status 等）
                let queryManager = TDQueryConditionManager()
                let result = try await queryManager.addLocalTask(newTask, context: modelContext)
                
                if result == .added {
                    // 5. 执行数据同步到服务器
                    await TDMainViewModel.shared.performSyncSeparately()
                    
                    print("✅ 创建副本成功，新任务ID: \(newTask.taskId)")
                } else {
                    print("❌ 创建副本失败，结果: \(result)")
                }
                
            } catch {
                print("❌ 创建副本失败: \(error)")
            }
        }
    }
    
    /// 根据复制类型获取目标日期 - 计算副本任务的日期
    /// - Parameter copyType: 复制类型
    /// - Returns: 目标日期的时间戳
    private func getCopyTodoTime(for copyType: TDDataOperationManager.CopyType) -> Int64 {
        switch copyType {
        case .normal:
            // 保持原日期
            return task.todoTime
            
        case .toToday:
            // 创建到今天
            return Date().startOfDayTimestamp
            
        case .toSpecificDate:
            // 创建到指定日期
            return selectedCopyDate.startOfDayTimestamp
        }
    }
    
    /// 获取选中的复制日期
    /// - Returns: 选中的日期时间戳
    private func getSelectedCopyDate() -> Int64 {
        // TODO: 从日期选择器获取选中的日期
        // 这里暂时返回当前日期
        let selectedCopyDate = Date()
        return selectedCopyDate.startOfDayTimestamp
    }
    
    /// 显示删除确认弹窗
    /// - Parameter deleteType: 删除类型
    private func showDeleteConfirmation(deleteType: TDDataOperationManager.DeleteType) {
        pendingDeleteType = deleteType
        showDeleteAlert = true
    }
    
    /// 处理删除任务
    /// - Parameter deleteType: 删除类型
    /// 处理删除任务功能
    /// - Parameter deleteType: 删除类型（单个、全部、未达成）
    private func handleDeleteTask(deleteType: TDDataOperationManager.DeleteType) {
        print("🗑️ 开始删除任务，类型: \(deleteType)，任务: \(task.taskContent)")
        
        Task {
            // 调用通用删除方法
            await deleteTasks(deleteType: deleteType)
            
//            // 执行数据同步到服务器
//            await TDMainViewModel.shared.performSyncSeparately()
            
            print("✅ 删除任务成功，类型: \(deleteType)")
        }
    }

    
    /// 通用删除任务方法
    /// - Parameter deleteType: 删除类型（单个、全部、未达成）
    private func deleteTasks(deleteType: TDDataOperationManager.DeleteType) async {
        do {
            var tasksToDelete: [TDMacSwiftDataListModel] = []
            
            switch deleteType {
            case .single:
                // 仅删除当前任务
                tasksToDelete = [task]
                
            case .all:
                // 删除重复事件组的全部事件
                guard let repeatId = task.standbyStr1, !repeatId.isEmpty else {
                    print("❌ 重复事件ID为空，无法删除重复组")
                    // 调用回调通知父组件显示Toast
                    onShowToast("重复事件ID为空")
                    return
                }
                
                // 使用 TDQueryConditionManager 查询所有重复任务
                tasksToDelete = try await TDQueryConditionManager.shared.getDuplicateTasks(
                    standbyStr1: repeatId,
                    onlyUncompleted: false,
                    context: modelContext
                )
                
            case .incomplete:
                // 删除重复事件组的全部未达成事件
                guard let repeatId = task.standbyStr1, !repeatId.isEmpty else {
                    print("❌ 重复事件ID为空，无法删除重复组")
                    // 调用回调通知父组件显示Toast
                    onShowToast("重复事件ID为空")
                    return
                }
                
                // 使用 TDQueryConditionManager 查询未达成的重复任务
                tasksToDelete = try await TDQueryConditionManager.shared.getDuplicateTasks(
                    standbyStr1: repeatId,
                    onlyUncompleted: true,
                    context: modelContext
                )
            }
            
            // 标记所有任务为删除状态
            for taskToDelete in tasksToDelete {
                taskToDelete.delete = true
                _ = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(
                    updatedTask: taskToDelete,
                    context: modelContext
                )
            }
            // 调用回调通知父组件显示Toast
            onShowToast("删除成功")
            // 得通知上层 调用同步啊
            onMoreOptionsSet()
            
        } catch {
            print("❌ 删除任务失败: \(error)")
            // 调用回调通知父组件显示Toast
            onShowToast("删除任务失败")
        }
    }
    
    /// 处理描述转为子任务功能
    private func handleDescriptionToSubtasks() {
        
        // 按回车符对描述内容进行拆分
        let lines = (task.taskDescribe ?? "").components(separatedBy: .newlines)
        
        // 处理拆分后的字符串：前后去空格，移除空字符
        var validSubtasks: [String] = []
        var remainingDescription = ""
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳过空字符
            if trimmedLine.isEmpty {
                continue
            }
            
            // 检查单个子任务长度限制（80字符）
            if trimmedLine.count > 80 {
                // 超过长度限制的字符串保留在描述里
                if !remainingDescription.isEmpty {
                    remainingDescription += "\n"
                }
                remainingDescription += line
            } else {
                validSubtasks.append(trimmedLine)
            }
        }
        
        // 检查子任务数量限制（最大20个）
        let currentSubtaskCount = task.subTaskList.count
        let totalCount = currentSubtaskCount + validSubtasks.count
        
        // 检查子任务数量是否超过限制（最大20个）
        if totalCount > 20 {
            // 情况1：超过数量限制，需要部分转换
            
            // 计算还可以添加多少个子任务（20 - 当前已有的子任务数量）
            let canAddCount = 20 - currentSubtaskCount
            
            // 检查是否还有空间可以添加子任务
            if canAddCount > 0 {
                // 情况1.1：还有空间，可以进行部分转换
                
                // 从待转换的子任务中取出可以添加的数量（取前canAddCount个）
                let subtasksToAdd = Array(validSubtasks.prefix(canAddCount))
                // 将可以添加的子任务添加到任务中
                addSubtasksToTask(subtasksToAdd)
                task.standbyStr2 = task.generateSubTasksString()
                // 处理剩余无法转换的子任务
                // 计算剩余的子任务（从第canAddCount+1个开始到最后）
                let remainingSubtasks = Array(validSubtasks.suffix(validSubtasks.count - canAddCount))
                // 将剩余的子任务重新放回描述中
                for subtask in remainingSubtasks {
                    // 如果描述不为空，先添加换行符
                    if !remainingDescription.isEmpty {
                        remainingDescription += "\n"
                    }
                    // 添加剩余的子任务内容到描述中
                    remainingDescription += subtask
                }
                
                // 更新任务的描述内容（包含无法转换的子任务）
                task.taskDescribe = remainingDescription
                // 调用回调通知父组件同步数据和显示Toast
                onShowToast("convert_success".localized)
                onMoreOptionsSet()
            } else {
                // 情况1.2：没有空间，无法添加任何子任务
                // 调用回调通知父组件显示Toast
                onShowToast("subtask_limit_reached".localized)
            }
        } else {
            // 情况2：没有超过数量限制，可以进行全部转换
            
            // 将所有有效的子任务添加到任务中
            addSubtasksToTask(validSubtasks)
            
            // 更新描述内容
            // 如果还有无法转换的内容（长度超过80字符的），保留在描述中
            // 如果没有无法转换的内容，描述会被清空
            task.taskDescribe = remainingDescription
            // 调用回调通知父组件同步数据和显示Toast
            onShowToast("convert_success".localized)
            onMoreOptionsSet()
            

        }
    }

    /// 添加子任务到任务中
    /// - Parameter subtasks: 要添加的子任务文本数组
    private func addSubtasksToTask(_ subtasks: [String]) {
        for (_, subtaskText) in subtasks.enumerated() {
            let newSubtask = TDMacSwiftDataListModel.SubTask(
                isComplete: false, // 临时ID，保存时会自动生成
                content: subtaskText,
                id: "0"
            )
            task.subTaskList.append(newSubtask)
            
        }
    }

    
    /// 处理子任务转为描述功能
    private func handleSubtasksToDescription() {
        
        // 将所有子任务进行拼接
        let subtaskTexts = task.subTaskList.map { $0.content }
        let newDescriptionText = subtaskTexts.joined(separator: "\n")
        
        // 检查描述最大长度限制（假设最大长度为1000字符）
        let maxDescriptionLength = 800
        let currentDescriptionLength = (task.taskDescribe ?? "").count
        let newTextLength = newDescriptionText.count
        let totalLength = currentDescriptionLength + newTextLength
        
        if totalLength > maxDescriptionLength {
            // 调用回调通知父组件显示Toast
            onShowToast("description_length_exceeded".localized)
            return
        }
        
        // 执行转换
        if !(task.taskDescribe?.isEmpty ?? true) {
            task.taskDescribe = (task.taskDescribe ?? "") + "\n" + newDescriptionText
        } else {
            task.taskDescribe = newDescriptionText
        }

        // 清空子任务列表
        task.subTaskList.removeAll()
        task.standbyStr2  = ""
        
        // 调用回调通知父组件同步数据和显示Toast
        onShowToast("convert_success".localized)
        onMoreOptionsSet()
    }
    
    /// 处理修改重复事件功能
    /// - Parameter modifyType: 修改类型（全部、未达成）
    private func handleModifyRepeatTasks(modifyType: TDDataOperationManager.ModifyType) {
        print("🔧 开始修改重复事件，类型: \(modifyType)，任务: \(task.taskContent)")
        
        Task {
            do {
                var tasksToModify: [TDMacSwiftDataListModel] = []
                
                switch modifyType {
                case .all:
                    // 修改重复事件组的全部事件
                    guard let repeatId = task.standbyStr1, !repeatId.isEmpty else {
                        print("❌ 重复事件ID为空，无法修改重复组")
                        onShowToast("重复事件ID为空")
                        return
                    }
                    
                    // 使用 TDQueryConditionManager 查询所有重复任务
                    tasksToModify = try await TDQueryConditionManager.shared.getDuplicateTasks(
                        standbyStr1: repeatId,
                        onlyUncompleted: false,
                        context: modelContext
                    )
                    
                case .incomplete:
                    // 修改重复事件组的全部未达成事件
                    guard let repeatId = task.standbyStr1, !repeatId.isEmpty else {
                        print("❌ 重复事件ID为空，无法修改重复组")
                        onShowToast("重复事件ID为空")
                        return
                    }
                    
                    // 使用 TDQueryConditionManager 查询未达成的重复任务
                    tasksToModify = try await TDQueryConditionManager.shared.getDuplicateTasks(
                        standbyStr1: repeatId,
                        onlyUncompleted: true,
                        context: modelContext
                    )
                }
                
                // 从查询结果中排除当前事件，只修改其他重复事件
                let tasksToModifyExcludingCurrent = tasksToModify.filter { $0.taskId != task.taskId }
                
                // 修改除当前事件外的所有重复任务
                for taskToModify in tasksToModifyExcludingCurrent {
                    // 这里可以根据需要修改任务的属性
                    // 例如：修改任务内容、描述、分类等
                    // taskToModify.taskContent = "修改后的内容"
                    taskToModify.taskContent = task.taskContent
//                    taskToModify.complete = task.complete
//                    taskToModify.delete = task.delete
                    taskToModify.standbyInt1 = task.standbyInt1
                    taskToModify.snowAssess = task.snowAssess
                    taskToModify.taskDescribe = task.taskDescribe
                    taskToModify.standbyStr2 = task.standbyStr2
                    taskToModify.snowAdd = task.snowAdd
                    taskToModify.standbyStr3 = task.standbyStr3
                    taskToModify.standbyStr4 = task.standbyStr4
                    taskToModify.standbyIntColor = task.standbyIntColor
                    taskToModify.standbyIntName = task.standbyIntName
                    taskToModify.subTaskList = task.subTaskList
                    taskToModify.attachmentList = task.attachmentList

                    if task.hasReminder {
                        let taskToModifyTodoTimeDate = Date.fromTimestamp(taskToModify.todoTime)
                        let taskReminderTimeDate = Date.fromTimestamp(task.reminderTime)
                        let reminderDate = Date.createDate(year: taskToModifyTodoTimeDate.year, month: taskToModifyTodoTimeDate.month, day: taskToModifyTodoTimeDate.day, hour: taskReminderTimeDate.hour, minute: taskReminderTimeDate.minute)
                        taskToModify.reminderTime = reminderDate.fullTimestamp
                        taskToModify.reminderTimeString = reminderDate.toString(format: "time_format_hour_minute".localized)
                    } else {
                        taskToModify.reminderTime = 0
                        taskToModify.reminderTimeString = ""
                    }
                    
                    _ = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(
                        updatedTask: taskToModify,
                        context: modelContext
                    )
                }
                
                print("✅ 修改重复事件成功，类型: \(modifyType)，共修改 \(tasksToModifyExcludingCurrent.count) 个任务（排除当前事件）")
                onShowToast("修改重复事件成功，共修改 \(tasksToModifyExcludingCurrent.count) 个任务")
                
                // 调用回调通知父组件同步数据
                onMoreOptionsSet()
                
            } catch {
                print("❌ 修改重复事件失败: \(error)")
                onShowToast("修改重复事件失败")
            }
        }
    }

    
}
// MARK: - 预览
#Preview {
    // 创建一个示例任务用于预览
    let sampleTask = TDMacSwiftDataListModel(
        id: 1,
        taskId: "preview_task",
        taskContent: "预览任务",
        taskDescribe: "这是一个预览任务",
        complete: false,
        createTime: Date().startOfDayTimestamp,
        delete: false,
        reminderTime: 0,
        snowAdd: 0,
        snowAssess: 0,
        standbyInt1: 1, // 分类ID，在事件内使用standbyInt1
        standbyStr1: nil,
        standbyStr2: nil,
        standbyStr3: nil,
        standbyStr4: nil,
        syncTime: Date().startOfDayTimestamp,
        taskSort: Decimal(1),
        todoTime: Date().startOfDayTimestamp,
        userId: 1,
        version: 1,
        status: "sync",
        isSubOpen: true,
        standbyIntColor: "",
        standbyIntName: "",
        reminderTimeString: "",
        subTaskList: [],
        attachmentList: []
    )

    TDMoreOptionsButtonView(
        task: sampleTask
    ) {
        print("更多选项操作完成，需要同步数据")
    }
    onShowToast: { message in
        print("显示Toast: \(message)")
    }
    .environmentObject(TDThemeManager.shared)
}
