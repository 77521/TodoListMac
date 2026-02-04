//
//  TDCalendarGridView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/10.
//

import SwiftUI
import SwiftData

/// 日历网格视图 - 显示所有日期单元格
struct TDCalendarGridView: View {
    /// 主题管理器
    @EnvironmentObject private var themeManager: TDThemeManager
    
    /// 设置管理器
    @EnvironmentObject private var settingManager: TDSettingManager
    
    /// 日历管理器
    @StateObject private var calendarManager = TDCalendarManager.shared

    /// 日程概览视图模型
    @EnvironmentObject private var viewModel: TDScheduleOverviewViewModel

    /// 当前显示月份范围内的所有任务（只做一次查询，避免每个格子一个查询）
    @Query private var monthTasks: [TDMacSwiftDataListModel]

    /// 初始化：构建单次查询条件（按“日历网格实际显示范围”取任务）
    init() {
        let vm = TDScheduleOverviewViewModel.shared
        let settingManager = TDSettingManager.shared

//        if vm.disableDailyTasksInCalendar {
//            let predicate = #Predicate<TDMacSwiftDataListModel> { _ in false }
//            _monthTasks = Query(filter: predicate)
//            return
//        }

        let displayMonth = vm.displayMonth
        let userId = TDUserManager.shared.userId
        let categoryId = vm.selectedCategory?.categoryId ?? 0
        let showCompleted = settingManager.showCompletedTasks

        // 计算网格实际显示的起止日期（包含上/下月补齐）
        let firstDayOfMonth = displayMonth.firstDayOfMonth
        let lastDayOfMonth = displayMonth.lastDayOfMonth

        let numberOfWeeks: Int = {
            let calendar = Calendar.current
            let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
            let totalDays = calendar.component(.day, from: lastDayOfMonth)
            let firstWeekdayOfMonth = settingManager.isFirstDayMonday ? (firstWeekday + 5) % 7 : (firstWeekday - 1)
            let totalCells = firstWeekdayOfMonth + totalDays
            return Int(ceil(Double(totalCells) / 7.0))
        }()

        let gridStartDate: Date = {
            let calendar = Calendar.current
            let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
            let offsetDays = settingManager.isFirstDayMonday ? ((firstWeekday + 5) % 7) : (firstWeekday - 1)
            return calendar.date(byAdding: .day, value: -offsetDays, to: firstDayOfMonth) ?? firstDayOfMonth
        }()

        let gridEndDate: Date = {
            let totalDaysToShow = numberOfWeeks * 7
            return Calendar.current.date(byAdding: .day, value: totalDaysToShow - 1, to: gridStartDate) ?? lastDayOfMonth
        }()

        let startTimestamp = gridStartDate.startOfDayTimestamp
        let endTimestamp = gridEndDate.startOfDayTimestamp

        // 查询条件：用户、未删除、在显示范围内、完成状态筛选、分类筛选
        let predicate: Predicate<TDMacSwiftDataListModel>
        if categoryId > 0 {
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                task.todoTime >= startTimestamp && task.todoTime <= endTimestamp &&
                task.standbyInt1 == categoryId &&
                (showCompleted || !task.complete)
            }
        } else {
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                task.todoTime >= startTimestamp && task.todoTime <= endTimestamp &&
                (showCompleted || !task.complete)
            }
        }

        // 排序：先按日期，再按“已完成在后”，最后按用户选择的排序字段
        let sortType = vm.sortType
        let sortDescriptors: [SortDescriptor<TDMacSwiftDataListModel>] = {
            switch sortType {
            case 1: // 提醒时间
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.reminderTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
                ]
            case 2: // 添加时间a-z
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.createTime, order: .forward)
                ]
            case 3: // 添加时间z-a
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.createTime, order: .reverse)
                ]
            case 4: // 工作量a-z
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.snowAssess, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
                ]
            case 5: // 工作量z-a
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.snowAssess, order: .reverse),
                    SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
                ]
            default: // 默认 taskSort
                return [
                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
                    SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
                ]
            }
        }()

        _monthTasks = Query(filter: predicate, sort: sortDescriptors)
    }
    
    var body: some View {
        // 首次进入优先使用 ViewModel 预加载缓存，避免“先空后补”的抖动；
        // 如缓存不可用（例如刚切换条件），再回退到 SwiftData @Query 的结果。
        let tasksByDay: [Int64: [TDMacSwiftDataListModel]] = {
            if viewModel.hasValidMonthTasksCache {
                return viewModel.monthTasksByDayFiltered(tagFilter: viewModel.tagFilter)
            }

            // 标签筛选在应用层处理（避免频繁重建 predicate）
            let filteredTasks = viewModel.tagFilter.isEmpty
                ? monthTasks
                : TDCorrectQueryBuilder.filterTasksByTag(monthTasks, tagFilter: viewModel.tagFilter)
            return Dictionary(grouping: filteredTasks, by: { $0.todoTime })
        }()

        GeometryReader { geometry in
            let cellHeight = geometry.size.height / CGFloat(calendarManager.calendarDates.count)
            
            VStack(spacing: 0) {
                ForEach(Array(calendarManager.calendarDates.enumerated()), id: \.offset) { weekIndex, week in
                    HStack(spacing: 0) {
                        ForEach(week) { dateModel in
                            let dayTimestamp = dateModel.date.startOfDayTimestamp
                            let dayTasks = tasksByDay[dayTimestamp] ?? []
                            TDCalendarDayCell(
                                dateModel: dateModel,
                                cellWidth: geometry.size.width / 7,
                                cellHeight: cellHeight,
                                tasks: dayTasks
                            )
                        }
                    }
                }
            }
            .onAppear {
                calendarManager.updateViewHeight(geometry.size.height)
            }
            .onChange(of: geometry.size.height) { oldValue, newValue in
                calendarManager.updateViewHeight(newValue)
            }
        }
    }
}

