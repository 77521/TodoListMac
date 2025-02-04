//
//  TDTaskRow.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/21.
//

import SwiftUI
import SwiftData

// 单个任务行视图
struct TDTaskRow: View {
    let task: TDMacSwiftDataListModel
    @StateObject private var themeManager = TDThemeManager.shared
    @StateObject private var mainViewModel = TDMainViewModel.shared
    @StateObject private var settingManager = TDSettingManager.shared
    @State private var selectedCategoryId: Int
    
    init(task: TDMacSwiftDataListModel) {
        self.task = task
        // 初始化选中的分类ID
        _selectedCategoryId = State(initialValue: task.standbyInt1)
    }
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            
//            HStack(alignment: .center, spacing: 15){
//                HStack(alignment: .top, spacing: 15){
//                    // 完成状态按钮
//                    TDTaskRowComponents.CheckButton(
//                        task: task,
//                        isDayTodo: mainViewModel.selectedCategory?.categoryId == -100
//                    )
//                    VStack(alignment: .leading, spacing: 8) {
//                        // 任务标题
//                        Text(task.taskContent)
//                            .font(.system(size: 14))
//                            .foregroundColor(task.complete ? themeManager.titleFinishTextColor : themeManager.titleTextColor)
//                            .strikethrough(task.complete)
//                            .lineLimit(nil)
//
//                        // 任务描述
//                        if let description = task.taskDescribe, !description.isEmpty {
//                            Text(description)
//                                .font(.system(size: 12))
//                                .foregroundColor(themeManager.descriptionTextColor)
//                                .lineLimit(settingManager.descriptionLineLimit) // 使用设置中的行数限制
//                        }
//                        
//                        // 日期、提醒时间、重复和附件信息
//                        HStack(spacing: 13) {
//    //                        // 分类显示
////                            TDTaskRowComponents.CategoryView(
////                                categoryId: task.standbyInt1,
////                                categoryColor: task.standbyIntColor,
////                                categoryName: task.standbyIntName,
////                                selectedCategoryId: $selectedCategoryId
////                            )
//
//                            // 日期显示
//                            TDTaskRowComponents.DateView(timestamp: task.todoTime)
//                            
//                            // 提醒时间
//                            TDTaskRowComponents.ReminderView(timestamp: task.reminderTime)
//                            
//                            // 重复标识
//                            if let repeatStr = task.standbyStr1, !repeatStr.isEmpty {
//                                Image(systemName: "repeat")
//                                    .font(.system(size: 14,weight: .medium))
//                                    .foregroundColor(themeManager.color(level: 5))
//                            }
//                            
//                            // 附件标识
//                            if let attachments = task.standbyStr4, !attachments.isEmpty {
//                                Image(systemName: "doc.text")
//                                    .font(.system(size: 14,weight: .medium))
//                                    .foregroundColor(themeManager.color(level: 5))
//                            }
//                        }
//                    }
//                }
//                
//                Spacer(minLength: 2)
//                // 专注模式按钮
//                Button(action: {
//                    // TODO: 切换到专注模式
//                }) {
//                    Image(systemName: "stopwatch.fill")
//                        .font(.system(size: 15))
//                        .foregroundColor(themeManager.color(level: 5))
//                        .frame(width: 30, height: 30)
//                        .background(
//                            Circle()
//                                .fill(themeManager.secondaryBackgroundColor)
//                        )
//                }
//                .buttonStyle(.plain)
//
//            }
////            HStack(alignment: .top, spacing: 18) {
////                
////                
////                
////                Spacer(minLength: 10)
////                
////                // 专注模式按钮
////                Button(action: {
////                    // TODO: 切换到专注模式
////                }) {
////                    Image(systemName: "timer")
////                        .font(.system(size: 16))
////                        .foregroundColor(themeManager.descriptionTextColor)
////                }
////                .buttonStyle(.plain)
////            }
//            
//            // 子任务列表
//            if let subTasksStr = task.standbyStr2, !subTasksStr.isEmpty {
//                TDTaskRowComponents.SubTaskListView(task: task)
//            }
//        }
//        .listRowInsets(EdgeInsets(top: 8, leading: 18, bottom: 8, trailing: 8))
//        .listRowBackground(themeManager.backgroundColor)
//    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 20) {
                // 左侧评估指示线
                if let color = assessmentColor {
                    Rectangle()
                        .fill(color)
                        .frame(width: 2)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 15) {
                        HStack(alignment: .top, spacing: 15) {
                            // 完成状态按钮
                            TDTaskRowComponents.CheckButton(
                                task: task,
                                isDayTodo: mainViewModel.selectedCategory?.categoryId == -100
                            )
                            
                            VStack(alignment: .leading, spacing: 8) {
                                // 任务标题
                                Text(task.taskContent)
                                    .font(.system(size: 14))
                                    .foregroundColor(task.complete ? themeManager.titleFinishTextColor : themeManager.titleTextColor)
                                    .strikethrough(task.complete)
                                    .lineLimit(nil)
                                
                                // 任务描述
                                if let description = task.taskDescribe, !description.isEmpty {
                                    Text(description)
                                        .font(.system(size: 12))
                                        .foregroundColor(themeManager.descriptionTextColor)
                                        .lineLimit(settingManager.descriptionLineLimit)
                                }
                                
                                // 日期、提醒时间、重复和附件信息
                                HStack(spacing: 13) {
                                    // 日期显示
                                    TDTaskRowComponents.DateView(timestamp: task.todoTime)
                                    
                                    // 提醒时间
                                    TDTaskRowComponents.ReminderView(timestamp: task.reminderTime)
                                    
                                    // 重复标识
                                    if let repeatStr = task.standbyStr1, !repeatStr.isEmpty {
                                        Image(systemName: "repeat")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(themeManager.color(level: 5))
                                    }
                                    
                                    // 附件标识
                                    if let attachments = task.standbyStr4, !attachments.isEmpty {
                                        Image(systemName: "doc.text")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(themeManager.color(level: 5))
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 2)
                        
                        // 专注模式按钮
                        Button(action: {
                            // TODO: 切换到专注模式
                        }) {
                            Image(systemName: "stopwatch.fill")
                                .font(.system(size: 15))
                                .foregroundColor(themeManager.color(level: 5))
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(themeManager.secondaryBackgroundColor)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // 子任务列表
                    if let subTasksStr = task.standbyStr2, !subTasksStr.isEmpty {
                        TDTaskRowComponents.SubTaskListView(task: task)
                    }
                }
//                .padding(.horizontal, 0)
                .padding(.vertical, 8)
            }
            
            // 底部分割线
            Rectangle()
                .fill(themeManager.separatorColor)
                .frame(height: 1)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(themeManager.backgroundColor)
    }

    // 获取评估指示线颜色
        private var assessmentColor: Color? {
            if task.snowAssess < 5 {
                return nil
            } else if task.snowAssess < 9 {
                return .orange
            } else {
                return .red
            }
        }
}
// 单个任务行视图
//struct TDTaskRow: View {
//    let task: TDMacSwiftDataListModel
//    @StateObject private var themeManager = TDThemeManager.shared
//    @GestureState private var isDetectingLongPress = false
//    
//    var body: some View {
//        HStack(spacing: 12) {
//            // 完成状态按钮
//            Button(action: {
//                Task {
//                    // 更新任务完成状态
//                    task.complete.toggle()
//                    try? await TDModelContainer.shared.perform {
//                        try TDModelContainer.shared.save()
//                    }
//                    await TDMainViewModel.shared.refreshTasks()
//                }
//            }) {
//                Image(systemName: task.complete ? "checkmark.circle.fill" : "circle")
//                    .foregroundColor(task.complete ? themeManager.color(level: 5) : themeManager.descriptionTextColor)
//            }
//            .buttonStyle(.plain)
//            
//            // 任务内容
//            VStack(alignment: .leading, spacing: 4) {
//                Text(task.taskContent)
//                    .font(.system(size: 14))
//                    .foregroundColor(task.complete ? themeManager.descriptionTextColor : themeManager.titleTextColor)
//                    .strikethrough(task.complete)
//                
//                // 如果有描述，显示描述
//                if let description = task.taskDescribe, !description.isEmpty {
//                    Text(description)
//                        .font(.system(size: 12))
//                        .foregroundColor(themeManager.descriptionTextColor)
//                        .lineLimit(1)
//                }
//                
//                // 如果有子任务，显示子任务数量
//                if !task.subTaskList.isEmpty {
//                    HStack(spacing: 4) {
//                        Image(systemName: "list.bullet")
//                        Text("\(task.subTaskList.filter(\.isComplete).count)/\(task.subTaskList.count)")
//                    }
//                    .font(.system(size: 12))
//                    .foregroundColor(themeManager.descriptionTextColor)
//                }
//            }
//            
//            Spacer()
//            
//            // 如果有提醒时间，显示提醒时间
//            if task.reminderTime > 0 {
//                Text(task.reminderTimeString)
//                    .font(.system(size: 12))
//                    .foregroundColor(themeManager.descriptionTextColor)
//            }
//            
//            // 详情按钮
//            Button(action: {
//                // TODO: 显示任务详情
//            }) {
//                Image(systemName: "info.circle")
//                    .foregroundColor(themeManager.descriptionTextColor)
//            }
//            .buttonStyle(.plain)
//        }
//        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
////        .listRowBackground(themeManager.backgroundColor)
//        .gesture(
//            LongPressGesture(minimumDuration: 0.5)
//                .updating($isDetectingLongPress) { currentState, gestureState, _ in
//                    gestureState = currentState
//                }
//        )
//        .scaleEffect(isDetectingLongPress ? 0.95 : 1.0)
//        .animation(.easeInOut(duration: 0.2), value: isDetectingLongPress)
//    }
//}
//#Preview {
//    TDTaskRow(task: TDMacSwiftDataListModel())
//}
