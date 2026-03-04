//
//  TDScheduleOverviewViewModel.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/9/23.
//

import Foundation
import SwiftUI
import OSLog
import SwiftData

class TDScheduleOverviewViewModel: ObservableObject {

    enum DisplayMode: Int, CaseIterable {
        case month
        case week
    }
    
    // MARK: - Published 属性
    /// 单例
    static let shared = TDScheduleOverviewViewModel()

    /// 当前显示的月份（用于驱动日历网格刷新）
    /// - 说明：与 `currentDate`（选中日期）解耦，避免点选日期导致整月任务查询/重渲染
    @Published var displayMonth: Date = Date()

    /// 当前选中的日期
    @Published var currentDate: Date = Date()

    /// 日程概览展示模式：月视图/周视图
    @Published var displayMode: DisplayMode = .month
    
    /// 选中的分类
    @Published var selectedCategory: TDSliderBarModel? = nil
    
    /// 可用的分类列表
    @Published var availableCategories: [TDSliderBarModel] = []
    
    /// 标签筛选
    @Published var tagFilter: String = ""
    
    /// 排序类型 0:默认 1:提醒时间 2:添加时间a-z 3:添加时间z-a 4:工作量a-z 5:工作量z-a
    @Published var sortType: Int = 0

    /// 是否显示日期选择器
    @Published var showDatePicker: Bool = false
    
    /// 是否显示筛选器
    @Published var showFilter: Bool = false
    
    /// 是否显示更多选项
    @Published var showMoreOptions: Bool = false
    

    /// 调试开关：是否禁用“日历格子内每天任务数据”的获取与展示
    /// - 目的：便于一步步排查日程概览问题，先只保留日历/节假日/选中态
    /// - 默认：Debug 为 true（先不取每天数据），Release 为 false（正常展示）
    @Published var disableDailyTasksInCalendar: Bool = {
#if DEBUG
        return true
#else
        return false
#endif
    }()

    // MARK: - 预加载缓存（用于首次进入“日程概览”首帧就有数据）
    struct MonthTasksCacheKey: Hashable {
        let monthStartTimestamp: Int64
        let categoryId: Int
        let sortType: Int
        let showCompleted: Bool
        let isFirstDayMonday: Bool
    }

    /// 当月任务缓存：按天分组（key = todoTime(startOfDayTimestamp)）
    @Published private(set) var monthTasksByDay: [Int64: [TDMacSwiftDataListModel]] = [:]
    @Published private(set) var monthTasksCacheKey: MonthTasksCacheKey? = nil


    // MARK: - 私有属性
    
    private let logger = OSLog(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDScheduleOverviewViewModel")

    /// 预加载令牌（用于快速切月时丢弃过期结果）
    private var monthPreloadToken: Int = 0
    
    // MARK: - 初始化
    
    init() {
        // 初始显示月份与选中日期一致
        displayMonth = Date().firstDayOfMonth
        loadCategories()

        // 启动预热：提前算好日历格子 + 当月任务（这样首次进入“日程概览”不再先空后补）
        Task { try? await TDCalendarManager.shared.updateCalendarData() }
        preloadMonthTasksIfNeeded(force: true)
    }
    
    // MARK: - 公共方法
    
    /// 更新当前日期
    /// - Parameter date: 新的日期
    func updateCurrentDate(_ date: Date) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentDate = date
        }
//        // 通知日历管理器更新数据
//        Task {
//            try? await TDCalendarManager.shared.updateCalendarData()
//        }

