////
////  TDTaskListView.swift
////  TodoMacRepertorie
////
////  Created by 孬孬 on 2024/12/28.
////
//
//import SwiftUI
//import SwiftData
//import Foundation
//
///// 任务列表界面 - 用于最近待办、未分类和用户分类
//struct TDTaskListView: View {
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @Environment(\.modelContext) private var modelContext
//    
//    let category: TDSliderBarModel
//    let tagFilter: String
//
//    // 状态变量：控制复制成功Toast的显示
//    @State private var showCopySuccessToast = false
//    // 监听多选模式状态变化
//    @ObservedObject private var mainViewModel = TDMainViewModel.shared
//
//    // MARK: - 分组ID（直接使用枚举的rawValue）
//    // 过期已达成=0, 过期未达成=1, 今天=2, 明天=3, 后天=4, 后续日程=5, 无日期=6
//    
//    // 为每个分组定义单独的 @Query，分别查询各个分组的任务数据
//    @Query private var overdueCompletedTasks: [TDMacSwiftDataListModel]  // 过期已完成任务
//    @Query private var overdueUncompletedTasks: [TDMacSwiftDataListModel]  // 过期未完成任务
//    @Query private var todayTasks: [TDMacSwiftDataListModel]  // 今天任务
//    @Query private var tomorrowTasks: [TDMacSwiftDataListModel]  // 明天任务
//    @Query private var dayAfterTomorrowTasks: [TDMacSwiftDataListModel]  // 后天任务
//    @Query private var futureScheduleTasks: [TDMacSwiftDataListModel]  // 后续日程任务
//    @Query private var noDateTasks: [TDMacSwiftDataListModel]  // 无日期任务
//    
//    // 分组展开状态管理
//    @State private var expandedGroups: Set<Int> = Self.getDefaultExpandedGroups()
//    @State private var hoveredGroups: Set<Int> = []
//    
//    init(category: TDSliderBarModel, tagFilter: String = "") {
//        self.category = category
//        self.tagFilter = tagFilter
//        
//        // 根据分类ID初始化查询条件
//        let categoryId = category.categoryId
//        
//        // 初始化各个分组的查询条件
//        let (overdueCompletedPredicate, overdueCompletedSort) = TDCorrectQueryBuilder.getExpiredCompletedQuery(categoryId: categoryId, tagFilter: tagFilter)
//        let (overdueUncompletedPredicate, overdueUncompletedSort) = TDCorrectQueryBuilder.getExpiredUncompletedQuery(categoryId: categoryId, tagFilter: tagFilter)
//        let (todayPredicate, todaySort) = TDCorrectQueryBuilder.getTodayQuery(categoryId: categoryId, tagFilter: tagFilter)
//        let (tomorrowPredicate, tomorrowSort) = TDCorrectQueryBuilder.getTomorrowQuery(categoryId: categoryId, tagFilter: tagFilter)
//        let (dayAfterTomorrowPredicate, dayAfterTomorrowSort) = TDCorrectQueryBuilder.getDayAfterTomorrowQuery(categoryId: categoryId, tagFilter: tagFilter)
//        let (futureSchedulePredicate, futureScheduleSort) = TDCorrectQueryBuilder.getFutureScheduleQuery(categoryId: categoryId, tagFilter: tagFilter)
//        let (noDatePredicate, noDateSort) = TDCorrectQueryBuilder.getNoDateQuery(categoryId: categoryId, tagFilter: tagFilter)
//        
//        // 初始化各个 @Query，分别查询各个分组的任务数据
//        _overdueCompletedTasks = Query(filter: overdueCompletedPredicate, sort: overdueCompletedSort)
//        _overdueUncompletedTasks = Query(filter: overdueUncompletedPredicate, sort: overdueUncompletedSort)
//        _todayTasks = Query(filter: todayPredicate, sort: todaySort)
//        _tomorrowTasks = Query(filter: tomorrowPredicate, sort: tomorrowSort)
//        _dayAfterTomorrowTasks = Query(filter: dayAfterTomorrowPredicate, sort: dayAfterTomorrowSort)
//        _futureScheduleTasks = Query(filter: futureSchedulePredicate, sort: futureScheduleSort)
//        _noDateTasks = Query(filter: noDatePredicate, sort: noDateSort)
//    }
//
//    // MARK: - 静态方法
//    
//    /// 获取默认展开状态的分组ID集合
//    /// 过期已达成默认关闭，其他分组默认展开
//    private static func getDefaultExpandedGroups() -> Set<Int> {
//        // 直接使用枚举的rawValue，简单直接
//        return [1, 2, 3, 4, 5, 6] // 过期未达成=1, 今天=2, 明天=3, 后天=4, 后续日程=5, 无日期=6
//        // 注意：0（过期已达成）不包含在内，所以默认是关闭的
//    }
//    
//    // MARK: - 计算属性
//    
//    private var allTasksCount: Int {
//        overdueCompletedTasks.count
//        + overdueUncompletedTasks.count
//        + todayTasks.count
//        + tomorrowTasks.count
//        + dayAfterTomorrowTasks.count
//        + futureScheduleTasks.count
//        + noDateTasks.count
//    }
//
//    /// 仅在需要时才拼接（避免滚动/hover 时反复分配大数组）
//    private var allTasksFlattened: [TDMacSwiftDataListModel] {
//        overdueCompletedTasks + overdueUncompletedTasks + todayTasks + tomorrowTasks + dayAfterTomorrowTasks + futureScheduleTasks + noDateTasks
//    }
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // 任务输入框
//            TDTaskInputView()
//                .padding(.horizontal, 20)
//                .padding(.vertical, 16)
//            
//            // 任务分组列表
//            if allTasksCount == 0 {
//                // 空状态
//                VStack(spacing: 16) {
//                    Image(systemName: "checkmark.circle")
//                        .font(.system(size: 48))
//                        .foregroundColor(.secondary)
//                    
//                    Text("暂无任务")
//                        .font(.headline)
//                        .foregroundColor(.secondary)
//                    
//                    Text("点击上方输入框添加新任务")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .padding(.top, 60)
//            } else {
//                // 分组列表
//                ScrollView {
//                    LazyVStack(spacing: 0) {
//                        // 过期已达成组
//                        if shouldShowOverdueCompletedGroup {
//                            overdueCompletedGroup
//                        }
//                        // 过期未达成组
//                        if shouldShowOverdueUncompletedGroup {
//                            overdueUncompletedGroup
//                        }
//                        // 今天组
//                        if !todayTasks.isEmpty {
//                            todayGroup
//                        }
//                        // 明天组
//                        if !tomorrowTasks.isEmpty {
//                            tomorrowGroup
//                        }
//                        // 后天组
//                        if !dayAfterTomorrowTasks.isEmpty {
//                            dayAfterTomorrowGroup
//                        }
//                        // 后续日程组
//                        if !futureScheduleTasks.isEmpty {
//                            futureScheduleGroup
//                        }
//                        // 无日期组
//                        if shouldShowNoDateGroup {
//                            noDateGroup
//                        }
//                    }
//                }
//                .scrollIndicators(.hidden)
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color(.windowBackgroundColor))
//        // 多选操作栏 - 只在多选模式下显示
//        .overlay(
//            Group {
//                if mainViewModel.isMultiSelectMode {
//                    let tasks = allTasksFlattened
//                    VStack {
//                        Spacer()
//                        TDMultiSelectActionBar(allTasks: tasks)
//                    }
//                }
//            }
//        )
//        // 复制成功提示
//        .tdToastBottom(
//            isPresenting: $showCopySuccessToast,
//            message: "copy_success_simple".localized,
//            type: .success
//        )
//    }
//    
//    // MARK: - 分组显示条件
//    
//    /// 是否显示过期已达成组
//    private var shouldShowOverdueCompletedGroup: Bool {
//        let settingManager = TDSettingManager.shared
//        return settingManager.expiredRangeCompleted != .hide && !overdueCompletedTasks.isEmpty
//    }
//    
//    /// 是否显示过期未达成组
//    private var shouldShowOverdueUncompletedGroup: Bool {
//        let settingManager = TDSettingManager.shared
//        return settingManager.expiredRangeUncompleted != .hide && !overdueUncompletedTasks.isEmpty
//    }
//    
//    /// 是否显示无日期组
//    private var shouldShowNoDateGroup: Bool {
//        let settingManager = TDSettingManager.shared
//        return settingManager.showNoDateEvents && !noDateTasks.isEmpty
//    }
//    
//    // MARK: - 分组视图
//    
//    /// 过期已达成组
//    private var overdueCompletedGroup: some View {
//        taskGroupSection(
//            type: .overdueCompleted,
//            tasks: overdueCompletedTasks,
//            title: "overdue_completed".localized,
//            completedCount: overdueCompletedTasks.count,
//            totalCount: overdueCompletedTasks.count
//        )
//    }
//    
//    /// 过期未达成组
//    private var overdueUncompletedGroup: some View {
//        taskGroupSection(
//            type: .overdueUncompleted,
//            tasks: overdueUncompletedTasks,
//            title: "overdue_uncompleted".localized,
//            completedCount: 0,
//            totalCount: overdueUncompletedTasks.count
//        )
//    }
//    
//    /// 今天组
//    private var todayGroup: some View {
//        let completedCount = todayTasks.filter { $0.complete }.count
//        return taskGroupSection(
//            type: .today,
//            tasks: todayTasks,
//            title: "today".localized,
//            completedCount: completedCount,
//            totalCount: todayTasks.count
//        )
//    }
//    
//    /// 明天组
//    private var tomorrowGroup: some View {
//        let completedCount = tomorrowTasks.filter { $0.complete }.count
//        return taskGroupSection(
//            type: .tomorrow,
//            tasks: tomorrowTasks,
//            title: "tomorrow".localized,
//            completedCount: completedCount,
//            totalCount: tomorrowTasks.count
//        )
//    }
//    
//    /// 后天组
//    private var dayAfterTomorrowGroup: some View {
//        let completedCount = dayAfterTomorrowTasks.filter { $0.complete }.count
//        return taskGroupSection(
//            type: .dayAfterTomorrow,
//            tasks: dayAfterTomorrowTasks,
//            title: "day_after_tomorrow".localized,
//            completedCount: completedCount,
//            totalCount: dayAfterTomorrowTasks.count
//        )
//    }
//    
//    /// 后续日程组
//    private var futureScheduleGroup: some View {
//        let completedCount = futureScheduleTasks.filter { $0.complete }.count
//        return taskGroupSection(
//            type: .upcomingSchedule,
//            tasks: futureScheduleTasks,
//            title: "upcoming_schedule".localized,
//            completedCount: completedCount,
//            totalCount: futureScheduleTasks.count
//        )
//    }
//    
//    /// 无日期组
//    private var noDateGroup: some View {
//        let completedCount = noDateTasks.filter { $0.complete }.count
//        return taskGroupSection(
//            type: .noDate,
//            tasks: noDateTasks,
//            title: "no_date".localized,
//            completedCount: completedCount,
//            totalCount: noDateTasks.count
//        )
//    }
//    
//    /// 通用任务分组区域
//    private func taskGroupSection(
//        type: TDTaskGroupType,
//        tasks: [TDMacSwiftDataListModel],
//        title: String,
//        completedCount: Int,
//        totalCount: Int
//    ) -> some View {
//        DisclosureGroup(
//            isExpanded: Binding(
//                get: { expandedGroups.contains(type.rawValue) },
//                set: { isExpanded in
//                    toggleGroupExpansion(for: type.rawValue)
//                }
//            ),
//            content: {
//                VStack(spacing: 0) {
//                    ForEach(Array(tasks.enumerated()), id: \.element.taskId) { index, task in
//                        TDTaskRowView(
//                            task: task,
//                            category: category,
//                            orderNumber: nil,
//                            isFirstRow: index == 0,
//                            isLastRow: index == tasks.count - 1,
//                            onCopySuccess: {
//                                // 显示复制成功提示
//                                showCopySuccessToast = true
//                            },
//                            onEnterMultiSelect: {
//                                // 进入多选模式时的回调，可以在这里添加其他逻辑
//                            }
//                        )
//                        .padding(.leading, 16)
//                        .padding(.vertical, 4)
//                    }
//                }
//            },
//            label: {
//                taskGroupHeaderView(
//                    type: type,
//                    title: title,
//                    totalCount: totalCount
//                )
//                .contentShape(Rectangle())
//                .onTapGesture {
//                    toggleGroupExpansion(for: type.rawValue)
//                }
//            }
//        )
//    }
//    
//    /// 分组头部视图
//    private func taskGroupHeaderView(
//        type: TDTaskGroupType,
//        title: String,
//        totalCount: Int
//    ) -> some View {
//        HStack {
//            // 分组标题
//            Text(title)
//                .font(.system(size: 14))
//                .foregroundColor(getTitleColor(for: type))
//            
//            Spacer()
//            
//            // 任务数量标签 - 只在有任务时才显示
//            if totalCount > 0 {
//                Text("\(totalCount)")
//                    .font(.system(size: 11, weight: .medium))
//                    .foregroundColor(themeManager.descriptionTextColor)
//                    .padding(.horizontal, 6)
//                    .padding(.vertical, 2)
//                    .background(
//                        RoundedRectangle(cornerRadius: 8)
//                            .fill(themeManager.color(level: 1))
//                    )
//            }
//            
//            // 按钮组（鼠标悬停时显示）
//            HStack(spacing: 4) {
//                // 设置按钮（如果需要）
//                if type.needsSettingsIcon {
//                    Button(action: {
//                        // TODO: 显示设置弹窗
//                    }) {
//                        Image(systemName: "gearshape")
//                            .font(.system(size: 12))
//                            .foregroundColor(.secondary)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                    .pointingHandCursor()
//                }
//                
//                // 重新安排按钮（如果需要）
//                if type.needsRescheduleButton {
//                    Button(action: {
//                        // TODO: 重新安排所有过期任务
//                    }) {
//                        Image(systemName: "arrow.clockwise")
//                            .font(.system(size: 12))
//                            .foregroundColor(.secondary)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                    .pointingHandCursor()
//
//                }
//            }
//            .opacity(hoveredGroups.contains(type.rawValue) ? 1 : 0)
//        }
//        .padding(.horizontal, 16)
//        .frame(height: 36) // 固定高度36
//        .background(getGroupHeaderBackgroundColor(for: type)) // 添加背景色
//        .onHover { isHovered in
//            withAnimation(.easeInOut(duration: 0.2)) {
//                if isHovered {
//                    hoveredGroups.insert(type.rawValue)
//                } else {
//                    hoveredGroups.remove(type.rawValue)
//                }
//            }
//        }
//    }
//    
//    // MARK: - 颜色获取方法
//    
//    /// 根据分组类型获取标题颜色
//    private func getTitleColor(for groupType: TDTaskGroupType) -> Color {
//        switch groupType.titleColorType {
//        case .descriptionColor:
//            return themeManager.descriptionTextColor
//        case .themeLevel6:
//            return themeManager.color(level: 6)
//        case .fixedNewYearRed:
//            return themeManager.fixedColor(themeId: "new_year_red", level: 6)
//        }
//    }
//    
//    /// 切换分组展开状态（性能优化版本）
//    private func toggleGroupExpansion(for groupId: Int) {
//        // 减少动画时长，提升性能
//        withAnimation(.easeInOut(duration: 0.1)) {
//            if expandedGroups.contains(groupId) {
//                expandedGroups.remove(groupId)
//            } else {
//                expandedGroups.insert(groupId)
//            }
//        }
//    }
//    
//    /// 根据分组类型获取组头背景色
//    private func getGroupHeaderBackgroundColor(for groupType: TDTaskGroupType) -> Color {
//        switch groupType {
//        case .overdueCompleted, .noDate:
//            // 过期已达成和无日期：使用主题背景色1级
//            return themeManager.color(level: 1)
//        case .overdueUncompleted:
//            // 过期未达成：使用新年红2级
//            return themeManager.fixedColor(themeId: "new_year_red", level: 2)
//        case .today, .tomorrow, .dayAfterTomorrow, .upcomingSchedule:
//            // 今天、明天、后天、后续日程：使用主题色2级
//            return themeManager.color(level: 2)
//        }
//    }
//}
//
//#Preview {
//    TDTaskListView(category: TDSliderBarModel(
//        categoryId: 1,
//        categoryName: "示例分类",
//        headerIcon: nil,
//        categoryColor: "#FF6B6B",
//        unfinishedCount: 5,
//        isSelect: false
//    ))
//    .environmentObject(TDThemeManager.shared)
//}


