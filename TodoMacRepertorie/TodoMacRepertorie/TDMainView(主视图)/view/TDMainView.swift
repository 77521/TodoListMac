////
////  TDMainView.swift
////  TodoMacRepertorie
////
////  Created by 孬孬 on 2024/12/28.
////
//
//import SwiftUI
//import SwiftData
//
///// 主界面视图，负责整体布局和全局依赖注入
//struct TDMainView: View {
//    @EnvironmentObject private var mainViewModel: TDMainViewModel
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @EnvironmentObject private var settingManager: TDSettingManager
//    @Environment(\.modelContext) private var modelContext
//    @State private var columnVisibility = NavigationSplitViewVisibility.all
//
//    var body: some View {
//        NavigationSplitView(columnVisibility: $columnVisibility) {
//            // 左侧导航栏
//            TDSliderBarView()
//                .frame(minWidth: 216, idealWidth: 216, maxWidth: 280)
//                .background(Color(.windowBackgroundColor))
//                .toolbar {
//                    ToolbarItemGroup(placement: .automatic) {
//                        Spacer()
//                        Button(action: {}) {
//                            Image(systemName: "ellipsis.circle")
//                        }
//                        Button(action: {
//                            TDUserManager.shared.logoutCurrentUser()
//                        }) {
//                            Image(systemName: "gearshape")
//                        }
//                    }
//                }
//        } content: {
//            // 中间主内容区
//            Group {
//                if mainViewModel.selectedCategory?.categoryId == -102 {
//                    // 日程概览
//                    TDCalendarView()
//                } else {
//                    ZStack(alignment: .top) {
//                        VStack(spacing: 0) {
//                            // 日历头部
//                            ZStack(alignment: .top) {
//                                Rectangle()
//                                    .fill(Color(.windowBackgroundColor))
//                                    .frame(height: 50)
//                                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
//                                TDWeekDatePickerView()
//                                    .frame(height: 50)
//                                    .padding(.horizontal, 24)
//                                    .background(Color.clear)
//                            }
//                            // 任务列表
//                            TDTaskListView()
//                        }
//                        .ignoresSafeArea(.container, edges: .all)
//                        // 悬浮输入框
//                        TDTaskInputView()
//                            .padding(.horizontal, 24)
//                            .padding(.top, 80)
//                    }
//                    .ignoresSafeArea(.container, edges: .all)
//                }
//            }
//            .background(Color(.windowBackgroundColor))
//            .navigationSplitViewColumnWidth(
//                min: mainViewModel.selectedCategory?.categoryId == -102 ? 840 : 450,
//                ideal: mainViewModel.selectedCategory?.categoryId == -102 ? 840 : 450,
//                max: .infinity
//            )
//        } detail: {
//            // 右侧详情区
//            TaskDetailView()
//                .navigationSplitViewColumnWidth(min: 414, ideal: 414, max: .infinity)
//                .background(Color(.windowBackgroundColor))
//        }
//        .frame(minWidth: mainViewModel.selectedCategory?.categoryId == -102 ? 1500 : 1100, minHeight: 700)
//        .background(Color(.windowBackgroundColor))
//        .navigationTitle("")
//        .task {
//            // 启动时自动同步
//            try? await mainViewModel.syncAfterLogin()
//        }
//    }
//}
//
//
//
////    var body: some View {
////        ZStack(alignment: .top) {
////            Rectangle()
////                .fill(.red)
////            
////            HSplitView {
////                // 第一列 - 左侧导航栏
////                TDSliderBarView()
////                    .frame(minWidth: 216, maxWidth: 300)
////                
////                // 第二列 - 根据选中的分类显示不同的视图
////                if mainViewModel.selectedCategory?.categoryId == -102 {
////                    // 日程概览
////                    TDCalendarView()
////                        .frame(minWidth: 833)
////                } else {
////                    // 其他分类显示任务列表
////                    VStack(spacing: 0) {
////                        // 顶部日期选择器（只在 DayTodo 视图下显示）
////                        if mainViewModel.selectedCategory?.categoryId == -100 {
////                            TDWeekDatePickerView()
////                                .padding(.vertical, 8)
////                                .padding(.horizontal, 12)
////                                .background(.ultraThinMaterial)
////                        }
////                        
////                        // 任务列表和悬浮输入框
////                        ZStack(alignment: .top) {
////                            // 任务列表
////                            TDTaskListView()
////                            
////                            // 悬浮的任务输入框
////                            TDTaskInputView()
////                                .padding(.horizontal, 12)
////                                .padding(.top, 10)
////                        }
////                    }
////                    .frame(minWidth: 833)
////                }
////
//////                TDTaskListView(
//////                    selectedCategory: mainViewModel.selectedCategory
//////                )
//////                .frame(minWidth: 417)
//////                .onChange(of: mainViewModel.shouldRefreshTaskList) { shouldRefresh in
//////                    if shouldRefresh {
//////                        // 当选中分类变化时，加载对应的任务列表
//////                        Task {
//////                            await mainViewModel.fetchTasksForSelectedCategory(modelContext: modelContext)
//////                        }
//////                    }
//////                }
////
////                // 第三列 - 任务详情
////                TaskDetailView()
////                    .frame(minWidth: 400)
////            }
////            .background(.white)
////        }
////        .task {
////            // 视图加载时启动同步
////            await mainViewModel.syncAfterLaunch()
////        }
////
////    }
////}
//
////
//struct TDMainView: View {
//    @EnvironmentObject private var mainViewModel: TDMainViewModel
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @EnvironmentObject private var settingManager: TDSettingManager
//    @Environment(\.modelContext) private var modelContext
//    @State private var columnVisibility = NavigationSplitViewVisibility.all
//    @State private var selectedTask: TDMacSwiftDataListModel?
//
//    var body: some View {
//        NavigationSplitView(columnVisibility: $columnVisibility) {
//            // 第一列：分类导航栏
//            firstColumn
//        } content: {
//            // 第二列：任务列表
//            secondColumn
//        } detail: {
//            // 第三列：任务详情
//            thirdColumn
//        }
//        .frame(minWidth: minWidth, minHeight: 700)
//        .background(Color(.windowBackgroundColor))
//        .navigationTitle("")
//        .onChange(of: mainViewModel.selectedCategory) { _, _ in
//            // 当分类改变时，清空选中的任务（第三列消失）
//            withAnimation(.easeInOut(duration: 0.3)) {
//                selectedTask = nil
//            }
//        }
//        .task {
//            // 启动时自动同步
//             await mainViewModel.syncAfterLogin()
//        }
//    }
//    
//    // MARK: - 第一列：分类导航栏
//    private var firstColumn: some View {
//        TDSliderBarView()
//            .frame(minWidth: 216, idealWidth: 216, maxWidth: 280)
//            .background(Color(.windowBackgroundColor))
//            .toolbar {
//                ToolbarItemGroup(placement: .automatic) {
//                    Spacer()
//                    Button(action: {}) {
//                        Image(systemName: "ellipsis.circle")
//                    }
//                    Button(action: {
//                        TDUserManager.shared.logoutCurrentUser()
//                    }) {
//                        Image(systemName: "gearshape")
//                    }
//                }
//            }
//    }
//    
//    // MARK: - 第二列：任务列表
//    private var secondColumn: some View {
//        Group {
//            if isCalendarView {
//                // 日程概览
//                TDCalendarView()
//            } else {
//                taskListView
//            }
//        }
//        .background(Color(.windowBackgroundColor))
//        .navigationSplitViewColumnWidth(
//            min: columnMinWidth,
//            ideal: columnIdealWidth,
//            max: .infinity
//        )
//    }
//    
//    // MARK: - 任务列表视图
//    private var taskListView: some View {
//        ZStack(alignment: .top) {
//            VStack(spacing: 0) {
//                // 日历头部（只在 DayTodo 模式下显示）
//                if isDayTodoMode {
//                    dayTodoHeader
//                }
//                // 任务列表
//                TDTaskListView(selectedTask: $selectedTask)
//            }
//            .ignoresSafeArea(.container, edges: .all)
//            // 悬浮输入框
//            TDTaskInputView()
//                .padding(.horizontal, 24)
//                .padding(.top, inputTopPadding)
//        }
//        .ignoresSafeArea(.container, edges: .all)
//    }
//    
//    // MARK: - DayTodo 头部
//    private var dayTodoHeader: some View {
//        ZStack(alignment: .top) {
//            Rectangle()
//                .fill(Color(.windowBackgroundColor))
//                .frame(height: 50)
//                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
//            TDWeekDatePickerView()
//                .frame(height: 50)
//                .padding(.horizontal, 24)
//                .background(Color.clear)
//        }
//    }
//    
//    // MARK: - 第三列：任务详情
//    private var thirdColumn: some View {
//        Group {
//            if let selectedTask = selectedTask {
//                TaskDetailView(task: selectedTask)
//                    .navigationSplitViewColumnWidth(min: 414, ideal: 414, max: .infinity)
//                    .background(Color(.windowBackgroundColor))
//                    .transition(.asymmetric(
//                        insertion: .move(edge: .trailing).combined(with: .opacity),
//                        removal: .move(edge: .trailing).combined(with: .opacity)
//                    ))
//            } else {
//                // 未选择任务时的占位视图
//                emptyTaskDetailView
//            }
//        }
//    }
//    
//    // MARK: - 空任务详情占位视图
//    private var emptyTaskDetailView: some View {
//        VStack(spacing: 16) {
//            Image(systemName: "doc.text")
//                .font(.system(size: 48))
//                .foregroundColor(.secondary)
//            Text("选择任务查看详情")
//                .font(.headline)
//                .foregroundColor(.secondary)
//            Text("点击左侧任务列表中的任意任务")
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color(.windowBackgroundColor))
//    }
//    
//    // MARK: - 计算属性
//    private var isCalendarView: Bool {
//        mainViewModel.selectedCategory?.categoryId == -102
//    }
//    
//    private var isDayTodoMode: Bool {
//        mainViewModel.selectedCategory?.categoryId == -100
//    }
//    
//    private var columnMinWidth: CGFloat {
//        isCalendarView ? 840 : 450
//    }
//    
//    private var columnIdealWidth: CGFloat {
//        isCalendarView ? 840 : 450
//    }
//    
//    private var minWidth: CGFloat {
//        isCalendarView ? 1500 : 1100
//    }
//    
//    private var inputTopPadding: CGFloat {
//        isDayTodoMode ? 80 : 20
//    }
//}
//
//// 任务详情视图
//struct TaskDetailView: View {
//    let task: TDMacSwiftDataListModel
//    @EnvironmentObject private var themeManager: TDThemeManager
//    
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 20) {
//                // 任务标题
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("任务详情")
//                        .font(.title2)
//                        .fontWeight(.semibold)
//                    
//                    Text(task.taskContent)
//                        .font(.headline)
//                        .foregroundColor(themeManager.titleTextColor)
//                }
//                
//                Divider()
//                
//                // 任务描述
//                if let description = task.taskDescribe, !description.isEmpty {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("描述")
//                            .font(.subheadline)
//                            .fontWeight(.medium)
//                        Text(description)
//                            .font(.body)
//                            .foregroundColor(themeManager.titleTextColor)
//                    }
//                    Divider()
//                }
//                
//                // 分类信息
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("分类")
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                    HStack {
//                        Circle()
//                            .fill(Color.fromHex(task.standbyIntColor))
//                            .frame(width: 12, height: 12)
//                        Text(task.standbyIntName.isEmpty ? "未分类" : task.standbyIntName)
//                            .font(.body)
//                            .foregroundColor(themeManager.titleTextColor)
//                    }
//                }
//                
//                Divider()
//                
//                // 时间信息
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("时间")
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                    
//                    if task.todoTime > 0 {
//                        HStack {
//                            Image(systemName: "calendar")
//                                .foregroundColor(.secondary)
//                            Text(Date.fromTimestamp(task.todoTime).formatted(date: .abbreviated, time: .omitted))
//                                .font(.body)
//                                .foregroundColor(themeManager.titleTextColor)
//                        }
//                    }
//                    
//                    if task.reminderTime > 0 {
//                        HStack {
//                            Image(systemName: "bell")
//                                .foregroundColor(.secondary)
//                            Text(Date.fromTimestamp(task.reminderTime).formatted(date: .omitted, time: .shortened))
//                                .font(.body)
//                                .foregroundColor(themeManager.titleTextColor)
//                        }
//                    }
//                }
//                
//                Divider()
//                
//                // 子任务
//                if !task.subTaskList.isEmpty {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("子任务")
//                            .font(.subheadline)
//                            .fontWeight(.medium)
//                        
//                        ForEach(Array(task.subTaskList.enumerated()), id: \.offset) { index, subTask in
//                            HStack {
//                                Image(systemName: subTask.isComplete ? "checkmark.circle.fill" : "circle")
//                                    .foregroundColor(subTask.isComplete ? .green : .secondary)
//                                Text(subTask.content)
//                                    .font(.body)
//                                    .foregroundColor(subTask.isComplete ? themeManager.titleFinishTextColor : themeManager.titleTextColor)
//                                    .strikethrough(subTask.isComplete)
//                            }
//                        }
//                    }
//                    Divider()
//                }
//                
//                // 附件
//                if !task.attachmentList.isEmpty {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("附件")
//                            .font(.subheadline)
//                            .fontWeight(.medium)
//                        
//                        ForEach(Array(task.attachmentList.enumerated()), id: \.offset) { index, attachment in
//                            HStack {
//                                Image(systemName: attachment.isPhoto ? "photo" : "doc")
//                                    .foregroundColor(.secondary)
//                                VStack(alignment: .leading, spacing: 2) {
//                                    Text(attachment.name)
//                                        .font(.body)
//                                        .foregroundColor(themeManager.titleTextColor)
//                                    Text(attachment.size)
//                                        .font(.caption)
//                                        .foregroundColor(themeManager.descriptionTextColor)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//            .padding()
//        }
//    }
//}
//
//#Preview {
//    TDMainView()
//        .environmentObject(TDMainViewModel.shared)
//        .environmentObject(TDThemeManager.shared)
//        .environmentObject(TDSettingManager.shared)
//}

import SwiftUI
import SwiftData

/// 主界面视图 - 三列布局
struct TDMainView: View {
    @EnvironmentObject private var mainViewModel: TDMainViewModel
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var settingManager: TDSettingManager
    @Environment(\.modelContext) private var modelContext
    
    @ObservedObject private var dateManager = TDDateManager.shared

    // 控制第三列的显示/隐藏
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @State private var selectedTask: TDMacSwiftDataListModel?
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 第一列：分类导航栏
            firstColumn
            
        } content: {
            // 第二列：任务列表
            secondColumn
        } detail: {
            // 第三列：任务详情
            thirdColumn
        }
        .frame(minWidth: 1100, minHeight: 700)
        .background(Color(.windowBackgroundColor))
        .ignoresSafeArea(.container, edges: .all)
        .task {
            // 界面加载完成后，立即执行四个初始化请求和同步操作
            await mainViewModel.performInitialServerRequests()
            // 单独执行同步操作，避免线程优先级冲突
//            await mainViewModel.performSyncSeparately()

        }
    }
    
    // MARK: - 第一列：分类导航栏
    private var firstColumn: some View {
        TDSliderBarView()
            .frame(minWidth: 216, idealWidth: 216, maxWidth: 280)
            .background(Color(.windowBackgroundColor))
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Spacer()
                    
                    // 更多按钮
                    Button(action: {
                        // TODO: 更多操作
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 设置按钮
                    Button(action: {
                        // TODO: 设置操作
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
    }
    
    // MARK: - 第二列：任务列表
    private var secondColumn: some View {
        AnyView(
            Group {
                if let selectedCategory = mainViewModel.selectedCategory {
                    switch selectedCategory.categoryId {
                    case -100: // DayTodo
                        TDDayTodoView(selectedDate: dateManager.selectedDate, category: selectedCategory)
                    case -101: // 最近待办
                        TDTaskListView(category: selectedCategory)
                    case -102: // 日程概览
                        TDScheduleOverviewView()
                    case -103: // 待办箱
                        TDInboxView()
                    case -107: // 最近已完成
                        TDCompletedDeletedView(category: selectedCategory)
                    case -108: // 回收站
                        TDCompletedDeletedView(category: selectedCategory)
                    case -106: // 数据复盘
                        TDDataReviewView()
                    case 0: // 未分类
                        TDTaskListView(category: selectedCategory)
                    default: // 用户创建的分类
                        if selectedCategory.categoryId > 0 {
                            TDTaskListView(category: selectedCategory)
                        } else {
                            // 如果出现未知分类，默认显示DayTodo
                            TDDayTodoView(selectedDate: dateManager.selectedDate, category: selectedCategory)
                        }
                    }
                } else {
                    // 如果没有选中分类，默认显示DayTodo
                    TDDayTodoView(selectedDate: dateManager.selectedDate, category: TDSliderBarModel.defaultItems.first(where: { $0.categoryId == -100 }) ?? TDSliderBarModel.defaultItems[0])
                }
            }
            .frame(minWidth: 450, idealWidth: 450, maxWidth: .infinity)
            .background(Color(.windowBackgroundColor))
            .ignoresSafeArea(.container, edges: .all)

        )
    }
    
    // MARK: - 第三列：任务详情
    private var thirdColumn: some View {
        Group {
            if let selectedTask = selectedTask {
                // 有选中任务时，显示任务详情
                VStack {
                    Text("任务详情")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("任务标题：\(selectedTask.taskContent)")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                self.selectedTask = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if let description = selectedTask.taskDescribe {
                            Text("任务描述：\(description)")
                                .font(.body)
                        }
                        
                        Text("任务ID：\(selectedTask.taskId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                }
                .frame(minWidth: 414, idealWidth: 414, maxWidth: .infinity)
                .background(Color(.windowBackgroundColor))
            } else {
                // 没有选中任务时，显示占位界面
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("暂无数据显示")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("请选择左侧任务列表中的任意任务")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.windowBackgroundColor))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedTask != nil)
    }

}

#Preview {
    TDMainView()
        .environmentObject(TDMainViewModel.shared)
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
}
