
//
//  TDMainView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

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
    @State private var columnVisibility = NavigationSplitViewVisibility.all
//    @State private var selectedTask: TDMacSwiftDataListModel?
    
    // 计算最小宽度：基础宽度 + 第三列宽度（如果显示）
    private var minWidth: CGFloat {
        let baseWidth: CGFloat = 260 + 450 // 基础宽度（不包含第三列）
        return mainViewModel.selectedTask != nil ? baseWidth + 414 : baseWidth
    }

    var body: some View {
//        NavigationSplitView(columnVisibility: $columnVisibility) {
//            // 第一列：分类导航栏
//            firstColumn
//            
//        } content: {
//            // 第二列：任务列表
//            secondColumn
//        } detail: {
//            // 第三列：任务详情
//            thirdColumn
//        }
//        .frame(minWidth: 1100, minHeight: 700)
//        .background(Color(.windowBackgroundColor))
//        .ignoresSafeArea(.container, edges: .all)
//        .task {
//            // 针对 macOS 26 强制显示三列
//            DispatchQueue.main.async {
//                columnVisibility = .all
//            }
//
//            // 界面加载完成后，立即执行四个初始化请求和同步操作
//            await mainViewModel.performInitialServerRequests()
//            // 单独执行同步操作，避免线程优先级冲突
////            await mainViewModel.performSyncSeparately()
//
//        }
        // 使用 HSplitView 实现三列布局 - 替代 NavigationSplitView
        HSplitView {
            // 第一列：分类导航栏
            firstColumn
            
            // 第二列：任务列表
            secondColumn
            
//            // 第三列：任务详情
//            thirdColumn
            // 第三列：任务详情 - 根据 selectedTask 显示/隐藏
            // 第三列：任务详情 - 根据 selectedTask 显示/隐藏
            if mainViewModel.selectedTask != nil {
                thirdColumn
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .scale(scale: 0.95, anchor: .trailing)),
                        removal: .move(edge: .leading).combined(with: .scale(scale: 0.95, anchor: .leading))
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: mainViewModel.selectedTask != nil)
        .frame(minWidth: minWidth,idealWidth: minWidth + 80, minHeight: 700)
        .background(TDVisualEffectView(material: .underWindowBackground))
        .ignoresSafeArea(.container, edges: .all)
        .animation(.easeInOut(duration: 0.3), value: mainViewModel.selectedTask != nil)
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
            .frame(minWidth: 260, idealWidth: 260, maxWidth: 260)
//            .background(TDVisualEffectView(material: .underWindowBackground))
//            .toolbar {
//                ToolbarItemGroup(placement: .automatic) {
//                    Spacer()
//                    
//                    // 更多按钮
//                    Button(action: {
//                        // TODO: 更多操作
//                    }) {
//                        Image(systemName: "ellipsis.circle")
//                            .foregroundColor(.secondary)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                    
//                    // 设置按钮
//                    Button(action: {
//                        // TODO: 设置操作
//                    }) {
//                        Image(systemName: "gearshape")
//                            .foregroundColor(.secondary)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                }
//            }
    }
    
    // MARK: - 第二列：任务列表
    private var secondColumn: some View {
        VStack(spacing: 0) {
            // 主要内容区域
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
                    .frame(minWidth: 450, idealWidth: 650, maxWidth: .infinity)
                .background(Color(.windowBackgroundColor))
                .ignoresSafeArea(.container, edges: .all)
            )
            Spacer(minLength: 0)
            // 专注界面
            TDFocusView()
            
        }

    }
    
    // MARK: - 第三列：任务详情
    private var thirdColumn: some View {
        Group {
            if let selectedTask = mainViewModel.selectedTask {
                // 有选中任务时，显示任务详情
                TDTaskDetailView(task: selectedTask)
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
        .animation(.easeInOut(duration: 0.3), value: mainViewModel.selectedTask != nil)
        .ignoresSafeArea(.container, edges: .all)

    }

}

#Preview {
    TDMainView()
        .environmentObject(TDMainViewModel.shared)
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
}
