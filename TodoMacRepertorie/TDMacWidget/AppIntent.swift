//
//  AppIntent.swift
//  TDMacWidget
//
//  列表类型小组件编辑配置：查看类型（Day Todo / 最近待办 / 分类清单）、分类选择、是否显示已过期
//  命名带 TD 前缀，后续其它小组件可单独定义自己的 Configuration Intent
//

import WidgetKit
import AppIntents

// MARK: - 列表类型 - 查看类型

enum TDWidgetListViewType: String, AppEnum {
    case dayTodo
    case recentTodos
    case categoryList

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "查看")
    }

    static var caseDisplayRepresentations: [TDWidgetListViewType: DisplayRepresentation] {
        [
            .dayTodo: DisplayRepresentation(title: "Day Todo"),
            .recentTodos: DisplayRepresentation(title: "最近待办"),
            .categoryList: DisplayRepresentation(title: "分类清单")
        ]
    }
}

// MARK: - 列表类型 - 分类实体（供配置里「分类清单」选择）

struct TDWidgetCategoryEntity: AppEntity {
    let categoryId: Int
    let categoryName: String

    var id: String { "\(categoryId)" }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "分类清单")
    }

    static var defaultQuery = TDWidgetCategoryQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(categoryName)")
    }
}

struct TDWidgetCategoryQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [TDWidgetCategoryEntity] {
        let userId = TDWidgetUserSession.currentUser()?.userId ?? -1
        let categories = TDCategoryManager.shared.loadLocalCategories(userId: userId)
        return identifiers.compactMap { id -> TDWidgetCategoryEntity? in
            guard let cid = Int(id) else { return nil }
            return categories.first { $0.categoryId == cid }.map {
                TDWidgetCategoryEntity(categoryId: $0.categoryId, categoryName: $0.categoryName)
            }
        }
    }

    func suggestedEntities() async throws -> [TDWidgetCategoryEntity] {
        let userId = TDWidgetUserSession.currentUser()?.userId ?? -1
        let categories = TDCategoryManager.shared.loadLocalCategories(userId: userId)
        return categories
            .filter { $0.categoryId > 0 && ($0.folderIs != true) }
            .map { TDWidgetCategoryEntity(categoryId: $0.categoryId, categoryName: $0.categoryName) }
    }
}

// MARK: - 列表类型编辑（仅用于列表模式小组件，其它小组件可另建 Intent）

struct TDListTypeConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "列表类型编辑" }
    static var description: IntentDescription { "选择小组件要显示的列表类型与选项（Day Todo / 最近待办 / 分类清单）" }

    /// 查看：Day Todo / 最近待办 / 分类清单
    @Parameter(title: "查看", default: .dayTodo)
    var viewType: TDWidgetListViewType

    /// 分类清单（仅当 viewType 为 分类清单 时显示）
    @Parameter(title: "分类清单")
    var category: TDWidgetCategoryEntity?

    /// 是否显示已过期（仅当 最近待办 或 分类清单 时显示）
    @Parameter(title: "显示已过期", default: true)
    var showExpired: Bool

    /// 是否自动夜间模式（放在编辑项最后一行；关闭则永远按白天模式渲染）
    @Parameter(title: "自动夜间模式", default: true)
    var autoNightMode: Bool

    /// 根据「查看」类型决定展示的配置项：Day Todo 只显示查看；最近待办 多显示「显示已过期」；分类清单 多显示「分类清单」+「显示已过期」
    static var parameterSummary: some ParameterSummary {
        When(\.$viewType, .equalTo, TDWidgetListViewType.dayTodo) {
            Summary("查看 \(\.$viewType)") {
                \.$autoNightMode
            }
        } otherwise: {
            When(\.$viewType, .equalTo, TDWidgetListViewType.recentTodos) {
                Summary("查看 \(\.$viewType)") {
                    \.$showExpired
                    \.$autoNightMode
                }
            } otherwise: {
                Summary("查看 \(\.$viewType)") {
                    \.$category
                    \.$showExpired
                    \.$autoNightMode
                }
            }
        }
    }
}

// MARK: - 列表小组件：切换完成状态（点击左侧完成按钮）

