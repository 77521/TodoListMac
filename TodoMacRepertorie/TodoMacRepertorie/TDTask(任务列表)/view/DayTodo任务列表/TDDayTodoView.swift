////
////  TDDayTodoView.swift
////  TodoMacRepertorie
////
////  Created by 孬孬 on 2024/12/28.
////
//
//import SwiftUI
//import SwiftData
//
///// DayTodo 界面 - 显示今天的任务
//struct TDDayTodoView: View {
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @Environment(\.modelContext) private var modelContext
//    // 监听多选模式状态变化
//    @ObservedObject private var mainViewModel = TDMainViewModel.shared
//
//    // 使用 @Query 来实时监控任务数据
//    @Query(sort: [
//        SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward),
//        SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
//    ]) private var allTasks: [TDMacSwiftDataListModel]
//
//    // 状态变量：控制复制成功Toast的显示
//    @State private var showCopySuccessToast = false
//
//    private let selectedDate: Date
//    private let selectedCategory: TDSliderBarModel
//
//    init(selectedDate: Date, category: TDSliderBarModel) {
//        self.selectedDate = selectedDate
//        self.selectedCategory = category
//
//        // 根据传入的日期和分类初始化查询条件
//        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getDayTodoQuery(selectedDate: selectedDate)
////        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getExpiredUncompletedQuery(categoryId: -101)
//
//        _allTasks = Query(filter: predicate, sort: sortDescriptors)
//
//    }
//
//    var body: some View {
//        VStack(spacing: 0) {
//            ZStack(alignment: .top) {
//                Color(themeManager.backgroundColor)
//                    .ignoresSafeArea(.container, edges: .all)
//                ZStack{
//                    if allTasks.isEmpty {
//                        // 没有任务时显示空状态
//                        VStack(spacing: 12) {
//                            Image(systemName: "checkmark.circle")
//                                .font(.system(size: 48))
//                                .foregroundColor(.secondary)
//
//                            Text("今天没有任务")
//                                .font(.headline)
//                                .foregroundColor(.secondary)
//
//                            Text("点击上方输入框添加新任务")
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
//                        }
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .padding(.top, 60)
//                    } else {
//                        // 使用 List 显示任务数据，性能更好
//                        List {
//                            ForEach(allTasks.indices, id: \.self) { index in
//                                let task = allTasks[index]
//                                TDTaskRowView(
//                                    task: task,
//                                    category: selectedCategory,
//                                    orderNumber: index + 1,
//                                    isFirstRow: index == 0,
//                                    isLastRow: index == allTasks.count - 1,
//                                    onCopySuccess: {
//                                        // 显示复制成功提示
//                                        showCopySuccessToast = true
//                                    }
//                                )
//                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
//                                .listRowBackground(Color.clear)
//                                .listRowSeparator(.hidden)
//                            }
//                        }
//                        .listStyle(.plain)
//                        .scrollContentBackground(.hidden)
//                        .background(Color.clear)
//                        // 性能优化
//                        .scrollIndicators(.hidden)
//                        .environment(\.defaultMinListRowHeight, 44) // 设置最小行高
//                        .padding(.horizontal, -9) // 去掉 List 的左右间距
//
//                    }
//
//                }
//                .padding(.top, 50)
//
//                // 顶部日期选择器 - 紧贴左右上边缘
//                TDWeekDatePickerView()
//                    .padding(.horizontal, 16)
//                    .frame(height: 50)
//                    .background(Color(themeManager.backgroundColor))
//                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
//
//
//                // 悬浮任务输入框 - 悬浮在任务列表上方，向下偏移20pt
//                TDTaskInputView()
//                    .padding(.horizontal, 16)
//                    .padding(.top, 80)
//                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
//            }
//            // 多选操作栏 - 只在多选模式下显示
//            if mainViewModel.isMultiSelectMode {
//                TDMultiSelectActionBar(allTasks: allTasks)
//                    .frame(maxWidth: .infinity)
//                    .padding(.horizontal, 0)
//                    .padding(.bottom, 0)
//            }
//
//        }
//
////        .onReceive(NotificationCenter.default.publisher(for: .dayTodoDataChanged)) { _ in
////            print("🔄 收到 DayTodo 数据变化通知，强制刷新查询")
////            // 通过改变状态来强制刷新视图
////            refreshTrigger = UUID()
////        }
//        // 复制成功提示
//        .tdToastBottom(
//            isPresenting: $showCopySuccessToast,
//            message: "copy_success_simple".localized,
//            type: .success
//        )
//
//    }
//
//}
//
//// MARK: - 多选操作栏组件
////struct TDMultiSelectActionBar: View {
////    // 主题管理器 - 用于获取颜色和样式
////    @EnvironmentObject private var themeManager: TDThemeManager
////    // 主视图模型 - 用于管理多选状态和任务操作
////    @ObservedObject private var mainViewModel = TDMainViewModel.shared
////
////    // 传入的参数：选中的任务数量、总任务数量、选中的任务ID数组
////    let totalCount: Int
////    let allTasks: [TDMacSwiftDataListModel]
////    // SwiftData 上下文 - 用于数据库操作
////    @Environment(\.modelContext) private var modelContext
////
////    // 状态变量：控制Toast提示的显示
////    @State private var showToast = false
////    // 状态变量：控制复制成功Toast的显示
////    @State private var showCopySuccessToast = false
////
////    // 状态变量：控制日期选择器弹窗的显示
////    @State private var showDatePicker = false
////    // 状态变量：存储日期选择器中选中的日期
////    @State private var selectedPickerDate = Date()
////
////
////    var body: some View {
////        HStack (alignment: .center){
////            // 全选按钮
////            HStack(alignment: .center, spacing: 10.0){
////                Button(action: {
////                    mainViewModel.toggleSelectAll(allTasks: allTasks)
////                }) {
////                    HStack(spacing: 8) {
////                        Image(systemName: mainViewModel.selectedTasks.count == totalCount ? "checkmark.square.fill" : "square")
////                            .font(.system(size: 16))
////                            .foregroundColor(themeManager.color(level: 5))
////
////                        Text(mainViewModel.selectedTasks.count == totalCount ? "deselect_all".localized : "select_all".localized)
////                            .font(.system(size: 14))
////                            .foregroundColor(themeManager.color(level: 5))
////                    }
////                }
////                .buttonStyle(PlainButtonStyle())
////
////                // 选中数量
////                Text("selected_count".localizedFormat(mainViewModel.selectedTasks.count))
////                    .font(.system(size: 14))
////                    .foregroundColor(themeManager.color(level: 5))
////
////            }
////
////            Spacer()
////
////            // 操作按钮
////            HStack(spacing: 8) {
////                // 日历按钮
////                Button(action: {
////                    // TODO: 实现选择日期功能
////                    // 检查是否有选中的任务，如果没有则显示提示
////                    if mainViewModel.selectedTasks.isEmpty {
////                        showToast = true
////                    } else {
////                        // TODO: 实现选择日期功能
////                        // 有选中任务时，设置当前日期并显示日期选择器弹窗
////                        selectedPickerDate = Date()
////                        showDatePicker = true
////                    }
////                }) {
////                    Image(systemName: "calendar")
////                        .font(.system(size: 16))
////                        .foregroundColor(themeManager.color(level: 5))
////                        .contentShape(Rectangle())
////                }
////                .buttonStyle(PlainButtonStyle()) // 使用无边框按钮样式
////                .help("select_date".localized) // 鼠标悬停提示文字
////                .popover(isPresented: $showDatePicker) {
////                    // 日期选择器弹窗 - 与顶部日期选择器使用相同的组件
////                    TDCustomDatePickerView(
////                        selectedDate: $selectedPickerDate, // 绑定的选中日期
////                        isPresented: $showDatePicker, // 绑定的弹窗显示状态
////                        onDateSelected: { date in
////                            // 日期选择完成后的回调函数
////                            // TODO: 实现多选模式下选择日期的逻辑
////                            // 这里需要：1. 批量修改选中任务的日期 2. 更新数据库 3. 刷新界面 4. 退出多选模式
////                            print("多选模式下选择日期: \(date)")
////                            let startOfDayTimestamp = date.startOfDayTimestamp
////
////
////                            // 实现多选模式下选择日期的逻辑
////                            Task {
////                                await handleMultiSelectDateChange(
////                                    selectedTimestamp: startOfDayTimestamp
////                                )
////                            }
////                            showDatePicker = false // 关闭弹窗
////
////                        }
////                    )
////                    .frame(width: 280, height: 320) // 设置弹窗尺寸，与顶部日期选择器保持一致
////                }
////
////                // 复制按钮
////                Button(action: {
////                    // TODO: 实现复制功能
////                    if mainViewModel.selectedTasks.isEmpty {
////                        showToast = true
////                    } else {
////                        // TODO: 实现复制功能
////                        // 实现复制功能
////                        copySelectedTasksToClipboard()
////                    }
////                }) {
////                    Image(systemName: "doc.on.doc")
////                        .font(.system(size: 14))
////                        .foregroundColor(themeManager.color(level: 5))
////                        .contentShape(Rectangle())
////                }
////                .buttonStyle(PlainButtonStyle())
////                .help("copy".localized)
////
////                // 删除按钮
////                Button(action: {
////                    // TODO: 实现批量删除功能
////                    if mainViewModel.selectedTasks.isEmpty {
////                        showToast = true
////                    } else {
////                        // TODO: 实现批量删除功能
////                        // 实现批量删除功能
////                        deleteSelectedTasks()
////                    }
////                }) {
////                    Image(systemName: "trash")
////                        .font(.system(size: 16))
////                        .foregroundColor(themeManager.color(level: 5))
////                        .contentShape(Rectangle())
////                }
////                .buttonStyle(PlainButtonStyle())
////                .help("delete".localized)
////
////                // 更多选项按钮 - 使用系统 Menu
////                Menu {
////                    if !mainViewModel.selectedTasks.isEmpty {
////                        TDMacSelectMenu(
////                            selectedTasks: mainViewModel.selectedTasks,
////                            onCategorySelected: {
////                                // 分类修改完成后的回调
////                                mainViewModel.exitMultiSelectMode()
////                            },
////                            onNewCategory: {
////                                // TODO: 实现新建分类功能
////                                print("新建分类")
////                            }
////                        )
////                    } else {
////                        Button("modify_category".localized) {
////                            showToast = true
////                        }
////                    }
////
////                    // 根据选中任务的完成状态动态显示菜单项
////                    if !mainViewModel.selectedTasks.isEmpty {
////                        // 计算未完成的任务数量
////                        let incompleteCount = mainViewModel.selectedTasks.filter { !$0.complete }.count
////                        // 计算已完成的任务数量
////                        let completeCount = mainViewModel.selectedTasks.filter { $0.complete }.count
////
////                        // 如果有未完成的任务，显示"达成事件"选项
////                        if incompleteCount > 0 {
////                            Button("complete_events".localizedFormat(incompleteCount)) {
////                                // TODO: 实现达成事件功能
////                                print("达成 \(incompleteCount) 个事件")
////                            }
////                        }
////
////                        // 如果有已完成的任务，显示"取消达成事件"选项
////                        if completeCount > 0 {
////                            Button("cancel_complete_events".localizedFormat(completeCount)) {
////                                // TODO: 实现取消达成事件功能
////                                print("取消达成 \(completeCount) 个事件")
////                            }
////                        }
////                    }
////                } label: {
////                    Text("more".localized)
////                        .font(.system(size: 12))
////                        .foregroundColor(themeManager.color(level: 5))
////                        .background(Color(.controlBackgroundColor))
////                        .cornerRadius(4)
////                }
////                .help("more_options".localized)
////                .menuStyle(.button)
////                .frame(width: 60)
////
////                // 退出多选按钮
////                Button(action: {
////                    mainViewModel.exitMultiSelectMode()
////                }) {
////                    Text("exit_multi_select".localized)
////                        .font(.system(size: 13))
////                        .foregroundColor(.white)
////                        .padding(.horizontal, 14)
////                        .padding(.vertical, 8)
////                        .frame(width: 80, alignment: .center)
////                        .background(Color.gray)
////                        .cornerRadius(6)
////                }
////                .buttonStyle(PlainButtonStyle())
////
////
////            }
////
////        }
////        .padding(.horizontal, 16)
////        .padding(.vertical, 12)
////        .background(Color(.controlBackgroundColor))
////        .overlay(
////            Rectangle()
////                .frame(height: 1)
////                .foregroundColor(themeManager.separatorColor),
////            alignment: .top
////        )
////        .tdToastBottom(
////            isPresenting: $showToast,
////            message: "select_at_least_one_event".localized,
////            type: .info
////        )
////        .tdToastBottom(
////            isPresenting: $showCopySuccessToast,
////            message: "copy_success".localizedFormat(mainViewModel.selectedTasks.count),
////            type: .success
////        )
////
////    }
////
////    // MARK: - 多选日期变更处理方法
////
////    /// 处理多选模式下的日期变更
////    /// - Parameters:
////    ///   - selectedTimestamp: 选择的新日期时间戳（毫秒）
////    private func handleMultiSelectDateChange(
////        selectedTimestamp: Int64
////    ) async {
////        print("🔄 开始批量更新任务日期，选中任务数量: \(mainViewModel.selectedTasks.count), 新时间戳: \(selectedTimestamp)")
////
////        // 遍历选中的任务对象，逐个更新
////        for selectedTask in mainViewModel.selectedTasks {
////            do {
////                // 1. 计算新日期对应的 taskSort 值
////                let newTaskSort = try await TDQueryConditionManager.shared.calculateTaskSortForNewTask(
////                    todoTime: selectedTimestamp,
////                    context: modelContext
////                )
////
////                // 2. 创建更新后的任务模型
////                let updatedTask = selectedTask
////                updatedTask.todoTime = selectedTimestamp
////                updatedTask.taskSort = newTaskSort
////
////                // 3. 使用通用方法更新本地数据
////                let result = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(
////                    updatedTask: updatedTask,
////                    context: modelContext
////                )
////
////                print("✅ 成功更新任务日期，taskId: \(selectedTask.taskId), todoTime: \(selectedTimestamp), taskSort: \(newTaskSort), 结果: \(result)")
////
////            } catch {
////                print("❌ 更新任务日期失败，taskId: \(selectedTask.taskId), 错误: \(error)")
////            }
////        }
////
////        // 4. 执行同步操作
////        await TDMainViewModel.shared.performSyncSeparately()
////
////        // 5. 退出多选模式
////        await MainActor.run {
////            mainViewModel.exitMultiSelectMode()
////        }
////
////        print("✅ 批量更新任务日期完成，共更新 \(mainViewModel.selectedTasks.count) 个任务")
////    }
////
////    // MARK: - 多选操作辅助方法
////
////    /// 将选中的任务内容复制到剪贴板
////    private func copySelectedTasksToClipboard() {
////        // 使用数据操作管理器复制任务
////        let success = TDDataOperationManager.shared.copyTasksToClipboard(mainViewModel.selectedTasks)
////
////        if success {
////            // 显示复制成功提示
////            showCopySuccessToast = true
////        }
////    }
////
////    /// 批量删除选中的任务
////    private func deleteSelectedTasks() {
////        print("🗑️ 开始批量删除任务，选中任务数量: \(mainViewModel.selectedTasks.count)")
////
////        Task {
////            do {
////                // 遍历选中的任务对象，逐个删除
////                for selectedTask in mainViewModel.selectedTasks {
////                    // 1. 创建更新后的任务模型
////                    let updatedTask = selectedTask
////                    updatedTask.delete = true
////
////                    // 2. 调用通用更新方法
////                    let queryManager = TDQueryConditionManager()
////                    let result = try await queryManager.updateLocalTaskWithModel(
////                        updatedTask: updatedTask,
////                        context: modelContext
////                    )
////
////                    print("✅ 成功删除任务，taskId: \(selectedTask.taskId), 结果: \(result)")
////                }
////
////                // 3. 执行同步操作
////                await TDMainViewModel.shared.performSyncSeparately()
////
////                // 4. 退出多选模式
////                await MainActor.run {
////                    mainViewModel.exitMultiSelectMode()
////                }
////
////                print("✅ 批量删除任务完成，共删除 \(mainViewModel.selectedTasks.count) 个任务")
////
////            } catch {
////                print("❌ 批量删除任务失败: \(error)")
////            }
////        }
////    }
////
////}
//
//#Preview {
//    TDDayTodoView(selectedDate: Date(), category: {
//        let defaults = TDSliderBarModel.defaultItems(settingManager: TDSettingManager.shared)
//        return defaults.first(where: { $0.categoryId == -100 }) ?? defaults[0]
//    }())
//        .environmentObject(TDThemeManager.shared)
//}



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
    
    /// 拖拽排序：当前被拖拽的任务
    @State private var draggedTask: TDMacSwiftDataListModel?
    
    /// 拖拽排序：预览插入位置（只用于 UI 占位，不写库）
    @State private var dragPlaceholderIndex: Int?
    
    /// 拖拽时自动滚动（-1 向上，1 向下，0 停止）
    @State private var dragAutoScrollDirection: Int = 0

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
        let items = buildDragRenderItems(allTasks: allTasks)
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
                        ScrollViewReader { proxy in
                            // 使用 List 显示任务数据，性能更好
                            List {
                                ForEach(items.indices, id: \.self) { index in
                                    let item = items[index]
                                    TDTaskRowView(
                                        task: item.task,
                                        category: selectedCategory,
                                        orderNumber: index + 1,
                                        isFirstRow: index == 0,
                                        isLastRow: index == items.count - 1,
                                        onCopySuccess: {
                                            // 显示复制成功提示（统一走全局 Toast Center）
                                            TDToastCenter.shared.show(
                                                "copy_success_simple",
                                                type: .success,
                                                position: .bottom
                                            )
                                        }
                                    )
                                    .id(item.id)
                                    // MARK: - 长按拖拽排序（系统自带）
                                    .onDrag({
                                        guard !item.isPlaceholder else {
                                            return NSItemProvider()
                                        }
                                        draggedTask = item.task
                                        // 初始占位：原位置（拖拽中“列表里多出一行占位”，内容与拖拽行一致）
                                        dragPlaceholderIndex = currentIndexInAllTasks(of: item.task, allTasks: allTasks)
                                        return NSItemProvider(object: item.task.taskId as NSString)
                                    }, preview: {
                                        TDTaskRowView(
                                            task: item.task,
                                            category: selectedCategory,
                                            orderNumber: index + 1,
                                            isFirstRow: index == 0,
                                            isLastRow: items.count - 1 == index,
                                            onCopySuccess: { }
                                        )
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color(themeManager.backgroundColor))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(themeManager.color(level: 5), lineWidth: 1.5)
                                        )
                                    })
                                    .onDrop(of: [.text], delegate: TDDayTodoTaskDropDelegate(
                                        destinationTask: item.task,
                                        allTasksProvider: { allTasks },
                                        draggedTask: $draggedTask,
                                        placeholderIndex: $dragPlaceholderIndex,
                                        autoScrollDirection: $dragAutoScrollDirection,
                                        context: modelContext,
                                        onDenied: { messageKey in
                                            // 拖拽排序被拒绝提示（仅在松手时触发）
                                            TDToastCenter.shared.show(
                                                messageKey,
                                                type: .info,
                                                position: .bottom
                                            )
                                        }
                                    ))
                                    // “预览插入位”：占位行样式（圆角 + 主题色边框 + 半透明）
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(themeManager.color(level: 5), lineWidth: 1.4)
                                            .opacity(item.isPlaceholder ? 1 : 0)
                                    )
                                    .opacity(item.isPlaceholder ? 0.55 : 1)
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
                            .onAppear {
                                if let id = mainViewModel.selectedTask?.taskId {
                                    DispatchQueue.main.async {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            proxy.scrollTo(id, anchor: .center)
                                        }
                                    }
                                }
                            }
                            .onChange(of: mainViewModel.selectedTask?.taskId) { _, newId in
                                guard let newId else { return }
                                DispatchQueue.main.async {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        proxy.scrollTo(newId, anchor: .center)
                                    }
                                }
                            }
                            // 拖拽“占位行”过渡
                            .animation(.easeInOut(duration: 0.15), value: items.map(\.id))
                            // 自动滚动：拖到顶部/底部时，持续把占位行滚入视野
                            .onReceive(Timer.publish(every: 0.06, on: .main, in: .common).autoconnect()) { _ in
                                guard draggedTask != nil else { return }
                                guard dragAutoScrollDirection != 0 else { return }
                                guard let placeholderId = items.first(where: { $0.isPlaceholder })?.id else { return }

                                // 先推进占位插入点（允许拖拽时一路滚到更远的位置）
                                if let draggedTask {
                                    let baseCount = max(allTasks.filter { $0.taskId != draggedTask.taskId }.count, 0)
                                    let maxIndex = baseCount
                                    let nextIndex = min(max((dragPlaceholderIndex ?? 0) + dragAutoScrollDirection, 0), maxIndex)
                                    if dragPlaceholderIndex != nextIndex {
                                        dragPlaceholderIndex = nextIndex
                                    }
                                }

                                withAnimation(.easeInOut(duration: 0.1)) {
                                    proxy.scrollTo(placeholderId, anchor: dragAutoScrollDirection < 0 ? .top : .bottom)
                                }
                            }
                            .overlay {
                                // 边缘自动滚动区：仅拖拽时启用
                                if draggedTask != nil {
                                    VStack(spacing: 0) {
                                        Color.clear
                                            .frame(height: 44)
                                            .contentShape(Rectangle())
                                            .onDrop(of: [.text], delegate: TDDayTodoAutoScrollEdgeDropDelegate(direction: -1, autoScrollDirection: $dragAutoScrollDirection))
                                        Spacer(minLength: 0)
                                        Color.clear
                                            .frame(height: 44)
                                            .contentShape(Rectangle())
                                            .onDrop(of: [.text], delegate: TDDayTodoAutoScrollEdgeDropDelegate(direction: 1, autoScrollDirection: $dragAutoScrollDirection))
                                    }
                                    .allowsHitTesting(true)
                                }
                            }
                        }
                        
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
    }
    
}

