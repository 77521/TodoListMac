////
////  TDTaskListView.swift
////  TodoMacRepertorie
////
////  Created by 孬孬 on 2024/12/29.
////
//
//import SwiftUI
//import SwiftData
//
/////// 任务列表视图，负责分组和渲染所有任务
////struct TDTaskListView: View {
////    @EnvironmentObject private var mainViewModel: TDMainViewModel
////    @EnvironmentObject private var themeManager: TDThemeManager
////    @EnvironmentObject private var settingManager: TDSettingManager
////
////    var body: some View {
////        let isDayTodo = mainViewModel.selectedCategory?.categoryId == -100
////        let sortedGroups = mainViewModel.groupedTasks.keys.sorted()
////
////        if isDayTodo {
////            dayTodoListView(sortedGroups: sortedGroups)
////        } else {
////            normalListView(sortedGroups: sortedGroups)
////        }
////    }
////
////    // MARK: - DayTodo 模式视图
////    @ViewBuilder
////    private func dayTodoListView(sortedGroups: [TDTaskGroup]) -> some View {
////        List {
////            ForEach(sortedGroups, id: \.rawValue) { group in
////                if let tasks = mainViewModel.groupedTasks[group], !tasks.isEmpty {
////                    taskRowsSection(tasks: tasks, showHeader: false)
////                }
////            }
////            topSpacerRow()
////        }
////        .listStyle(.plain)
////        .background(Color(.windowBackgroundColor))
////    }
////
////    // MARK: - 普通模式视图
////    @ViewBuilder
////    private func normalListView(sortedGroups: [TDTaskGroup]) -> some View {
////        List {
////            ForEach(sortedGroups, id: \.rawValue) { group in
////                if let tasks = mainViewModel.groupedTasks[group], !tasks.isEmpty {
////                    Section {
////                        taskRowsSection(tasks: tasks, showHeader: true)
////                    } header: {
////                        TDTaskGroupHeader(group: group, taskCount: tasks.count)
////                            .frame(height: 36)
////                    }
////                }
////            }
////        }
////        .listStyle(.sidebar)
////        .scrollContentBackground(.hidden)
////    }
////
////    // MARK: - 任务行区域
////    @ViewBuilder
////    private func taskRowsSection(tasks: [TDMacSwiftDataListModel], showHeader: Bool) -> some View {
////        ForEach(tasks, id: \.taskId) { task in
////            TDTaskRow(task: task)
////                .listRowInsets(showHeader ? EdgeInsets() : EdgeInsets())
////                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
////                    deleteButton(for: task)
////                }
////                .contextMenu {
////                    deleteContextMenu(for: task)
////                }
////        }
////        .onMove { from, to in
////            handleTaskMove(from: from, to: to, in: tasks)
////        }
////    }
////
////    // MARK: - 删除按钮
////    @ViewBuilder
////    private func deleteButton(for task: TDMacSwiftDataListModel) -> some View {
////        Button(role: .destructive) {
////            deleteTask(task)
////        } label: {
////            Label("删除", systemImage: "trash")
////        }
////    }
////
////    // MARK: - 删除上下文菜单
////    @ViewBuilder
////    private func deleteContextMenu(for task: TDMacSwiftDataListModel) -> some View {
////        Button(action: {
////            deleteTask(task)
////        }) {
////            Label("删除", systemImage: "trash")
////                .foregroundColor(.red)
////        }
////    }
////
////    // MARK: - 顶部空白行
////    @ViewBuilder
////    private func topSpacerRow() -> some View {
////        Color.clear
////            .frame(height: 80)
////            .listRowInsets(EdgeInsets())
////    }
////
////    // MARK: - 删除任务操作
////    private func deleteTask(_ task: TDMacSwiftDataListModel) {
////        Task {
////            await performDeleteTask(task)
////        }
////    }
////
////    // MARK: - 异步删除任务
////    @MainActor
////    private func performDeleteTask(_ task: TDMacSwiftDataListModel) async {
////        do {
////            // 标记为删除
////            task.delete = true
////            task.status = "update"
////
////            // 异步更新数据库
////            try await TDQueryConditionManager.shared.updateLocalTaskFields([task])
////
////            // 刷新界面
////            try await mainViewModel.refreshTasks()
////
////            // 同步到服务器
////            try? await mainViewModel.syncAfterLogin()
////        } catch {
////            print("删除任务失败: \(error)")
////        }
////    }
////
////    // MARK: - 处理任务移动
////    private func handleTaskMove(from source: IndexSet, to destination: Int, in tasks: [TDMacSwiftDataListModel]) {
////        Task {
////            await performTaskMove(from: source, to: destination, in: tasks)
////        }
////    }
////
////    // MARK: - 异步处理任务移动
////    @MainActor
////    private func performTaskMove(from source: IndexSet, to destination: Int, in tasks: [TDMacSwiftDataListModel]) async {
////        // TODO: 实现任务重新排序逻辑
////        // 1. 重新计算 taskSort 值
////        // 2. 异步更新数据库
////        // 3. 刷新界面
////        print("任务移动: 从 \(source) 到 \(destination)")
////    }
////}
//
//
///// 任务列表视图，负责分组和渲染所有任务
///// 使用 @Query 属性包装器直接在 View 中查询数据
//struct TDTaskListView: View {
//    @EnvironmentObject private var mainViewModel: TDMainViewModel
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @EnvironmentObject private var settingManager: TDSettingManager
//    @Environment(\.modelContext) private var modelContext
//
//    // MARK: - 任务选择状态
//    @Binding var selectedTask: TDMacSwiftDataListModel?
//
//    // MARK: - @Query 属性包装器
//    @Query private var allTasks: [TDMacSwiftDataListModel]
//
//    // 根据当前选中的分类和设置查询任务
//    private var filteredTasks: [TDMacSwiftDataListModel] {
//        guard let selectedCategory = mainViewModel.selectedCategory else { return [] }
//
//        // 根据分类类型过滤任务
//        switch selectedCategory.categoryId {
//        case -100: // DayTodo - 查询今日任务
//            return queryTodayTasks()
//        default:
//            return [] // 其他分类暂时返回空数组
//        }
//    }
//
//    // 查询今日任务
//    private func queryTodayTasks() -> [TDMacSwiftDataListModel] {
//        let today = Date().startOfDayTimestamp
//        let userId = TDUserManager.shared.userId
//
//        // 构建查询条件
//        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
//            task.userId == userId &&
//            !task.delete &&
//            task.todoTime == today
//        }
//
//        // 根据设置决定是否显示已完成任务
//        if settingManager.showCompletedTasks {
//            // 显示已完成任务，已完成排在未完成后面
//            let completedPredicate = #Predicate<TDMacSwiftDataListModel> { task in
//                task.userId == userId &&
//                !task.delete &&
//                task.todoTime == today
//            }
//
//            return allTasks.filter { task in
//                task.userId == userId &&
//                !task.delete &&
//                task.todoTime == today
//            }.sorted { first, second in
//                // 先按完成状态排序（未完成在前）
//                if first.complete != second.complete {
//                    return !first.complete
//                }
//                // 再按 taskSort 排序
//                if settingManager.isTaskSortAscending {
//                    return first.taskSort < second.taskSort
//                } else {
//                    return first.taskSort > second.taskSort
//                }
//            }
//        } else {
//            // 不显示已完成任务，只查询未完成
//            return allTasks.filter { task in
//                task.userId == userId &&
//                !task.delete &&
//                task.todoTime == today &&
//                !task.complete
//            }.sorted { first, second in
//                if settingManager.isTaskSortAscending {
//                    return first.taskSort < second.taskSort
//                } else {
//                    return first.taskSort > second.taskSort
//                }
//            }
//        }
//    }
//
//    // MARK: - 初始化方法
//    init(selectedTask: Binding<TDMacSwiftDataListModel?>) {
//        // 初始化 selectedTask 绑定
//        self._selectedTask = selectedTask
//        // 初始化 @Query，查询所有任务
//        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
//            !task.delete // 只查询未删除的任务
//        }
//
//        let sortDescriptors = [
//            SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
//            SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
//        ]
//
//        _allTasks = Query(
//            filter: predicate,
//            sort: sortDescriptors
//        )
//    }
//
//    var body: some View {
//        let isDayTodo = mainViewModel.selectedCategory?.categoryId == -100
//        let sortedGroups = groupTasks(filteredTasks)
//
//        if isDayTodo {
//            dayTodoListView(sortedGroups: sortedGroups)
//        } else {
//            normalListView(sortedGroups: sortedGroups)
//        }
//    }
//
//    // MARK: - 任务分组
//    private func groupTasks(_ tasks: [TDMacSwiftDataListModel]) -> [TDTaskGroup: [TDMacSwiftDataListModel]] {
//        var grouped: [TDTaskGroup: [TDMacSwiftDataListModel]] = [:]
//
//        for task in tasks {
//            let group = TDTaskGroup.fromTask(task)
//            if grouped[group] == nil {
//                grouped[group] = []
//            }
//            grouped[group]?.append(task)
//        }
//
//        return grouped
//    }
//
//    // MARK: - DayTodo 模式视图 - 使用优化的 List
//    @ViewBuilder
//    private func dayTodoListView(sortedGroups: [TDTaskGroup: [TDMacSwiftDataListModel]]) -> some View {
//        List {
//            ForEach(Array(sortedGroups.keys.sorted()), id: \.rawValue) { group in
//                if let tasks = sortedGroups[group], !tasks.isEmpty {
//                    Section {
//                        ForEach(tasks, id: \.taskId) { task in
//                            TDTaskRow(task: task, selectedTask: $selectedTask)
//                                .listRowInsets(EdgeInsets())
//                                .listRowBackground(themeManager.backgroundColor)
//                                .listRowSeparator(.hidden)
//                                .contextMenu {
//                                    deleteContextMenu(for: task)
//                                }
//                        }
//                    }
//                }
//            }
//            topSpacerRow()
//        }
//        .listStyle(.plain)
//        .background(Color(.windowBackgroundColor))
//        // 性能优化配置
//        .environment(\.defaultMinListRowHeight, 44)
//        .environment(\.defaultMinListHeaderHeight, 36)
//    }
//
//    // MARK: - 普通模式视图 - 使用优化的 List
//    @ViewBuilder
//    private func normalListView(sortedGroups: [TDTaskGroup: [TDMacSwiftDataListModel]]) -> some View {
//        List {
//            ForEach(Array(sortedGroups.keys.sorted()), id: \.rawValue) { group in
//                if let tasks = sortedGroups[group], !tasks.isEmpty {
//                    Section {
//                        ForEach(tasks, id: \.taskId) { task in
//                            TDTaskRow(task: task, selectedTask: $selectedTask)
//                                .listRowInsets(EdgeInsets())
//                                .listRowBackground(themeManager.backgroundColor)
//                                .listRowSeparator(.hidden)
//                                .contextMenu {
//                                    deleteContextMenu(for: task)
//                                }
//                        }
//                    } header: {
//                        TDTaskGroupHeader(group: group, taskCount: tasks.count)
//                            .frame(height: 36)
//                    }
//                }
//            }
//        }
//        .listStyle(.sidebar)
//        .scrollContentBackground(.hidden)
//        // 性能优化配置
//        .environment(\.defaultMinListRowHeight, 44)
//        .environment(\.defaultMinListHeaderHeight, 36)
//    }
//
//    // MARK: - 删除上下文菜单
//    @ViewBuilder
//    private func deleteContextMenu(for task: TDMacSwiftDataListModel) -> some View {
//        Button(action: {
//            deleteTask(task)
//        }) {
//            Label("删除", systemImage: "trash")
//                .foregroundColor(.red)
//        }
//    }
//
//    // MARK: - 顶部空白行
//    @ViewBuilder
//    private func topSpacerRow() -> some View {
//        Rectangle()
//            .fill(Color.clear)
//            .frame(height: 100)
//            .listRowBackground(Color.clear)
//    }
//
//    // MARK: - 删除任务
//    private func deleteTask(_ task: TDMacSwiftDataListModel) {
//        task.delete = true
//        task.status = "update"
//
//        do {
//            try modelContext.save()
//        } catch {
//            print("删除任务失败: \(error)")
//        }
//    }
//}
//
//
//
//
/////// 任务列表视图，负责分组和渲染所有任务
////struct TDTaskListView: View {
////    @EnvironmentObject private var mainViewModel: TDMainViewModel
////    @EnvironmentObject private var themeManager: TDThemeManager
////    @EnvironmentObject private var settingManager: TDSettingManager
////
////    var body: some View {
////        let isDayTodo = mainViewModel.selectedCategory?.categoryId == -100
////
////        if isDayTodo {
////            // DayTodo模式：无组头
////            List {
////                ForEach(mainViewModel.groupedTasks.keys.sorted(), id: \.rawValue) { group in
////                    if let tasks = mainViewModel.groupedTasks[group], !tasks.isEmpty {
////                        ForEach(tasks, id: \.taskId) { task in
////                            TDTaskRow(task: task)
////                                .listRowInsets(EdgeInsets())
////                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
////                                    Button(role: .destructive) {
////                                        Task {
////                                            task.delete = true
////                                            try? await TDModelContainer.shared.perform {
////                                                try TDModelContainer.shared.save()
////                                            }
////                                            await mainViewModel.refreshTasks()
////                                        }
////                                    } label: {
////                                        Label("删除", systemImage: "trash")
////                                    }
////                                }
////                                .contextMenu {
////                                    Button(action: {
////                                        Task {
////                                            task.delete = true
////                                            try? await TDModelContainer.shared.perform {
////                                                try TDModelContainer.shared.save()
////                                            }
////                                            await mainViewModel.refreshTasks()
////                                        }
////                                    }) {
////                                        Label("删除", systemImage: "trash")
////                                            .foregroundColor(.red)
////                                    }
////                                }
////                        }
////                        .onMove { from, to in
////                            // TODO: 处理任务重新排序
////                        }
////                    }
////                }
////                // 顶部空白
////                Color.clear
////                    .frame(height: 80)
////                    .listRowInsets(EdgeInsets())
////            }
////            .listStyle(.plain)
////            .background(Color(.windowBackgroundColor))
////        } else {
////            // 普通模式：有组头
////            List {
////                ForEach(mainViewModel.groupedTasks.keys.sorted(), id: \.rawValue) { group in
////                    if let tasks = mainViewModel.groupedTasks[group], !tasks.isEmpty {
////                        Section {
////                            ForEach(tasks, id: \.taskId) { task in
////                                TDTaskRow(task: task)
////                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
////                                        Button(role: .destructive) {
////                                            Task {
////                                                task.delete = true
////                                                try? await TDModelContainer.shared.perform {
////                                                    try TDModelContainer.shared.save()
////                                                }
////                                                await mainViewModel.refreshTasks()
////                                            }
////                                        } label: {
////                                            Label("删除", systemImage: "trash")
////                                        }
////                                    }
////                                    .contextMenu {
////                                        Button(action: {
////                                            Task {
////                                                task.delete = true
////                                                try? await TDModelContainer.shared.perform {
////                                                    try TDModelContainer.shared.save()
////                                                }
////                                                await mainViewModel.refreshTasks()
////                                            }
////                                        }) {
////                                            Label("删除", systemImage: "trash")
////                                                .foregroundColor(.red)
////                                        }
////                                    }
////                            }
////                            .onMove { from, to in
////                                // TODO: 处理任务重新排序
////                            }
////                        } header: {
////                            TDTaskGroupHeader(group: group, taskCount: tasks.count)
////                                .frame(height: 36)
////                        }
////                    }
////                }
////            }
////            .listStyle(.sidebar)
////            .scrollContentBackground(.hidden)
////        }
////    }
////}
////struct TDTaskListView: View {
////    @StateObject private var mainViewModel = TDMainViewModel.shared
////    @StateObject private var themeManager = TDThemeManager.shared
////
////    var body: some View {
////        List {
////            ForEach(mainViewModel.groupedTasks.keys.sorted(), id: \.rawValue) { group in
////                if let tasks = mainViewModel.groupedTasks[group], !tasks.isEmpty {
////                    Section {
////                        ForEach(tasks, id: \.taskId) { task in
////                            TDTaskRow(task: task)
////                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
////                                    Button(role: .destructive) {
////                                        Task {
////                                            // 删除任务
////                                            task.delete = true
////                                            try? await TDModelContainer.shared.perform {
////                                                try TDModelContainer.shared.save()
////                                            }
////                                            await mainViewModel.refreshTasks()
////                                        }
////                                    } label: {
////                                        Label("删除", systemImage: "trash")
////                                    }
////                                }
////                                .contextMenu {
////                                    Button(action: {
////                                        Task {
////                                            // 删除任务
////                                            task.delete = true
////                                            try? await TDModelContainer.shared.perform {
////                                                try TDModelContainer.shared.save()
////                                            }
////                                            await mainViewModel.refreshTasks()
////                                        }
////                                    }) {
////                                        Label("删除", systemImage: "trash")
////                                            .foregroundColor(.red)
////                                    }
////                                }
////                        }
////                        .onMove { from, to in
////                            // TODO: 处理任务重新排序
////                            // 需要更新 taskSort 字段并保存
////                        }
////                    } header: {
////                        if mainViewModel.selectedCategory?.categoryId == -100 {
////                            // DayTodo 模式下显示空的组头，但保持一定高度
////                            Color.clear
////                                .frame(height: 0)
////                                .listRowBackground(Color.clear)
////                        } else {
////                            TDTaskGroupHeader(group: group, taskCount: tasks.count)
////                        }
////                    }
////                }
////            }
////        }
////        .listStyle(.inset)
////        .scrollContentBackground(.hidden)
//////        .background(.ultraThinMaterial)
////    }
////}
////
////// 任务组区域视图
////struct TDTaskGroupSection: View {
////    let group: TDMacTaskGroup
////    let tasks: [TDMacSwiftDataListModel]
////
////    var body: some View {
////        VStack(alignment: .leading, spacing: 8) {
////            // 组标题
////            Text(group.title)
////                .font(.headline)
////                .foregroundColor(.secondary)
////
////            // 任务列表
////            ForEach(tasks) { task in
////                TDTaskRow(task: task)
////            }
////        }
////    }
////}
////
////// 单个任务行视图
////struct TDTaskRow: View {
////    let task: TDMacSwiftDataListModel
////
////    var body: some View {
////        HStack {
////            // 完成状态复选框
////            Image(systemName: task.complete ? "checkmark.circle.fill" : "circle")
////                .foregroundColor(task.complete ? .green : .gray)
////
////            // 任务内容
////            VStack(alignment: .leading) {
////                Text(task.taskContent ?? "")
////                    .strikethrough(task.complete)
////
////                if let describe = task.taskDescribe, !describe.isEmpty {
////                    Text(describe)
////                        .font(.caption)
////                        .foregroundColor(.secondary)
////                }
////            }
////
////            Spacer()
////
////            // 如果有日期，显示日期
////            if let todoTime = task.todoTime {
////                Text(todoTime.toDate.formattedString)
////                    .font(.caption)
////                    .foregroundColor(.secondary)
////            }
////        }
////        .padding()
////        .background(Color.red)
////        .cornerRadius(8)
////        .shadow(radius: 1)
////    }
////}
////
////#Preview {
////    let config = ModelConfiguration(isStoredInMemoryOnly: true)
////    let container = try! ModelContainer(for: TDMacSwiftDataListModel.self, configurations: config)
////
////    TDTaskListView(modelContext: container.mainContext, selectedCategory: .constant(TDSliderBarModel()))
////}


