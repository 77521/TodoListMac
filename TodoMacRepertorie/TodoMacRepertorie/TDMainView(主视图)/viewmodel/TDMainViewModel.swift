//
//  TDMainViewModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import Foundation
import SwiftData
import SwiftUI
import OSLog

/// 主视图模型 - 极简高性能版本
/// 优化重点：
/// 1. 去掉缓存机制，直接查询更快
/// 2. 简化异步操作，减少嵌套
/// 3. UI切换立即响应，数据异步加载
/// 4. 优化查询条件，减少复杂计算
@MainActor
final class TDMainViewModel: ObservableObject {
    
    // MARK: - 日志系统
    private let logger = OSLog(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDMainViewModel")
    
    /// 单例
    static let shared = TDMainViewModel()
    
    // MARK: - Published 属性
    
    /// 是否正在加载
    @Published var isLoading = false
    
    /// 错误信息
    @Published var error: Error?
    
    /// 搜索文本
    @Published var searchText = ""
    
    /// 选中的分类
    @Published var selectedCategory: TDSliderBarModel?
    
    /// 分类列表
    @Published var categories: [TDSliderBarModel] = []
    
    /// 分组任务数据
    @Published private(set) var groupedTasks: [TDTaskGroup: [TDMacSwiftDataListModel]] = [:]

    // MARK: - 私有属性
    
    /// 工具管理器
    private let queryManager = TDQueryConditionManager.shared
    
    /// 防抖控制
    private var categorySelectionTask: Task<Void, Never>?

    // MARK: - 初始化方法
    
    private init() {
        os_signpost(.begin, log: logger, name: "MainViewModel_Init")
        
        // 初始化默认系统分类
        categories = TDSliderBarModel.defaultItems
        
        // 异步选择默认分类
        Task {
            await selectDefaultCategoryAsync()
        }
        
        os_signpost(.end, log: logger, name: "MainViewModel_Init")
    }
    
    // MARK: - 公共方法
    
    /// 同步数据
    func sync() async {
        os_signpost(.begin, log: logger, name: "Sync")
        
        await setLoadingState(true)
        
        do {
            // 1. 获取服务器分类数据
            let serverCategories = try await TDCategoryAPI.shared.getCategoryList()
            
            // 2. 保存到本地
            await TDCategoryManager.shared.saveCategories(serverCategories)
            
            // 3. 更新界面
            updateCategories(serverCategories)
            
            // 4. 同步任务数据
            let localMaxVersion = try await queryManager.getMaxSyncVersion()
            let serverData = try await TDTaskAPI.shared.getTaskList(version: localMaxVersion)
            
            if !serverData.isEmpty {
                try await queryManager.saveTasks(serverData)
            }
            
            // 5. 上传本地数据
            let unsyncedJson = try await queryManager.getAllUnsyncedTasksJson()
            let syncResults = try await TDTaskAPI.shared.syncPushData(tasksJson: unsyncedJson)
            
            if !syncResults.isEmpty {
                try await queryManager.updateLocalTasksAfterSync(results: syncResults)
            }
            
            await setLoadingState(false)
            
        } catch {
            os_log(.error, log: logger, "❌ 同步失败: %@", error.localizedDescription)
            await handleSyncError(error)
        }
        
        os_signpost(.end, log: logger, name: "Sync")
    }
    
    /// 登录后同步数据 - 优化版本
    func syncAfterLogin() async throws {
        await sync()
    }
    
    /// 选择分类 - 极简优化版本
    func selectCategory(_ category: TDSliderBarModel) {
        
        // 如果选择的是同一个分类，直接返回
        if selectedCategory?.categoryId == category.categoryId {
            return
        }

        
        os_log(.info, log: logger, "🎯 选择分类: %@ (ID: %d)", category.categoryName, category.categoryId)

        // 1. 立即更新UI选中状态
        categorySelectionTask?.cancel()
        
        // 3. 启动新的查询任务
        categorySelectionTask = Task {
            // 1. 在异步任务中更新UI选中状态
            await MainActor.run {
                selectedCategory = category
            }
            await loadTasksForCategory(category)
        }
    }
    
    /// 刷新当前分类的任务
    func refreshTasks() async {
        if let currentCategory = selectedCategory {
            await loadTasksForCategory(currentCategory)
        }
    }
    
    /// 清除错误信息
    func clearError() {
        error = nil
    }
    
    // MARK: - 私有方法
    
    /// 异步选择默认分类
    private func selectDefaultCategoryAsync() async {
        if let dayTodo = categories.first(where: { $0.categoryId == -100 }) {
            selectedCategory = dayTodo
            await loadTasksForCategory(dayTodo)
        }
    }
    
    /// 加载分类任务 - 核心优化方法
    private func loadTasksForCategory(_ category: TDSliderBarModel) async {
        os_signpost(.begin, log: logger, name: "LoadTasks")
        
        await setLoadingState(true)
        
        do {
            // 直接查询，不使用缓存
            let tasks = try await queryManager.queryLocalTasks(categoryId: category.categoryId)
            
            // 在后台线程快速分组
            let grouped = fastGroupTasks(tasks)

            // 更新UI
            self.groupedTasks = grouped
            await setLoadingState(false)
            
            os_log(.debug, log: logger, "✅ 加载任务完成，分类: %@，任务数: %d", category.categoryName, tasks.count)
            
        } catch {
            os_log(.error, log: logger, "❌ 加载任务失败: %@", error.localizedDescription)
            await handleTaskUpdateError(error)
        }
        
        os_signpost(.end, log: logger, name: "LoadTasks")
    }
    
    /// 快速分组任务 - 优化版本
    private func fastGroupTasks(_ tasks: [TDMacSwiftDataListModel]) -> [TDTaskGroup: [TDMacSwiftDataListModel]] {
        var grouped: [TDTaskGroup: [TDMacSwiftDataListModel]] = [:]
        
        // 预计算时间戳
        let today = Date()
        let todayStart = today.startOfDayTimestamp
        let tomorrowStart = today.adding(days: 1).startOfDayTimestamp
        let dayAfterTomorrowStart = today.adding(days: 2).startOfDayTimestamp
        
        // 一次遍历完成分组
        for task in tasks {
            let group: TDTaskGroup
            
            if task.todoTime == 0 {
                group = .noDate
            } else if task.todoTime < todayStart {
                group = task.complete ? .overdueCompleted : .overdueIncomplete
            } else if task.todoTime < tomorrowStart {
                group = .today
            } else if task.todoTime < dayAfterTomorrowStart {
                group = .tomorrow
            } else if task.todoTime < dayAfterTomorrowStart + 86400000 {
                group = .dayAfterTomorrow
            } else {
                group = .future
            }
            
            grouped[group, default: []].append(task)
        }
        
        return grouped
    }
    
    /// 设置加载状态
    private func setLoadingState(_ loading: Bool) async {
        isLoading = loading
        if loading {
            error = nil
        }
    }
    
    /// 处理任务更新错误
    private func handleTaskUpdateError(_ error: Error) async {
        self.error = error
        await setLoadingState(false)
    }
    
    /// 处理同步错误
    private func handleSyncError(_ error: Error) async {
        await setLoadingState(false)
        self.error = error
    }
    
    /// 更新分类数据
    func updateCategories(_ categories: [TDSliderBarModel]) {
        os_log(.debug, log: logger, "🔄 更新分类数据，共 %d 项", categories.count)
        
        // 合并系统分类和用户分类
        var newItems = TDSliderBarModel.defaultItems
        
        if let categoryListIndex = newItems.firstIndex(where: { $0.categoryId == -104 }) {
            newItems.insert(contentsOf: categories, at: categoryListIndex + 1)
        }
        
        self.categories = newItems
        
        // 验证选中分类是否有效
        if let selectedCategory = selectedCategory,
           !newItems.contains(where: { $0.categoryId == selectedCategory.categoryId }) {
            if let dayTodo = newItems.first(where: { $0.categoryId == -100 }) {
                Task {
                    await loadTasksForCategory(dayTodo)
                }
            }
        }
    }
    
    // MARK: - 清理方法
    
    deinit {
        os_log(.info, log: logger, "🗑️ 主视图模型销毁")
        categorySelectionTask?.cancel()
    }
}

// MARK: - 扩展：性能监控

#if DEBUG
extension TDMainViewModel {
    /// 打印性能统计信息
    func printPerformanceStats() {
        os_log(.debug, log: logger, """
        📊 性能统计:
        - 分类数量: %d
        - 当前选中: %@
        - 加载状态: %@
        """,
        categories.count,
        selectedCategory?.categoryName ?? "无",
        isLoading ? "加载中" : "空闲")
    }
}
#endif




//import os
//
//let log = OSLog(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDMainViewModel")
//
//@MainActor
//final class TDMainViewModel: ObservableObject {
//    /// 单例
//    static let shared = TDMainViewModel()
//    
//    // MARK: - Published 属性
//    
//    /// 是否正在加载
//    @Published var isLoading = false
//    
//    /// 错误信息
//    @Published var error: Error?
//    
//    /// 搜索文本
//    @Published var searchText = ""
//    
//    /// 选中的分类
//    @Published var selectedCategory: TDSliderBarModel?
//    
//    /// 分类列表
//    @Published var categories: [TDSliderBarModel] = []
//    
//    @Published private(set) var groupedTasks: [TDTaskGroup: [TDMacSwiftDataListModel]] = [:]
//
//    // MARK: - 私有属性
//    private let dateManager = TDDateManager.shared
//    private let settingManager = TDSettingManager.shared
//    private let queryManager = TDQueryConditionManager.shared
//    
//    // 异步处理相关属性
//    private var categorySelectionTask: Task<Void, Never>?
//    private var dataLoadingTask: Task<Void, Never>?
//    // 数据处理队列
//    private let dataProcessingQueue = DispatchQueue(label: "com.todoapp.mainview.dataprocessing", qos: .userInitiated)
//    // 数据缓存，避免重复计算
//    private var taskCache: [Int: [TDMacSwiftDataListModel]] = [:]
//    private var cacheTimestamp: [Int: Date] = [:]
//    private let cacheValidDuration: TimeInterval = 30 // 缓存有效期30秒
//
//    // MARK: - 初始化方法
//    
//    private init() {
//        // 异步初始化，避免阻塞主线程
//        Task {
//            await initializeAsync()
//        }
//    }
//
//    // MARK: - 公共异步方法
//    
//    /// 异步选择分类（新增方法）
//    func selectCategoryAsync(_ category: TDSliderBarModel) async {
//        // 取消之前的选择任务
//        categorySelectionTask?.cancel()
//        
//        categorySelectionTask = Task { @MainActor in
//            print("异步选择分类开始: id=\(category.categoryId), name=\(category.categoryName)")
//            
//            // 立即更新选中状态，提供即时反馈
//            selectedCategory = category
//            
//            // 异步加载数据
//            await updateTasksForSelectedCategoryAsync()
//            
//            print("异步选择分类完成: id=\(category.categoryId)")
//        }
//    }
//    
//    /// 异步同步数据（新增方法）
//    func syncAsync() async {
//        await MainActor.run {
//            isLoading = true
//        }
//        
//        do {
//            // 在后台线程获取服务器数据
//            let serverCategories = try await Task.detached {
//                return try await TDCategoryAPI.shared.getCategoryList()
//            }.value
//            
//            // 在后台线程保存到本地
//            await Task.detached {
//                await TDCategoryManager.shared.saveCategories(serverCategories)
//            }.value
//            
//            // 在主线程更新界面数据
//            await MainActor.run {
//                updateCategories(serverCategories)
//            }
//            
//            // 在后台线程同步服务器数据到本地数据库
//            await syncServerDataToLocalAsync()
//            
//            await MainActor.run {
//                isLoading = false
//            }
//        } catch {
//            print("异步同步失败: \(error)")
//            await MainActor.run {
//                isLoading = false
//                self.error = error
//            }
//        }
//    }
//    
//    // MARK: - 原有公共方法
//    
//    /// 登录后同步数据
//    func syncAfterLogin() async {
//        await MainActor.run {
//            isLoading = true
//        }
//        do {
//            // 1. 在异步线程获取服务器分类清单数据
//            let serverCategories = try await Task.detached {
//                return try await TDCategoryAPI.shared.getCategoryList()
//            }.value
//            
//            // 2. 在异步线程保存到本地
//            await Task.detached {
//                await TDCategoryManager.shared.saveCategories(serverCategories)
//            }.value
//            
//            // 3. 在主线程更新界面数据
//            await MainActor.run {
//                updateCategories(serverCategories)
//            }
//            
//            // 异步同步服务器数据到本地数据库
//            await syncServerDataToLocalAsync()
//            
//            await MainActor.run {
//                isLoading = false
//                // 确保同步完成后选中默认分类
//                if selectedCategory == nil {
//                    selectDefaultCategory()
//                }
//            }
//        } catch {
//            print("登录后同步失败: \(error)")
//            await MainActor.run {
//                isLoading = false
//                self.error = error
//                // 确保同步完成后选中默认分类
//                if selectedCategory == nil {
//                    selectDefaultCategory()
//                }
//            }
//        }
//    }
//    
//    /// 启动后同步数据
//    func syncAfterLaunch() async {
//        // 1. 在异步线程加载本地数据
//        let localCategories = await Task.detached {
//            return TDCategoryManager.shared.loadLocalCategories()
//        }.value
//        
//        // 2. 在主线程更新界面
//        await MainActor.run {
//            updateCategories(localCategories)
//            isLoading = true
//        }
//        
//        do {
//            let serverCategories = try await Task.detached {
//                return try await TDCategoryAPI.shared.getCategoryList()
//            }.value
//            
//            await Task.detached {
//                await TDCategoryManager.shared.saveCategories(serverCategories)
//            }.value
//            
//            // 3. 在主线程更新界面数据
//            await MainActor.run {
//                updateCategories(serverCategories)
//            }
//            
//            // 异步同步服务器数据到本地数据库
//            await syncServerDataToLocalAsync()
//            
//            await MainActor.run {
//                isLoading = false
//                // 确保同步完成后选中默认分类
//                if selectedCategory == nil {
//                    selectDefaultCategory()
//                }
//            }
//        } catch {
//            print("启动后同步失败: \(error)")
//            await MainActor.run {
//                isLoading = false
//                self.error = error
//                // 确保同步完成后选中默认分类
//                if selectedCategory == nil {
//                    selectDefaultCategory()
//                }
//            }
//        }
//    }
//    
//    /// 手动同步数据
//    func sync() async {
//        await syncAsync()
//    }
//    
//    /// 选择分类（保持向后兼容）
//    func selectCategory(_ category: TDSliderBarModel) {
//        Task {
//            await selectCategoryAsync(category)
//        }
//    }
//    
//    /// 更新选中分类的任务列表（公开方法）
//    func refreshTasks() async {
//        await updateTasksForSelectedCategoryAsync()
//    }
//    
//    // MARK: - 私有方法
//    
//    /// 异步初始化
//    private func initializeAsync() async {
//        // 在后台线程准备默认数据
//        let defaultCategories = await Task.detached {
//            return TDSliderBarModel.defaultItems
//        }.value
//        
//        // 在主线程更新界面
//        await MainActor.run {
//            categories = defaultCategories
//            selectDefaultCategory()
//        }
//    }
//    
//    /// 更新分类数据
//    private func updateCategories(_ categories: [TDSliderBarModel]) {
//        // 1. 将系统默认分类和用户创建的分类合并
//        var newItems = TDSliderBarModel.defaultItems
//        
//        // 2. 找到分类清单的位置
//        if let categoryListIndex = newItems.firstIndex(where: { $0.categoryId == -104 }) {
//            // 3. 在分类清单后面插入用户创建的分类
//            newItems.insert(contentsOf: categories, at: categoryListIndex + 1)
//        }
//        
//        // 4. 更新界面数据
//        self.categories = newItems
//        
//        // 5. 如果当前选中的分类在新数据中不存在,则选中 DayTodo
//        if let selectedCategory = selectedCategory,
//           !newItems.contains(where: { $0.categoryId == selectedCategory.categoryId }) {
//            if let dayTodo = newItems.first(where: { $0.categoryId == -100 }) {
//                Task {
//                    await selectCategoryAsync(dayTodo)
//                }
//            }
//        }
//        
//        // 6. 清除相关缓存
//        clearCacheForCategories()
//    }
//    
//    /// 选择默认分类（DayTodo）
//    private func selectDefaultCategory() {
//        if let dayTodo = categories.first(where: { $0.categoryId == -100 }) {
//            Task {
//                await selectCategoryAsync(dayTodo)
//            }
//        }
//    }
//    
//    /// 获取任务数据（增加缓存机制）
//    private func fetchTasks(for category: TDSliderBarModel) async throws -> [TDMacSwiftDataListModel] {
//        // 检查缓存
//        if let cachedTasks = getCachedTasks(for: category.categoryId) {
//            print("使用缓存数据 for category: \(category.categoryId)")
//            return cachedTasks
//        }
//        
//        // 在后台线程查询数据
//        let tasks = try await Task.detached {
//            return try await self.queryManager.queryLocalTasks(categoryId: category.categoryId)
//        }.value
//        
//        // 更新缓存
//        setCachedTasks(tasks, for: category.categoryId)
//        
//        return tasks
//    }
//
//    /// 异步更新任务列表（优化版本）
//    private func updateTasksForSelectedCategoryAsync() async {
//        // 取消之前的数据加载任务
//        dataLoadingTask?.cancel()
//        
//        dataLoadingTask = Task { @MainActor in
//            os_signpost(.begin, log: log, name: "TaskLoadingAsync")
//            
//            guard let category = selectedCategory else { return }
//            
//            do {
//                switch category.categoryId {
//                case -102: // 日程概览
//                    // 异步更新日历数据
//                    await TDCalendarManager.shared.updateCalendarDataAsync()
//                    
//                default:
//                    // 在后台线程获取和处理任务数据
//                    let processedTasks = await withTaskGroup(of: [TDTaskGroup: [TDMacSwiftDataListModel]].self) { group in
//                        group.addTask {
//                            do {
//                                let tasks = try await self.fetchTasks(for: category)
//                                
//                                // 检查任务是否被取消
//                                if Task.isCancelled { return [:] }
//                                
//                                // 在后台线程进行数据分组和排序
//                                return await self.processTasksInBackground(tasks, for: category)
//                            } catch {
//                                print("获取任务失败: \(error)")
//                                await MainActor.run {
//                                    self.error = error
//                                }
//                                return [:]
//                            }
//                        }
//                        
//                        // 等待数据处理完成
//                        var result: [TDTaskGroup: [TDMacSwiftDataListModel]] = [:]
//                        for await groupedTasks in group {
//                            result = groupedTasks
//                        }
//                        return result
//                    }
//                    
//                    // 检查任务是否被取消
//                    if Task.isCancelled { return }
//                    
//                    // 在主线程批量更新UI
//                    await MainActor.run {
//                        self.groupedTasks = processedTasks
//                    }
//                }
//            }
//            
//            os_signpost(.end, log: log, name: "TaskLoadingAsync")
//        }
//    }
//    
//    /// 在后台线程处理任务数据
//    private func processTasksInBackground(_ tasks: [TDMacSwiftDataListModel], for category: TDSliderBarModel) async -> [TDTaskGroup: [TDMacSwiftDataListModel]] {
//        return await Task.detached { [weak self] in
//            guard let self = self else { return [:] }
//            switch category.categoryId {
//            case -100: // DayTodo
//                // DayTodo 模式：只显示选中日期的任务，不需要分组
//                return [.today: tasks]
//                
//            case -101: // 最近待办
//                // 最近待办：按日期状态分组
//                return self.groupTasksInBackground(tasks)
//                
//            case -103: // 待办箱
//                // 待办箱：所有任务放在无日期组
//                return [.noDate: tasks]
//                
//            case -107: // 最近已完成
//                // 最近已完成：所有任务放在已完成组
//                return [.completed: tasks]
//                
//            case -108: // 回收站
//                // 回收站：所有任务放在删除组
//                return [.deleted: tasks]
//                
//            case let id where id >= 0: // 自定义分类
//                // 自定义分类：按日期状态分组
//                return self.groupTasksInBackground(tasks)
//                
//            default:
//                return [:]
//            }
//        }.value
//    }
//    
//    /// 在后台线程对任务进行分组（优化版本）
//    private func groupTasksInBackground(_ tasks: [TDMacSwiftDataListModel]) -> [TDTaskGroup: [TDMacSwiftDataListModel]] {
//        var grouped: [TDTaskGroup: [TDMacSwiftDataListModel]] = [:]
//        let today = Date()
//        
//        // 预计算时间戳，避免重复计算
//        let todayStart = today.startOfDayTimestamp
//        let tomorrowStart = today.adding(days: 1).startOfDayTimestamp
//        let dayAfterTomorrowStart = today.adding(days: 2).startOfDayTimestamp
//        
//        // 使用数组批量处理，而不是逐个处理
//        let noDateTasks = tasks.filter { $0.todoTime == 0 }
//        let dateTasks = tasks.filter { $0.todoTime != 0 }
//        
//        // 批量分组有日期的任务
//        for task in dateTasks {
//            let taskDate = Date.fromTimestamp(task.todoTime)
//            let group: TDTaskGroup
//            
//            if taskDate.isOverdue {
//                // 过期任务
//                if task.complete {
//                    // 已完成的过期任务
//                    if settingManager.expiredRangeCompleted != .hide {
//                        let rangeStartTimestamp = today.daysAgoStartTimestamp(settingManager.expiredRangeCompleted.rawValue)
//                        if task.todoTime >= rangeStartTimestamp {
//                            group = .overdueCompleted
//                        } else {
//                            continue // 跳过不在范围内的任务
//                        }
//                    } else {
//                        continue // 隐藏已完成过期任务
//                    }
//                } else {
//                    // 未完成的过期任务
//                    if settingManager.expiredRangeUncompleted != .hide {
//                        let rangeStartTimestamp = today.daysAgoStartTimestamp(settingManager.expiredRangeUncompleted.rawValue)
//                        if task.todoTime >= rangeStartTimestamp {
//                            group = .overdueIncomplete
//                        } else {
//                            continue // 跳过不在范围内的任务
//                        }
//                    } else {
//                        continue // 隐藏未完成过期任务
//                    }
//                }
//            } else if taskDate.isToday {
//                group = .today
//            } else if taskDate.isTomorrow {
//                group = .tomorrow
//            } else if taskDate.isDayAfterTomorrow {
//                group = .dayAfterTomorrow
//            } else {
//                group = .future
//            }
//            
//            grouped[group, default: []].append(task)
//        }
//        
//        // 添加无日期任务
//        if !noDateTasks.isEmpty {
//            grouped[.noDate] = noDateTasks
//        }
//        
//        // 批量排序所有分组
//        for (group, tasks) in grouped {
//            let sortedTasks = sortTasksInBackground(tasks, for: group)
//            grouped[group] = sortedTasks
//        }
//        
//        return grouped
//    }
//
//    /// 在后台线程对任务进行排序（优化版本）
//    private func sortTasksInBackground(_ tasks: [TDMacSwiftDataListModel], for group: TDTaskGroup) -> [TDMacSwiftDataListModel] {
//        // 使用稳定排序算法，减少不必要的比较
//        return tasks.sorted { task1, task2 in
//            // 首先按完成状态分组：未完成任务在前
//            if task1.complete != task2.complete {
//                return !task1.complete
//            }
//            
//            // 对于future组，先按日期排序
//            if group == .future && task1.todoTime != task2.todoTime {
//                return task1.todoTime < task2.todoTime
//            }
//            
//            // 最后按taskSort排序
//            return settingManager.isTaskSortAscending ?
//                task1.taskSort < task2.taskSort :
//                task1.taskSort > task2.taskSort
//        }
//    }
//    
//    /// 异步同步服务器数据到本地数据库
//    private func syncServerDataToLocalAsync() async {
//        do {
//            // 在后台线程执行数据同步逻辑
//            await Task.detached {
//                do {
//                    // 1. 获取本地最大同步时间戳（只考虑已同步的记录）
//                    let maxVersion = try await self.queryManager.getMaxSyncVersion()
//                    print("本地最大同步值戳: \(maxVersion)")
//                    
//                    // 2. 获取服务器最大版本号
//                    let serverMaxVersion = try await TDTaskAPI.shared.getCurrentVersion()
//                    print("服务器最大版本号: \(serverMaxVersion)")
//                    
//                    // 3. 如果服务器版本号大于本地版本号，需要同步服务器数据
//                    if serverMaxVersion > maxVersion {
//                        print("从服务器获取更新的数据...")
//                        
//                        // 获取服务器数据
//                        let serverTasks = try await TDTaskAPI.shared.getTaskList(version: serverMaxVersion - maxVersion)
//                        
//                        // 保存数据到本地
//                        try await self.queryManager.saveTasks(serverTasks)
//                        
//                        // 处理日历事件
//                        for task in serverTasks {
//                            do {
//                                try await TDCalendarService.shared.handleReminderEvent(task: task)
//                            } catch {
//                                print("处理任务 \(task.taskId) 的日历事件失败: \(error.localizedDescription)")
//                                continue
//                            }
//                        }
//                        
//                        // 同步本地未同步数据到服务器
//                        await self.syncLocalUnsyncedTasksAsync()
//                    } else {
//                        print("本地数据已是最新")
//                        // 同步本地未同步数据到服务器
//                        await self.syncLocalUnsyncedTasksAsync()
//                    }
//                } catch {
//                    print("同步服务器数据到本地失败: \(error)")
//                }
//            }.value
//            
//            // 清除缓存，强制重新加载数据
//            await MainActor.run {
//                clearAllCache()
//                
//                // 更新当前选中分类的任务列表
//                if selectedCategory != nil {
//                    Task {
//                        await updateTasksForSelectedCategoryAsync()
//                    }
//                }
//            }
//        }
//    }
//    
//    /// 异步同步本地未同步数据
//    private func syncLocalUnsyncedTasksAsync() async {
//        // 在后台线程执行
//        await Task.detached {
//            do {
//                // 1. 查询所有未同步任务转为 JSON
//                guard let tasksJson = try await self.queryManager.getAllUnsyncedTasksJson(),
//                      !tasksJson.isEmpty,
//                      tasksJson != "[]" else {
//                    print("没有需要同步的数据")
//                    return
//                }
//                
//                // 2. 推送数据到服务器
//                let results = try await TDTaskAPI.shared.syncPushData(tasksJson: tasksJson)
//                try await self.queryManager.updateLocalTasksAfterSync(results: results)
//                print("本地未同步数据推送成功")
//            } catch {
//                print("推送数据失败: \(error)")
//            }
//        }.value
//    }
//    
//    // MARK: - 缓存管理方法
//    
//    /// 获取缓存的任务数据
//    private func getCachedTasks(for categoryId: Int) -> [TDMacSwiftDataListModel]? {
//        guard let timestamp = cacheTimestamp[categoryId],
//              Date().timeIntervalSince(timestamp) < cacheValidDuration else {
//            return nil
//        }
//        return taskCache[categoryId]
//    }
//    
//    /// 设置缓存的任务数据
//    private func setCachedTasks(_ tasks: [TDMacSwiftDataListModel], for categoryId: Int) {
//        taskCache[categoryId] = tasks
//        cacheTimestamp[categoryId] = Date()
//    }
//    
//    /// 清除指定分类的缓存
//    private func clearCacheForCategories() {
//        taskCache.removeAll()
//        cacheTimestamp.removeAll()
//    }
//    
//    /// 清除所有缓存
//    private func clearAllCache() {
//        taskCache.removeAll()
//        cacheTimestamp.removeAll()
//    }
//    
//    /// 获取任务查询描述符
//    private func getTasksDescriptor(for category: TDSliderBarModel) -> FetchDescriptor<TDMacSwiftDataListModel> {
//        var descriptor = FetchDescriptor<TDMacSwiftDataListModel>()
//        return descriptor
//    }
//
//    
//    
//}
