

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
    
    // MARK: - macOS 原生拖拽状态（onDrag + onDrop）
    
    /// 当前正在拖拽的任务（拖拽开始时赋值；松手/取消时清空）
    @State private var draggedTask: TDMacSwiftDataListModel?
    
    /// 拖拽预览占位：当前落点所在分组
    @State private var dragPlaceholderGroup: TDTaskGroupType?
    
    /// 拖拽预览占位：在目标分组中的插入位置（0...count）
    @State private var dragPlaceholderIndex: Int?
    
    /// 拖拽靠近滚动边界时自动滚动（-1 向上，1 向下，0 停止）
    @State private var dragAutoScrollDirection: Int = 0

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

    private struct GroupedTasks {
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
        let isDragging = draggedTask != nil

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
                // 分组列表
                ScrollViewReader { proxy in
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
                                onCopySuccess: { showCopySuccessToast = true },
                                isDragging: isDragging,
                                draggedTask: $draggedTask,
                                placeholderGroup: $dragPlaceholderGroup,
                                placeholderIndex: $dragPlaceholderIndex,
                                autoScrollDirection: $dragAutoScrollDirection,
                                context: modelContext,
                                groupTasksProvider: { grouped.overdueCompleted },
                                onDenied: { messageKey in
                                    TDToastCenter.shared.show(messageKey, type: .info, position: .bottom)
                                }
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
                                onCopySuccess: { showCopySuccessToast = true },
                                isDragging: isDragging,
                                draggedTask: $draggedTask,
                                placeholderGroup: $dragPlaceholderGroup,
                                placeholderIndex: $dragPlaceholderIndex,
                                autoScrollDirection: $dragAutoScrollDirection,
                                context: modelContext,
                                groupTasksProvider: { grouped.overdueUncompleted },
                                onDenied: { messageKey in
                                    TDToastCenter.shared.show(messageKey, type: .info, position: .bottom)
                                }
                            )
                            .id(TDTaskGroupType.overdueUncompleted.rawValue)
                        }
                        // 今天组
                        if isDragging || !grouped.today.isEmpty {
                            TDTaskGroupSectionView(
                                type: .today,
                                tasks: grouped.today,
                                title: "today".localized,
                                totalCount: grouped.today.count,
                                category: category,
                                onCopySuccess: { showCopySuccessToast = true },
                                isDragging: isDragging,
                                draggedTask: $draggedTask,
                                placeholderGroup: $dragPlaceholderGroup,
                                placeholderIndex: $dragPlaceholderIndex,
                                autoScrollDirection: $dragAutoScrollDirection,
                                context: modelContext,
                                groupTasksProvider: { grouped.today },
                                onDenied: { messageKey in
                                    TDToastCenter.shared.show(messageKey, type: .info, position: .bottom)
                                }
                            )
                            .id(TDTaskGroupType.today.rawValue)
                        }
                        // 明天组
                        if isDragging || !grouped.tomorrow.isEmpty {
                            TDTaskGroupSectionView(
                                type: .tomorrow,
                                tasks: grouped.tomorrow,
                                title: "tomorrow".localized,
                                totalCount: grouped.tomorrow.count,
                                category: category,
                                onCopySuccess: { showCopySuccessToast = true },
                                isDragging: isDragging,
                                draggedTask: $draggedTask,
                                placeholderGroup: $dragPlaceholderGroup,
                                placeholderIndex: $dragPlaceholderIndex,
                                autoScrollDirection: $dragAutoScrollDirection,
                                context: modelContext,
                                groupTasksProvider: { grouped.tomorrow },
                                onDenied: { messageKey in
                                    TDToastCenter.shared.show(messageKey, type: .info, position: .bottom)
                                }
                            )
                            .id(TDTaskGroupType.tomorrow.rawValue)
                        }
                        // 后天组
                        if isDragging || !grouped.dayAfterTomorrow.isEmpty {
                            TDTaskGroupSectionView(
                                type: .dayAfterTomorrow,
                                tasks: grouped.dayAfterTomorrow,
                                title: "day_after_tomorrow".localized,
                                totalCount: grouped.dayAfterTomorrow.count,
                                category: category,
                                onCopySuccess: { showCopySuccessToast = true },
                                isDragging: isDragging,
                                draggedTask: $draggedTask,
                                placeholderGroup: $dragPlaceholderGroup,
                                placeholderIndex: $dragPlaceholderIndex,
                                autoScrollDirection: $dragAutoScrollDirection,
                                context: modelContext,
                                groupTasksProvider: { grouped.dayAfterTomorrow },
                                onDenied: { messageKey in
                                    TDToastCenter.shared.show(messageKey, type: .info, position: .bottom)
                                }
                            )
                            .id(TDTaskGroupType.dayAfterTomorrow.rawValue)
                        }
                        // 后续日程组
                        if isDragging || !grouped.futureSchedule.isEmpty {
                            TDTaskGroupSectionView(
                                type: .upcomingSchedule,
                                tasks: grouped.futureSchedule,
                                title: "upcoming_schedule".localized,
                                totalCount: grouped.futureSchedule.count,
                                category: category,
                                onCopySuccess: { showCopySuccessToast = true },
                                isDragging: isDragging,
                                draggedTask: $draggedTask,
                                placeholderGroup: $dragPlaceholderGroup,
                                placeholderIndex: $dragPlaceholderIndex,
                                autoScrollDirection: $dragAutoScrollDirection,
                                context: modelContext,
                                groupTasksProvider: { grouped.futureSchedule },
                                onDenied: { messageKey in
                                    TDToastCenter.shared.show(messageKey, type: .info, position: .bottom)
                                }
                            )
                            .id(TDTaskGroupType.upcomingSchedule.rawValue)
                        }
                        // 无日期组
                        if settingManager.showNoDateEvents, (isDragging || !grouped.noDate.isEmpty) {
                            TDTaskGroupSectionView(
                                type: .noDate,
                                tasks: grouped.noDate,
                                title: "no_date".localized,
                                totalCount: grouped.noDate.count,
                                category: category,
                                onCopySuccess: { showCopySuccessToast = true },
                                isDragging: isDragging,
                                draggedTask: $draggedTask,
                                placeholderGroup: $dragPlaceholderGroup,
                                placeholderIndex: $dragPlaceholderIndex,
                                autoScrollDirection: $dragAutoScrollDirection,
                                context: modelContext,
                                groupTasksProvider: { grouped.noDate },
                                onDenied: { messageKey in
                                    TDToastCenter.shared.show(messageKey, type: .info, position: .bottom)
                                }
                            )
                            .id(TDTaskGroupType.noDate.rawValue)
                        }
                        }
                    }
                    .scrollIndicators(.hidden)
                    // MARK: - 边界自动滚动（关键体验，仿滴答清单）
                    //
                    // 设计说明：
                    // - SwiftUI 的拖拽回调不会持续给我们“当前位置”；
                    // - 所以我们采用“边界透明 Drop 区 + 定时器”的方式：
                    //   1) 拖到顶部/底部边缘 → 进入透明 Drop 区 → 设置滚动方向
                    //   2) 定时器每 60ms 推进“占位插入点”，并 scrollTo 占位行
                    // - 结果：无需手动滚轮，拖到边界会自动滚动，体验接近滴答清单
                    .onReceive(Timer.publish(every: 0.06, on: .main, in: .common).autoconnect()) { _ in
                        guard let draggedTask else { return }
                        guard dragAutoScrollDirection != 0 else { return }
                        guard let placeholderGroup = dragPlaceholderGroup else { return }
                        let placeholderId = TDTaskListDragRender.placeholderId(for: draggedTask)
                        
                        // 1) 推进“占位插入点”（让自动滚动过程中落点能一路向上/向下走）
                        let currentGroupTasks: [TDMacSwiftDataListModel] = {
                            switch placeholderGroup {
                            case .overdueCompleted: return grouped.overdueCompleted
                            case .overdueUncompleted: return grouped.overdueUncompleted
                            case .today: return grouped.today
                            case .tomorrow: return grouped.tomorrow
                            case .dayAfterTomorrow: return grouped.dayAfterTomorrow
                            case .upcomingSchedule: return grouped.futureSchedule
                            case .noDate: return grouped.noDate
                            }
                        }()
                        let baseCount = currentGroupTasks.filter { $0.taskId != draggedTask.taskId }.count
                        let maxIndex = max(baseCount, 0)
                        let nextIndex = min(max((dragPlaceholderIndex ?? 0) + dragAutoScrollDirection, 0), maxIndex)
                        if dragPlaceholderIndex != nextIndex {
                            dragPlaceholderIndex = nextIndex
                        }
                        
                        // 2) 把占位行滚入视野（占位 id 固定，但位置会随插入点变化而变化）
                        withAnimation(.easeInOut(duration: 0.1)) {
                            proxy.scrollTo(placeholderId, anchor: dragAutoScrollDirection < 0 ? .top : .bottom)
                        }
                    }
                    .overlay {
                        // 边缘自动滚动区：仅拖拽时启用
                        if isDragging {
                            VStack(spacing: 0) {
                                Color.clear
                                    .frame(height: 52)
                                    .contentShape(Rectangle())
                                    .onDrop(of: [.text], delegate: TDTaskListAutoScrollEdgeDropDelegate(direction: -1, autoScrollDirection: $dragAutoScrollDirection))
                                Spacer(minLength: 0)
                                Color.clear
                                    .frame(height: 52)
                                    .contentShape(Rectangle())
                                    .onDrop(of: [.text], delegate: TDTaskListAutoScrollEdgeDropDelegate(direction: 1, autoScrollDirection: $dragAutoScrollDirection))
                            }
                            .allowsHitTesting(true)
                        }
                    }
                    .onAppear {
                        if let id = mainViewModel.selectedTask?.taskId {
                            DispatchQueue.main.async {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    proxy.scrollTo(id, anchor: .center)
                                }
                            }
                        }
                    }
                    .onChange(of: mainViewModel.selectedTask?.taskId) { _, newId in
                        guard let newId else { return }
                        DispatchQueue.main.async {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(newId, anchor: .center)
                            }
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
    
    /// 当前是否处于拖拽态（用于显示空分组 drop 目标、强制展开等）
    let isDragging: Bool
    
    /// 当前被拖拽的任务
    @Binding var draggedTask: TDMacSwiftDataListModel?
    
    /// 当前占位落点（目标分组 + 插入位置）
    @Binding var placeholderGroup: TDTaskGroupType?
    @Binding var placeholderIndex: Int?
    
    /// 自动滚动方向（由边缘 drop 区控制）
    @Binding var autoScrollDirection: Int
    
    /// SwiftData context：拖拽松手时写库
    let context: ModelContext
    
    /// 目标分组的“原始任务数组”提供者（用于 drop 时计算插入点与 taskSort）
    let groupTasksProvider: () -> [TDMacSwiftDataListModel]
    
    /// 拖拽被拒绝时回调（统一走 Toast）
    let onDenied: (String) -> Void

    @State private var isExpanded: Bool

    init(
        type: TDTaskGroupType,
        tasks: [TDMacSwiftDataListModel],
        title: String,
        totalCount: Int,
        category: TDSliderBarModel,
        onCopySuccess: @escaping () -> Void,
        isDragging: Bool,
        draggedTask: Binding<TDMacSwiftDataListModel?>,
        placeholderGroup: Binding<TDTaskGroupType?>,
        placeholderIndex: Binding<Int?>,
        autoScrollDirection: Binding<Int>,
        context: ModelContext,
        groupTasksProvider: @escaping () -> [TDMacSwiftDataListModel],
        onDenied: @escaping (String) -> Void
    ) {
        self.type = type
        self.tasks = tasks
        self.title = title
        self.totalCount = totalCount
        self.category = category
        self.onCopySuccess = onCopySuccess
        self.isDragging = isDragging
        self._draggedTask = draggedTask
        self._placeholderGroup = placeholderGroup
        self._placeholderIndex = placeholderIndex
        self._autoScrollDirection = autoScrollDirection
        self.context = context
        self.groupTasksProvider = groupTasksProvider
        self.onDenied = onDenied
        // 默认：过期已达成关闭，其它分组展开（与原逻辑一致）
        _isExpanded = State(initialValue: type != .overdueCompleted)
    }

    var body: some View {
        let renderItems = TDTaskListDragRender.build(
            groupTasks: tasks,
            groupType: type,
            draggedTask: draggedTask,
            placeholderGroup: placeholderGroup,
            placeholderIndex: placeholderIndex
        )
        let activePlaceholderGroup = placeholderGroup
        let placeholderId = draggedTask.map { TDTaskListDragRender.placeholderId(for: $0) }

        // 使用 DisclosureGroup：保留系统更稳定的展开/收起动画
        // 但通过自定义 DisclosureGroupStyle 隐藏系统左侧箭头，界面仍由我们完全自定义
        VStack(spacing: 0) {
            DisclosureGroup(
                isExpanded: $isExpanded,
                content: {
                    LazyVStack(spacing: 0) {
                        // 空分组：拖拽时也要给一个“可落点区域”（否则你无法拖到空分组）
                        if isDragging, tasks.isEmpty, !type.isOverdueGroup {
                            TDTaskEmptyDropTargetRow(themeManager: themeManager, title: "task.drag.drop_here".localized)
                                .id(type.rawValue * 10_000 + 999) // 避免与任务 id 冲突（这里只用于 scrollTo）
                                .onDrop(of: [.text], delegate: TDTaskListGroupHeaderDropDelegate(
                                    destinationGroupType: type,
                                    destinationIndexProvider: { 0 },
                                    groupTasksProvider: groupTasksProvider,
                                    draggedTask: $draggedTask,
                                    placeholderGroup: $placeholderGroup,
                                    placeholderIndex: $placeholderIndex,
                                    autoScrollDirection: $autoScrollDirection,
                                    context: context,
                                    onDenied: onDenied
                                ))
                        }
                        
                        ForEach(renderItems.indices, id: \.self) { renderIndex in
                            let item = renderItems[renderIndex]
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
                            .onDrag({
                                // macOS 原生拖拽：按住直接拖即可进入拖拽会话
                                guard !item.isPlaceholder else { return NSItemProvider() }
                                draggedTask = item.task
                                placeholderGroup = type
                                placeholderIndex = tasks.firstIndex(where: { $0.taskId == item.task.taskId }) ?? 0
                                autoScrollDirection = 0
                                
                                return NSItemProvider(object: item.task.taskId as NSString)
                            }, preview: {
                                TDTaskRowView(
                                    task: item.task,
                                    category: category,
                                    orderNumber: nil,
                                    isFirstRow: isFirst,
                                    isLastRow: isLast,
                                    onCopySuccess: { },
                                    onEnterMultiSelect: { }
                                )
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color(themeManager.backgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(themeManager.color(level: 5), lineWidth: 1.5)
                                )
                            })
                            // Drop：落到某一行上（更新占位索引；松手时写库）
                            .onDrop(of: [.text], delegate: TDTaskListGroupRowDropDelegate(
                                destinationTask: item.task,
                                destinationGroupType: type,
                                groupTasksProvider: groupTasksProvider,
                                draggedTask: $draggedTask,
                                placeholderGroup: $placeholderGroup,
                                placeholderIndex: $placeholderIndex,
                                autoScrollDirection: $autoScrollDirection,
                                context: context,
                                onDenied: onDenied
                            ))
                            // 占位行：用描边 + 半透明提示“插入位置”
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(themeManager.color(level: 5), lineWidth: 1.4)
                                    .opacity(item.isPlaceholder ? 1 : 0)
                            )
                            .opacity(item.isPlaceholder ? 0.55 : 1.0)
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
                    // Drop：落到组头（适配“空分组/收起分组”也能作为目标）
                    .onDrop(of: [.text], delegate: TDTaskListGroupHeaderDropDelegate(
                        destinationGroupType: type,
                        destinationIndexProvider: { tasks.count }, // 默认落到组尾，更符合“拖到组头=进入该组”
                        groupTasksProvider: groupTasksProvider,
                        draggedTask: $draggedTask,
                        placeholderGroup: $placeholderGroup,
                        placeholderIndex: $placeholderIndex,
                        autoScrollDirection: $autoScrollDirection,
                        context: context,
                        onDenied: onDenied
                    ))
                }
            )
            .disclosureGroupStyle(TDNoIndicatorDisclosureGroupStyle())
            // 拖拽落点进入本组时，强制展开（否则占位行无法出现，体验会断层）
            .onChange(of: activePlaceholderGroup) { _, newValue in
                guard isDragging else { return }
                guard newValue == type else { return }
                if !isExpanded {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded = true
                    }
                }
            }
            .onChange(of: placeholderId) { _, _ in
                // 只要开始拖拽且落点在本组，也确保本组展开
                guard isDragging else { return }
                guard activePlaceholderGroup == type else { return }
                if !isExpanded {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded = true
                    }
                }
            }

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

// MARK: - 拖拽渲染（分组列表通用）

/// 分组列表拖拽渲染项：正常行 / 占位行
private struct TDTaskListDragRenderItem: Identifiable {
    let id: String
    let task: TDMacSwiftDataListModel
    let isPlaceholder: Bool
}

/// 统一构建“拖拽中的渲染列表”：从原列表移除被拖拽行，再在落点插入一行占位
private enum TDTaskListDragRender {
    static func placeholderId(for task: TDMacSwiftDataListModel) -> String {
        "placeholder-\(task.taskId)"
    }
    
    static func build(
        groupTasks: [TDMacSwiftDataListModel],
        groupType: TDTaskGroupType,
        draggedTask: TDMacSwiftDataListModel?,
        placeholderGroup: TDTaskGroupType?,
        placeholderIndex: Int?
    ) -> [TDTaskListDragRenderItem] {
        guard let draggedTask else {
            return groupTasks.map { TDTaskListDragRenderItem(id: $0.taskId, task: $0, isPlaceholder: false) }
        }
        
        // 1) 从本组中移除原行（避免“同一任务显示两行”）
        var base = groupTasks.filter { $0.taskId != draggedTask.taskId }
        
        // 2) 仅当落点在本组时，插入占位行（占位显示同样的数据，但视觉上更淡 + 边框）
        guard placeholderGroup == groupType else {
            return base.map { TDTaskListDragRenderItem(id: $0.taskId, task: $0, isPlaceholder: false) }
        }
        
        let safeIndex = min(max(placeholderIndex ?? 0, 0), base.count)
        base.insert(draggedTask, at: safeIndex)
        
        return base.enumerated().map { idx, task in
            if task.taskId == draggedTask.taskId, idx == safeIndex {
                return TDTaskListDragRenderItem(id: placeholderId(for: task), task: task, isPlaceholder: true)
            } else {
                return TDTaskListDragRenderItem(id: task.taskId, task: task, isPlaceholder: false)
            }
        }
    }
}

// MARK: - DropDelegate（分组列表：行 / 组头 / 边缘自动滚动）

/// 分组列表：落到某一行上的 drop 代理
private struct TDTaskListGroupRowDropDelegate: DropDelegate {
    let destinationTask: TDMacSwiftDataListModel
    let destinationGroupType: TDTaskGroupType
    let groupTasksProvider: () -> [TDMacSwiftDataListModel]
    
    @Binding var draggedTask: TDMacSwiftDataListModel?
    @Binding var placeholderGroup: TDTaskGroupType?
    @Binding var placeholderIndex: Int?
    @Binding var autoScrollDirection: Int
    
    let context: ModelContext
    let onDenied: (String) -> Void
    
    func dropEntered(info: DropInfo) {
        guard let draggedTask else { return }
        guard draggedTask.taskId != destinationTask.taskId else { return }
        _ = info
        
        // 禁止把任何任务“移入过期分组”（仅允许已过期任务在自己分组内排序）
        if destinationGroupType.isOverdueGroup, !draggedTask.isOverdueTask {
            return
        }
        
        // 拖拽过程中：只更新占位插入点，不写库
        let base = groupTasksProvider().filter { $0.taskId != draggedTask.taskId }
        let stableIndex = base.firstIndex(where: { $0.taskId == destinationTask.taskId }) ?? base.count
        withAnimation(.easeInOut(duration: 0.15)) {
            placeholderGroup = destinationGroupType
            placeholderIndex = stableIndex
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        _ = info
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        defer {
            placeholderIndex = nil
            placeholderGroup = nil
            draggedTask = nil
            autoScrollDirection = 0
        }
        _ = info
        guard let draggedTask else { return true }
        
        // 业务规则 1：任何任务不允许移动到“过期分组”
        if destinationGroupType.isOverdueGroup, !draggedTask.isOverdueTask {
            onDenied("task.drag.denied.to_overdue")
            return true
        }
        
        // 业务规则 2：过期任务不允许跨“过期已达成/过期未达成”分组（避免产生难以理解的“完成状态迁移”）
        if draggedTask.isOverdueTask, destinationGroupType.isOverdueGroup {
            let sourceOverdueGroup: TDTaskGroupType = draggedTask.complete ? .overdueCompleted : .overdueUncompleted
            if destinationGroupType != sourceOverdueGroup {
                onDenied("task.drag.denied.overdue_cross")
                return true
            }
        }
        
        // 计算目标分组的 todoTime（移动到非过期分组时会改日期；过期分组仅允许内部排序）
        let targetTodoTime = destinationGroupType.targetTodoTimeForDrop()
        if destinationGroupType.isOverdueGroup, targetTodoTime != nil {
            // 防御：过期分组不应产生“改日期”的移动
            onDenied("task.drag.denied.to_overdue")
            return true
        }
        
        // 构造“移动后的目标分组数组”（只用于计算 taskSort，不直接写库）
        let groupTasks = groupTasksProvider()
        var simulated = groupTasks.filter { $0.taskId != draggedTask.taskId }
        
        let safeIndex: Int = {
            // placeholderIndex 是“拖拽过程中”实时更新的落点
            if placeholderGroup == destinationGroupType, let placeholderIndex {
                return min(max(placeholderIndex, 0), simulated.count)
            }
            // 没有占位索引时，默认按“落到该行”来插入
            let stableIndex = simulated.firstIndex(where: { $0.taskId == destinationTask.taskId }) ?? simulated.count
            return min(max(stableIndex, 0), simulated.count)
        }()
        simulated.insert(draggedTask, at: safeIndex)
        
        // 规则：拖拽不能跨“未完成/已完成”的边界（与 DayTodo 一致）
        if let deniedKey = TDTaskListDragValidation.deniedMessageKey(
            draggedComplete: draggedTask.complete,
            in: simulated,
            at: safeIndex
        ) {
            onDenied(deniedKey)
            return true
        }
        
        // 只在“同完成状态”区间内找上下相邻的 taskSort（更符合用户预期）
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
                print("❌ 分组列表拖拽移动失败: \(error)")
            }
        }
        return true
    }
}

/// 分组列表：落到“组头/空白区域”的 drop 代理（用于空分组、收起分组也能作为目标）
private struct TDTaskListGroupHeaderDropDelegate: DropDelegate {
    let destinationGroupType: TDTaskGroupType
    let destinationIndexProvider: () -> Int
    let groupTasksProvider: () -> [TDMacSwiftDataListModel]
    
    @Binding var draggedTask: TDMacSwiftDataListModel?
    @Binding var placeholderGroup: TDTaskGroupType?
    @Binding var placeholderIndex: Int?
    @Binding var autoScrollDirection: Int
    
    let context: ModelContext
    let onDenied: (String) -> Void
    
    func dropEntered(info: DropInfo) {
        guard let draggedTask else { return }
        _ = info
        
        if destinationGroupType.isOverdueGroup, !draggedTask.isOverdueTask {
            return
        }
        
        withAnimation(.easeInOut(duration: 0.12)) {
            placeholderGroup = destinationGroupType
            placeholderIndex = min(max(destinationIndexProvider(), 0), groupTasksProvider().filter { $0.taskId != draggedTask.taskId }.count)
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        _ = info
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        defer {
            placeholderIndex = nil
            placeholderGroup = nil
            draggedTask = nil
            autoScrollDirection = 0
        }
        _ = info
        guard let draggedTask else { return true }
        
        // 业务规则 1：任何任务不允许移动到“过期分组”
        if destinationGroupType.isOverdueGroup, !draggedTask.isOverdueTask {
            onDenied("task.drag.denied.to_overdue")
            return true
        }
        
        // 业务规则 2：过期任务不允许跨“过期已达成/过期未达成”分组
        if draggedTask.isOverdueTask, destinationGroupType.isOverdueGroup {
            let sourceOverdueGroup: TDTaskGroupType = draggedTask.complete ? .overdueCompleted : .overdueUncompleted
            if destinationGroupType != sourceOverdueGroup {
                onDenied("task.drag.denied.overdue_cross")
                return true
            }
        }
        
        // 计算目标分组的 todoTime（移动到非过期分组时会改日期；过期分组仅允许内部排序）
        let targetTodoTime = destinationGroupType.targetTodoTimeForDrop()
        if destinationGroupType.isOverdueGroup, targetTodoTime != nil {
            onDenied("task.drag.denied.to_overdue")
            return true
        }
        
        let groupTasks = groupTasksProvider()
        var simulated = groupTasks.filter { $0.taskId != draggedTask.taskId }
        let safeIndex = min(max(destinationIndexProvider(), 0), simulated.count)
        simulated.insert(draggedTask, at: safeIndex)
        
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
                print("❌ 分组列表组头拖拽移动失败: \(error)")
            }
        }
        return true
    }
}

/// 分组列表：拖拽靠边自动滚动
private struct TDTaskListAutoScrollEdgeDropDelegate: DropDelegate {
    let direction: Int
    @Binding var autoScrollDirection: Int
    
    func dropEntered(info: DropInfo) {
        autoScrollDirection = direction
        _ = info
    }
    
    func dropExited(info: DropInfo) {
        autoScrollDirection = 0
        _ = info
    }
    
    func performDrop(info: DropInfo) -> Bool {
        autoScrollDirection = 0
        _ = info
        return true
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

private struct TDTaskEmptyDropTargetRow: View {
    let themeManager: TDThemeManager
    let title: String
    
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .stroke(themeManager.descriptionTextColor.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .frame(width: 18, height: 18)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(themeManager.descriptionTextColor.opacity(0.8))
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

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
