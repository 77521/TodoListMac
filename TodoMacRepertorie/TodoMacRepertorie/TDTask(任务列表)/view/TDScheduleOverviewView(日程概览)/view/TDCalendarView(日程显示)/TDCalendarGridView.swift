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
    
    var body: some View {
        GeometryReader { geometry in
            let cellHeight = geometry.size.height / CGFloat(calendarManager.calendarDates.count)
            
            VStack(spacing: 0) {
                ForEach(Array(calendarManager.calendarDates.enumerated()), id: \.offset) { weekIndex, week in
                    HStack(spacing: 0) {
                        ForEach(week) { dateModel in
                            TDCalendarDayCell(
                                dateModel: dateModel,
//                                cellWidth: 0, // 使用0让单元格自动填充宽度
                                cellWidth: geometry.size.width / 7,
                                cellHeight: cellHeight
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

    /// 日历管理器
    @StateObject private var calendarManager = TDCalendarManager.shared
    /// 日程概览视图模型
    @EnvironmentObject private var viewModel: TDScheduleOverviewViewModel

    /// 使用 @Query 来实时监控任务数据
    @Query private var allTasks: [TDMacSwiftDataListModel]
    
    /// 拖拽状态
    @State private var draggedTask: TDMacSwiftDataListModel? = nil

    /// 当前日期的任务列表
    private var currentDateTasks: [TDMacSwiftDataListModel] {
        let tasks = allTasks
        
        // 应用标签筛选（仅当标签筛选值不为空时）
        if viewModel.tagFilter.isEmpty {
            // 没有标签筛选，直接返回原始任务列表
            return tasks
        } else {
            // 有标签筛选，进行筛选
            let filteredTasks = TDCorrectQueryBuilder.filterTasksByTag(tasks, tagFilter: viewModel.tagFilter)
            return filteredTasks
        }
    }


    /// 日期模型
    let dateModel: TDCalendarDateModel
    
    /// 单元格宽度
    let cellWidth: CGFloat
    
    /// 单元格高度
    let cellHeight: CGFloat
    
    /// 初始化方法 - 根据日期和筛选条件设置查询条件
    init(dateModel: TDCalendarDateModel, cellWidth: CGFloat, cellHeight: CGFloat) {
        self.dateModel = dateModel
        self.cellWidth = cellWidth
        self.cellHeight = cellHeight
        
        // 获取筛选条件
        let viewModel = TDScheduleOverviewViewModel.shared
        let dateTimestamp = dateModel.date.startOfDayTimestamp
        let categoryId = viewModel.selectedCategory?.categoryId ?? 0
        
        // 使用新的查询方法
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getLocalDataQuery(
            dateTimestamp: dateTimestamp,
            categoryId: categoryId,
            sortType: viewModel.sortType
        )
        _allTasks = Query(filter: predicate, sort: sortDescriptors)
    }

    
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
                    if !currentDateTasks.isEmpty {
                        TDCalendarTaskList(
                            tasks: currentDateTasks,
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
                    .stroke(dateModel.isSelected ? themeManager.color(level: 5) : Color.clear, lineWidth: 1)
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
                if !currentDateTasks.isEmpty {
                    // 有数据：默认选中第一个任务
                    let firstTask = currentDateTasks.first!
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
