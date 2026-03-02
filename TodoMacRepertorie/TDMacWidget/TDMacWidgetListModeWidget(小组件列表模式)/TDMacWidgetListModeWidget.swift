//
//  TDMacWidgetListModeWidget.swift
//  TDMacWidget
//
//  列表模式小组件：支持 Day Todo / 最近待办 / 分类清单，可配置是否显示已过期
//

import WidgetKit
import SwiftUI
import Foundation
import SwiftData
import AppIntents

private struct TDWidgetUserEntry: TimelineEntry {
    let date: Date
    /// 与 Demo 一致：Entry 必须持有 configuration，系统据此识别为可编辑小组件并弹出编辑界面
    let configuration: TDListTypeConfigurationIntent
    let isLoggedIn: Bool
    let userId: Int
    let userName: String
    /// 当前查看类型标题（Day Todo / 最近待办 / 分类名）
    let viewTitle: String
    /// 统计：已完成 / 未完成（仅 DayTodo 显示数字，其它类型仍计算但不展示）
    let completedCount: Int
    let totalCount: Int
    /// 标题颜色：DayTodo / 最近待办 用主题 5 级色，分类清单用自身颜色
    let titleColor: Color
    /// 完整任务列表（直接使用主 App 的 SwiftData 模型，未完成优先已由 descriptor 排序保证）
    let tasks: [TDMacSwiftDataListModel]
    let swiftDataError: String?
}

private struct TDWidgetIntentProvider: AppIntentTimelineProvider {
    typealias Intent = TDListTypeConfigurationIntent

    func placeholder(in context: Context) -> TDWidgetUserEntry {
        TDWidgetUserEntry(
            date: .now,
            configuration: TDListTypeConfigurationIntent(),
            isLoggedIn: false,
            userId: -1,
            userName: "未登录",
            viewTitle: "Day Todo",
            completedCount: 0,
            totalCount: 0,
            titleColor: TDThemeManager.shared.primaryTintColor(),
            tasks: [],
            swiftDataError: nil
        )
    }

    func snapshot(for configuration: TDListTypeConfigurationIntent, in context: Context) async -> TDWidgetUserEntry {
        await entry(for: configuration, family: context.family)
    }

    func timeline(for configuration: TDListTypeConfigurationIntent, in context: Context) async -> Timeline<TDWidgetUserEntry> {
        let entry = await entry(for: configuration, family: context.family)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(15 * 60)
        return Timeline(entries: [entry], policy: .after(next))
    }

    private func entry(for configuration: TDListTypeConfigurationIntent, family: WidgetFamily) async -> TDWidgetUserEntry {
        let viewTitle = viewTitle(for: configuration)
        guard let user = TDWidgetUserSession.currentUser() else {
            return TDWidgetUserEntry(
                date: .now,
                configuration: configuration,
                isLoggedIn: false,
                userId: -1,
                userName: "未登录",
                viewTitle: viewTitle,
                completedCount: 0,
                totalCount: 0,
                titleColor: TDThemeManager.shared.primaryTintColor(),
                tasks: [],
                swiftDataError: nil
            )
        }

        let fetchLimit = TDWidgetTaskDisplayLimit.value(for: family)
        let prefetchLimit = TDWidgetTaskDisplayLimit.prefetchValue(
            displayLimit: fetchLimit,
            repeatPerGroupLimit: TDSettingManager.shared.repeatNum,
            viewType: configuration.viewType
        )

        do {
            let context = try TDSharedSwiftDataStore.makeWidgetContext()
            let descriptor = descriptor(for: configuration, userId: user.userId, fetchLimit: prefetchLimit)
            let rawTasks = try context.fetch(descriptor)
            let tasks = TDWidgetTaskRepeatLimiter.apply(
                rawTasks,
                viewType: configuration.viewType,
                perRepeatGroupLimit: TDSettingManager.shared.repeatNum,
                overallDisplayLimit: fetchLimit
            )

            let completedCount = tasks.filter { $0.complete }.count
            let totalCount = tasks.count

            // 标题颜色：DayTodo / 最近待办 用主题 5 级色，分类清单用清单自身颜色
            let titleColor: Color
            switch configuration.viewType {
            case .dayTodo, .recentTodos:
                titleColor = TDThemeManager.shared.primaryTintColor()
            case .categoryList:
                if let categoryId = configuration.category?.categoryId {
                    let categories = TDCategoryManager.shared.loadLocalCategories(userId: user.userId)
                    if let category = categories.first(where: { $0.categoryId == categoryId }),
                       let hex = category.categoryColor {
                        titleColor = Color.fromHex(hex)
                    } else {
                        titleColor = TDThemeManager.shared.primaryTintColor()
                    }
                } else {
                    titleColor = TDThemeManager.shared.primaryTintColor()
                }
            }

            return TDWidgetUserEntry(
                date: .now,
                configuration: configuration,
                isLoggedIn: true,
                userId: user.userId,
                userName: user.userName,
                viewTitle: viewTitle,
                completedCount: completedCount,
                totalCount: totalCount,
                titleColor: titleColor,
                tasks: tasks,
                swiftDataError: nil
            )
        } catch {
            return TDWidgetUserEntry(
                date: .now,
                configuration: configuration,
                isLoggedIn: true,
                userId: user.userId,
                userName: user.userName,
                viewTitle: viewTitle,
                completedCount: 0,
                totalCount: 0,
                titleColor: TDThemeManager.shared.primaryTintColor(),
                tasks: [],
                swiftDataError: "\(error)"
            )
        }
    }