// MARK: - Drag Render Items（DayTodo）

private extension TDDayTodoView {
    struct TDDragRenderItem: Identifiable {
        let id: String
        let task: TDMacSwiftDataListModel
        let isPlaceholder: Bool
    }
    
    func currentIndexInAllTasks(of task: TDMacSwiftDataListModel, allTasks: [TDMacSwiftDataListModel]) -> Int {
        allTasks.firstIndex(where: { $0.taskId == task.taskId }) ?? 0
    }
    
    func buildDragRenderItems(allTasks: [TDMacSwiftDataListModel]) -> [TDDragRenderItem] {
        guard let draggedTask else {
            return allTasks.map { TDDragRenderItem(id: $0.taskId, task: $0, isPlaceholder: false) }
        }
        // 拖拽中：从列表里移除原行，并在当前落点插入一行占位（显示同样数据）
        var base = allTasks.filter { $0.taskId != draggedTask.taskId }
        let safeIndex = min(max(dragPlaceholderIndex ?? 0, 0), base.count)
        base.insert(draggedTask, at: safeIndex)
        
        return base.enumerated().map { idx, task in
            if task.taskId == draggedTask.taskId, idx == safeIndex {
                return TDDragRenderItem(id: "placeholder-\(task.taskId)", task: task, isPlaceholder: true)
            } else {
                return TDDragRenderItem(id: task.taskId, task: task, isPlaceholder: false)
            }
        }
    }
}