import SwiftUI
import SwiftData
import Foundation

/// 任务列表界面 - 用于最近待办、未分类和用户分类
struct TDTaskListView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    
    let category: TDSliderBarModel
    let tagFilter: String

    // 状态变量：控制复制成功Toast的显示
    @State private var showCopySuccessToast = false
    // 监听多选模式状态变化
    @ObservedObject private var mainViewModel = TDMainViewModel.shared

    // 关键优化：只保留 1 个 @Query
    // - 切换分类时由 7 次查询 → 1 次查询，显著降低 CPU 峰值与“切换慢”
    // - 分组逻辑不变：仅把“分组”从数据库层挪到内存一次遍历完成
    @Query private var tasks: [TDMacSwiftDataListModel]
    
    init(category: TDSliderBarModel, tagFilter: String = "") {
        self.category = category
        self.tagFilter = tagFilter
        
        // 根据分类ID初始化查询条件
        let categoryId = category.categoryId
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getTaskListSupersetQuery(
            categoryId: categoryId,
            tagFilter: tagFilter
        )
        _tasks = Query(filter: predicate, sort: sortDescriptors)
    }

    // MARK: - 计算属性
    
    /// 获取当前分类的所有任务（用于多选功能）
    private var allTasksCount: Int { tasks.count }
    private var allTasksFlattened: [TDMacSwiftDataListModel] { tasks }

    private struct GroupedTasks {
        var overdueCompleted: [TDMacSwiftDataListModel] = []
        var overdueUncompleted: [TDMacSwiftDataListModel] = []
        var today: [TDMacSwiftDataListModel] = []
        var tomorrow: [TDMacSwiftDataListModel] = []
        var dayAfterTomorrow: [TDMacSwiftDataListModel] = []
        var futureSchedule: [TDMacSwiftDataListModel] = []
        var noDate: [TDMacSwiftDataListModel] = []
    }

    /// 一次遍历完成分组（避免 7 次 filter）
    private func groupTasks(_ tasks: [TDMacSwiftDataListModel]) -> GroupedTasks {
        var grouped = GroupedTasks()
        grouped.overdueCompleted.reserveCapacity(32)
        grouped.overdueUncompleted.reserveCapacity(32)
        grouped.today.reserveCapacity(32)
        grouped.tomorrow.reserveCapacity(32)
        grouped.dayAfterTomorrow.reserveCapacity(32)
        grouped.futureSchedule.reserveCapacity(32)
        grouped.noDate.reserveCapacity(32)

        let settingManager = TDSettingManager.shared
        let showCompleted = settingManager.showCompletedTasks
        let showNoDate = settingManager.showNoDateEvents
        let showCompletedNoDate = settingManager.showCompletedNoDateEvents
        let completedDaysLimit = settingManager.expiredRangeCompleted.rawValue
        let uncompletedDaysLimit = settingManager.expiredRangeUncompleted.rawValue
        let futureScheduleDaysLimit = settingManager.futureDateRange.rawValue

        let allowByCompletedSetting: (TDMacSwiftDataListModel) -> Bool = { showCompleted || !$0.complete }

        let today = Date()
        let todayTimestamp = today.startOfDayTimestamp
        let tomorrowTimestamp = today.adding(days: 1).startOfDayTimestamp
        let dayAfterTomorrowTimestamp = today.adding(days: 2).startOfDayTimestamp

        let completedStartTimestamp = today.adding(days: -completedDaysLimit).startOfDayTimestamp
        let uncompletedStartTimestamp = today.adding(days: -uncompletedDaysLimit).startOfDayTimestamp

        let futureUpperBound: Int64 = {
            if futureScheduleDaysLimit <= 0 { return Int64.max }
            return today.adding(days: futureScheduleDaysLimit).endOfDayTimestamp
        }()

        for task in tasks {
            let tt = task.todoTime
            if tt == 0 {
                // 无日期：严格按设置过滤
                if showNoDate && (showCompletedNoDate || !task.complete) {
                    grouped.noDate.append(task)
                }
                continue
            }
            if tt < todayTimestamp {
                // 过期：complete 决定分组
                if task.complete {
                    // 过期已达成：仅 showCompleted=true 且在设置范围内
                    if showCompleted && completedDaysLimit > 0 && tt >= completedStartTimestamp {
                        grouped.overdueCompleted.append(task)
                    }
                } else {
                    // 过期未达成：在设置范围内
                    if uncompletedDaysLimit > 0 && tt >= uncompletedStartTimestamp {
                        grouped.overdueUncompleted.append(task)
                    }
                }
                continue
            }

            // 今天/明天/后天（按设置可能不含已完成）
            if tt == todayTimestamp {
                if allowByCompletedSetting(task) { grouped.today.append(task) }
                continue
            }
            if tt == tomorrowTimestamp {
                if allowByCompletedSetting(task) { grouped.tomorrow.append(task) }
                continue
            }
            if tt == dayAfterTomorrowTimestamp {
                if allowByCompletedSetting(task) { grouped.dayAfterTomorrow.append(task) }
                continue
            }

            // 后续日程
            if tt > dayAfterTomorrowTimestamp {
                if allowByCompletedSetting(task), tt <= futureUpperBound {
                    grouped.futureSchedule.append(task)
                }
            }
        }

        return grouped
    }
    
    var body: some View {
        let grouped = groupTasks(tasks)
        let settingManager = TDSettingManager.shared

        VStack(spacing: 0) {
            // 任务输入框
            TDTaskInputView()
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            
            // 任务分组列表
            if tasks.isEmpty {
                // 空状态
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("暂无任务")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("点击上方输入框添加新任务")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 60)
            } else {
                // 分组列表
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // 过期已达成组
                        if settingManager.expiredRangeCompleted != .hide, !grouped.overdueCompleted.isEmpty {
                            TDTaskGroupSectionView(
                                type: .overdueCompleted,
                                tasks: grouped.overdueCompleted,
                                title: "overdue_completed".localized,
                                totalCount: grouped.overdueCompleted.count,
                                category: category,
                                onCopySuccess: { showCopySuccessToast = true }
                            )
                            .id(TDTaskGroupType.overdueCompleted.rawValue)
                        }
                        // 过期未达成组
                        if settingManager.expiredRangeUncompleted != .hide, !grouped.overdueUncompleted.isEmpty {
                            TDTaskGroupSectionView(
                                type: .overdueUncompleted,
                                tasks: grouped.overdueUncompleted,
                                title: "overdue_uncompleted".localized,
                                totalCount: grouped.overdueUncompleted.count,
                                category: category,
                                onCopySuccess: { showCopySuccessToast = true }
                            )
                            .id(TDTaskGroupType.overdueUncompleted.rawValue)
                        }
                        // 今天组
                        if !grouped.today.isEmpty {
                            TDTaskGroupSectionView(
                                type: .today,
                                tasks: grouped.today,
                                title: "today".localized,
                                totalCount: grouped.today.count,
                                category: category,
                                onCopySuccess: { showCopySuccessToast = true }
                            )
                            .id(TDTaskGroupType.today.rawValue)
                        }
                        // 明天组
                        if !grouped.tomorrow.isEmpty {
                            TDTaskGroupSectionView(
                                type: .tomorrow,
                                tasks: grouped.tomorrow,
                                title: "tomorrow".localized,
                                totalCount: grouped.tomorrow.count,
                                category: category,
                                onCopySuccess: { showCopySuccessToast = true }
                            )
                            .id(TDTaskGroupType.tomorrow.rawValue)
                        }
                        // 后天组
                        if !grouped.dayAfterTomorrow.isEmpty {
                            TDTaskGroupSectionView(
                                type: .dayAfterTomorrow,
                                tasks: grouped.dayAfterTomorrow,
                                title: "day_after_tomorrow".localized,
                                totalCount: grouped.dayAfterTomorrow.count,
                                category: category,
                                onCopySuccess: { showCopySuccessToast = true }
                            )
                            .id(TDTaskGroupType.dayAfterTomorrow.rawValue)
                        }
                        // 后续日程组
                        if !grouped.futureSchedule.isEmpty {
                            TDTaskGroupSectionView(
                                type: .upcomingSchedule,
                                tasks: grouped.futureSchedule,
                                title: "upcoming_schedule".localized,
                                totalCount: grouped.futureSchedule.count,
                                category: category,
                                onCopySuccess: { showCopySuccessToast = true }
                            )
                            .id(TDTaskGroupType.upcomingSchedule.rawValue)
                        }
                        // 无日期组
                        if settingManager.showNoDateEvents, !grouped.noDate.isEmpty {
                            TDTaskGroupSectionView(
                                type: .noDate,
                                tasks: grouped.noDate,
                                title: "no_date".localized,
                                totalCount: grouped.noDate.count,
                                category: category,
                                onCopySuccess: { showCopySuccessToast = true }
                            )
                            .id(TDTaskGroupType.noDate.rawValue)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
        // 多选操作栏 - 只在多选模式下显示
        .overlay(
            Group {
                if mainViewModel.isMultiSelectMode {
                    let tasks = allTasksFlattened
                    VStack {
                        Spacer()
                        TDMultiSelectActionBar(allTasks: tasks)
                    }
                }
            }
        )
        // 复制成功提示
        .tdToastBottom(
            isPresenting: $showCopySuccessToast,
            message: "copy_success_simple".localized,
            type: .success
        )
    }
}

// MARK: - 分组子视图：把展开/悬停状态下沉，避免父视图整棵树频繁重算导致卡顿

/// 自定义 DisclosureGroup 样式（隐藏系统左侧箭头，只保留 DisclosureGroup 的原生展开动画）
/// - 目的：你要“用 DisclosureGroup 的动画”，但界面完全自定义（箭头在最右侧、按钮布局按规范）
private struct TDNoIndicatorDisclosureGroupStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 0) {
            configuration.label
            if configuration.isExpanded {
                configuration.content
            }
        }
    }
}


