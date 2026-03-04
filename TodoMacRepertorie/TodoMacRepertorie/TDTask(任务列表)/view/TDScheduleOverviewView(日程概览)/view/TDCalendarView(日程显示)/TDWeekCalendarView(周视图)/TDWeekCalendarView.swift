//
//  TDWeekCalendarView.swift
//  TodoMacRepertorie
//
//  周视图：与“日程概览”月视图同一套数据/样式体系
//

import SwiftUI
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
        }
        .frame(width: cellWidth, height: cellHeight)
    }

    private var backgroundColor: Color {
        if dateModel.date.isSameDay(as: viewModel.currentDate) {
            return themeManager.color(level: 2).opacity(0.25)
        }
        return themeManager.backgroundColor
    }

    private func calculateMaxTasks() -> Int {
        // 与月视图保持一致的估算方式
        let baseHeight: CGFloat = 14 + 2 + 8
        let availableHeight = cellHeight - baseHeight
        let fontSize = settingManager.fontSize.size
        let taskRowHeight = fontSize + 3
        return max(0, Int(availableHeight / taskRowHeight))
    }
}

#Preview {
    TDWeekCalendarView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
        .environmentObject(TDScheduleOverviewViewModel.shared)
}

