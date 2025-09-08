//
//  TDTaskDetailBottomToolbar.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData
import AppKit

/// 任务详情底部工具栏组件
/// 包含：选择时间、重复、附件、标签、更多按钮
struct TDTaskDetailBottomToolbar: View {
    // MARK: - 数据绑定和依赖注入
    @Bindable var task: TDMacSwiftDataListModel  // 当前任务数据（可绑定修改）
    @EnvironmentObject private var themeManager: TDThemeManager  // 主题管理器
    @Environment(\.modelContext) private var modelContext  // SwiftData 数据上下文
    
    // MARK: - 状态变量
    @State private var showDatePickerForCopy = false  // 是否显示副本日期选择器
    @State private var selectedCopyDate = Date()  // 选中的副本日期
    @State private var showCopySuccessToast = false  // 是否显示复制成功提示
    @State private var showTimePicker = false  // 是否显示时间选择器
    @State private var selectedTime = Date()  // 选中的提醒时间
    @State private var showTagView = false  // 是否显示标签选择视图
    @State private var showToast = false  // 是否显示Toast提示
    @State private var toastMessage = ""  // Toast提示内容
    @State private var showDeleteAlert = false  // 是否显示删除确认弹窗
    @State private var pendingDeleteType: DeleteType? = nil  // 待确认的删除类型
    @State private var showDocumentPicker = false  // 是否显示附件弹窗

    // MARK: - 枚举定义
    
    /// 复制类型枚举 - 定义创建副本的不同方式
    private enum CopyType {
        case normal        // 创建副本 - 保持原日期
        case toToday      // 创建副本到今天
        case toSpecificDate // 创建副本到指定日期
    }
    
    /// 删除类型枚举 - 定义不同的删除方式
    private enum DeleteType {
        case single      // 仅删除该事件
        case all         // 删除该重复事件组的全部事件
        case incomplete  // 删除该重复事件组的全部未达成事件
    }
    
    /// 自定义重复类型枚举 - 定义各种重复模式
    private enum CustomRepeatType: String, CaseIterable {
        case daily = "每天"                    // 每天重复
        case weekly = "每周"                  // 每周重复
        case workday = "每周工作日"            // 每周工作日重复
        case monthly = "每月"                 // 每月重复
        case monthlyLastDay = "每月最后一天"    // 每月最后一天重复
        case monthlyWeekday = "每月星期几"      // 每月第N个星期几重复
        case yearly = "每年"                  // 每年重复
        case lunarYearly = "每年农历"          // 每年农历重复
        case legalWorkday = "法定工作日"        // 法定工作日重复
        case ebbinghaus = "艾宾浩斯记忆法"      // 艾宾浩斯记忆法重复
    }
    
    // MARK: - 计算属性
    
    /// 判断任务日期是否是今天
    private var isToday: Bool {
        return task.taskDate.isToday
    }
    
