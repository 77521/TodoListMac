//
//  TDRepeatSettingView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import SwiftUI
import SwiftData

/// 重复设置组件
/// 用于设置任务的重复模式
struct TDRepeatSettingView: View {
    
    // MARK: - 数据绑定
    @Bindable var task: TDMacSwiftDataListModel  // 当前任务数据（可绑定修改）
    @EnvironmentObject private var themeManager: TDThemeManager  // 主题管理器
    @Environment(\.modelContext) private var modelContext  // SwiftData 数据上下文
    
    // MARK: - 回调
    let onRepeatSet: () -> Void  // 重复设置完成回调（仅用于同步数据）
    // MARK: - 状态变量
    @State private var showRepeatDataView = false  // 控制重复事件管理弹窗显示

    @State private var showCustomRepeatSetting = false  // 控制自定义重复设置弹窗显示

    
    // MARK: - 主视图
    var body: some View {
        if task.hasRepeat {
            // 如果任务已有重复，显示重复状态按钮
            Button(action: {
                // TODO: 可以添加查看重复任务的逻辑
                print("查看重复任务")
                showRepeatDataView = true
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
            .animation(.easeInOut(duration: 0.15), value: task.hasRepeat)
            .buttonStyle(PlainButtonStyle())
            .help("查看重复任务")  // 鼠标悬停提示
            .sheet(isPresented: $showRepeatDataView) {
                // 弹窗内容
                TDRepeatManagementView(isPresented: $showRepeatDataView, task: task)
                    .presentationDragIndicator(.visible)
            }

        } else {
            // 如果任务没有重复，显示重复设置菜单
            Menu {
                // 自定义重复设置选项
                Button("自定义重复设置") {
                    // TODO: 显示自定义重复设置弹窗
                    print("显示自定义重复设置弹窗")
                    showCustomRepeatSetting = true
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
                Button("每年 (\(task.taskDate.lunarMonthDay))") {
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
            .sheet(isPresented: $showCustomRepeatSetting) {
                // 自定义重复设置弹窗
                TDCustomRepeatSettingView(isPresented: $showCustomRepeatSetting,
                                          task: task,
                                          onRepeatDatesCalculated: { dates in
                    // 处理重复日期数组
                    print("收到重复日期: \(dates.count)个")
                    // 创建重复任务
                    Task {
                        do {
                            let repeatTaskId = TDAppConfig.generateTaskId()
                            try await createRepeatTasks(repeatDates: dates, repeatTaskId: repeatTaskId)
                            print("✅ 自定义重复任务创建成功: \(dates.count)个任务")
                        } catch {
                            print("❌ 自定义重复任务创建失败: \(error)")
                        }
                    }
                }
                )
                
                    .presentationDragIndicator(.visible)
            }

        }
        
    }
    
    // MARK: - 私有方法
    
    /// 处理自定义重复 - 创建72个重复任务
    /// - Parameter repeatType: 重复类型
    private func handleCustomRepeat(repeatType: TDDataOperationManager.CustomRepeatType) {
        print("开始处理自定义重复，类型: \(repeatType)，将创建72个重复任务")
        
        Task {
            do {
                // 1. 计算72个重复日期
                let repeatDates = getRepeatDates(for: repeatType, count: 72, startDate: task.taskDate)
                let repeatTaskId = TDAppConfig.generateTaskId() // 重复事件使用相同的standbyStr1
                
                
                // 2. 创建重复任务
                try await createRepeatTasks(repeatDates: repeatDates, repeatTaskId: repeatTaskId)
                
                print("✅ 自定义重复成功: 更新了1个任务，新增了71个重复任务，类型: \(repeatType.rawValue)")
                

            } catch {
                print("❌ 自定义重复失败: \(error)")
            }
        }
    }
    
    
    // MARK: - 私有方法
    
    /// 创建重复任务
    /// - Parameters:
    ///   - repeatDates: 重复日期数组
    ///   - repeatTaskId: 重复任务ID
    private func createRepeatTasks(repeatDates: [Date], repeatTaskId: String) async throws {
        for (index, repeatDate) in repeatDates.enumerated() {
            if index == 0 {
                // 第一个任务：更新当前任务
                let originalTodoTime = task.todoTime
                let newTodoTime = repeatDate.startOfDayTimestamp
                
                // 判断 todoTime 是否发生变化
                if originalTodoTime != newTodoTime {
                    print("📅 第一个任务的 todoTime 发生变化:")
                    print("  - 原始时间: \(Date.fromTimestamp(originalTodoTime).dateAndWeekString)")
                    print("  - 新时间: \(Date.fromTimestamp(newTodoTime).dateAndWeekString)")
                    print("  - 清除第二列选中的列表内容")
                    TDMainViewModel.shared.selectedTask = nil

                    // TODO: 清除第二列选中的列表内容
                    // 这里需要根据具体的UI实现来清除第二列的内容
                    // 可能需要调用相关的清除方法或发送通知
                }
                
                task.todoTime = newTodoTime

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
        onRepeatSet()
    }

    
    /// 根据重复类型计算72个重复日期 - 生成重复任务的日期列表
    /// - Parameters:
    ///   - repeatType: 重复类型
    ///   - count: 重复次数（固定为72）
    ///   - startDate: 开始日期
    /// - Returns: 重复日期数组
    private func getRepeatDates(for repeatType: TDDataOperationManager.CustomRepeatType, count: Int, startDate: Date) -> [Date] {
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
            let currentLunar = currentDate.toLunar
            for i in 0..<count {
                if let nextLunarDate = currentDate.nextLunarYearMonthDay(lunarMonth: currentLunar.month, lunarDay: currentLunar.day, yearsLater: i) {
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

    TDRepeatSettingView(
        task: sampleTask
    ) {
        print("重复设置完成，需要同步数据")
    }
    .environmentObject(TDThemeManager.shared)
}
