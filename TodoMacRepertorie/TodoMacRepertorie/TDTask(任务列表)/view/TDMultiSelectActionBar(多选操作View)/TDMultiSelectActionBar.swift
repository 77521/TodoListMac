//
//  TDMultiSelectActionBar.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/21.
//

import SwiftUI
import SwiftData

/// 多选操作栏组件
/// 提供多选模式下的各种操作功能，如全选、复制、删除、修改分类等
struct TDMultiSelectActionBar: View {
    // 主题管理器 - 用于获取颜色和样式
    @EnvironmentObject private var themeManager: TDThemeManager
    // 主视图模型 - 用于管理多选状态和任务操作
    @ObservedObject private var mainViewModel = TDMainViewModel.shared
    // SwiftData 上下文 - 用于数据库操作
    @Environment(\.modelContext) private var modelContext
        
    // 状态变量：控制Toast提示的显示
    @State private var showToast = false
    // 状态变量：控制复制成功Toast的显示
    @State private var showCopySuccessToast = false
    // 状态变量：控制日期选择器弹窗的显示
    @State private var showDatePicker = false
    // 状态变量：存储日期选择器中选中的日期
    @State private var selectedPickerDate = Date()

    
    // 传入的参数：当前分类的所有任务数组（@Query 数据，用于全选功能）
    let allTasks: [TDMacSwiftDataListModel]

    
    var body: some View {
        HStack(spacing: 15) {
            // 左边组：全选按钮 + 选中数量
            HStack(alignment: .center, spacing: 10.0) {
                // 全选按钮
                Button(action: {
                    mainViewModel.toggleSelectAll(allTasks: allTasks)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: mainViewModel.selectedTasks.count == allTasks.count ? "checkmark.square.fill" : "square")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.color(level: 5))
                        
                        Text(mainViewModel.selectedTasks.count == allTasks.count ? "deselect_all".localized : "select_all".localized)
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.color(level: 5))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()

                // 选中数量
                Text("selected_count".localizedFormat(mainViewModel.selectedTasks.count))
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.color(level: 5))
            }
            Spacer() // 添加 Spacer 让左右两组内容分别靠左和靠右

            // 右边组：操作按钮
            HStack(spacing: 8) {
                // 选择日期按钮 - 用于批量修改选中任务的日期
                Button(action: {
                    // 检查是否有选中的任务，如果没有则显示提示
                    if mainViewModel.selectedTasks.isEmpty {
                        showToast = true
                    } else {
                        // 有选中任务时，设置当前日期并显示日期选择器弹窗
                        selectedPickerDate = Date()
                        showDatePicker = true
                    }
                }) {
                    // 日历图标
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.color(level: 5))
                        .contentShape(Rectangle()) // 扩大点击区域
                }
                .buttonStyle(PlainButtonStyle()) // 使用无边框按钮样式
                .pointingHandCursor()
                .help("select_date".localized) // 鼠标悬停提示文字
                // 注意：这里使用 .sheet（居中弹窗），不是 popover（靠按钮的气泡）
                .sheet(isPresented: $showDatePicker) {
                    // 日期选择器弹窗 - 与顶部日期选择器使用相同的组件
                    TDCustomDatePickerView(
                        selectedDate: $selectedPickerDate, // 绑定的选中日期
                        isPresented: $showDatePicker, // 绑定的弹窗显示状态
                        onDateSelected: { date in
                            // 日期选择完成后的回调函数
                            // 将选择的日期转换为当前时区的开始时间戳（毫秒）
                            let startOfDayTimestamp = date.startOfDayTimestamp
                            
                            // 实现多选模式下选择日期的逻辑
                            Task {
                                await handleMultiSelectDateChange(
                                    selectedTimestamp: startOfDayTimestamp
                                )
                            }
                            
                            showDatePicker = false // 关闭弹窗
                        }
                    )
                    .frame(width: 320, height: 360)
                }