    private func viewTitle(for configuration: TDListTypeConfigurationIntent) -> String {
        switch configuration.viewType {
        case .dayTodo:
            return "Day Todo"
        case .recentTodos:
            return "最近待办"
        case .categoryList:
            return configuration.category?.categoryName ?? "分类清单"
        }
    }

    private func descriptor(
        for configuration: TDListTypeConfigurationIntent,
        userId: Int,
        fetchLimit: Int
    ) -> FetchDescriptor<TDMacSwiftDataListModel> {
        switch configuration.viewType {
        case .dayTodo:
            return TDWidgetTaskFetchDescriptorFactory.dayTodoToday(userId: userId, fetchLimit: fetchLimit)
        case .recentTodos:
            return TDWidgetTaskFetchDescriptorFactory.taskListSuperset(
                userId: userId,
                categoryId: -101,
                tagFilter: "",
                fetchLimit: fetchLimit,
                showExpired: configuration.showExpired
            )
        case .categoryList:
            let categoryId = configuration.category?.categoryId ?? 0
            return TDWidgetTaskFetchDescriptorFactory.taskListSuperset(
                userId: userId,
                categoryId: categoryId > 0 ? categoryId : -101,
                tagFilter: "",
                fetchLimit: fetchLimit,
                showExpired: configuration.showExpired
            )
        }
    }
}

/// 小组件单行任务：选中框 + 难度色条 + 标题 + 提醒/重复/子任务图标（尽量复用主 App 逻辑）
private struct TDWidgetTaskRowView: View {
    let task: TDMacSwiftDataListModel
    /// 是否按“自动夜间模式 + 系统暗色”渲染（不写回任何设置，避免影响主 App）
    let isDark: Bool
    /// 仅 最近待办 / 分类清单 需要：标题后追加日期；Day Todo 不显示日期（对齐主 App）
    let showsInlineDate: Bool

    private var checkboxColor: Color {
        if TDSettingManager.shared.checkboxFollowCategoryColor, task.standbyInt1 > 0, !task.standbyIntColor.isEmpty {
            return Color.fromHex(task.standbyIntColor)
        }
        return TDThemeManager.shared.currentTheme.baseColors.descriptionText.color(isDark: isDark)
    }
    private var difficultyColor: Color { task.difficultyColor }
    private var titleColor: Color {
        if task.complete {
            return TDThemeManager.shared.currentTheme.baseColors.descriptionText.color(isDark: isDark)
        }
        return TDThemeManager.shared.currentTheme.baseColors.titleText.color(isDark: isDark)
    }

