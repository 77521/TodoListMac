//
//  TDTaskPickerView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/9/24.
//

import SwiftUI
import SwiftData

struct TDTaskPickerView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Binding var isPresented: Bool
    @Binding var selectedTask: TDMacSwiftDataListModel?

    // 状态管理
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker: Bool = false
    @State private var tasks: [TDMacSwiftDataListModel] = []
    @State private var isLoading: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView
            
            // 日期选择
            dateSelectionView
            
            // 任务列表
            taskListView
        }
        .frame(width: 400, height: 500)
        .background(themeManager.backgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .task {
            await loadTasks()
        }
    }
    
    // MARK: - 标题栏
    private var headerView: some View {
        HStack {
            Text("请选择要关联的事件")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.titleTextColor)
            
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
    
    // MARK: - 日期选择
    private var dateSelectionView: some View {
        HStack {
            Button(action: {
                showDatePicker = true
            }) {
                HStack(spacing: 4) {
                    Text("日期:")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.titleTextColor)
                    
                    Text(formatDate(selectedDate))
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.titleTextColor)
                    Image(systemName: "arrowtriangle.down.fill")
                        .resizable()
                        .frame(width: 12, height: 8)
                        .foregroundColor(themeManager.titleTextColor)

                }
                .contentShape(Rectangle())

            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showDatePicker) {
                TDCustomDatePickerView(
                    selectedDate: $selectedDate,
                    isPresented: $showDatePicker,
                    onDateSelected: { date in
                        selectedDate = date
                        Task {
                            await loadTasks()
                        }
                    }
                )
                .frame(width: 280, height: 320)
            }

            Spacer()
            
            // 取消关联按钮
            Button(action: {
                selectedTask = nil
                isPresented = false
            }) {
                Text("取消关联")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.color(level: 5))
            }
            .buttonStyle(PlainButtonStyle())
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
    
    // MARK: - 任务列表
    private var taskListView: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else if tasks.isEmpty {
                emptyView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks, id: \.taskId) { task in
                            TaskPickerRowView(
                                task: task,
                                isSelected: selectedTask?.taskId == task.taskId,
                                onSelect: {
                                    selectedTask = task
                                    isPresented = false
                                }
                            )
                            .environmentObject(themeManager)
                        }
                    }
                }
            }
        }
        .background(themeManager.backgroundColor)
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
                .tint(themeManager.color(level: 5))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 空状态视图
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet")
                .font(.system(size: 48))
                .foregroundColor(themeManager.descriptionTextColor)
            
            Text("该日期没有任务")
                .font(.system(size: 14))
                .foregroundColor(themeManager.descriptionTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 方法
    
    /// 格式化日期显示
    private func formatDate(_ date: Date) -> String {
        
        if date.isToday {
            return "今天"
        } else if date.isTomorrow {
            return "明天"
        } else if date.isDayAfterTomorrow {
            return "后天"
        } else {
            return date.formattedString
        }
    }
    
    /// 加载任务数据
    private func loadTasks() async {
        // 只有在不是初始加载时才设置 loading 状态
        if !isLoading {
            await MainActor.run {
                self.isLoading = true
            }
        }

        do {
            let context = TDModelContainer.shared.mainContext
            let taskModels = try await TDQueryConditionManager.shared.getTasksByDate(
                selectedDate: selectedDate,
                context: context
            )
            
            await MainActor.run {
                self.tasks = taskModels
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.tasks = []
                self.isLoading = false
            }
            print("❌ 加载任务数据失败: \(error)")
        }
    }
}

// MARK: - 任务行视图
struct TaskPickerRowView: View {
    let task: TDMacSwiftDataListModel
    let isSelected: Bool
    let onSelect: () -> Void
    @EnvironmentObject private var themeManager: TDThemeManager
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.color(level: 5))
                
                Text(task.taskContent)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.titleTextColor)
                    .lineLimit(1)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.color(level: 5))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                isSelected ? themeManager.color(level: 5).opacity(0.1) : themeManager.backgroundColor
            )
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            Rectangle()
                .fill(themeManager.separatorColor)
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

#Preview {
    TDTaskPickerView(
        isPresented: .constant(true),
        selectedTask: .constant(nil)
    )
    .environmentObject(TDThemeManager.shared)
}
