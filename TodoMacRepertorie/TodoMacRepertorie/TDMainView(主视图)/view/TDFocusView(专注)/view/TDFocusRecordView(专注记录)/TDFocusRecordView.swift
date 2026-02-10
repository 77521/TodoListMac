////
////  TDFocusRecordView.swift
////  TodoMacRepertorie
////
////  Created by 赵浩 on 2025/9/24.
////
//
//import SwiftUI
//
//struct TDFocusRecordView: View {
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @EnvironmentObject private var tomatoManager: TDTomatoManager
//    @Binding var isPresented: Bool
//    
//    // 状态管理
//    @State private var focusRecords: [TDTomatoRecordModel] = []
//    @State private var isLoading: Bool = false
//    @State private var showAddRecord: Bool = false
//    
//    @State private var showToast: Bool = false
//    @State private var toastMessage: String = ""
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // 标题栏
//            headerView
//            
//            // 记录列表
//            if isLoading {
//                loadingView
//            } else {
//                recordListView
//            }
//        }
//        .frame(width: 600, height: 500)
//        .background(themeManager.backgroundColor)
//        .cornerRadius(12)
//        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
//        .task {
//            await loadFocusRecords()
//        }
//        .tdToastBottom(
//            isPresenting: $showToast,
//            message: toastMessage,
//            type: .error
//        )
//
//    }
//    
//    // MARK: - 标题栏
//    private var headerView: some View {
//        HStack {
//            Text("番茄专注记录")
//                .font(.system(size: 16, weight: .semibold))
//                .foregroundColor(themeManager.color(level: 5))
//            
//            Spacer()
//            
//            // 手动添加记录按钮
//            Button(action: {
//                handleAddRecordClick()
//            }) {
//                Text("手动添加记录")
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 16)
//                    .padding(.vertical, 8)
//                    .background(
//                        RoundedRectangle(cornerRadius: 6)
//                            .fill(themeManager.color(level: 5))
//                    )
//            }
//            .buttonStyle(PlainButtonStyle())
//            .pointingHandCursor()
//
//            // 关闭按钮
//            Button(action: {
//                isPresented = false
//            }) {
//                Image(systemName: "xmark")
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(themeManager.descriptionTextColor)
//                    .frame(width: 24, height: 24)
//                    .background(
//                        Circle()
//                            .fill(themeManager.secondaryBackgroundColor)
//                    )
//            }
//            .buttonStyle(PlainButtonStyle())
//            .pointingHandCursor()
//        }
//        .padding(.horizontal, 20)
//        .padding(.vertical, 16)
//        .background(themeManager.backgroundColor)
//        .overlay(
//            Rectangle()
//                .fill(themeManager.separatorColor)
//                .frame(height: 1),
//            alignment: .bottom
//        )
//        .sheet(isPresented: $showAddRecord) {
//            TDAddFocusRecordView(
//                isPresented: $showAddRecord,
//                onRecordAdded: {
//                    // 记录添加成功后刷新数据
//                    Task {
//                        await loadFocusRecords()
//                    }
//                }
//            )
//            .environmentObject(themeManager)
//            .environmentObject(tomatoManager)
//        }
//
//    }
//    
//    // MARK: - 加载视图
//    private var loadingView: some View {
//        VStack(spacing: 16) {
//            ProgressView()
//                .scaleEffect(1.2)
//                .tint(themeManager.color(level: 5))
//            
//            Text("正在加载专注记录...")
//                .font(.system(size: 14))
//                .foregroundColor(themeManager.descriptionTextColor)
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//    
//    // MARK: - 记录列表
//    private var recordListView: some View {
//        ScrollView {
//            LazyVStack(spacing: 0) {
//                ForEach(focusRecords, id: \.tomatoId) { record in
//                    FocusRecordRowView(record: record)
//                        .environmentObject(themeManager)
//                }
//            }
//            .padding(.vertical, 8)
//        }
//        .background(themeManager.backgroundColor)
//    }
//    
//    // MARK: - 加载数据
//    private func loadFocusRecords() async {
//        isLoading = true
//        
//        let records = await tomatoManager.fetchTomatoRecords()
//        
//        await MainActor.run {
//            self.focusRecords = records
//            self.isLoading = false
//        }
//    }
//    
//    // MARK: - 手动添加记录相关方法
//       
//       /// 获取今日手动添加记录数量
//       private func getTodayManualRecordsCount() -> Int {
//           // 获取今日日期（只比较年月日）
//           let today = Calendar.current.startOfDay(for: Date())
//           let todayString = today.toString(format: "yyyy-MM-dd")
//           
//           // 从 UserDefaults 获取今日手动添加次数
//           let key = "manual_tomato_count_\(todayString)"
//           return UserDefaults.standard.integer(forKey: key)
//       }
//       
//       /// 处理手动添加记录按钮点击
//       private func handleAddRecordClick() {
//           let currentCount = getTodayManualRecordsCount()
//           let maxDailyRecords = 3
//           
//           if currentCount >= maxDailyRecords {
//               // 已达到每日限制，显示 Toast 提示
//               toastMessage = "今日手动添加记录已达上限（3条），请明天再试"
//               showToast = true
//           } else {
//               // 可以添加，打开添加记录界面
//               showAddRecord = true
//           }
//       }
//}
//
//// MARK: - 记录行视图
//struct FocusRecordRowView: View {
//    let record: TDTomatoRecordModel
//    @EnvironmentObject private var themeManager: TDThemeManager
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            // 主要信息行
//            HStack(spacing: 0) {
//                // 左侧：日期和时间信息
//                HStack(spacing: 8) {
//                    // 日期
//                    Text(formatDate(record.startTime))
//                        .font(.system(size: 14))
//                        .foregroundColor(themeManager.titleTextColor)
//                    
//                    // 时间范围
//                    Text(formatTimeRange(record.startTime, endTime: record.endTime))
//                        .font(.system(size: 13))
//                        .foregroundColor(themeManager.descriptionTextColor)
//                    
//                    // 专注完成图标（只有专注成功才显示）
//                    if record.focus {
//                        Image("icon_tomato")
//                            .renderingMode(.template)
//                            .resizable()
//                            .frame(width: 15, height: 15)
//                            .foregroundStyle(themeManager.color(level: 5))
//                    }
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//                
//                // 右侧：专注时长和删除按钮
//                HStack(spacing: 8) {
//                    // 专注时长
//                    Text(formatDuration(record.focusDuration))
//                        .font(.system(size: 13))
//                        .foregroundColor(themeManager.titleTextColor)
//                    
//                    // 删除按钮（仅本地记录显示）
//                    if record.status == "add" {
//                        Button(action: {
//                            // TODO: 实现删除功能
//                            print("删除记录: \(record.tomatoId)")
//                        }) {
//                            Image(systemName: "xmark")
//                                .font(.system(size: 12))
//                                .foregroundColor(themeManager.descriptionTextColor)
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                        .pointingHandCursor()
//                    }
//                }
//            }
//            
//            // 任务标题（如果有内容）
//            // 任务标题（如果有内容且不是null）
//            if let taskContent = record.taskContent,
//               !taskContent.isEmpty &&
//               taskContent.lowercased() != "null" {
//                HStack(spacing: 6) {
//                    Image(systemName: "link")
//                        .font(.system(size: 12, weight: .medium))
//                        .foregroundColor(themeManager.color(level: 5))
//
//                    Text(taskContent)
//                        .font(.system(size: 12))
//                        .foregroundColor(themeManager.titleTextColor)
//                        .lineLimit(1)
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(.top, 4)
//            }
//        }
//        .padding(.horizontal, 20)
//        .padding(.vertical, 12)
//        .background(themeManager.backgroundColor)
//        .overlay(
//            Rectangle()
//                .fill(themeManager.separatorColor)
//                .frame(height: 1),
//            alignment: .bottom
//        )
//    }
//    
//    // MARK: - 格式化方法
//    private func formatDate(_ timestamp: Int64) -> String {
//        let date = Date.fromTimestamp(timestamp)
//        return date.formattedString
//    }
//    
//    private func formatTimeRange(_ startTime: Int64, endTime: Int64) -> String {
//        let startDate = Date.fromTimestamp(startTime)
//        let startTimeStr = startDate.toString(format: "HH:mm:ss")
//        
//        // 如果专注完成了，显示开始时间-结束时间
//        if record.focus {
//            let endDate = Date.fromTimestamp(endTime)
//            let endTimeStr = endDate.toString(format: "HH:mm:ss")
//            return "\(startTimeStr)-\(endTimeStr)"
//        } else {
//            // 如果专注没完成，只显示开始时间
//            return startTimeStr
//        }
//    }
//
//    
//    private func formatDuration(_ seconds: Int) -> String {
//        let hours = seconds / 3600
//        let minutes = (seconds % 3600) / 60
//        let remainingSeconds = seconds % 60
//        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
//    }
//    
//    
//}
//
//#Preview {
//    TDFocusRecordView(isPresented: .constant(true))
//        .environmentObject(TDThemeManager.shared)
//        .environmentObject(TDTomatoManager.shared)
//}

