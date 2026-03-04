//
//  TDMacWidgetScheduleOverviewWidget.swift
//  TDMacWidget
//
//  日程概览小组件：中型=周视图；大/超大=月视图（对齐主 App 日程概览的月视图逻辑）
//

import WidgetKit
import SwiftUI
import SwiftData
import Foundation
import AppIntents

private struct TDScheduleWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: TDScheduleOverviewConfigurationIntent
    let isLoggedIn: Bool
    let userId: Int
    let isVIP: Bool
    let tasks: [TDMacSwiftDataListModel]
    let swiftDataError: String?
}

private struct TDScheduleWidgetProvider: AppIntentTimelineProvider {
    typealias Intent = TDScheduleOverviewConfigurationIntent

    func placeholder(in context: Context) -> TDScheduleWidgetEntry {
        TDScheduleWidgetEntry(
            date: .now,
            configuration: TDScheduleOverviewConfigurationIntent(),
            isLoggedIn: false,
            userId: -1,
            isVIP: false,
            tasks: [],
            swiftDataError: nil
        )
    }

    func snapshot(for configuration: TDScheduleOverviewConfigurationIntent, in context: Context) async -> TDScheduleWidgetEntry {
        await entry(for: configuration, family: context.family)
    }

    func timeline(for configuration: TDScheduleOverviewConfigurationIntent, in context: Context) async -> Timeline<TDScheduleWidgetEntry> {
        let entry = await entry(for: configuration, family: context.family)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(15 * 60)
        return Timeline(entries: [entry], policy: .after(next))
    }

    private func entry(for configuration: TDScheduleOverviewConfigurationIntent, family: WidgetFamily) async -> TDScheduleWidgetEntry {
        guard let user = TDWidgetUserSession.currentUser() else {
            return TDScheduleWidgetEntry(
                date: .now,
                configuration: configuration,
                isLoggedIn: false,
                userId: -1,
                isVIP: false,
                tasks: [],
                swiftDataError: nil
            )
        }

        do {
            let context = try TDSharedSwiftDataStore.makeWidgetContext()

            let anchor: Date = {
                switch family {
                case .systemMedium:
                    return TDWidgetScheduleOverviewState.weekAnchorDate()
                case .systemLarge, .systemExtraLarge:
                    return TDWidgetScheduleOverviewState.monthAnchorDate()
                default:
                    return Date()
                }
            }()

            let (start, end) = TDWidgetScheduleRange.range(for: family, anchor: anchor)
            let startTs = start.startOfDayTimestamp
            let endTs = end.startOfDayTimestamp

            let showCompleted = TDSettingManager.shared.showCompletedTasks
            let userId = user.userId

            let predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId
                && (!task.delete)
                && (task.todoTime >= startTs && task.todoTime <= endTs)
                && (showCompleted || !task.complete)
            }

            // 对齐日程概览：先按日期，再按“已完成在后”，最后按 taskSort
            let sortDescriptors: [SortDescriptor<TDMacSwiftDataListModel>] = [
                SortDescriptor(\.todoTime, order: .forward),
                SortDescriptor(\.complete, order: .forward),
                SortDescriptor(\.taskSort, order: .forward)
            ]

            var descriptor = FetchDescriptor<TDMacSwiftDataListModel>(predicate: predicate, sortBy: sortDescriptors)
            descriptor.fetchLimit = 3000

            let tasks = try context.fetch(descriptor)
            return TDScheduleWidgetEntry(
                date: .now,
                configuration: configuration,
                isLoggedIn: true,
                userId: userId,
                isVIP: user.isVIP,
                tasks: tasks,
                swiftDataError: nil
            )
        } catch {
            return TDScheduleWidgetEntry(
                date: .now,
                configuration: configuration,
                isLoggedIn: true,
                userId: user.userId,
                isVIP: user.isVIP,
                tasks: [],
                swiftDataError: "\(error)"
            )
        }
    }
}

// MARK: - Widget

struct TDMacWidgetScheduleOverviewWidget: Widget {
    let kind: String = TDWidgetKind.scheduleOverview

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: TDScheduleOverviewConfigurationIntent.self,
            provider: TDScheduleWidgetProvider()
        ) { entry in
            TDScheduleWidgetView(entry: entry)
        }
        .configurationDisplayName("日程概览")
        .description("周视图（中型）与月视图（大/超大）。")
        .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - View

