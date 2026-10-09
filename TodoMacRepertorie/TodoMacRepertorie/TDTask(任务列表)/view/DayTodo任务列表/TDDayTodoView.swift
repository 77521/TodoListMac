//
//  TDDayTodoView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData

// MARK: - DayTodo 主视图

/// DayTodo 界面 - 显示今天的任务（List / NSTableView 虚拟化，大量数据只渲染可见行）
///
/// 拖拽排序跟分类清单同一套 begin → hoverMove → commit：
/// - 维护一份当前顺序 `taskDragOrder`（角色等同 categorySource）
/// - hover 只改内存顺序，松手才写 taskSort + 同步
/// - DayTodo 是扁平列表，没有文件夹
///
/// 向下移动必须用 Array.move 的标准偏移：`to > from ? to + 1 : to`。
/// 若先 remove 再按「删除后」的 destination 下标 insert，拖到下一行会插回原位
/// （两条数据时表现为只能往上拖、往下拖不动）。
struct TDDayTodoView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var mainViewModel = TDMainViewModel.shared

    @Query private var allTasks: [TDMacSwiftDataListModel]

    @State private var draggedTask: TDMacSwiftDataListModel?
    @State private var dragAutoScrollDirection: Int = 0

    /// 拖拽期间实际渲染用的顺序，角色等同分类清单的 categorySource
    @State private var taskDragOrder: [TDMacSwiftDataListModel] = []

    private let selectedDate: Date
    private let selectedCategory: TDSliderBarModel

    init(selectedDate: Date, category: TDSliderBarModel) {
        self.selectedDate = selectedDate
        self.selectedCategory = category
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getDayTodoQuery(selectedDate: selectedDate)
        _allTasks = Query(filter: predicate, sort: sortDescriptors)
    }

    /// 列表实际展示的数据：拖拽中用内存顺序；未拖且缓存还没铺上时先用 @Query 结果
    private var displayTasks: [TDMacSwiftDataListModel] {
        taskDragOrder.isEmpty ? allTasks : taskDragOrder
    }

    /// 把 taskDragOrder 跟 allTasks 对齐；拖拽过程中不能被打断
    private func syncTaskDragOrder() {
        guard draggedTask == nil else { return }
        guard taskDragOrder.map(\.taskId) != allTasks.map(\.taskId) else { return }
        taskDragOrder = allTasks
    }

    var body: some View {
        let isMultiSelect = mainViewModel.isMultiSelectMode
        let selectedTasks = mainViewModel.selectedTasks
        let selectedTaskId = mainViewModel.selectedTask?.taskId
        let selectedTaskIds = Set(selectedTasks.map(\.taskId))

        VStack(spacing: 0) {
            TDWeekDatePickerView()
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color(themeManager.backgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

            TDTaskInputView(todoTimeOverride: selectedDate.startOfDayTimestamp)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

            listContentView(
                isMultiSelect: isMultiSelect,
                selectedTaskId: selectedTaskId,
                selectedTaskIds: selectedTaskIds
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if isMultiSelect {
                TDMultiSelectActionBar(allTasks: allTasks)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(Color(themeManager.backgroundColor).ignoresSafeArea(.container, edges: .all))
    }

    // MARK: - 列表内容

    @ViewBuilder
    private func listContentView(
        isMultiSelect: Bool,
        selectedTaskId: String?,
        selectedTaskIds: Set<String>
    ) -> some View {
        if allTasks.isEmpty {
            TDEmptyStateView(
                icon: "checkmark.circle",
                title: "今天没有任务",
                subtitle: "点击上方输入框添加新任务"
            )
        } else {
            let items = displayTasks
            ScrollViewReader { proxy in
                List {
                    ForEach(Array(items.enumerated()), id: \.element.taskId) { index, task in
                        TDTaskRowView(
                            task: task,
                            category: selectedCategory,
                            orderNumber: index + 1,
                            isFirstRow: index == 0,
                            isLastRow: index == items.count - 1,
                            isMultiSelectMode: isMultiSelect,
                            isSelectedTask: selectedTaskId == task.taskId,
                            isMultiSelected: selectedTaskIds.contains(task.taskId),
                            onCopySuccess: {
                                TDToastCenter.shared.show(
                                    "copy_success_simple", type: .success, position: .bottom
                                )
                            }
                        )
                        .equatable()
                        .id(task.taskId)
                        .contentShape(Rectangle())
                        .onDrag({
                            beginDayTodoDrag(task)
                            return NSItemProvider(object: task.taskId as NSString)
                        }, preview: {
                            TDTaskRowView(
                                task: task,
                                category: selectedCategory,
                                orderNumber: nil,
                                isFirstRow: false,
                                isLastRow: false,
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
                        .onDrop(of: [.text], delegate: TDDayTodoTaskDropDelegate(
                            destinationTaskId: task.taskId,
                            draggedTask: $draggedTask,
                            onHoverMove: { draggedId, destinationId in
                                hoverMoveDayTodoTask(draggedId: draggedId, destinationId: destinationId)
                            },
                            onCommit: { commitDayTodoDrag() }
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
                .animation(.easeInOut(duration: 0.15), value: items.map(\.taskId))
                .onAppear {
                    syncTaskDragOrder()
                    scrollToSelectedTask(proxy: proxy)
                }
                .onChange(of: allTasks) { oldTasks, newTasks in
                    syncTaskDragOrder()
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
                .onReceive(Timer.publish(every: 0.06, on: .main, in: .common).autoconnect()) { _ in
                    guard draggedTask != nil, dragAutoScrollDirection != 0 else { return }
                    advanceDraggedTaskOneStep(direction: dragAutoScrollDirection, proxy: proxy)
                }
                .overlay {
                    if draggedTask != nil {
                        edgeScrollOverlay()
                    }
                }
            }
        }
    }

    // MARK: - 拖拽生命周期（begin / hoverMove / commit）

    private func beginDayTodoDrag(_ task: TDMacSwiftDataListModel) {
        if taskDragOrder.map(\.taskId) != allTasks.map(\.taskId) {
            taskDragOrder = allTasks
        }
        draggedTask = task
    }

    /// 悬停重排：下标一律按「当前数组、删除前」计算，向下时 toOffset = to + 1
    private func hoverMoveDayTodoTask(draggedId: String, destinationId: String) {
        guard draggedId != destinationId else { return }
        guard let from = taskDragOrder.firstIndex(where: { $0.taskId == draggedId }),
              let to = taskDragOrder.firstIndex(where: { $0.taskId == destinationId }) else { return }
        var updated = taskDragOrder
        updated.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        taskDragOrder = updated
    }

    private func moveDraggedTask(to targetIndex: Int) {
        guard let dragged = draggedTask,
              let from = taskDragOrder.firstIndex(where: { $0.taskId == dragged.taskId }) else { return }
        let to = min(max(targetIndex, 0), taskDragOrder.count - 1)
        guard to != from else { return }
        var updated = taskDragOrder
        updated.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        taskDragOrder = updated
    }

    private func commitDayTodoDrag() {
        defer {
            draggedTask = nil
            dragAutoScrollDirection = 0
        }
        guard let dragged = draggedTask else { return }
        guard let idx = taskDragOrder.firstIndex(where: { $0.taskId == dragged.taskId }) else { return }

        if let deniedKey = TDDragSortValidation.deniedMessageKey(
            draggedComplete: dragged.complete, in: taskDragOrder, at: idx
        ) {
            TDToastCenter.shared.show(deniedKey, type: .info, position: .bottom)
            taskDragOrder = allTasks
            return
        }

        let (top, next) = TDTaskDragSortHelper.findTopAndNextTaskSort(
            in: taskDragOrder, at: idx, where: { $0.complete == dragged.complete }
        )
        var newSort = TDTaskSortCalculator.getMoveCurrentTaskSortValue(
            currentTaskSort: dragged.taskSort, topTaskSort: top, nextTaskSort: next
        )
        if top == nil, next == nil { newSort = TDAppConfig.defaultTaskSort }

        let updated = dragged
        updated.taskSort = newSort

        let context = modelContext
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

    private func advanceDraggedTaskOneStep(direction: Int, proxy: ScrollViewProxy) {
        guard let dragged = draggedTask,
              let idx = taskDragOrder.firstIndex(where: { $0.taskId == dragged.taskId }) else { return }
        withAnimation(.easeInOut(duration: 0.1)) {
            moveDraggedTask(to: idx + direction)
            proxy.scrollTo(dragged.taskId, anchor: direction < 0 ? .top : .bottom)
        }
    }

    @ViewBuilder
    private func edgeScrollOverlay() -> some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 44)
                .contentShape(Rectangle())
                .onDrop(of: [.text], delegate: TDDayTodoEdgeDropDelegate(
                    direction: -1,
                    draggedTask: $draggedTask,
                    autoScrollDirection: $dragAutoScrollDirection,
                    onEnterEdge: { moveDraggedTask(to: 0) },
                    onCommit: { commitDayTodoDrag() }
                ))
            Spacer(minLength: 0)
            Color.clear
                .frame(height: 44)
                .contentShape(Rectangle())
                .onDrop(of: [.text], delegate: TDDayTodoEdgeDropDelegate(
                    direction: 1,
                    draggedTask: $draggedTask,
                    autoScrollDirection: $dragAutoScrollDirection,
                    onEnterEdge: { moveDraggedTask(to: taskDragOrder.count - 1) },
                    onCommit: { commitDayTodoDrag() }
                ))
        }
        .allowsHitTesting(true)
    }
}

// MARK: - DropDelegate：行

private struct TDDayTodoTaskDropDelegate: DropDelegate {
    let destinationTaskId: String
    @Binding var draggedTask: TDMacSwiftDataListModel?
    let onHoverMove: (_ draggedId: String, _ destinationId: String) -> Void
    let onCommit: () -> Void

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedTask, dragged.taskId != destinationTaskId else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            onHoverMove(dragged.taskId, destinationTaskId)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        onCommit()
        return true
    }
}

// MARK: - DropDelegate：边缘区域

private struct TDDayTodoEdgeDropDelegate: DropDelegate {
    let direction: Int
    @Binding var draggedTask: TDMacSwiftDataListModel?
    @Binding var autoScrollDirection: Int
    let onEnterEdge: () -> Void
    let onCommit: () -> Void

    func dropEntered(info: DropInfo) {
        autoScrollDirection = direction
        guard draggedTask != nil else { return }
        withAnimation(.easeInOut(duration: 0.12)) {
            onEnterEdge()
        }
    }

    func dropExited(info: DropInfo) { autoScrollDirection = 0 }

    func performDrop(info: DropInfo) -> Bool {
        onCommit()
        return true
    }
}

// MARK: - 拖拽排序校验

private enum TDDragSortValidation {
    static func deniedMessageKey(
        draggedComplete: Bool,
        in moved: [TDMacSwiftDataListModel],
        at index: Int
    ) -> String? {
        let top = index > 0 ? moved[index - 1] : nil
        let next = index < moved.count - 1 ? moved[index + 1] : nil
        if draggedComplete, let next, !next.complete { return "task.drag.denied.to_uncompleted" }
        if !draggedComplete, let top, top.complete { return "task.drag.denied.to_completed" }
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
