//
//  TDDayTodoView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData

// MARK: - DayTodo 主视图

/// DayTodo 界面 - 显示今天的任务（使用 SwiftUI List / NSTableView 后端，丝滑滚动无卡顿）
struct TDDayTodoView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var mainViewModel = TDMainViewModel.shared

    @Query private var allTasks: [TDMacSwiftDataListModel]

    @State private var draggedTask:          TDMacSwiftDataListModel?
    @State private var dragPlaceholderIndex: Int?
    @State private var dragAutoScrollDirection: Int = 0

    private let selectedDate:     Date
    private let selectedCategory: TDSliderBarModel

    init(selectedDate: Date, category: TDSliderBarModel) {
        self.selectedDate     = selectedDate
        self.selectedCategory = category
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getDayTodoQuery(selectedDate: selectedDate)
        _allTasks = Query(filter: predicate, sort: sortDescriptors)
    }

    // MARK: - 拖拽渲染数据
    // 使用稳定 id（taskId）避免 List 行因 id 变化而闪烁

    private var dragRenderItems: [TDDayDragItem] {
        guard !allTasks.isEmpty else { return [] }
        guard let dragged = draggedTask else {
            return allTasks.map { TDDayDragItem(id: $0.taskId, task: $0, isPlaceholder: false) }
        }
        var base = allTasks.filter { $0.taskId != dragged.taskId }
        let safeIdx = min(max(dragPlaceholderIndex ?? 0, 0), base.count)
        base.insert(dragged, at: safeIdx)
        return base.enumerated().map { idx, task in
            let isHolder = task.taskId == dragged.taskId && idx == safeIdx
            return TDDayDragItem(id: task.taskId, task: task, isPlaceholder: isHolder)
        }
    }

    var body: some View {
        let isMultiSelect  = mainViewModel.isMultiSelectMode
        let selectedTasks  = mainViewModel.selectedTasks
        let selectedTaskId = mainViewModel.selectedTask?.taskId

        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                Color(themeManager.backgroundColor)
                    .ignoresSafeArea(.container, edges: .all)

                listContentView(
                    isMultiSelect:  isMultiSelect,
                    selectedTaskId: selectedTaskId,
                    selectedTasks:  selectedTasks
                )
                .padding(.top, 50)

                // 顶部日期选择器（固定在列表上方）
                TDWeekDatePickerView()
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color(themeManager.backgroundColor))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                // 悬浮任务输入框
                TDTaskInputView()
                    .padding(.horizontal, 16)
                    .padding(.top, 80)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            // 多选操作栏
            if isMultiSelect {
                TDMultiSelectActionBar(allTasks: allTasks)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - 列表内容

    @ViewBuilder
    private func listContentView(
        isMultiSelect:  Bool,
        selectedTaskId: String?,
        selectedTasks:  [TDMacSwiftDataListModel]
    ) -> some View {
        if allTasks.isEmpty {
            TDEmptyStateView(
                icon:     "checkmark.circle",
                title:    "今天没有任务",
                subtitle: "点击上方输入框添加新任务"
            )
        } else {
            let items = dragRenderItems
            ScrollViewReader { proxy in
                List {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        TDTaskRowView(
                            task:             item.task,
                            category:         selectedCategory,
                            orderNumber:      index + 1,
                            isFirstRow:       index == 0,
                            isLastRow:        index == items.count - 1,
                            isMultiSelectMode: isMultiSelect,
                            isSelectedTask:   selectedTaskId == item.task.taskId,
                            isMultiSelected:  selectedTasks.contains(where: { $0.taskId == item.task.taskId }),
                            onCopySuccess: {
                                TDToastCenter.shared.show(
                                    "copy_success_simple", type: .success, position: .bottom
                                )
                            }
                        )
                        .equatable()   // props 完全一致时跳过 body 重执行
                        .id(item.id)
                        // 占位行外观（拖拽时）
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(themeManager.color(level: 5), lineWidth: 1.4)
                                .opacity(item.isPlaceholder ? 1 : 0)
                        )
                        .opacity(item.isPlaceholder ? 0.55 : 1)
                        // 拖拽启动
                        .onDrag({
                            guard !item.isPlaceholder else { return NSItemProvider() }
                            draggedTask          = item.task
                            dragPlaceholderIndex = allTasks.firstIndex(where: { $0.taskId == item.task.taskId }) ?? 0
                            return NSItemProvider(object: item.task.taskId as NSString)
                        }, preview: {
                            TDTaskRowView(
                                task:        item.task,
                                category:    selectedCategory,
                                orderNumber: nil,
                                isFirstRow:  false,
                                isLastRow:   false,
                                onCopySuccess: {}
                            )
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(Color(themeManager.backgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(themeManager.color(level: 5), lineWidth: 1.5)
                            )
                        })
                        // 拖拽落点
                        .onDrop(of: [.text], delegate: TDDayTodoTaskDropDelegate(
                            destinationTask:      item.task,
                            allTasksProvider:     { allTasks },
                            draggedTask:          $draggedTask,
                            placeholderIndex:     $dragPlaceholderIndex,
                            autoScrollDirection:  $dragAutoScrollDirection,
                            context:              modelContext,
                            onDenied: { key in
                                TDToastCenter.shared.show(key, type: .info, position: .bottom)
                            }
                        ))
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .scrollIndicators(.hidden)
                .environment(\.defaultMinListRowHeight, 44)
                .padding(.horizontal, -9)
                // 占位行过渡动画
                .animation(.easeInOut(duration: 0.15), value: dragPlaceholderIndex)
                // 初次加载时将已选中任务滚动至可见区域
                .onAppear { scrollToSelectedTask(proxy: proxy) }
                // 新任务添加后自动选中并滚动到可见区域
                .onChange(of: allTasks) { oldTasks, newTasks in
                    guard newTasks.count > oldTasks.count else { return }
                    let oldIds = Set(oldTasks.map { $0.taskId })
                    guard let newTask = newTasks.first(where: { !oldIds.contains($0.taskId) }) else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        mainViewModel.selectTask(newTask)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(newTask.taskId, anchor: .center)
                        }
                    }
                }
                // 边缘自动滚动（guard 保证只在拖拽时执行）
                .onReceive(Timer.publish(every: 0.06, on: .main, in: .common).autoconnect()) { _ in
                    guard draggedTask != nil, dragAutoScrollDirection != 0 else { return }
                    advancePlaceholder(proxy: proxy)
                }
                .overlay {
                    if draggedTask != nil {
                        edgeScrollOverlay(proxy: proxy)
                    }
                }
            }
        }
    }

    // MARK: - 自动滚动辅助

    private func scrollToSelectedTask(proxy: ScrollViewProxy) {
        guard let id = mainViewModel.selectedTask?.taskId else { return }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(id, anchor: .center)
            }
        }
    }

    private func advancePlaceholder(proxy: ScrollViewProxy) {
        guard let dragged = draggedTask else { return }
        let baseCount = max(allTasks.filter { $0.taskId != dragged.taskId }.count, 0)
        let next = min(max((dragPlaceholderIndex ?? 0) + dragAutoScrollDirection, 0), baseCount)
        if dragPlaceholderIndex != next { dragPlaceholderIndex = next }
        withAnimation(.easeInOut(duration: 0.1)) {
            proxy.scrollTo(dragged.taskId, anchor: dragAutoScrollDirection < 0 ? .top : .bottom)
        }
    }

    @ViewBuilder
    private func edgeScrollOverlay(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 44)
                .contentShape(Rectangle())
                .onDrop(of: [.text], delegate: TDDayTodoEdgeDropDelegate(
                    direction: -1,
                    destinationIndexProvider: { 0 },
                    allTasksProvider:    { allTasks },
                    draggedTask:         $draggedTask,
                    placeholderIndex:    $dragPlaceholderIndex,
                    autoScrollDirection: $dragAutoScrollDirection,
                    context:             modelContext,
                    onDenied: { key in TDToastCenter.shared.show(key, type: .info, position: .bottom) }
                ))
            Spacer(minLength: 0)
            Color.clear
                .frame(height: 44)
                .contentShape(Rectangle())
                .onDrop(of: [.text], delegate: TDDayTodoEdgeDropDelegate(
                    direction: 1,
                    destinationIndexProvider: {
                        guard let d = draggedTask else { return allTasks.count }
                        return allTasks.filter { $0.taskId != d.taskId }.count
                    },
                    allTasksProvider:    { allTasks },
                    draggedTask:         $draggedTask,
                    placeholderIndex:    $dragPlaceholderIndex,
                    autoScrollDirection: $dragAutoScrollDirection,
                    context:             modelContext,
                    onDenied: { key in TDToastCenter.shared.show(key, type: .info, position: .bottom) }
                ))
        }
        .allowsHitTesting(true)
    }
}

