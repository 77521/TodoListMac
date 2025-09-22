//
//  TDRepeatManagementView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/21.
//

import SwiftUI

/// 重复事件管理弹窗视图
/// 用于显示和管理重复任务的列表
struct TDRepeatManagementView: View {
    
    // MARK: - 数据绑定
    @EnvironmentObject private var themeManager: TDThemeManager  // 主题管理器
    @Environment(\.modelContext) private var modelContext  // SwiftData 数据上下文
    @Binding var isPresented: Bool  // 控制弹窗显示状态
    let task: TDMacSwiftDataListModel  // 当前任务数据
    
    // MARK: - 状态变量
    @State private var repeatTasks: [TDMacSwiftDataListModel] = []  // 重复任务列表
    @State private var showHelpModal = false  // 控制帮助说明弹窗显示
    @State private var showDeleteAlert = false  // 控制删除确认弹窗
    
    // MARK: - 主视图
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar
            
            // 分割线
            Divider()
                .background(themeManager.separatorColor)
            
            // 任务列表
            taskList
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 底部操作栏
            bottomActionBar
        }
        .frame(width: 450, height: 500)
        .background(themeManager.backgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .overlay(
            // 帮助说明弹窗
            Group {
                if showHelpModal {
                    helpModalOverlay
                }
            }
        )
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteAllRepeatTasks()
            }
        } message: {
            Text("确定要删除所有重复事件吗？此操作不可撤销。")
        }
    }
    
    // MARK: - 子视图
    
    /// 标题栏
    private var titleBar: some View {
        HStack {
            // 标题和问号图标按钮
            Button(action: {
                showHelpModal = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "repeat.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.color(level: 5))
                    
                    Text("重复事件管理")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.titleTextColor)
                    
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.descriptionTextColor)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .help("查看重复事件说明")
            
            Spacer()
            
            // 关闭按钮
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.descriptionTextColor)
            }
            .buttonStyle(PlainButtonStyle())
            .help("关闭")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(themeManager.backgroundColor)
    }
    
    /// 任务列表
    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(repeatTasks.enumerated()), id: \.offset) { index, task in
                    TaskRowView(task: task)
                        .environmentObject(themeManager)
                        .onAppear {
                            print("📱 显示任务 \(index + 1): \(task.taskContent)")
                        }
                }
            }
            .padding(.vertical, 8)
        }
        .background(themeManager.backgroundColor)
        .onAppear {
            loadRepeatTasks()
        }
        .onChange(of: repeatTasks.count) { oldValue, newValue in
            print("🔄 任务数量变化: \(oldValue) -> \(newValue)")
        }

    }
    
    /// 底部操作栏
    private var bottomActionBar: some View {
        HStack {
            // 统计信息
            HStack(spacing: 4) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.descriptionTextColor)
                
                Text("共 \(repeatTasks.count) 个重复事件")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.descriptionTextColor)
            }
            
            Spacer()
            
            // 删除按钮
            Button(action: {
                showDeleteAlert = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12))
                    Text("删除全部")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.red)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .help("删除所有重复事件")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(themeManager.secondaryBackgroundColor)
    }
    
    
    /// 帮助说明弹窗遮罩
    private var helpModalOverlay: some View {
        ZStack {
            // 半透明背景遮罩
            Color.black.opacity(0.4)
                .ignoresSafeArea(.all)
                .onTapGesture {
                    showHelpModal = false
                }
            
            // 帮助说明弹窗内容
            helpModalContent
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .opacity)
                ))
        }
        .zIndex(1000)
        .animation(.easeInOut(duration: 0.2), value: showHelpModal)
    }
    
    /// 帮助说明弹窗内容
    private var helpModalContent: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.color(level: 5))
                
                Text("重复事件说明")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.titleTextColor)
                
                Spacer()
                
                Button(action: {
                    showHelpModal = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.descriptionTextColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // 分割线
            Divider()
                .background(themeManager.separatorColor)
            
            // 说明内容
            VStack(alignment: .leading, spacing: 20) {
                // 第1条说明
                helpItem(
                    icon: "pencil.circle.fill",
                    title: "如何修改重复事件?",
                    description: "您可以在事件弹窗中进行修改，并点击保存，选择全部修改。"
                )
                
                // 第2条说明
                helpItem(
                    icon: "trash.circle.fill",
                    title: "如何删除重复事件?",
                    description: "在事件弹窗或者重复事件管理中进行删除，选择全部删除。"
                )
                
                // 第3条说明
                helpItem(
                    icon: "gear.circle.fill",
                    title: "如何修改重复规则?",
                    description: "暂时无法修改，您可以删除全部后重新创建新的规则。"
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(width: 320)
        .background(themeManager.backgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
    
    /// 帮助说明项
    private func helpItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(themeManager.color(level: 5))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.titleTextColor)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.descriptionTextColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - 私有方法
    
    /// 加载重复任务数据
    private func loadRepeatTasks() {
        guard let repeatId = task.standbyStr1, !repeatId.isEmpty else {
            return
        }
        
        Task {
            do {
                // 查询所有重复任务（包括已完成的）
                let tasks = try await TDQueryConditionManager.shared.getDuplicateTasks(
                    standbyStr1: repeatId,
                    onlyUncompleted: false,
                    context: modelContext
                )
                
                await MainActor.run {
                    self.repeatTasks = tasks
                    print("✅ 加载重复任务成功，共 \(tasks.count) 个任务")
                }
                
            } catch {
                print("❌ 加载重复任务失败: \(error)")
            }
        }
    }
    
    /// 删除所有重复任务
    private func deleteAllRepeatTasks() {
        guard let repeatId = task.standbyStr1, !repeatId.isEmpty else {
            return
        }
        
        Task {
            do {
                // 查询所有重复任务（包括已完成的）
                let tasksToDelete = try await TDQueryConditionManager.shared.getDuplicateTasks(
                    standbyStr1: repeatId,
                    onlyUncompleted: false,
                    context: modelContext
                )
                
                // 标记所有任务为删除状态
                for taskToDelete in tasksToDelete {
                    taskToDelete.delete = true
                    taskToDelete.status = "delete"
                    _ = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(
                        updatedTask: taskToDelete,
                        context: modelContext
                    )
                }
                // 清空第二列选中的任务数据，避免第三列显示已删除任务的数据
                TDMainViewModel.shared.selectedTask = nil

                await MainActor.run {
                    // 删除成功后关闭弹窗
                    isPresented = false
                }
                
                print("✅ 删除重复事件组成功，共删除 \(tasksToDelete.count) 个任务")
                
            } catch {
                print("❌ 删除重复任务失败: \(error)")
            }
        }
    }
}

// MARK: - 任务行视图
struct TaskRowView: View {
    let task: TDMacSwiftDataListModel
    @EnvironmentObject private var themeManager: TDThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 任务标题
            Text(task.taskContent)
                .font(.system(size: 14))
                .foregroundColor(themeManager.titleTextColor)
                .lineLimit(1)
            
            // 日期
            Text(task.taskDate.dateAndWeekString)
                .font(.system(size: 12))
                .foregroundColor(themeManager.color(level: 5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(themeManager.backgroundColor)
        .overlay(
            Rectangle()
                .fill(themeManager.separatorColor)
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

//// MARK: - 预览
//#Preview {
//    let sampleTask = TDMacSwiftDataListModel(
//        taskContent: "示例任务",
//        todoTime: Date().fullTimestamp,
//        reminderTime: 0
//    )
//    
//    TDRepeatManagementView(isPresented: .constant(true), task: sampleTask)
//        .environmentObject(TDThemeManager.shared)
//}