struct TDWidgetListToggleCompleteIntent: AppIntent {
    static var title: LocalizedStringResource = "切换完成状态"

    @Parameter(title: "taskId")
    var taskId: String

    /// 让调用方可以直接用 String 创建 intent（否则会要求 IntentParameter<String>）
    init(taskId: String) {
        self.taskId = taskId
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        // 对齐主 App：先改本地数据（走 TDQueryConditionManager 的通用更新方法），再走同步推送流程
        guard let user = TDWidgetUserSession.currentUser() else { return .result() }

        // 让共享的 TDUserManager 在 Widget 进程里也有 token/userId（TDNetworkManager/QueryBuilder 依赖它）
        TDUserManager.shared.currentUser = user
        TDUserManager.shared.currentUserId = user.userId
        do {
            let context = try TDSharedSwiftDataStore.makeWidgetContext()

            // 1) 读取本地任务（复用主 App 方法，依赖 TDUserManager.userId）
            guard let task = try await TDQueryConditionManager.shared.getLocalTaskByTaskId(taskId: taskId, context: context) else {
                return .result()
            }

            // 2) 先改本地（复用主 App 通用更新方法：version/status/syncTime/索引等都在里面）
            let updatedTask = task
            updatedTask.complete = !task.complete
            _ = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(updatedTask: updatedTask, context: context)

            // 3) 再走同步推送（复用主 App 的数据组装与回写）
            if let tasksJson = try await TDQueryConditionManager.shared.getLocalUnsyncedDataAsJson(context: context),
               !tasksJson.isEmpty {
                let results = try await TDTaskAPI.shared.syncPushData(tasksJson: tasksJson)
                try await TDQueryConditionManager.shared.markTasksAsSynced(results: results, context: context)
            }
        } catch {
            // widget intent 里不抛 UI 错误，保持静默
        }
        return .result()
    }
}


// MARK: - 日程概览（周/月）小组件编辑

struct TDScheduleOverviewConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "日程概览编辑" }
    static var description: IntentDescription { "配置日程概览小组件选项（添加事件按钮、自动夜间模式）" }

    /// 是否显示右下角「添加事件」按钮
    @Parameter(title: "添加事件", default: true)
    var showAddButton: Bool

    /// 是否自动夜间模式（关闭则永远按白天模式渲染）
    @Parameter(title: "自动夜间模式", default: true)
    var autoNightMode: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("日程概览") {
            \.$showAddButton
            \.$autoNightMode
        }
    }
}

// MARK: - AppGroup（给小组件存储“当前显示的周/月”用）

private enum TDWidgetAppGroup {
    static let id = "group.com.TodoMacRepertorie.mac"
    static let defaults = UserDefaults(suiteName: id)
}

enum TDWidgetScheduleOverviewState {
    private static let monthAnchorKey = "td_widget_schedule_overview_month_anchor_ms"
    private static let weekAnchorKey = "td_widget_schedule_overview_week_anchor_ms"
    
    private static func isReasonable(_ date: Date, relativeTo now: Date) -> Bool {
        // 防御：避免 AppGroup 残留/异常值把小组件固定到很远的过去/未来
        let cal = Calendar.current
        let base = now.firstDayOfMonth
        let target = date.firstDayOfMonth
        let diff = cal.dateComponents([.month], from: base, to: target).month ?? 0
        return abs(diff) <= 24
    }

    static func monthAnchorDate() -> Date {
        let now = Date()
        let d = TDWidgetAppGroup.defaults
        let ms = d?.object(forKey: monthAnchorKey) as? Int64
        if let ms, ms > 0 {
            let candidate = Date(timeIntervalSince1970: TimeInterval(Double(ms) / 1000.0)).firstDayOfMonth
            if isReasonable(candidate, relativeTo: now) {
                return candidate
            } else {
                d?.removeObject(forKey: monthAnchorKey)
                return now.firstDayOfMonth
            }
        }
        return now.firstDayOfMonth
    }