                // 复制按钮
                Button(action: {
                    if mainViewModel.selectedTasks.isEmpty {
                        showToast = true
                    } else {
                        // 实现复制功能
                        copySelectedTasksToClipboard()
                    }
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.color(level: 5))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
                .help("copy".localized)
                
                // 删除按钮
                Button(action: {
                    if mainViewModel.selectedTasks.isEmpty {
                        showToast = true
                    } else {
                        // 实现批量删除功能
                        deleteSelectedTasks()
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.color(level: 5))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
                .help("delete".localized)
                
                // 更多选项按钮 - 使用系统 Menu
                Menu {
                    if !mainViewModel.selectedTasks.isEmpty {
                        TDMacSelectMenu(
                            selectedTasks: mainViewModel.selectedTasks,
                            onCategorySelected: {
                                // 分类修改完成后的回调
                                print("✅ 分类修改完成")
                                mainViewModel.exitMultiSelectMode()
                            },
                            onNewCategory: {
                                // TODO: 实现新建分类功能
                                print("新建分类")
                            }
                        )
                    } else {
                        Button("modify_category".localized) {
                            showToast = true
                        }
                        .pointingHandCursor()
                    }
                    
                    // 根据选中任务的完成状态动态显示菜单项
                    if !mainViewModel.selectedTasks.isEmpty {
                        // 计算未完成的任务数量
                        let incompleteCount = mainViewModel.selectedTasks.filter { !$0.complete }.count
                        // 计算已完成的任务数量
                        let completeCount = mainViewModel.selectedTasks.filter { $0.complete }.count
                        
                        // 如果有未完成的任务，显示"达成事件"选项
                        if incompleteCount > 0 {
                            Button("complete_events".localizedFormat(incompleteCount)) {
                                // TODO: 实现达成事件功能
                                // 实现批量达成事件功能
                                toggleSelectedTasksCompletion(complete: true)
                            }
                        }
                        
                        // 如果有已完成的任务，显示"取消达成事件"选项
                        if completeCount > 0 {
                            Button("cancel_complete_events".localizedFormat(completeCount)) {
                                // TODO: 实现取消达成事件功能
                                toggleSelectedTasksCompletion(complete: false)
                            }
                            .pointingHandCursor()
                        }
                    }
                } label: {
                    Text("more".localized)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.color(level: 5))
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(4)
                }
                .help("more_options".localized)
                .menuStyle(.button)
                .frame(width: 60)

                // 退出多选按钮
                Button(action: {
                    mainViewModel.exitMultiSelectMode()
                }) {
                    Text("exit_multi_select".localized)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .frame(width: 80, alignment: .center)
                        .background(Color.gray)
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()

            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(themeManager.separatorColor),
            alignment: .top
        )
        .tdToastBottom(
            isPresenting: $showToast,
            message: "select_at_least_one_event".localized,
            type: .info
        )
        .tdToastBottom(
            isPresenting: $showCopySuccessToast,
            message: "copy_success_simple".localized,
            type: .success
        )
        // 外部触发：仅“重新安排”会发出一次性请求；右键“选择事件”不会发出请求，因此不会误弹窗
        // 仍用 task(id:)：支持“请求先发生、ActionBar 后挂载”的场景
        .task(id: mainViewModel.pendingMultiSelectDatePickerRequestId) {
            guard mainViewModel.isMultiSelectMode else { return }
            guard mainViewModel.pendingMultiSelectDatePickerRequestId != nil else { return }
            guard !mainViewModel.selectedTasks.isEmpty else {
                // 没有选中任务就不弹窗，并清空请求（避免卡住）
                mainViewModel.consumeMultiSelectDatePickerRequest()
                return
            }

            // 消费请求，确保后续 ActionBar 重建不会重复弹出
            mainViewModel.consumeMultiSelectDatePickerRequest()

            selectedPickerDate = Date()
            showDatePicker = true
        }

    }
    
    // MARK: - 多选操作辅助方法
    
    /// 将选中的任务内容复制到剪贴板
    private func copySelectedTasksToClipboard() {
        // 使用数据操作管理器复制任务
        let success = TDDataOperationManager.shared.copyTasksToClipboard(mainViewModel.selectedTasks)
        
        if success {
            // 显示复制成功提示
            showCopySuccessToast = true
        }
    }
    
    /// 批量删除选中的任务
    private func deleteSelectedTasks() {
        print("🗑️ 开始批量删除任务，选中任务数量: \(mainViewModel.selectedTasks.count)")
        
        Task {
            do {
                // 遍历选中的任务对象，逐个删除
                for selectedTask in mainViewModel.selectedTasks {
                    // 1. 创建更新后的任务模型
                    let updatedTask = selectedTask
                    updatedTask.delete = true
                    updatedTask.status = "delete"

                    // 2. 调用通用更新方法
                    let queryManager = TDQueryConditionManager()
                    let result = try await queryManager.updateLocalTaskWithModel(
                        updatedTask: updatedTask,
                        context: modelContext
                    )
                    
                    print("✅ 成功删除任务，taskId: \(selectedTask.taskId), 结果: \(result)")
                }
                // 4. 退出多选模式
                await MainActor.run {
                    mainViewModel.exitMultiSelectMode()
                }

                // 3. 执行同步操作
                await TDMainViewModel.shared.performSyncSeparately()
                
                
                print("✅ 批量删除任务完成，共删除 \(mainViewModel.selectedTasks.count) 个任务")
                
            } catch {
                print("❌ 批量删除任务失败: \(error)")
            }
        }
    }
    
    // MARK: - 多选日期变更处理方法
    
    /// 处理多选模式下的日期变更
    /// - Parameters:
    ///   - selectedTimestamp: 选择的新日期时间戳（毫秒）
    private func handleMultiSelectDateChange(
        selectedTimestamp: Int64
    ) async {
        print("🔄 开始批量更新任务日期，选中任务数量: \(mainViewModel.selectedTasks.count), 新时间戳: \(selectedTimestamp)")
        
        // 遍历选中的任务对象，逐个更新
        for selectedTask in mainViewModel.selectedTasks {
            do {
                // 1. 计算新日期对应的 taskSort 值
                let newTaskSort = try await TDQueryConditionManager.shared.calculateTaskSortForNewTask(
                    todoTime: selectedTimestamp,
                    context: modelContext
                )
                
                // 2. 创建更新后的任务模型
                let updatedTask = selectedTask
                updatedTask.todoTime = selectedTimestamp
                updatedTask.taskSort = newTaskSort
                
                // 3. 使用通用方法更新本地数据
                let result = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(
                    updatedTask: updatedTask,
                    context: modelContext
                )
                
                print("✅ 成功更新任务日期，taskId: \(selectedTask.taskId), todoTime: \(selectedTimestamp), taskSort: \(newTaskSort), 结果: \(result)")
                
            } catch {
                print("❌ 更新任务日期失败，taskId: \(selectedTask.taskId), 错误: \(error)")
            }
        }
        // 5. 退出多选模式
        await MainActor.run {
            mainViewModel.exitMultiSelectMode()
        }

        // 4. 执行同步操作
        await TDMainViewModel.shared.performSyncSeparately()
        
        
        print("✅ 批量更新任务日期完成，共更新 \(mainViewModel.selectedTasks.count) 个任务")
    }
    
    /// 批量切换选中任务的完成状态
    /// - Parameter complete: true 表示设置为已完成，false 表示设置为未完成
    private func toggleSelectedTasksCompletion(complete: Bool) {
        let actionName = complete ? "达成" : "取消达成"
        print("🔄 开始批量\(actionName)任务，选中任务数量: \(mainViewModel.selectedTasks.count)")
        
        Task {
            do {
                // 遍历选中的任务对象，逐个切换状态
                for selectedTask in mainViewModel.selectedTasks {
                    // 只处理状态不匹配的任务
                    if selectedTask.complete != complete {
                        // 1. 创建更新后的任务模型
                        let updatedTask = selectedTask
                        updatedTask.complete = complete // 设置为指定状态
                        
                        // 2. 调用通用更新方法
                        let queryManager = TDQueryConditionManager()
                        let result = try await queryManager.updateLocalTaskWithModel(
                            updatedTask: updatedTask,
                            context: modelContext
                        )
                        
                        print("✅ 成功\(actionName)任务，taskId: \(selectedTask.taskId), 结果: \(result)")
                    }
                }
                // 4. 退出多选模式
                await MainActor.run {
                    mainViewModel.exitMultiSelectMode()
                }

                // 3. 执行同步操作
                await TDMainViewModel.shared.performSyncSeparately()
                
                
                print("✅ 批量\(actionName)任务完成")
                
            } catch {
                print("❌ 批量\(actionName)任务失败: \(error)")
            }
        }
    }

}

#Preview {
    TDMultiSelectActionBar(allTasks: [])
        .environmentObject(TDThemeManager.shared)
}
