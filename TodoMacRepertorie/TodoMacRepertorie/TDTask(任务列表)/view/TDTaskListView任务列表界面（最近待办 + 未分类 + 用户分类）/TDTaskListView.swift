

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
    
    /// 分组展开状态（默认：过期已达成关闭，其它分组展开）
    @State private var expandedGroups: Set<TDTaskGroupType> = Set(TDTaskGroupType.allCases).subtracting([.overdueCompleted])
    
    // MARK: - 拖拽移动（最初版本：ScrollView + LazyVStack）
    //
    // 说明：
    // - 你要求“回退到最初的界面结构”，这里恢复为 ScrollView + LazyVStack
    // - 组头/任务行 UI 完全复用你原来的 `TDTaskGroupHeaderView` / `TDTaskRowView`
    // - 拖拽仍用 macOS 原生 `onDrag/onDrop`，并保留你要的“靠近边缘自动滚动”
    @State private var draggedTask: TDMacSwiftDataListModel?
    @State private var placeholderGroup: TDTaskGroupType?
    @State private var placeholderIndex: Int?
    @State private var autoScrollDirection: Int = 0

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
    
    /// 获取当前分类的所有“可见任务”（用于多选功能）
    /// - 关键：重复事件显示个数限制仅对“后续日程”生效，所以这里的可见性也以分组逻辑为准
    private var allTasksCount: Int {
        let grouped = groupTasks(tasks)
        return flattenGrouped(grouped).count
    }
    private var allTasksFlattened: [TDMacSwiftDataListModel] {
        let grouped = groupTasks(tasks)
        return flattenGrouped(grouped)
    }

    /// 分组结果
    fileprivate struct GroupedTasks {
        var overdueCompleted: [TDMacSwiftDataListModel] = []
        var overdueUncompleted: [TDMacSwiftDataListModel] = []
        var today: [TDMacSwiftDataListModel] = []
        var tomorrow: [TDMacSwiftDataListModel] = []
        var dayAfterTomorrow: [TDMacSwiftDataListModel] = []
        var futureSchedule: [TDMacSwiftDataListModel] = []
        var noDate: [TDMacSwiftDataListModel] = []
    }

    private func flattenGrouped(_ grouped: GroupedTasks) -> [TDMacSwiftDataListModel] {
        // 顺序与页面分组一致（用于多选操作栏）
        grouped.overdueCompleted
        + grouped.overdueUncompleted
        + grouped.today
        + grouped.tomorrow
        + grouped.dayAfterTomorrow
        + grouped.futureSchedule
        + grouped.noDate
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
        let repeatPerGroupLimit = settingManager.repeatNum

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

        // 仅用于“后续日程”的重复计数：同一重复ID最多显示 N 条（设置为 0 表示全部）
        var futureRepeatCounts: [String: Int] = [:]

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
                    // 重复事件显示个数限制：只在“后续日程”生效
                    if repeatPerGroupLimit > 0, let rid = task.standbyStr1, !rid.isEmpty {
                        let next = (futureRepeatCounts[rid] ?? 0) + 1
                        if next > repeatPerGroupLimit { continue }
                        futureRepeatCounts[rid] = next
                    }
                    grouped.futureSchedule.append(task)
                }
            }
        }

        return grouped
    }
    
    var body: some View {
        let grouped = groupTasks(tasks)
        let settingManager = TDSettingManager.shared
        
        let groupTasksByType: (TDTaskGroupType) -> [TDMacSwiftDataListModel] = { type in
            switch type {
            case .overdueCompleted: return grouped.overdueCompleted
            case .overdueUncompleted: return grouped.overdueUncompleted
            case .today: return grouped.today
            case .tomorrow: return grouped.tomorrow
            case .dayAfterTomorrow: return grouped.dayAfterTomorrow
            case .upcomingSchedule: return grouped.futureSchedule
            case .noDate: return grouped.noDate
            }
        }

        VStack(spacing: 0) {
            // 任务输入框
            TDTaskInputView()
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            
            // 任务分组列表
            if flattenGrouped(grouped).isEmpty {
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
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // 顶部边缘：自动滚动 + 松手提交（按当前占位）
                            Color.clear
                                .frame(height: 18)
                                .id(TDTaskListDragRender.edgeTopId)
                                .contentShape(Rectangle())
                                .onDrop(of: [.text], delegate: TDTaskListAutoScrollEdgeDropDelegate(
                                    direction: -1,
                                    draggedTask: $draggedTask,
                                    placeholderGroup: $placeholderGroup,
                                    placeholderIndex: $placeholderIndex,
                                    autoScrollDirection: $autoScrollDirection,
                                    context: modelContext,
                                    groupTasksByType: groupTasksByType,
                                    onDenied: { key in
                                        TDToastCenter.shared.show(key, type: .info, position: .bottom)
                                    }
                                ))
                            
                            TDTaskListGroupSection(
                                type: .overdueCompleted,
                                title: "overdue_completed".localized,
                                tasks: grouped.overdueCompleted,
                                isVisible: settingManager.expiredRangeCompleted != .hide && !grouped.overdueCompleted.isEmpty,
                                category: category,
                                isExpanded: bindingForGroupExpanded(.overdueCompleted),
                                draggedTask: $draggedTask,
                                placeholderGroup: $placeholderGroup,
                                placeholderIndex: $placeholderIndex,
                                autoScrollDirection: $autoScrollDirection,
                                context: modelContext,
                                groupTasksByType: groupTasksByType,
                                onCopySuccess: { showCopySuccessToast = true }
                            )
                            
                            TDTaskListGroupSection(
                                type: .overdueUncompleted,
                                title: "overdue_uncompleted".localized,
                                tasks: grouped.overdueUncompleted,
                                isVisible: settingManager.expiredRangeUncompleted != .hide && !grouped.overdueUncompleted.isEmpty,
                                category: category,
                                isExpanded: bindingForGroupExpanded(.overdueUncompleted),
                                draggedTask: $draggedTask,
                                placeholderGroup: $placeholderGroup,
                                placeholderIndex: $placeholderIndex,
                                autoScrollDirection: $autoScrollDirection,
                                context: modelContext,
                                groupTasksByType: groupTasksByType,
                                onCopySuccess: { showCopySuccessToast = true }
                            )
                            
                            TDTaskListGroupSection(
                                type: .today,
                                title: "today".localized,
                                tasks: grouped.today,
                                isVisible: !grouped.today.isEmpty,
                                category: category,
                                isExpanded: bindingForGroupExpanded(.today),
                                draggedTask: $draggedTask,
                                placeholderGroup: $placeholderGroup,
                                placeholderIndex: $placeholderIndex,
                                autoScrollDirection: $autoScrollDirection,
                                context: modelContext,
                                groupTasksByType: groupTasksByType,
                                onCopySuccess: { showCopySuccessToast = true }
                            )
                            
                            TDTaskListGroupSection(
                                type: .tomorrow,
                                title: "tomorrow".localized,
                                tasks: grouped.tomorrow,
                                isVisible: !grouped.tomorrow.isEmpty,
                                category: category,
                                isExpanded: bindingForGroupExpanded(.tomorrow),
                                draggedTask: $draggedTask,
                                placeholderGroup: $placeholderGroup,
                                placeholderIndex: $placeholderIndex,
                                autoScrollDirection: $autoScrollDirection,
                                context: modelContext,
                                groupTasksByType: groupTasksByType,
                                onCopySuccess: { showCopySuccessToast = true }
                            )
                            
                            TDTaskListGroupSection(
                                type: .dayAfterTomorrow,
                                title: "day_after_tomorrow".localized,
                                tasks: grouped.dayAfterTomorrow,
                                isVisible: !grouped.dayAfterTomorrow.isEmpty,
                                category: category,
                                isExpanded: bindingForGroupExpanded(.dayAfterTomorrow),
                                draggedTask: $draggedTask,
                                placeholderGroup: $placeholderGroup,
                                placeholderIndex: $placeholderIndex,
                                autoScrollDirection: $autoScrollDirection,
                                context: modelContext,
                                groupTasksByType: groupTasksByType,
                                onCopySuccess: { showCopySuccessToast = true }
                            )
                            
                            TDTaskListGroupSection(
                                type: .upcomingSchedule,
                                title: "upcoming_schedule".localized,
                                tasks: grouped.futureSchedule,
                                isVisible: !grouped.futureSchedule.isEmpty,
                                category: category,
                                isExpanded: bindingForGroupExpanded(.upcomingSchedule),
                                draggedTask: $draggedTask,
                                placeholderGroup: $placeholderGroup,
                                placeholderIndex: $placeholderIndex,
                                autoScrollDirection: $autoScrollDirection,
                                context: modelContext,
                                groupTasksByType: groupTasksByType,
                                onCopySuccess: { showCopySuccessToast = true }
                            )
                            
                            TDTaskListGroupSection(
                                type: .noDate,
                                title: "no_date".localized,
                                tasks: grouped.noDate,
                                isVisible: settingManager.showNoDateEvents && !grouped.noDate.isEmpty,
                                category: category,
                                isExpanded: bindingForGroupExpanded(.noDate),
                                draggedTask: $draggedTask,
                                placeholderGroup: $placeholderGroup,
                                placeholderIndex: $placeholderIndex,
                                autoScrollDirection: $autoScrollDirection,
                                context: modelContext,
                                groupTasksByType: groupTasksByType,
                                onCopySuccess: { showCopySuccessToast = true }
                            )
                            
                            // 底部边缘：自动滚动 + 松手提交（按当前占位）
                            Color.clear
                                .frame(height: 18)
                                .id(TDTaskListDragRender.edgeBottomId)
                                .contentShape(Rectangle())
                                .onDrop(of: [.text], delegate: TDTaskListAutoScrollEdgeDropDelegate(
                                    direction: 1,
                                    draggedTask: $draggedTask,
                                    placeholderGroup: $placeholderGroup,
                                    placeholderIndex: $placeholderIndex,
                                    autoScrollDirection: $autoScrollDirection,
                                    context: modelContext,
                                    groupTasksByType: groupTasksByType,
                                    onDenied: { key in
                                        TDToastCenter.shared.show(key, type: .info, position: .bottom)
                                    }
                                ))
                        }
                        .padding(.bottom, 12)
                    }
                    // 兜底：松手落在滚动区域时也要清理拖拽态（避免占位残留）
                    .onDrop(of: [.text], delegate: TDTaskListDragCleanupDropDelegate(
                        draggedTask: $draggedTask,
                        placeholderGroup: $placeholderGroup,
                        placeholderIndex: $placeholderIndex,
                        autoScrollDirection: $autoScrollDirection
                    ))
                    // 边缘自动滚动：通过“移动占位索引 + scrollTo 占位行”实现平滑滚动
                    .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
                        guard let draggedTask else { return }
                        guard autoScrollDirection != 0 else { return }
                        guard let g = placeholderGroup else { return }
                        guard let idx = placeholderIndex else { return }
                        
                        let baseCount = groupTasksByType(g).filter { $0.taskId != draggedTask.taskId }.count
                        let nextIndex = min(max(idx + autoScrollDirection, 0), baseCount)
                        
                        // 只有索引变化时才触发动画，减少抖动
                        if nextIndex != idx {
                            placeholderIndex = nextIndex
                        }
                        withAnimation(.easeInOut(duration: 0.06)) {
                            proxy.scrollTo(
                                TDTaskListDragRender.placeholderId(for: draggedTask),
                                anchor: autoScrollDirection < 0 ? .top : .bottom
                            )
                        }
                    }
                }
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

