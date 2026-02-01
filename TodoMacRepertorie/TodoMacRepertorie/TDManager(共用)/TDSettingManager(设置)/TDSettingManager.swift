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
        /// 是否启用隐私保护模式
        static let isPrivacyModeEnabled = "td_is_privacy_mode_enabled"
        /// 晒图时是否展示全部事件（针对日程概览的分享/截屏）
        static let scheduleShareShowAllEvents = "td_schedule_share_show_all_events"

        /// 日历任务颜色识别模式
        static let calendarTaskColorRecognition = "td_calendar_task_color_recognition"
        /// 是否显示农历
        static let showLunarCalendar = "td_show_lunar_calendar"

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
        /// 任务列表排序方式（0:自定义 1:提醒时间 2:添加时间早→晚 3:添加时间晚→早 4:工作量少→多 5:工作量多→少）
        static let taskListSortType = "td_task_list_sort_type"

        
        /// 是否开启震动
        static let enableVibration = "td_enable_vibration"
        /// 是否开启音效
        static let enableSound = "td_enable_sound"
        /// 音效类型（1: ok_ding, 2: todofinishvoice）
        static let soundType = "td_sound_type"
        /// 番茄专注：屏幕常亮
        static let focusKeepScreenOn = "td_focus_keep_screen_on"
        /// 番茄专注：推送通知
        static let focusPushEnabled = "td_focus_push_enabled"
        /// 番茄专注：播放完成提示音
        static let focusPlayFinishSound = "td_focus_play_finish_sound"

        /// 专注时长（分钟）
        static let focusDuration = "td_focus_duration"
        /// 休息时长（分钟）
        static let restDuration = "td_rest_duration"

        /// 模块：番茄专注开关
        static let enableTomatoFocus = "td_enable_tomato_focus"
        /// 模块：日程概览开关
        static let enableScheduleOverview = "td_enable_schedule_overview"
        
        /// 数据统计设置

        /// 是否显示专注功能
        static let showFocusFeature = "td_show_focus_feature"

        /// 应用图标选择
        static let appIconId = "td_app_icon_id"
        /// Dock 中显示图标
        static let showDockIcon = "td_show_dock_icon"
        /// Dock 图标显示未完成任务数量
        static let showDockBadge = "td_show_dock_badge"

        
        /// 今日未完成角标显示
        static let showTodayBadge = "td_show_today_badge"
        /// 记忆上次分类选择
        static let rememberLastCategory = "td_remember_last_category"
        /// 记忆上次选择的“分类清单”（按 userId 分开存储）
        /// - 注意：这个 key 只是前缀，最终 key 会拼上 userId：`td_last_selected_category_id_<userId>`
        static let lastSelectedCategoryIdPrefix = "td_last_selected_category_id_"

        /// 显示法定节假日标记
        static let showHolidayMark = "td_show_holiday_mark"
        /// 子任务默认展开
        static let expandSubtask = "td_expand_subtask"
        /// 子任务全部完成时自动完成事件
        static let autoCompleteWhenSubtasksDone = "td_auto_complete_when_subtasks_done"
        /// 事件描述显示行数
        static let taskDescriptionLinesNew = "td_task_description_lines_new"
        /// 默认提醒时间（枚举）
        static let defaultReminderOffsetNew = "td_default_reminder_offset"
        /// 显示待办箱事件（无日期）
        static let showInboxNoDate = "td_show_inbox_no_date"
        /// 显示已达成的无日期事件
        static let showCompletedNoDate = "td_show_completed_no_date"
        /// 侧滑栏工作量热力图
        static let showSidebarHeatmap = "td_show_sidebar_heatmap"


    }
    // MARK: - 存储属性（每个都带注释）
    
    /// 主题模式（0: 跟随系统，1: 白天，2: 黑夜）
    var themeMode: TDThemeMode {
        get { TDThemeMode(rawValue: sharedDefaults?.integer(forKey: Keys.themeMode) ?? TDThemeMode.light.rawValue) ?? .light }
        set { sharedDefaults?.set(newValue.rawValue, forKey: Keys.themeMode); objectWillChange.send() }
    }
    
    /// 字体大小
    var fontSize: TDFontSize {
        get { TDFontSize(rawValue: sharedDefaults?.integer(forKey: Keys.fontSize) ?? TDFontSize.size9.rawValue) ?? .size9 }
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

    /// 记忆上次分类选择（默认关闭）
    var rememberLastCategory: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.rememberLastCategory) == nil { return false }
            return sharedDefaults?.bool(forKey: Keys.rememberLastCategory) ?? false
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.rememberLastCategory); objectWillChange.send() }
    }
    // MARK: - 分类清单选择记忆（按用户维度）
    /// 获取“上次选择的分类清单 id”
    /// - Parameter userId: 当前登录用户 id
    /// - Returns: categoryId（>0 表示某个分类清单；0/未存表示未分类）
    func getLastSelectedCategoryId(for userId: Int) -> Int {
        guard userId > 0 else { return 0 }
        let key = "\(Keys.lastSelectedCategoryIdPrefix)\(userId)"
        return sharedDefaults?.integer(forKey: key) ?? 0
    }

    /// 记录“上次选择的分类清单 id”
    /// - Parameter categoryId: categoryId（>0 表示某个分类清单；0 表示未分类）
    /// - Parameter userId: 当前登录用户 id
    func setLastSelectedCategoryId(_ categoryId: Int, for userId: Int) {
        guard userId > 0 else { return }
        let key = "\(Keys.lastSelectedCategoryIdPrefix)\(userId)"
        sharedDefaults?.set(categoryId, forKey: key)
        objectWillChange.send()
    }

    /// 清除“上次选择的分类清单 id”（通常用于退出登录 / 清理数据）
    func clearLastSelectedCategoryId(for userId: Int) {
        guard userId > 0 else { return }
        let key = "\(Keys.lastSelectedCategoryIdPrefix)\(userId)"
        sharedDefaults?.removeObject(forKey: key)
        objectWillChange.send()
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
    /// 显示法定节假日标记（默认开启）
    var showHolidayMark: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.showHolidayMark) == nil { return true }
            return sharedDefaults?.bool(forKey: Keys.showHolidayMark) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.showHolidayMark); objectWillChange.send() }
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
    /// 默认提醒时间（分钟偏移，0 表示发生时，默认 5 分钟前）
    var defaultReminderOffset: TDDefaultReminder {
        get {
            let raw = sharedDefaults?.integer(forKey: "td_default_reminder_offset") ?? TDDefaultReminder.five.rawValue
            return TDDefaultReminder(rawValue: raw) ?? .five
        }
        set {
            sharedDefaults?.set(newValue.rawValue, forKey: "td_default_reminder_offset")
            objectWillChange.send()
        }
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

    /// 晒图时是否展示全部事件（默认展示全部，便于分享）
    var scheduleShareShowAllEvents: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.scheduleShareShowAllEvents) == nil {
                return true
            }
            return sharedDefaults?.bool(forKey: Keys.scheduleShareShowAllEvents) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.scheduleShareShowAllEvents); objectWillChange.send() }
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
    
    /// 任务列表排序方式（默认：自定义）
    var taskListSortType: Int {
        get {
            if sharedDefaults?.object(forKey: Keys.taskListSortType) == nil {
                return 0
            }
            return sharedDefaults?.integer(forKey: Keys.taskListSortType) ?? 0
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.taskListSortType); objectWillChange.send() }
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
            if let style = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")?.lowercased() {
                return style.contains("dark")
            }
            return false

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
            // 兼容旧 key，优先读取新 key
            if let value = sharedDefaults?.object(forKey: Keys.taskDescriptionLinesNew) as? Int {
                return min(max(value, 1), 5)
            }
            if let legacy = sharedDefaults?.object(forKey: Keys.taskDescriptionLines) as? Int {
                return min(max(legacy, 1), 5)
            }
            return 3 // 默认3行
        }
        set {
            let clamped = min(max(newValue, 1), 5)
            sharedDefaults?.set(clamped, forKey: Keys.taskDescriptionLinesNew)
            objectWillChange.send()
        }
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
    
    /// 今日未完成角标显示（默认开启）
    var showTodayBadge: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.showTodayBadge) == nil { return true }
            return sharedDefaults?.bool(forKey: Keys.showTodayBadge) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.showTodayBadge); objectWillChange.send() }
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
    
    /// 子任务默认展开（默认开启）
    var expandSubtask: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.expandSubtask) == nil { return true }
            return sharedDefaults?.bool(forKey: Keys.expandSubtask) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.expandSubtask); objectWillChange.send() }
    }
    /// 子任务全部完成时自动完成事件（默认开启）
    var autoCompleteWhenSubtasksDone: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.autoCompleteWhenSubtasksDone) == nil { return true }
            return sharedDefaults?.bool(forKey: Keys.autoCompleteWhenSubtasksDone) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.autoCompleteWhenSubtasksDone); objectWillChange.send() }
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
    
    /// 模块：番茄专注开关（默认开启）
    var enableTomatoFocus: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.enableTomatoFocus) == nil {
                return true
            }
            return sharedDefaults?.bool(forKey: Keys.enableTomatoFocus) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.enableTomatoFocus); objectWillChange.send() }
    }

    /// 模块：日程概览开关（默认开启）
    var enableScheduleOverview: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.enableScheduleOverview) == nil {
                return true
            }
            return sharedDefaults?.bool(forKey: Keys.enableScheduleOverview) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.enableScheduleOverview); objectWillChange.send() }
    }

    /// 当前选择的应用图标 ID（默认马尔斯绿）
    var appIconId: String {
        get { sharedDefaults?.string(forKey: Keys.appIconId) ?? "mars_green" }
        set { sharedDefaults?.set(newValue, forKey: Keys.appIconId); objectWillChange.send() }
    }

    /// 是否在 Dock 中显示应用图标（默认显示）
    var showDockIcon: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.showDockIcon) == nil {
                return true
            }
            return sharedDefaults?.bool(forKey: Keys.showDockIcon) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.showDockIcon); objectWillChange.send() }
    }

    /// 是否在 Dock 图标显示今天未完成任务数量（默认显示）
    var showDockBadge: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.showDockBadge) == nil {
                return true
            }
            return sharedDefaults?.bool(forKey: Keys.showDockBadge) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.showDockBadge); objectWillChange.send() }
    }
    
    /// 侧滑栏工作量热力图（默认开启）
    var showSidebarHeatmap: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.showSidebarHeatmap) == nil { return true }
            return sharedDefaults?.bool(forKey: Keys.showSidebarHeatmap) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.showSidebarHeatmap); objectWillChange.send() }
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
    

    /// 专注时长（分钟，默认25分钟）
    var focusDuration: Int {
        get {
            if sharedDefaults?.object(forKey: Keys.focusDuration) == nil {
                return 25 // 默认25分钟
            }
            return sharedDefaults?.integer(forKey: Keys.focusDuration) ?? 25
        }
        set {
            let clamped = min(max(newValue, 5), 120) // 限制为 5~120 分钟
            sharedDefaults?.set(clamped, forKey: Keys.focusDuration)
            objectWillChange.send()
        }
    }

    /// 休息时长（分钟，默认5分钟）
    var restDuration: Int {
        get {
            if sharedDefaults?.object(forKey: Keys.restDuration) == nil {
                return 5 // 默认5分钟
            }
            return sharedDefaults?.integer(forKey: Keys.restDuration) ?? 5
        }
        set {
            let clamped = min(max(newValue, 5), 120) // 限制为 5~120 分钟
            sharedDefaults?.set(clamped, forKey: Keys.restDuration)
            objectWillChange.send()
        }
    }

    /// 番茄专注：专注时屏幕常亮（默认开启）
    var focusKeepScreenOn: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.focusKeepScreenOn) == nil {
                return true
            }
            return sharedDefaults?.bool(forKey: Keys.focusKeepScreenOn) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.focusKeepScreenOn); objectWillChange.send() }
    }
    
    /// 番茄专注：推送通知（默认开启）
    var focusPushEnabled: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.focusPushEnabled) == nil {
                return true
            }
            return sharedDefaults?.bool(forKey: Keys.focusPushEnabled) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.focusPushEnabled); objectWillChange.send() }
    }
    
    /// 番茄专注：播放完成提示音（默认开启）
    var focusPlayFinishSound: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.focusPlayFinishSound) == nil {
                return true
            }
            return sharedDefaults?.bool(forKey: Keys.focusPlayFinishSound) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.focusPlayFinishSound); objectWillChange.send() }
    }

    
    /// 是否启用隐私保护模式（默认关闭）
    var isPrivacyModeEnabled: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.isPrivacyModeEnabled) == nil {
                return false // 默认关闭隐私保护模式
            }
            return sharedDefaults?.bool(forKey: Keys.isPrivacyModeEnabled) ?? false
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.isPrivacyModeEnabled); objectWillChange.send() }
    }

    /// 日历任务颜色识别模式（默认自动识别）
    var calendarTaskColorRecognition: TDCalendarTaskColorRecognition {
        get {
            if sharedDefaults?.object(forKey: Keys.calendarTaskColorRecognition) == nil {
                return .auto // 默认自动识别
            }
            return TDCalendarTaskColorRecognition(rawValue: sharedDefaults?.integer(forKey: Keys.calendarTaskColorRecognition) ?? 0) ?? .auto
        }
        set { sharedDefaults?.set(newValue.rawValue, forKey: Keys.calendarTaskColorRecognition); objectWillChange.send() }
    }
    
    /// 是否显示农历（默认显示）
    var showLunarCalendar: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.showLunarCalendar) == nil {
                return true // 默认显示农历
            }
            return sharedDefaults?.bool(forKey: Keys.showLunarCalendar) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.showLunarCalendar); objectWillChange.send() }
    }
    
    /// 是否显示专注功能（默认显示）
    var showFocusFeature: Bool {
        get {
            if sharedDefaults?.object(forKey: Keys.showFocusFeature) == nil {
                return true // 默认显示专注功能
            }
            return sharedDefaults?.bool(forKey: Keys.showFocusFeature) ?? true
        }
        set { sharedDefaults?.set(newValue, forKey: Keys.showFocusFeature); objectWillChange.send() }
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
