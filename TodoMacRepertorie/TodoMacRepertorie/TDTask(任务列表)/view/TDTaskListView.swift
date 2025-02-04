//
//  TDTaskListView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/29.
//

import SwiftUI
import SwiftData

struct TDTaskListView: View {
    @StateObject private var mainViewModel = TDMainViewModel.shared
    @StateObject private var themeManager = TDThemeManager.shared
    
    var body: some View {
        List {
            ForEach(mainViewModel.groupedTasks.keys.sorted(), id: \.rawValue) { group in
                if let tasks = mainViewModel.groupedTasks[group], !tasks.isEmpty {
                    Section {
                        ForEach(tasks, id: \.taskId) { task in
                            TDTaskRow(task: task)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task {
                                            // 删除任务
                                            task.delete = true
                                            try? await TDModelContainer.shared.perform {
                                                try TDModelContainer.shared.save()
                                            }
                                            await mainViewModel.refreshTasks()
                                        }
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button(action: {
                                        Task {
                                            // 删除任务
                                            task.delete = true
                                            try? await TDModelContainer.shared.perform {
                                                try TDModelContainer.shared.save()
                                            }
                                            await mainViewModel.refreshTasks()
                                        }
                                    }) {
                                        Label("删除", systemImage: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                        }
                        .onMove { from, to in
                            // TODO: 处理任务重新排序
                            // 需要更新 taskSort 字段并保存
                        }
                    } header: {
                        if mainViewModel.selectedCategory?.categoryId == -100 {
                            // DayTodo 模式下显示空的组头，但保持一定高度
                            Color.clear
                                .frame(height: 60)
                                .listRowBackground(Color.clear)
                        } else {
                            TDTaskGroupHeader(group: group, taskCount: tasks.count)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
    }
}
//
//// 任务组区域视图
//struct TDTaskGroupSection: View {
//    let group: TDMacTaskGroup
//    let tasks: [TDMacSwiftDataListModel]
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            // 组标题
//            Text(group.title)
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            // 任务列表
//            ForEach(tasks) { task in
//                TDTaskRow(task: task)
//            }
//        }
//    }
//}
//
//// 单个任务行视图
//struct TDTaskRow: View {
//    let task: TDMacSwiftDataListModel
//    
//    var body: some View {
//        HStack {
//            // 完成状态复选框
//            Image(systemName: task.complete ? "checkmark.circle.fill" : "circle")
//                .foregroundColor(task.complete ? .green : .gray)
//            
//            // 任务内容
//            VStack(alignment: .leading) {
//                Text(task.taskContent ?? "")
//                    .strikethrough(task.complete)
//                
//                if let describe = task.taskDescribe, !describe.isEmpty {
//                    Text(describe)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//            }
//            
//            Spacer()
//            
//            // 如果有日期，显示日期
//            if let todoTime = task.todoTime {
//                Text(todoTime.toDate.formattedString)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//        }
//        .padding()
//        .background(Color.red)
//        .cornerRadius(8)
//        .shadow(radius: 1)
//    }
//}
//
//#Preview {
//    let config = ModelConfiguration(isStoredInMemoryOnly: true)
//    let container = try! ModelContainer(for: TDMacSwiftDataListModel.self, configurations: config)
//    
//    TDTaskListView(modelContext: container.mainContext, selectedCategory: .constant(TDSliderBarModel()))
//}