/// 分组列表：拖拽靠边自动滚动
private struct TDTaskListAutoScrollEdgeDropDelegate: DropDelegate {
    let direction: Int
    
    @Binding var draggedTask: TDMacSwiftDataListModel?
    @Binding var placeholderGroup: TDTaskGroupType?
    @Binding var placeholderIndex: Int?
    @Binding var autoScrollDirection: Int
    
    let context: ModelContext
    let groupTasksByType: (TDTaskGroupType) -> [TDMacSwiftDataListModel]
    let onDenied: (String) -> Void
    
    func dropEntered(info: DropInfo) {
        autoScrollDirection = direction
        _ = info
    }
    
    func dropExited(info: DropInfo) {
        autoScrollDirection = 0
        _ = info
    }
    
    func performDrop(info: DropInfo) -> Bool {
        _ = info
        defer {
            // 松手：结束拖拽态（即使提交失败也要还原 UI）
            placeholderIndex = nil
            placeholderGroup = nil
            draggedTask = nil
            autoScrollDirection = 0
        }
        
        guard let dragged = draggedTask else { return true }
        guard let destGroup = placeholderGroup else { return true }
        let destIndex = placeholderIndex ?? groupTasksByType(destGroup).count
        
        return TDTaskListDropCommitLogic.commit(
            draggedTask: dragged,
            destinationGroup: destGroup,
            destinationIndex: destIndex,
            groupTasksByType: groupTasksByType,
            context: context,
            onDenied: onDenied
        )
    }
}