    private var inlineDateText: String? {
        guard showsInlineDate else { return nil }
        return TDWidgetTaskInlineDateLabel.text(for: task)
    }
    private var inlineDateColor: Color {
        TDWidgetTaskInlineDateLabel.color(for: task, isDark: isDark)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 5.0) {
            // 完成按钮：可点击（与主 App 切换完成一致），尺寸/间距对齐你给的 iOS 版
            Button(intent: TDWidgetListToggleCompleteIntent(taskId: task.taskId)) {
                Image(systemName: task.complete ? "checkmark.square.fill" : "square")
                    .resizable()
                    .imageScale(.small)
                    .frame(width: 14.0, height: 14.0)
                    .foregroundColor(checkboxColor)
            }
            .frame(width: 15.0, height: 15.0)
            .tint(.clear)
            .buttonStyle(.plain)

            // 难度标识：仅 > 5 时显示（对齐你图里的规则）
            if task.snowAssess > 5 {
                RoundedRectangle(cornerRadius: 2.0)
                    .fill(difficultyColor)
                    .frame(width: 4.0, height: 12.0)
            }

            // 左侧：标题 + 紧跟图标（不靠右）
            HStack(alignment: .center, spacing: 4.0) {
                Text(task.taskContent)
                    .font(.system(size: 13, weight: .regular))
                    // 字体颜色必须复用主 App 的主题文字色（baseColors），并由 isDark 决定深浅色
                    .foregroundColor(titleColor)
                    .strikethrough(
                        task.complete && TDSettingManager.shared.showCompletedTaskStrikethrough,
                        color: titleColor
                    )
                    .opacity(task.complete ? 0.6 : 1.0)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .fixedClipped()

                // 图标紧跟文字，颜色用主题色 5 级；尺寸按你贴的写
                if task.hasReminder {
                    Image("icon_reminder")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(.tint)
                        .widgetAccentable()
                }
                if task.hasRepeat {
                    Image("icon_repeat")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(.tint)
                        .widgetAccentable()
                }
                if task.hasSubTasks {
                    Image("icon_subtask")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 10, height: 10)
                        .foregroundStyle(.tint)
                        .widgetAccentable()
                }
            }
            // 注意：不要用 maxWidth: .infinity 把空间全部吃掉，否则右侧日期会被挤没
            .layoutPriority(0)

            Spacer(minLength: 0)

            // 右侧：日期（自适应宽度，始终贴右）
            if let dateText = inlineDateText, !dateText.isEmpty {
                Text(dateText)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(inlineDateColor)
                    .lineLimit(1)
                    // 关键：日期不被压缩；标题先截断
                    .fixedSize(horizontal: true, vertical: false)
                    .layoutPriority(1)
            }
        }
        // 行内图标使用主题 5 级色（不跟随分类标题色）
        .tint(TDThemeManager.shared.primaryTintColor(isDark: isDark))
        // 行间距再小 1：按你要求，行高从 22 降到 21
        .frame(height: 21.0)
    }
}

private enum TDWidgetTaskDisplayLimit {
    static func value(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall:
            return 6
        case .systemMedium:
            return 6
        case .systemLarge:
            return 14
        default:
            return 6
        }
    }

    /// 为了在“重复事件限制”过滤后仍能填满显示行数：预取更多数据再在内存里裁剪到 displayLimit
    static func prefetchValue(
        displayLimit: Int,
        repeatPerGroupLimit: Int,
        viewType: TDWidgetListViewType
    ) -> Int {
        // Day Todo 不需要重复组限制（且列表通常更短），避免不必要的额外 fetch
        guard viewType != .dayTodo else { return displayLimit }
        // 设置为“全部(0)”时不做限制：不必额外预取
        guard repeatPerGroupLimit > 0 else { return displayLimit }
        // 经验值：最多拉 5 倍，避免重复组过多导致过滤后不够行
        return min(max(displayLimit * 5, displayLimit), 200)
    }
}

// MARK: - 小组件：标题后日期（最近待办 / 分类清单）

private enum TDWidgetTaskInlineDateLabel {
    /// 显示文本：过期/后续日期显示“月日”；今天/明天/后天显示文字；无日期不显示
    static func text(for task: TDMacSwiftDataListModel) -> String? {
        if task.todoTime == 0 { return nil }

        let date = Date.fromTimestamp(task.todoTime)
        if date.isToday { return "今天" }
        if date.isTomorrow { return "明天" }
        if date.isDayAfterTomorrow { return "后天" }
        return monthDayString(date)
    }