private struct TDTaskGroupSectionView: View {
    @EnvironmentObject private var themeManager: TDThemeManager

    let type: TDTaskGroupType
    let tasks: [TDMacSwiftDataListModel]
    let title: String
    let totalCount: Int
    let category: TDSliderBarModel
    let onCopySuccess: () -> Void

    @State private var isExpanded: Bool

    init(
        type: TDTaskGroupType,
        tasks: [TDMacSwiftDataListModel],
        title: String,
        totalCount: Int,
        category: TDSliderBarModel,
        onCopySuccess: @escaping () -> Void
    ) {
        self.type = type
        self.tasks = tasks
        self.title = title
        self.totalCount = totalCount
        self.category = category
        self.onCopySuccess = onCopySuccess
        // 默认：过期已达成关闭，其它分组展开（与原逻辑一致）
        _isExpanded = State(initialValue: type != .overdueCompleted)
    }

    var body: some View {
        // 使用 DisclosureGroup：保留系统更稳定的展开/收起动画
        // 但通过自定义 DisclosureGroupStyle 隐藏系统左侧箭头，界面仍由我们完全自定义
        VStack(spacing: 0) {
            DisclosureGroup(
                isExpanded: $isExpanded,
                content: {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks.indices, id: \.self) { index in
                            let task = tasks[index]
                            TDTaskRowView(
                                task: task,
                                category: category,
                                orderNumber: nil,
                                isFirstRow: index == 0,
                                isLastRow: index == tasks.count - 1,
                                onCopySuccess: onCopySuccess,
                                onEnterMultiSelect: { }
                            )
//                            .padding(.leading, 16)
//                            .padding(.vertical, 4)
                        }
                    }
                },
                label: {
                    TDTaskGroupHeaderView(
                        type: type,
                        title: title,
                        tasks: tasks,
                        totalCount: totalCount,
                        isExpanded: $isExpanded
                    )
                }
            )
            .disclosureGroupStyle(TDNoIndicatorDisclosureGroupStyle())

