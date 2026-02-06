//
//  TDDayTodoView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData

/// DayTodo 界面 - 显示今天的任务
struct TDDayTodoView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    // 监听多选模式状态变化
    @ObservedObject private var mainViewModel = TDMainViewModel.shared
    
    // 使用 @Query 来实时监控任务数据
    @Query(sort: [
        SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
        SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
    ]) private var allTasks: [TDMacSwiftDataListModel]
    
    // 状态变量：控制复制成功Toast的显示
    @State private var showCopySuccessToast = false

    private let selectedDate: Date
    private let selectedCategory: TDSliderBarModel
    
    init(selectedDate: Date, category: TDSliderBarModel) {
        self.selectedDate = selectedDate
        self.selectedCategory = category
        
        // 根据传入的日期和分类初始化查询条件
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getDayTodoQuery(selectedDate: selectedDate)
//        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getExpiredUncompletedQuery(categoryId: -101)

        _allTasks = Query(filter: predicate, sort: sortDescriptors)

    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                Color(themeManager.backgroundColor)
                    .ignoresSafeArea(.container, edges: .all)
                ZStack{
                    if allTasks.isEmpty {
                        // 没有任务时显示空状态
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("今天没有任务")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("点击上方输入框添加新任务")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 60)
                    } else {
                        // 使用 List 显示任务数据，性能更好
                        List {
                            ForEach(allTasks.indices, id: \.self) { index in
                                let task = allTasks[index]
                                TDTaskRowView(
                                    task: task,
                                    category: selectedCategory,
                                    orderNumber: index + 1,
                                    isFirstRow: index == 0,
                                    isLastRow: index == allTasks.count - 1,
                                    onCopySuccess: {
                                        // 显示复制成功提示
                                        showCopySuccessToast = true
                                    }
                                )
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        // 性能优化
                        .scrollIndicators(.hidden)
                        .environment(\.defaultMinListRowHeight, 44) // 设置最小行高
                        .padding(.horizontal, -9) // 去掉 List 的左右间距
                        
                    }
                    
                }
                .padding(.top, 50)
                
                // 顶部日期选择器 - 紧贴左右上边缘
                TDWeekDatePickerView()
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color(themeManager.backgroundColor))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                
                // 悬浮任务输入框 - 悬浮在任务列表上方，向下偏移20pt
                TDTaskInputView()
                    .padding(.horizontal, 16)
                    .padding(.top, 80)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            // 多选操作栏 - 只在多选模式下显示
            if mainViewModel.isMultiSelectMode {
                TDMultiSelectActionBar(allTasks: allTasks)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 0)
                    .padding(.bottom, 0)
            }

        }
        
//        .onReceive(NotificationCenter.default.publisher(for: .dayTodoDataChanged)) { _ in
//            print("🔄 收到 DayTodo 数据变化通知，强制刷新查询")
//            // 通过改变状态来强制刷新视图
//            refreshTrigger = UUID()
//        }
        // 复制成功提示
        .tdToastBottom(
            isPresenting: $showCopySuccessToast,
            message: "copy_success_simple".localized,
            type: .success
        )

    }
    
}

