//
//  TDMacWidgetMonthDayListWidget.swift
//  TDMacWidget
//
//  月历 + 日清单小组件：
//  - 左侧：只显示当月日期（不显示上/下月补齐日期），按主 App「周起始」排列，可点击选择日期
//  - 右侧：按选中日期展示 DayTodo 同款列表（含可点击完成按钮）；无数据/未登录显示空态图标
//

import WidgetKit
import SwiftUI
import SwiftData
import Foundation
import AppIntents

private struct TDMonthDayListEntry: TimelineEntry {
    let date: Date
    let configuration: TDMonthDayListConfigurationIntent
    let monthAnchor: Date
    let selectedDate: Date
    let isLoggedIn: Bool
    let userId: Int
    let userName: String
    let tasks: [TDMacSwiftDataListModel]
    let swiftDataError: String?
}

private struct TDMonthDayListProvider: AppIntentTimelineProvider {
    typealias Intent = TDMonthDayListConfigurationIntent

    func placeholder(in context: Context) -> TDMonthDayListEntry {
        // placeholder 用“今天/本月”，不要读 AppGroup 持久化（避免残留状态展示成 2031 之类异常日期）
        let month = Date().firstDayOfMonth
        return TDMonthDayListEntry(
            date: .now,
            configuration: TDMonthDayListConfigurationIntent(),
            monthAnchor: month,
            selectedDate: Date(),
            isLoggedIn: false,
            userId: -1,
            userName: "未登录",
            tasks: [],
            swiftDataError: nil
        )
    }

    func snapshot(for configuration: TDMonthDayListConfigurationIntent, in context: Context) async -> TDMonthDayListEntry {
        await entry(for: configuration, family: context.family)
    }

    func timeline(for configuration: TDMonthDayListConfigurationIntent, in context: Context) async -> Timeline<TDMonthDayListEntry> {
        let entry = await entry(for: configuration, family: context.family)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(15 * 60)
        return Timeline(entries: [entry], policy: .after(next))
    }

    private func entry(for configuration: TDMonthDayListConfigurationIntent, family: WidgetFamily) async -> TDMonthDayListEntry {
        let month = TDWidgetMonthDayListState.monthAnchorDate()
        let selected = TDWidgetMonthDayListState.selectedDate()

        guard let user = TDWidgetUserSession.currentUser() else {
            return TDMonthDayListEntry(
                date: .now,
                configuration: configuration,
                monthAnchor: month,
                selectedDate: selected,
                isLoggedIn: false,
                userId: -1,
                userName: "未登录",
                tasks: [],
                swiftDataError: nil
            )
        }

        let fetchLimit = TDMonthDayListTaskDisplayLimit.value(for: family)
        do {
            let context = try TDSharedSwiftDataStore.makeWidgetContext()
            let descriptor = TDWidgetTaskFetchDescriptorFactory.dayTodo(on: selected, userId: user.userId, fetchLimit: fetchLimit)
            let tasks = try context.fetch(descriptor)
            return TDMonthDayListEntry(
                date: .now,
                configuration: configuration,
                monthAnchor: month,
                selectedDate: selected,
                isLoggedIn: true,
                userId: user.userId,
                userName: user.userName,
                tasks: tasks,
                swiftDataError: nil
            )
        } catch {
            return TDMonthDayListEntry(
                date: .now,
                configuration: configuration,
                monthAnchor: month,
                selectedDate: selected,
                isLoggedIn: true,
                userId: user.userId,
                userName: user.userName,
                tasks: [],
                swiftDataError: "\(error)"
            )
        }
    }
}

// MARK: - Widget

struct TDMacWidgetMonthDayListWidget: Widget {
    let kind: String = TDWidgetKind.monthDayList

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: TDMonthDayListConfigurationIntent.self,
            provider: TDMonthDayListProvider()
        ) { entry in
            TDMonthDayListWidgetView(entry: entry)
        }
        .configurationDisplayName("月历日清单")
        .description("左侧月历点选日期，右侧显示当天 Day Todo。")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - View

private struct TDMonthDayListWidgetView: View {
    let entry: TDMonthDayListEntry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    private var widgetIsDark: Bool { entry.configuration.autoNightMode ? (colorScheme == .dark) : false }
    private var tintColor: Color { TDThemeManager.shared.primaryTintColor(isDark: widgetIsDark) }

    private func deepLinkURL(taskId: String? = nil, action: String? = nil, date: Date? = nil) -> URL {
        var comps = URLComponents()
        comps.scheme = "todomac"
        comps.host = "widget"
        var items: [URLQueryItem] = [
            URLQueryItem(name: "categoryId", value: "-100") // DayTodo
        ]
        if let action, !action.isEmpty {
            items.append(URLQueryItem(name: "action", value: action))
        }
        if let taskId, !taskId.isEmpty {
            items.append(URLQueryItem(name: "taskId", value: taskId))
        }
        if let date {
            items.append(URLQueryItem(name: "date", value: "\(date.startOfDayTimestamp)"))
        }
        comps.queryItems = items
        return comps.url ?? URL(string: "todomac://widget?categoryId=-100")!
    }