//
//  TDFocusRecordView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/9/24.
//

import SwiftUI

struct TDFocusRecordView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var tomatoManager: TDTomatoManager
    @Binding var isPresented: Bool
    
    // 状态管理
    @State private var focusRecords: [TDTomatoRecordModel] = []
    @State private var isLoading: Bool = false
    @State private var showAddRecord: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView
            
            // 记录列表
            if isLoading {
                loadingView
            } else {
                recordListView
            }
        }
        .frame(width: 600, height: 500)
        .background(themeManager.backgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .task {
            await loadFocusRecords()
        }

    }
    
    // MARK: - 标题栏
    private var headerView: some View {
        HStack {
            Text("番茄专注记录")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.color(level: 5))
            
            Spacer()
            
            // 手动添加记录按钮
            Button(action: {
                handleAddRecordClick()
            }) {
                Text("手动添加记录")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(themeManager.color(level: 5))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()

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
        .sheet(isPresented: $showAddRecord) {
            TDAddFocusRecordView(
                isPresented: $showAddRecord,
                onRecordAdded: {
                    // 记录添加成功后刷新数据
                    Task {
                        await loadFocusRecords()
                    }
                }
            )
            .environmentObject(themeManager)
            .environmentObject(tomatoManager)
        }

    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(themeManager.color(level: 5))
            
            Text("正在加载专注记录...")
                .font(.system(size: 14))
                .foregroundColor(themeManager.descriptionTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 记录列表
    private var recordListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(focusRecords, id: \.tomatoId) { record in
                    FocusRecordRowView(record: record)
                        .environmentObject(themeManager)
                }
            }
            .padding(.vertical, 8)
        }
        .background(themeManager.backgroundColor)
    }
    
    // MARK: - 加载数据
    private func loadFocusRecords() async {
        isLoading = true
        
        let records = await tomatoManager.fetchTomatoRecords()
        
        await MainActor.run {
            self.focusRecords = records
            self.isLoading = false
        }
    }
    
    // MARK: - 手动添加记录相关方法
       
       /// 获取今日手动添加记录数量
       private func getTodayManualRecordsCount() -> Int {
           // 获取今日日期（只比较年月日）
           let today = Calendar.current.startOfDay(for: Date())
           let todayString = today.toString(format: "yyyy-MM-dd")
           
           // 从 UserDefaults 获取今日手动添加次数
           let key = "manual_tomato_count_\(todayString)"
           return UserDefaults.standard.integer(forKey: key)
       }
       
       /// 处理手动添加记录按钮点击
       private func handleAddRecordClick() {
           let currentCount = getTodayManualRecordsCount()
           let maxDailyRecords = 3
           
           if currentCount >= maxDailyRecords {
               // 已达到每日限制，显示 Toast 提示
               TDToastCenter.shared.show(
                   "今日手动添加记录已达上限（3条），请明天再试",
                   type: .info,
                   position: .bottom
               )
           } else {
               // 可以添加，打开添加记录界面
               showAddRecord = true
           }
       }
}