// MARK: - 拖拽数据模型

private struct TDDayDragItem: Identifiable {
    let id: String
    let task: TDMacSwiftDataListModel
    let isPlaceholder: Bool
}

// MARK: - DropDelegate：行

private struct TDDayTodoTaskDropDelegate: DropDelegate {
    let destinationTask:  TDMacSwiftDataListModel
    let allTasksProvider: () -> [TDMacSwiftDataListModel]

    @Binding var draggedTask:         TDMacSwiftDataListModel?
    @Binding var placeholderIndex:    Int?
    @Binding var autoScrollDirection: Int
    let context:  ModelContext
    let onDenied: (String) -> Void

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedTask, dragged.taskId != destinationTask.taskId else { return }
        let base = allTasksProvider().filter { $0.taskId != dragged.taskId }
        let idx  = base.firstIndex(where: { $0.taskId == destinationTask.taskId }) ?? base.count
        withAnimation(.easeInOut(duration: 0.15)) {
            if placeholderIndex != idx { placeholderIndex = idx }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        TDDayTodoDropLogic.performDrop(
            allTasksProvider:   allTasksProvider,
            draggedTask:        &draggedTask,
            placeholderIndex:   &placeholderIndex,
            autoScrollDirection: &autoScrollDirection,
            context:            context,
            onDenied:           onDenied
        )
    }
}