// MARK: - 分组区块（最初 UI 结构：ScrollView + LazyVStack）

/// 单个分组区块：组头 + 任务列表（展开时）
/// - 重要：组头/任务行 UI 完全复用现有组件，不改界面，只注入移动能力
private struct TDTaskListGroupSection: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    
    let type: TDTaskGroupType
    let title: String
    let tasks: [TDMacSwiftDataListModel]
    let isVisible: Bool
    let category: TDSliderBarModel
    @Binding var isExpanded: Bool
    
    @Binding var draggedTask: TDMacSwiftDataListModel?
    @Binding var placeholderGroup: TDTaskGroupType?
    @Binding var placeholderIndex: Int?
    @Binding var autoScrollDirection: Int
    
    let context: ModelContext
    let groupTasksByType: (TDTaskGroupType) -> [TDMacSwiftDataListModel]
    let onCopySuccess: () -> Void
    
    var body: some View {
        guard isVisible else { return AnyView(EmptyView()) }
        
        let isDragging = draggedTask != nil
        let renderItems = TDTaskListDragRender.build(
            groupTasks: tasks,
            groupType: type,
            draggedTask: draggedTask,
            placeholderGroup: placeholderGroup,
            placeholderIndex: placeholderIndex
        )
        
        return AnyView(
            VStack(spacing: 0) {
                TDTaskGroupHeaderView(
                    type: type,
                    title: title,
                    tasks: tasks,
                    totalCount: tasks.count,
                    isExpanded: $isExpanded
                )
                // 拖到组头：落到组首（更符合直觉）
                .onDrop(of: [.text], delegate: TDTaskListGroupHeaderDropDelegate(
                    destinationGroupType: type,
                    destinationIndexProvider: { 0 },
                    draggedTask: $draggedTask,
                    placeholderGroup: $placeholderGroup,
                    placeholderIndex: $placeholderIndex,
                    autoScrollDirection: $autoScrollDirection,
                    context: context,
                    groupTasksByType: groupTasksByType,
                    onDenied: { key in
                        TDToastCenter.shared.show(key, type: .info, position: .bottom)
                    }
                ))
                
                if isExpanded {
                    LazyVStack(spacing: 0) {
                        // 空分组：拖拽时提供一个“不可见落点”，避免无法拖入
                        if isDragging, tasks.isEmpty, !type.isOverdueGroup {
                            Color.clear
                                .frame(height: 10)
                                .contentShape(Rectangle())
                                .onDrop(of: [.text], delegate: TDTaskListGroupHeaderDropDelegate(
                                    destinationGroupType: type,
                                    destinationIndexProvider: { 0 },
                                    draggedTask: $draggedTask,
                                    placeholderGroup: $placeholderGroup,
                                    placeholderIndex: $placeholderIndex,
                                    autoScrollDirection: $autoScrollDirection,
                                    context: context,
                                    groupTasksByType: groupTasksByType,
                                    onDenied: { key in
                                        TDToastCenter.shared.show(key, type: .info, position: .bottom)
                                    }
                                ))
                        }
                        
                        ForEach(Array(renderItems.enumerated()), id: \.element.id) { renderIndex, item in
                            let isFirst = renderIndex == 0
                            let isLast = renderIndex == renderItems.count - 1
                            
                            TDTaskRowView(
                                task: item.task,
                                category: category,
                                orderNumber: nil,
                                isFirstRow: isFirst,
                                isLastRow: isLast,
                                onCopySuccess: onCopySuccess,
                                onEnterMultiSelect: { }
                            )
                            .id(item.id)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(themeManager.color(level: 5), lineWidth: 1.4)
                                    .opacity(item.isPlaceholder ? 1 : 0)
                            )
                            .opacity(item.isPlaceholder ? 0.55 : 1.0)
                            .onDrag({
                                // 占位行不可再拖
                                guard !item.isPlaceholder else { return NSItemProvider() }
                                
                                draggedTask = item.task
                                placeholderGroup = type
                                placeholderIndex = tasks.firstIndex(where: { $0.taskId == item.task.taskId }) ?? 0
                                autoScrollDirection = 0
                                return NSItemProvider(object: item.task.taskId as NSString)
                            })
                            .onDrop(of: [.text], delegate: TDTaskListGroupRowDropDelegate(
                                destinationTask: item.task,
                                destinationGroupType: type,
                                draggedTask: $draggedTask,
                                placeholderGroup: $placeholderGroup,
                                placeholderIndex: $placeholderIndex,
                                autoScrollDirection: $autoScrollDirection,
                                context: context,
                                groupTasksByType: groupTasksByType,
                                onDenied: { key in
                                    TDToastCenter.shared.show(key, type: .info, position: .bottom)
                                }
                            ))
                        }
                    }
                } else {
                    // 收起时保留一个极小间距（不改变你原有布局观感）
                    Color.clear.frame(height: 2)
                }
            }
        )
    }
}

