//
//  TDMainView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData

struct TDMainView: View {
    @StateObject private var mainViewModel = TDMainViewModel.shared
    @State private var searchText = ""
    @Environment(\.modelContext) private var modelContext
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 第一列 - 左侧导航栏
            TDSliderBarView()
                .navigationSplitViewColumnWidth(min: 216, ideal: 250, max: 300)
            
        } content: {
            // 第二列 - 根据选中的分类显示不同的视图
            Group {
                if mainViewModel.selectedCategory?.categoryId == -102 {
                    // 日程概览
                    TDCalendarView()
                } else {
                    // 其他分类显示任务列表
                    VStack(spacing: 0) {
                        // 顶部日期选择器（只在 DayTodo 视图下显示）
                        if mainViewModel.selectedCategory?.categoryId == -100 {
                            TDWeekDatePickerView()
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(.ultraThinMaterial)
                        }
                        
                        // 任务列表和悬浮输入框
                        ZStack(alignment: .top) {
                            // 任务列表
                            TDTaskListView()
                            
                            // 悬浮的任务输入框
                            TDTaskInputView()
                                .padding(.horizontal, 12)
                                .padding(.top, 10)
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 600, ideal: 833, max: .infinity)
            
        } detail: {
            // 第三列 - 任务详情
            TaskDetailView()
                .navigationSplitViewColumnWidth(min: 400, ideal: 450, max: .infinity)
        }
        .task {
            // 视图加载时启动同步
            await mainViewModel.syncAfterLaunch()
        }
    }
}
  



//    var body: some View {
//        ZStack(alignment: .top) {
//            Rectangle()
//                .fill(.red)
//            
//            HSplitView {
//                // 第一列 - 左侧导航栏
//                TDSliderBarView()
//                    .frame(minWidth: 216, maxWidth: 300)
//                
//                // 第二列 - 根据选中的分类显示不同的视图
//                if mainViewModel.selectedCategory?.categoryId == -102 {
//                    // 日程概览
//                    TDCalendarView()
//                        .frame(minWidth: 833)
//                } else {
//                    // 其他分类显示任务列表
//                    VStack(spacing: 0) {
//                        // 顶部日期选择器（只在 DayTodo 视图下显示）
//                        if mainViewModel.selectedCategory?.categoryId == -100 {
//                            TDWeekDatePickerView()
//                                .padding(.vertical, 8)
//                                .padding(.horizontal, 12)
//                                .background(.ultraThinMaterial)
//                        }
//                        
//                        // 任务列表和悬浮输入框
//                        ZStack(alignment: .top) {
//                            // 任务列表
//                            TDTaskListView()
//                            
//                            // 悬浮的任务输入框
//                            TDTaskInputView()
//                                .padding(.horizontal, 12)
//                                .padding(.top, 10)
//                        }
//                    }
//                    .frame(minWidth: 833)
//                }
//
////                TDTaskListView(
////                    selectedCategory: mainViewModel.selectedCategory
////                )
////                .frame(minWidth: 417)
////                .onChange(of: mainViewModel.shouldRefreshTaskList) { shouldRefresh in
////                    if shouldRefresh {
////                        // 当选中分类变化时，加载对应的任务列表
////                        Task {
////                            await mainViewModel.fetchTasksForSelectedCategory(modelContext: modelContext)
////                        }
////                    }
////                }
//
//                // 第三列 - 任务详情
//                TaskDetailView()
//                    .frame(minWidth: 400)
//            }
//            .background(.white)
//        }
//        .task {
//            // 视图加载时启动同步
//            await mainViewModel.syncAfterLaunch()
//        }
//
//    }
//}

//
//struct TDMainView: View {
////    @StateObject private var navigationState = NavigationState()
//        @State private var selectedCategory: TDSliderBarModel?
//    @State private var searchText = ""
//    @Environment(\.modelContext) private var modelContext
//
//    var body: some View {
//        
//        ZStack(alignment: .top) {
//            Rectangle()
//                .fill(.red)
//            HSplitView {
//                // 第一列 - 左侧导航栏
//                // 用户信息部分
//                TDSliderBarView()
//                .frame(minWidth: 216, maxWidth: 220)
//
//                // 第二列 - 任务列表
////                TDTaskListView(
////                    modelContext: modelContext,
////                    selectedCategory: Binding(
////                        get: { selectedCategory },
////                        set: { selectedCategory = $0 }
////                    )
////                )
////                .frame(minWidth: 417)
//
//                // 第三列 - 任务详情
//                TaskDetailView()
//                .frame(minWidth: 400)
////                .toolbar {
////                    ToolbarItem(placement: .automatic) {
////                        HStack(spacing: 8) {
////                            Spacer() // 将内容推到最右边
////
////                            HStack {
////                                Image(systemName: "magnifyingglass")
////                                    .foregroundColor(.secondary)
////                                TextField("搜索事件", text: .constant(""))
////                                    .textFieldStyle(PlainTextFieldStyle())
////                                    .frame(width: 120)
////                            }
////                            .padding(.horizontal, 6)
////                            .padding(.vertical, 4)
////                            .background(Color(.textBackgroundColor))
////                            .cornerRadius(6)
////
////                            Button(action: {}) {
////                                Image(systemName: "ellipsis.circle")
////                            }
////
////                            Button(action: {}) {
////                                Image(systemName: "gearshape")
////                            }
////                        }
////                        .frame(maxWidth: .infinity, alignment: .trailing)
////                    }
////                }
//
//            }
//            .background(.white)
//
//        }
//    }
//}
// 自定义标题栏
struct CustomTitleBar: View {
    @Binding var searchText: String
    @State private var selectedDate = Date()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
//            // 左侧窗口控制按钮
//            HStack(spacing: 8) {
//                Circle()
//                    .fill(Color.red)
//                    .frame(width: 12, height: 12)
//                Circle()
//                    .fill(Color.yellow)
//                    .frame(width: 12, height: 12)
//                Circle()
//                    .fill(Color.green)
//                    .frame(width: 12, height: 12)
//            }
//            .padding(.leading, 8)
            
            // 用户信息
            HStack(spacing: 4) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 16, height: 16)
                Text("VYTAS ZHAO")
                    .font(.system(size: 12))
                Text("diwww@gm...")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 8)
            
            // 日期导航
            HStack(spacing: 0) {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12))
                }
                
                ForEach(15...21, id: \.self) { day in
                    Text("\(day)")
                        .font(.system(size: 12))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(day == 18 ? Color.accentColor : Color.clear)
                        .cornerRadius(4)
                        .foregroundColor(day == 18 ? .white : .primary)
                }
                
                Button(action: {}) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(6)
            
            Text("11.18 周四")
                .font(.system(size: 12))
            
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索事件", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.textBackgroundColor))
            .cornerRadius(6)
            
            // 右侧按钮
            HStack(spacing: 8) {
                Button(action: {}) {
                    Image(systemName: "ellipsis.circle")
                }
                
                Button(action: {}) {
                    Image(systemName: "gearshape")
                }
            }
            .padding(.trailing, 8)
        }
        .padding(.vertical, 8)
        .background(colorScheme == .dark ? Color(.windowBackgroundColor) : Color(.windowBackgroundColor))
        .frame(height: 38)
    }
}
// 左侧导航栏
struct SidebarView: View {
    var body: some View {
        List {
            Section {
                NavigationLink(destination: Text("同步完成")) {
                    Label("同步完成", systemImage: "arrow.triangle.2.circlepath.circle")
                }
                
                NavigationLink(destination: DayTodoView()) {
                    Label("DayTodo", systemImage: "sun.max")
                }
                .badge(6)
                
                NavigationLink(destination: Text("最近待办")) {
                    Label("最近待办", systemImage: "clock")
                }
                
                NavigationLink(destination: Text("日程概览")) {
                    Label("日程概览", systemImage: "calendar")
                }
                
                NavigationLink(destination: Text("待办箱")) {
                    Label("待办箱", systemImage: "tray")
                }
            }
            
            Section("分类清单") {
                NavigationLink(destination: Text("未分类")) {
                    Label("未分类", systemImage: "circle")
                }
                
                NavigationLink(destination: Text("工作")) {
                    Label("工作", systemImage: "briefcase")
                }
                
                NavigationLink(destination: Text("生活")) {
                    Label("生活", systemImage: "house")
                }
                
                NavigationLink(destination: Text("Project-Pors")) {
                    Label("Project-Pors", systemImage: "folder")
                }
            }
            
            Section("标签") {
                Text("#所有标签")
                Text("#城投")
            }
        }
        .listStyle(SidebarListStyle())
    }
}

