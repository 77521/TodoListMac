//
//  TDMenuBarPopoverRootView.swift
//  TodoMacRepertorie
//
//  Created by Cursor AI on 2026/3/27.
//

import AppKit
import SwiftData
import SwiftUI

/// 状态栏弹窗根视图：上方月历 + 下方 DayTodo 列表（查询/筛选/排序与 Daytodo 一致）
struct TDMenuBarPopoverRootView: View {
    @StateObject private var themeManager = TDThemeManager.shared
    @StateObject private var holidayManager = TDHolidayManager.shared
    @ObservedObject private var settingManager = TDSettingManager.shared

    @State private var selectedDate: Date = Date()
    @State private var displayMonth: Date = Date()
    
    private let popoverWidth: CGFloat = 320
    private let popoverHeight: CGFloat = 520
    private let horizontalPadding: CGFloat = 12

    private var dayTodoCategory: TDSliderBarModel {
        let defaults = TDSliderBarModel.defaultItems(settingManager: settingManager)
        return defaults.first(where: { $0.categoryId == -100 }) ?? defaults[0]
    }

    var body: some View {
        VStack(spacing: 0) {
            TDMenuBarMonthCalendarView(
                selectedDate: $selectedDate,
                displayMonth: $displayMonth,
                themeManager: themeManager,
                holidayManager: holidayManager,
                settingManager: settingManager,
                containerWidth: popoverWidth - horizontalPadding * 2,
                onAdd: {
                    // 先做最小实现：激活主窗口并聚焦输入框（行为与 Widget 的 add 类似）
                    NSApp.activate(ignoringOtherApps: true)
                    TDSettingsWindowTracker.shared.mainWindow?.makeKeyAndOrderFront(nil)
                    TDMainViewModel.shared.selectedTask = nil
                    TDMainViewModel.shared.pendingInputFocusRequestId = UUID()
                }
            )
            .padding(.top, 10)
            .padding(.bottom, 8)
            .padding(.horizontal, horizontalPadding)

            Divider()

            // Daytodo 列表：用 id 强制重建 @Query（让 selectedDate 变化能更新 predicate）
            TDMenuBarDayTodoListView(selectedDate: selectedDate, category: dayTodoCategory)
                .id(selectedDate.startOfDayTimestamp)
        }
        .frame(width: popoverWidth, height: popoverHeight)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .modelContainer(TDModelContainer.shared.container)
        .environmentObject(themeManager)
    }
}

// MARK: - 上方：月历（视觉与 TDCustomDatePickerView 对齐）

