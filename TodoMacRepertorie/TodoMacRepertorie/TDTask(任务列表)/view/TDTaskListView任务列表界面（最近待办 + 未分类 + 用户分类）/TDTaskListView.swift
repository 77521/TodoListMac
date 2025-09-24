//
//  TDTaskListView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData
import Foundation

/// 任务列表界面 - 用于最近待办、未分类和用户分类
struct TDTaskListView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    
    let category: TDSliderBarModel
    // 状态变量：控制复制成功Toast的显示
    @State private var showCopySuccessToast = false
    // 监听多选模式状态变化
    @ObservedObject private var mainViewModel = TDMainViewModel.shared

    // MARK: - 分组ID（直接使用枚举的rawValue）
    // 过期已达成=0, 过期未达成=1, 今天=2, 明天=3, 后天=4, 后续日程=5, 无日期=6
    
    // 为每个分组定义单独的 @Query，分别查询各个分组的任务数据
    @Query private var overdueCompletedTasks: [TDMacSwiftDataListModel]  // 过期已完成任务
    @Query private var overdueUncompletedTasks: [TDMacSwiftDataListModel]  // 过期未完成任务
    @Query private var todayTasks: [TDMacSwiftDataListModel]  // 今天任务
    @Query private var tomorrowTasks: [TDMacSwiftDataListModel]  // 明天任务
    @Query private var dayAfterTomorrowTasks: [TDMacSwiftDataListModel]  // 后天任务
    @Query private var futureScheduleTasks: [TDMacSwiftDataListModel]  // 后续日程任务
    @Query private var noDateTasks: [TDMacSwiftDataListModel]  // 无日期任务
    
    // 分组展开状态管理
    @State private var expandedGroups: Set<Int> = Self.getDefaultExpandedGroups()
    @State private var hoveredGroups: Set<Int> = []
    
    init(category: TDSliderBarModel) {
        self.category = category
        
        // 根据分类ID初始化查询条件
        let categoryId = category.categoryId
        
        // 初始化各个分组的查询条件
        let (overdueCompletedPredicate, overdueCompletedSort) = TDCorrectQueryBuilder.getExpiredCompletedQuery(categoryId: categoryId)
        let (overdueUncompletedPredicate, overdueUncompletedSort) = TDCorrectQueryBuilder.getExpiredUncompletedQuery(categoryId: categoryId)
        let (todayPredicate, todaySort) = TDCorrectQueryBuilder.getTodayQuery(categoryId: categoryId)
        let (tomorrowPredicate, tomorrowSort) = TDCorrectQueryBuilder.getTomorrowQuery(categoryId: categoryId)
        let (dayAfterTomorrowPredicate, dayAfterTomorrowSort) = TDCorrectQueryBuilder.getDayAfterTomorrowQuery(categoryId: categoryId)
        let (futureSchedulePredicate, futureScheduleSort) = TDCorrectQueryBuilder.getFutureScheduleQuery(categoryId: categoryId)
        let (noDatePredicate, noDateSort) = TDCorrectQueryBuilder.getNoDateQuery(categoryId: categoryId)
        
        // 初始化各个 @Query，分别查询各个分组的任务数据
        _overdueCompletedTasks = Query(filter: overdueCompletedPredicate, sort: overdueCompletedSort)
        _overdueUncompletedTasks = Query(filter: overdueUncompletedPredicate, sort: overdueUncompletedSort)
        _todayTasks = Query(filter: todayPredicate, sort: todaySort)
        _tomorrowTasks = Query(filter: tomorrowPredicate, sort: tomorrowSort)
        _dayAfterTomorrowTasks = Query(filter: dayAfterTomorrowPredicate, sort: dayAfterTomorrowSort)
        _futureScheduleTasks = Query(filter: futureSchedulePredicate, sort: futureScheduleSort)
        _noDateTasks = Query(filter: noDatePredicate, sort: noDateSort)
    }
    
    // MARK: - 静态方法
    
    /// 获取默认展开状态的分组ID集合
    /// 过期已达成默认关闭，其他分组默认展开
    private static func getDefaultExpandedGroups() -> Set<Int> {
        // 直接使用枚举的rawValue，简单直接
        return [1, 2, 3, 4, 5, 6] // 过期未达成=1, 今天=2, 明天=3, 后天=4, 后续日程=5, 无日期=6
        // 注意：0（过期已达成）不包含在内，所以默认是关闭的
    }
    
    // MARK: - 计算属性
    
    /// 获取当前分类的所有任务（用于多选功能）
    private var allTasks: [TDMacSwiftDataListModel] {
        return overdueCompletedTasks + overdueUncompletedTasks + todayTasks + tomorrowTasks + dayAfterTomorrowTasks + futureScheduleTasks + noDateTasks
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 任务输入框
            TDTaskInputView()
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            
            // 任务分组列表
            if allTasks.isEmpty {
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
                        if shouldShowOverdueCompletedGroup {
                            overdueCompletedGroup
                        }
                        // 过期未达成组
                        if shouldShowOverdueUncompletedGroup {
                            overdueUncompletedGroup
                        }
                        // 今天组
                        if !todayTasks.isEmpty {
                            todayGroup
                        }
                        // 明天组
                        if !tomorrowTasks.isEmpty {
                            tomorrowGroup
                        }
                        // 后天组
                        if !dayAfterTomorrowTasks.isEmpty {
                            dayAfterTomorrowGroup
                        }
                        // 后续日程组
                        if !futureScheduleTasks.isEmpty {
                            futureScheduleGroup
                        }
                        // 无日期组
                        if shouldShowNoDateGroup {
                            noDateGroup
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
                    VStack {
                        Spacer()
                        TDMultiSelectActionBar(allTasks: allTasks)
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
    
    // MARK: - 分组显示条件
    
    /// 是否显示过期已达成组
    private var shouldShowOverdueCompletedGroup: Bool {
        let settingManager = TDSettingManager.shared
        return settingManager.expiredRangeCompleted != .hide && !overdueCompletedTasks.isEmpty
    }
    
    /// 是否显示过期未达成组
    private var shouldShowOverdueUncompletedGroup: Bool {
        let settingManager = TDSettingManager.shared
        return settingManager.expiredRangeUncompleted != .hide && !overdueUncompletedTasks.isEmpty
    }
    
    /// 是否显示无日期组
    private var shouldShowNoDateGroup: Bool {
        let settingManager = TDSettingManager.shared
        return settingManager.showNoDateEvents && !noDateTasks.isEmpty
    }
    
    // MARK: - 分组视图
    
    /// 过期已达成组
    private var overdueCompletedGroup: some View {
        taskGroupSection(
            type: .overdueCompleted,
            tasks: overdueCompletedTasks,
            title: "overdue_completed".localized,
            completedCount: overdueCompletedTasks.count,
            totalCount: overdueCompletedTasks.count
        )
    }
    
    /// 过期未达成组
    private var overdueUncompletedGroup: some View {
        taskGroupSection(
            type: .overdueUncompleted,
            tasks: overdueUncompletedTasks,
            title: "overdue_uncompleted".localized,
            completedCount: 0,
            totalCount: overdueUncompletedTasks.count
        )
    }
    
    /// 今天组
    private var todayGroup: some View {
        let completedCount = todayTasks.filter { $0.complete }.count
        return taskGroupSection(
            type: .today,
            tasks: todayTasks,
            title: "today".localized,
            completedCount: completedCount,
            totalCount: todayTasks.count
        )
    }
    
    /// 明天组
    private var tomorrowGroup: some View {
        let completedCount = tomorrowTasks.filter { $0.complete }.count
        return taskGroupSection(
            type: .tomorrow,
            tasks: tomorrowTasks,
            title: "tomorrow".localized,
            completedCount: completedCount,
            totalCount: tomorrowTasks.count
        )
    }
    
    /// 后天组
    private var dayAfterTomorrowGroup: some View {
        let completedCount = dayAfterTomorrowTasks.filter { $0.complete }.count
        return taskGroupSection(
            type: .dayAfterTomorrow,
            tasks: dayAfterTomorrowTasks,
            title: "day_after_tomorrow".localized,
            completedCount: completedCount,
            totalCount: dayAfterTomorrowTasks.count
        )
    }
    
    /// 后续日程组
    private var futureScheduleGroup: some View {
        let completedCount = futureScheduleTasks.filter { $0.complete }.count
        return taskGroupSection(
            type: .upcomingSchedule,
            tasks: futureScheduleTasks,
            title: "upcoming_schedule".localized,
            completedCount: completedCount,
            totalCount: futureScheduleTasks.count
        )
    }
    
    /// 无日期组
    private var noDateGroup: some View {
        let completedCount = noDateTasks.filter { $0.complete }.count
        return taskGroupSection(
            type: .noDate,
            tasks: noDateTasks,
            title: "no_date".localized,
            completedCount: completedCount,
            totalCount: noDateTasks.count
        )
    }
    
    /// 通用任务分组区域
    private func taskGroupSection(
        type: TDTaskGroupType,
        tasks: [TDMacSwiftDataListModel],
        title: String,
        completedCount: Int,
        totalCount: Int
    ) -> some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedGroups.contains(type.rawValue) },
                set: { isExpanded in
                    toggleGroupExpansion(for: type.rawValue)
                }
            ),
            content: {
                VStack(spacing: 0) {
                    ForEach(Array(tasks.enumerated()), id: \.element.taskId) { index, task in
                        TDTaskRowView(
                            task: task,
                            category: category,
                            orderNumber: nil,
                            isFirstRow: index == 0,
                            isLastRow: index == tasks.count - 1,
                            onCopySuccess: {
                                // 显示复制成功提示
                                showCopySuccessToast = true
                            },
                            onEnterMultiSelect: {
                                // 进入多选模式时的回调，可以在这里添加其他逻辑
                            }
                        )
                        .padding(.leading, 16)
                        .padding(.vertical, 4)
                    }
                }
            },
            label: {
                taskGroupHeaderView(
                    type: type,
                    title: title,
                    totalCount: totalCount
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleGroupExpansion(for: type.rawValue)
                }
            }
        )
    }
    
    /// 分组头部视图
    private func taskGroupHeaderView(
        type: TDTaskGroupType,
        title: String,
        totalCount: Int
    ) -> some View {
        HStack {
            // 分组标题
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(getTitleColor(for: type))
            
            Spacer()
            
            // 任务数量标签 - 只在有任务时才显示
            if totalCount > 0 {
                Text("\(totalCount)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeManager.descriptionTextColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.color(level: 1))
                    )
            }
            
            // 按钮组（鼠标悬停时显示）
            HStack(spacing: 4) {
                // 设置按钮（如果需要）
                if type.needsSettingsIcon {
                    Button(action: {
                        // TODO: 显示设置弹窗
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 重新安排按钮（如果需要）
                if type.needsRescheduleButton {
                    Button(action: {
                        // TODO: 重新安排所有过期任务
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .opacity(hoveredGroups.contains(type.rawValue) ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .frame(height: 36) // 固定高度36
        .background(getGroupHeaderBackgroundColor(for: type)) // 添加背景色
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.2)) {
                if isHovered {
                    hoveredGroups.insert(type.rawValue)
                } else {
                    hoveredGroups.remove(type.rawValue)
                }
            }
        }
    }
    
    // MARK: - 颜色获取方法
    
    /// 根据分组类型获取标题颜色
    private func getTitleColor(for groupType: TDTaskGroupType) -> Color {
        switch groupType.titleColorType {
        case .descriptionColor:
            return themeManager.descriptionTextColor
        case .themeLevel6:
            return themeManager.color(level: 6)
        case .fixedNewYearRed:
            return themeManager.fixedColor(themeId: "new_year_red", level: 6)
        }
    }
    
    /// 切换分组展开状态（性能优化版本）
    private func toggleGroupExpansion(for groupId: Int) {
        // 减少动画时长，提升性能
        withAnimation(.easeInOut(duration: 0.1)) {
            if expandedGroups.contains(groupId) {
                expandedGroups.remove(groupId)
            } else {
                expandedGroups.insert(groupId)
            }
        }
    }
    
    /// 根据分组类型获取组头背景色
    private func getGroupHeaderBackgroundColor(for groupType: TDTaskGroupType) -> Color {
        switch groupType {
        case .overdueCompleted, .noDate:
            // 过期已达成和无日期：使用主题背景色1级
            return themeManager.color(level: 1)
        case .overdueUncompleted:
            // 过期未达成：使用新年红2级
            return themeManager.fixedColor(themeId: "new_year_red", level: 2)
        case .today, .tomorrow, .dayAfterTomorrow, .upcomingSchedule:
            // 今天、明天、后天、后续日程：使用主题色2级
            return themeManager.color(level: 2)
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

//
//  TDTaskListView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

//import SwiftUI
//import SwiftData
//import Foundation
//
//
///// 自定义 DisclosureGroup 样式
////struct CustomDisclosureGroupStyle: DisclosureGroupStyle {
////    func makeBody(configuration: Configuration) -> some View {
////        VStack(alignment: .leading, spacing: 0) {
////            configuration.label
////            if configuration.isExpanded {
////                configuration.content
////                    .transition(.asymmetric(
////                        insertion: .opacity.combined(with: .move(edge: .top)).animation(.easeOut(duration: 0.15)),
////                        removal: .opacity.combined(with: .move(edge: .bottom)).animation(.easeIn(duration: 0.15))
////                    ))
////            }
////        }
////        .animation(.easeInOut(duration: 0.15), value: configuration.isExpanded)
////    }
////}
//
//struct CustomDisclosureGroupStyle: DisclosureGroupStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        VStack {
//            // 自定义标签，不显示系统箭头
//            configuration.label
//            if configuration.isExpanded {
//                configuration.content
//            }
//        }
//    }
//}
//
///// 任务列表界面 - 用于最近待办、未分类和用户分类
//struct TDTaskListView: View {
//    @Environment(\.modelContext) private var modelContext
//    
//    let category: TDSliderBarModel
//    // 状态变量：控制复制成功Toast的显示
//    @State private var showCopySuccessToast = false
//    // 监听多选模式状态变化
//    @ObservedObject private var mainViewModel = TDMainViewModel.shared
//    
//    // 分组展开状态管理
//    @State private var expandedGroups: Set<String> = ["今天"]
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
//    init(category: TDSliderBarModel) {
//        self.category = category
//        
//        // 根据分类ID初始化查询条件
//        let categoryId = category.categoryId
//        
//        // 初始化各个分组的查询条件
//        let (overdueCompletedPredicate, overdueCompletedSort) = TDCorrectQueryBuilder.getExpiredCompletedQuery(categoryId: categoryId)
//        let (overdueUncompletedPredicate, overdueUncompletedSort) = TDCorrectQueryBuilder.getExpiredUncompletedQuery(categoryId: categoryId)
//        let (todayPredicate, todaySort) = TDCorrectQueryBuilder.getTodayQuery(categoryId: categoryId)
//        let (tomorrowPredicate, tomorrowSort) = TDCorrectQueryBuilder.getTomorrowQuery(categoryId: categoryId)
//        let (dayAfterTomorrowPredicate, dayAfterTomorrowSort) = TDCorrectQueryBuilder.getDayAfterTomorrowQuery(categoryId: categoryId)
//        let (futureSchedulePredicate, futureScheduleSort) = TDCorrectQueryBuilder.getFutureScheduleQuery(categoryId: categoryId)
//        let (noDatePredicate, noDateSort) = TDCorrectQueryBuilder.getNoDateQuery(categoryId: categoryId)
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
//    var body: some View {
//        List {
//                // 测试分组1 - 今天
//                DisclosureGroup(
//                    isExpanded: Binding(
//                        get: { expandedGroups.contains("今天") },
//                        set: { isExpanded in
//                            toggleGroupExpansion(for: "今天")
//                        }
//                    ),
//                    content: {
//                        ForEach(["完成项目文档", "参加团队会议", "回复客户邮件"], id: \.self) { taskTitle in
//                            HStack {
//                                Text(taskTitle)
//                                    .font(.system(size: 14))
//                                Spacer()
//                                Text("今天")
//                                    .font(.system(size: 12))
//                                    .foregroundColor(.secondary)
//                            }
//                            .padding(.horizontal, 16)
//                            .padding(.vertical, 8)
//                            .background(Color.gray)
//                            .cornerRadius(8)
//                        }
//                    },
//                    label: {
//                        HStack {
//                            Text("今天")
//                                .font(.system(size: 14, weight: .medium))
//                            Spacer()
//                            Text("3")
//                                .font(.system(size: 11, weight: .medium))
//                                .foregroundColor(.secondary)
//                                .padding(.horizontal, 6)
//                                .padding(.vertical, 2)
//                                .background(
//                                    RoundedRectangle(cornerRadius: 8)
//                                        .fill(Color.gray)
//                                )
//                        }
//                        .padding(.horizontal, 16)
//                        .frame(height: 36)
//                        .background(Color.blue)
//                        .contentShape(Rectangle())
//                        .onTapGesture {
//                            toggleGroupExpansion(for: "今天")
//                        }
//                    }
//                )
////                .disclosureGroupStyle(CustomDisclosureGroupStyle())
//                .overlay(
//                                    // 用透明视图覆盖系统箭头，保持系统动画
//                                    HStack {
//                                        Spacer()
//                                        Color.clear
//                                            .frame(width: 20, height: 20)
//                                    }
//                                )
//                // 测试分组2 - 明天
//                DisclosureGroup(
//                    isExpanded: Binding(
//                        get: { expandedGroups.contains("明天") },
//                        set: { isExpanded in
//                            toggleGroupExpansion(for: "明天")
//                        }
//                    ),
//                    content: {
//                        ForEach(101...200, id: \.self) { index in
//                            TaskRowView1(
//                                title: "任务 \(index)",
//                                subtitle: "明天",
//                                index: index
//                            )
//                        }
//                    },
//                    label: {
//                        HStack {
//                            Text("明天")
//                                .font(.system(size: 14, weight: .medium))
//                            Spacer()
//                            Text("2")
//                                .font(.system(size: 11, weight: .medium))
//                                .foregroundColor(.secondary)
//                                .padding(.horizontal, 6)
//                                .padding(.vertical, 2)
//                                .background(
//                                    RoundedRectangle(cornerRadius: 8)
//                                        .fill(Color.gray)
//                                )
//                        }
//                        .padding(.horizontal, 16)
//                        .frame(height: 36)
//                        .background(Color.green)
//                        .contentShape(Rectangle())
//                        .onTapGesture {
//                            toggleGroupExpansion(for: "明天")
//                        }
//                    }
//                )
////                .disclosureGroupStyle(CustomDisclosureGroupStyle())
//        }
//        .listStyle(.sidebar)
//    }
//    
//    /// 切换分组展开状态
//    private func toggleGroupExpansion(for groupId: String) {
//        withAnimation(.easeInOut(duration: 0.2)) {
//            if expandedGroups.contains(groupId) {
//                expandedGroups.remove(groupId)
//            } else {
//                expandedGroups.insert(groupId)
//            }
//        }
//    }
//}
///// 优化的任务行视图 - 使用 Identifiable 和 Equatable 提升性能
//struct TaskRowView1: View, Identifiable, Equatable {
//    let id: Int
//    let title: String
//    let subtitle: String
//    
//    init(title: String, subtitle: String, index: Int) {
//        self.id = index
//        self.title = title
//        self.subtitle = subtitle
//    }
//    
//    var body: some View {
//        HStack {
//            Text(title)
//                .font(.system(size: 14))
//                .lineLimit(1)
//            Spacer()
//            Text(subtitle)
//                .font(.system(size: 12))
//                .foregroundColor(.secondary)
//        }
//        .padding(.horizontal, 16)
//        .padding(.vertical, 6)
//        .background(Color.gray)
//        .cornerRadius(6)
//    }
//    
////    // Equatable 实现 - 只有内容变化时才重新渲染
////    static func == (lhs: TaskRowView1, rhs: TaskRowView1) -> Bool {
////        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.subtitle == rhs.subtitle
////    }
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
//}
