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