private struct TDMenuBarMonthCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var displayMonth: Date

    let themeManager: TDThemeManager
    let holidayManager: TDHolidayManager
    let settingManager: TDSettingManager
    let containerWidth: CGFloat
    let onAdd: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var gridCells: [GridCell] = []
    @State private var gridWeekCount: Int = 6
    @State private var rebuildTask: Task<Void, Never>?
    @State private var rebuildToken: Int = 0
    @State private var lunarCache: [Int64: LunarInfo] = [:]

    @State private var isMonthYearPickerPresented: Bool = false
    @State private var pickerYear: Int = 0
    @State private var pickerMonth: Int = 0

    private let calendar: Calendar = Calendar(identifier: .gregorian)

    private var dateCircleDiameter: CGFloat { 30 }
    private var gridSpacing: CGFloat { 4 } // 日期间距更紧凑

    // 7 列铺满宽度（列宽自适应），圆圈仍固定 30 居中
    private var calendarColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(minimum: dateCircleDiameter, maximum: 100), spacing: gridSpacing, alignment: .center),
            count: 7
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.bottom, 6)

            weekdayHeader
                .padding(.bottom, 6)

            monthGrid(cells: gridCells)
        }
        .frame(width: containerWidth, height: preferredHeight(weekCount: gridWeekCount))
        .onAppear {
            if !calendar.isDate(selectedDate, equalTo: displayMonth, toGranularity: .month) {
                displayMonth = selectedDate
            }
            scheduleRebuildGrid()
        }
        .onChange(of: displayMonth) { _, _ in scheduleRebuildGrid() }
        .onChange(of: settingManager.isFirstDayMonday) { _, _ in scheduleRebuildGrid() }
        .onChange(of: holidayManager.holidayList.count) { _, _ in scheduleRebuildGrid() }
        .onChange(of: settingManager.showCompletedTasks) { _, _ in scheduleRebuildGrid() }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                pickerYear = calendar.component(.year, from: displayMonth)
                pickerMonth = calendar.component(.month, from: displayMonth)
                isMonthYearPickerPresented = true
            } label: {
                Text(monthYearString(from: displayMonth))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(themeManager.titleTextColor)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .popover(isPresented: $isMonthYearPickerPresented, arrowEdge: .top) {
                TDMonthYearPickerPopover(
                    themeTitleColor: themeManager.titleTextColor,
                    themeSubColor: themeManager.descriptionTextColor,
                    year: $pickerYear,
                    month: $pickerMonth,
                    onCancel: { isMonthYearPickerPresented = false },
                    onConfirm: {
                        let comps = DateComponents(year: pickerYear, month: pickerMonth, day: 1)
                        if let newMonth = calendar.date(from: comps) {
                            displayMonth = newMonth
                            if !calendar.isDate(selectedDate, equalTo: newMonth, toGranularity: .month) {
                                selectedDate = newMonth
                            }
                        }
                        isMonthYearPickerPresented = false
                    }
                )
                .padding(12)
            }

            Spacer(minLength: 0)

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(themeManager.titleTextColor)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointingHandCursor()

            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeManager.titleTextColor)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointingHandCursor()

            Button(action: goToday) {
                Image(systemName: "circle")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(themeManager.titleTextColor)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointingHandCursor()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeManager.titleTextColor)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
        }
        .frame(width: containerWidth, alignment: .center)
    }

    private var weekdayHeader: some View {
        let labels = settingManager.isFirstDayMonday
            ? ["一", "二", "三", "四", "五", "六", "日"]
            : ["日", "一", "二", "三", "四", "五", "六"]

        return LazyVGrid(columns: calendarColumns, spacing: gridSpacing) {
            ForEach(labels, id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeManager.descriptionTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func monthGrid(cells: [GridCell]) -> some View {
        LazyVGrid(columns: calendarColumns, spacing: gridSpacing) {
            ForEach(cells) { cell in
                dateCell(cell: cell)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func dateCell(cell: GridCell) -> some View {
        let date = cell.date
        let isCurrentMonth = cell.isCurrentMonth
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = date.isToday

        let solarColor: Color = {
            if isSelected { return .white }
            if isToday { return themeManager.color(level: 6) }
            if !isCurrentMonth { return themeManager.descriptionTextColor }
            return themeManager.titleTextColor
        }()
        let lunarColor: Color = {
            if isSelected { return .white }
            if isToday { return themeManager.color(level: 6) }
            if !isCurrentMonth { return themeManager.descriptionTextColor }
            return themeManager.descriptionTextColor
        }()
        let circleBackgroundColor: Color = {
            if isSelected { return themeManager.color(level: 5) }
            if isToday { return themeManager.color(level: 3) }
            return .clear
        }()

        let holidayBadge = cell.holidayBadge

        return Button {
            selectedDate = date
            if !calendar.isDate(selectedDate, equalTo: displayMonth, toGranularity: .month) {
                displayMonth = selectedDate
            }
        } label: {
            TDDateCircleContent(
                diameter: dateCircleDiameter,
                day: cell.day,
                lunarText: cell.lunarText,
                solarColor: solarColor,
                lunarColor: lunarColor,
                circleBackgroundColor: circleBackgroundColor,
                hasDataDot: cell.hasData,
                dataDotColor: themeManager.color(level: 5),
                holidayBadge: holidayBadge,
                holidayBadgeFill: { isHoliday in
                    isHoliday ? themeManager.color(level: 5) : themeManager.color(level: 2)
                },
                holidayBadgeTextColor: { isHoliday in
                    isHoliday ? .white : themeManager.color(level: 7)
                }
            )
            .frame(width: dateCircleDiameter, height: dateCircleDiameter)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }

    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: displayMonth) {
            displayMonth = newDate
        }
    }

    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: displayMonth) {
            displayMonth = newDate
        }
    }

    private func goToday() {
        let today = Date()
        selectedDate = today
        displayMonth = today
    }

    private var cellHeight: CGFloat { dateCircleDiameter }

    private func preferredHeight(weekCount: Int) -> CGFloat {
        let top: CGFloat = 28
        let weekday: CGFloat = 22
        let grid = CGFloat(weekCount) * cellHeight + CGFloat(max(0, weekCount - 1)) * gridSpacing
        return top + weekday + grid
    }

    // MARK: - Precompute grid（与 TDCustomDatePickerView 同逻辑）

    fileprivate struct HolidayBadge: Equatable {
        let text: String
        let isHoliday: Bool
    }

    private struct GridCell: Identifiable, Equatable {
        let id: Int64
        let date: Date
        let day: Int
        let isCurrentMonth: Bool
        let lunarText: String
        let holidayBadge: HolidayBadge?
        let hasData: Bool
    }
    
    private struct LunarInfo: Equatable {
        let smart: String
        let lunarMonthDisplay: String
    }

    private static let lunarMonthNames = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
    private static let lunarDayNames = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]

    private static func systemLunarMonthDisplay(for date: Date) -> String {
        let chineseCalendar = Calendar(identifier: .chinese)
        let comps = chineseCalendar.dateComponents([.month, .day, .isLeapMonth], from: date)
        let month = comps.month ?? 1
        let day = comps.day ?? 1
        let isLeap = comps.isLeapMonth ?? false

        let monthName = Self.lunarMonthNames[max(0, min(11, month - 1))]
        if day == 1 {
            return (isLeap ? "闰" : "") + monthName + "月"
        }
        return Self.lunarDayNames[max(0, min(29, day - 1))]
    }

    private func scheduleRebuildGrid() {
        rebuildTask?.cancel()
        rebuildToken += 1
        let token = rebuildToken

        let month = displayMonth
        let firstDayMonday = settingManager.isFirstDayMonday
        let holidays = holidayManager.getHolidayList()
        let cached = lunarCache
        let userId = TDUserManager.shared.userId
        let showCompleted = settingManager.showCompletedTasks

        // 计算当前网格可见日期范围
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let daysCount = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let offsetDays: Int = firstDayMonday ? ((firstWeekday + 5) % 7) : (firstWeekday - 1)
        let gridStartDate = calendar.date(byAdding: .day, value: -offsetDays, to: startOfMonth) ?? startOfMonth
        // 固定 6 行：42 格
        let gridEndDate = calendar.date(byAdding: .day, value: 42, to: gridStartDate) ?? gridStartDate
        let startTS = gridStartDate.startOfDayTimestamp
        let endTS = gridEndDate.startOfDayTimestamp

        // 查询该范围内有哪些日期有任务（用于显示 2pt 小圆点）
        var datesWithTasks: Set<Int64> = []
        do {
            let predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId
                && !task.delete
                && task.todoTime >= startTS
                && task.todoTime < endTS
                && (showCompleted || !task.complete)
            }
            let descriptor = FetchDescriptor<TDMacSwiftDataListModel>(predicate: predicate)
            let tasks = try modelContext.fetch(descriptor)
            datesWithTasks = Set(tasks.map(\.todoTime).filter { $0 > 0 })
        } catch { }

        rebuildTask = Task.detached(priority: .userInitiated) { [calendar] in
            if Task.isCancelled { return }

            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
            let daysCount = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30
            let firstWeekday = calendar.component(.weekday, from: startOfMonth)
            let offsetDays: Int = firstDayMonday ? ((firstWeekday + 5) % 7) : (firstWeekday - 1)
            let gridStart = calendar.date(byAdding: .day, value: -offsetDays, to: startOfMonth) ?? startOfMonth

            var holidayByDate: [Int64: Bool] = [:]
            holidayByDate.reserveCapacity(holidays.count)
            for h in holidays {
                holidayByDate[h.date] = h.holiday
            }

            var cells: [GridCell] = []
            cells.reserveCapacity(42)

            for i in 0..<42 {
                if Task.isCancelled { return }
                guard let date = calendar.date(byAdding: .day, value: i, to: gridStart) else { continue }
                let id = date.startOfDayTimestamp
                let isCurrentMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)
                let day = calendar.component(.day, from: date)
                let lunarText = Self.systemLunarMonthDisplay(for: date)

                let holidayBadge: HolidayBadge? = {
                    guard let isHoliday = holidayByDate[id] else { return nil }
                    return HolidayBadge(text: isHoliday ? "休" : "班", isHoliday: isHoliday)
                }()

                cells.append(
                    GridCell(
                        id: id,
                        date: date,
                        day: day,
                        isCurrentMonth: isCurrentMonth,
                        lunarText: lunarText,
                        holidayBadge: holidayBadge,
                        hasData: datesWithTasks.contains(id)
                    )
                )
            }

            if Task.isCancelled { return }
            await MainActor.run {
                guard self.rebuildToken == token else { return }
                self.gridWeekCount = 6
                self.gridCells = cells
            }
            
            // 只对“当月日期”补齐节气/节日 smartDisplay（与 TDCustomDatePickerView 一致）
            var updated = cells
            var newCache: [Int64: LunarInfo] = [:]
            newCache.reserveCapacity(31)
            
            var computedCount = 0
            for idx in updated.indices {
                if Task.isCancelled { return }
                guard updated[idx].isCurrentMonth else { continue }
                
                let date = updated[idx].date
                let id = updated[idx].id
                
                let info: LunarInfo
                if let cachedInfo = cached[id] {
                    info = cachedInfo
                } else if let cachedInfo = newCache[id] {
                    info = cachedInfo
                } else {
                    let (smart, lunarMonthDisplay) = TDLunarCalendar.getSmartDisplayAndLunarMonthDisplay(for: date)
                    let computed = LunarInfo(smart: smart, lunarMonthDisplay: lunarMonthDisplay)
                    newCache[id] = computed
                    info = computed
                    
                    computedCount += 1
                    if computedCount % 6 == 0 {
                        try? await Task.sleep(nanoseconds: 1_200_000)
                    }
                }
                
                let smartText = info.smart.count > 4 ? info.lunarMonthDisplay : info.smart
                if smartText != updated[idx].lunarText {
                    updated[idx] = GridCell(
                        id: updated[idx].id,
                        date: updated[idx].date,
                        day: updated[idx].day,
                        isCurrentMonth: updated[idx].isCurrentMonth,
                        lunarText: smartText,
                        holidayBadge: updated[idx].holidayBadge,
                        hasData: updated[idx].hasData
                    )
                }
            }
            
            if Task.isCancelled { return }
            await MainActor.run {
                guard self.rebuildToken == token else { return }
                
                if !newCache.isEmpty {
                    for (k, v) in newCache {
                        self.lunarCache[k] = v
                    }
                }
                // smartDisplay 补齐只更新文案，不做动画，避免“闪一下”
                withTransaction(Transaction(animation: nil)) {
                    self.gridCells = updated
                }
            }
        }
    }
}