// MARK: - 记录行视图
struct FocusRecordRowView: View {
    let record: TDTomatoRecordModel
    @EnvironmentObject private var themeManager: TDThemeManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 主要信息行
            HStack(spacing: 0) {
                // 左侧：日期和时间信息
                HStack(spacing: 8) {
                    // 日期
                    Text(formatDate(record.startTime))
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.titleTextColor)
                    
                    // 时间范围
                    Text(formatTimeRange(record.startTime, endTime: record.endTime))
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.descriptionTextColor)
                    
                    // 专注完成图标（只有专注成功才显示）
                    if record.focus {
                        Image("icon_tomato")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 15, height: 15)
                            .foregroundStyle(themeManager.color(level: 5))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 右侧：专注时长和删除按钮
                HStack(spacing: 8) {
                    // 专注时长
                    Text(formatDuration(record.focusDuration))
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.titleTextColor)
                    
                    // 删除按钮（仅本地记录显示）
                    if record.status == "add" {
                        Button(action: {
                            // TODO: 实现删除功能
                            print("删除记录: \(record.tomatoId)")
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.descriptionTextColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .pointingHandCursor()
                    }
                }
            }
            
            // 任务标题（如果有内容）
            // 任务标题（如果有内容且不是null）
            if let taskContent = record.taskContent,
               !taskContent.isEmpty &&
               taskContent.lowercased() != "null" {
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.color(level: 5))

                    Text(taskContent)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.titleTextColor)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(themeManager.backgroundColor)
        .overlay(
            Rectangle()
                .fill(themeManager.separatorColor)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - 格式化方法
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date.fromTimestamp(timestamp)
        return date.formattedString
    }
    
    private func formatTimeRange(_ startTime: Int64, endTime: Int64) -> String {
        let startDate = Date.fromTimestamp(startTime)
        let startTimeStr = startDate.toString(format: "HH:mm:ss")
        
        // 如果专注完成了，显示开始时间-结束时间
        if record.focus {
            let endDate = Date.fromTimestamp(endTime)
            let endTimeStr = endDate.toString(format: "HH:mm:ss")
            return "\(startTimeStr)-\(endTimeStr)"
        } else {
            // 如果专注没完成，只显示开始时间
            return startTimeStr
        }
    }

    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }
    
    
}

#Preview {
    TDFocusRecordView(isPresented: .constant(true))
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDTomatoManager.shared)
}
