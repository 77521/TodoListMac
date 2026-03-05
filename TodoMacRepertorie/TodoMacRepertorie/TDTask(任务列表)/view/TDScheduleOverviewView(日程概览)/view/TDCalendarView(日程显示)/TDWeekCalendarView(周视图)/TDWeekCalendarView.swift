//
//  TDWeekCalendarView.swift
//  TodoMacRepertorie
//
//  周视图：与“日程概览”月视图同一套数据/样式体系
//

import SwiftUI
import AppKit
import SwiftData

/// 日程概览 - 周视图（7列 * 1行）
struct TDWeekCalendarView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var settingManager: TDSettingManager
    @EnvironmentObject private var viewModel: TDScheduleOverviewViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var tasksByDay: [Int64: [TDMacSwiftDataListModel]] = [:]

    var body: some View {
        VStack(spacing: 0) {
            TDScheduleWeekdayView()

            GeometryReader { geo in
                let cellWidth = geo.size.width / 7.0
                let cellHeight = geo.size.height

                HStack(spacing: 0) {
                    ForEach(viewModel.currentWeekDates(), id: \.startOfDayTimestamp) { date in
                        let dateModel = makeDateModel(for: date)
                        let dayTasks = tasksByDay[date.startOfDayTimestamp] ?? []
                        TDWeekDayCell(
                            dateModel: dateModel,
                            cellWidth: cellWidth,
                            cellHeight: cellHeight,
                            tasks: dayTasks
                        )
                    }
                }
            }
        }
        .task(id: reloadKey) {
            await reloadWeekTasks()
        }
    }

    /// 触发 reload 的 key：日期/分类/排序/完成开关/标签变更都要刷新
    private var reloadKey: String {
        let cat = viewModel.selectedCategory?.categoryId ?? 0
        return "\(viewModel.currentWeekStartDate().startOfDayTimestamp)-\(cat)-\(viewModel.sortType)-\(settingManager.showCompletedTasks)-\(viewModel.tagFilter)"
    }

    private func makeDateModel(for date: Date) -> TDCalendarDateModel {
        TDCalendarDateModel(
            date: date,
            isToday: date.isToday,
            isCurrentMonth: true,
            isHoliday: date.isInHolidayData ? date.isHoliday : false,
            isInHolidayData: date.isInHolidayData,
            smartDisplay: date.smartDisplay,
            isSelected: date.isSameDay(as: viewModel.currentDate)
        )
    }

    @MainActor
    private func reloadWeekTasks() async {
        let userId = TDUserManager.shared.userId
        guard userId > 0 else {
            tasksByDay = [:]
            return
        }

        let start = viewModel.currentWeekStartDate()
        let end = viewModel.currentWeekEndDate()
        let startTimestamp = start.startOfDayTimestamp
        let endTimestamp = end.startOfDayTimestamp

        let categoryId = viewModel.selectedCategory?.categoryId ?? 0
        let showCompleted = settingManager.showCompletedTasks

        let predicate: Predicate<TDMacSwiftDataListModel> = {
            if categoryId > 0 {
                return #Predicate<TDMacSwiftDataListModel> { task in
                    task.userId == userId && !task.delete &&
                    task.todoTime >= startTimestamp && task.todoTime <= endTimestamp &&
                    task.standbyInt1 == categoryId &&
                    (showCompleted || !task.complete)
                }
            } else {
                return #Predicate<TDMacSwiftDataListModel> { task in
                    task.userId == userId && !task.delete &&
                    task.todoTime >= startTimestamp && task.todoTime <= endTimestamp &&
                    (showCompleted || !task.complete)
                }
            }
        }()

        let sortDescriptors: [SortDescriptor<TDMacSwiftDataListModel>] = {
            switch viewModel.sortType {
            case 1:
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.reminderTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
                ]
            case 2:
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.createTime, order: .forward)
                ]
            case 3:
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.createTime, order: .reverse)
                ]
            case 4:
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.snowAssess, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
                ]
            case 5:
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.snowAssess, order: .reverse),
                    SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
                ]
            default:
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
                ]
            }
        }()

        do {
            let descriptor = FetchDescriptor<TDMacSwiftDataListModel>(predicate: predicate, sortBy: sortDescriptors)
            let tasks = try modelContext.fetch(descriptor)
            let filteredTasks = viewModel.tagFilter.isEmpty
                ? tasks
                : TDCorrectQueryBuilder.filterTasksByTag(tasks, tagFilter: viewModel.tagFilter)
            tasksByDay = Dictionary(grouping: filteredTasks, by: { $0.todoTime })
        } catch {
            tasksByDay = [:]
        }
    }
}