// MARK: - DayTodo：任务拖拽排序 DropDelegate

/// DayTodo 列表拖拽排序代理（对齐 iOS：仅允许在同“完成状态”分段内排序）
private struct TDDayTodoTaskDropDelegate: DropDelegate {
    let destinationTask: TDMacSwiftDataListModel
    let allTasksProvider: () -> [TDMacSwiftDataListModel]

    @Binding var draggedTask: TDMacSwiftDataListModel?
    @Binding var placeholderIndex: Int?
    @Binding var autoScrollDirection: Int
    let context: ModelContext
    let onDenied: (String) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggedTask else { return }
        guard draggedTask.taskId != destinationTask.taskId else { return }

        // 拖拽过程中：只更新“占位插入位置”，不做校验/写库/同步
        // 关键：用“稳定的 baseIndex”（从原始数组里找），避免占位插入后 index 变化导致来回跳
        let base = allTasksProvider().filter { $0.taskId != draggedTask.taskId }
        let stableIndex = base.firstIndex(where: { $0.taskId == destinationTask.taskId }) ?? base.count
        withAnimation(.easeInOut(duration: 0.15)) {
            if placeholderIndex != stableIndex {
                placeholderIndex = stableIndex
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        defer {
            // 松手：结束预览态
            placeholderIndex = nil
            draggedTask = nil
            autoScrollDirection = 0
        }
        guard let draggedTask else { return true }
        
        // 只在松手时做一次性校验/计算/写库/同步
        let allTasks = allTasksProvider()
        var simulated = allTasks.filter { $0.taskId != draggedTask.taskId }
        let safeIndex = min(max(placeholderIndex ?? 0, 0), simulated.count)
        simulated.insert(draggedTask, at: safeIndex)
        let newIndex = safeIndex

        // DayTodo 规则：
        // - 已完成事件：不能放到任何“未完成”之前（即 next 是未完成时禁止）
        // - 未完成事件：不能放到任何“已完成”之后（即 top 是已完成时禁止）
        if let deniedKey = TDDragSortValidation.deniedMessageKey(
            draggedComplete: draggedTask.complete,
            in: simulated,
            at: newIndex
        ) {
            onDenied(deniedKey)
            return true
        }

        // 计算移动后的上下相邻 taskSort（只在“同完成状态”内找）
        let (top, next) = TDTaskDragSortHelper.findTopAndNextTaskSort(
            in: simulated,
            at: newIndex,
            where: { $0.complete == draggedTask.complete }
        )

        var newSort = TDTaskSortCalculator.getMoveCurrentTaskSortValue(
            currentTaskSort: draggedTask.taskSort,
            topTaskSort: top,
            nextTaskSort: next
        )
        if top == nil, next == nil {
            newSort = TDAppConfig.defaultTaskSort
        }

        let updated = draggedTask
        updated.taskSort = newSort

        Task {
            do {
                _ = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(
                    updatedTask: updated,
                    context: context
                )
                await TDMainViewModel.shared.performSyncSeparately()
            } catch {
                print("❌ DayTodo 拖拽排序更新失败: \(error)")
            }
        }
        return true
    }
}

/// DayTodo：拖拽靠边自动滚动
private struct TDDayTodoAutoScrollEdgeDropDelegate: DropDelegate {
    let direction: Int
    @Binding var autoScrollDirection: Int
    
    func dropEntered(info: DropInfo) {
        autoScrollDirection = direction
        _ = info
    }
    
    func dropExited(info: DropInfo) {
        autoScrollDirection = 0
        _ = info
    }
    
    func performDrop(info: DropInfo) -> Bool {
        autoScrollDirection = 0
        _ = info
        return true
    }
}

// MARK: - 拖拽排序校验（提示语按 iOS 规则）

private enum TDDragSortValidation {
    /// 按“移动后”的相邻项，给出拒绝提示 key
    static func deniedMessageKey(
        draggedComplete: Bool,
        in moved: [TDMacSwiftDataListModel],
        at index: Int
    ) -> String? {
        let top = index > 0 ? moved[index - 1] : nil
        let next = index < moved.count - 1 ? moved[index + 1] : nil

        // 已完成：如果下一个是未完成，说明被放到了未完成之前 → 禁止
        if draggedComplete, let next, next.complete == false {
            return "task.drag.denied.to_uncompleted"
        }
        // 未完成：如果上一个是已完成，说明被放到了已完成之后 → 禁止
        if !draggedComplete, let top, top.complete == true {
            return "task.drag.denied.to_completed"
        }
        return nil
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
