
import SwiftUI
import SwiftData
import Foundation

// MARK: - 扁平列表项（List + ForEach 高效渲染，替代 ScrollView + LazyVStack）

private enum TDListFlatItem: Identifiable {
    /// 分组组头行
    case groupHeader(TDTaskGroupType)
    /// 任务行（含拖拽占位信息）
    case task(TDTaskListRenderItem, groupType: TDTaskGroupType, isFirst: Bool, isLast: Bool)
    /// 分组尾部：isExpanded=true 时作为 8pt 拖拽落点，false 时作为 2pt 间距（折叠组间距）
    case groupFooter(TDTaskGroupType, isExpanded: Bool)

    var id: String {
        switch self {
        case .groupHeader(let t):            return "hdr-\(t.rawValue)"
        case .task(let item, _, _, _):       return item.id
        case .groupFooter(let t, _):         return "ftr-\(t.rawValue)"
        }
    }
}

// MARK: - 任务列表主视图

/// 任务列表界面 - 用于最近待办、未分类和用户分类
struct TDTaskListView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var mainViewModel = TDMainViewModel.shared

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

    var body: some View {
        let grouped         = groupTasks(tasks)
        let settingManager  = TDSettingManager.shared
        let visibleGroups   = buildVisibleGroups(grouped: grouped, settingManager: settingManager)
        let groupTasksByType: (TDTaskGroupType) -> [TDMacSwiftDataListModel] = { grouped.tasks(for: $0) }
        let flatItems       = buildFlatItems(grouped: grouped, visibleGroups: visibleGroups)
        // 有任务就显示列表（即使全部折叠也保留组头），真正无任务才显示空状态
        let hasVisibleTasks = !visibleGroups.isEmpty

        let isMultiSelect  = mainViewModel.isMultiSelectMode
        let selectedTasks  = mainViewModel.selectedTasks
        let selectedTaskId = mainViewModel.selectedTask?.taskId

        VStack(spacing: 0) {
            // 顶部任务输入框
            TDTaskInputView()
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

            if !hasVisibleTasks {
                // 空状态
                TDEmptyStateView(
                    icon: "checkmark.circle",
                    title: "暂无任务",
                    subtitle: "点击上方输入框添加新任务"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    // ✅ 核心改动：使用 SwiftUI List（NSTableView 后端）替代
                    //    ScrollView + LazyVStack，获得原生单元格虚拟化与丝滑滚动
                    List {
                        ForEach(flatItems) { item in
                            flatItemRow(
                                item,
                                isMultiSelect:  isMultiSelect,
                                selectedTaskId: selectedTaskId,
                                selectedTasks:  selectedTasks,
                                groupTasksByType: groupTasksByType
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                    .environment(\.defaultMinListRowHeight, 0)
                    // macOS List 有约 9pt 内建水平内边距，负 padding 补偿使内容铺满宽度（与 DayTodoView 一致）
                    .padding(.horizontal, -9)
                    // 兜底：松手落在滚动区域空白处时清理拖拽状态
                    .onDrop(of: [.text], delegate: TDTaskListDragCleanupDropDelegate(
                        draggedTask:        $draggedTask,
                        placeholderGroup:   $placeholderGroup,
                        placeholderIndex:   $placeholderIndex,
                        autoScrollDirection: $autoScrollDirection
                    ))
                    // 新任务添加后自动展开所在分组、选中任务并滚动到可见区域
                    .onChange(of: tasks) { oldTasks, newTasks in
                        guard newTasks.count > oldTasks.count else { return }
                        let oldIds = Set(oldTasks.map { $0.taskId })
                        guard let newTask = newTasks.first(where: { !oldIds.contains($0.taskId) }) else { return }
                        // 若所在分组折叠则先展开，确保任务行存在于 flatItems 中
                        let grouped = groupTasks(newTasks)
                        if let targetGroup = groupTypeFor(task: newTask, in: grouped),
                           !expandedGroups.contains(targetGroup) {
                            expandedGroups.insert(targetGroup)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            mainViewModel.selectTask(newTask)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(newTask.taskId, anchor: .center)
                            }
                        }
                    }
                    // 边缘自动滚动定时器（guard 保证只在拖拽时执行，不额外消耗 CPU）
                    .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
                        guard draggedTask != nil, autoScrollDirection != 0 else { return }
                        handleAutoScroll(
                            proxy: proxy,
                            visibleGroups: visibleGroups,
                            groupTasksByType: groupTasksByType
                        )
                    }
                    // 顶部边缘自动滚动命中层
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
                    // 底部边缘自动滚动命中层
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
        // 拖入某分组时自动展开该分组
        .onChange(of: placeholderGroup) { _, newGroup in
            guard draggedTask != nil, let newGroup else { return }
            if !expandedGroups.contains(newGroup) {
                withAnimation(.easeInOut(duration: 0.15)) { expandedGroups.insert(newGroup) }
            }
        }
        // 多选操作栏
        .overlay(alignment: .bottom) {
            if isMultiSelect {
                TDMultiSelectActionBar(allTasks: flattenGrouped(grouped))
            }
        }
    }

    // MARK: - 扁平行视图构建

    @ViewBuilder
    private func flatItemRow(
        _ item: TDListFlatItem,
        isMultiSelect:    Bool,
        selectedTaskId:   String?,
        selectedTasks:    [TDMacSwiftDataListModel],
        groupTasksByType: @escaping (TDTaskGroupType) -> [TDMacSwiftDataListModel]
    ) -> some View {
        switch item {

        // ── 组头行 ──────────────────────────────────────────────────────────
        case .groupHeader(let type):
            let groupTasks = groupTasksByType(type)
            TDTaskGroupHeaderView(
                type:        type,
                title:       type.localizedBaseTitle,
                tasks:       groupTasks,
                totalCount:  groupTasks.count,
                isExpanded:  bindingForGroupExpanded(type)
            )
            .onDrop(of: [.text], delegate: TDTaskListGroupHeaderDropDelegate(
                destinationGroupType: type,
                destinationIndexProvider: { 0 },
                draggedTask:        $draggedTask,
                placeholderGroup:   $placeholderGroup,
                placeholderIndex:   $placeholderIndex,
                autoScrollDirection: $autoScrollDirection,
                context: modelContext,
                groupTasksByType: groupTasksByType,
                onDenied: { key in TDToastCenter.shared.show(key, type: .info, position: .bottom) }
            ))

        // ── 任务行 ──────────────────────────────────────────────────────────
        case .task(let renderItem, let groupType, let isFirst, let isLast):
            let isMultiSelected = selectedTasks.contains(where: { $0.taskId == renderItem.task.taskId })
            TDTaskRowView(
                task:             renderItem.task,
                category:         category,
                orderNumber:      nil,
                isFirstRow:       isFirst,
                isLastRow:        isLast,
                isMultiSelectMode: isMultiSelect,
                isSelectedTask:   selectedTaskId == renderItem.task.taskId,
                isMultiSelected:  isMultiSelected,
                onCopySuccess: {
                    TDToastCenter.shared.show("copy_success_simple", type: .success, position: .bottom)
                },
                onEnterMultiSelect: { }
            )
            .equatable()   // props 完全一致时跳过 body 重执行（需在父视图调用，不能在 body 内链式调用）
            .id(renderItem.id)
            // 占位行外观（拖拽时）
            .opacity(renderItem.isPlaceholder ? 0.55 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(themeManager.color(level: 5), lineWidth: 1.4)
                    .opacity(renderItem.isPlaceholder ? 1 : 0)
            )
            // 拖拽启动
            .onDrag({
                guard !renderItem.isPlaceholder else { return NSItemProvider() }
                let groupTasks = groupTasksByType(groupType)
                draggedTask         = renderItem.task
                placeholderGroup    = groupType
                placeholderIndex    = groupTasks.firstIndex(where: { $0.taskId == renderItem.task.taskId }) ?? 0
                autoScrollDirection = 0
                return NSItemProvider(object: renderItem.task.taskId as NSString)
            })
            // 拖拽落点
            .onDrop(of: [.text], delegate: TDTaskListGroupRowDropDelegate(
                destinationTask:      renderItem.task,
                destinationGroupType: groupType,
                draggedTask:        $draggedTask,
                placeholderGroup:   $placeholderGroup,
                placeholderIndex:   $placeholderIndex,
                autoScrollDirection: $autoScrollDirection,
                context: modelContext,
                groupTasksByType: groupTasksByType,
                onDenied: { key in TDToastCenter.shared.show(key, type: .info, position: .bottom) }
            ))

        // ── 分组尾部（展开时 8pt 拖拽落点，折叠时 2pt 组间间距）──────────
        case .groupFooter(let type, let isExpanded):
            Color.clear
                .frame(height: isExpanded ? 8 : 2)
                .contentShape(Rectangle())
                .onDrop(of: [.text], delegate: TDTaskListGroupAreaDropDelegate(
                    destinationGroupType: type,
                    destinationIndexProvider: { groupTasksByType(type).count },
                    draggedTask:        $draggedTask,
                    placeholderGroup:   $placeholderGroup,
                    placeholderIndex:   $placeholderIndex,
                    autoScrollDirection: $autoScrollDirection,
                    context: modelContext,
                    groupTasksByType: groupTasksByType,
                    onDenied: { key in TDToastCenter.shared.show(key, type: .info, position: .bottom) }
                ))
        }
    }

    // MARK: - 边缘自动滚动逻辑

    private func handleAutoScroll(
        proxy:            ScrollViewProxy,
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

        withAnimation(.linear(duration: 0.05)) {
            proxy.scrollTo(
                TDTaskListDragRender.placeholderId(for: draggedTask),
                anchor: autoScrollDirection < 0 ? .top : .bottom
            )
        }
    }

    // MARK: - 展开状态 Binding

    private func bindingForGroupExpanded(_ type: TDTaskGroupType) -> Binding<Bool> {
        Binding(
            get: { expandedGroups.contains(type) },
            set: { newValue in
                if newValue { expandedGroups.insert(type) }
                else        { expandedGroups.remove(type) }
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

    // MARK: 扁平列表构建（含拖拽占位行）

    func buildFlatItems(grouped: GroupedTasks, visibleGroups: [TDTaskGroupType]) -> [TDListFlatItem] {
        var items: [TDListFlatItem] = []
        items.reserveCapacity(tasks.count + visibleGroups.count * 2)

        for groupType in visibleGroups {
            items.append(.groupHeader(groupType))
            let isExpanded = expandedGroups.contains(groupType)
            if isExpanded {
                let groupTasks = grouped.tasks(for: groupType)
                let renderItems = TDTaskListDragRender.build(
                    groupTasks:      groupTasks,
                    groupType:       groupType,
                    draggedTask:     draggedTask,
                    placeholderGroup: placeholderGroup,
                    placeholderIndex: placeholderIndex
                )
                for (i, item) in renderItems.enumerated() {
                    items.append(.task(item, groupType: groupType,
                                       isFirst: i == 0,
                                       isLast:  i == renderItems.count - 1))
                }
            }
            // 展开时 8pt 拖拽落点，折叠时 2pt 组间间距（始终渲染）
            items.append(.groupFooter(groupType, isExpanded: isExpanded))
        }
        return items
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

private struct TDTaskListRenderItem: Identifiable {
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
