//
//  TDSettingManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI
//import SwiftDate
//import Combine

class TDSettingManager: ObservableObject {
    static let shared = TDSettingManager()
    
    // MARK: - AppStorage Keys
    private struct Keys {
        /// 主题模式 跟随系统 白天  黑夜
        static let themeMode = "td_theme_mode"
        /// 字体大小
        static let fontSize = "td_font_size"
        /// 语言
        static let language = "td_language"
        /// 每周第一天
        static let firstDayOfWeek = "td_first_day_of_week"
        /// 是否显示已完成任务
        static let showCompletedTasks = "td_show_completed_tasks"
        /// 数据展示排序
        static let taskSortOrder = "td_task_sort_order"
        /// 是否显示本地日历数据
        static let showLocalCalendarEvents = "td_show_local_calendar_events"
        /// 描述显示行数 (1-5行)
        static let descriptionLineLimit = "td_description_line_limit"
        /// 已完成过期任务显示范围
        static let expiredRangeCompleted = "td_expired_range_completed"
        /// 未完成过期任务显示范围
        static let expiredRangeUncompleted = "td_expired_range_uncompleted"
        /// 重复数据显示个数
        static let repeatTasksLimit = "td_repeat_tasks_limit"
        /// 后续日程显示范围
        static let futureDateRange = "td_future_date_range"
        
        
        /// 日历视图任务背景色模式
        static let calendarTaskBackgroundMode = "td_calendar_task_background_mode"
        /// 日历视图是否显示已完成分割线
        static let calendarShowCompletedSeparator = "td_calendar_show_completed_separator"
        /// 日历视图是否显示剩余任务数量
        static let calendarShowRemainingCount = "td_calendar_show_remaining_count"


    }
    
    /// 主题模式
    @AppStorage(Keys.themeMode) private var themeModeRawValue: Int = TDThemeMode.light.rawValue {
        didSet { objectWillChange.send() }
    }
    
    /// 文字大小
    @AppStorage(Keys.fontSize) private var fontSizeRawValue: Int = TDFontSize.system.rawValue {
        didSet { objectWillChange.send() }
    }
    
    /// 语言设置
    @AppStorage(Keys.language) private var languageRawValue: Int = TDLanguage.system.rawValue {
        didSet { objectWillChange.send() }
    }
    /// 每周第一天（0: 周日，1: 周一）
    @AppStorage(Keys.firstDayOfWeek) private var firstDayOfWeekValue: Int = 1 {
        didSet { objectWillChange.send() }
    }

    /// 是否显示已完成任务
    @AppStorage(Keys.showCompletedTasks) private var showCompletedTasksValue: Bool = false {
        didSet { objectWillChange.send() }
    }
    /// 数据展示排序
    @AppStorage(Keys.taskSortOrder) private var taskSortOrderValue: Bool = true {
        didSet { objectWillChange.send() }
    }
    /// 是否显示本地日历数据
    @AppStorage(Keys.showLocalCalendarEvents) private var showLocalCalendarEventsValue: Bool = false {
        didSet { objectWillChange.send() }
    }
    /// 描述显示行数 (1-5行)
    @AppStorage(Keys.descriptionLineLimit) private var descriptionLineLimitValue: Int = 1 {
        didSet {
            // 确保值在1-5之间
            if descriptionLineLimitValue < 1 {
                descriptionLineLimitValue = 1
            } else if descriptionLineLimitValue > 5 {
                descriptionLineLimitValue = 5
            }
            objectWillChange.send()
        }
    }
    
    /// 已完成过期任务显示范围
    @AppStorage(Keys.expiredRangeCompleted) private var expiredRangeCompletedValue: Int = TDExpiredRange.sevenDays.rawValue {
        didSet { objectWillChange.send() }
    }
    
    /// 未完成过期任务显示范围
    @AppStorage(Keys.expiredRangeUncompleted) private var expiredRangeUncompletedValue: Int = TDExpiredRange.sevenDays.rawValue {
        didSet { objectWillChange.send() }
    }

    /// 重复数据显示个数
    @AppStorage(Keys.repeatTasksLimit) private var repeatTasksLimitValue: Int = TDRepeatTasksLimit.all.rawValue {
        didSet { objectWillChange.send() }
    }
    /// 后续日程显示范围
    @AppStorage(Keys.futureDateRange) private var futureDateRangeValue: Int = TDFutureDateRange.thirtyDays.rawValue {
        didSet { objectWillChange.send() }
    }
    
