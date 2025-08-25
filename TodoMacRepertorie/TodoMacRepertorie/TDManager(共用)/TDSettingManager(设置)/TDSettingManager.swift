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
    
    /// App Group 标识符，主程序和小组件都要配置同一个 groupId
    private let appGroupIdentifier = TDAppConfig.appGroupId
    /// 共享的 UserDefaults，用于主程序和小组件数据同步
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    
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
        /// 新数据添加位置（true: 添加到顶部，false: 添加到底部）
        static let newTaskAddToTop = "td_new_task_add_to_top"

        /// 是否显示本地日历数据
        static let showLocalCalendarEvents = "td_show_local_calendar_events"
        /// 已完成过期任务显示范围
        static let expiredRangeCompleted = "td_expired_range_completed"
        /// 未完成过期任务显示范围
        static let expiredRangeUncompleted = "td_expired_range_uncompleted"
        /// 重复数据显示个数
        static let repeatTasksLimit = "td_repeat_tasks_limit"
        /// 后续日程显示范围
        static let futureDateRange = "td_future_date_range"
        
        /// 是否显示无日期事件
        static let showNoDateEvents = "td_show_no_date_events"
        /// 是否显示已完成的无日期事件
        static let showCompletedNoDateEvents = "td_show_completed_no_date_events"

        
        /// 日历视图任务背景色模式
        static let calendarTaskBackgroundMode = "td_calendar_task_background_mode"
        /// 日历视图是否显示已完成分割线
        static let calendarShowCompletedSeparator = "td_calendar_show_completed_separator"
        /// 日历视图是否显示剩余任务数量
        static let calendarShowRemainingCount = "td_calendar_show_remaining_count"
        /// DayTodo 是否显示顺序数字
        static let showDayTodoOrderNumber = "td_show_daytodo_order_number1"

        /// 任务标题显示行数
        static let taskTitleLines = "td_task_title_lines"
        /// 任务描述显示行数
        static let taskDescriptionLines = "td_task_description_lines"
        /// 是否显示任务描述
        static let showTaskDescription = "td_show_task_description"
        /// 任务已完成标题是否显示删除线
        static let showCompletedTaskStrikethrough = "td_show_completed_task_strikethrough"
        /// 选中框是否跟随分类清单颜色
        static let checkboxFollowCategoryColor = "td_checkbox_follow_category_color"

        
        /// 是否开启震动
        static let enableVibration = "td_enable_vibration"
        /// 是否开启音效
        static let enableSound = "td_enable_sound"
        /// 音效类型（1: ok_ding, 2: todofinishvoice）
        static let soundType = "td_sound_type"


    }
    // MARK: - 存储属性（每个都带注释）
    
    /// 主题模式（0: 跟随系统，1: 白天，2: 黑夜）
    var themeMode: TDThemeMode {
        get { TDThemeMode(rawValue: sharedDefaults?.integer(forKey: Keys.themeMode) ?? TDThemeMode.light.rawValue) ?? .light }
        set { sharedDefaults?.set(newValue.rawValue, forKey: Keys.themeMode); objectWillChange.send() }
    }
    
    /// 字体大小
    var fontSize: TDFontSize {
        get { TDFontSize(rawValue: sharedDefaults?.integer(forKey: Keys.fontSize) ?? TDFontSize.system.rawValue) ?? .system }
        set { sharedDefaults?.set(newValue.rawValue, forKey: Keys.fontSize); objectWillChange.send() }
    }
    
    /// 语言（0: 跟随系统，1: 中文，2: 英文 ...）
    var language: TDLanguage {
        get { TDLanguage(rawValue: sharedDefaults?.integer(forKey: Keys.language) ?? TDLanguage.system.rawValue) ?? .system }
        set { sharedDefaults?.set(newValue.rawValue, forKey: Keys.language); objectWillChange.send() }
    }
    /// 每周第一天是否为周一
    var isFirstDayMonday: Bool {
        get {
            // 如果没有存储过值，默认返回 true（周一）
            if sharedDefaults?.object(forKey: Keys.firstDayOfWeek) == nil {
                return true
            }
            return sharedDefaults?.integer(forKey: Keys.firstDayOfWeek) == 1
        }
        set { sharedDefaults?.set(newValue ? 1 : 0, forKey: Keys.firstDayOfWeek); objectWillChange.send() }
    }
    
    /// 是否显示已完成任务
    var showCompletedTasks: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.showCompletedTasks) == nil {
                return true // 默认显示已完成任务
            }
            return sharedDefaults?.bool(forKey: Keys.showCompletedTasks) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.showCompletedTasks); objectWillChange.send() }
    }
    
    /// 数据展示排序（true: 升序，false: 降序）