// 与 TDCustomDatePickerView 的日期显示一致（固定 30×30）
private struct TDDateCircleContent: View {
    let diameter: CGFloat
    let day: Int
    let lunarText: String
    let solarColor: Color
    let lunarColor: Color
    let circleBackgroundColor: Color
    let hasDataDot: Bool
    let dataDotColor: Color
    let holidayBadge: TDMenuBarMonthCalendarView.HolidayBadge?
    let holidayBadgeFill: (Bool) -> Color
    let holidayBadgeTextColor: (Bool) -> Color

    var body: some View {
        ZStack {
            Circle()
                .fill(circleBackgroundColor)
                .frame(width: diameter, height: diameter)

            VStack(spacing: 0) {
                Text("\(day)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(solarColor)
                    .overlay(alignment: .topTrailing) {
                        if let badge = holidayBadge {
                            ZStack {
                                Circle().fill(holidayBadgeFill(badge.isHoliday))
                                Text(badge.text)
                                    .font(.system(size: 7, weight: .regular))
                                    .foregroundColor(holidayBadgeTextColor(badge.isHoliday))
                            }
                            .frame(width: 14, height: 14)
                            .offset(x: 14, y: -7)
                            .allowsHitTesting(false)
                        }
                    }

                Text(lunarText)
                    .font(.system(size: 8, weight: .regular))
                    .foregroundColor(lunarColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if hasDataDot {
                    Circle()
                        .fill(dataDotColor)
                        .frame(width: 3, height: 3)
                        .padding(.top, 1)
                }
            }
            .frame(width: diameter, height: diameter, alignment: .center)
        }
    }
}

private struct TDMonthYearPickerPopover: View {
    let themeTitleColor: Color
    let themeSubColor: Color

    @Binding var year: Int
    @Binding var month: Int

    let onCancel: () -> Void
    let onConfirm: () -> Void

    private var years: [Int] { Array(1900...2100) }

    var body: some View {
        VStack(spacing: 10) {
            Text("选择年月")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeTitleColor)

            HStack(spacing: 8) {
                Picker("", selection: $year) {
                    ForEach(years, id: \.self) { y in
                        Text("\(y)年").tag(y)
                    }
                }
                .labelsHidden()
                .frame(width: 120)
                .pickerStyle(.menu)

                Picker("", selection: $month) {
                    ForEach(1...12, id: \.self) { m in
                        Text("\(m)月").tag(m)
                    }
                }
                .labelsHidden()
                .frame(width: 80)
                .pickerStyle(.menu)
            }

            HStack {
                Button("取消", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundColor(themeSubColor)

                Spacer()

                Button("确定", action: onConfirm)
                    .buttonStyle(.plain)
                    .foregroundColor(themeTitleColor)
            }
        }
        .frame(width: 240)
    }
}

// MARK: - 下方：DayTodo 列表（查询/筛选/排序与 TDDayTodoView 一致）

private struct TDMenuBarDayTodoListView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    
    @ObservedObject private var settingManager = TDSettingManager.shared

    @Query private var allTasks: [TDMacSwiftDataListModel]

    private let selectedDate: Date
    private let selectedCategory: TDSliderBarModel

    init(selectedDate: Date, category: TDSliderBarModel) {
        self.selectedDate = selectedDate
        self.selectedCategory = category

        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getDayTodoQuery(selectedDate: selectedDate)
        _allTasks = Query(filter: predicate, sort: sortDescriptors)
    }

    var body: some View {
        if allTasks.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "calendar")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                Text("你这一天没有任务")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("放松一下吧")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(allTasks.indices, id: \.self) { index in
                    let task = allTasks[index]
                    TDMenuBarTaskRowView(task: task, settingManager: settingManager)
                        .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(themeManager.backgroundColor))
            .scrollIndicators(.hidden)
            .environment(\.defaultMinListRowHeight, 32)
        }
    }
}

