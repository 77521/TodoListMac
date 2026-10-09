
import SwiftUI
import SwiftData
import Foundation
import AppKit

// MARK: - 任务列表主视图

/// 任务列表界面 - 用于最近待办、未分类和用户分类
struct TDTaskListView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var mainViewModel = TDMainViewModel.shared
    @ObservedObject private var settingManager = TDSettingManager.shared

    let category: TDSliderBarModel
    let tagFilter: String

    // MARK: - 分组展开状态（过期已达成默认折叠）
    @State private var expandedGroups: Set<TDTaskGroupType> =
        Set(TDTaskGroupType.allCases).subtracting([.overdueCompleted])

    // MARK: - 拖拽排序状态
    @State private var draggedTask: TDMacSwiftDataListModel?
    @State private var placeholderGroup: TDTaskGroupType?
    @State private var placeholderIndex: Int?
    @State private var autoScrollDirection: Int = 0

    /// 分组 / 扁平行缓存：选中行、多选、hover 等无关状态变化时不再 O(n) 重算
    @State private var cachedGrouped = GroupedTasks()
    @State private var cachedVisibleGroups: [TDTaskGroupType] = []
    @State private var cachedFlattenedTasks: [TDMacSwiftDataListModel] = []
    @State private var tableScrollToId: String?

    // MARK: - 单次 @Query，切换分类时只需一次数据库查询
    @Query private var tasks: [TDMacSwiftDataListModel]

    init(category: TDSliderBarModel, tagFilter: String = "") {
        self.category = category
        self.tagFilter = tagFilter
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getTaskListSupersetQuery(
            categoryId: category.categoryId,
            tagFilter: tagFilter
        )
        _tasks = Query(filter: predicate, sort: sortDescriptors)
    }

    // MARK: - Body

    /// 影响内存分组 / 可见组的设置指纹：变了才重建缓存，不跟着选中行刷新
    private var groupingSettingsFingerprint: String {
        "\(settingManager.showCompletedTasks)-\(settingManager.showNoDateEvents)-\(settingManager.showCompletedNoDateEvents)-\(settingManager.expiredRangeCompleted.rawValue)-\(settingManager.expiredRangeUncompleted.rawValue)-\(settingManager.futureDateRange.rawValue)-\(settingManager.repeatNum)-\(settingManager.taskListSortType)"
    }

    private func rebuildListCache() {
        let grouped = groupTasks(tasks)
        let visible = buildVisibleGroups(grouped: grouped, settingManager: settingManager)
        cachedGrouped = grouped
        cachedVisibleGroups = visible
        cachedFlattenedTasks = flattenGrouped(grouped)
    }

    /// 先让侧栏切换落地，下一帧再分组，避免点「最近待办」卡在当前页
    private func scheduleRebuildListCache() {
        DispatchQueue.main.async {
            rebuildListCache()
        }
    }

    var body: some View {
        let visibleGroups = cachedVisibleGroups
        let groupedSource = cachedGrouped
        let groupTasksByType: (TDTaskGroupType) -> [TDMacSwiftDataListModel] = { groupedSource.tasks(for: $0) }
        let hasVisibleTasks = !visibleGroups.isEmpty
        let isQuerying = visibleGroups.isEmpty && !tasks.isEmpty

        let isMultiSelect  = mainViewModel.isMultiSelectMode
        let selectedTaskId = mainViewModel.selectedTask?.taskId
        let selectedTaskIds = Set(mainViewModel.selectedTasks.map(\.taskId))

        VStack(spacing: 0) {
            // 顶部任务输入框
            TDTaskInputView()
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

            if isQuerying {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !hasVisibleTasks {
                TDEmptyStateView(
                    icon: "checkmark.circle",
                    title: "暂无任务",
                    subtitle: "点击上方输入框添加新任务"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let tableItems = buildTableItems(visibleGroups: visibleGroups, grouped: groupedSource)
                let updateToken = tableUpdateToken(
                    isMultiSelect: isMultiSelect,
                    selectedTaskId: selectedTaskId,
                    selectedTaskIds: selectedTaskIds
                )
                TDTaskAppKitTable(
                    items: tableItems,
                    expandToken: expandedGroups,
                    updateToken: updateToken,
                    scrollToId: $tableScrollToId
                ) { item in
                    tableRow(
                        item,
                        isMultiSelect: isMultiSelect,
                        selectedTaskId: selectedTaskId,
                        selectedTaskIds: selectedTaskIds,
                        groupTasksByType: groupTasksByType
                    )
                }
                .onChange(of: draggedTask?.taskId) { _, _ in rebuildListCache() }
                .onChange(of: placeholderGroup) { _, _ in rebuildListCache() }
                .onChange(of: placeholderIndex) { _, _ in rebuildListCache() }
                .onDrop(of: [.text], delegate: TDTaskListDragCleanupDropDelegate(
                    draggedTask:        $draggedTask,
                    placeholderGroup:   $placeholderGroup,
                    placeholderIndex:   $placeholderIndex,
                    autoScrollDirection: $autoScrollDirection
                ))
                .onChange(of: tasks) { oldTasks, newTasks in
                    guard newTasks.count > oldTasks.count else { return }
                    let oldIds = Set(oldTasks.map { $0.taskId })
                    guard let newTask = newTasks.first(where: { !oldIds.contains($0.taskId) }) else { return }
                    if let targetGroup = groupTypeFor(task: newTask, in: cachedGrouped),
                       !expandedGroups.contains(targetGroup) {
                        expandedGroups.insert(targetGroup)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        mainViewModel.selectTask(newTask)
                        tableScrollToId = newTask.taskId
                    }
                }
                .background {
                    if draggedTask != nil {
                        Color.clear
                            .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
                                guard autoScrollDirection != 0 else { return }
                                handleAutoScroll(
                                    visibleGroups: visibleGroups,
                                    groupTasksByType: groupTasksByType
                                )
                            }
                    }
                }
                .overlay(alignment: .top) {
                    Color.clear
                        .frame(height: 44)
                        .contentShape(Rectangle())
                        .onDrop(of: [.text], delegate: TDTaskListAutoScrollEdgeDropDelegate(
                            direction: -1,
                            draggedTask:        $draggedTask,
                            placeholderGroup:   $placeholderGroup,
                            placeholderIndex:   $placeholderIndex,
                            autoScrollDirection: $autoScrollDirection,
                            context: modelContext,
                            groupTasksByType: groupTasksByType,
                            onDenied: { key in TDToastCenter.shared.show(key, type: .info, position: .bottom) }
                        ))
                        .allowsHitTesting(draggedTask != nil)
                }
                .overlay(alignment: .bottom) {
                    Color.clear
                        .frame(height: 44)
                        .contentShape(Rectangle())
                        .onDrop(of: [.text], delegate: TDTaskListAutoScrollEdgeDropDelegate(
                            direction: 1,
                            draggedTask:        $draggedTask,
                            placeholderGroup:   $placeholderGroup,
                            placeholderIndex:   $placeholderIndex,
                            autoScrollDirection: $autoScrollDirection,
                            context: modelContext,
                            groupTasksByType: groupTasksByType,
                            onDenied: { key in TDToastCenter.shared.show(key, type: .info, position: .bottom) }
                        ))
                        .allowsHitTesting(draggedTask != nil)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
        .onAppear { scheduleRebuildListCache() }
        .onChange(of: groupingSettingsFingerprint) { _, _ in scheduleRebuildListCache() }
        .onChange(of: tasks) { _, _ in scheduleRebuildListCache() }
        // 拖入某分组时自动展开该分组
        .onChange(of: placeholderGroup) { _, newGroup in
            guard draggedTask != nil, let newGroup else { return }
            if !expandedGroups.contains(newGroup) {
                expandedGroups.insert(newGroup)
            }
        }
        // 多选操作栏
        .overlay(alignment: .bottom) {
            if isMultiSelect {
                TDMultiSelectActionBar(allTasks: cachedFlattenedTasks)
            }
        }
    }

    // MARK: - 分组行

    private func tableUpdateToken(
        isMultiSelect: Bool,
        selectedTaskId: String?,
        selectedTaskIds: Set<String>
    ) -> String {
        var token = isMultiSelect ? "1" : "0"
        token += "|"
        token += selectedTaskId ?? ""
        token += "|"
        token += selectedTaskIds.sorted().joined(separator: ",")
        token += "|"
        token += draggedTask?.taskId ?? ""
        token += "|"
        token += placeholderGroup.map { String($0.rawValue) } ?? ""
        token += "|"
        token += placeholderIndex.map(String.init) ?? ""
        return token
    }

    private func buildTableItems(
        visibleGroups: [TDTaskGroupType],
        grouped: GroupedTasks
    ) -> [TDTaskTableItem] {
        var result: [TDTaskTableItem] = []
        result.reserveCapacity(64)
        for type in visibleGroups {
            result.append(.header(type))
            guard expandedGroups.contains(type) else { continue }
            let items = renderItems(for: type, grouped: grouped)
            for (idx, item) in items.enumerated() {
                result.append(.task(item, groupType: type, isFirst: idx == 0, isLast: idx == items.count - 1))
            }
        }
        return result
    }

    @ViewBuilder
    private func tableRow(
        _ item: TDTaskTableItem,
        isMultiSelect: Bool,
        selectedTaskId: String?,
        selectedTaskIds: Set<String>,
        groupTasksByType: @escaping (TDTaskGroupType) -> [TDMacSwiftDataListModel]
    ) -> some View {
        switch item {
        case .header(let type):
            groupHeaderRow(type, groupTasksByType: groupTasksByType)
        case .task(let renderItem, let type, let isFirst, let isLast):
            taskRow(
                renderItem,
                groupType: type,
                isFirst: isFirst,
                isLast: isLast,
                isMultiSelect: isMultiSelect,
                selectedTaskId: selectedTaskId,
                selectedTaskIds: selectedTaskIds,
                groupTasksByType: groupTasksByType
            )
        case .revealSpacer:
            EmptyView()
        }
    }

    private func renderItems(
        for groupType: TDTaskGroupType,
        grouped: GroupedTasks
    ) -> [TDTaskListRenderItem] {
        TDTaskListDragRender.build(
            groupTasks: grouped.tasks(for: groupType),
            groupType: groupType,
            draggedTask: draggedTask,
            placeholderGroup: placeholderGroup,
            placeholderIndex: placeholderIndex
        )
    }

    @ViewBuilder
    private func groupHeaderRow(
        _ type: TDTaskGroupType,
        groupTasksByType: @escaping (TDTaskGroupType) -> [TDMacSwiftDataListModel]
    ) -> some View {
        let groupTasks = groupTasksByType(type)
        TDTaskGroupHeaderView(
            type: type,
            title: type.localizedBaseTitle,
            tasks: groupTasks,
            totalCount: groupTasks.count,
            isExpanded: bindingForGroupExpanded(type),
            onReschedule: {
                mainViewModel.enterMultiSelectMode()
                mainViewModel.selectedTasks = groupTasks
                mainViewModel.requestShowMultiSelectDatePicker()
            },
            handlesTapToToggle: true
        )
        .onDrop(of: [.text], delegate: TDTaskListGroupHeaderDropDelegate(
            destinationGroupType: type,
            destinationIndexProvider: { 0 },
            draggedTask: $draggedTask,
            placeholderGroup: $placeholderGroup,
            placeholderIndex: $placeholderIndex,
            autoScrollDirection: $autoScrollDirection,
            context: modelContext,
            groupTasksByType: groupTasksByType,
            onDenied: { key in TDToastCenter.shared.show(key, type: .info, position: .bottom) }
        ))
    }

    @ViewBuilder
    private func taskRow(
        _ renderItem: TDTaskListRenderItem,
        groupType: TDTaskGroupType,
        isFirst: Bool,
        isLast: Bool,
        isMultiSelect: Bool,
        selectedTaskId: String?,
        selectedTaskIds: Set<String>,
        groupTasksByType: @escaping (TDTaskGroupType) -> [TDMacSwiftDataListModel]
    ) -> some View {
        TDTaskRowView(
            task: renderItem.task,
            category: category,
            orderNumber: nil,
            isFirstRow: isFirst,
            isLastRow: isLast,
            isMultiSelectMode: isMultiSelect,
            isSelectedTask: selectedTaskId == renderItem.task.taskId,
            isMultiSelected: selectedTaskIds.contains(renderItem.task.taskId),
            onCopySuccess: {
                TDToastCenter.shared.show("copy_success_simple", type: .success, position: .bottom)
            },
            onEnterMultiSelect: { }
        )
        .equatable()
        .id(renderItem.id)
        .opacity(renderItem.isPlaceholder ? 0.55 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(themeManager.color(level: 5), lineWidth: 1.4)
                .opacity(renderItem.isPlaceholder ? 1 : 0)
        )
        .onDrag({
            guard !renderItem.isPlaceholder else { return NSItemProvider() }
            let groupTasks = groupTasksByType(groupType)
            draggedTask = renderItem.task
            placeholderGroup = groupType
            placeholderIndex = groupTasks.firstIndex(where: { $0.taskId == renderItem.task.taskId }) ?? 0
            autoScrollDirection = 0
            return NSItemProvider(object: renderItem.task.taskId as NSString)
        })
        .onDrop(of: [.text], delegate: TDTaskListGroupRowDropDelegate(
            destinationTask: renderItem.task,
            destinationGroupType: groupType,
            draggedTask: $draggedTask,
            placeholderGroup: $placeholderGroup,
            placeholderIndex: $placeholderIndex,
            autoScrollDirection: $autoScrollDirection,
            context: modelContext,
            groupTasksByType: groupTasksByType,
            onDenied: { key in TDToastCenter.shared.show(key, type: .info, position: .bottom) }
        ))
    }

    @ViewBuilder
    private func groupFooterRow(
        _ type: TDTaskGroupType,
        height: CGFloat,
        groupTasksByType: @escaping (TDTaskGroupType) -> [TDMacSwiftDataListModel]
    ) -> some View {
        Color.clear
            .frame(height: height)
            .contentShape(Rectangle())
            .onDrop(of: [.text], delegate: TDTaskListGroupAreaDropDelegate(
                destinationGroupType: type,
                destinationIndexProvider: { groupTasksByType(type).count },
                draggedTask: $draggedTask,
                placeholderGroup: $placeholderGroup,
                placeholderIndex: $placeholderIndex,
                autoScrollDirection: $autoScrollDirection,
                context: modelContext,
                groupTasksByType: groupTasksByType,
                onDenied: { key in TDToastCenter.shared.show(key, type: .info, position: .bottom) }
            ))
    }

    // MARK: - 边缘自动滚动逻辑

    private func handleAutoScroll(
        visibleGroups:    [TDTaskGroupType],
        groupTasksByType: (TDTaskGroupType) -> [TDMacSwiftDataListModel]
    ) {
        guard let draggedTask else { return }
        guard let g   = placeholderGroup else { return }
        guard let idx = placeholderIndex else { return }

        let baseCount = groupTasksByType(g).filter { $0.taskId != draggedTask.taskId }.count
        var nextGroup = g
        var nextIndex = idx + autoScrollDirection

        if autoScrollDirection > 0, idx >= baseCount, nextIndex > baseCount {
            if let cur = visibleGroups.firstIndex(of: g), cur + 1 < visibleGroups.count {
                nextGroup = visibleGroups[cur + 1]
                nextIndex = 0
            } else {
                nextIndex = baseCount
            }
        } else if autoScrollDirection < 0, idx <= 0, nextIndex < 0 {
            if let cur = visibleGroups.firstIndex(of: g), cur - 1 >= 0 {
                nextGroup = visibleGroups[cur - 1]
                let prevCount = groupTasksByType(nextGroup).filter { $0.taskId != draggedTask.taskId }.count
                nextIndex = prevCount
            } else {
                nextIndex = 0
            }
        } else {
            nextIndex = min(max(nextIndex, 0), baseCount)
        }

        guard (nextGroup != g) || (nextIndex != idx) else { return }
        placeholderGroup = nextGroup
        placeholderIndex = nextIndex
        tableScrollToId = TDTaskListDragRender.placeholderId(for: draggedTask)
    }

    // MARK: - 展开状态 Binding

    private func bindingForGroupExpanded(_ type: TDTaskGroupType) -> Binding<Bool> {
        Binding(
            get: { expandedGroups.contains(type) },
            set: { newValue in
                withAnimation(.timingCurve(0.22, 1.0, 0.36, 1.0, duration: 0.32)) {
                    if newValue { expandedGroups.insert(type) }
                    else { expandedGroups.remove(type) }
                }
            }
        )
    }
}

// MARK: - 分组数据模型与分组逻辑

private extension TDTaskListView {

    // MARK: GroupedTasks

    struct GroupedTasks {
        var overdueCompleted:   [TDMacSwiftDataListModel] = []
        var overdueUncompleted: [TDMacSwiftDataListModel] = []
        var today:              [TDMacSwiftDataListModel] = []
        var tomorrow:           [TDMacSwiftDataListModel] = []
        var dayAfterTomorrow:   [TDMacSwiftDataListModel] = []
        var futureSchedule:     [TDMacSwiftDataListModel] = []
        var noDate:             [TDMacSwiftDataListModel] = []

        func tasks(for type: TDTaskGroupType) -> [TDMacSwiftDataListModel] {
            switch type {
            case .overdueCompleted:   return overdueCompleted
            case .overdueUncompleted: return overdueUncompleted
            case .today:              return today
            case .tomorrow:           return tomorrow
            case .dayAfterTomorrow:   return dayAfterTomorrow
            case .upcomingSchedule:   return futureSchedule
            case .noDate:             return noDate
            }
        }
    }

    // MARK: 单次遍历完成全部分组（O(n)，避免 7 次 filter）

    func groupTasks(_ tasks: [TDMacSwiftDataListModel]) -> GroupedTasks {
        var g = GroupedTasks()
        g.overdueCompleted.reserveCapacity(32)
        g.overdueUncompleted.reserveCapacity(32)
        g.today.reserveCapacity(64)
        g.tomorrow.reserveCapacity(32)
        g.dayAfterTomorrow.reserveCapacity(32)
        g.futureSchedule.reserveCapacity(32)
        g.noDate.reserveCapacity(32)

        let sm                    = TDSettingManager.shared
        let showCompleted         = sm.showCompletedTasks
        let showNoDate            = sm.showNoDateEvents
        let showCompletedNoDate   = sm.showCompletedNoDateEvents
        let completedDaysLimit    = sm.expiredRangeCompleted.rawValue
        let uncompletedDaysLimit  = sm.expiredRangeUncompleted.rawValue
        let futureLimit           = sm.futureDateRange.rawValue
        let repeatPerGroupLimit   = sm.repeatNum

        let now                       = Date()
        let todayTS                   = now.startOfDayTimestamp
        let tomorrowTS                = now.adding(days: 1).startOfDayTimestamp
        let dayAfterTS                = now.adding(days: 2).startOfDayTimestamp
        let completedStartTS          = now.adding(days: -completedDaysLimit).startOfDayTimestamp
        let uncompletedStartTS        = now.adding(days: -uncompletedDaysLimit).startOfDayTimestamp
        let futureUpperBound: Int64   = futureLimit <= 0 ? .max : now.adding(days: futureLimit).endOfDayTimestamp

        var futureRepeatCounts: [String: Int] = [:]

        for task in tasks {
            let tt = task.todoTime
            if tt == 0 {
                if showNoDate && (showCompletedNoDate || !task.complete) {
                    g.noDate.append(task)
                }
                continue
            }
            if tt < todayTS {
                if task.complete {
                    if showCompleted && completedDaysLimit > 0 && tt >= completedStartTS {
                        g.overdueCompleted.append(task)
                    }
                } else {
                    if uncompletedDaysLimit > 0 && tt >= uncompletedStartTS {
                        g.overdueUncompleted.append(task)
                    }
                }
                continue
            }
            let allowByCompleted = showCompleted || !task.complete
            if tt == todayTS    { if allowByCompleted { g.today.append(task) };           continue }
            if tt == tomorrowTS { if allowByCompleted { g.tomorrow.append(task) };        continue }
            if tt == dayAfterTS { if allowByCompleted { g.dayAfterTomorrow.append(task) }; continue }
            if tt > dayAfterTS, allowByCompleted, tt <= futureUpperBound {
                if repeatPerGroupLimit > 0, let rid = task.standbyStr1, !rid.isEmpty {
                    let next = (futureRepeatCounts[rid] ?? 0) + 1
                    if next > repeatPerGroupLimit { continue }
                    futureRepeatCounts[rid] = next
                }
                g.futureSchedule.append(task)
            }
        }
        return g
    }

    // MARK: 可见分组列表

    func buildVisibleGroups(grouped: GroupedTasks, settingManager: TDSettingManager) -> [TDTaskGroupType] {
        var list: [TDTaskGroupType] = []
        if settingManager.expiredRangeCompleted   != .hide, !grouped.overdueCompleted.isEmpty   { list.append(.overdueCompleted) }
        if settingManager.expiredRangeUncompleted != .hide, !grouped.overdueUncompleted.isEmpty { list.append(.overdueUncompleted) }
        if !grouped.today.isEmpty          { list.append(.today) }
        if !grouped.tomorrow.isEmpty       { list.append(.tomorrow) }
        if !grouped.dayAfterTomorrow.isEmpty { list.append(.dayAfterTomorrow) }
        if !grouped.futureSchedule.isEmpty { list.append(.upcomingSchedule) }
        if settingManager.showNoDateEvents, !grouped.noDate.isEmpty { list.append(.noDate) }
        return list
    }

    // MARK: 展平全部分组（供多选操作栏使用）

    func flattenGrouped(_ grouped: GroupedTasks) -> [TDMacSwiftDataListModel] {
        grouped.overdueCompleted
        + grouped.overdueUncompleted
        + grouped.today
        + grouped.tomorrow
        + grouped.dayAfterTomorrow
        + grouped.futureSchedule
        + grouped.noDate
    }

    // MARK: 根据任务查找其所在分组（用于新任务自动展开分组）

    private func groupTypeFor(task: TDMacSwiftDataListModel, in grouped: GroupedTasks) -> TDTaskGroupType? {
        let id = task.taskId
        if grouped.overdueCompleted.contains(where:   { $0.taskId == id }) { return .overdueCompleted }
        if grouped.overdueUncompleted.contains(where: { $0.taskId == id }) { return .overdueUncompleted }
        if grouped.today.contains(where:              { $0.taskId == id }) { return .today }
        if grouped.tomorrow.contains(where:           { $0.taskId == id }) { return .tomorrow }
        if grouped.dayAfterTomorrow.contains(where:   { $0.taskId == id }) { return .dayAfterTomorrow }
        if grouped.futureSchedule.contains(where:     { $0.taskId == id }) { return .upcomingSchedule }
        if grouped.noDate.contains(where:             { $0.taskId == id }) { return .noDate }
        return nil
    }
}

// MARK: - 拖拽渲染（占位行，使用稳定 id 避免 List 行闪烁）

private enum TDTaskListDragRender {

    /// 占位行 id 与真实行 id 保持一致，List 不会因 id 变化而闪烁
    static func placeholderId(for task: TDMacSwiftDataListModel) -> String {
        task.taskId
    }

    static func build(
        groupTasks:       [TDMacSwiftDataListModel],
        groupType:        TDTaskGroupType,
        draggedTask:      TDMacSwiftDataListModel?,
        placeholderGroup: TDTaskGroupType?,
        placeholderIndex: Int?
    ) -> [TDTaskListRenderItem] {
        guard let draggedTask else {
            return groupTasks.map { TDTaskListRenderItem(id: $0.taskId, task: $0, isPlaceholder: false) }
        }
        var base = groupTasks.filter { $0.taskId != draggedTask.taskId }
        guard placeholderGroup == groupType else {
            return base.map { TDTaskListRenderItem(id: $0.taskId, task: $0, isPlaceholder: false) }
        }
        let safeIndex = min(max(placeholderIndex ?? 0, 0), base.count)
        base.insert(draggedTask, at: safeIndex)
        return base.enumerated().map { idx, task in
            let isHolder = task.taskId == draggedTask.taskId && idx == safeIndex
            return TDTaskListRenderItem(id: task.taskId, task: task, isPlaceholder: isHolder)
        }
    }
}

struct TDTaskListRenderItem: Identifiable {
    let id: String
    let task: TDMacSwiftDataListModel
    let isPlaceholder: Bool
}

// MARK: - DropDelegate：行

private struct TDTaskListGroupRowDropDelegate: DropDelegate {
    let destinationTask:      TDMacSwiftDataListModel
    let destinationGroupType: TDTaskGroupType

    @Binding var draggedTask:        TDMacSwiftDataListModel?
    @Binding var placeholderGroup:   TDTaskGroupType?
    @Binding var placeholderIndex:   Int?
    @Binding var autoScrollDirection: Int

    let context:          ModelContext
    let groupTasksByType: (TDTaskGroupType) -> [TDMacSwiftDataListModel]
    let onDenied:         (String) -> Void

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedTask, dragged.taskId != destinationTask.taskId else { return }
        if destinationGroupType.isOverdueGroup, !dragged.isOverdueTask { return }
        let base       = groupTasksByType(destinationGroupType).filter { $0.taskId != dragged.taskId }
        let stableIdx  = base.firstIndex(where: { $0.taskId == destinationTask.taskId }) ?? base.count
        withAnimation(.easeInOut(duration: 0.12)) {
            placeholderGroup = destinationGroupType
            placeholderIndex = stableIdx
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        defer { clearDragState() }
        guard let dragged = draggedTask else { return true }
        let destIndex: Int = {
            if placeholderGroup == destinationGroupType, let idx = placeholderIndex { return idx }
            let base = groupTasksByType(destinationGroupType).filter { $0.taskId != dragged.taskId }
            return base.firstIndex(where: { $0.taskId == destinationTask.taskId }) ?? base.count
        }()
        return TDTaskListDropCommitLogic.commit(
            draggedTask: dragged, destinationGroup: destinationGroupType,
            destinationIndex: destIndex, groupTasksByType: groupTasksByType,
            context: context, onDenied: onDenied
        )
    }

    private func clearDragState() {
        placeholderIndex = nil; placeholderGroup = nil; draggedTask = nil; autoScrollDirection = 0
    }
}

// MARK: - DropDelegate：组头

private struct TDTaskListGroupHeaderDropDelegate: DropDelegate {
    let destinationGroupType:    TDTaskGroupType
    let destinationIndexProvider: () -> Int

    @Binding var draggedTask:        TDMacSwiftDataListModel?
    @Binding var placeholderGroup:   TDTaskGroupType?
    @Binding var placeholderIndex:   Int?
    @Binding var autoScrollDirection: Int

    let context:          ModelContext
    let groupTasksByType: (TDTaskGroupType) -> [TDMacSwiftDataListModel]
    let onDenied:         (String) -> Void

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedTask else { return }
        if destinationGroupType.isOverdueGroup, !dragged.isOverdueTask { return }
        let baseCount = groupTasksByType(destinationGroupType).filter { $0.taskId != dragged.taskId }.count
        let safeIndex = min(max(destinationIndexProvider(), 0), baseCount)
        withAnimation(.easeInOut(duration: 0.12)) {
            placeholderGroup = destinationGroupType
            placeholderIndex = safeIndex
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        defer { clearDragState() }
        guard let dragged = draggedTask else { return true }
        let baseCount = groupTasksByType(destinationGroupType).filter { $0.taskId != dragged.taskId }.count
        let destIndex = min(max(destinationIndexProvider(), 0), baseCount)
        return TDTaskListDropCommitLogic.commit(
            draggedTask: dragged, destinationGroup: destinationGroupType,
            destinationIndex: destIndex, groupTasksByType: groupTasksByType,
            context: context, onDenied: onDenied
        )
    }

    private func clearDragState() {
        placeholderIndex = nil; placeholderGroup = nil; draggedTask = nil; autoScrollDirection = 0
    }
}

// MARK: - DropDelegate：分组区域兜底

private struct TDTaskListGroupAreaDropDelegate: DropDelegate {
    let destinationGroupType:    TDTaskGroupType
    let destinationIndexProvider: () -> Int

    @Binding var draggedTask:        TDMacSwiftDataListModel?
    @Binding var placeholderGroup:   TDTaskGroupType?
    @Binding var placeholderIndex:   Int?
    @Binding var autoScrollDirection: Int

    let context:          ModelContext
    let groupTasksByType: (TDTaskGroupType) -> [TDMacSwiftDataListModel]
    let onDenied:         (String) -> Void

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedTask else { return }
        if destinationGroupType.isOverdueGroup, !dragged.isOverdueTask { return }
        let baseCount = groupTasksByType(destinationGroupType).filter { $0.taskId != dragged.taskId }.count
        let safeIndex = min(max(destinationIndexProvider(), 0), baseCount)
        withAnimation(.easeInOut(duration: 0.12)) {
            placeholderGroup = destinationGroupType
            placeholderIndex = safeIndex
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        defer { clearDragState() }
        guard let dragged = draggedTask else { return true }
        let baseCount = groupTasksByType(destinationGroupType).filter { $0.taskId != dragged.taskId }.count
        let destIndex = min(max(destinationIndexProvider(), 0), baseCount)
        return TDTaskListDropCommitLogic.commit(
            draggedTask: dragged, destinationGroup: destinationGroupType,
            destinationIndex: destIndex, groupTasksByType: groupTasksByType,
            context: context, onDenied: onDenied
        )
    }

    private func clearDragState() {
        placeholderIndex = nil; placeholderGroup = nil; draggedTask = nil; autoScrollDirection = 0
    }
}

// MARK: - DropDelegate：边缘自动滚动

private struct TDTaskListAutoScrollEdgeDropDelegate: DropDelegate {
    let direction: Int

    @Binding var draggedTask:        TDMacSwiftDataListModel?
    @Binding var placeholderGroup:   TDTaskGroupType?
    @Binding var placeholderIndex:   Int?
    @Binding var autoScrollDirection: Int

    let context:          ModelContext
    let groupTasksByType: (TDTaskGroupType) -> [TDMacSwiftDataListModel]
    let onDenied:         (String) -> Void

    func dropEntered(info: DropInfo) { autoScrollDirection = direction }
    func dropExited(info: DropInfo)  { autoScrollDirection = 0 }

    func performDrop(info: DropInfo) -> Bool {
        defer { clearDragState() }
        guard let dragged    = draggedTask   else { return true }
        guard let destGroup  = placeholderGroup else { return true }
        let destIndex = placeholderIndex ?? groupTasksByType(destGroup).count
        return TDTaskListDropCommitLogic.commit(
            draggedTask: dragged, destinationGroup: destGroup,
            destinationIndex: destIndex, groupTasksByType: groupTasksByType,
            context: context, onDenied: onDenied
        )
    }

    private func clearDragState() {
        placeholderIndex = nil; placeholderGroup = nil; draggedTask = nil; autoScrollDirection = 0
    }
}

// MARK: - DropDelegate：兜底清理（松手在滚动区空白处）

private struct TDTaskListDragCleanupDropDelegate: DropDelegate {
    @Binding var draggedTask:        TDMacSwiftDataListModel?
    @Binding var placeholderGroup:   TDTaskGroupType?
    @Binding var placeholderIndex:   Int?
    @Binding var autoScrollDirection: Int

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        placeholderIndex = nil; placeholderGroup = nil; draggedTask = nil; autoScrollDirection = 0
        return true
    }
}

// MARK: - 松手写库逻辑（所有 DropDelegate 共用）

private enum TDTaskListDropCommitLogic {
    static func commit(
        draggedTask:      TDMacSwiftDataListModel,
        destinationGroup: TDTaskGroupType,
        destinationIndex: Int,
        groupTasksByType: (TDTaskGroupType) -> [TDMacSwiftDataListModel],
        context:          ModelContext,
        onDenied:         (String) -> Void
    ) -> Bool {
        if destinationGroup.isOverdueGroup, !draggedTask.isOverdueTask {
            onDenied("task.drag.denied.to_overdue"); return true
        }
        if draggedTask.isOverdueTask, destinationGroup.isOverdueGroup {
            let sourceGroup: TDTaskGroupType = draggedTask.complete ? .overdueCompleted : .overdueUncompleted
            if destinationGroup != sourceGroup {
                onDenied("task.drag.denied.overdue_cross"); return true
            }
        }

        let targetTodoTime = destinationGroup.targetTodoTimeForDrop()
        if destinationGroup.isOverdueGroup, targetTodoTime != nil {
            onDenied("task.drag.denied.to_overdue"); return true
        }

        var simulated = groupTasksByType(destinationGroup).filter { $0.taskId != draggedTask.taskId }
        let safeIndex = min(max(destinationIndex, 0), simulated.count)
        simulated.insert(draggedTask, at: safeIndex)

        if let deniedKey = TDTaskListDragValidation.deniedMessageKey(
            draggedComplete: draggedTask.complete, in: simulated, at: safeIndex
        ) { onDenied(deniedKey); return true }

        let (top, next) = TDTaskDragSortHelper.findTopAndNextTaskSort(
            in: simulated, at: safeIndex, where: { $0.complete == draggedTask.complete }
        )
        var newSort = TDTaskSortCalculator.getMoveCurrentTaskSortValue(
            currentTaskSort: draggedTask.taskSort, topTaskSort: top, nextTaskSort: next
        )
        if top == nil, next == nil { newSort = TDAppConfig.defaultTaskSort }

        let updated = draggedTask
        if let targetTodoTime { updated.todoTime = targetTodoTime }
        updated.taskSort = newSort

        Task {
            do {
                _ = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(
                    updatedTask: updated, context: context
                )
                await TDMainViewModel.shared.performSyncSeparately()
            } catch {
                print("❌ 拖拽排序提交失败: \(error)")
            }
        }
        return true
    }
}

// MARK: - 拖拽校验

private enum TDTaskListDragValidation {
    static func deniedMessageKey(
        draggedComplete: Bool,
        in moved:        [TDMacSwiftDataListModel],
        at index:        Int
    ) -> String? {
        let top  = index > 0               ? moved[index - 1] : nil
        let next = index < moved.count - 1 ? moved[index + 1] : nil
        if draggedComplete,  let next, !next.complete  { return "task.drag.denied.to_uncompleted" }
        if !draggedComplete, let top,  top.complete    { return "task.drag.denied.to_completed"   }
        return nil
    }
}

// MARK: - TDTaskGroupType 辅助扩展

private extension TDTaskGroupType {
    var isOverdueGroup: Bool {
        self == .overdueCompleted || self == .overdueUncompleted
    }

    func targetTodoTimeForDrop(now: Date = Date()) -> Int64? {
        switch self {
        case .overdueCompleted, .overdueUncompleted: return nil
        case .today:             return now.startOfDayTimestamp
        case .tomorrow:          return now.adding(days: 1).startOfDayTimestamp
        case .dayAfterTomorrow:  return now.adding(days: 2).startOfDayTimestamp
        case .upcomingSchedule:  return now.adding(days: 3).startOfDayTimestamp
        case .noDate:            return 0
        }
    }
}

private extension TDMacSwiftDataListModel {
    var isOverdueTask: Bool {
        todoTime > 0 && todoTime < Date().startOfDayTimestamp
    }
}

// MARK: - Preview

#Preview {
    TDTaskListView(category: TDSliderBarModel(
        categoryId:   1,
        categoryName: "示例分类",
        headerIcon:   nil,
        categoryColor: "#FF6B6B",
        unfinishedCount: 5,
        isSelect: false
    ))
    .environmentObject(TDThemeManager.shared)
}