// MARK: - 多选操作栏组件
//struct TDMultiSelectActionBar: View {
//    // 主题管理器 - 用于获取颜色和样式
//    @EnvironmentObject private var themeManager: TDThemeManager
//    // 主视图模型 - 用于管理多选状态和任务操作
//    @ObservedObject private var mainViewModel = TDMainViewModel.shared
//    
//    // 传入的参数：选中的任务数量、总任务数量、选中的任务ID数组
//    let totalCount: Int
//    let allTasks: [TDMacSwiftDataListModel]
//    // SwiftData 上下文 - 用于数据库操作
//    @Environment(\.modelContext) private var modelContext
//    
//    // 状态变量：控制Toast提示的显示
//    @State private var showToast = false
//    // 状态变量：控制复制成功Toast的显示
//    @State private var showCopySuccessToast = false
//
//    // 状态变量：控制日期选择器弹窗的显示
//    @State private var showDatePicker = false
//    // 状态变量：存储日期选择器中选中的日期
//    @State private var selectedPickerDate = Date()
//    
//    
//    var body: some View {
//        HStack (alignment: .center){
//            // 全选按钮
//            HStack(alignment: .center, spacing: 10.0){
//                Button(action: {
//                    mainViewModel.toggleSelectAll(allTasks: allTasks)
//                }) {
//                    HStack(spacing: 8) {
//                        Image(systemName: mainViewModel.selectedTasks.count == totalCount ? "checkmark.square.fill" : "square")
//                            .font(.system(size: 16))
//                            .foregroundColor(themeManager.color(level: 5))
//                        
//                        Text(mainViewModel.selectedTasks.count == totalCount ? "deselect_all".localized : "select_all".localized)
//                            .font(.system(size: 14))
//                            .foregroundColor(themeManager.color(level: 5))
//                    }
//                }
//                .buttonStyle(PlainButtonStyle())
//                
//                // 选中数量
//                Text("selected_count".localizedFormat(mainViewModel.selectedTasks.count))
//                    .font(.system(size: 14))
//                    .foregroundColor(themeManager.color(level: 5))
//                
//            }
//            
//            Spacer()
//            
//            // 操作按钮
//            HStack(spacing: 8) {
//                // 日历按钮
//                Button(action: {
//                    // TODO: 实现选择日期功能
//                    // 检查是否有选中的任务，如果没有则显示提示
//                    if mainViewModel.selectedTasks.isEmpty {
//                        showToast = true
//                    } else {
//                        // TODO: 实现选择日期功能
//                        // 有选中任务时，设置当前日期并显示日期选择器弹窗
//                        selectedPickerDate = Date()
//                        showDatePicker = true
//                    }
//                }) {
//                    Image(systemName: "calendar")
//                        .font(.system(size: 16))
//                        .foregroundColor(themeManager.color(level: 5))
//                        .contentShape(Rectangle())
//                }
//                .buttonStyle(PlainButtonStyle()) // 使用无边框按钮样式
//                .help("select_date".localized) // 鼠标悬停提示文字
//                .popover(isPresented: $showDatePicker) {
//                    // 日期选择器弹窗 - 与顶部日期选择器使用相同的组件
//                    TDCustomDatePickerView(
//                        selectedDate: $selectedPickerDate, // 绑定的选中日期
//                        isPresented: $showDatePicker, // 绑定的弹窗显示状态
//                        onDateSelected: { date in
//                            // 日期选择完成后的回调函数
//                            // TODO: 实现多选模式下选择日期的逻辑
//                            // 这里需要：1. 批量修改选中任务的日期 2. 更新数据库 3. 刷新界面 4. 退出多选模式
//                            print("多选模式下选择日期: \(date)")
//                            let startOfDayTimestamp = date.startOfDayTimestamp
//                            
//                            
//                            // 实现多选模式下选择日期的逻辑
//                            Task {
//                                await handleMultiSelectDateChange(
//                                    selectedTimestamp: startOfDayTimestamp
//                                )
//                            }
//                            showDatePicker = false // 关闭弹窗
//                            
//                        }
//                    )
//                    .frame(width: 280, height: 320) // 设置弹窗尺寸，与顶部日期选择器保持一致
//                }
//                
//                // 复制按钮
//                Button(action: {
//                    // TODO: 实现复制功能
//                    if mainViewModel.selectedTasks.isEmpty {
//                        showToast = true
//                    } else {
//                        // TODO: 实现复制功能
//                        // 实现复制功能
//                        copySelectedTasksToClipboard()
//                    }
//                }) {
//                    Image(systemName: "doc.on.doc")
//                        .font(.system(size: 14))
//                        .foregroundColor(themeManager.color(level: 5))
//                        .contentShape(Rectangle())
//                }
//                .buttonStyle(PlainButtonStyle())
//                .help("copy".localized)
//                
//                // 删除按钮
//                Button(action: {
//                    // TODO: 实现批量删除功能
//                    if mainViewModel.selectedTasks.isEmpty {
//                        showToast = true
//                    } else {
//                        // TODO: 实现批量删除功能
//                        // 实现批量删除功能
//                        deleteSelectedTasks()
//                    }
//                }) {
//                    Image(systemName: "trash")
//                        .font(.system(size: 16))
//                        .foregroundColor(themeManager.color(level: 5))
//                        .contentShape(Rectangle())
//                }
//                .buttonStyle(PlainButtonStyle())
//                .help("delete".localized)
//                
//                // 更多选项按钮 - 使用系统 Menu
//                Menu {
//                    if !mainViewModel.selectedTasks.isEmpty {
//                        TDMacSelectMenu(
//                            selectedTasks: mainViewModel.selectedTasks,
//                            onCategorySelected: {
//                                // 分类修改完成后的回调
//                                mainViewModel.exitMultiSelectMode()
//                            },
//                            onNewCategory: {
//                                // TODO: 实现新建分类功能
//                                print("新建分类")
//                            }
//                        )
//                    } else {
//                        Button("modify_category".localized) {
//                            showToast = true
//                        }
//                    }
//
//                    // 根据选中任务的完成状态动态显示菜单项
//                    if !mainViewModel.selectedTasks.isEmpty {
//                        // 计算未完成的任务数量
//                        let incompleteCount = mainViewModel.selectedTasks.filter { !$0.complete }.count
//                        // 计算已完成的任务数量
//                        let completeCount = mainViewModel.selectedTasks.filter { $0.complete }.count
//                        
//                        // 如果有未完成的任务，显示"达成事件"选项
//                        if incompleteCount > 0 {
//                            Button("complete_events".localizedFormat(incompleteCount)) {
//                                // TODO: 实现达成事件功能
//                                print("达成 \(incompleteCount) 个事件")
//                            }
//                        }
//                        
//                        // 如果有已完成的任务，显示"取消达成事件"选项
//                        if completeCount > 0 {
//                            Button("cancel_complete_events".localizedFormat(completeCount)) {
//                                // TODO: 实现取消达成事件功能
//                                print("取消达成 \(completeCount) 个事件")
//                            }
//                        }
//                    }
//                } label: {
//                    Text("more".localized)
//                        .font(.system(size: 12))
//                        .foregroundColor(themeManager.color(level: 5))
//                        .background(Color(.controlBackgroundColor))
//                        .cornerRadius(4)
//                }
//                .help("more_options".localized)
//                .menuStyle(.button)
//                .frame(width: 60)
//                
//                // 退出多选按钮
//                Button(action: {
//                    mainViewModel.exitMultiSelectMode()
//                }) {
//                    Text("exit_multi_select".localized)
//                        .font(.system(size: 13))
//                        .foregroundColor(.white)
//                        .padding(.horizontal, 14)
//                        .padding(.vertical, 8)
//                        .frame(width: 80, alignment: .center)
//                        .background(Color.gray)
//                        .cornerRadius(6)
//                }
//                .buttonStyle(PlainButtonStyle())
//                
//                
//            }
//            
//        }
//        .padding(.horizontal, 16)
//        .padding(.vertical, 12)
//        .background(Color(.controlBackgroundColor))
//        .overlay(
//            Rectangle()
//                .frame(height: 1)
//                .foregroundColor(themeManager.separatorColor),
//            alignment: .top
//        )
//        .tdToastBottom(
//            isPresenting: $showToast,
//            message: "select_at_least_one_event".localized,
//            type: .info
//        )
//        .tdToastBottom(
//            isPresenting: $showCopySuccessToast,
//            message: "copy_success".localizedFormat(mainViewModel.selectedTasks.count),
//            type: .success
//        )
//
//    }
//    
//    // MARK: - 多选日期变更处理方法
//    
//    /// 处理多选模式下的日期变更
//    /// - Parameters:
//    ///   - selectedTimestamp: 选择的新日期时间戳（毫秒）
//    private func handleMultiSelectDateChange(
//        selectedTimestamp: Int64
//    ) async {
//        print("🔄 开始批量更新任务日期，选中任务数量: \(mainViewModel.selectedTasks.count), 新时间戳: \(selectedTimestamp)")
//        
//        // 遍历选中的任务对象，逐个更新
//        for selectedTask in mainViewModel.selectedTasks {
//            do {
//                // 1. 计算新日期对应的 taskSort 值
//                let newTaskSort = try await TDQueryConditionManager.shared.calculateTaskSortForNewTask(
//                    todoTime: selectedTimestamp,
//                    context: modelContext
//                )
//                
//                // 2. 创建更新后的任务模型
//                let updatedTask = selectedTask
//                updatedTask.todoTime = selectedTimestamp
//                updatedTask.taskSort = newTaskSort
//                
//                // 3. 使用通用方法更新本地数据
//                let result = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(
//                    updatedTask: updatedTask,
//                    context: modelContext
//                )
//                
//                print("✅ 成功更新任务日期，taskId: \(selectedTask.taskId), todoTime: \(selectedTimestamp), taskSort: \(newTaskSort), 结果: \(result)")
//                
//            } catch {
//                print("❌ 更新任务日期失败，taskId: \(selectedTask.taskId), 错误: \(error)")
//            }
//        }
//        
//        // 4. 执行同步操作
//        await TDMainViewModel.shared.performSyncSeparately()
//        
//        // 5. 退出多选模式
//        await MainActor.run {
//            mainViewModel.exitMultiSelectMode()
//        }
//        
//        print("✅ 批量更新任务日期完成，共更新 \(mainViewModel.selectedTasks.count) 个任务")
//    }
//    
//    // MARK: - 多选操作辅助方法
//    
//    /// 将选中的任务内容复制到剪贴板
//    private func copySelectedTasksToClipboard() {
//        // 使用数据操作管理器复制任务
//        let success = TDDataOperationManager.shared.copyTasksToClipboard(mainViewModel.selectedTasks)
//        
//        if success {
//            // 显示复制成功提示
//            showCopySuccessToast = true
//        }
//    }
//
//    /// 批量删除选中的任务
//    private func deleteSelectedTasks() {
//        print("🗑️ 开始批量删除任务，选中任务数量: \(mainViewModel.selectedTasks.count)")
//        
//        Task {
//            do {
//                // 遍历选中的任务对象，逐个删除
//                for selectedTask in mainViewModel.selectedTasks {
//                    // 1. 创建更新后的任务模型
//                    let updatedTask = selectedTask
//                    updatedTask.delete = true
//                    
//                    // 2. 调用通用更新方法
//                    let queryManager = TDQueryConditionManager()
//                    let result = try await queryManager.updateLocalTaskWithModel(
//                        updatedTask: updatedTask,
//                        context: modelContext
//                    )
//                    
//                    print("✅ 成功删除任务，taskId: \(selectedTask.taskId), 结果: \(result)")
//                }
//                
//                // 3. 执行同步操作
//                await TDMainViewModel.shared.performSyncSeparately()
//                
//                // 4. 退出多选模式
//                await MainActor.run {
//                    mainViewModel.exitMultiSelectMode()
//                }
//                
//                print("✅ 批量删除任务完成，共删除 \(mainViewModel.selectedTasks.count) 个任务")
//                
//            } catch {
//                print("❌ 批量删除任务失败: \(error)")
//            }
//        }
//    }
//
//}

#Preview {
    TDDayTodoView(selectedDate: Date(), category: {
        let defaults = TDSliderBarModel.defaultItems(settingManager: TDSettingManager.shared)
        return defaults.first(where: { $0.categoryId == -100 }) ?? defaults[0]
    }())
        .environmentObject(TDThemeManager.shared)
}
