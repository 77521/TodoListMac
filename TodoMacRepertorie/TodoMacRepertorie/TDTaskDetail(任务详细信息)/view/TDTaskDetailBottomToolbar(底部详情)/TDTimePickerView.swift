//
//  TDTimePickerView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import SwiftUI
import SwiftData

/// 时间选择器弹窗组件
/// 用于选择任务的提醒时间
struct TDTimePickerView: View {
    
    // MARK: - 数据绑定
    @Binding var isPresented: Bool  // 控制弹窗显示状态
    @Binding var selectedTime: Date  // 选中的时间
    
    // MARK: - 任务数据
    @Bindable var task: TDMacSwiftDataListModel  // 当前任务数据（可绑定修改）
    @Environment(\.modelContext) private var modelContext  // SwiftData 数据上下文
    
    // MARK: - 回调
    let onTimeSelected: () -> Void  // 时间选择完成回调（仅用于同步数据）
    
    // MARK: - 主视图
    var body: some View {
        VStack(spacing: 16) {
            // 顶部：标题
            Text("选择时间")
                .font(.headline)
            
            // 中间：时间选择器（居中显示）
            HStack {
                Spacer()
                
                // 时间选择器（根据系统设置自动显示24小时制或12小时制）
                DatePicker("选择时间", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                
                Spacer()
            }
            
            // 底部：操作按钮
            HStack(spacing: 12) {
                Button("取消") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Button("设定") {
                    handleTimeSelection()  // 处理时间选择
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 200, height: 140)
    }
    
    // MARK: - 私有方法
    
    /// 处理时间选择 - 将用户选择的时间设置为提醒时间
    private func handleTimeSelection() {
        // 获取任务的日期（从 todoTime 获取年月日）
        let taskDate = Date.fromTimestamp(task.todoTime)
        
        // 从用户选择的时间中获取时分（使用新的扩展方法）
        let selectedHour = selectedTime.hour    // 获取选中的小时
        let selectedMinute = selectedTime.minute  // 获取选中的分钟
        
        // 创建提醒时间：使用任务的年月日 + 用户选择的时分（使用新的扩展方法）
        let reminderDate = Date.createDate(
            year: taskDate.year,
            month: taskDate.month,
            day: taskDate.day,
            hour: selectedHour,
            minute: selectedMinute,
            second: 0
        )
        
        // 打印时间日期信息（转换为字符串格式）
        print("⏰ 设置提醒时间:")
        print("- 任务日期: \(taskDate.toString(format: "yyyy-MM-dd"))")
        print("- 选中的时间: \(selectedTime.toString(format: "HH:mm"))")
        print("- 提醒日期: \(reminderDate.toString(format: "yyyy-MM-dd HH:mm:ss"))")
        print("- 提醒时间戳: \(reminderDate.fullTimestamp)")
        print("- 任务内容: \(task.taskContent)")
        
        // 使用动画设置提醒时间
        withAnimation(.easeInOut(duration: 0.3)) {
            task.reminderTime = reminderDate.fullTimestamp  // 设置任务的提醒时间
            task.reminderTimeString = Date.timestampToString(timestamp: task.reminderTime, format: "HH:mm")
        }
        
        print("- 最终提醒时间：\(Date.timestampToString(timestamp: task.reminderTime, format: "yyyy.MM.dd HH:mm:ss"))")
        
        // 在本地日历中添加提醒事件
        Task {
            do {
                try await TDCalendarService.shared.handleReminderEvent(task: task)
                print("✅ 本地日历提醒事件添加成功")
            } catch {
                print("❌ 本地日历提醒事件添加失败: \(error)")
            }
        }
        
        // 调用回调通知父组件同步数据
        onTimeSelected()
    }
}

// MARK: - 预览
#Preview {
    @State var isPresented = true
    @State var selectedTime = Date()
    
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
    TDTimePickerView(
        isPresented: $isPresented,
        selectedTime: $selectedTime,
        task: sampleTask
    ) {
        print("时间选择完成，需要同步数据")
    }
}