//
//  TDTaskListView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

//import SwiftUI
//import SwiftData
//
///// 任务列表界面 - 用于最近待办、未分类和用户分类
//struct TDTaskListView: View {
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @Environment(\.modelContext) private var modelContext
//
//    let category: TDSliderBarModel
//
//    // MARK: - 静态UUID缓存（避免重复计算）
//    private static let groupIdCache: [TDTaskGroupType: UUID] = {
//        var cache: [TDTaskGroupType: UUID] = [:]
//        for groupType in TDTaskGroupType.allCases {
//            let uuidString = String(format: "00000000-0000-0000-0000-%012d", groupType.rawValue)
//            cache[groupType] = UUID(uuidString: uuidString) ?? UUID()
//        }
//        return cache
//    }()
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
//    @State private var expandedGroups: Set<UUID> = Self.getDefaultExpandedGroups()
//    @State private var hoveredGroups: Set<UUID> = []
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
//
//        // 设置默认展开状态：过期已达成默认关闭，其他分组默认展开
//        // 注意：这里不需要额外设置，因为 expandedGroups 已经在声明时初始化了
//    }
//
//    // MARK: - 静态方法
//
//    /// 获取默认展开状态的分组ID集合
//    /// 过期已达成默认关闭，其他分组默认展开
//    private static func getDefaultExpandedGroups() -> Set<UUID> {
//        var defaultExpandedGroups: Set<UUID> = []
//
//        // 添加默认展开的分组（除了过期已达成）
//        defaultExpandedGroups.insert(groupIdCache[.overdueUncompleted]!)
//        defaultExpandedGroups.insert(groupIdCache[.today]!)
//        defaultExpandedGroups.insert(groupIdCache[.tomorrow]!)
//        defaultExpandedGroups.insert(groupIdCache[.dayAfterTomorrow]!)
//        defaultExpandedGroups.insert(groupIdCache[.upcomingSchedule]!)
//        defaultExpandedGroups.insert(groupIdCache[.noDate]!)
//
//        // 注意：.overdueCompleted 不添加到默认展开集合中，所以默认是关闭的
//
//        return defaultExpandedGroups
//    }
//
//    // MARK: - 计算属性
//
//    /// 基于各个查询结果创建任务分组数组（性能优化版本）
//    ///
//    /// 调用机制说明：
//    /// 1. 当 View 的 body 被访问时，SwiftUI 会自动调用这个计算属性
//    /// 2. 每次访问都会重新计算，确保数据是最新的
//    /// 3. 当 @Query 查询结果发生变化时，SwiftUI 会自动重新渲染 View
//    /// 4. 重新渲染时会再次调用这个计算属性，获取最新的分组数据
//    /// 5. 这样就实现了响应式的数据更新，无需手动刷新
//    private var taskGroups: [TDTaskGroupModel] {
//        // 步骤1：初始化分组数组，用于存储所有要显示的分组
//        var groups: [TDTaskGroupModel] = []
//
//        // 步骤2：获取设置管理器，用于读取用户的分组显示设置
//        let settingManager = TDSettingManager.shared
//
//        // 步骤3：使用缓存的UUID，避免重复计算
//        func getGroupId(for type: TDTaskGroupType) -> UUID {
//            return Self.groupIdCache[type] ?? UUID()
//        }
//
//        // 步骤4.1：创建过期已达成分组
//        // 条件：设置中未设置为隐藏，且确实有过期已完成的任务
//        if settingManager.expiredRangeCompleted != .hide && !overdueCompletedTasks.isEmpty {
//            let groupId = getGroupId(for: .overdueCompleted)
//            // 创建分组模型，包含任务数量、完成状态、展开状态等信息
//            let group = TDTaskGroupModel(
//                type: .overdueCompleted,
//                taskCount: overdueCompletedTasks.count,        // 任务总数
//                completedCount: overdueCompletedTasks.count,   // 完成数量（过期已完成的都是已完成）
//                totalCount: overdueCompletedTasks.count,       // 总数量
//                isExpanded: expandedGroups.contains(groupId),  // 是否展开
//                isHovered: hoveredGroups.contains(groupId),    // 是否悬停
//                tasks: overdueCompletedTasks,                  // 将查询到的任务数组赋值给分组
//                id: groupId                                    // 使用固定的UUID
//            )
//            groups.append(group)  // 将分组添加到数组中
//        }
//
//        // 步骤4.2：创建过期未达成分组
//        // 条件：设置中未设置为隐藏，且确实有过期未完成的任务
//        if settingManager.expiredRangeUncompleted != .hide && !overdueUncompletedTasks.isEmpty {
//            let groupId = getGroupId(for: .overdueUncompleted)
//            // 创建分组模型
//            let group = TDTaskGroupModel(
//                type: .overdueUncompleted,
//                taskCount: overdueUncompletedTasks.count,      // 任务总数
//                completedCount: 0,                             // 完成数量（过期未完成的都是未完成）
//                totalCount: overdueUncompletedTasks.count,     // 总数量
//                isExpanded: expandedGroups.contains(groupId),  // 是否展开
//                isHovered: hoveredGroups.contains(groupId),    // 是否悬停
//                tasks: overdueUncompletedTasks,                // 将查询到的任务数组赋值给分组
//                id: groupId                                    // 使用固定的UUID
//            )
//            groups.append(group)  // 将分组添加到数组中
//        }
//
//        // 步骤4.3：创建今天分组
//        // 条件：只有今天确实有任务才显示
//        if !todayTasks.isEmpty {
//            let groupId = getGroupId(for: .today)
//            // 计算已完成任务的数量
//            let completedCount = todayTasks.filter { $0.complete }.count
//            // 创建分组模型
//            let group = TDTaskGroupModel(
//                type: .today,
//                taskCount: todayTasks.count,                   // 任务总数
//                completedCount: completedCount,                // 已完成数量
//                totalCount: todayTasks.count,                  // 总数量
//                isExpanded: expandedGroups.contains(groupId),  // 是否展开
//                isHovered: hoveredGroups.contains(groupId),    // 是否悬停
//                tasks: todayTasks,                             // 将查询到的任务数组赋值给分组
//                id: groupId                                    // 使用固定的UUID
//            )
//            groups.append(group)  // 将分组添加到数组中
//        }
//
//        // 步骤4.4：创建明天分组
//        // 条件：只有明天确实有任务才显示
//        if !tomorrowTasks.isEmpty {
//            let groupId = getGroupId(for: .tomorrow)
//            let completedCount = tomorrowTasks.filter { $0.complete }.count
//            let group = TDTaskGroupModel(
//                type: .tomorrow,
//                taskCount: tomorrowTasks.count,                 // 任务总数
//                completedCount: completedCount,                // 已完成数量
//                totalCount: tomorrowTasks.count,               // 总数量
//                isExpanded: expandedGroups.contains(groupId),  // 是否展开
//                isHovered: hoveredGroups.contains(groupId),    // 是否悬停
//                tasks: tomorrowTasks,                          // 将查询到的任务数组赋值给分组
//                id: groupId                                    // 使用固定的UUID
//            )
//            groups.append(group)  // 将分组添加到数组中
//        }
//
//        // 步骤4.5：创建后天分组
//        // 条件：只有后天确实有任务才显示
//        if !dayAfterTomorrowTasks.isEmpty {
//            let groupId = getGroupId(for: .dayAfterTomorrow)
//            let completedCount = dayAfterTomorrowTasks.filter { $0.complete }.count
//            let group = TDTaskGroupModel(
//                type: .dayAfterTomorrow,
//                taskCount: dayAfterTomorrowTasks.count,         // 任务总数
//                completedCount: completedCount,                // 已完成数量
//                totalCount: dayAfterTomorrowTasks.count,       // 总数量
//                isExpanded: expandedGroups.contains(groupId),  // 是否展开
//                isHovered: hoveredGroups.contains(groupId),    // 是否悬停
//                tasks: dayAfterTomorrowTasks,                  // 将查询到的任务数组赋值给分组
//                id: groupId                                    // 使用固定的UUID
//            )
//            groups.append(group)  // 将分组添加到数组中
//        }
//
//        // 步骤4.6：创建后续日程分组
//        // 条件：确实有后续日程任务（设置中的"全部"表示显示所有后续日程）
//        if !futureScheduleTasks.isEmpty {
//            let groupId = getGroupId(for: .upcomingSchedule)
//            let completedCount = futureScheduleTasks.filter { $0.complete }.count
//            let group = TDTaskGroupModel(
//                type: .upcomingSchedule,
//                taskCount: futureScheduleTasks.count,           // 任务总数
//                completedCount: completedCount,                // 已完成数量
//                totalCount: futureScheduleTasks.count,         // 总数量
//                isExpanded: expandedGroups.contains(groupId),  // 是否展开
//                isHovered: hoveredGroups.contains(groupId),    // 是否悬停
//                tasks: futureScheduleTasks,                    // 将查询到的任务数组赋值给分组
//                id: groupId                                    // 使用固定的UUID
//            )
//            groups.append(group)  // 将分组添加到数组中
//        }
//
//        // 步骤4.7：创建无日期分组
//        // 条件：设置中显示无日期事件，且确实有无日期任务
//        if settingManager.showNoDateEvents && !noDateTasks.isEmpty {
//            let groupId = getGroupId(for: .noDate)
//            let completedCount = noDateTasks.filter { $0.complete }.count
//            let group = TDTaskGroupModel(
//                type: .noDate,
//                taskCount: noDateTasks.count,                   // 任务总数
//                completedCount: completedCount,                // 已完成数量
//                totalCount: noDateTasks.count,                 // 总数量
//                isExpanded: expandedGroups.contains(groupId),  // 是否展开
//                isHovered: hoveredGroups.contains(groupId),    // 是否悬停
//                tasks: noDateTasks,                            // 将查询到的任务数组赋值给分组
//                id: groupId                                    // 使用固定的UUID
//            )
//            groups.append(group)  // 将分组添加到数组中
//        }
//
//        // 步骤5：按分组类型排序并返回最终结果
//        // 使用枚举的 rawValue 进行排序，确保分组显示顺序一致
//        return groups.sorted { $0.type < $1.type }
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
//            if taskGroups.isEmpty {
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
//                ScrollViewReader { proxy in
//                    List {
//                        ForEach(taskGroups) { group in
//                            taskGroupSection(for: group)
//                        }
//                    }
//                    .listStyle(.plain)
//                    .scrollContentBackground(.hidden)
//                    .background(Color.clear)
//                    // 性能优化配置
//                    .environment(\.defaultMinListRowHeight, 44)
//                    .environment(\.defaultMinListHeaderHeight, 36)
//                    // 禁用滚动指示器，提升性能
//                    .scrollIndicators(.hidden)
//                }
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color(.windowBackgroundColor))
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
//    private func toggleGroupExpansion(for groupId: UUID) {
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
//
//    // MARK: - 分组视图
//
//    /// 任务分组区域
//    private func taskGroupSection(for group: TDTaskGroupModel) -> some View {
//        DisclosureGroup(
//            isExpanded: Binding(
//                get: { expandedGroups.contains(group.id) },
//                set: { isExpanded in
//                    toggleGroupExpansion(for: group.id)
//                }
//            ),
//            content: {
//                VStack(spacing: 0) {
//                    ForEach(group.tasks, id: \.taskId) { task in
//                        TaskRowView(task: task, category: category)
//                            .padding(.leading, 16)
//                            .padding(.vertical, 4)
//                    }
//                }
//            },
//            label: {
//                taskGroupHeaderView(for: group)
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        toggleGroupExpansion(for: group.id)
//                    }
//            }
//        )
//        .listRowInsets(EdgeInsets())
//        .listRowBackground(Color.clear)
//        .listRowSeparator(.hidden)
//    }
//
//    /// 分组头部视图
//    private func taskGroupHeaderView(for group: TDTaskGroupModel) -> some View {
//        HStack {
//            // 分组标题
//            Text(group.title)
//                .font(.system(size: 14))
//                .foregroundColor(getTitleColor(for: group.type))
//
//            Spacer()
//
//            // 任务数量标签 - 只在有任务时才显示
//            if group.totalCount > 0 {
//                Text("\(group.totalCount)")
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
//                if group.type.needsSettingsIcon {
//                    Button(action: {
//                        // TODO: 显示设置弹窗
//                    }) {
//                        Image(systemName: "gearshape")
//                            .font(.system(size: 12))
//                            .foregroundColor(.secondary)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                }
//
//                // 重新安排按钮（如果需要）
//                if group.type.needsRescheduleButton {
//                    Button(action: {
//                        // TODO: 重新安排所有过期任务
//                    }) {
//                        Image(systemName: "arrow.clockwise")
//                            .font(.system(size: 12))
//                            .foregroundColor(.secondary)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                }
//            }
//            .opacity(hoveredGroups.contains(group.id) ? 1 : 0)
//        }
//        .padding(.horizontal, 16)
//        .frame(height: 36) // 固定高度36
//        .background(getGroupHeaderBackgroundColor(for: group.type)) // 添加背景色
//        .onHover { isHovered in
//            withAnimation(.easeInOut(duration: 0.2)) {
//                if isHovered {
//                    hoveredGroups.insert(group.id)
//                } else {
//                    hoveredGroups.remove(group.id)
//                }
//            }
//        }
//    }
//
//    // MARK: - 任务行视图
//
//    /// 任务行视图（性能优化版本）
//    private struct TaskRowView: View {
//        @EnvironmentObject private var themeManager: TDThemeManager
//
//        let task: TDMacSwiftDataListModel
//        let category: TDSliderBarModel
//
//        // 缓存颜色，避免重复计算
//        private var circleColor: Color {
//            themeManager.color(level: 5)
//        }
//
//        private var textColor: Color {
//            themeManager.titleTextColor
//        }
//
//        var body: some View {
//            HStack(spacing: 12) {
//                // 完成状态圆圈
//                Circle()
//                    .stroke(circleColor, lineWidth: 1.5)
//                    .frame(width: 20, height: 20)
//                    .overlay(
//                        Group {
//                            if task.complete {
//                                Image(systemName: "checkmark")
//                                    .font(.system(size: 12, weight: .bold))
//                                    .foregroundColor(circleColor)
//                            }
//                        }
//                    )
//
//                // 任务标题
//                Text(task.taskContent)
//                    .font(.system(size: 14))
//                    .foregroundColor(textColor)
//                    .strikethrough(task.complete)
//                    .opacity(task.complete ? 0.6 : 1.0)
//                    .lineLimit(2) // 限制行数，避免布局计算
//
//                Spacer()
//            }
//            .padding(.vertical, 8)
//    }
//}  // TaskRowView 结束
//
//}  // TDTaskListView 结束
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
    
    // 缓存当前分类的分组结果，避免滑动时重复计算
    @State private var cachedTaskGroups: [TDTaskGroupModel] = []
    
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
        
        // 设置默认展开状态：过期已达成默认关闭，其他分组默认展开
        // 注意：这里不需要额外设置，因为 expandedGroups 已经在声明时初始化了
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
    
    /// 获取任务分组数组（使用缓存避免滑动时重复计算）
    private var taskGroups: [TDTaskGroupModel] {
        return cachedTaskGroups
    }
    
    /// 更新分组缓存（只在数据真正变化时调用）
    private func updateTaskGroups() {
        // 步骤1：初始化分组数组，用于存储所有要显示的分组
        var groups: [TDTaskGroupModel] = []
        
        // 步骤2：获取设置管理器，用于读取用户的分组显示设置
        let settingManager = TDSettingManager.shared
        
        // 步骤3：直接使用枚举的rawValue作为ID
        func getGroupId(for type: TDTaskGroupType) -> Int {
            return type.rawValue
        }
        
        // 步骤4.1：创建过期已达成分组
        // 条件：设置中未设置为隐藏，且确实有过期已完成的任务
        if settingManager.expiredRangeCompleted != .hide && !overdueCompletedTasks.isEmpty {
            let groupId = getGroupId(for: .overdueCompleted)
            // 创建分组模型，包含任务数量、完成状态、展开状态等信息
            let group = TDTaskGroupModel(
                type: .overdueCompleted,
                taskCount: overdueCompletedTasks.count,        // 任务总数
                completedCount: overdueCompletedTasks.count,   // 完成数量（过期已完成的都是已完成）
                totalCount: overdueCompletedTasks.count,       // 总数量
                isExpanded: expandedGroups.contains(groupId),  // 是否展开
                isHovered: hoveredGroups.contains(groupId),    // 是否悬停
                tasks: overdueCompletedTasks                   // 将查询到的任务数组赋值给分组
            )
            groups.append(group)  // 将分组添加到数组中
        }
        
        // 步骤4.2：创建过期未达成分组
        // 条件：设置中未设置为隐藏，且确实有过期未完成的任务
        if settingManager.expiredRangeUncompleted != .hide && !overdueUncompletedTasks.isEmpty {
            let groupId = getGroupId(for: .overdueUncompleted)
            // 创建分组模型
            let group = TDTaskGroupModel(
                type: .overdueUncompleted,
                taskCount: overdueUncompletedTasks.count,      // 任务总数
                completedCount: 0,                             // 完成数量（过期未完成的都是未完成）
                totalCount: overdueUncompletedTasks.count,     // 总数量
                isExpanded: expandedGroups.contains(groupId),  // 是否展开
                isHovered: hoveredGroups.contains(groupId),    // 是否悬停
                tasks: overdueUncompletedTasks                 // 将查询到的任务数组赋值给分组
            )
            groups.append(group)  // 将分组添加到数组中
        }
        
        // 步骤4.3：创建今天分组
        // 条件：只有今天确实有任务才显示
        if !todayTasks.isEmpty {
            let groupId = getGroupId(for: .today)
            // 计算已完成任务的数量
            let completedCount = todayTasks.filter { $0.complete }.count
            // 创建分组模型
            let group = TDTaskGroupModel(
                type: .today,
                taskCount: todayTasks.count,                   // 任务总数
                completedCount: completedCount,                // 已完成数量
                totalCount: todayTasks.count,                  // 总数量
                isExpanded: expandedGroups.contains(groupId),  // 是否展开
                isHovered: hoveredGroups.contains(groupId),    // 是否悬停
                tasks: todayTasks                              // 将查询到的任务数组赋值给分组
            )
            groups.append(group)  // 将分组添加到数组中
        }
        
        // 步骤4.4：创建明天分组
        // 条件：只有明天确实有任务才显示
        if !tomorrowTasks.isEmpty {
            let groupId = getGroupId(for: .tomorrow)
            let completedCount = tomorrowTasks.filter { $0.complete }.count
            let group = TDTaskGroupModel(
                type: .tomorrow,
                taskCount: tomorrowTasks.count,                 // 任务总数
                completedCount: completedCount,                // 已完成数量
                totalCount: tomorrowTasks.count,               // 总数量
                isExpanded: expandedGroups.contains(groupId),  // 是否展开
                isHovered: hoveredGroups.contains(groupId),    // 是否悬停
                tasks: tomorrowTasks                           // 将查询到的任务数组赋值给分组
            )
            groups.append(group)  // 将分组添加到数组中
        }
        
        // 步骤4.5：创建后天分组
        // 条件：只有后天确实有任务才显示
        if !dayAfterTomorrowTasks.isEmpty {
            let groupId = getGroupId(for: .dayAfterTomorrow)
            let completedCount = dayAfterTomorrowTasks.filter { $0.complete }.count
            let group = TDTaskGroupModel(
                type: .dayAfterTomorrow,
                taskCount: dayAfterTomorrowTasks.count,         // 任务总数
                completedCount: completedCount,                // 已完成数量
                totalCount: dayAfterTomorrowTasks.count,       // 总数量
                isExpanded: expandedGroups.contains(groupId),  // 是否展开
                isHovered: hoveredGroups.contains(groupId),    // 是否悬停
                tasks: dayAfterTomorrowTasks                   // 将查询到的任务数组赋值给分组
            )
            groups.append(group)  // 将分组添加到数组中
        }
        
        // 步骤4.6：创建后续日程分组
        // 条件：确实有后续日程任务（设置中的"全部"表示显示所有后续日程）
        if !futureScheduleTasks.isEmpty {
            let groupId = getGroupId(for: .upcomingSchedule)
            let completedCount = futureScheduleTasks.filter { $0.complete }.count
            let group = TDTaskGroupModel(
                type: .upcomingSchedule,
                taskCount: futureScheduleTasks.count,           // 任务总数
                completedCount: completedCount,                // 已完成数量
                totalCount: futureScheduleTasks.count,         // 总数量
                isExpanded: expandedGroups.contains(groupId),  // 是否展开
                isHovered: hoveredGroups.contains(groupId),    // 是否悬停
                tasks: futureScheduleTasks                     // 将查询到的任务数组赋值给分组
            )
            groups.append(group)  // 将分组添加到数组中
        }
        
        // 步骤4.7：创建无日期分组
        // 条件：设置中显示无日期事件，且确实有无日期任务
        if settingManager.showNoDateEvents && !noDateTasks.isEmpty {
            let groupId = getGroupId(for: .noDate)
            let completedCount = noDateTasks.filter { $0.complete }.count
            let group = TDTaskGroupModel(
                type: .noDate,
                taskCount: noDateTasks.count,                   // 任务总数
                completedCount: completedCount,                // 已完成数量
                totalCount: noDateTasks.count,                 // 总数量
                isExpanded: expandedGroups.contains(groupId),  // 是否展开
                isHovered: hoveredGroups.contains(groupId),    // 是否悬停
                tasks: noDateTasks                             // 将查询到的任务数组赋值给分组
            )
            groups.append(group)  // 将分组添加到数组中
        }
        
        // 步骤5：更新缓存
        cachedTaskGroups = groups.sorted { $0.type < $1.type }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 任务输入框
            TDTaskInputView()
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            
            // 任务分组列表
            if taskGroups.isEmpty {
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
                ScrollViewReader { proxy in
                    List {
                        ForEach(taskGroups) { group in
                            taskGroupSection(for: group)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    // 性能优化配置
                    .environment(\.defaultMinListRowHeight, 44)
                    .environment(\.defaultMinListHeaderHeight, 36)
                    // 禁用滚动指示器，提升性能
                    .scrollIndicators(.hidden)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            // 初始化时更新分组缓存
            updateTaskGroups()
        }
        // 监听任务数据变化通知，重新计算分组
        .onReceive(NotificationCenter.default.publisher(for: .taskDataChanged)) { _ in
            updateTaskGroups()
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
    
    // MARK: - 分组视图
    
    /// 任务分组区域
    private func taskGroupSection(for group: TDTaskGroupModel) -> some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedGroups.contains(group.type.rawValue) },
                set: { isExpanded in
                    toggleGroupExpansion(for: group.type.rawValue)
                }
            ),
            content: {
                VStack(spacing: 0) {
                    ForEach(group.tasks, id: \.taskId) { task in
                        TaskRowView(task: task, category: category)
                            .padding(.leading, 16)
                            .padding(.vertical, 4)
                    }
                }
            },
            label: {
                taskGroupHeaderView(for: group)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleGroupExpansion(for: group.type.rawValue)
                    }
            }
        )
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    /// 分组头部视图
    private func taskGroupHeaderView(for group: TDTaskGroupModel) -> some View {
        HStack {
            // 分组标题
            Text(group.title)
                .font(.system(size: 14))
                .foregroundColor(getTitleColor(for: group.type))
            
            Spacer()
            
            // 任务数量标签 - 只在有任务时才显示
            if group.totalCount > 0 {
                Text("\(group.totalCount)")
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
                if group.type.needsSettingsIcon {
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
                if group.type.needsRescheduleButton {
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
            .opacity(hoveredGroups.contains(group.type.rawValue) ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .frame(height: 36) // 固定高度36
        .background(getGroupHeaderBackgroundColor(for: group.type)) // 添加背景色
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.2)) {
                if isHovered {
                    hoveredGroups.insert(group.type.rawValue)
                } else {
                    hoveredGroups.remove(group.type.rawValue)
                }
            }
        }
    }
    
    // MARK: - 任务行视图
    
    /// 任务行视图（性能优化版本）
    private struct TaskRowView: View {
        @EnvironmentObject private var themeManager: TDThemeManager
        
        let task: TDMacSwiftDataListModel
        let category: TDSliderBarModel
        
        // 缓存颜色，避免重复计算
        private var circleColor: Color {
            themeManager.color(level: 5)
        }
        
        private var textColor: Color {
            themeManager.titleTextColor
        }
        
        var body: some View {
            HStack(spacing: 12) {
                // 完成状态圆圈
                Circle()
                    .stroke(circleColor, lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Group {
                            if task.complete {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(circleColor)
                            }
                        }
                    )
                
                // 任务标题
                Text(task.taskContent)
                    .font(.system(size: 14))
                    .foregroundColor(textColor)
                    .strikethrough(task.complete)
                    .opacity(task.complete ? 0.6 : 1.0)
                    .lineLimit(2) // 限制行数，避免布局计算
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }  // TaskRowView 结束
    
}  // TDTaskListView 结束

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