// MARK: - 拖拽渲染（占位行）

private enum TDTaskListDragRender {
    static let edgeTopId: String = "td-tasklist-edge-top"
    static let edgeBottomId: String = "td-tasklist-edge-bottom"
    
    static func placeholderId(for task: TDMacSwiftDataListModel) -> String {
        "placeholder-\(task.taskId)"
    }
    
    static func build(
        groupTasks: [TDMacSwiftDataListModel],
        groupType: TDTaskGroupType,
        draggedTask: TDMacSwiftDataListModel?,
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
            if task.taskId == draggedTask.taskId, idx == safeIndex {
                return TDTaskListRenderItem(id: placeholderId(for: task), task: task, isPlaceholder: true)
            } else {
                return TDTaskListRenderItem(id: task.taskId, task: task, isPlaceholder: false)
            }
        }
    }
}

private struct TDTaskListRenderItem: Identifiable {
    let id: String
    let task: TDMacSwiftDataListModel
    let isPlaceholder: Bool
}

// MARK: - DropDelegate（行 / 组头）

private struct TDTaskListGroupRowDropDelegate: DropDelegate {
    let destinationTask: TDMacSwiftDataListModel
    let destinationGroupType: TDTaskGroupType
    
    @Binding var draggedTask: TDMacSwiftDataListModel?
    @Binding var placeholderGroup: TDTaskGroupType?
    @Binding var placeholderIndex: Int?
    @Binding var autoScrollDirection: Int
    