/// 周视图单日格子（复用月视图的“日期头 + 任务列表”样式）
private struct TDWeekDayCell: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var settingManager: TDSettingManager
    @EnvironmentObject private var viewModel: TDScheduleOverviewViewModel

    let dateModel: TDCalendarDateModel
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    let tasks: [TDMacSwiftDataListModel]

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    HStack(alignment: .center, spacing: 4) {
                        Text("\(dateModel.date.day)")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.titleTextColor)

                        if settingManager.showLunarCalendar {
                            // 农历节日/节气文案过长（>4）时，不显示节日名，回退为农历日期
                            let display = dateModel.smartDisplay
                            Text(display.count > 4 ? dateModel.date.lunarMonthDisplay : display)
                                .font(.system(size: 10))
                                .foregroundColor(themeManager.descriptionTextColor)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    if dateModel.isInHolidayData, settingManager.showHolidayMark {
                        Text(dateModel.isHoliday ? "休" : "班")
                            .font(.system(size: 9))
                            .foregroundColor(dateModel.isHoliday ? .white : themeManager.color(level: 7))
                            .padding(.all, 2)
                            .background(
                                Circle()
                                    .fill(dateModel.isHoliday ? themeManager.color(level: 5) : themeManager.color(level: 2))
                            )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)

                if !tasks.isEmpty {
                    TDCalendarTaskList(
                        tasks: tasks,
                        cellWidth: geo.size.width - 4,
                        cellHeight: cellHeight,
                        maxTasks: calculateMaxTasks(),
                        onTaskTap: { task in
                            viewModel.selectDateOnly(dateModel.date)
                            TDMainViewModel.shared.selectTask(task)
                        }
                    )
                    .padding(.horizontal, 2)
                }

                Spacer(minLength: 0)
            }
            .frame(width: cellWidth, height: cellHeight, alignment: .topLeading)
            .background(backgroundColor)
            .overlay(
                Rectangle()
                    .fill(themeManager.separatorColor)
                    .frame(width: 1),
                alignment: .trailing
            )
            .overlay(
                Rectangle()
                    .stroke(
                        dateModel.date.isSameDay(as: viewModel.currentDate) ? themeManager.color(level: 5) : Color.clear,
                        lineWidth: 1
                    )
                    .padding(.all, 1)
            )
        }
        .frame(width: cellWidth, height: cellHeight)
    }

    private var backgroundColor: Color {
        // 周视图与月视图保持一致：背景只表示“今天”，选中态用描边表示
        return dateModel.isToday
            ? themeManager.color(level: 1).opacity(0.3)
            : themeManager.backgroundColor
    }

    private func calculateMaxTasks() -> Int {
        // 与月视图保持一致：用真实 lineHeight + 实际 spacing 算行数，避免低估导致留白
        // 顶部行有 .padding(.top, 4) + 外层 VStack spacing(2)
        let topPadding: CGFloat = 4
        let headerSpacing: CGFloat = 2

        func lineHeight(for size: CGFloat) -> CGFloat {
            let font = NSFont.systemFont(ofSize: size)
            return font.boundingRectForFont.height
        }

        let dayLineHeight = lineHeight(for: 12)
        var headerHeight = dayLineHeight

        if settingManager.showLunarCalendar {
            let lunarLineHeight = lineHeight(for: 10)
            headerHeight = max(headerHeight, lunarLineHeight)
        }

        if dateModel.isInHolidayData && settingManager.showHolidayMark {
            let holidayBadgeHeight = lineHeight(for: 9) + 4 // .padding(.all, 2)
            headerHeight = max(headerHeight, holidayBadgeHeight)
        }

        let baseHeight = topPadding + headerHeight + headerSpacing
        let availableHeight = max(0, cellHeight - baseHeight + 0.75)

        let taskLineHeight = lineHeight(for: settingManager.fontSize.size)
        let rowSpacing: CGFloat = 1 // TDCalendarTaskList 内部 VStack spacing
        let rowHeight = taskLineHeight + rowSpacing

        return max(0, Int((availableHeight + rowSpacing) / rowHeight))
    }
}

#Preview {
    TDWeekCalendarView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
        .environmentObject(TDScheduleOverviewViewModel.shared)
}