            // 关键细节：
            // - 只有“收起”时才在组与组之间留 2pt 间距
            // - “展开”时绝不增加底部空隙，避免最后一组/最后一行看起来多出一截
            if !isExpanded {
                Color.clear.frame(height: 2)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

private struct TDTaskGroupHeaderView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @ObservedObject private var mainViewModel = TDMainViewModel.shared
    /// 用于打开「设置」窗口（App 内 WindowGroup(id: "Settings")）
    @Environment(\.openWindow) private var openWindow

    let type: TDTaskGroupType
    let title: String
    let tasks: [TDMacSwiftDataListModel]
    let totalCount: Int
    @Binding var isExpanded: Bool

    @State private var isHovering: Bool = false

    var body: some View {
        HStack {
            // MARK: - 左侧标题（带国际化 + 动态信息）
            HStack(spacing: 8) {
                Text(displayTitle)
                    .font(.system(size: 14))
                    .foregroundColor(titleColor)

                // 设置按钮：紧挨着标题右侧（按你的视觉规范）
                // 规则：只在鼠标悬停到“当前组头”时显示；颜色 = 主题色 5 级；每组独立控制
                if type.needsSettingsIcon {
                    Button(action: {
                        // TODO: 打开对应组的设置面板（这里只做 UI 优化，不改业务逻辑）
                        // 打开设置弹窗，并直接切换到「事件设置」
                        // 说明：
                        // - 通过 settingsSidebarStore 的选中项驱动右侧详情页
                        // - 使用 WindowGroup(id: "Settings") 打开/激活设置窗口
                        TDSettingsSidebarStore.shared.TDHandleSettingSelection(.eventSettings)
                        TDSettingsWindowTracker.shared.presentSettingsWindow(using: openWindow)

                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.color(level: 5))
                            .frame(width: 20, height: 20, alignment: .center)
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                    .opacity(isHovering ? 1 : 0)
                    .allowsHitTesting(isHovering)
                    .accessibilityHidden(!isHovering)
                }
            }

            Spacer()
            // MARK: - 右侧数量（每组规则不同：过往未达成不展示数量；后天展示“未完成数”）
            if shouldShowCount {
                Text("\(displayCount)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(countColor)
            }

            // MARK: - 悬停按钮（每组单独控制）
            // MARK: - 悬停按钮（每组单独控制）
            // 规则：
            // - “过往未达成”的重新安排按钮：只在悬停显示；颜色 = 新年红 5 级
            HStack(spacing: 8) {
                if type.needsRescheduleButton {
                    Button(action: {
                        // “重新安排”一键流程（按你的要求）：
                        // 1) 如果该分组当前是关闭状态：先打开
                        // 2) 进入多选模式
                        // 3) 默认全选该分组全部任务
                        // 4) 弹出“选择日期”弹窗
                        if !isExpanded {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = true
                            }
                        }
                        // 进入多选模式并全选该分组任务
                        mainViewModel.enterMultiSelectMode()
                        mainViewModel.selectedTasks = tasks
                        // 弹出日期选择器（由多选操作栏响应该 token）
                        mainViewModel.requestShowMultiSelectDatePicker()
                    }) {
                        // 注意：这里是文字按钮，不是刷新图标
                        Text("task.group.reschedule".localized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                    .opacity(isHovering ? 1 : 0)
                    .allowsHitTesting(isHovering)
                    .accessibilityHidden(!isHovering)
                }
            }

            // MARK: - 展开/收起按钮（放最右侧，不占左侧箭头位）
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(chevronColor)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
        }
        .padding(.horizontal, 20)
        .frame(height: 36)
        .background(backgroundColor)
        .contentShape(Rectangle())
        // 点击组头空白区域也可展开/收起（与侧边栏一致的“轻交互”）
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
    }

    // MARK: - 标题构建（国际化 + 动态信息）

    /// 标题显示文本
    /// - 过往已达成/未达成：追加“（%d天内）”
    /// - 今天/明天/后天：追加“周几”
    private var displayTitle: String {
        let settingManager = TDSettingManager.shared
        switch type {
        case .overdueCompleted:
            let days = settingManager.expiredRangeCompleted.rawValue
            return title + withinDaysSuffix(days)
        case .overdueUncompleted:
            let days = settingManager.expiredRangeUncompleted.rawValue
            return title + withinDaysSuffix(days)
        case .today:
            return "\(title) \(Date().weekdayDisplay())"
        case .tomorrow:
            return "\(title) \(Date().adding(days: 1).weekdayDisplay())"
        case .dayAfterTomorrow:
            return "\(title) \(Date().adding(days: 2).weekdayDisplay())"
        case .upcomingSchedule, .noDate:
            return title
        }
    }

    /// “（%d天内）”后缀（国际化）
    private func withinDaysSuffix(_ days: Int) -> String {
        guard days > 0 else { return "" }
        return "task.group.within_days".localizedFormat(days)
    }

    // MARK: - 数量规则（每组不同）

    /// 是否显示数量
    /// - 过往未达成：不显示数量（按你的规则）
    private var shouldShowCount: Bool {
        switch type {
        case .overdueUncompleted:
            return false
        default:
            return totalCount > 0
        }
    }

    /// 右侧显示的数量
    /// - 后天：显示“未完成数量”
    /// - 其它：显示总数
    private var displayCount: Int {
        switch type {
        case .dayAfterTomorrow:
            // 注意：这里按你的规则显示“未完成数”
            return tasks.reduce(0) { $0 + ($1.complete ? 0 : 1) }
        default:
            return totalCount
        }
    }

    // MARK: - 颜色/背景规则（完全按你列的 7 条）

    /// 标题颜色
    private var titleColor: Color {
        switch type {
        case .today, .tomorrow, .dayAfterTomorrow, .upcomingSchedule:
            // 今天/明天/后天/后续日程：主题色 5 级
            return themeManager.color(level: 5)
        case .overdueUncompleted:
            // 过往未达成：新年红 5 级
            return themeManager.fixedColor(themeId: "new_year_red", level: 5)
        case .overdueCompleted, .noDate:
            // 过往已达成/无日期：主题标题颜色
            return themeManager.titleTextColor
        }
    }

    /// 数量颜色
    private var countColor: Color {
        switch type {
        case .today, .tomorrow, .dayAfterTomorrow, .upcomingSchedule:
            return themeManager.color(level: 5)
        case .overdueCompleted, .noDate:
            return themeManager.titleTextColor
        case .overdueUncompleted:
            return themeManager.fixedColor(themeId: "new_year_red", level: 5)
        }
    }

    /// 展开/收起箭头颜色
    private var chevronColor: Color {
        switch type {
        case .today, .tomorrow, .dayAfterTomorrow, .upcomingSchedule:
            return themeManager.color(level: 5)
        case .overdueUncompleted:
            return themeManager.fixedColor(themeId: "new_year_red", level: 5)
        case .overdueCompleted, .noDate:
            // 二级描述颜色
            return themeManager.descriptionTextColor
        }
    }

    /// 组头背景色
    private var backgroundColor: Color {
        switch type {
        case .overdueCompleted:
            // 二级背景色
            return themeManager.secondaryBackgroundColor
        case .overdueUncompleted:
            // 新年红 2 级
            return themeManager.fixedColor(themeId: "new_year_red", level: 2)
        case .today, .tomorrow, .dayAfterTomorrow, .upcomingSchedule:
            // 主题颜色 2 级
            return themeManager.color(level: 2)
        case .noDate:
            // 与“过往已达成”一致：二级背景色
            return themeManager.secondaryBackgroundColor
        }
    }
}

#Preview {
    TDTaskListView(category: TDSliderBarModel(
        categoryId: 1,
        categoryName: "示例分类",
        headerIcon: nil,
        categoryColor: "#FF6B6B",
        unfinishedCount: 5,
        isSelect: false
    ))
    .environmentObject(TDThemeManager.shared)
}