    var body: some View {
        GeometryReader { geo in
            let leftWidth = max(160, geo.size.width * (family == .systemMedium ? 0.46 : 0.42))

            // 你要的效果：不要中间分割线，改为左右留出同等间距
            HStack(spacing: 12) {
                leftCalendar
                    .frame(width: leftWidth)

                rightDayTodo
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .tint(tintColor)
        .containerBackground(for: .widget) {
            td_adaptiveBackgroundFill(
                base: TDThemeManager.shared.currentTheme.baseColors.primaryBackground.color(isDark: widgetIsDark),
                renderingMode: widgetRenderingMode
            )
        }
    }

    // MARK: Left Calendar

    private var leftCalendar: some View {
        VStack(spacing: 8) {
            calendarHeader
            weekdayHeader
            calendarGrid
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var calendarHeader: some View {
        HStack(spacing: 10) {
            Button(intent: TDWidgetMonthDayListChangeMonthIntent(month: -1)) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tint)
                    .widgetAccentable()
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Text(entry.monthAnchor.toString(format: entry.monthAnchor.isThisYear ? "M月" : "yyyy年 M月"))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.tint)
                .widgetAccentable()
                .lineLimit(1)

            Spacer(minLength: 0)

            Button(intent: TDWidgetMonthDayListChangeMonthIntent(month: 1)) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tint)
                    .widgetAccentable()
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }

    private var weekdayHeader: some View {
        let headers = TDSettingManager.shared.isFirstDayMonday
        ? ["一", "二", "三", "四", "五", "六", "日"]
        : ["日", "一", "二", "三", "四", "五", "六"]

        return HStack(spacing: 0) {
            ForEach(Array(headers.enumerated()), id: \.offset) { _, t in
                Text(t)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(weekdayTextColor.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
            }
        }
    }

    private var weekdayTextColor: Color {
        if widgetRenderingMode != .fullColor {
            return Color.secondary
        }
        return TDThemeManager.shared.currentTheme.baseColors.titleText.color(isDark: widgetIsDark)
    }

    private var calendarGrid: some View {
        let grid = TDMonthOnlyGridBuilder.build(month: entry.monthAnchor)

        return GeometryReader { geo in
            let rows = max(1, grid.rows)
            let vSpacing = td_monthGridRowSpacing(forRows: rows, availableHeight: geo.size.height)
            let totalSpacing = vSpacing * CGFloat(max(0, rows - 1))
            let cellHeight = max(0, (geo.size.height - totalSpacing) / CGFloat(rows))
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

            LazyVGrid(columns: columns, spacing: vSpacing) {
                ForEach(Array(grid.cells.enumerated()), id: \.offset) { idx, d in
                    if let d {
                        Button(intent: TDWidgetMonthDayListSelectDateIntent(date: d)) {
                            TDMonthDayCell(
                                date: d,
                                isSelected: d.startOfDayTimestamp == entry.selectedDate.startOfDayTimestamp,
                                isDark: widgetIsDark,
                                renderingMode: widgetRenderingMode
                            )
                            .frame(height: cellHeight)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(height: cellHeight)
                            .id("empty-\(idx)")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Right DayTodo

    private var rightDayTodo: some View {
        VStack(alignment: .leading, spacing: 6) {
            if entry.isLoggedIn {
                if !entry.tasks.isEmpty {
                    // 右侧事件间距：按你要求 2pt
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(entry.tasks) { model in
                            TDMonthDayListTaskRowView(
                                task: model,
                                isDark: widgetIsDark
                            )
                            .overlay {
                                Link(destination: deepLinkURL(taskId: model.taskId, date: entry.selectedDate)) {
                                    Color.clear
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 24) // 保留左侧完成按钮可点击
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else if entry.swiftDataError == nil {
                    TDWidgetEmptyLogoView(
                        text: nil,
                        isDark: widgetIsDark
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                TDWidgetEmptyLogoView(
                    text: "未登录",
                    isDark: widgetIsDark
                )
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Components

@inline(__always)
private func td_monthGridRowSpacing(forRows rows: Int, availableHeight: CGFloat) -> CGFloat {
    // 目标：日期少（4行）间距大一点；日期多（6行）间距小一点
    // 同时做一个高度兜底，避免在较小 widget 高度里把 cellHeight 压成 0
    if availableHeight < 120 { return 2 }
    switch rows {
    case 1...4:
        return 8
    case 5:
        return 4
    default:
        return 2
    }
}

private struct TDWidgetEmptyLogoView: View {
    let text: String?
    let isDark: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(TDThemeManager.shared.currentTheme.baseColors.descriptionText.color(isDark: isDark).opacity(0.75))
            if let text, !text.isEmpty {
                Text(text)
                    .font(.system(size: 12))
                    .foregroundColor(TDThemeManager.shared.currentTheme.baseColors.descriptionText.color(isDark: isDark))
            }
        }
    }
}

private struct TDMonthDayCell: View {
    let date: Date
    let isSelected: Bool
    let isDark: Bool
    let renderingMode: WidgetRenderingMode

    private var labelText: String {
        if date.isToday { return "今" }
        return "\(date.day)"
    }
    
    private var isWeekday: Bool {
        // 对齐 iOS 玻璃模式：工作日/周末做不同透明度
        !Calendar.current.isDateInWeekend(date)
    }

    private var textColor: Color {
        if renderingMode != .fullColor {
            // 对齐你给的 iOS 逻辑（玻璃模式）
            if date.isToday { return .black }
            if isWeekday { return .white.opacity(0.2) }
            if isSelected { return .gray }
            return .white.opacity(0.7)
        } else {
            // fullColor：沿用原本的主题逻辑
            if isSelected { return .white }
            if date.isToday { return TDThemeManager.shared.primaryTintColor(isDark: isDark) }
            return TDThemeManager.shared.currentTheme.baseColors.titleText.color(isDark: isDark)
        }
    }

    private var selectedCircleFill: Color {
        if renderingMode == .fullColor {
            return TDThemeManager.shared.primaryTintColor(isDark: isDark)
        } else {
            // 对齐你给的 iOS 逻辑：玻璃模式选中圆圈 = white 0.2
            return .white.opacity(0.2)
        }
    }

    var body: some View {
        GeometryReader { geo in
            // 选中背景：文字到圆边距约 1~2pt（避免“挨着”）
            let inset: CGFloat = 1
            let diameter = max(0, min(geo.size.width, geo.size.height) - inset * 2)
            ZStack {
                if isSelected {
                    Circle()
                        .fill(selectedCircleFill)
                        .frame(width: diameter, height: diameter)
                }

                Text(labelText)
                    // 日期字体再小一点；不加粗
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    // 21/22 之类两位数避免被“圆背景尺寸”硬裁切：不再把 Text 约束到 diameter
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
    }
}

/// 右侧 DayTodo 行（复用列表小组件视觉规则：完成按钮可点 + 难度条 + 图标）
private struct TDMonthDayListTaskRowView: View {
    let task: TDMacSwiftDataListModel
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

            if task.snowAssess > 5 {
                RoundedRectangle(cornerRadius: 2.0)
                    .fill(difficultyColor)
                    .frame(width: 4.0, height: 12.0)
            }

            HStack(alignment: .center, spacing: 4.0) {
                Text(task.taskContent)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(titleColor)
                    .strikethrough(
                        task.complete && TDSettingManager.shared.showCompletedTaskStrikethrough,
                        color: titleColor
                    )
                    .opacity(task.complete ? 0.6 : 1.0)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .fixedClipped()

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
            .layoutPriority(0)

            Spacer(minLength: 0)
        }
        .tint(TDThemeManager.shared.primaryTintColor(isDark: isDark))
        .frame(height: 21.0)
    }
}

private enum TDMonthDayListTaskDisplayLimit {
    static func value(for family: WidgetFamily) -> Int {
        switch family {
        case .systemMedium:
            return 6
        case .systemLarge:
            return 12
        case .systemExtraLarge:
            return 18
        default:
            return 10
        }
    }
}

private struct TDMonthOnlyGrid {
    let cells: [Date?]
    let rows: Int
}

/// 只构建“当月日期 + 前置空位”，不把上/下月日期补齐进来
private enum TDMonthOnlyGridBuilder {
    static func build(month: Date) -> TDMonthOnlyGrid {
        let cal = Calendar.current
        let first = month.firstDayOfMonth
        let last = month.lastDayOfMonth
        let totalDays = cal.component(.day, from: last)

        let firstWeekday = cal.component(.weekday, from: first) // 1=周日
        let offset: Int = {
            if TDSettingManager.shared.isFirstDayMonday {
                // 把周一映射为 0
                return (firstWeekday + 5) % 7
            } else {
                return firstWeekday - 1
            }
        }()

        let totalCells = offset + totalDays
        let rows = Int(ceil(Double(totalCells) / 7.0))
        let paddedCount = rows * 7

        var cells: [Date?] = Array(repeating: nil, count: paddedCount)
        for day in 1...totalDays {
            var comps = cal.dateComponents([.year, .month], from: first)
            comps.day = day
            let d = cal.date(from: comps) ?? first
            let idx = offset + (day - 1)
            if idx >= 0 && idx < cells.count {
                cells[idx] = d
            }
        }
        return TDMonthOnlyGrid(cells: cells, rows: rows)
    }
}

// MARK: - iOS 17+ 渲染模式适配（与现有日程概览小组件一致）

@inline(__always)
private func td_adaptiveBackgroundFill(base: Color, renderingMode: WidgetRenderingMode) -> Color {
    if renderingMode == .fullColor {
        return base
    } else {
        return Color.secondary.opacity(0.12)
    }
}