        os_log(.info, log: logger, "📅 更新当前日期: %@", date.formattedString)
    }
    /// 只更新选中状态，不触发日历数据重新计算
    /// - Parameter date: 要选中的日期
    func selectDateOnly(_ date: Date) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentDate = date
        }
        os_log(.info, log: logger, "📅 选中日期: %@", date.formattedString)
    }
    
    /// 上一个月
    func previousMonth() {
        let newDate = displayMonth.adding(months: -1)
        // 智能选择日期：如果是当月选中今天，否则选中1日
        let targetDate = getSmartSelectedDate(for: newDate)
        // 直接更新日期并重新计算日历数据
        withAnimation(.easeInOut(duration: 0.3)) {
            displayMonth = newDate.firstDayOfMonth
            currentDate = targetDate
        }
        // 手动触发日历数据重新计算
        Task {
            try? await TDCalendarManager.shared.updateCalendarData()
        }
        preloadMonthTasksIfNeeded(force: true)
        os_log(.info, log: logger, "📅 切换到上一个月: %@", targetDate.formattedString)
    }
    
    /// 下一个月
    func nextMonth() {
        let newDate = displayMonth.adding(months: 1)
        // 智能选择日期：如果是当月选中今天，否则选中1日
        let targetDate = getSmartSelectedDate(for: newDate)
        // 直接更新日期并重新计算日历数据
        withAnimation(.easeInOut(duration: 0.3)) {
            displayMonth = newDate.firstDayOfMonth
            currentDate = targetDate
        }
        // 手动触发日历数据重新计算
        Task {
            try? await TDCalendarManager.shared.updateCalendarData()
        }
        preloadMonthTasksIfNeeded(force: true)
        os_log(.info, log: logger, "📅 切换到下一个月: %@", targetDate.formattedString)
    }

    // MARK: - Week navigation

    /// 获取当前周的开始日期（受“周一为一周开始”设置影响）
    func currentWeekStartDate() -> Date {
        weekStartDate(for: currentDate)
    }

    /// 获取当前周的结束日期
    func currentWeekEndDate() -> Date {
        let start = currentWeekStartDate()
        return Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start
    }

    /// 获取当前周的 7 天日期数组（从周起始开始）
    func currentWeekDates() -> [Date] {
        let start = currentWeekStartDate()
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }

    /// 上一周
    func previousWeek() {
        let newDate = currentDate.adding(days: -7)
        withAnimation(.easeInOut(duration: 0.3)) {
            currentDate = newDate
            // 让“月份”与当前日期保持一致，便于周/月切换时月视图不跳
            displayMonth = newDate.firstDayOfMonth
        }
        Task { try? await TDCalendarManager.shared.updateCalendarData() }
        preloadMonthTasksIfNeeded(force: true)
    }

    /// 下一周
    func nextWeek() {
        let newDate = currentDate.adding(days: 7)
        withAnimation(.easeInOut(duration: 0.3)) {
            currentDate = newDate
            displayMonth = newDate.firstDayOfMonth
        }
        Task { try? await TDCalendarManager.shared.updateCalendarData() }
        preloadMonthTasksIfNeeded(force: true)
    }

    /// 顶部显示文案（周/月模式自适配）
    var displayTitleText: String {
        switch displayMode {
        case .month:
            return displayMonth.toString(format: displayMonth.isThisYear ? "M月" : "yyyy年 M月")
        case .week:
            // 周视图标题也按“月份标题”展示（上/下箭头仍按周切换）
            return displayMonth.toString(format: displayMonth.isThisYear ? "M月" : "yyyy年 M月")
        }
    }

    /// 根据当前展示模式切换上一段（上月/上一周）
    func previousPeriod() {
        switch displayMode {
        case .month: previousMonth()
        case .week: previousWeek()
        }
    }

    /// 根据当前展示模式切换下一段（下月/下一周）
    func nextPeriod() {
        switch displayMode {
        case .month: nextMonth()
        case .week: nextWeek()
        }
    }

    /// 获取智能选中的日期
    /// - Parameter targetDate: 目标月份中的任意日期
    /// - Returns: 智能选中的日期
    private func getSmartSelectedDate(for targetDate: Date) -> Date {
        // 判断是否切换到当前月份
        if targetDate.isCurrentMonth {
            // 切换到当前月份，默认选中今天
            return Date()
        } else {
            // 切换到其他月份，默认选中该月第一天
            return targetDate.firstDayOfMonth
        }
    }

    /// 回到今天
    func backToToday() {
        // 直接更新日期并重新计算日历数据
        withAnimation(.easeInOut(duration: 0.3)) {
            displayMonth = Date().firstDayOfMonth
            currentDate = Date()
        }
        // 手动触发日历数据重新计算
        Task {
            try? await TDCalendarManager.shared.updateCalendarData()
        }
        preloadMonthTasksIfNeeded(force: true)
        os_log(.info, log: logger, "📅 回到今天: %@", Date().formattedString)
    }

    /// 从日期选择器设置“显示月份 + 选中日期”
    /// - Parameter date: 选择的日期
    func setMonthAndSelectDate(_ date: Date) {
        withAnimation(.easeInOut(duration: 0.3)) {
            displayMonth = date.firstDayOfMonth
            currentDate = date
        }
        Task {
            try? await TDCalendarManager.shared.updateCalendarData()
        }
        preloadMonthTasksIfNeeded(force: true)
        os_log(.info, log: logger, "📅 设置月份并选中日期: %@", date.formattedString)
    }

    // MARK: - Helpers

    private func weekStartDate(for date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) // 1=Sun...7=Sat
        let firstWeekday = TDSettingManager.shared.isFirstDayMonday ? 2 : 1 // 2=Mon, 1=Sun
        let delta = (weekday - firstWeekday + 7) % 7
        let start = calendar.date(byAdding: .day, value: -delta, to: date) ?? date
        return calendar.startOfDay(for: start)
    }

    /// 更新选中的分类
    /// - Parameter category: 分类对象，nil 表示未分类
    func updateSelectedCategory(_ category: TDSliderBarModel?) {
        selectedCategory = category
        updateCurrentDate(currentDate)
        preloadMonthTasksIfNeeded(force: true)
        os_log(.info, log: logger, "🏷️ 更新选中分类: %@", category?.categoryName ?? "未分类")
    }
    /// 更新标签筛选
    /// - Parameter tag: 标签筛选条件
    func updateTagFilter(_ tag: String) {
        tagFilter = tag
        updateCurrentDate(currentDate)
        os_log(.info, log: logger, "🏷️ 更新标签筛选: %@", tag)
    }
    
    /// 更新排序类型
    /// - Parameter sort: 排序类型
    func updateSortType(_ sort: Int) {
        sortType = sort
        updateCurrentDate(currentDate)
        preloadMonthTasksIfNeeded(force: true)
        os_log(.info, log: logger, "📊 更新排序类型: %d", sort)
    }

    /// 显示日期选择器
    func showDatePickerView() {
        showDatePicker = true
    }
    
    /// 隐藏日期选择器
    func hideDatePickerView() {
        showDatePicker = false
    }
    
    /// 显示筛选器
    func showFilterView() {
        showFilter = true
    }
    
    /// 隐藏筛选器
    func hideFilterView() {
        showFilter = false
    }
    
    /// 显示更多选项
    func showMoreOptionsView() {
        showMoreOptions = true
    }
    
    /// 隐藏更多选项
    func hideMoreOptionsView() {
        showMoreOptions = false
    }
    
    
    // MARK: - 私有方法
    
    /// 加载分类数据
    private func loadCategories() {
        let allCategories = TDCategoryManager.shared.loadLocalCategories()
        availableCategories = allCategories
        os_log(.info, log: logger, "📂 加载分类数据: %d 个分类", allCategories.count)
    }

    // MARK: - Month tasks preload

    /// 当前条件下的缓存 Key（不包含 tagFilter，因为标签筛选在应用层处理）
    func makeCurrentMonthTasksCacheKey() -> MonthTasksCacheKey {
        let settingManager = TDSettingManager.shared
        let monthStartTimestamp = displayMonth.firstDayOfMonth.startOfDayTimestamp
        let categoryId = selectedCategory?.categoryId ?? 0
        return MonthTasksCacheKey(
            monthStartTimestamp: monthStartTimestamp,
            categoryId: categoryId,
            sortType: sortType,
            showCompleted: settingManager.showCompletedTasks,
            isFirstDayMonday: settingManager.isFirstDayMonday
        )
    }

    /// 是否已有可用缓存（用于首帧直接渲染，避免“先空后补”）
    var hasValidMonthTasksCache: Bool {
        monthTasksCacheKey == makeCurrentMonthTasksCacheKey()
    }

    /// 获取（可选标签筛选后的）按天分组任务
    func monthTasksByDayFiltered(tagFilter: String) -> [Int64: [TDMacSwiftDataListModel]] {
        guard !tagFilter.isEmpty else { return monthTasksByDay }
        var result: [Int64: [TDMacSwiftDataListModel]] = [:]
        result.reserveCapacity(monthTasksByDay.count)
        for (k, v) in monthTasksByDay {
            let filtered = TDCorrectQueryBuilder.filterTasksByTag(v, tagFilter: tagFilter)
            if !filtered.isEmpty { result[k] = filtered }
        }
        return result
    }

    /// 预加载当月任务到缓存（后台抓取，主线程一次性发布）
    func preloadMonthTasksIfNeeded(force: Bool = false) {
        if disableDailyTasksInCalendar { return }

        let key = makeCurrentMonthTasksCacheKey()
        if !force, monthTasksCacheKey == key { return }

        monthPreloadToken += 1
        let token = monthPreloadToken

        let settingManager = TDSettingManager.shared
        let userId = TDUserManager.shared.userId
        let categoryId = key.categoryId
        let showCompleted = key.showCompleted
        let sortType = key.sortType

        // 计算网格实际显示的起止日期（包含上/下月补齐）
        let firstDayOfMonth = displayMonth.firstDayOfMonth
        let lastDayOfMonth = displayMonth.lastDayOfMonth

        let numberOfWeeks: Int = {
            let calendar = Calendar.current
            let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
            let totalDays = calendar.component(.day, from: lastDayOfMonth)
            let firstWeekdayOfMonth = settingManager.isFirstDayMonday ? (firstWeekday + 5) % 7 : (firstWeekday - 1)
            let totalCells = firstWeekdayOfMonth + totalDays
            return Int(ceil(Double(totalCells) / 7.0))
        }()

        let gridStartDate: Date = {
            let calendar = Calendar.current
            let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
            let offsetDays = settingManager.isFirstDayMonday ? ((firstWeekday + 5) % 7) : (firstWeekday - 1)
            return calendar.date(byAdding: .day, value: -offsetDays, to: firstDayOfMonth) ?? firstDayOfMonth
        }()

        let gridEndDate: Date = {
            let totalDaysToShow = numberOfWeeks * 7
            return Calendar.current.date(byAdding: .day, value: totalDaysToShow - 1, to: gridStartDate) ?? lastDayOfMonth
        }()

        let startTimestamp = gridStartDate.startOfDayTimestamp
        let endTimestamp = gridEndDate.startOfDayTimestamp

        // 排序（与日历格子展示一致）
        let sortDescriptors: [SortDescriptor<TDMacSwiftDataListModel>] = {
            switch sortType {
            case 1:
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.reminderTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
                ]
            case 2:
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.createTime, order: .forward)
                ]
            case 3:
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.createTime, order: .reverse)
                ]
            case 4:
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.snowAssess, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
                ]
            case 5:
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.snowAssess, order: .reverse),
                    SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
                ]
            default:
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
                ]
            }
        }()

        let container = TDModelContainer.shared.container

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let context = ModelContext(container)

            let predicate: Predicate<TDMacSwiftDataListModel>
            if categoryId > 0 {
                predicate = #Predicate<TDMacSwiftDataListModel> { task in
                    task.userId == userId && !task.delete &&
                    task.todoTime >= startTimestamp && task.todoTime <= endTimestamp &&
                    task.standbyInt1 == categoryId &&
                    (showCompleted || !task.complete)
                }
            } else {
                predicate = #Predicate<TDMacSwiftDataListModel> { task in
                    task.userId == userId && !task.delete &&
                    task.todoTime >= startTimestamp && task.todoTime <= endTimestamp &&
                    (showCompleted || !task.complete)
                }
            }

            let descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
                predicate: predicate,
                sortBy: sortDescriptors
            )

            let tasks = (try? context.fetch(descriptor)) ?? []
            let grouped = Dictionary(grouping: tasks, by: { $0.todoTime })

            DispatchQueue.main.async {
                guard let self else { return }
                // 丢弃过期结果（快速切月/切筛选时）
                guard token == self.monthPreloadToken else { return }
                // 确保条件未变
                guard self.makeCurrentMonthTasksCacheKey() == key else { return }

                self.monthTasksByDay = grouped
                self.monthTasksCacheKey = key
            }
        }
    }
}