private struct TDScheduleWidgetView: View {
    let entry: TDScheduleWidgetEntry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    private var widgetIsDark: Bool { entry.configuration.autoNightMode ? (colorScheme == .dark) : false }

    private var tasksByDay: [Int64: [TDMacSwiftDataListModel]] {
        Dictionary(grouping: entry.tasks, by: { $0.todoTime })
    }

    private var scheduleModeParam: String {
        switch family {
        case .systemMedium:
            return "week"
        case .systemLarge, .systemExtraLarge:
            return "month"
        default:
            return "week"
        }
    }

    private var displayAnchorDate: Date {
        switch family {
        case .systemMedium:
            return TDWidgetScheduleOverviewState.weekAnchorDate()
        case .systemLarge, .systemExtraLarge:
            return TDWidgetScheduleOverviewState.monthAnchorDate()
        default:
            return Date()
        }
    }

    private func deepLinkURL(date: Date? = nil, action: String? = nil) -> URL {
        var comps = URLComponents()
        comps.scheme = "todomac"
        comps.host = "widget"
        var items: [URLQueryItem] = [
            URLQueryItem(name: "categoryId", value: "-102"),
            URLQueryItem(name: "scheduleMode", value: scheduleModeParam)
        ]
        if let action, !action.isEmpty {
            items.append(URLQueryItem(name: "action", value: action))
        }
        if let date {
            items.append(URLQueryItem(name: "date", value: "\(date.startOfDayTimestamp)"))
        }
        comps.queryItems = items
        return comps.url ?? URL(string: "todomac://widget?categoryId=-102")!
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                header
                    .padding(.top, 4)

                if entry.isLoggedIn {
                    TDWidgetWeekdayHeader(isDark: widgetIsDark, renderingMode: widgetRenderingMode)

                    ZStack {
                        calendarGrid
                    }
                    .overlay(vipOverlay)
                } else {
                    emptyState(text: "未登录")
                }
                if let err = entry.swiftDataError, !err.isEmpty {
                    Text("SwiftData读取失败")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.red)
                        .padding(.top, 4)
                }
            }

            if entry.isLoggedIn, entry.isVIP, entry.configuration.showAddButton {
                Link(destination: deepLinkURL(date: displayAnchorDate, action: "add")) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.tint)
                        .widgetAccentable()
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                .padding(.bottom, 8)
            }
        }
        .tint(TDThemeManager.shared.primaryTintColor(isDark: widgetIsDark))
        // 空白区域点击：打开主 App，并切到对应周/月视图与月份
        .widgetURL(deepLinkURL(date: displayAnchorDate))
        .containerBackground(for: .widget) {
            td_adaptiveBackgroundFill(
                base: TDThemeManager.shared.currentTheme.baseColors.primaryBackground.color(isDark: widgetIsDark),
                renderingMode: widgetRenderingMode
            )
        }
    }

    private var header: some View {
        HStack {
            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button(intent: headerPreviousIntent) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tint)
                        .widgetAccentable()
                        .frame(width: 18, height: 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text(displayAnchorDate.toString(format: displayAnchorDate.isThisYear ? "M月" : "yyyy年 M月"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.tint)
                    .widgetAccentable()

                Button(intent: headerNextIntent) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tint)
                        .widgetAccentable()
                        .frame(width: 18, height: 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, 6)
    }

    private var headerPreviousIntent: any AppIntent {
        switch family {
        case .systemMedium:
            return TDCalendrEventChangeWeekClick(week: -1)
        case .systemLarge, .systemExtraLarge:
            return TDCalendrEventChangeMonthClick(month: -1)
        default:
            return TDCalendrEventChangeWeekClick(week: -1)
        }
    }

    private var headerNextIntent: any AppIntent {
        switch family {
        case .systemMedium:
            return TDCalendrEventChangeWeekClick(week: 1)
        case .systemLarge, .systemExtraLarge:
            return TDCalendrEventChangeMonthClick(month: 1)
        default:
            return TDCalendrEventChangeWeekClick(week: 1)
        }
    }

    @ViewBuilder
    private var calendarGrid: some View {
        switch family {
        case .systemMedium:
            weekGrid
        case .systemLarge, .systemExtraLarge:
            monthGrid
        default:
            emptyState(text: "不支持的尺寸")
        }
    }

    private func emptyState(text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(TDThemeManager.shared.currentTheme.baseColors.descriptionText.color(isDark: widgetIsDark))
            Spacer()
        }
    }

    @ViewBuilder
    private var vipOverlay: some View {
        if entry.isLoggedIn, !entry.isVIP {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(widgetIsDark ? 0.80 : 0.88)

                VStack(spacing: 14) {
                    Text("升级到高级账户，使用日历小组件查看任务")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(TDThemeManager.shared.currentTheme.baseColors.titleText.color(isDark: widgetIsDark))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 16)

                    Link(destination: deepLinkURL(action: "premium")) {
                        Text("升级到高级会员")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.orange)
                            .padding(.vertical, 10)
                            .frame(maxWidth: 220)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.orange, lineWidth: 2)
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.white.opacity(widgetIsDark ? 0.08 : 0.6))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            EmptyView()
        }
    }

    // MARK: - Week

    private var weekGrid: some View {
        let (start, _) = TDWidgetScheduleRange.weekRange(anchor: displayAnchorDate)
        let dates = TDWidgetScheduleRange.weekDates(start: start)

        return GeometryReader { geo in
            let cellWidth = geo.size.width / 7.0
            let cellHeight = geo.size.height
            HStack(spacing: 0) {
                ForEach(dates, id: \.startOfDayTimestamp) { d in
                    TDWidgetScheduleDayCell(
                        date: d,
                        cellWidth: cellWidth,
                        cellHeight: cellHeight,
                        tasks: tasksByDay[d.startOfDayTimestamp] ?? [],
                        isDark: widgetIsDark,
                        referenceMonth: nil,
                        linkURL: deepLinkURL(date: d)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Month

    private var monthGrid: some View {
        let month = displayAnchorDate.firstDayOfMonth
        let grid = TDWidgetMonthGridBuilder.build(month: month)

        return GeometryReader { geo in
            let rows = grid.count
            let cellWidth = geo.size.width / 7.0
            let cellHeight = rows > 0 ? geo.size.height / CGFloat(rows) : geo.size.height

            VStack(spacing: 0) {
                ForEach(Array(grid.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 0) {
                        ForEach(week, id: \.startOfDayTimestamp) { d in
                            TDWidgetScheduleDayCell(
                                date: d,
                                cellWidth: cellWidth,
                                cellHeight: cellHeight,
                                tasks: tasksByDay[d.startOfDayTimestamp] ?? [],
                                isDark: widgetIsDark,
                                referenceMonth: month,
                                linkURL: deepLinkURL(date: d)
                            )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Components

private struct TDWidgetWeekdayHeader: View {
    let isDark: Bool
    let renderingMode: WidgetRenderingMode

    var body: some View {
        let headers = TDSettingManager.shared.isFirstDayMonday
            ? ["一", "二", "三", "四", "五", "六", "日"]
            : ["日", "一", "二", "三", "四", "五", "六"]
        return HStack(spacing: 0) {
            ForEach(Array(headers.enumerated()), id: \.offset) { idx, t in
                Text(t)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(weekdayTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                    .overlay(
                        Group {
                            if idx < headers.count - 1 {
                                Rectangle()
                                    .fill(separatorColor)
                                    .frame(width: 1)
                            }
                        },
                        alignment: .trailing
                    )
            }
        }
        .background(weekdayBackground)
        .overlay(
            Rectangle()
                .fill(separatorColor)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var weekdayTextColor: Color {
        if renderingMode != .fullColor {
            return Color.secondary.opacity(0.85)
        }
        return TDThemeManager.shared.currentTheme.baseColors.titleText.color(isDark: isDark).opacity(0.85)
    }

    private var separatorColor: Color {
        if renderingMode != .fullColor {
            return Color.secondary.opacity(0.22)
        }
        return TDThemeManager.shared.currentTheme.baseColors.separator.color(isDark: isDark)
    }

    private var weekdayBackground: Color {
        td_adaptiveBackgroundFill(
            base: TDThemeManager.shared.currentTheme.baseColors.primaryBackground.color(isDark: isDark),
            renderingMode: renderingMode
        )
    }
}

private struct TDWidgetScheduleDayCell: View {
    let date: Date
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    let tasks: [TDMacSwiftDataListModel]
    let isDark: Bool
    /// 仅月视图使用：用于把“上/下月补齐日期”做弱化显示
    let referenceMonth: Date?
    let linkURL: URL

    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    private var isToday: Bool { date.isToday }
    private var isCurrentMonth: Bool {
        guard let referenceMonth else { return true }
        let cal = Calendar.current
        return cal.component(.month, from: date) == cal.component(.month, from: referenceMonth)
            && cal.component(.year, from: date) == cal.component(.year, from: referenceMonth)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    HStack(alignment: .center, spacing: 0) {
                        let solarColor: Color = {
                            if isToday { return TDThemeManager.shared.primaryTintColor(isDark: isDark) }
                            if widgetRenderingMode != .fullColor {
                                return Color.primary.opacity(isCurrentMonth ? 0.90 : 0.60)
                            }
                            let base = isCurrentMonth
                                ? TDThemeManager.shared.currentTheme.baseColors.titleText.color(isDark: isDark)
                                : TDThemeManager.shared.currentTheme.baseColors.descriptionText.color(isDark: isDark)
                            return isCurrentMonth ? base : base.opacity(0.65)
                        }()
                        let rightTextColor: Color = {
                            if widgetRenderingMode != .fullColor {
                                return Color.secondary.opacity(isCurrentMonth ? 0.75 : 0.55)
                            }
                            let base = TDThemeManager.shared.currentTheme.baseColors.descriptionText.color(isDark: isDark)
                            return isCurrentMonth ? base : base.opacity(0.65)
                        }()

                        Text("\(date.day)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(solarColor)
                            .padding(.leading, 1)

                        Spacer(minLength: 0)

                        // 调休/节假日：不显示农历，改显示「班/休」
                        if TDSettingManager.shared.showHolidayMark, date.isInHolidayData {
                            Text(date.isHoliday ? "休" : "班")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(date.isHoliday
                                                 ? TDThemeManager.shared.primaryTintColor(isDark: isDark)
                                                 : rightTextColor)
                                .lineLimit(1)
                                .padding(.trailing, 1)
                        } else if TDSettingManager.shared.showLunarCalendar {
                            // 节日/节气文案太长（>3）会在小组件玻璃模式下可读性很差：回退为农历日期
                            Text(date.smartDisplay.count > 3 ? date.lunarMonthDisplay : date.smartDisplay)
                                .font(.system(size: 10))
                                .foregroundColor(rightTextColor)
                                .lineLimit(1)
                                .padding(.trailing, 1)
                        }
                    }
                    .padding(.horizontal, 1)
                    .padding(.top, 2)
                }

                if !tasks.isEmpty {
                    TDWidgetTinyTaskList(
                        tasks: tasks,
                        cellWidth: cellWidth - 4,
                        cellHeight: cellHeight,
                        isDark: isDark
                    )
                    .padding(.horizontal, 2)
                }

                Spacer(minLength: 0)
            }

            Link(destination: linkURL) { Color.clear }
                .buttonStyle(.plain)
        }
        .frame(width: cellWidth, height: cellHeight)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .fill(separatorColor)
                .frame(width: 1),
            alignment: .trailing
        )
        .overlay(
            Rectangle()
                .fill(separatorColor)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var separatorColor: Color {
        if widgetRenderingMode != .fullColor {
            return Color.secondary.opacity(0.18)
        }
        return TDThemeManager.shared.currentTheme.baseColors.separator.color(isDark: isDark)
    }

    private var backgroundColor: Color {
        if isToday {
            return TDThemeManager.shared.primaryTintColor(isDark: isDark).opacity(0.1)
        }
        return td_adaptiveBackgroundFill(
            base: TDThemeManager.shared.currentTheme.baseColors.primaryBackground.color(isDark: isDark),
            renderingMode: widgetRenderingMode
        )
    }
}

// MARK: - iOS 17+ 渲染模式适配（对齐你给的 td_adaptiveChipFill 逻辑）

@inline(__always)
private func td_adaptiveChipFill(base: Color, renderingMode: WidgetRenderingMode) -> Color {
    if renderingMode == .fullColor {
        return base
    } else {
        return Color.secondary.opacity(0.2)
    }
}

/// 背景专用：让“事件色块”在玻璃模式下还能区分出来（背景更浅一点）
@inline(__always)
private func td_adaptiveBackgroundFill(base: Color, renderingMode: WidgetRenderingMode) -> Color {
    if renderingMode == .fullColor {
        return base
    } else {
        return Color.secondary.opacity(0.12)
    }
}

/// 小组件内的极简任务列表（对齐“月视图块状条目”视觉）
private struct TDWidgetTinyTaskList: View {
    let tasks: [TDMacSwiftDataListModel]
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    let isDark: Bool
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            let maxTasks = maxTasksToShow()
            if maxTasks <= 0 {
                EmptyView()
            } else if TDSettingManager.shared.calendarShowRemainingCount, tasks.count > maxTasks {
                // 关键：不额外“预留一行”给 +N；能显示几条任务就显示几条，
                // 若还有剩余，把 +N 贴在“最后一条任务”的右侧。
                let displayTasks = min(maxTasks, tasks.count)
                let remainingCount = tasks.count - displayTasks

                if displayTasks > 1 {
                    ForEach(Array(tasks.prefix(displayTasks - 1).enumerated()), id: \.offset) { _, task in
                        taskRow(task)
                    }
                }

                let lastTask = tasks[displayTasks - 1]
                HStack(alignment: .center, spacing: 2) {
                    // 最后一条右侧要跟 +N 时：按真实可用宽度计算可显示字符数（不出现 ...）
                    let maxChars = remainingCount > 0
                        ? maxCharsForLastRow(remainingCount: remainingCount)
                        : nil
                    taskRow(lastTask, maxCharsOverride: maxChars)
                    if remainingCount > 0 {
                        Text("+\(remainingCount)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .padding(.trailing, 1)
                            .fixedSize()
                    }
                }
            } else {
                ForEach(Array(tasks.prefix(maxTasks).enumerated()), id: \.offset) { _, task in
                    taskRow(task)
                }
            }
        }
    }

    @ViewBuilder
    private func taskRow(_ task: TDMacSwiftDataListModel, maxCharsOverride: Int? = nil) -> some View {
        let style = TDSettingManager.shared.getTaskStyle(for: task)
        let textColor: Color = {
            // 在“玻璃/强调色渲染”下，优先用系统色保证可读性
            if widgetRenderingMode != .fullColor {
                if task.complete { return Color.secondary.opacity(0.85) }
                return isDark ? Color.white.opacity(0.92) : Color.black.opacity(0.78)
            }
            return style.textColor
        }()

        Text(truncate(task.taskContent, maxCharsOverride: maxCharsOverride))
            .font(.system(size: 9))
            .foregroundColor(textColor)
            .strikethrough(task.complete && TDSettingManager.shared.calendarShowCompletedSeparator, color: textColor)
            .lineLimit(1)
            .fixedClipped() // 不要系统的 "..."，超出直接裁剪
            .padding(.horizontal, 2)
            .frame(height: 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        td_adaptiveChipFill(
                            base: (style.backgroundColor ?? TDThemeManager.shared.currentTheme.baseColors.tertiaryBackground.color(isDark: isDark)),
                            renderingMode: widgetRenderingMode
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(
                        widgetRenderingMode == .fullColor ? Color.clear : Color.secondary.opacity(0.16),
                        lineWidth: widgetRenderingMode == .fullColor ? 0 : 0.5
                    )
            )
    }

    private func maxTasksToShow() -> Int {
        // 对齐 iOS 小组件：事件行高 12，行间距约 1（≈13）
        // 预留顶部日期行与内边距（避免被顶起来）
        let headerReserve = CGFloat(18)
        let available = max(0, cellHeight - headerReserve)
        let row = CGFloat(13)
        return max(0, Int(available / row))
    }

    /// 最后一行右侧带 +N 时，按剩余宽度计算最多显示多少字符
    private func maxCharsForLastRow(remainingCount: Int) -> Int {
        // 估算 "+N" 的占宽（9pt 字体）：每个字符约 6pt，再加上 1-2pt 内边距
        let digits = String(remainingCount).count
        let plusLabelWidth = CGFloat(digits + 1) * 6.0 + 4.0 // +N
        let spacing: CGFloat = 2.0
        let trailing: CGFloat = 1.0

        // taskRow 内部还有左右 padding(2)，这里扣掉，避免触发 Text 自己的省略号
        let textInternalPadding: CGFloat = 4.0

        let available = max(10, cellWidth - plusLabelWidth - spacing - trailing - textInternalPadding)
        let avgCharWidth: CGFloat = 9.0 // 中文按 9pt 估算（更保守，不会出现 ...）
        return max(1, Int(available / avgCharWidth))
    }

    private func truncate(_ text: String, maxCharsOverride: Int? = nil) -> String {
        // 与主 App 隐私模式一致的“首字 + *”压缩逻辑（只在 widget 中做轻量实现）
        let maxChars = maxCharsOverride ?? max(1, Int(cellWidth / 9) - 1)
        if TDSettingManager.shared.isPrivacyModeEnabled {
            if text.count <= 1 { return text }
            let first = String(text.prefix(1))
            let asterisks = String(repeating: "*", count: min(text.count - 1, maxChars))
            return first + asterisks
        }
        if text.count <= maxChars { return text }
        return String(text.prefix(maxChars))
    }
}

// MARK: - Range helpers

private enum TDWidgetScheduleRange {
    static func range(for family: WidgetFamily, anchor: Date) -> (Date, Date) {
        switch family {
        case .systemMedium:
            return weekRange(anchor: anchor)
        case .systemLarge, .systemExtraLarge:
            return monthGridRange(month: anchor.firstDayOfMonth)
        default:
            return weekRange(anchor: anchor)
        }
    }

    static func weekRange(anchor: Date) -> (Date, Date) {
        let start = weekStart(anchor: anchor)
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start
        return (start, end)
    }

    static func weekDates(start: Date) -> [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }

    private static func weekStart(anchor: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: anchor)
        let firstWeekday = TDSettingManager.shared.isFirstDayMonday ? 2 : 1
        let delta = (weekday - firstWeekday + 7) % 7
        let start = calendar.date(byAdding: .day, value: -delta, to: anchor) ?? anchor
        return calendar.startOfDay(for: start)
    }

    static func monthGridRange(month: Date) -> (Date, Date) {
        let grid = TDWidgetMonthGridBuilder.build(month: month)
        guard let first = grid.first?.first, let last = grid.last?.last else {
            return (month.firstDayOfMonth, month.lastDayOfMonth)
        }
        return (first, last)
    }
}

private enum TDWidgetMonthGridBuilder {
    static func build(month: Date) -> [[Date]] {
        let firstDay = month.firstDayOfMonth
        let lastDay = month.lastDayOfMonth
        let calendar = Calendar.current

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let totalDays = calendar.component(.day, from: lastDay)
        let firstWeekdayOfMonth = TDSettingManager.shared.isFirstDayMonday ? (firstWeekday + 5) % 7 : (firstWeekday - 1)
        let totalCells = firstWeekdayOfMonth + totalDays
        let numberOfWeeks = Int(ceil(Double(totalCells) / 7.0))

        let gridStart: Date = {
            let offsetDays = TDSettingManager.shared.isFirstDayMonday ? ((firstWeekday + 5) % 7) : (firstWeekday - 1)
            return calendar.date(byAdding: .day, value: -offsetDays, to: firstDay) ?? firstDay
        }()

        let totalDaysToShow = numberOfWeeks * 7
        let allDates: [Date] = (0..<totalDaysToShow).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }

        var weeks: [[Date]] = []
        weeks.reserveCapacity(numberOfWeeks)
        for i in 0..<numberOfWeeks {
            let start = i * 7
            let end = min(start + 7, allDates.count)
            if start < end {
                weeks.append(Array(allDates[start..<end]))
            }
        }
        return weeks
    }
}