// 中间任务列表
struct TaskListView: View {
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.orange)
                TextField("在此编辑内容,按回车创建事件", text: $searchText)
                Image(systemName: "plus")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.textBackgroundColor))
            
            // 任务列表
            List {
                TaskRow(
                    title: "马尔斯绿Marrs green, 经历为期6个月的全球调查",
                    descriptions: ["流畅的页面展示,", "科学的功能呈现,", "带给用户赏心悦目的完美体验。"],
                    type: "工作",
                    time: "7:25",
                    repeatCount: 3
                )
                
                TaskRow(title: "摒弃了传统同类软件繁杂的日程管理流程，采用了最轻量的交互方式，用最助用户安排事项、管理时间。",
                       type: "旅游清单",
                       time: "7:25",
                       date: "今天 周四")
            }
        }
    }
}

// 任务行
struct TaskRow: View {
    let title: String
    var descriptions: [String]? = nil
    let type: String
    let time: String
    var repeatCount: Int? = nil
    var date: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题
            Text(title)
                .lineLimit(3)
            
            // 描述列表
            if let descriptions = descriptions {
                ForEach(descriptions, id: \.self) { desc in
                    Text(desc)
                        .foregroundColor(.secondary)
                }
            }
            
            // 底部信息
            HStack {
                Label(type, systemImage: "circle.fill")
                    .foregroundColor(.blue)
                
                Image(systemName: "clock")
                Text(time)
                
                if let repeatCount = repeatCount {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("\(repeatCount)")
                }
                
                if let date = date {
                    Text(date)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// 右侧任务详情
struct TaskDetailView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Task Content")
                .font(.headline)
            
            Text("describe")
                .foregroundColor(.secondary)
            
            Label("未分类", systemImage: "circle")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// DayTodo 视图
struct DayTodoView: View {
    var body: some View {
        Text("DayTodo")
    }
}

//struct TDMainView: View {
//
//    @State private var selectedCategory: TDSliderBarModel?
//
//    @State private var columnVisibility = NavigationSplitViewVisibility.all
//
//    var body: some View {
//
//        NavigationSplitView(columnVisibility: $columnVisibility) {
//            // 第一列：分类列表
//            TDSliderBarView(selection: Binding(
//                get: { selectedCategory },
//                set: { selectedCategory = $0 }
//            ))
//            .navigationSplitViewColumnWidth(min: 216, ideal: 220, max: 220)
//            .toolbarBackground(Color(hexString: "#282828").opacity(0.6))
//        } content: {
//            TaskListView()
//                .frame(minWidth: 417)
//                .navigationSplitViewColumnWidth(min: 417, ideal: 500, max: .infinity)
//
//                .toolbar(content: {
//                    ToolbarItem(placement: .automatic) {
//                        TDDetailToobarDateView()
//                            .frame(height: 32)
//                            .frame(maxWidth: .infinity)
//                    }
//                })
//        } detail: {
//            TaskDetailView()
//                .navigationSplitViewColumnWidth(min: 400, ideal: 500, max: .infinity)
//                .toolbar {
//                    ToolbarItem(placement: .automatic) {
//                        HStack(spacing: 8) {
//
//                            HStack {
//                                Image(systemName: "magnifyingglass")
//                                    .foregroundColor(.secondary)
//                                TextField("搜索事件", text: .constant(""))
//                                    .textFieldStyle(PlainTextFieldStyle())
//                                    .frame(width: 120)
//                            }
//                            .padding(.horizontal, 6)
//                            .padding(.vertical, 4)
//                            .background(Color(.textBackgroundColor))
//                            .cornerRadius(6)
//
//                            Button(action: {}) {
//                                Image(systemName: "ellipsis.circle")
//                            }
//
//                            Button(action: {}) {
//                                Image(systemName: "gearshape")
//                            }
//                        }
//                        .frame(maxWidth: .infinity)
//                    }
//                }
//        }
//
//    }
//}

#Preview {
    TDMainView()
}