    static func weekAnchorDate() -> Date {
        let now = Date()
        let d = TDWidgetAppGroup.defaults
        let ms = d?.object(forKey: weekAnchorKey) as? Int64
        if let ms, ms > 0 {
            let candidate = Date(timeIntervalSince1970: TimeInterval(Double(ms) / 1000.0))
            if isReasonable(candidate, relativeTo: now) {
                return candidate
            } else {
                d?.removeObject(forKey: weekAnchorKey)
                return now
            }
        }
        return now
    }

    static func shiftMonth(by delta: Int) {
        let base = monthAnchorDate()
        let next = base.adding(months: delta).firstDayOfMonth
        TDWidgetAppGroup.defaults?.set(next.startOfDayTimestamp, forKey: monthAnchorKey)
    }

    static func shiftWeek(by deltaWeeks: Int) {
        let base = weekAnchorDate()
        let next = base.adding(days: deltaWeeks * 7)
        TDWidgetAppGroup.defaults?.set(next.startOfDayTimestamp, forKey: weekAnchorKey)
    }
}

// MARK: - 日程概览小组件：左右切换（周/月）

/// 以下为月视图事件获取月份点击事件（与列表小组件“完成按钮”一致，走 AppIntent 刷新小组件）
struct TDCalendrEventChangeMonthClick: AppIntent {
    static var title: LocalizedStringResource = "TDCalendrEventChangeMonthClick"
    static var description: IntentDescription = IntentDescription("TDCalendrEventChangeMonthClick")

    /// 传入 -1 表示上个月，+1 表示下个月
    @Parameter(title: "month")
    var month: Int

    init(month: Int) {
        self.month = month
    }

    init() {
        self.month = 0
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        TDWidgetScheduleOverviewState.shiftMonth(by: month)
        WidgetCenter.shared.reloadTimelines(ofKind: TDWidgetKind.scheduleOverview)
        return .result()
    }
}

/// 周视图左右切换：-1 上周，+1 下周
struct TDCalendrEventChangeWeekClick: AppIntent {
    static var title: LocalizedStringResource = "TDCalendrEventChangeWeekClick"
    static var description: IntentDescription = IntentDescription("TDCalendrEventChangeWeekClick")

    @Parameter(title: "week")
    var week: Int

    init(week: Int) {
        self.week = week
    }

    init() {
        self.week = 0
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        TDWidgetScheduleOverviewState.shiftWeek(by: week)
        WidgetCenter.shared.reloadTimelines(ofKind: TDWidgetKind.scheduleOverview)
        return .result()
    }
}


// MARK: - 月历 + 日清单小组件编辑

struct TDMonthDayListConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "月历日清单编辑" }
    static var description: IntentDescription { "配置月历日清单小组件选项（自动夜间模式）" }
    
    @Parameter(title: "自动夜间模式", default: true)
    var autoNightMode: Bool
    
    static var parameterSummary: some ParameterSummary {
        Summary("月历日清单") {
            \.$autoNightMode
        }
    }
}


// MARK: - 月历 + 日清单小组件（左月历可点，右侧按选中日期显示 DayTodo）

enum TDWidgetMonthDayListState {
    private static let monthAnchorKey = "td_widget_month_day_list_month_anchor_ms"
    private static let selectedDateKey = "td_widget_month_day_list_selected_date_ms"
    
    private static func isReasonable(_ date: Date, relativeTo now: Date) -> Bool {
        let cal = Calendar.current
        let base = now.firstDayOfMonth
        let target = date.firstDayOfMonth
        let diff = cal.dateComponents([.month], from: base, to: target).month ?? 0
        return abs(diff) <= 24
    }
    
    static func monthAnchorDate() -> Date {
        let now = Date()
        let d = TDWidgetAppGroup.defaults
        let ms = d?.object(forKey: monthAnchorKey) as? Int64
        if let ms, ms > 0 {
            let candidate = Date(timeIntervalSince1970: TimeInterval(Double(ms) / 1000.0)).firstDayOfMonth
            if isReasonable(candidate, relativeTo: now) {
                return candidate
            } else {
                // AppGroup 异常/残留值：重置为本月，并同步重置选中日期为今天
                let resetMonth = now.firstDayOfMonth
                d?.set(resetMonth.startOfDayTimestamp, forKey: monthAnchorKey)
                d?.set(now.startOfDayTimestamp, forKey: selectedDateKey)
                return resetMonth
            }
        }
        return now.firstDayOfMonth
    }
    
