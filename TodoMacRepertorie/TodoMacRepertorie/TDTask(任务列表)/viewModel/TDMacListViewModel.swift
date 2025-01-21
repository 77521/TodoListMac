////
////  TDMacListViewModel.swift
////  TodoMacRepertorie
////
////  Created by 孬孬 on 2024/12/28.
////
//
//import SwiftUI
//import SwiftData
//import Foundation
//
///// 任务列表视图模型
///// 负责管理任务列表的数据加载、同步和界面状态
//
//@Observable
//@MainActor
//class TDMacListViewModel : ObservableObject{
//    // MARK: - Properties
//    
//    /// 任务服务，用于处理任务相关的数据操作
//    private var taskService: TDMacTaskService
//    /// SwiftData 上下文，用于本地数据存储
//    private let modelContext: ModelContext
//    
//    /// 是否正在加载数据
//    var isLoading = false
//    /// 当前选中的侧边栏项目
//    var selectedSidebarItem: TDSliderBarModel?
//    /// 按组分类的任务数据
//    var taskGroups: [TDMacTaskGroup: [TDMacSwiftDataListModel]] = [:]
//
//    // MARK: - Initialization
//        
//    /// 初始化视图模型
//    /// - Parameter modelContext: SwiftData 上下文
//    init(modelContext: ModelContext) {
//        self.modelContext = modelContext
//        self.taskService = TDMacTaskService.shared
//        // 在初始化后异步设置共享实例
////                Task { @MainActor in
////                    self.taskService = TDMacTaskService.shared
////                }
//    }
//    
//    // MARK: - Public Methods
//    
//    /// 登录成功后初始化数据
//    /// 先加载本地数据，再执行同步流程
//    /// 初始化数据（登录成功后调用）
//       func initializeAfterLogin() {
//           Task {
//               await initializeData()
//           }
//       }
//    /// 异步初始化数据
//    @MainActor
//    private func initializeData() async {
//        isLoading = true
//        defer { isLoading = false }
//        
//        do {
//            // 1. 在后台线程获取清单数据
//            try await withThrowingTaskGroup(of: Void.self) { group in
//                // 获取清单数据
//                group.addTask {
//                     await TDCategoryManager.shared.fetchCategories()
//                }
//                
//                // 同步任务数据
//                group.addTask {
//                    try await self.taskService.syncTasks()
//                }
//                
//                // 等待所有任务完成
//                try await group.waitForAll()
//            }
//            
//            // 2. 加载默认分类的任务（在主线程更新 UI）
//            if let defaultCategory = selectedSidebarItem {
//                taskGroups = try await taskService.fetchTasks(categoryId: defaultCategory.categoryId)
//            }
//        } catch {
//            print("初始化数据失败: \(error)")
//            // 处理错误，可以设置一个 error 状态供 UI 显示
//        }
//    }
//    
//
//    /// 手动同步数据
//    /// 手动同步数据
//    func syncAndRefresh() {
//        Task {
//            await syncData()
//        }
//    }
//    /// 异步同步数据
//    @MainActor
//    private func syncData() async {
//        isLoading = true
//        defer { isLoading = false }
//        
//        do {
//            // 1. 在后台线程执行同步操作
//            try await withThrowingTaskGroup(of: Void.self) { group in
//                // 获取清单数据
//                group.addTask {
//                     await TDCategoryManager.shared.fetchCategories()
//                }
//                
//                // 同步任务数据
//                group.addTask {
//                    try await self.taskService.syncTasks()
//                }
//                
//                // 等待所有任务完成
//                try await group.waitForAll()
//            }
//            
//            // 2. 在主线程刷新当前选中分类的任务
//            if let currentCategory = selectedSidebarItem {
//                taskGroups = try await taskService.fetchTasks(categoryId: currentCategory.categoryId)
//            }
//        } catch {
//            print("同步数据失败: \(error)")
//            // 处理错误，可以设置一个 error 状态供 UI 显示
//        }
//    }
//
//    
//    // MARK: - Private Methods
//    
//    /// 获取清单数据
//    /// 从服务器获取最新的清单数据，失败不影响后续流程
//    private func fetchCategories() async {
//        await TDCategoryManager.shared.fetchCategories()
//    }
//    
//    
//    
//    
//    /// 加载指定分类的任务
//    /// 异步加载分类任务
//    @MainActor
//    private func loadTasksForCategory(_ category: TDSliderBarModel) async {
//        selectedSidebarItem = category
//        isLoading = true
//        defer { isLoading = false }
//        
//        do {
//            taskGroups = try await taskService.fetchTasks(categoryId: category.categoryId)
//        } catch {
//            print("加载任务失败: \(error)")
//            taskGroups = [:]
//        }
//    }
//
//}