    /// 日历视图任务背景色模式
    @AppStorage(Keys.calendarTaskBackgroundMode) private var taskBackgroundModeValue: Int = TDTaskBackgroundMode.workload.rawValue {
        didSet { objectWillChange.send() }
    }

    /// 日历视图是否显示已完成分割线
    @AppStorage(Keys.calendarShowCompletedSeparator) private var showCompletedSeparatorValue: Bool = true {
        didSet { objectWillChange.send() }
    }
    
    /// 日历视图是否显示剩余任务数量
    @AppStorage(Keys.calendarShowRemainingCount) private var showRemainingCountValue: Bool = true {
        didSet { objectWillChange.send() }
    }
    // MARK: - 计算属性
    
    /// 当前主题模式
    var themeMode: TDThemeMode {
        get { TDThemeMode(rawValue: themeModeRawValue) ?? .light }
        set { themeModeRawValue = newValue.rawValue }
    }
    
    /// 当前文字大小
    var fontSize: TDFontSize {
        get { TDFontSize(rawValue: fontSizeRawValue) ?? .system }
        set { fontSizeRawValue = newValue.rawValue }
    }
    
    /// 当前语言
    var language: TDLanguage {
        get { TDLanguage(rawValue: languageRawValue) ?? .system }
        set { languageRawValue = newValue.rawValue }
    }
    
    /// 获取当前是否是深色模式
    var isDarkMode: Bool {
        switch themeMode {
        case .system:
            return NSApp.effectiveAppearance.isDarkMode
        case .light:
            return false
        case .dark:
            return true
        }
    }
    /// 每周第一天是否为周一
    var isFirstDayMonday: Bool {
        get { firstDayOfWeekValue == 1 }
        set { firstDayOfWeekValue = newValue ? 1 : 0 }
    }

    /// 是否显示已完成任务
    var showCompletedTasks: Bool {
        get { showCompletedTasksValue }
        set { showCompletedTasksValue = newValue }
    }
    
    /// 数据展示排序
    var isTaskSortAscending: Bool {
        get { taskSortOrderValue }
        set { taskSortOrderValue = newValue }
    }
    /// 是否显示本地日历数据
    var showLocalCalendarEvents: Bool {
        get { showLocalCalendarEventsValue }
        set { showLocalCalendarEventsValue = newValue }
    }
    /// 描述显示行数
    var descriptionLineLimit: Int {
        get { descriptionLineLimitValue }
        set { descriptionLineLimitValue = min(max(newValue, 1), 5) }
    }
    
    /// 已完成过期任务显示范围
    var expiredRangeCompleted: TDExpiredRange {
        get { TDExpiredRange(rawValue: expiredRangeCompletedValue) ?? .sevenDays }
        set { expiredRangeCompletedValue = newValue.rawValue }
    }
    
    /// 未完成过期任务显示范围
    var expiredRangeUncompleted: TDExpiredRange {
        get { TDExpiredRange(rawValue: expiredRangeUncompletedValue) ?? .sevenDays }
        set { expiredRangeUncompletedValue = newValue.rawValue }
    }
    
    /// 重复数据显示个数
    var repeatTasksLimit: TDRepeatTasksLimit {
        get { TDRepeatTasksLimit(rawValue: repeatTasksLimitValue) ?? .all }
        set { repeatTasksLimitValue = newValue.rawValue }
    }
    /// 获取重复数据显示个数的具体数值
    var repeatNum: Int {
        repeatTasksLimit.rawValue
    }
    
    /// 后续日程显示范围
    var futureDateRange: TDFutureDateRange {
        get { TDFutureDateRange(rawValue: futureDateRangeValue) ?? .thirtyDays }
        set { futureDateRangeValue = newValue.rawValue }
    }
    
    /// 获取后续日程显示范围的天数
    var futureDays: Int {
        futureDateRange.rawValue
    }
    
    /// 获取后续日程的结束时间戳
    func getFutureEndTimestamp(from date: Date) -> Int64 {
        if futureDateRange == .all {
            // 如果是全部，返回一个很大的时间戳
            return Int64.max
        } else {
            return date.adding(days: futureDays).endOfDayTimestamp
        }
    }

    /// 日历视图任务背景色模式
    var calendarTaskBackgroundMode: TDTaskBackgroundMode {
        get { TDTaskBackgroundMode(rawValue: taskBackgroundModeValue) ?? .workload }
        set { taskBackgroundModeValue = newValue.rawValue }
    }
    /// 日历视图是否显示已完成分割线
    var calendarShowCompletedSeparator: Bool {
        get { showCompletedSeparatorValue }
        set { showCompletedSeparatorValue = newValue }
    }
    