// MARK: - DropDelegate：边缘区域

private struct TDDayTodoEdgeDropDelegate: DropDelegate {
    let direction:                  Int
    let destinationIndexProvider:   () -> Int
    let allTasksProvider:           () -> [TDMacSwiftDataListModel]

    @Binding var draggedTask:         TDMacSwiftDataListModel?
    @Binding var placeholderIndex:    Int?
    @Binding var autoScrollDirection: Int
    let context:  ModelContext
    let onDenied: (String) -> Void

    func dropEntered(info: DropInfo) {
        autoScrollDirection = direction
        guard let dragged = draggedTask else { return }
        let baseCount = allTasksProvider().filter { $0.taskId != dragged.taskId }.count
        let idx = min(max(destinationIndexProvider(), 0), baseCount)
        withAnimation(.easeInOut(duration: 0.12)) { placeholderIndex = idx }
    }

    func dropExited(info: DropInfo) { autoScrollDirection = 0 }

    func performDrop(info: DropInfo) -> Bool {
        TDDayTodoDropLogic.performDrop(
            allTasksProvider:   allTasksProvider,
            draggedTask:        &draggedTask,
            placeholderIndex:   &placeholderIndex,
            autoScrollDirection: &autoScrollDirection,
            context:            context,
            onDenied:           onDenied
        )
    }
}

// MARK: - 松手写库逻辑（行/边缘复用）

private enum TDDayTodoDropLogic {
    static func performDrop(
        allTasksProvider:   () -> [TDMacSwiftDataListModel],
        draggedTask:        inout TDMacSwiftDataListModel?,
        placeholderIndex:   inout Int?,
        autoScrollDirection: inout Int,
        context:            ModelContext,
        onDenied:           (String) -> Void
    ) -> Bool {
        defer {
            placeholderIndex    = nil
            draggedTask         = nil
            autoScrollDirection = 0
        }
        guard let dragged = draggedTask else { return true }

        let allTasks = allTasksProvider()
        var simulated = allTasks.filter { $0.taskId != dragged.taskId }
        let safeIdx = min(max(placeholderIndex ?? 0, 0), simulated.count)
        simulated.insert(dragged, at: safeIdx)

        if let deniedKey = TDDragSortValidation.deniedMessageKey(
            draggedComplete: dragged.complete, in: simulated, at: safeIdx
        ) {
            onDenied(deniedKey); return true
        }

        let (top, next) = TDTaskDragSortHelper.findTopAndNextTaskSort(
            in: simulated, at: safeIdx, where: { $0.complete == dragged.complete }
        )
        var newSort = TDTaskSortCalculator.getMoveCurrentTaskSortValue(
            currentTaskSort: dragged.taskSort, topTaskSort: top, nextTaskSort: next
        )
        if top == nil, next == nil { newSort = TDAppConfig.defaultTaskSort }

        let updated = dragged
        updated.taskSort = newSort

        Task {
            do {
                _ = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(
                    updatedTask: updated, context: context
                )
                await TDMainViewModel.shared.performSyncSeparately()
            } catch {
                print("❌ DayTodo 拖拽排序更新失败: \(error)")
            }
        }
        return true
    }
}

// MARK: - 拖拽排序校验

private enum TDDragSortValidation {
    static func deniedMessageKey(
        draggedComplete: Bool,
        in moved:        [TDMacSwiftDataListModel],
        at index:        Int
    ) -> String? {
        let top  = index > 0               ? moved[index - 1] : nil
        let next = index < moved.count - 1 ? moved[index + 1] : nil
        if draggedComplete,  let next, !next.complete { return "task.drag.denied.to_uncompleted" }
        if !draggedComplete, let top, top.complete    { return "task.drag.denied.to_completed" }
        return nil
    }
}

// MARK: - Preview

#Preview {
    TDDayTodoView(selectedDate: Date(), category: {
        let defaults = TDSliderBarModel.defaultItems(settingManager: TDSettingManager.shared)
        return defaults.first(where: { $0.categoryId == -100 }) ?? defaults[0]
    }())
    .environmentObject(TDThemeManager.shared)
}
