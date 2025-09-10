//
//  TDSubtaskListView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI

/// 子任务列表视图
struct TDSubtaskListView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    
    // 任务数据
    @Bindable var task: TDMacSwiftDataListModel
    
    // 拖拽状态
    @State private var draggedItem: TDMacSwiftDataListModel.SubTask?
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 0) {
            // 子任务列表（如果有数据）
            if !task.subTaskList.isEmpty {
                ForEach(Array(task.subTaskList.enumerated()), id: \.element.id) { index, subTask in
                    TDSubtaskRowView(
                        task: task,
                        index: index,
                        subTaskId: subTask.id,
                        onToggleComplete: { isComplete in
                            // 使用 ID 查找当前子任务的索引
                            if let currentIndex = task.subTaskList.firstIndex(where: { $0.id == subTask.id }) {
                                task.subTaskList[currentIndex].isComplete = isComplete
                                updateTask()
                            }
                        },
                        onDelete: {
                            // 使用 ID 查找当前子任务的索引
                            if let currentIndex = task.subTaskList.firstIndex(where: { $0.id == subTask.id }) {
                                task.subTaskList.remove(at: currentIndex)
                                updateTask()
                            }
                        },
                        onContentChanged: {
                            updateTask()
                        }
                    )
                    .offset(draggedItem?.id == subTask.id ? dragOffset : .zero)
                    .opacity(draggedItem?.id == subTask.id ? 0.8 : 1.0)
                    .scaleEffect(draggedItem?.id == subTask.id ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: dragOffset)
                    .animation(.easeInOut(duration: 0.2), value: draggedItem?.id)
                    .onDrag {
                        draggedItem = subTask
                        return NSItemProvider(object: subTask.id as NSString)
                    }
                    .onDrop(of: [.text], delegate: SubtaskDropDelegate(
                        destinationItem: subTask,
                        task: task,
                        draggedItem: $draggedItem,
                        dragOffset: $dragOffset,
                        onMove: moveSubTasks(from:to:),
                        onDropCompleted: {
                            // 拖拽完成后的同步回调
                            updateTask()
                        }
                    ))

                }

            }
            
        }
    }
    
    // MARK: - 私有方法
    /// 移动子任务（通过索引）
    private func moveSubTasks(from sourceIndex: Int, to destinationIndex: Int) {
        print("移动子任务：从索引 \(sourceIndex) 到索引 \(destinationIndex)")
        print("当前子任务数量：\(task.subTaskList.count)")
        
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0 && sourceIndex < task.subTaskList.count,
              destinationIndex >= 0 && destinationIndex < task.subTaskList.count else {
            print("移动失败：索引无效")
            return
        }
        withAnimation {
            
            let item = task.subTaskList.remove(at: sourceIndex)
            print("移除项目：\(item.content)")
            
            task.subTaskList.insert(item, at: destinationIndex)
            print("插入到索引：\(destinationIndex)")
            
            print("移动完成，新的子任务顺序：")
            for (index, subTask) in task.subTaskList.enumerated() {
                print("  \(index): \(subTask.content)")
            }
        }
        
//        updateTask()
    }
    /// 更新任务数据
    private func updateTask() {
        task.standbyStr2 = task.generateSubTasksString()

        Task {
            do {
                try await TDQueryConditionManager.shared.updateLocalTaskWithModel(
                    updatedTask: task,
                    context: modelContext
                )
                await TDMainViewModel.shared.performSyncSeparately()
                print("✅ 子任务更新成功")
            } catch {
                print("❌ 子任务更新失败: \(error)")
            }
        }
    }
}


struct SubtaskDropDelegate: DropDelegate {
    let destinationItem: TDMacSwiftDataListModel.SubTask
    let task: TDMacSwiftDataListModel
    @Binding var draggedItem: TDMacSwiftDataListModel.SubTask?
    @Binding var dragOffset: CGSize
    let onMove: (Int, Int) -> Void
    let onDropCompleted: (() -> Void)?

    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem,
              draggedItem.id != destinationItem.id else {
            print("拖拽进入：跳过，源项目或目标项目无效")
            return
        }
        
        // 计算拖拽位置
        let draggedIndex = task.subTaskList.firstIndex(where: { $0.id == draggedItem.id }) ?? 0
        let destinationIndex = task.subTaskList.firstIndex(where: { $0.id == destinationItem.id }) ?? 0
        
        print("拖拽进入：从索引 \(draggedIndex) 移动到索引 \(destinationIndex)")
        print("拖拽项目：\(draggedItem.content)")
        print("目标项目：\(destinationItem.content)")
        
        // 执行移动
        onMove(draggedIndex, destinationIndex)
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        print("拖拽更新：允许移动操作")
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        print("拖拽完成：重置状态")
        // 拖拽完成后进行同步
        onDropCompleted?()
        // 重置拖拽状态
        draggedItem = nil
        dragOffset = .zero
        return true
    }
    
    func dropExited(info: DropInfo) {
        print("拖拽退出：重置状态")
        // 拖拽退出时重置状态
        if draggedItem?.id == destinationItem.id {
            dragOffset = .zero
        }
    }
}


//#Preview