// MARK: - 日历日期单元格
/// 日历日期单元格 - 显示单个日期的所有信息
struct TDCalendarDayCell: View {
    /// 主题管理器
    @EnvironmentObject private var themeManager: TDThemeManager
    /// 设置管理器
    @EnvironmentObject private var settingManager: TDSettingManager

    /// 日程概览视图模型
    @EnvironmentObject private var viewModel: TDScheduleOverviewViewModel

    /// 拖拽状态
    @State private var draggedTask: TDMacSwiftDataListModel? = nil

    /// 日期模型
    let dateModel: TDCalendarDateModel
    
    /// 单元格宽度
    let cellWidth: CGFloat
    
    /// 单元格高度
    let cellHeight: CGFloat

    /// 当前日期的任务列表（由父层按天分组后下发）
    let tasks: [TDMacSwiftDataListModel]

    
    var body: some View {
        GeometryReader { geometry in
            
            ZStack {
                // 主要内容区域
                VStack(alignment: .leading, spacing: 2) {
                    // 日期和农历信息 - 水平居中对齐
                    HStack {
                        // 左侧：阳历和农历
                        HStack(alignment: .center,spacing: 4) {
                            // 阳历日期
                            Text("\(dateModel.date.day)")
                                .font(.system(size: 12))
                                .foregroundColor(dateModel.isCurrentMonth ? themeManager.titleTextColor : themeManager.descriptionTextColor)
                            
                            // 农历日期（根据设置决定是否显示）
                            if settingManager.showLunarCalendar {
                                Text(dateModel.smartDisplay)
                                    .font(.system(size: 10))
                                    .foregroundColor(themeManager.descriptionTextColor)
                            }
                        }
                        
                        Spacer()
                        
                        // 右侧：调休/上班状态
                        if dateModel.isInHolidayData {
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
                    
                    // 任务列表 - 根据高度动态显示任务数量
                    if !tasks.isEmpty {
                        TDCalendarTaskList(
                            tasks: tasks,
                            cellWidth: geometry.size.width,
                            cellHeight: cellHeight,
                            maxTasks: calculateMaxTasks(),
                            onTaskTap: { task in
                                // 点击任务时：选中当前日期并传递任务给主视图模型
                                viewModel.selectDateOnly(dateModel.date)
                                // 调用主视图模型的选择任务方法
                                TDMainViewModel.shared.selectTask(task)
                                print("点击了任务: \(task.taskContent), 日期: \(dateModel.date.formattedString)")
                            }
                        )

                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: cellHeight)
            .background(
                Rectangle()
                    .fill(dateModel.isToday ? themeManager.color(level: 1).opacity(0.3) : Color.clear)
            )
            
            .overlay(
                // 添加网格分割线
                Rectangle()
                    .stroke(themeManager.separatorColor, lineWidth: 1)
            )
            .overlay(
                Rectangle()
                    .stroke(dateModel.date.isSameDay(as: viewModel.currentDate) ? themeManager.color(level: 5) : Color.clear, lineWidth: 1)
                    .padding(.all,1)
            )
            .contentShape(Rectangle()) // 让整个单元格区域都可以点击
            .onTapGesture {
                // TODO: 处理日期点击事件
                // 选择当前日期
//                calendarManager.selectDate(dateModel.date)
                // 只更新选中状态，不重新查询数据，不切换月份
                viewModel.selectDateOnly(dateModel.date)
                // 判断当前日期是否有本地数据
                if !tasks.isEmpty {
                    // 有数据：默认选中第一个任务
                    let firstTask = tasks.first!
                    TDMainViewModel.shared.selectTask(firstTask)
                    print("点击日期为：\(dateModel.date.formattedString)，选中第一个任务：\(firstTask.taskContent)")
                } else {
                    // 没有数据：清空选中的任务
                    TDMainViewModel.shared.selectedTask = nil
                    print("点击日期为：\(dateModel.date.formattedString)，该日期无任务数据")
                }

                print("点击日期为：\(dateModel.date.formattedString)")
            }
            .onDrop(of: [.text], isTargeted: nil) { providers in
                // 处理拖拽放置
                guard let provider = providers.first else { return false }
                
                provider.loadItem(forTypeIdentifier: "public.text", options: nil) { (item, error) in
                    if let data = item as? Data,
                       let taskId = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            // 使用 TDQueryConditionManager 根据 taskId 查询任务
                            Task {
                                do {
                                    let queryManager = TDQueryConditionManager()
                                    let modelContainer = TDModelContainer.shared
                                    
                                    if let task = try await queryManager.getLocalTaskByTaskId(
                                        taskId: taskId,
                                        context: modelContainer.mainContext
                                    ) {
                                        print("🔄 拖拽任务: \(task.taskContent) 到日期: \(dateModel.date.formattedString)")
                                        await moveTaskToDate(task: task, targetDate: dateModel.date)
                                    } else {
                                        print("❌ 未找到任务ID: \(taskId)")
                                    }
                                } catch {
                                    print("❌ 查询任务失败: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
                return true
            }

        }
    
        
    }
    /// 根据单元格高度计算可显示的最大任务数量
    /// - Returns: 可显示的任务数量
    private func calculateMaxTasks() -> Int {
        // 基础高度：阳历文字高度(12) + VStack间距(2) + 水平内边距(4*2=8)
        let baseHeight: CGFloat = 14 + 2 + 8 // 22pt
        let availableHeight = cellHeight - baseHeight
        
        // 每个任务行的高度（根据字体大小动态计算，包括上下间距1pt）
        let fontSize = settingManager.fontSize.size
        let taskRowHeight = fontSize + 3 // 字体高度 + 上下间距
        
        // 计算可显示的任务数量（根据实际高度能显示多少就显示多少）
        let maxTasks = max(0, Int(availableHeight / taskRowHeight))
        
        return maxTasks
    }
    
    
    /// 移动任务到指定日期的核心逻辑
    /// - Parameters:
    ///   - task: 要移动的任务
    ///   - targetDate: 目标日期
    private func moveTaskToDate(task: TDMacSwiftDataListModel, targetDate: Date) async {
        let queryManager = TDQueryConditionManager()
        let modelContainer = TDModelContainer.shared
        
        do {
            // 1. 更新任务的 todoTime 为目标日期的时间戳
            let targetTimestamp = targetDate.startOfDayTimestamp
            
            // 2. 使用 TDQueryConditionManager 的智能计算方法
            let newTaskSort = try await queryManager.calculateTaskSortForNewTask(
                todoTime: targetTimestamp,
                context: modelContainer.mainContext
            )
            
            // 3. 创建更新后的任务对象
            let updatedTask = task
            updatedTask.todoTime = targetTimestamp
            updatedTask.taskSort = newTaskSort
            
            // 4. 更新任务到数据库
            let result = try await queryManager.updateLocalTaskWithModel(
                updatedTask: updatedTask,
                context: modelContainer.mainContext
            )
            
            if result == .updated {
                print("✅ 任务移动成功: \(task.taskContent) 到日期: \(targetDate.formattedString), 新 taskSort: \(newTaskSort)")
                
                // 5. 触发数据同步
                await TDMainViewModel.shared.performSyncSeparately()
            } else {
                print("❌ 任务移动失败: 更新结果异常")
            }
            
        } catch {
            print("❌ 任务移动失败: \(error.localizedDescription)")
        }
    }


}


// MARK: - 预览
#Preview {
    TDCalendarGridView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
        .environmentObject(TDScheduleOverviewViewModel.shared)
}




//struct CustomHorizontalPagingBehavior: ScrollTargetBehavior {
//  enum Direction {
//    case left, right, none
//  }
//
//  func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
//    let scrollViewWidth = context.containerSize.width
//    let contentWidth = context.contentSize.width
//
//    // 如果内容宽度小于或等于ScrollView宽度，对齐到最左边位置
//    guard contentWidth > scrollViewWidth else {
//      target.rect.origin.x = 0
//      return
//    }
//
//    let originalOffset = context.originalTarget.rect.minX
//    let targetOffset = target.rect.minX
//
//    // 通过比较原始偏移量和目标偏移量来确定滚动方向
//    let direction: Direction = targetOffset > originalOffset ? .left : (targetOffset < originalOffset ? .right : .none)
//    guard direction != .none else {
//      target.rect.origin.x = originalOffset
//      return
//    }
//
//    let thresholdRatio: CGFloat = 1 / 3
//
//    // 根据滚动方向计算剩余内容宽度并确定拖动阈值
//    let remaining: CGFloat = direction == .left
//      ? (contentWidth - context.originalTarget.rect.maxX)
//      : (context.originalTarget.rect.minX)
//
//    let threshold = remaining <= scrollViewWidth ? remaining * thresholdRatio : scrollViewWidth * thresholdRatio
//
//    let dragDistance = originalOffset - targetOffset
//    var destination: CGFloat = originalOffset
//
//    if abs(dragDistance) > threshold {
//      // 如果拖动距离超过阈值，调整目标到上一页或下一页
//      destination = dragDistance > 0 ? originalOffset - scrollViewWidth : originalOffset + scrollViewWidth
//    } else {
//      // 如果拖动距离在阈值内，根据滚动方向对齐
//      if direction == .right {
//        // 向右滚动（向左翻页），向上取整
//        destination = ceil(originalOffset / scrollViewWidth) * scrollViewWidth
//      } else {
//        // 向左滚动（向右翻页），向下取整
//        destination = floor(originalOffset / scrollViewWidth) * scrollViewWidth
//      }
//    }
//
//    // 边界处理：确保目标位置在有效范围内并与页面对齐
//    let maxOffset = contentWidth - scrollViewWidth
//    let boundedDestination = min(max(destination, 0), maxOffset)
//
//    if boundedDestination >= maxOffset * 0.95 {
//      // 如果接近末尾，贴合到最后可能的位置
//      destination = maxOffset
//    } else if boundedDestination <= scrollViewWidth * 0.05 {
//      // 如果接近开始，贴合到起始位置
//      destination = 0
//    } else {
//      if direction == .right {
//        // 对于从右向左滚动，从右端计算
//        let offsetFromRight = maxOffset - boundedDestination
//        let pageFromRight = round(offsetFromRight / scrollViewWidth)
//        destination = maxOffset - (pageFromRight * scrollViewWidth)
//      } else {
//        // 对于从左向右滚动，保持原始行为
//        let pageNumber = round(boundedDestination / scrollViewWidth)
//        destination = min(pageNumber * scrollViewWidth, maxOffset)
//      }
//    }
//
//    target.rect.origin.x = destination
//  }
//}
//extension ScrollTargetBehavior where Self == CustomHorizontalPagingBehavior {
//    static var horizontalPaging: CustomHorizontalPagingBehavior { .init() }
//}
//