    /// 日历视图是否显示剩余任务数量
    var calendarShowRemainingCount: Bool {
        get { showRemainingCountValue }
        set { showRemainingCountValue = newValue }
    }
    
    

    /// 获取任务显示样式
    @MainActor
    func getTaskStyle(for task: TDMacSwiftDataListModel) -> (backgroundColor: Color?, textColor: Color) {
        let themeManager = TDThemeManager.shared
        
        switch calendarTaskBackgroundMode {
        case .workload:
            // 工作量背景色
            let backgroundColor: Color
            if task.snowAssess < 5 {
                backgroundColor = .gray.opacity(0.1)
            } else if task.snowAssess < 9 {
                backgroundColor = .orange.opacity(0.1)
            } else {
                backgroundColor = .red.opacity(0.1)
            }
            return (
                backgroundColor,
                task.complete ? themeManager.titleFinishTextColor : themeManager.titleTextColor
            )
            
        case .category:
            // 清单颜色 - 只有自定义分类（categoryId > 0）才显示清单颜色
            if task.standbyInt1 > 0 {
                let color = Color.fromHex(task.standbyIntColor)
                return (
                    color.opacity(0.1),
                    task.complete ? themeManager.titleFinishTextColor : color
                )
            }
            // 系统分类使用默认主题颜色
            return (
                nil,
                task.complete ? themeManager.titleFinishTextColor : themeManager.titleTextColor
            )
        }
    }

    // MARK: - 初始化
    private init() {}
    
}
    // 主题颜色模式是否跟随系统
//    @AppStorage("themeFollowSystem") var followSystem: Bool = true
//    
//    // 添加事件 是置顶 还是置底 显示是升序还是 降序 默认 置顶
//    @AppStorage("isTop") var isTop: Bool = true
//    
//    // 是否允许订阅日历 是的话 就获取本地日历数据
//    @AppStorage("isSubscription") var isSubscription: Bool = true
//    
//    // 列表是否展示 已完成数据
//    @AppStorage("isShowFinishData") var isShowFinishData: Bool = false
//
//    // 最近待办 未分类 清单数据 展示 过期已完成的数据 日期范围 0：不显示， 7天 30天 100天
//    @AppStorage("expiredRangeCompleted") var expiredRangeCompleted: Int = 7
//
//    // 最近待办 未分类 清单数据 展示 过期未完成的数据 日期范围 0：不显示， 7天 30天 100天
//    @AppStorage("expiredRangeUncompleted") var expiredRangeUncompleted: Int = 30
//    // 最近待办 未分类 清单数据 展示 过期未完成的数据 日期范围 0： 全部， 1、2、5、10条
//    @AppStorage("repeatNum") var repeatNum: Int = 5
//    
//    // 最近待办 未分类 清单数据 是否显示没有日期的事件 默认显示
//    @AppStorage("isShowNoDateData") var isShowNoDateData: Bool = true
//
//    // 最近待办 未分类 清单数据 是否显示已完成的无日期事件 默认显示
//    @AppStorage("isShowNoDateFinishData") var isShowNoDateFinishData: Bool = true
//
//    
//    /// 待办箱内 清单分类的筛选 0 所有类 >0 根据id 筛选
//    @Published var noDateCategoryId : Int = 0
//    
//    /// 待办箱内 筛选类型 noDateSortState = 0：按创建日期，1：按自定义排序， 2：按工作量
//    @Published var noDateSortState : Int = 0
//    /// 待办箱内 筛选类型 排序方式 升序降序
//    @Published var noDateSort : Bool = false
//
//    
//    // 每周的第一天 是否是 周一
//    @AppStorage("weekStartsOnMonday") var weekStartsOnMonday: Bool = true {
//        didSet {
//            configureCalendar()
//        }
//    }
//    
//    private init() {
//        configureCalendar()
//    }
//    
//    var firstWeekday: Int {
//        weekStartsOnMonday ? 2 : 1  // 1 = 周日, 2 = 周一
//    }
//    
//    private func configureCalendar() {
//        var calendar = Calendar.current
//        calendar.firstWeekday = firstWeekday
//        SwiftDate.defaultRegion = Region(
//            calendar: calendar,
//            zone: TimeZone.current,
//            locale: Locale(identifier: "zh_CN")
//        )
//    }
//}
