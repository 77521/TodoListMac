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
//struct TDTaskListView: View {
//    @Environment(\.modelContext) private var modelContext
//    @StateObject private var viewModel: TDMacListViewModel
//    @Binding var selectedCategory: TDSliderBarModel?
//
//    init(modelContext: ModelContext, selectedCategory: Binding<TDSliderBarModel?>) {
//        _viewModel = StateObject(wrappedValue: TDMacListViewModel(modelContext: modelContext))
//        self._selectedCategory = selectedCategory
//
//    }
//    
//    var body: some View {
//        Group {
//            if viewModel.isLoading {
//                ProgressView()
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            } else {
//                taskListContent
//            }
//        }
//        .task {
//            // 初始加载数据
//            await viewModel.initializeAfterLogin()
//        }
//    }
//    
//    private var taskListContent: some View {
//        VStack {
//            // 顶部工具栏
//            HStack {
//                // 同步按钮
//                Button {
//                    Task {
//                        await viewModel.syncAndRefresh()
//                    }
//                } label: {
//                    Image(systemName: "arrow.clockwise")
//                }
//                .disabled(viewModel.isLoading)
//                
//                Spacer()
//                
//                // 其他工具栏按钮...
//            }
//            .padding()
//            
//            // 任务列表
//            ScrollView {
//                LazyVStack(spacing: 16) {
//                    ForEach(TDMacTaskGroup.allCases, id: \.self) { group in
//                        if let tasks = viewModel.taskGroups[group], !tasks.isEmpty {
//                            TDTaskGroupSection(group: group, tasks: tasks)
//                        }
//                    }
//                }
//                .padding()
//            }
//        }
//    }
//
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