    /// 颜色规则：
    /// - 已过期：红色（固定新年红 5 级）
    /// - 今天/明天/后天：主题色（5 级，全局统一入口）
    /// - 后续日期/无日期：描述文字色（适配深浅色）
    static func color(for task: TDMacSwiftDataListModel, isDark: Bool) -> Color {
        // 无日期（理论上不会走到这里：text=nil 不渲染）
        if task.todoTime == 0 { return TDThemeManager.shared.currentTheme.baseColors.descriptionText.color(isDark: isDark) }

        let date = Date.fromTimestamp(task.todoTime)
        if date.isOverdue {
            return TDThemeManager.shared.fixedColor(themeId: "new_year_red", level: TDThemeManager.primaryTintColorLevel)
        }
        if date.isToday || date.isTomorrow || date.isDayAfterTomorrow {
            return TDThemeManager.shared.primaryTintColor(isDark: isDark)
        }
        return TDThemeManager.shared.currentTheme.baseColors.descriptionText.color(isDark: isDark)
    }

    private static func monthDayString(_ date: Date) -> String {
        // “月日”短格式：避免占用标题空间
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: date)
    }
}

// MARK: - 小组件：重复事件显示数量限制（与主 App 设置一致）

private enum TDWidgetTaskRepeatLimiter {
    /// - Parameters:
    ///   - perRepeatGroupLimit: 0 表示全部；>0 表示同一 standbyStr1（重复ID）最多显示 N 条
    static func apply(
        _ tasks: [TDMacSwiftDataListModel],
        viewType: TDWidgetListViewType,
        perRepeatGroupLimit: Int,
        overallDisplayLimit: Int
    ) -> [TDMacSwiftDataListModel] {
        // DayTodo：不做重复组过滤（对齐主 App 列表：DayTodo 主要按当天展示）
        guard viewType != .dayTodo else {
            return Array(tasks.prefix(overallDisplayLimit))
        }
        // 设置为“全部”
        guard perRepeatGroupLimit > 0 else {
            return Array(tasks.prefix(overallDisplayLimit))
        }

        // 重复事件显示个数限制：只在“后续日程（>后天）”生效
        let dayAfterTomorrowStart: Int64 = Date().adding(days: 2).startOfDayTimestamp

        var repeatCounts: [String: Int] = [:]
        var result: [TDMacSwiftDataListModel] = []
        result.reserveCapacity(min(tasks.count, overallDisplayLimit))

        for task in tasks {
            // 仅当任务属于“后续日程”且有重复ID时才限制
            if task.todoTime > dayAfterTomorrowStart, let rid = task.standbyStr1, !rid.isEmpty {
                let next = (repeatCounts[rid] ?? 0) + 1
                if next > perRepeatGroupLimit { continue }
                repeatCounts[rid] = next
            }

            result.append(task)
            if result.count >= overallDisplayLimit { break }
        }

        return result
    }
}

private struct TDWidgetUserView: View {
    let entry: TDWidgetIntentProvider.Entry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    
    private var widgetCategoryId: Int {
        switch entry.configuration.viewType {
        case .dayTodo:
            return -100
        case .recentTodos:
            return -101
        case .categoryList:
            return entry.configuration.category?.categoryId ?? -101
        }
    }
    
    private func deepLinkURL(taskId: String? = nil, action: String? = nil) -> URL {
        var comps = URLComponents()
        comps.scheme = "todomac"
        comps.host = "widget"
        var items: [URLQueryItem] = [
            URLQueryItem(name: "categoryId", value: "\(widgetCategoryId)")
        ]
        if let action, !action.isEmpty {
            items.append(URLQueryItem(name: "action", value: action))
        }
        if let taskId, !taskId.isEmpty {
            items.append(URLQueryItem(name: "taskId", value: taskId))
        }
        comps.queryItems = items
        return comps.url ?? URL(string: "todomac://widget?categoryId=\(widgetCategoryId)")!
    }

