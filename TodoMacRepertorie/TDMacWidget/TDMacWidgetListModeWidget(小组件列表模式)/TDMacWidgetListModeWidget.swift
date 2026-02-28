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

        do {
            let context = try TDSharedSwiftDataStore.makeWidgetContext()
            let descriptor = descriptor(for: configuration, userId: user.userId, fetchLimit: fetchLimit)
            let tasks = try context.fetch(descriptor)

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

            // 标题 + 紧跟图标（不靠右）
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

            Spacer()
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
            return 5
        case .systemMedium:
            return 7
        case .systemLarge:
            return 15
        default:
            return 7
        }
    }
}

private struct TDWidgetUserView: View {
    let entry: TDWidgetIntentProvider.Entry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

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
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .imageScale(.large)
                        .frame(width: 20.0, height: 20.0)
                        .foregroundStyle(.tint)
                        .widgetAccentable()
                }
                .padding(.top, 12.0)

                if entry.isLoggedIn {
                    if entry.tasks.count > 0 {
                        VStack(alignment: .leading, spacing: 0.0) {
                            ForEach(entry.tasks) { model in
                                TDWidgetTaskRowView(task: model, isDark: widgetIsDark)
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