/// 状态栏弹窗的精简任务行：仅显示完成按钮 + 标题 +（重复/附件/提醒）图标
private struct TDMenuBarTaskRowView: View {
    let task: TDMacSwiftDataListModel
    let settingManager: TDSettingManager

    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 10) {
            Button(action: toggleTaskCompletion) {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(task.checkboxColor, lineWidth: 1.5)
                        .frame(width: 18, height: 18)

                    if task.complete {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(task.checkboxColor)
                            .frame(width: 18, height: 18)

                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointingHandCursor()

            TDTaskTitleRichTextView(
                rawTitle: task.taskContent,
                baseTextColor: task.taskTitleColor,
                fontSize: 13,
                lineLimit: 1,
                isStrikethrough: task.complete ? settingManager.showCompletedTaskStrikethrough : false,
                opacity: task.complete ? 0.6 : 1.0,
                onTapPlain: {
                    NSApp.activate(ignoringOtherApps: true)
                    TDSettingsWindowTracker.shared.mainWindow?.makeKeyAndOrderFront(nil)
                    TDMainViewModel.shared.selectTask(task)
                }
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                if task.hasRepeat {
                    Image("icon_repeat")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundColor(themeManager.color(level: 4))
                }

                if task.hasAttachment || !task.attachmentList.isEmpty {
                    Image(systemName: "paperclip")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.color(level: 4))
                }

                if task.hasReminder {
                    Image("icon_reminder")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundColor(themeManager.color(level: 4))
                        .help(task.reminderTimeString.isEmpty ? "有提醒" : task.reminderTimeString)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func toggleTaskCompletion() {
        Task {
            if !task.complete {
                TDAudioManager.shared.playCompletionSound()
            }
            do {
                let updatedTask = task
                updatedTask.complete = !task.complete

                let queryManager = TDQueryConditionManager()
                let result = try await queryManager.updateLocalTaskWithModel(
                    updatedTask: updatedTask,
                    context: modelContext
                )

                if result == .updated {
                    await TDMainViewModel.shared.performSyncSeparately()
                }
            } catch {
                print("状态栏弹窗切换完成失败: \(error)")
            }
        }
    }
}

