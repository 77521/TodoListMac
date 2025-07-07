//
//  TDTaskRow.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/21.
//

//import SwiftUI
//import SwiftData
//
//// 单个任务行视图
//struct TDTaskRow: View {
//    let task: TDMacSwiftDataListModel
//    @StateObject private var themeManager = TDThemeManager.shared
//    @StateObject private var mainViewModel = TDMainViewModel.shared
//    @StateObject private var settingManager = TDSettingManager.shared
//    @State private var selectedCategoryId: Int
//    
//    init(task: TDMacSwiftDataListModel) {
//        self.task = task
//        // 初始化选中的分类ID
//        _selectedCategoryId = State(initialValue: task.standbyInt1)
//    }
//    var body: some View {
//        
//        VStack(alignment: .leading, spacing: 0) {
//            ZStack(alignment: .leading) {  // 使用 ZStack 来确保评估指示线在最左边
//                // 左侧评估指示线
//                if let color = assessmentColor {
//                    Rectangle()
//                        .fill(color)
//                        .frame(width: 2)
//                }
//                
//                // 主要内容区域
//                HStack(spacing: 0) {
//                    // 固定左边距
//                    Spacer()
//                        .frame(width: 18)
//                    
//                    VStack(alignment: .leading, spacing: 8) {
//                        // ... 其他内容保持不变 ...
//                        HStack(alignment: .center, spacing: 15) {
//                            HStack(alignment: .top, spacing: 15) {
//                                // 完成状态按钮
//                                TDTaskRowComponents.CheckButton(
//                                    task: task,
//                                    isDayTodo: mainViewModel.selectedCategory?.categoryId == -100
//                                )
//                                
//                                VStack(alignment: .leading, spacing: 8) {
//                                    // 任务标题
//                                    Text(task.taskContent)
//                                        .font(.system(size: 14))
//                                        .foregroundColor(task.complete ? themeManager.titleFinishTextColor : themeManager.titleTextColor)
//                                        .strikethrough(task.complete)
//                                        .lineLimit(nil)
//                                    
//                                    // 任务描述
//                                    if let description = task.taskDescribe, !description.isEmpty {
//                                        Text(description)
//                                            .font(.system(size: 12))
//                                            .foregroundColor(themeManager.descriptionTextColor)
//                                            .lineLimit(settingManager.descriptionLineLimit)
//                                    }
//                                    
//                                    // 日期、提醒时间、重复和附件信息
//                                    HStack(spacing: 13) {
//                                        // 日期显示
//                                        TDTaskRowComponents.DateView(timestamp: task.todoTime)
//                                        
//                                        // 提醒时间
//                                        TDTaskRowComponents.ReminderView(timestamp: task.reminderTime)
//                                        
//                                        // 重复标识
//                                        if let repeatStr = task.standbyStr1, !repeatStr.isEmpty {
//                                            Image(systemName: "repeat")
//                                                .font(.system(size: 14, weight: .medium))
//                                                .foregroundColor(themeManager.color(level: 5))
//                                        }
//                                        
//                                        // 附件标识
//                                        if let attachments = task.standbyStr4, !attachments.isEmpty {
//                                            Image(systemName: "doc.text")
//                                                .font(.system(size: 14, weight: .medium))
//                                                .foregroundColor(themeManager.color(level: 5))
//                                        }
//                                    }
//                                }
//                            }
//                            
//                            Spacer(minLength: 2)
//                            
//                            // 专注模式按钮
//                            Button(action: {
//                                // TODO: 切换到专注模式
//                            }) {
//                                Image(systemName: "stopwatch.fill")
//                                    .font(.system(size: 15))
//                                    .foregroundColor(themeManager.color(level: 5))
//                                    .frame(width: 30, height: 30)
//                                    .background(
//                                        Circle()
//                                            .fill(themeManager.secondaryBackgroundColor)
//                                    )
//                            }
//                            .buttonStyle(.plain)
//                        }
//                        
//                        // 子任务列表
//                        if let subTasksStr = task.standbyStr2, !subTasksStr.isEmpty {
//                            TDTaskRowComponents.SubTaskListView(task: task)
//                        }
//
//                        
//                    }
//                    .padding(.vertical, 8)
//                }
//            }
//            
//            // 底部分割线
//            GeometryReader { geometry in  // 使用 GeometryReader 让分割线铺满整个宽度
//                Rectangle()
//                    .fill(themeManager.separatorColor)
//                    .frame(width: geometry.size.width, height: 1)
//            }
//            .frame(height: 1)  // 固定高度为1
//        }
//        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
//        .listRowBackground(themeManager.backgroundColor)
//    }
//
//    // 获取评估指示线颜色
//        private var assessmentColor: Color? {
//            if task.snowAssess < 5 {
//                return nil
//            } else if task.snowAssess < 9 {
//                return .orange
//            } else {
//                return .red
//            }
//        }
//}
import SwiftUI
import SwiftData

/// 单个任务行视图，只做展示，所有依赖通过 @EnvironmentObject 获取
struct TDTaskRow: View {
    let task: TDMacSwiftDataListModel
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var mainViewModel: TDMainViewModel
    @EnvironmentObject private var settingManager: TDSettingManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                // 左侧评估指示线
                if let color = assessmentColor {
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(color)
                        .frame(width: 2)
                        .padding(.leading, mainViewModel.selectedCategory?.categoryId == -100 ? -7.8 : -15.8)
                        .padding(.vertical, 5)
                } else {
                    Color.clear
                        .frame(width: 2)
                        .padding(.leading, mainViewModel.selectedCategory?.categoryId == -100 ? -7.8 : -15.8)
                        .padding(.vertical, 5)
                }
                Spacer().frame(width: 10)
                // 主要内容区域
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
                                    TDTaskRowComponents.DateView(timestamp: task.todoTime)
                                    TDTaskRowComponents.ReminderView(timestamp: task.reminderTime)
                                    if let repeatStr = task.standbyStr1, !repeatStr.isEmpty {
                                        Image(systemName: "repeat")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(themeManager.color(level: 5))
                                    }
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
                .padding(.leading, 10)
                .padding(.vertical, 8)
            }
            // 底部分割线
            Rectangle()
                .fill(themeManager.separatorColor)
                .frame(height: 1)
                .edgesIgnoringSafeArea(.horizontal)
                .padding(.leading, -20)
                .padding(.trailing, -20)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(themeManager.backgroundColor)
        .listRowSeparator(.hidden)
    }

    /// 评估指示线颜色
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
