//
//  TDTaskListView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/29.
//

import SwiftUI
import SwiftData

/// 任务列表视图，负责分组和渲染所有任务
struct TDTaskListView: View {
    @EnvironmentObject private var mainViewModel: TDMainViewModel
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var settingManager: TDSettingManager

    var body: some View {
        let isDayTodo = mainViewModel.selectedCategory?.categoryId == -100
        let sortedGroups = mainViewModel.groupedTasks.keys.sorted()
        
        if isDayTodo {
            dayTodoListView(sortedGroups: sortedGroups)
        } else {
            normalListView(sortedGroups: sortedGroups)
        }
    }
    
    // MARK: - DayTodo 模式视图
    @ViewBuilder
    private func dayTodoListView(sortedGroups: [TDTaskGroup]) -> some View {
        List {
            ForEach(sortedGroups, id: \.rawValue) { group in
                if let tasks = mainViewModel.groupedTasks[group], !tasks.isEmpty {
                    taskRowsSection(tasks: tasks, showHeader: false)
                }
            }
            topSpacerRow()
        }
        .listStyle(.plain)
        .background(Color(.windowBackgroundColor))
    }
    
    // MARK: - 普通模式视图
    @ViewBuilder
    private func normalListView(sortedGroups: [TDTaskGroup]) -> some View {
        List {
            ForEach(sortedGroups, id: \.rawValue) { group in
                if let tasks = mainViewModel.groupedTasks[group], !tasks.isEmpty {
                    Section {
                        taskRowsSection(tasks: tasks, showHeader: true)
                    } header: {
                        TDTaskGroupHeader(group: group, taskCount: tasks.count)
                            .frame(height: 36)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - 任务行区域
    @ViewBuilder
    private func taskRowsSection(tasks: [TDMacSwiftDataListModel], showHeader: Bool) -> some View {
        ForEach(tasks, id: \.taskId) { task in
            TDTaskRow(task: task)
                .listRowInsets(showHeader ? EdgeInsets() : EdgeInsets())
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    deleteButton(for: task)
                }
                .contextMenu {
                    deleteContextMenu(for: task)
                }
        }
        .onMove { from, to in
            handleTaskMove(from: from, to: to, in: tasks)
        }
    }
    
    // MARK: - 删除按钮
    @ViewBuilder
    private func deleteButton(for task: TDMacSwiftDataListModel) -> some View {
        Button(role: .destructive) {
            deleteTask(task)
        } label: {
            Label("删除", systemImage: "trash")
        }
    }
    
    // MARK: - 删除上下文菜单
    @ViewBuilder
    private func deleteContextMenu(for task: TDMacSwiftDataListModel) -> some View {
        Button(action: {
            deleteTask(task)
        }) {
            Label("删除", systemImage: "trash")
                .foregroundColor(.red)
        }
    }
    
    // MARK: - 顶部空白行
    @ViewBuilder
    private func topSpacerRow() -> some View {
        Color.clear
            .frame(height: 80)
            .listRowInsets(EdgeInsets())
    }
    
    // MARK: - 删除任务操作
    private func deleteTask(_ task: TDMacSwiftDataListModel) {
        Task {
            await performDeleteTask(task)
        }
    }
    
    // MARK: - 异步删除任务
    @MainActor
    private func performDeleteTask(_ task: TDMacSwiftDataListModel) async {
        do {
            // 标记为删除
            task.delete = true
            task.status = "update"
            
            // 异步更新数据库
            try await TDQueryConditionManager.shared.updateLocalTaskFields([task])
            
            // 刷新界面
            try await mainViewModel.refreshTasks()
            
            // 同步到服务器
            try? await mainViewModel.syncAfterLogin()
        } catch {
            print("删除任务失败: \(error)")
        }
    }
    
    // MARK: - 处理任务移动
    private func handleTaskMove(from source: IndexSet, to destination: Int, in tasks: [TDMacSwiftDataListModel]) {
        Task {
            await performTaskMove(from: source, to: destination, in: tasks)
        }
    }
    
    // MARK: - 异步处理任务移动
    @MainActor
    private func performTaskMove(from source: IndexSet, to destination: Int, in tasks: [TDMacSwiftDataListModel]) async {
        // TODO: 实现任务重新排序逻辑
        // 1. 重新计算 taskSort 值
        // 2. 异步更新数据库
        // 3. 刷新界面
        print("任务移动: 从 \(source) 到 \(destination)")
    }
}


///// 任务列表视图，负责分组和渲染所有任务
//struct TDTaskListView: View {
//    @EnvironmentObject private var mainViewModel: TDMainViewModel
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @EnvironmentObject private var settingManager: TDSettingManager
//
//    var body: some View {
//        let isDayTodo = mainViewModel.selectedCategory?.categoryId == -100
//
//        if isDayTodo {
//            // DayTodo模式：无组头
//            List {
//                ForEach(mainViewModel.groupedTasks.keys.sorted(), id: \.rawValue) { group in
//                    if let tasks = mainViewModel.groupedTasks[group], !tasks.isEmpty {
//                        ForEach(tasks, id: \.taskId) { task in
//                            TDTaskRow(task: task)
//                                .listRowInsets(EdgeInsets())
//                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                                    Button(role: .destructive) {
//                                        Task {
//                                            task.delete = true
//                                            try? await TDModelContainer.shared.perform {
//                                                try TDModelContainer.shared.save()
//                                            }
//                                            await mainViewModel.refreshTasks()
//                                        }
//                                    } label: {
//                                        Label("删除", systemImage: "trash")
//                                    }
//                                }
//                                .contextMenu {
//                                    Button(action: {
//                                        Task {
//                                            task.delete = true
//                                            try? await TDModelContainer.shared.perform {
//                                                try TDModelContainer.shared.save()
//                                            }
//                                            await mainViewModel.refreshTasks()
//                                        }
//                                    }) {
//                                        Label("删除", systemImage: "trash")
//                                            .foregroundColor(.red)
//                                    }
//                                }
//                        }
//                        .onMove { from, to in
//                            // TODO: 处理任务重新排序
//                        }
//                    }
//                }
//                // 顶部空白
//                Color.clear
//                    .frame(height: 80)
//                    .listRowInsets(EdgeInsets())
//            }
//            .listStyle(.plain)
//            .background(Color(.windowBackgroundColor))
//        } else {
//            // 普通模式：有组头
//            List {
//                ForEach(mainViewModel.groupedTasks.keys.sorted(), id: \.rawValue) { group in
//                    if let tasks = mainViewModel.groupedTasks[group], !tasks.isEmpty {
//                        Section {
//                            ForEach(tasks, id: \.taskId) { task in
//                                TDTaskRow(task: task)
//                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                                        Button(role: .destructive) {
//                                            Task {
//                                                task.delete = true
//                                                try? await TDModelContainer.shared.perform {
//                                                    try TDModelContainer.shared.save()
//                                                }
//                                                await mainViewModel.refreshTasks()
//                                            }
//                                        } label: {
//                                            Label("删除", systemImage: "trash")
//                                        }
//                                    }
//                                    .contextMenu {
//                                        Button(action: {
//                                            Task {
//                                                task.delete = true
//                                                try? await TDModelContainer.shared.perform {
//                                                    try TDModelContainer.shared.save()
//                                                }
//                                                await mainViewModel.refreshTasks()
//                                            }
//                                        }) {
//                                            Label("删除", systemImage: "trash")
//                                                .foregroundColor(.red)
//                                        }
//                                    }
//                            }
//                            .onMove { from, to in
//                                // TODO: 处理任务重新排序
//                            }
//                        } header: {
//                            TDTaskGroupHeader(group: group, taskCount: tasks.count)
//                                .frame(height: 36)
//                        }
//                    }
//                }
//            }
//            .listStyle(.sidebar)
//            .scrollContentBackground(.hidden)
//        }
//    }
//}
//struct TDTaskListView: View {
//    @StateObject private var mainViewModel = TDMainViewModel.shared
//    @StateObject private var themeManager = TDThemeManager.shared
//    
//    var body: some View {
//        List {
//            ForEach(mainViewModel.groupedTasks.keys.sorted(), id: \.rawValue) { group in
//                if let tasks = mainViewModel.groupedTasks[group], !tasks.isEmpty {
//                    Section {
//                        ForEach(tasks, id: \.taskId) { task in
//                            TDTaskRow(task: task)
//                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                                    Button(role: .destructive) {
//                                        Task {
//                                            // 删除任务
//                                            task.delete = true
//                                            try? await TDModelContainer.shared.perform {
//                                                try TDModelContainer.shared.save()
//                                            }
//                                            await mainViewModel.refreshTasks()
//                                        }
//                                    } label: {
//                                        Label("删除", systemImage: "trash")
//                                    }
//                                }
//                                .contextMenu {
//                                    Button(action: {
//                                        Task {
//                                            // 删除任务
//                                            task.delete = true
//                                            try? await TDModelContainer.shared.perform {
//                                                try TDModelContainer.shared.save()
//                                            }
//                                            await mainViewModel.refreshTasks()
//                                        }
//                                    }) {
//                                        Label("删除", systemImage: "trash")
//                                            .foregroundColor(.red)
//                                    }
//                                }
//                        }
//                        .onMove { from, to in
//                            // TODO: 处理任务重新排序
//                            // 需要更新 taskSort 字段并保存
//                        }
//                    } header: {
//                        if mainViewModel.selectedCategory?.categoryId == -100 {
//                            // DayTodo 模式下显示空的组头，但保持一定高度
//                            Color.clear
//                                .frame(height: 0)
//                                .listRowBackground(Color.clear)
//                        } else {
//                            TDTaskGroupHeader(group: group, taskCount: tasks.count)
//                        }
//                    }
//                }
//            }
//        }
//        .listStyle(.inset)
//        .scrollContentBackground(.hidden)
////        .background(.ultraThinMaterial)
//    }
//}
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