    var body: some View {
        // 小组件最终的深浅色开关：
        // - 自动夜间模式：跟随系统 colorScheme
        // - 关闭自动夜间模式：永远按白天（isDark=false）渲染
        let widgetIsDark = entry.configuration.autoNightMode ? (colorScheme == .dark) : false
        // Header 的 tint：DayTodo/最近待办跟随系统深浅色；分类清单保持分类色不变
        let headerTint: Color = {
            switch entry.configuration.viewType {
            case .categoryList:
                return entry.titleColor
            case .dayTodo, .recentTodos:
                return TDThemeManager.shared.primaryTintColor(isDark: widgetIsDark)
            }
        }()

        // 按你贴的 iOS 结构：外层 ZStack 背景填满 + .edgesIgnoringSafeArea(.all)（这里用 ignoresSafeArea 等价）
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .center, spacing: 5.0) {
                HStack {
                    let isDayTodo = entry.configuration.viewType == .dayTodo
                    let titleText: String = {
                        if isDayTodo {
                            return "\(entry.viewTitle) \(entry.completedCount)/\(entry.totalCount)"
                        } else {
                            return entry.viewTitle
                        }
                    }()

                    Text(titleText)
                        .font(.system(size: 15.0, weight: .bold))
                        // 让小组件在“强调色/单色”渲染模式下也能使用自定义主题色
                        .foregroundStyle(.tint)
                        .widgetAccentable()
                        .lineLimit(1)
                    Spacer()
                    Link(destination: deepLinkURL(action: "add")) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .imageScale(.large)
                            .frame(width: 20.0, height: 20.0)
                            .foregroundStyle(.tint)
                            .widgetAccentable()
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 12.0)

                if entry.isLoggedIn {
                    if entry.tasks.count > 0 {
                        VStack(alignment: .leading, spacing: 0.0) {
                            ForEach(entry.tasks) { model in
                                TDWidgetTaskRowView(
                                    task: model,
                                    isDark: widgetIsDark,
                                    showsInlineDate: entry.configuration.viewType != .dayTodo
                                )
                                    .overlay {
                                        Link(destination: deepLinkURL(taskId: model.taskId)) {
                                            Color.clear
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        }
                                        .buttonStyle(.plain)
                                        // 让左侧“完成按钮”保留可点击区域
                                        .padding(.leading, 24)
                                    }
                            }
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    } else if entry.swiftDataError == nil {
                        // 空态：这里先保持简单文案（项目里暂无 logo_todo_lou 资源）
                        ZStack {
                            Text("暂无任务")
                                .font(.system(size: 12))
                                .foregroundColor(TDThemeManager.shared.currentTheme.baseColors.descriptionText.color(isDark: widgetIsDark))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    if let err = entry.swiftDataError, !err.isEmpty {
                        Text("SwiftData读取失败")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.red)
                        Text(err)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                } else {
                    Text("未登录")
                        .font(.system(size: 12))
                        .foregroundColor(TDThemeManager.shared.currentTheme.baseColors.descriptionText.color(isDark: widgetIsDark))
                }
            }
            .padding(.horizontal, 12.0)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        }
        // 把我们计算出的 tint 作为强调色，供 .widgetAccentable() / .foregroundStyle(.tint) 使用
        // 关键：跟随系统深浅色切换，避免“背景变了但字体/图标不变”
        .tint(headerTint)
        // 点击小组件空白区域：默认打开主 App 并切到对应模式
        .widgetURL(deepLinkURL())
        // 系统要求：Widget 背景使用 containerBackground API（否则会出现 “Please adopt containerBackground API”）
        // 自动夜间模式：跟随系统 colorScheme；关闭则永远使用白天模式（白底）
        .containerBackground(for: .widget) {
            widgetIsDark ? Color.black.opacity(0.25) : Color.white
        }
    }
}

/// 列表模式小组件：可配置 Day Todo / 最近待办 / 分类清单，及是否显示已过期
struct TDMacWidgetListModeWidget: Widget {
    let kind: String = TDWidgetKind.listMode

    var body: some WidgetConfiguration {
        // macOS Widget Extension 的部署目标是 14.0（project.pbxproj 已设置），这里可以直接使用 contentMarginsDisabled
        AppIntentConfiguration(
            kind: kind,
            intent: TDListTypeConfigurationIntent.self,
            provider: TDWidgetIntentProvider()
        ) { entry in
            TDWidgetUserView(entry: entry)
        }
        .configurationDisplayName("列表模式")
        .description("快速查看任务。添加后右键点击小组件选「编辑」可配置：查看（Day Todo / 最近待办 / 分类清单）、显示已过期等。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
