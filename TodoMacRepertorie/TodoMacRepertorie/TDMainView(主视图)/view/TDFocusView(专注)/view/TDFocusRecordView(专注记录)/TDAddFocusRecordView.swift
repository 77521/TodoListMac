//
//  TDAddFocusRecordView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/9/24.
//

import SwiftUI

struct TDAddFocusRecordView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var tomatoManager: TDTomatoManager
    @Binding var isPresented: Bool
    // 回调参数
    let onRecordAdded: (() -> Void)?

    // 状态管理
    @State private var startTime: Date = Date()
    @State private var focusDuration: Int = 25
    @State private var restDuration: Int = 5
    @State private var selectedTask: TDMacSwiftDataListModel? = nil
    @State private var showTaskPicker: Bool = false
    
    // 时长限制
    private let minFocusDuration = 5
    private let maxFocusDuration = 120
    private let minRestDuration = 1
    private let maxRestDuration = 30
    
    // 限制信息
    private let maxDailyRecords = 3
    
    private var remainingRecords: Int {
        maxDailyRecords - getTodayManualRecordsCount()
    }
    private var canAddRecord: Bool {
        getTodayManualRecordsCount() < maxDailyRecords
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView
            
            // 内容区域
            contentView
            
            // 底部按钮
            bottomButtons
        }
        .frame(width: 500, height: 400)
        .background(themeManager.backgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .sheet(isPresented: $showTaskPicker) {
            TDTaskPickerView(
                isPresented: $showTaskPicker,
                selectedTask: $selectedTask
            )
            .environmentObject(themeManager)
        }

    }
    
    // MARK: - 标题栏
    private var headerView: some View {
        HStack {
            Text("add_record_title".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.color(level: 5))
            
            Spacer()
            
            // 关闭按钮
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.descriptionTextColor)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(themeManager.secondaryBackgroundColor)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(themeManager.backgroundColor)
        .overlay(
            Rectangle()
                .fill(themeManager.separatorColor)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - 内容区域
    private var contentView: some View {
        VStack(spacing: 20) {
            // 开始时间
            startTimeSection
            
            // 专注时长
            focusDurationSection
            
            // 休息时长
            restDurationSection
            
            // 关联事件
            associatedTaskSection
            
            // 限制信息
            limitInfoSection
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
    
    // MARK: - 开始时间
    private var startTimeSection: some View {
        HStack {
            Text("开始时间")
                .font(.system(size: 14))
                .foregroundColor(themeManager.titleTextColor)
            
            Text("*")
                .font(.system(size: 14))
                .foregroundColor(.red)
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.color(level: 5))
                
                DatePicker("", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
        }
    }
    
    // MARK: - 专注时长
    private var focusDurationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("focus_duration_slider_label".localized)
                .font(.system(size: 14))
                .foregroundColor(themeManager.titleTextColor)
            
            HStack(spacing: 12) {
                // 滑块
                Slider(value: Binding(
                    get: { Double(focusDuration) },
                    set: { focusDuration = Int($0) }
                ), in: Double(minFocusDuration)...Double(maxFocusDuration), step: 1)
                .accentColor(themeManager.color(level: 5))
                
                // 数值控制
                HStack(spacing: 8) {
                    Button(action: {
                        if focusDuration > minFocusDuration {
                            focusDuration -= 1
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 12))
                            .foregroundColor(focusDuration <= minFocusDuration ? themeManager.descriptionTextColor : themeManager.color(level: 5))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(themeManager.secondaryBackgroundColor)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(focusDuration <= minFocusDuration)
                    .pointingHandCursor()

                    Text("\(focusDuration)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.titleTextColor)
                        .frame(width: 30)
                    
                    Button(action: {
                        if focusDuration < maxFocusDuration {
                            focusDuration += 1
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                            .foregroundColor(focusDuration >= maxFocusDuration ? themeManager.descriptionTextColor : themeManager.color(level: 5))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(themeManager.secondaryBackgroundColor)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                    .disabled(focusDuration >= maxFocusDuration)
                }
            }
        }
    }
    
    // MARK: - 休息时长
    private var restDurationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("rest_duration_slider_label".localized)
                .font(.system(size: 14))
                .foregroundColor(themeManager.titleTextColor)
            
            HStack(spacing: 12) {
                // 滑块
                Slider(value: Binding(
                    get: { Double(restDuration) },
                    set: { restDuration = Int($0) }
                ), in: Double(minRestDuration)...Double(maxRestDuration), step: 1)
                .accentColor(themeManager.color(level: 5))
                
                // 数值控制
                HStack(spacing: 8) {
                    Button(action: {
                        if restDuration > minRestDuration {
                            restDuration -= 1
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 12))
                            .foregroundColor(restDuration <= minRestDuration ? themeManager.descriptionTextColor : themeManager.color(level: 5))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(themeManager.secondaryBackgroundColor)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                    .disabled(restDuration <= minRestDuration)
                    
                    Text("\(restDuration)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.titleTextColor)
                        .frame(width: 30)
                    
                    Button(action: {
                        if restDuration < maxRestDuration {
                            restDuration += 1
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                            .foregroundColor(restDuration >= maxRestDuration ? themeManager.descriptionTextColor : themeManager.color(level: 5))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(themeManager.secondaryBackgroundColor)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                    .disabled(restDuration >= maxRestDuration)
                }
            }
        }
    }
    
    // MARK: - 关联事件
    private var associatedTaskSection: some View {
        HStack {
            Text("associated_task_label".localized)
                .font(.system(size: 14))
                .foregroundColor(themeManager.titleTextColor)
            
            Spacer()
            
            Button(action: {
                showTaskPicker = true
            }) {
                Text(selectedTask?.taskContent ?? "select_task_placeholder".localized)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.color(level: 5))
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()

        }
    }
    
    // MARK: - 限制信息
    private var limitInfoSection: some View {
        (Text("daily_limit_info".localized) +
        Text("\(maxDailyRecords)" + "daily_limit_count".localized)
            .foregroundColor(themeManager.color(level: 5)) +
         Text("daily_limit_remaining".localized) +
         Text("\(remainingRecords)")
            .foregroundColor(themeManager.color(level: 5)))
        .font(.system(size: 12))
        .foregroundColor(themeManager.descriptionTextColor)
        .multilineTextAlignment(.leading)

    }

    // MARK: - 底部按钮
    private var bottomButtons: some View {
        HStack(spacing: 12) {
            Spacer()
            
            // 取消按钮
            Button(action: {
                isPresented = false
            }) {
                Text("cancel_button".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.titleTextColor)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.secondaryBackgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeManager.separatorColor, lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 添加按钮
            Button(action: {
                addRecord()
            }) {
                Text("add_button".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.color(level: 5))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(themeManager.backgroundColor)
    }
    
    // MARK: - 方法
    
    /// 获取今日手动添加记录数量
    private func getTodayManualRecordsCount() -> Int {
        // 获取今日日期（只比较年月日）
        let today = Calendar.current.startOfDay(for: Date())
        let todayString = today.toString(format: "yyyy-MM-dd")
        
        // 从 UserDefaults 获取今日手动添加次数
        let key = "manual_tomato_count_\(todayString)"
        return UserDefaults.standard.integer(forKey: key)
    }
    
    /// 增加今日手动添加记录数量
    private func incrementTodayManualRecordsCount() {
        // 获取今日日期（只比较年月日）
        let today = Calendar.current.startOfDay(for: Date())
        let todayString = today.toString(format: "yyyy-MM-dd")
        
        // 增加计数
        let key = "manual_tomato_count_\(todayString)"
        let currentCount = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(currentCount + 1, forKey: key)
    }
    

    
    /// 添加记录
    private func addRecord() {
        // 计算结束时间（开始时间 + 专注时长 + 休息时长）
        let focusEndTime = startTime.adding(minutes: focusDuration)
        let restEndTime = focusEndTime.adding(minutes: restDuration)
        
        // 获取用户ID
        let userId = TDUserManager.shared.userId
        
        // 生成番茄钟ID
        let tomatoId = TDAppConfig.generateTaskId()
        
        // 创建番茄记录
        let record = TDTomatoRecordModel(
            userId: userId,
            tomatoId: tomatoId,
            taskContent: selectedTask?.taskContent ?? "null",  // 空值时传 "null"
            taskId: selectedTask?.taskId ?? "null",          // 空值时传 "null"
            startTime: startTime.fullTimestamp,
            endTime: restEndTime.fullTimestamp,
            focus: true, // 手动添加的记录默认专注成功
            focusDuration: focusDuration * 60, // 转换为秒
            rest: true, // 手动添加的记录默认休息成功
            restDuration: restDuration * 60, // 转换为秒
            snowAdd: 0,
            syncTime: Date.currentTimestamp,
            status: "add"
        )
        
        // 保存到本地数据库
        tomatoManager.insertTomatoRecord(record)
        
        
        // 增加今日手动添加计数
        incrementTodayManualRecordsCount()
        // 自动同步数据到服务器
        Task {
            await tomatoManager.syncUnsyncedRecords()
            // 调用回调通知父界面刷新数据
            DispatchQueue.main.async {
                self.onRecordAdded?()
            }

        }
        
        isPresented = false
    }
}

#Preview {
    TDAddFocusRecordView(
        isPresented: .constant(true),
        onRecordAdded: {
            print("预览：记录添加成功回调")
        }
    )
    .environmentObject(TDThemeManager.shared)
    .environmentObject(TDTomatoManager.shared)
}