    // MARK: - 主视图
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // MARK: - 选择时间按钮（第一个按钮）
            Button(action: {
                showTimePicker = true  // 显示时间选择器弹窗
            }) {
                
                // 有提醒时间时显示时间信息
                HStack(spacing: 0) {
                    // 时钟图标
                    Image(systemName: "alarm")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(task.hasReminder ? themeManager.color(level: 5) : themeManager.subtaskTextColor)
                        .padding(.all,8)
                        .background(
                            Circle()
                                .fill(themeManager.secondaryBackgroundColor)
                            //                                .fill(.red)
                        )
                    
                    if task.hasReminder {
                        // 提醒时间文字（如：23:42）
                        Text(task.reminderTimeString)
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.color(level: 5))
                        
                        // 清除提醒时间按钮
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                task.reminderTime = 0  // 清除提醒时间
                                task.reminderTimeString = ""
                            }
                            syncTaskData(operation: "清除提醒时间")
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.descriptionTextColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.leading,6)
                    }
                }
                .padding(.vertical,0)
                .padding(.leading,0)
                .padding(.trailing,task.hasReminder ? 8 : 0)
                .background(
                    RoundedRectangle(cornerRadius: 17)
                        .fill(task.hasReminder ? themeManager.secondaryBackgroundColor : Color.clear)
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.1, anchor: .leading).combined(with: .opacity),
                    removal: .scale(scale: 0.1, anchor: .leading).combined(with: .opacity)
                ))
            }
            .animation(.easeInOut(duration: 0.15), value: task.hasReminder)  // 添加状态变化动画
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showTimePicker, attachmentAnchor: .point(.top)) {
                VStack(spacing: 16) {
                    // 顶部：标题
                    Text("选择时间")
                        .font(.headline)
                    
                    // 中间：时间选择器（居中显示）
                    HStack {
                        Spacer()
                        
                        // 时间选择器（根据系统设置自动显示24小时制或12小时制）
                        DatePicker("选择时间", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                        
                        Spacer()
                    }
                    
                    // 底部：操作按钮
                    HStack(spacing: 12) {
                        Button("取消") {
                            showTimePicker = false
                        }
                        .buttonStyle(.bordered)
                        
                        Button("设定") {
                            handleTimeSelection()  // 处理时间选择
                            showTimePicker = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .frame(width: 200, height: 140)
            }
            .help("选择时间")  // 鼠标悬停提示
            
            // MARK: - 重复按钮（第二个按钮）
            if task.hasRepeat {
                // MARK: - 选择时间按钮（第一个按钮）
                Button(action: {
                    
                }) {
                    
                    HStack(spacing: 6) {
                        Image(systemName: "repeat")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(task.hasRepeat ? themeManager.color(level: 5) : themeManager.subtaskTextColor)
                        
                        Text("重复")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.color(level: 5))
                    }
                    .padding(.vertical,8)
                    .padding(.horizontal,8)
                    .background(
                        RoundedRectangle(cornerRadius: 17)
                            .fill(themeManager.secondaryBackgroundColor)
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.1, anchor: .leading).combined(with: .opacity),
                        removal: .scale(scale: 0.1, anchor: .leading).combined(with: .opacity)
                    ))
                }
                .animation(.easeInOut(duration: 0.15), value: task.hasReminder)  // 添加状态变化动画
                .buttonStyle(PlainButtonStyle())
                .help("查看重复任务")  // 鼠标悬停提示

            } else {
                Menu {
                    // 自定义重复设置选项
                    Button("自定义重复设置") {
                        // TODO: 显示自定义重复设置弹窗
                        print("显示自定义重复设置弹窗")
                    }
                    
                    Divider()  // 分割线
                    
                    // 基础重复选项
                    Button("每天") {
                        handleCustomRepeat(repeatType: .daily)
                    }
                    
                    // 每周重复（显示任务日期的星期几）
                    Button("每周 (\(task.taskDate.weekdayDisplay()))") {
                        handleCustomRepeat(repeatType: .weekly)
                    }
                    
                    // 每周工作日重复（周一至周五）
                    Button("每周工作日 (周一至周五)") {
                        handleCustomRepeat(repeatType: .workday)
                    }
                    
                    // 每月重复（显示任务日期的几号）
                    Button("每月 (\(task.taskDate.dayOfMonth())日)") {
                        handleCustomRepeat(repeatType: .monthly)
                    }
                    
                    // 每月最后一天重复
                    Button("每月 (最后一天)") {
                        handleCustomRepeat(repeatType: .monthlyLastDay)
                    }
                    
                    // 每月第N个星期几重复
                    Button("每月 (第 \(task.taskDate.weekdayOrdinal()) 个 \(task.taskDate.weekdayDisplay()))") {
                        handleCustomRepeat(repeatType: .monthlyWeekday)
                    }
                    
                    // 每年重复（显示任务日期的月日）
                    Button("每年 (\(task.taskDate.monthDayString()))") {
                        handleCustomRepeat(repeatType: .yearly)
                    }
                    
                    // 每年农历重复（显示任务日期的农历月日）
                    Button("每年 (\(task.taskDate.lunarMonthDayString()))") {
                        handleCustomRepeat(repeatType: .lunarYearly)
                    }
                    
                    Divider()  // 分割线
                    
                    // 高级重复选项
                    Button("法定工作日") {
                        handleCustomRepeat(repeatType: .legalWorkday)
                    }
                    
                    Button("艾宾浩斯记忆法") {
                        handleCustomRepeat(repeatType: .ebbinghaus)
                    }
                } label: {
                    Image(systemName: "repeat")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(task.hasRepeat ? themeManager.color(level: 5) : themeManager.subtaskTextColor)
                        .padding(.all,8)
                        .background(
                            Circle()
                                .fill(themeManager.secondaryBackgroundColor)
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.1, anchor: .leading).combined(with: .opacity),
                            removal: .scale(scale: 0.1, anchor: .leading).combined(with: .opacity)
                        ))
                }
                .menuStyle(.button)
                .menuIndicator(.hidden)  // 隐藏菜单指示器
                .buttonStyle(PlainButtonStyle())
                .help("设置重复任务")  // 鼠标悬停提示
                
            }
            
            // MARK: - 附件按钮（第三个按钮）
            Button(action: {
                handleAttachmentButtonClick()

            }) {
                
                HStack(spacing: 0) {
                    // 文档图标
                    Image(systemName: "text.document")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(task.hasAttachment ? themeManager.color(level: 5) : themeManager.subtaskTextColor)
                        .padding(.all,8)
                        .background(
                            Circle()
                                .fill(themeManager.secondaryBackgroundColor)
                        )
                    
                    if task.hasAttachment {
                        // 附件数量文字（如：附件 1）
                        Text("附件 \(task.attachmentList.count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.color(level: 5))
                    }
                }
                .padding(.vertical,0)
                .padding(.leading,0)
                .padding(.trailing,task.hasAttachment ? 8 : 0)
                .background(
                    RoundedRectangle(cornerRadius: 17)
                        .fill(task.hasAttachment ? themeManager.secondaryBackgroundColor : Color.clear)
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.1, anchor: .leading).combined(with: .opacity),
                    removal: .scale(scale: 0.1, anchor: .leading).combined(with: .opacity)
                ))
                
            }
            .buttonStyle(PlainButtonStyle())
            .help("选择附件")  // 鼠标悬停提示
            
            // MARK: - 标签按钮（第四个按钮）
            //            Button(action: {
            //                showTagView = true  // 显示标签选择弹窗
            //            }) {
            //                // 标签按钮始终显示灰色圆形图标（#号图标）
            //                Image(systemName: "number")
            //                    .font(.system(size: 16))
            //                    .foregroundColor(themeManager.descriptionTextColor)
            //                    .frame(width: 32, height: 32)
            //                    .background(
            //                        Circle()
            //                            .fill(themeManager.secondaryBackgroundColor)
            //                    )
            //            }
            //            .buttonStyle(PlainButtonStyle())
            //            .help("标签")  // 鼠标悬停提示
            
            Spacer()  // 弹性空间，将更多按钮推到右边
            
            // MARK: - 更多选项按钮（右边按钮）
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
        }
        .padding(.horizontal, 12)  // 左右内边距
        .padding(.vertical, 10)    // 上下内边距
        .background(Color(.controlBackgroundColor))  // 工具栏背景色
        .overlay(
            // 顶部边框线
            Rectangle()
                .frame(height: 1)
                .foregroundColor(themeManager.separatorColor),
            alignment: .top
        )
        // MARK: - 弹窗组件
        
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
        
        // 标签选择弹窗
        .popover(isPresented: $showTagView) {
            VStack(spacing: 16) {
                Text("选择标签")
                    .font(.headline)
                
                // 标签功能预留位置
                Text("标签功能开发中...")
                    .foregroundColor(themeManager.descriptionTextColor)
                
                Button("确定") {
                    showTagView = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(width: 250, height: 150)
        }
        // 复制成功提示弹窗
        .tdToastBottom(
            isPresenting: $showCopySuccessToast,
            message: "copy_success_simple".localized,
            type: .success
        )
        // 通用Toast提示弹窗
        .tdToastBottom(
            isPresenting: $showToast,
            message: toastMessage,
            type: .info
        )
        // 文档选择器
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            handleDocumentSelection(result: result)
        }
        // 删除确认弹窗
        .alert("删除确认", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {
                pendingDeleteType = nil
            }
            Button("确认", role: .destructive) {
                if let deleteType = pendingDeleteType {
                    handleDeleteTask(deleteType: deleteType)
                }
                pendingDeleteType = nil
            }
        } message: {
            if let deleteType = pendingDeleteType {
                switch deleteType {
                case .single:
                    Text("确定要删除该事件？")
                case .all:
                    Text("确定进行批量删除吗？")
                case .incomplete:
                    Text("确定删除该重复事件组的全部未达成事件吗？")
                }
            }
        }

    }
    
    // MARK: - 私有方法
    
    /// 处理时间选择 - 将用户选择的时间设置为提醒时间
    private func handleTimeSelection() {
        // 获取任务的日期（从 todoTime 获取年月日）
        // 获取任务的日期（从 todoTime 获取年月日）
        let taskDate = Date.fromTimestamp(task.todoTime)
        
        // 从用户选择的时间中获取时分（使用新的扩展方法）
        let selectedHour = selectedTime.hour    // 获取选中的小时
        let selectedMinute = selectedTime.minute  // 获取选中的分钟
        
        // 创建提醒时间：使用任务的年月日 + 用户选择的时分（使用新的扩展方法）
        let reminderDate = Date.createDate(
            year: taskDate.year,
            month: taskDate.month,
            day: taskDate.day,
            hour: selectedHour,
            minute: selectedMinute,
            second: 0
        )
        // 打印时间日期信息（转换为字符串格式）
        print("⏰ 设置提醒时间:")
        print("- 任务日期: \(taskDate.toString(format: "yyyy-MM-dd"))")
        print("- 选中的时间: \(selectedTime.toString(format: "HH:mm"))")
        print("- 提醒日期: \(reminderDate.toString(format: "yyyy-MM-dd HH:mm:ss"))")
        print("- 提醒时间戳: \(reminderDate.fullTimestamp)")
        print("- 任务内容: \(task.taskContent)")
        // 使用动画设置提醒时间
        withAnimation(.easeInOut(duration: 0.3)) {
            task.reminderTime = reminderDate.fullTimestamp  // 设置任务的提醒时间
            task.reminderTimeString = Date.timestampToString(timestamp: task.reminderTime, format: "HH:mm")
        }
        
        print("- 最终提醒时间：\(Date.timestampToString(timestamp: task.reminderTime, format: "yyyy.MM.dd HH:mm:ss"))")
        
        // 在本地日历中添加提醒事件
        Task {
            do {
                try await TDCalendarService.shared.handleReminderEvent(task: task)
                print("✅ 本地日历提醒事件添加成功")
            } catch {
                print("❌ 本地日历提醒事件添加失败: \(error)")
            }
        }
        syncTaskData(operation: "设置提醒时间")  // 同步数据到数据库
    }
    
    /// 同步任务数据到数据库和服务器
    /// - Parameter operation: 操作描述，用于日志记录
    private func syncTaskData(operation: String) {
        Task {
            do {
                // 更新本地数据库
                _ = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(
                    updatedTask: task,
                    context: modelContext
                )
                
                // 执行数据同步到服务器
                await TDMainViewModel.shared.performSyncSeparately()
                
                print("✅ \(operation)成功")
            } catch {
                print("❌ \(operation)失败: \(error)")
            }
        }
    }
    
    /// 处理创建副本的逻辑 - 根据不同类型创建任务副本
    /// - Parameter copyType: 副本创建类型（普通副本、到今天、到指定日期）
    private func handleCreateCopy(copyType: CopyType) {
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
    
    /// 处理复制内容 - 将任务内容复制到剪贴板
    private func handleCopyContent() {
        // 使用 TDDataOperationManager 复制任务内容到剪贴板
        let success = TDDataOperationManager.shared.copyTasksToClipboard([task])
        
        if success {
            // 显示复制成功提示
            showCopySuccessToast = true
            print("✅ 任务内容已复制到剪贴板")
        } else {
            print("❌ 复制任务内容失败")
        }
    }
    
    /// 根据复制类型获取目标日期 - 计算副本任务的日期
    /// - Parameter copyType: 复制类型
    /// - Returns: 目标日期的时间戳
    private func getCopyTodoTime(for copyType: CopyType) -> Int64 {
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
    
    
    // MARK: - 重复任务相关方法
    
    /// 根据重复类型计算72个重复日期 - 生成重复任务的日期列表
    /// - Parameters:
    ///   - repeatType: 重复类型
    ///   - count: 重复次数（固定为72）
    ///   - startDate: 开始日期
    /// - Returns: 重复日期数组
    private func getRepeatDates(for repeatType: CustomRepeatType, count: Int, startDate: Date) -> [Date] {
        var dates: [Date] = []
        let currentDate = startDate
        
        switch repeatType {
        case .daily:
            // 每天重复：连续72天
            for i in 0..<count {
                dates.append(currentDate.adding(days: i))
            }
            
        case .weekly:
            // 每周重复：下个同一天，72周
            let currentWeekday = Calendar.current.component(.weekday, from: currentDate)
            for i in 0..<count {
                dates.append(currentDate.nextWeekday(currentWeekday, weeksLater: i))
            }
            
        case .workday:
            // 每周工作日重复：下个工作日，72个工作日
            for i in 0..<count {
                if i == 0 {
                    dates.append(currentDate.nextWorkday())
                } else {
                    let lastDate = dates.last!
                    dates.append(lastDate.nextWorkday())
                }
            }
            
        case .monthly:
            // 每月重复：下个月同一天，72个月
            let currentDay = Calendar.current.component(.day, from: currentDate)
            for i in 0..<count {
                dates.append(currentDate.nextMonthDay(currentDay, monthsLater: i))
            }
            
        case .monthlyLastDay:
            // 每月最后一天重复：下个月最后一天，72个月
            for i in 0..<count {
                dates.append(currentDate.nextMonthLastDay(monthsLater: i))
            }
            
        case .monthlyWeekday:
            // 每月第N个星期几重复：下个月第N个同星期，72个月
            let currentWeekday = Calendar.current.component(.weekday, from: currentDate)
            let ordinal = currentDate.weekdayOrdinal()
            for i in 0..<count {
                dates.append(currentDate.nextMonthWeekday(ordinal: ordinal, weekday: currentWeekday, monthsLater: i))
            }
            
        case .yearly:
            // 每年重复：下一年同月日，72年
            let currentMonth = Calendar.current.component(.month, from: currentDate)
            let currentDay = Calendar.current.component(.day, from: currentDate)
            for i in 0..<count {
                dates.append(currentDate.nextYearMonthDay(month: currentMonth, day: currentDay, yearsLater: i))
            }
            
        case .lunarYearly:
            // 每年农历重复：下一年农历同月日，72年
            let currentLunar = currentDate.toLunar()
            for i in 0..<count {
                if let nextLunarDate = currentDate.nextLunarYearMonthDay(lunarMonth: currentLunar.month, lunarDay: currentLunar.day, isLeapMonth: currentLunar.isLeapMonth, yearsLater: i) {
                    dates.append(nextLunarDate)
                } else {
                    // 如果农历转换失败，使用阳历加一年
                    dates.append(currentDate.adding(years: i + 1))
                }
            }
            
        case .legalWorkday:
            // 法定工作日重复：下个工作日，72个工作日
            for i in 0..<count {
                if i == 0 {
                    dates.append(currentDate.nextWorkday())
                } else {
                    let lastDate = dates.last!
                    dates.append(lastDate.nextWorkday())
                }
            }
            
        case .ebbinghaus:
            // 艾宾浩斯记忆法重复：1, 2, 4, 7, 15, 30天后，然后循环
            let intervals = [1, 2, 4, 7, 15, 30]  // 记忆间隔天数
            var totalDays = 0
            
            for i in 0..<count {
                let intervalIndex = i % intervals.count
                totalDays += intervals[intervalIndex]
                dates.append(currentDate.adding(days: totalDays))
            }
        }
        
        return dates
    }
    
    /// 处理自定义重复 - 创建72个重复任务
    /// - Parameter repeatType: 重复类型
    private func handleCustomRepeat(repeatType: CustomRepeatType) {
        print("开始处理自定义重复，类型: \(repeatType)，将创建72个重复任务")
        
        Task {
            do {
                // 1. 计算72个重复日期
                let repeatDates = getRepeatDates(for: repeatType, count: 72, startDate: task.taskDate)
                let repeatTaskId = TDAppConfig.generateTaskId() // 重复事件使用相同的standbyStr1
                
                // 2. 创建重复任务
                for (index, repeatDate) in repeatDates.enumerated() {
                    if index == 0 {
                        // 第一个任务：更新当前任务
                        task.todoTime = repeatDate.startOfDayTimestamp
                        task.standbyStr1 = repeatTaskId
                        
                        _ = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(
                            updatedTask: task,
                            context: modelContext
                        )
                        
                    } else {
                        // 其他任务：新增重复任务
                        
                        // 1. 将当前任务转换为 TDTaskModel
                        let taskModel = TDTaskModel(from: task)
                        
                        // 2. 将 TDTaskModel 转换回新的 TDMacSwiftDataListModel 对象
                        let newTask = taskModel.toSwiftDataModel()

                        
                        newTask.todoTime = repeatDate.startOfDayTimestamp
                        newTask.standbyStr1 = repeatTaskId
                        
                        _ = try await TDQueryConditionManager.shared.addLocalTask(
                            newTask,
                            context: modelContext
                        )
                    }
                }
                
                print("✅ 自定义重复成功: 更新了1个任务，新增了71个重复任务，类型: \(repeatType.rawValue)")
                
                // 3. 执行数据同步到服务器
                await TDMainViewModel.shared.performSyncSeparately()
                
            } catch {
                print("❌ 自定义重复失败: \(error)")
            }
        }
    }
    
    /// 处理附件按钮点击
    private func handleAttachmentButtonClick() {
        // 检查附件数量限制（最多4个）
        if task.attachmentList.count >= 4 {
            showToastMessage("正在添加四个附件")
            return
        }
        
        // 显示文件选择器
        showDocumentPicker = true
    }
    
    /// 处理文档选择结果
    /// - Parameter result: 文件选择结果
    private func handleDocumentSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            // 成功选择文件
            if !urls.isEmpty {
                handleSelectedFiles(urls: urls)
            }
        case .failure(let error):
            // 选择文件失败
            print("❌ 选择文件失败: \(error)")
            showToastMessage("选择文件失败")
        }
    }
    
    /// 处理选中的文件
    /// - Parameter urls: 选中的文件URL数组
    private func handleSelectedFiles(urls: [URL]) {
        print("📎 用户选择了 \(urls.count) 个文件")
        
        for url in urls {
            print("- 文件路径: \(url.path)")
            print("- 文件名: \(url.lastPathComponent)")
            
            // 这里可以添加文件处理逻辑
            // 例如：复制文件到应用目录、保存文件信息到数据库等
            // 暂时只打印文件信息
        }
        
        // 显示选择成功提示
        showToastMessage("已选择 \(urls.count) 个文件")
        
        // TODO: 实现文件保存到任务附件的逻辑
        // 1. 复制文件到应用沙盒目录
        // 2. 保存文件信息到 task.attachmentList
        // 3. 同步数据到数据库
    }


    // MARK: - 描述与子任务转换相关方法
    
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
                // 显示部分转换成功的提示
                showToastMessage("convert_success".localized)
                // 同步数据到数据库
                syncTaskData(operation: "描述转为子任务（部分转换）")
            } else {
                // 情况1.2：没有空间，无法添加任何子任务
                showToastMessage("subtask_limit_reached".localized)
            }
        } else {
            // 情况2：没有超过数量限制，可以进行全部转换
            
            // 将所有有效的子任务添加到任务中
            addSubtasksToTask(validSubtasks)
            
            // 更新描述内容
            // 如果还有无法转换的内容（长度超过80字符的），保留在描述中
            // 如果没有无法转换的内容，描述会被清空
            task.taskDescribe = remainingDescription
            showToastMessage("convert_success".localized)
            // 同步数据到数据库
            syncTaskData(operation: "描述转为子任务")
            

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
    /// 显示Toast提示消息
    /// - Parameter message: 提示消息内容
    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
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
            showToastMessage("description_length_exceeded".localized)
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
        
        showToastMessage("convert_success".localized)
        syncTaskData(operation: "子任务转为描述")
    }
    
    // MARK: - 删除任务相关方法
    
    /// 显示删除确认弹窗
    /// - Parameter deleteType: 删除类型
    private func showDeleteConfirmation(deleteType: DeleteType) {
        pendingDeleteType = deleteType
        showDeleteAlert = true
    }

    /// 处理删除任务功能
    /// - Parameter deleteType: 删除类型（单个、全部、未达成）
    private func handleDeleteTask(deleteType: DeleteType) {
        print("🗑️ 开始删除任务，类型: \(deleteType)，任务: \(task.taskContent)")
        
        Task {
            // 调用通用删除方法
            await deleteTasks(deleteType: deleteType)
            
            // 执行数据同步到服务器
            await TDMainViewModel.shared.performSyncSeparately()
            
            print("✅ 删除任务成功，类型: \(deleteType)")
        }
    }

    
    /// 通用删除任务方法
    /// - Parameter deleteType: 删除类型（单个、全部、未达成）
    private func deleteTasks(deleteType: DeleteType) async {
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
                    showToastMessage("重复事件ID为空")
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
                    showToastMessage("重复事件ID为空")
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
            showToastMessage("删除成功")

            
        } catch {
            print("❌ 删除任务失败: \(error)")
            showToastMessage("删除任务失败")
        }
    }


}

// MARK: - 预览组件
#Preview {
    TDTaskDetailBottomToolbar(task: TDMacSwiftDataListModel(
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
    ))
    .environmentObject(TDThemeManager.shared)
}