    static func selectedDate() -> Date {
        let anchor = monthAnchorDate()
        let now = Date()
        let d = TDWidgetAppGroup.defaults
        let ms = d?.object(forKey: selectedDateKey) as? Int64
        if let ms, ms > 0 {
            let candidate = Date(timeIntervalSince1970: TimeInterval(Double(ms) / 1000.0))
            // 如果外部写入了非当前月的日期（理论上不会），回退到默认规则，避免 UI 与数据不一致
            if candidate.isSameMonth(as: anchor), isReasonable(candidate, relativeTo: now) {
                return candidate
            }
        }
        let fallback = defaultSelectedDate(for: anchor)
        d?.set(fallback.startOfDayTimestamp, forKey: selectedDateKey)
        return fallback
    }
    
    static func setSelectedDate(_ date: Date) {
        TDWidgetAppGroup.defaults?.set(date.startOfDayTimestamp, forKey: selectedDateKey)
    }
    
    static func shiftMonth(by delta: Int) {
        let base = monthAnchorDate()
        let nextMonth = base.adding(months: delta).firstDayOfMonth
        TDWidgetAppGroup.defaults?.set(nextMonth.startOfDayTimestamp, forKey: monthAnchorKey)
        
        let nextSelected = defaultSelectedDate(for: nextMonth)
        TDWidgetAppGroup.defaults?.set(nextSelected.startOfDayTimestamp, forKey: selectedDateKey)
    }
    
    private static func defaultSelectedDate(for month: Date) -> Date {
        // 切换日期：
        // - 如果是当月：默认选中今天
        // - 不是当月：默认选中当月第一天
        if month.isSameMonth(as: Date()) {
            return Date()
        }
        return month.firstDayOfMonth
    }
}

// MARK: - 月历 + 日清单小组件：切换月份 / 选择日期

struct TDWidgetMonthDayListChangeMonthIntent: AppIntent {
    static var title: LocalizedStringResource = "TDWidgetMonthDayListChangeMonthIntent"
    static var description: IntentDescription = IntentDescription("月历日清单小组件：切换月份")
    
    @Parameter(title: "month")
    var month: Int
    
    init(month: Int) {
        self.month = month
    }
    
    init() {
        self.month = 0
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        TDWidgetMonthDayListState.shiftMonth(by: month)
        WidgetCenter.shared.reloadTimelines(ofKind: TDWidgetKind.monthDayList)
        return .result()
    }
}

struct TDWidgetMonthDayListSelectDateIntent: AppIntent {
    static var title: LocalizedStringResource = "TDWidgetMonthDayListSelectDateIntent"
    static var description: IntentDescription = IntentDescription("月历日清单小组件：选择日期")
    
    @Parameter(title: "date")
    var date: Date
    
    init(date: Date) {
        self.date = date
    }
    
    init() {
        self.date = Date()
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        TDWidgetMonthDayListState.setSelectedDate(date)
        WidgetCenter.shared.reloadTimelines(ofKind: TDWidgetKind.monthDayList)
        return .result()
    }
}


// MARK: - 番茄专注小组件：开始/放弃（按钮用法同“列表完成按钮”）

struct TDWidgetFocusToggleIntent: AppIntent {
    static var title: LocalizedStringResource = "番茄专注：开始/放弃"

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let user = TDWidgetUserSession.currentUser() else { return .result() }

        // 让共享的 TDUserManager 在 Widget 进程里也有 token/userId（网络与 SwiftData 依赖它）
        TDUserManager.shared.currentUser = user
        TDUserManager.shared.currentUserId = user.userId

        let store = TDFocusSessionStore.shared
        store.refreshFromDefaults()

        if store.state.phase == .idle {
            store.start(
                focusMinutes: TDSettingManager.shared.focusDuration,
                restMinutes: TDSettingManager.shared.restDuration,
                taskId: nil,
                taskContent: nil,
                owner: .widget
            )
        } else {
            await store.abandon()
        }

        WidgetCenter.shared.reloadTimelines(ofKind: TDWidgetKind.focus)
        return .result()
    }
}