    let context: ModelContext
    let groupTasksByType: (TDTaskGroupType) -> [TDMacSwiftDataListModel]
    let onDenied: (String) -> Void
    
    func dropEntered(info: DropInfo) {
        guard let draggedTask else { return }
        guard draggedTask.taskId != destinationTask.taskId else { return }
        _ = info
        
        // 禁止把任何任务“移入过期分组”（过期任务可以移出）
        if destinationGroupType.isOverdueGroup, !draggedTask.isOverdueTask {
            return
        }
        
        let base = groupTasksByType(destinationGroupType).filter { $0.taskId != draggedTask.taskId }
        let stableIndex = base.firstIndex(where: { $0.taskId == destinationTask.taskId }) ?? base.count
        withAnimation(.easeInOut(duration: 0.12)) {
            placeholderGroup = destinationGroupType
            placeholderIndex = stableIndex
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        _ = info
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        _ = info
        defer {
            placeholderIndex = nil
            placeholderGroup = nil
            draggedTask = nil
            autoScrollDirection = 0
        }
        
        guard let draggedTask else { return true }
        
        let destIndex: Int = {
            if placeholderGroup == destinationGroupType, let placeholderIndex {
                return placeholderIndex
            }
            let base = groupTasksByType(destinationGroupType).filter { $0.taskId != draggedTask.taskId }
            return base.firstIndex(where: { $0.taskId == destinationTask.taskId }) ?? base.count
        }()
        
        return TDTaskListDropCommitLogic.commit(
            draggedTask: draggedTask,
            destinationGroup: destinationGroupType,
            destinationIndex: destIndex,
            groupTasksByType: groupTasksByType,
            context: context,
            onDenied: onDenied
        )
    }
}

private struct TDTaskListGroupHeaderDropDelegate: DropDelegate {
    let destinationGroupType: TDTaskGroupType
    let destinationIndexProvider: () -> Int
    
