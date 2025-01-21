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
    @GestureState private var isDetectingLongPress = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 完成状态按钮
            Button(action: {
                Task {
                    // 更新任务完成状态
                    task.complete.toggle()
                    try? await TDModelContainer.shared.perform {
                        try TDModelContainer.shared.save()
                    }
                    await TDMainViewModel.shared.refreshTasks()
                }
            }) {
                Image(systemName: task.complete ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.complete ? themeManager.color(level: 5) : themeManager.secondaryTextColor)
            }
            .buttonStyle(.plain)
            
            // 任务内容
            VStack(alignment: .leading, spacing: 4) {
                Text(task.taskContent)
                    .font(.system(size: 14))
                    .foregroundColor(task.complete ? themeManager.secondaryTextColor : themeManager.primaryTextColor)
                    .strikethrough(task.complete)
                
                // 如果有描述，显示描述
                if let description = task.taskDescribe, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(1)
                }
                
                // 如果有子任务，显示子任务数量
                if !task.subTaskList.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                        Text("\(task.subTaskList.filter(\.isComplete).count)/\(task.subTaskList.count)")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Spacer()
            
            // 如果有提醒时间，显示提醒时间
            if task.reminderTime > 0 {
                Text(task.reminderTimeString)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            // 详情按钮
            Button(action: {
                // TODO: 显示任务详情
            }) {
                Image(systemName: "info.circle")
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .buttonStyle(.plain)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowBackground(themeManager.backgroundColor)
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .updating($isDetectingLongPress) { currentState, gestureState, _ in
                    gestureState = currentState
                }
        )
        .scaleEffect(isDetectingLongPress ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDetectingLongPress)
    }
}
//#Preview {
//    TDTaskRow(task: TDMacSwiftDataListModel())
//}
