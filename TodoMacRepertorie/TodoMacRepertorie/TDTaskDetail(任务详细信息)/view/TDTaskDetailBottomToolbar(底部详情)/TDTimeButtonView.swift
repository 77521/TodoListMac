//
//  TDTimeButtonView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import SwiftUI
import SwiftData

/// 时间选择按钮组件
/// 用于显示提醒时间状态和选择提醒时间
struct TDTimeButtonView: View {
    
    // MARK: - 数据绑定
    @Bindable var task: TDMacSwiftDataListModel  // 当前任务数据（可绑定修改）
    @EnvironmentObject private var themeManager: TDThemeManager  // 主题管理器
    @Environment(\.modelContext) private var modelContext  // SwiftData 数据上下文
    
    // MARK: - 状态变量
    @State private var showTimePicker = false  // 控制时间选择器弹窗显示
    @State private var selectedTime = Date()  // 选中的时间
    
    // MARK: - 回调
    let onTimeSet: () -> Void  // 时间设置完成回调（仅用于同步数据）
    
    // MARK: - 主视图
    var body: some View {
        // MARK: - 选择时间按钮（第一个按钮）
        Button(action: {
            showTimePicker = true  // 显示时间选择器弹窗
        }) {
            
            // 有提醒时间时显示时间信息
            HStack(spacing: 0) {
                // 时钟图标
                Image(systemName: "alarm")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(task.hasReminder ? themeManager.color(level: 5) : themeManager.subtaskTextColor)
                    .padding(.all,8)
                    .background(
                        Circle()
                            .fill(themeManager.secondaryBackgroundColor)
                    )
                
                if task.hasReminder {
                    // 提醒时间文字（如：23:42）
                    Text(task.reminderTimeString)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.color(level: 5))
                    
                    // 清除提醒时间按钮
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            task.reminderTime = 0  // 清除提醒时间
                            task.reminderTimeString = ""
                            selectedTime = Date()
                        }
                        onTimeSet()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.descriptionTextColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading,6)
                }
            }
            .padding(.vertical,0)
            .padding(.leading,0)
            .padding(.trailing,task.hasReminder ? 8 : 0)
            .background(
                RoundedRectangle(cornerRadius: 17)
                    .fill(task.hasReminder ? themeManager.secondaryBackgroundColor : Color.clear)
            )
            .transition(.asymmetric(
                insertion: .scale(scale: 0.1, anchor: .leading).combined(with: .opacity),
                removal: .scale(scale: 0.1, anchor: .leading).combined(with: .opacity)
            ))
        }
        .animation(.easeInOut(duration: 0.15), value: task.hasReminder)  // 添加状态变化动画
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showTimePicker, attachmentAnchor: .point(.top)) {
            TDTimePickerView(
                isPresented: $showTimePicker,
                selectedTime: $selectedTime,
                task: task
            ) {
                onTimeSet()  // 同步数据到数据库
            }
        }
        .help("选择时间")  // 鼠标悬停提示
    }
}

// MARK: - 预览
#Preview {
    // 创建一个示例任务用于预览
    // 创建一个示例任务用于预览
    let sampleTask = TDMacSwiftDataListModel(
        id: 1,
        taskId: "preview_task",
        taskContent: "预览任务",
        taskDescribe: "这是一个预览任务",
        complete: false,
        createTime: Date().startOfDayTimestamp,
        delete: false,
        reminderTime: 0,
        snowAdd: 0,
        snowAssess: 0,
        standbyInt1: 1, // 分类ID，在事件内使用standbyInt1
        standbyStr1: nil,
        standbyStr2: nil,
        standbyStr3: nil,
        standbyStr4: nil,
        syncTime: Date().startOfDayTimestamp,
        taskSort: Decimal(1),
        todoTime: Date().startOfDayTimestamp,
        userId: 1,
        version: 1,
        status: "sync",
        isSubOpen: true,
        standbyIntColor: "",
        standbyIntName: "",
        reminderTimeString: "",
        subTaskList: [],
        attachmentList: []
    )

    TDTimeButtonView(
        task: sampleTask,
        onTimeSet: {
            print("时间设置完成，需要同步数据")
        }
    )
    .environmentObject(TDThemeManager.shared)
}