//    var isTaskSortAscending: Bool {
//        get { sharedDefaults?.bool(forKey: Keys.taskSortOrder) ?? true }
//        set { sharedDefaults?.set(newValue, forKey: Keys.taskSortOrder); objectWillChange.send() }
//    }
    /// 新数据添加位置（true: 添加到顶部，false: 添加到底部，默认添加到底部）
    var isNewTaskAddToTop: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.newTaskAddToTop) == nil {
                return false // 默认添加到底部
            }
            return sharedDefaults?.bool(forKey: Keys.newTaskAddToTop) ?? false
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.newTaskAddToTop); objectWillChange.send() }
    }

    /// 是否显示本地日历数据
    var showLocalCalendarEvents: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.showLocalCalendarEvents) == nil {
                return false // 默认不显示本地日历数据
            }
            return sharedDefaults?.bool(forKey: Keys.showLocalCalendarEvents) ?? false
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.showLocalCalendarEvents); objectWillChange.send() }
    }
    
    
    /// 已完成过期任务显示范围
    var expiredRangeCompleted: TDExpiredRange {
        get { TDExpiredRange(rawValue: sharedDefaults?.integer(forKey: Keys.expiredRangeCompleted) ?? TDExpiredRange.sevenDays.rawValue) ?? .sevenDays }
        set { sharedDefaults?.set(newValue.rawValue, forKey: Keys.expiredRangeCompleted); objectWillChange.send() }
    }

    /// 未完成过期任务显示范围
    var expiredRangeUncompleted: TDExpiredRange {
        get { TDExpiredRange(rawValue: sharedDefaults?.integer(forKey: Keys.expiredRangeUncompleted) ?? TDExpiredRange.sevenDays.rawValue) ?? .sevenDays }
        set { sharedDefaults?.set(newValue.rawValue, forKey: Keys.expiredRangeUncompleted); objectWillChange.send() }
    }
    
    /// 重复数据显示个数
    var repeatTasksLimit: TDRepeatTasksLimit {
        get { TDRepeatTasksLimit(rawValue: sharedDefaults?.integer(forKey: Keys.repeatTasksLimit) ?? TDRepeatTasksLimit.five.rawValue) ?? .five }
        set { sharedDefaults?.set(newValue.rawValue, forKey: Keys.repeatTasksLimit); objectWillChange.send() }
    }
    
    /// 后续日程显示范围
    var futureDateRange: TDFutureDateRange {
        get { TDFutureDateRange(rawValue: sharedDefaults?.integer(forKey: Keys.futureDateRange) ?? TDFutureDateRange.thirtyDays.rawValue) ?? .thirtyDays }
        set { sharedDefaults?.set(newValue.rawValue, forKey: Keys.futureDateRange); objectWillChange.send() }
    }
    
    /// 是否显示无日期事件
    var showNoDateEvents: Bool {
        get { sharedDefaults?.bool(forKey: Keys.showNoDateEvents) ?? true }
        set { sharedDefaults?.set(newValue, forKey: Keys.showNoDateEvents); objectWillChange.send() }
    }

    /// 是否显示已完成的无日期事件
    var showCompletedNoDateEvents: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.showNoDateEvents) == nil {
                return true // 默认显示无日期事件
            }
            return sharedDefaults?.bool(forKey: Keys.showNoDateEvents) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.showCompletedNoDateEvents); objectWillChange.send() }
    }


    /// 日历视图任务背景色模式
    var calendarTaskBackgroundMode: TDTaskBackgroundMode {
        get { TDTaskBackgroundMode(rawValue: sharedDefaults?.integer(forKey: Keys.calendarTaskBackgroundMode) ?? TDTaskBackgroundMode.workload.rawValue) ?? .workload }
        set { sharedDefaults?.set(newValue.rawValue, forKey: Keys.calendarTaskBackgroundMode); objectWillChange.send() }
    }
    
    /// 日历视图是否显示已完成分割线
    var calendarShowCompletedSeparator: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.calendarShowCompletedSeparator) == nil {
                return true // 默认显示已完成分割线
            }
            return sharedDefaults?.bool(forKey: Keys.calendarShowCompletedSeparator) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.calendarShowCompletedSeparator); objectWillChange.send() }
    }
    
    /// 日历视图是否显示剩余任务数量
    var calendarShowRemainingCount: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.calendarShowRemainingCount) == nil {
                return true // 默认显示剩余任务数量
            }
            return sharedDefaults?.bool(forKey: Keys.calendarShowRemainingCount) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.calendarShowRemainingCount); objectWillChange.send() }
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
    /// 获取重复数据显示个数的具体数值
    var repeatNum: Int {
        repeatTasksLimit.rawValue
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
    
    // MARK: - 任务显示设置
    
    /// 任务标题显示行数（默认2行）
    var taskTitleLines: Int {
        get {
            if sharedDefaults?.object(forKey: Keys.taskTitleLines) == nil {
                return 2 // 默认2行
            }
            return sharedDefaults?.integer(forKey: Keys.taskTitleLines) ?? 2
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.taskTitleLines); objectWillChange.send() }
    }
    
    /// 任务描述显示行数（默认3行）
    var taskDescriptionLines: Int {
        get {
            if sharedDefaults?.object(forKey: Keys.taskDescriptionLines) == nil {
                return 3 // 默认3行
            }
            return sharedDefaults?.integer(forKey: Keys.taskDescriptionLines) ?? 3
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.taskDescriptionLines); objectWillChange.send() }
    }
    
    /// 是否显示任务描述（默认显示）
    var showTaskDescription: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.showTaskDescription) == nil {
                return true // 默认显示任务描述
            }
            return sharedDefaults?.bool(forKey: Keys.showTaskDescription) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.showTaskDescription); objectWillChange.send() }
    }
    
    /// 任务已完成标题是否显示删除线（默认显示）
    var showCompletedTaskStrikethrough: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.showCompletedTaskStrikethrough) == nil {
                return true // 默认显示删除线
            }
            return sharedDefaults?.bool(forKey: Keys.showCompletedTaskStrikethrough) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.showCompletedTaskStrikethrough); objectWillChange.send() }
    }
    /// 选中框是否跟随分类清单颜色（默认不跟随）
    var checkboxFollowCategoryColor: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.checkboxFollowCategoryColor) == nil {
                return false // 默认不跟随分类颜色
            }
            return sharedDefaults?.bool(forKey: Keys.checkboxFollowCategoryColor) ?? false
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.checkboxFollowCategoryColor); objectWillChange.send() }
    }

    /// DayTodo 是否显示顺序数字（默认显示）
    var showDayTodoOrderNumber: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.showDayTodoOrderNumber) == nil {
                return true // 默认显示顺序数字
            }
            return sharedDefaults?.bool(forKey: Keys.showDayTodoOrderNumber) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.showDayTodoOrderNumber); objectWillChange.send() }
    }
    
    /// 是否开启震动（默认开启）
    var enableVibration: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.enableVibration) == nil {
                return true // 默认开启震动
            }
            return sharedDefaults?.bool(forKey: Keys.enableVibration) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.enableVibration); objectWillChange.send() }
    }
    
    /// 是否开启音效（默认开启）
    var enableSound: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.enableSound) == nil {
                return true // 默认开启音效
            }
            return sharedDefaults?.bool(forKey: Keys.enableSound) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.enableSound); objectWillChange.send() }
    }
    
    /// 音效类型（默认使用 ok_ding）
    var soundType: TDSoundType {
        get {
            if sharedDefaults?.object(forKey: Keys.soundType) == nil {
                return .okDing // 默认使用 ok_ding
            }
            return TDSoundType(rawValue: sharedDefaults?.integer(forKey: Keys.soundType) ?? TDSoundType.okDing.rawValue) ?? .okDing
        }
        set { sharedDefaults?.set(newValue.rawValue, forKey: Keys.soundType); objectWillChange.send() }
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
