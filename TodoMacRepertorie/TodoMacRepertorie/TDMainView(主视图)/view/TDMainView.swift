
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

    // 控制第三列的显示/隐藏（历史遗留：已改用 HSplitView，这里不再需要动态切换可见性）
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    // MARK: - 三列宽度策略（解决“第三栏出现时窗口跳动” + “第二栏太窄”）
    //
    // 根因：
    // - 之前 `minWidth` 会随着第三栏显示/隐藏动态变化；
    // - macOS 为满足新的最小宽度，会触发窗口尺寸与 SplitView 的重排 → 视觉上会“跳一下”。
    //
    // 解决方案：
    // - **窗口最小宽度固定**：始终足够容纳三栏（即便第三栏当前折叠也不改变窗口约束）
    // - **第三栏不插拔**：始终存在于 HSplitView 中，仅通过宽度 0/固定宽度折叠展开
    // - **第二栏加宽**：提升 min/ideal，让列表与详情并排时更舒适
    private let firstColumnWidth: CGFloat = 260
    private let secondColumnMinWidth: CGFloat = 560
    private let secondColumnIdealWidth: CGFloat = 760
    private let thirdColumnWidth: CGFloat = 414
    
    private var windowMinWidth: CGFloat {
        firstColumnWidth + secondColumnMinWidth + thirdColumnWidth
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
            // 第一列：分类导航栏（固定宽度）
            firstColumn
            
            // 第二列：任务列表（加宽）
            secondColumn
                .frame(minWidth: secondColumnMinWidth, idealWidth: secondColumnIdealWidth, maxWidth: .infinity)
                .layoutPriority(1) // 让第二列优先获得剩余空间
            
            // 第三列：任务详情
            // 说明：这里恢复为“有选中任务才插入第三栏”，避免折叠/裁切导致顶部布局异常。
            // 窗口跳动的问题由“固定窗口 minWidth”解决，不再靠折叠第三栏。
            if mainViewModel.selectedTask != nil {
                thirdColumn
                    .frame(minWidth: thirdColumnWidth, idealWidth: thirdColumnWidth, maxWidth: thirdColumnWidth)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .scale(scale: 0.95, anchor: .trailing)),
                        removal: .move(edge: .leading).combined(with: .scale(scale: 0.95, anchor: .leading))
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: mainViewModel.selectedTask != nil)
        .frame(minWidth: windowMinWidth, idealWidth: windowMinWidth + 120, minHeight: 700)
        .background(TDVisualEffectView(material: .underWindowBackground))
        .ignoresSafeArea(.container, edges: .all)
        .task {
            // 界面加载完成后，立即执行四个初始化请求和同步操作
            await mainViewModel.performInitialServerRequests()
            
            // 预热“日程概览”（避免首次点开 -102 时才初始化导致先空后补的卡顿感）
            _ = TDScheduleOverviewViewModel.shared

            // 单独执行同步操作，避免线程优先级冲突
//            await mainViewModel.performSyncSeparately()
        }
        


    }
    
    // MARK: - 第一列：分类导航栏
    private var firstColumn: some View {
        TDSliderBarView()
            .frame(minWidth: firstColumnWidth, idealWidth: firstColumnWidth, maxWidth: firstColumnWidth)
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
                    
                    // 搜索模式：只要侧边栏输入非空，第二栏改为搜索结果
                    if mainViewModel.isSearchActive {
                        TDTaskSearchView()
                    } else
                    if let tagKey = mainViewModel.selectedTagKey, !tagKey.isEmpty {
                        // 标签模式：复用 TDTaskListView，只是查询条件多一个 tagFilter
                        TDTaskListView(
                            category: TDSliderBarModel(categoryId: -9999, categoryName: tagKey, headerIcon: "tag"),
                            tagFilter: tagKey
                        )
                    } else {
                    
                    if let selectedCategory = mainViewModel.selectedCategory {
                        switch selectedCategory.categoryId {
                        case -100: // DayTodo
                            TDDayTodoView(selectedDate: dateManager.selectedDate, category: selectedCategory)
                        case -101: // 最近待办
                            TDTaskListView(category: selectedCategory)
                        case -102: // 日程概览
                            TDScheduleOverviewView()
                        case -103: // 待办箱
                            TDInboxView(category: selectedCategory)
                        case -107: // 最近已完成
                            TDRecentCompletedView(category: selectedCategory)
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
                        let defaults = TDSliderBarModel.defaultItems(settingManager: settingManager)
                        TDDayTodoView(selectedDate: dateManager.selectedDate, category: defaults.first(where: { $0.categoryId == -100 }) ?? defaults[0])
                    }
                }
                }
                    // 宽度由 HSplitView 的 secondColumn 包裹层统一控制，这里不再重复约束
                .background(Color(.windowBackgroundColor))
                .ignoresSafeArea(.container, edges: .all)
            )
            Spacer(minLength: 0)
            // 专注界面（按设置开关显示）
            if settingManager.enableTomatoFocus {
                TDFocusView()
            }

        }

    }
    
    // MARK: - 第三列：任务详情
    private var thirdColumn: some View {
        Group {
            if let selectedTask = mainViewModel.selectedTask {
                // 有选中任务时，显示任务详情
                TDTaskDetailView(task: selectedTask)
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
        .ignoresSafeArea(.container, edges: .all)

    }

}

#Preview {
    TDMainView()
        .environmentObject(TDMainViewModel.shared)
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
}
