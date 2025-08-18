//
//  TDDayTodoView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData

/// DayTodo 界面 - 显示今天的任务
@MainActor
struct TDDayTodoView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    
    // 使用 @Query 来实时监控任务数据
    @Query private var dayTodoTasks: [TDMacSwiftDataListModel]
//    @State private var processedTasks: [TDMacSwiftDataListModel] = []
    
    init(selectedDate: Date, category: TDSliderBarModel) {
        // 根据传入的日期和分类初始化查询条件
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getDayTodoQuery(selectedDate: selectedDate)

        _dayTodoTasks = Query(
            filter: predicate,
            sort: sortDescriptors
        )
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color(.windowBackgroundColor)
                .ignoresSafeArea(.container, edges: .all)
            
            VStack(spacing: 0) {
                // 顶部日期选择器 - 紧贴左右上边缘
                TDWeekDatePickerView()
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                
                // 悬浮任务输入框 - 紧贴左右边缘
                TDTaskInputView()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                
                // 任务列表区域
                if dayTodoTasks.isEmpty {
                    // 没有任务时显示空状态
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("今天没有任务")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("点击上方输入框添加新任务")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 60)
                } else {
                    // 使用 List 显示任务数据，性能更好
                    List(dayTodoTasks, id: \.id) { task in
                        TaskRowView(
                            taskTitle: task.taskContent,
                            isCompleted: task.complete
                        )
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }
        }
        .task {
                   // 让出执行权，避免 @Query 访问时的线程优先级反转
                   await Task.yield()
               }
//        .task {
//            // 让出执行权，避免 @Query 访问时的线程优先级反转
//            await Task.yield()
//
//            // 更新处理后的任务数据
//            await Task.detached(priority: .userInitiated) { @MainActor in
//                self.processedTasks = self.dayTodoTasks
//            }.value
//        }
//        .onChange(of: dayTodoTasks) { _, newTasks in
//                    // 当 @Query 数据变化时，更新 processedTasks
//                    Task { @MainActor in
//                        self.processedTasks = newTasks
//                    }
//                }
        //        .task {
        //                    // 监听 @Query 变化并更新 @State，避免直接访问 wrappedValue
        //                    for await tasks in al.values {
        //                        await Task.detached(priority: .userInitiated) { @MainActor in
        //                            self.allTasks = tasks
        //                        }.value
        //                    }
        //                }
    }
}

// MARK: - 任务行视图
struct TaskRowView: View {
    let taskTitle: String
    let isCompleted: Bool
    
    @EnvironmentObject private var themeManager: TDThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // 完成状态圆圈
            Circle()
                .stroke(themeManager.color(level: 5), lineWidth: 1.5)
                .frame(width: 20, height: 20)
                .overlay(
                    Group {
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                )
            
            // 任务标题
            Text(taskTitle)
                .font(.system(size: 14))
                .foregroundColor(themeManager.titleTextColor)
                .strikethrough(isCompleted)
                .opacity(isCompleted ? 0.6 : 1.0)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(themeManager.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(themeManager.borderColor, lineWidth: 0.5)
        )
    }
}

#Preview {
    TDDayTodoView(selectedDate: Date(), category: TDSliderBarModel.defaultItems.first(where: { $0.categoryId == -100 }) ?? TDSliderBarModel.defaultItems[0])
        .environmentObject(TDThemeManager.shared)
}