    @Binding var draggedTask: TDMacSwiftDataListModel?
    @Binding var placeholderGroup: TDTaskGroupType?
    @Binding var placeholderIndex: Int?
    @Binding var autoScrollDirection: Int
    
    let context: ModelContext
    let groupTasksByType: (TDTaskGroupType) -> [TDMacSwiftDataListModel]
    let onDenied: (String) -> Void
    
    func dropEntered(info: DropInfo) {
        guard let draggedTask else { return }
        _ = info
        
        if destinationGroupType.isOverdueGroup, !draggedTask.isOverdueTask {
            return
        }
        
        let baseCount = groupTasksByType(destinationGroupType).filter { $0.taskId != draggedTask.taskId }.count
        let safeIndex = min(max(destinationIndexProvider(), 0), baseCount)
        withAnimation(.easeInOut(duration: 0.12)) {
            placeholderGroup = destinationGroupType
            placeholderIndex = safeIndex
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        _ = info
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        _ = info
        defer {
            placeholderIndex = nil
            placeholderGroup = nil
            draggedTask = nil
            autoScrollDirection = 0
        }
        
        guard let draggedTask else { return true }
        let baseCount = groupTasksByType(destinationGroupType).filter { $0.taskId != draggedTask.taskId }.count
        let destIndex = min(max(destinationIndexProvider(), 0), baseCount)
        
        return TDTaskListDropCommitLogic.commit(
            draggedTask: draggedTask,
            destinationGroup: destinationGroupType,
            destinationIndex: destIndex,
            groupTasksByType: groupTasksByType,
            context: context,
            onDenied: onDenied
        )
    }
}

/// 分组列表：在“边缘自动滚动区”松手时，也要按当前占位提交移动
/// - 修复：拖到边缘自动滚动后松手，占位不消失/不提交的问题
private enum TDTaskListDropCommitLogic {
    static func commit(
        draggedTask: TDMacSwiftDataListModel,
        destinationGroup: TDTaskGroupType,
        destinationIndex: Int,
        groupTasksByType: (TDTaskGroupType) -> [TDMacSwiftDataListModel],
        context: ModelContext,
        onDenied: (String) -> Void
    ) -> Bool {
        // 业务规则 1：任何任务不允许移动到“过期分组”
        if destinationGroup.isOverdueGroup, !draggedTask.isOverdueTask {
            onDenied("task.drag.denied.to_overdue")
            return true
        }
        
        // 业务规则 2：过期任务不允许跨“过期已达成/过期未达成”分组
        if draggedTask.isOverdueTask, destinationGroup.isOverdueGroup {
            let sourceOverdueGroup: TDTaskGroupType = draggedTask.complete ? .overdueCompleted : .overdueUncompleted
            if destinationGroup != sourceOverdueGroup {
                onDenied("task.drag.denied.overdue_cross")
                return true
            }
        }
        
        // 目标分组对应的目标日期（非过期分组才会改 todoTime）
        let targetTodoTime = destinationGroup.targetTodoTimeForDrop()
        if destinationGroup.isOverdueGroup, targetTodoTime != nil {
            onDenied("task.drag.denied.to_overdue")
            return true
        }
        
        let groupTasks = groupTasksByType(destinationGroup)
        var simulated = groupTasks.filter { $0.taskId != draggedTask.taskId }
        let safeIndex = min(max(destinationIndex, 0), simulated.count)
        simulated.insert(draggedTask, at: safeIndex)
        
        // 完成/未完成边界限制（与列表其它落点一致）
        if let deniedKey = TDTaskListDragValidation.deniedMessageKey(
            draggedComplete: draggedTask.complete,
            in: simulated,
            at: safeIndex
        ) {
            onDenied(deniedKey)
            return true
        }
        
        let (top, next) = TDTaskDragSortHelper.findTopAndNextTaskSort(
            in: simulated,
            at: safeIndex,
            where: { $0.complete == draggedTask.complete }
        )
        var newSort = TDTaskSortCalculator.getMoveCurrentTaskSortValue(
            currentTaskSort: draggedTask.taskSort,
            topTaskSort: top,
            nextTaskSort: next
        )
        if top == nil, next == nil {
            newSort = TDAppConfig.defaultTaskSort
        }
        
        let updated = draggedTask
        if let targetTodoTime {
            updated.todoTime = targetTodoTime
        }
        updated.taskSort = newSort
        
        Task {
            do {
                _ = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(updatedTask: updated, context: context)
                await TDMainViewModel.shared.performSyncSeparately()
            } catch {
                print("❌ 边缘松手提交拖拽失败: \(error)")
            }
        }
        
        return true
    }
}

/// 拖拽兜底清理：只要松手落在 ScrollView 上，就结束拖拽态
/// - 目的：解决“松手后占位不消失”的残留问题
private struct TDTaskListDragCleanupDropDelegate: DropDelegate {
    @Binding var draggedTask: TDMacSwiftDataListModel?
    @Binding var placeholderGroup: TDTaskGroupType?
    @Binding var placeholderIndex: Int?
    @Binding var autoScrollDirection: Int
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        _ = info
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        _ = info
        placeholderIndex = nil
        placeholderGroup = nil
        draggedTask = nil
        autoScrollDirection = 0
        return true
    }
}

// MARK: - 展开状态 Binding

private extension TDTaskListView {
    func bindingForGroupExpanded(_ type: TDTaskGroupType) -> Binding<Bool> {
        Binding(
            get: { expandedGroups.contains(type) },
            set: { newValue in
                if newValue {
                    expandedGroups.insert(type)
                } else {
                    expandedGroups.remove(type)
                }
            }
        )
    }
}

// MARK: - 拖拽校验（提示语 key 与 iOS 规则一致）

private enum TDTaskListDragValidation {
    /// 根据“移动后”的相邻项给出拒绝提示 key
    /// - 已完成：不能被放到任何未完成之前
    /// - 未完成：不能被放到任何已完成之后
    static func deniedMessageKey(
        draggedComplete: Bool,
        in moved: [TDMacSwiftDataListModel],
        at index: Int
    ) -> String? {
        let top = index > 0 ? moved[index - 1] : nil
        let next = index < moved.count - 1 ? moved[index + 1] : nil
        
        if draggedComplete, let next, next.complete == false {
            return "task.drag.denied.to_uncompleted"
        }
        if !draggedComplete, let top, top.complete == true {
            return "task.drag.denied.to_completed"
        }
        return nil
    }
}

// MARK: - 小组件：空分组落点提示

// MARK: - 辅助：过期判断与分组目标日期

private extension TDTaskGroupType {
    var isOverdueGroup: Bool {
        self == .overdueCompleted || self == .overdueUncompleted
    }
    
    /// 分组列表“移动到某分组”时，应该把 todoTime 改成什么
    /// - 返回 nil 表示“保持原 todoTime”（例如：只在过期分组内部排序）
    func targetTodoTimeForDrop(now: Date = Date()) -> Int64? {
        switch self {
        case .overdueCompleted, .overdueUncompleted:
            return nil
        case .today:
            return now.startOfDayTimestamp
        case .tomorrow:
            return now.adding(days: 1).startOfDayTimestamp
        case .dayAfterTomorrow:
            return now.adding(days: 2).startOfDayTimestamp
        case .upcomingSchedule:
            // “后续日程”是一个聚合分组（包含很多未来日期），拖入时需要给一个明确日期：
            // 这里取“3天后”，保证一定落在该分组内（>后天）
            return now.adding(days: 3).startOfDayTimestamp
        case .noDate:
            return 0
        }
    }
}

private extension TDMacSwiftDataListModel {
    /// 是否属于“过期任务”（todoTime < 今天 且 todoTime != 0）
    var isOverdueTask: Bool {
        let today = Date().startOfDayTimestamp
        return todoTime > 0 && todoTime < today
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
