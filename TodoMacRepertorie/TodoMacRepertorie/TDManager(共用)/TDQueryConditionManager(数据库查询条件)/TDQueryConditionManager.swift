//
//  TDQueryConditionManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/17.
//


import Foundation
import SwiftData
import SwiftUI
import OSLog

/// 数据库查询条件管理器 - 极简高性能版本
/// 优化重点：
/// 1. 去掉缓存机制，直接查询更快
/// 2. 简化查询条件，减少复杂计算
/// 3. 优化内存处理，避免卡顿
/// 4. 减少后台线程切换开销
@MainActor
final class TDQueryConditionManager: ObservableObject {
    
    // MARK: - 日志系统
    private let logger = OSLog(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDQueryConditionManager")
    
    /// 单例
    static let shared = TDQueryConditionManager()
    
    // MARK: - 私有属性
    private let settingManager = TDSettingManager.shared
    private let userId: Int = TDUserManager.shared.userId
    
    private init() {
        os_log(.info, log: logger, "📚 数据库查询管理器初始化")
    }
    
    // MARK: - 公共方法
    
    /// 获取已同步任务的最大版本号
    func getMaxSyncVersion() async throws -> Int {
        let currentUserId = self.userId
        
        return try await TDModelContainer.shared.performAsync { context in
            let predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == currentUserId &&
                !task.delete &&
                task.status == "sync"
            }
            
            var descriptor = FetchDescriptor(
                predicate: predicate,
                sortBy: [SortDescriptor(\.version, order: .reverse)]
            )
            descriptor.fetchLimit = 1
            
            if let result = try context.fetch(descriptor).first {
                return result.version
            }
            return 0
        }
    }
    
    /// 查询本地任务数据 - 极简优化版本
    func queryLocalTasks(categoryId: Int) async throws -> [TDMacSwiftDataListModel] {
        os_signpost(.begin, log: logger, name: "QueryLocalTasks")
        
        let result = try await queryLocalTasksInternal(categoryId: categoryId)
        
        os_log(.debug, log: logger, "📚 查询完成，分类ID: %d，共 %d 条任务", categoryId, result.count)
        os_signpost(.end, log: logger, name: "QueryLocalTasks")
        
        return result
    }
    
    /// 内部查询方法 - 简化版本
    private func queryLocalTasksInternal(categoryId: Int) async throws -> [TDMacSwiftDataListModel] {
        switch categoryId {
        case -100: // DayTodo
            return try await queryTasksByDate(timestamp: Date().startOfDayTimestamp)
            
        case -101: // 最近待办
            return try await queryRecentTasksSimple()
            
        case -103: // 待办箱(无日期任务)
            return try await queryNoDateTasks()
            
        case -107: // 最近已完成
            return try await queryRecentCompletedTasks()
            
        case -108: // 回收站
            return try await queryRecycleBinTasks()
            
        case _ where categoryId >= 0: // 自定义分类
            return try await queryRecentTasksSimple(categoryId: categoryId)
            
        default:
            return []
        }
    }
    
    /// 根据日期查询任务
    func queryTasksByDate(timestamp: Int64) async throws -> [TDMacSwiftDataListModel] {
        let currentUserId = self.userId
        let isTaskSortAscending = self.settingManager.isTaskSortAscending
        let showCompletedTasks = self.settingManager.showCompletedTasks
        
        return try await TDModelContainer.shared.performAsync { context in
            var allTasks: [TDMacSwiftDataListModel] = []
            
            // 1. 查询未完成任务
            let incompletePredicate = #Predicate<TDMacSwiftDataListModel> { task in
                !task.delete &&
                task.userId == currentUserId &&
                task.todoTime == timestamp &&
                !task.complete
            }
            
            let incompleteDescriptor = FetchDescriptor(
                predicate: incompletePredicate,
                sortBy: [
                    SortDescriptor(\.taskSort,
                                 order: isTaskSortAscending ? .forward : .reverse)
                ]
            )
            
            let incompleteTasks = try context.fetch(incompleteDescriptor)
            allTasks.append(contentsOf: incompleteTasks)
            
            // 2. 如果需要显示已完成任务，查询已完成任务
            if showCompletedTasks {
                let completePredicate = #Predicate<TDMacSwiftDataListModel> { task in
                    !task.delete &&
                    task.userId == currentUserId &&
                    task.todoTime == timestamp &&
                    task.complete
                }
                
                let completeDescriptor = FetchDescriptor(
                    predicate: completePredicate,
                    sortBy: [
                        SortDescriptor(\.taskSort,
                                     order: isTaskSortAscending ? .forward : .reverse)
                    ]
                )
                
                let completeTasks = try context.fetch(completeDescriptor)
                allTasks.append(contentsOf: completeTasks)
            }
            
            return allTasks
        }
    }
    
    /// 简化的最近待办查询
    private func queryRecentTasksSimple(categoryId: Int? = nil) async throws -> [TDMacSwiftDataListModel] {
        let currentUserId = self.userId
        let isTaskSortAscending = self.settingManager.isTaskSortAscending
        let showCompletedTasks = self.settingManager.showCompletedTasks
        
        return try await TDModelContainer.shared.performAsync { context in
            var allTasks: [TDMacSwiftDataListModel] = []
            
            // 1. 查询未完成任务
            var incompletePredicate: Predicate<TDMacSwiftDataListModel>
            if let categoryId = categoryId {
                incompletePredicate = #Predicate<TDMacSwiftDataListModel> { task in
                    !task.delete &&
                    task.userId == currentUserId &&
                    task.standbyInt1 == categoryId &&
                    !task.complete
                }
            } else {
                incompletePredicate = #Predicate<TDMacSwiftDataListModel> { task in
                    !task.delete &&
                    task.userId == currentUserId &&
                    !task.complete
                }
            }
            
            let incompleteDescriptor = FetchDescriptor(
                predicate: incompletePredicate,
                sortBy: [
                    SortDescriptor(\.todoTime),
                    SortDescriptor(\.taskSort,
                                 order: isTaskSortAscending ? .forward : .reverse)
                ]
            )
            
            let incompleteTasks = try context.fetch(incompleteDescriptor)
            allTasks.append(contentsOf: incompleteTasks)
            
            // 2. 如果需要显示已完成任务，查询已完成任务
            if showCompletedTasks {
                var completePredicate: Predicate<TDMacSwiftDataListModel>
                if let categoryId = categoryId {
                    completePredicate = #Predicate<TDMacSwiftDataListModel> { task in
                        !task.delete &&
                        task.userId == currentUserId &&
                        task.standbyInt1 == categoryId &&
                        task.complete
                    }
                } else {
                    completePredicate = #Predicate<TDMacSwiftDataListModel> { task in
                        !task.delete &&
                        task.userId == currentUserId &&
                        task.complete
                    }
                }
                
                let completeDescriptor = FetchDescriptor(
                    predicate: completePredicate,
                    sortBy: [
                        SortDescriptor(\.todoTime),
                        SortDescriptor(\.taskSort,
                                     order: isTaskSortAscending ? .forward : .reverse)
                    ]
                )
                
                let completeTasks = try context.fetch(completeDescriptor)
                allTasks.append(contentsOf: completeTasks)
            }
            
            return allTasks
        }
    }
    
    /// 查询无日期任务
    private func queryNoDateTasks() async throws -> [TDMacSwiftDataListModel] {
        let currentUserId = self.userId
        let isTaskSortAscending = self.settingManager.isTaskSortAscending
        let showCompletedTasks = self.settingManager.showCompletedTasks
        
        return try await TDModelContainer.shared.performAsync { context in
            var allTasks: [TDMacSwiftDataListModel] = []
            
            // 1. 查询未完成任务
            let incompletePredicate = #Predicate<TDMacSwiftDataListModel> { task in
                !task.delete &&
                task.userId == currentUserId &&
                task.todoTime == 0 &&
                !task.complete
            }
            
            let incompleteDescriptor = FetchDescriptor(
                predicate: incompletePredicate,
                sortBy: [
                    SortDescriptor(\.taskSort,
                                 order: isTaskSortAscending ? .forward : .reverse)
                ]
            )
            
            let incompleteTasks = try context.fetch(incompleteDescriptor)
            allTasks.append(contentsOf: incompleteTasks)
            
            // 2. 如果需要显示已完成任务，查询已完成任务
            if showCompletedTasks {
                let completePredicate = #Predicate<TDMacSwiftDataListModel> { task in
                    !task.delete &&
                    task.userId == currentUserId &&
                    task.todoTime == 0 &&
                    task.complete
                }
                
                let completeDescriptor = FetchDescriptor(
                    predicate: completePredicate,
                    sortBy: [
                        SortDescriptor(\.taskSort,
                                     order: isTaskSortAscending ? .forward : .reverse)
                    ]
                )
                
                let completeTasks = try context.fetch(completeDescriptor)
                allTasks.append(contentsOf: completeTasks)
            }
            
            return allTasks
        }
    }
    
    /// 查询最近已完成任务
    private func queryRecentCompletedTasks() async throws -> [TDMacSwiftDataListModel] {
        let currentUserId = self.userId
        let isTaskSortAscending = self.settingManager.isTaskSortAscending
        
        return try await TDModelContainer.shared.performAsync { context in
            let thirtyDaysAgo = Date().adding(days: -30).startOfDayTimestamp
            
            let predicate = #Predicate<TDMacSwiftDataListModel> { task in
                !task.delete &&
                task.userId == currentUserId &&
                task.complete &&
                task.todoTime >= thirtyDaysAgo
            }
            
            let descriptor = FetchDescriptor(
                predicate: predicate,
                sortBy: [
                    SortDescriptor(\.todoTime, order: .reverse),
                    SortDescriptor(\.taskSort,
                                 order: isTaskSortAscending ? .forward : .reverse)
                ]
            )
            
            return try context.fetch(descriptor)
        }
    }
    
    /// 查询回收站任务
    private func queryRecycleBinTasks() async throws -> [TDMacSwiftDataListModel] {
        let currentUserId = self.userId
        let isTaskSortAscending = self.settingManager.isTaskSortAscending
        
        return try await TDModelContainer.shared.performAsync { context in
            let predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.delete &&
                task.userId == currentUserId
            }
            
            let descriptor = FetchDescriptor(
                predicate: predicate,
                sortBy: [
                    SortDescriptor(\.syncTime, order: .reverse),
                    SortDescriptor(\.taskSort,
                                 order: isTaskSortAscending ? .forward : .reverse)
                ]
            )
            
            return try context.fetch(descriptor)
        }
    }
    
    /// 查询本地是否存在指定任务
    func findLocalTask(taskId: String) async -> TDMacSwiftDataListModel? {
        let currentUserId = self.userId
        
        let result = try? await TDModelContainer.shared.performAsync { context in
            let predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.taskId == taskId &&
                task.userId == currentUserId
            }
            
            let descriptor = FetchDescriptor(predicate: predicate)
            return try context.fetch(descriptor).first
        }
        
        return result
    }
    
    /// 根据 taskId 查询单个任务
    func findTaskByTaskId(_ taskId: String) async throws -> TDMacSwiftDataListModel? {
        let currentUserId = self.userId
        
        return try await TDModelContainer.shared.performAsync { context in
            let predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.taskId == taskId &&
                task.userId == currentUserId
            }
            
            let descriptor = FetchDescriptor(predicate: predicate)
            return try context.fetch(descriptor).first
        }
    }
    
    /// 批量保存任务数据到本地
    func saveTasks(_ tasks: [TDMacSwiftDataListModel], batchSize: Int = 100) async throws {
        os_signpost(.begin, log: logger, name: "SaveTasks")
        os_log(.info, log: logger, "💾 开始保存 %d 条任务数据", tasks.count)
        
        // 分批处理数据
        for i in stride(from: 0, to: tasks.count, by: batchSize) {
            let end = min(i + batchSize, tasks.count)
            let batch = Array(tasks[i..<end])
            
            // 处理这一批数据
            for task in batch {
                if let existingTask = await findLocalTask(taskId: task.taskId) {
                    // 更新现有数据
                    if task.syncTime > existingTask.syncTime {
                        existingTask.taskContent = task.taskContent
                        existingTask.taskDescribe = task.taskDescribe
                        existingTask.complete = task.complete
                        existingTask.createTime = task.createTime
                        existingTask.delete = task.delete
                        existingTask.reminderTime = task.reminderTime
                        existingTask.snowAdd = task.snowAdd
                        existingTask.snowAssess = task.snowAssess
                        existingTask.standbyInt1 = task.standbyInt1
                        existingTask.standbyStr1 = task.standbyStr1
                        existingTask.standbyStr2 = task.standbyStr2
                        existingTask.standbyStr3 = task.standbyStr3
                        existingTask.standbyStr4 = task.standbyStr4
                        existingTask.syncTime = task.syncTime
                        existingTask.taskSort = task.taskSort
                        existingTask.todoTime = task.todoTime
                        existingTask.version = task.version
                        existingTask.status = task.status
                        existingTask.number = task.number
                        existingTask.isSubOpen = task.isSubOpen
                        existingTask.standbyIntColor = task.standbyIntColor
                        existingTask.standbyIntName = task.standbyIntName
                        existingTask.reminderTimeString = task.reminderTimeString
                        existingTask.subTaskList = task.subTaskList
                        existingTask.attachmentList = task.attachmentList
                    }
                } else {
                    // 插入新数据
                    try await TDModelContainer.shared.performAsync { context in
                    context.insert(task)
                }
                }
            }
            
            // 批量保存
            try await TDModelContainer.shared.performAsync { context in
                try context.save()
            }
            
            os_log(.debug, log: logger, "✅ 已保存 %d/%d 条数据", end, tasks.count)
        }
        
        os_log(.info, log: logger, "✅ 任务数据保存完成")
        os_signpost(.end, log: logger, name: "SaveTasks")
    }
    
    /// 获取所有未同步的任务并转为 JSON 字符串
    func getAllUnsyncedTasksJson() async throws -> String {
        let currentUserId = self.userId
        
        return try await TDModelContainer.shared.performAsync { context in
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == currentUserId &&
            task.status != "sync"
        }
        
        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createTime, order: .forward)]
        )
        
            let unsyncedTasks = try context.fetch(descriptor)
            
        let taskModels = unsyncedTasks.map { TDTaskModel(from: $0) }
        return TDSwiftJsonUtil.arrayToJson(taskModels) ?? "[]"
        }
    }
    
    /// 根据同步结果更新本地任务状态
    func updateLocalTasksAfterSync(results: [TDTaskSyncResultModel]) async throws {
        os_signpost(.begin, log: logger, name: "UpdateAfterSync")
        
        for result in results {
                guard result.succeed else { continue }
                
            if let task = try await findTaskByTaskId(result.taskId) {
                    task.status = "sync"
                    task.version = result.version
                }
            }
        
        // 保存更改
        try await TDModelContainer.shared.performAsync { context in
            try context.save()
        }
        
        os_signpost(.end, log: logger, name: "UpdateAfterSync")
    }
    
    /// 批量更新本地任务的所有字段
    func updateLocalTaskFields(_ updatedTasks: [TDMacSwiftDataListModel]) async throws {
        os_signpost(.begin, log: logger, name: "UpdateTaskFields")
        os_log(.info, log: logger, "🔄 开始更新 %d 条任务数据", updatedTasks.count)
        
        for updatedTask in updatedTasks {
            if let localTask = try await findTaskByTaskId(updatedTask.taskId) {
                // 直接更新字段
                localTask.taskContent = updatedTask.taskContent
                localTask.taskDescribe = updatedTask.taskDescribe
                localTask.complete = updatedTask.complete
                localTask.createTime = updatedTask.createTime
                localTask.delete = updatedTask.delete
                localTask.reminderTime = updatedTask.reminderTime
                localTask.snowAdd = updatedTask.snowAdd
                localTask.snowAssess = updatedTask.snowAssess
                localTask.standbyInt1 = updatedTask.standbyInt1
                localTask.standbyStr1 = updatedTask.standbyStr1
                localTask.standbyStr2 = updatedTask.standbyStr2
                localTask.standbyStr3 = updatedTask.standbyStr3
                localTask.standbyStr4 = updatedTask.standbyStr4
                localTask.syncTime = updatedTask.syncTime
                localTask.taskSort = updatedTask.taskSort
                localTask.todoTime = updatedTask.todoTime
                localTask.version = updatedTask.version
                localTask.status = updatedTask.status
                localTask.number = updatedTask.number
                localTask.isSubOpen = updatedTask.isSubOpen
                localTask.standbyIntColor = updatedTask.standbyIntColor
                localTask.standbyIntName = updatedTask.standbyIntName
                localTask.reminderTimeString = updatedTask.reminderTimeString
                localTask.subTaskList = updatedTask.subTaskList
                localTask.attachmentList = updatedTask.attachmentList
            }
        }
        
        // 保存更改
        try await TDModelContainer.shared.performAsync { context in
            try context.save()
        }
        
        os_log(.info, log: logger, "✅ 任务字段更新完成")
        os_signpost(.end, log: logger, name: "UpdateTaskFields")
    }
    
    // MARK: - 清理方法
    
    deinit {
        os_log(.info, log: logger, "🗑️ 数据库查询管理器销毁")
    }
}



// MARK: - 扩展：性能监控

#if DEBUG
extension TDQueryConditionManager {
    /// 打印性能统计信息
    func printPerformanceStats() {
        os_log(.debug, log: logger, """
            📊 性能统计:
            - 用户ID: %d
            - 管理器状态: 活跃
            """, userId)
    }
}
#endif




//@MainActor
//final class TDQueryConditionManager: ObservableObject {
//    /// 单例
//    static let shared = TDQueryConditionManager()
//    // MARK: - 私有属性
//    private let settingManager = TDSettingManager.shared
//    private let userId = TDUserManager.shared.userId
//    
//    private init() {}
//    
//    /// 获取已同步任务的最大时间戳
//    func getMaxSyncVersion() async throws -> Int {
//        // 在进入 Task.detached 之前捕获 userId
//        let userId = self.userId
//        
//        return await Task.detached {
//            var descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
//                predicate: #Predicate<TDMacSwiftDataListModel> { task in
//                    task.userId == userId &&
//                    !task.delete &&
//                    task.status == "sync"
//                }, sortBy: [SortDescriptor(\TDMacSwiftDataListModel.version, order: .reverse)]
//            )
//            descriptor.fetchLimit = 1
//            
//            do {
//                if let result = try await TDModelContainer.shared.fetchOne(descriptor) {
//                    return result.version
//                }
//                return 0
//            } catch {
//                print("获取最大同步时间戳失败: \(error)")
//                return 0
//            }
//        }.value
//    }
//    
//    /// 查询本地是否存在指定任务
//    func findLocalTask(taskId: String) async -> TDMacSwiftDataListModel? {
//        return await Task.detached {
//            let descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
//                predicate: #Predicate<TDMacSwiftDataListModel> { task in
//                    task.taskId == taskId
//                }
//            )
//            
//            do {
//                return try await TDModelContainer.shared.fetchOne(descriptor)
//            } catch {
//                print("查询本地任务失败: \(error)")
//                return nil
//            }
//        }.value
//    }
//    
//    /// 保存任务数据到本地
//    func saveTasks(_ tasks: [TDMacSwiftDataListModel], batchSize: Int = 100) async throws {
//        print("开始保存 \(tasks.count) 条数据...")
//        
//        // 分批处理数据
//        for i in stride(from: 0, to: tasks.count, by: batchSize) {
//            let end = min(i + batchSize, tasks.count)
//            let batch = tasks[i..<end]
//            
//            // 处理这一批数据
//            for task in batch {
//                if let existingTask = await findLocalTask(taskId: task.taskId) {
//                    // 更新现有数据
//                    // 只有当网络获取的 syncTime 大于本地 syncTime 时，才更新
//                    if task.syncTime > existingTask.syncTime {
//                        
//                        existingTask.id = task.id
//                        existingTask.taskContent = task.taskContent
//                        existingTask.taskDescribe = task.taskDescribe
//                        existingTask.complete = task.complete
//                        existingTask.createTime = task.createTime
//                        existingTask.delete = task.delete
//                        existingTask.reminderTime = task.reminderTime
//                        existingTask.snowAdd = task.snowAdd
//                        existingTask.snowAssess = task.snowAssess
//                        existingTask.standbyInt1 = task.standbyInt1
//                        existingTask.standbyStr1 = task.standbyStr1
//                        existingTask.standbyStr2 = task.standbyStr2
//                        existingTask.standbyStr3 = task.standbyStr3
//                        existingTask.standbyStr4 = task.standbyStr4
//                        existingTask.syncTime = task.syncTime
//                        existingTask.taskSort = task.taskSort
//                        existingTask.todoTime = task.todoTime
//                        existingTask.userId = task.userId
//                        existingTask.version = task.version
//                        existingTask.status = task.status
//                        existingTask.isSubOpen = task.isSubOpen
//                        existingTask.number = task.number
//                        existingTask.standbyIntColor = task.standbyIntColor
//                        existingTask.standbyIntName = task.standbyIntName
//                        existingTask.reminderTimeString = task.reminderTimeString
//                        existingTask.subTaskList = task.subTaskList
//                        existingTask.attachmentList = task.attachmentList
//                    }
//                } else {
//                    // 插入新数据
//                    TDModelContainer.shared.insert(task)
//                }
//            }
//            
//            try TDModelContainer.shared.save()
//            print("已保存 \(end)/\(tasks.count) 条数据")
//        }
//        
//        print("数据保存完成")
//    }
//    
//    /// 获取本地任务数据（优化版本 - 异步批量处理）
//    func queryLocalTasks(categoryId: Int) async throws -> [TDMacSwiftDataListModel] {
//        // 在后台线程执行查询，避免阻塞主线程
//        return try await Task.detached {
//            switch categoryId {
//            case -100: // DayTodo
//                return try await self.queryTasksByDateAsync(timestamp: Date().startOfDayTimestamp)
//                
//            case -101: // 最近待办
//                return try await self.queryRecentTasksAsync()
//
//            case -103: // 待办箱(无日期任务)
//                return try await self.queryNoDateBoxTasksAsync()
//
//            case -107: // 最近已完成
//                return try await self.queryRecentCompletedTasksAsync()
//
//            case -108: // 回收站
//                return try await self.queryRecycleBinTasksAsync()
//
//            case _ where categoryId >= 0: // 自定义分类
//                return try await self.queryRecentTasksAsync(categoryId: categoryId)
//
//            default:
//                return []
//            }
//        }.value
//    }
//    
//    /// 异步根据日期查询任务（优化版本）
//    private func queryTasksByDateAsync(timestamp: Int64) async throws -> [TDMacSwiftDataListModel] {
//        return try await Task.detached {
//            var allTasks: [TDMacSwiftDataListModel] = []
//            
//            // 1. 批量查询未完成的任务
//            let uncompletedPredicate = #Predicate<TDMacSwiftDataListModel> { task in
//                !task.delete &&
//                !task.complete &&
//                task.userId == self.userId &&
//                task.todoTime == timestamp
//            }
//            
//            let uncompletedDescriptor = FetchDescriptor(
//                predicate: uncompletedPredicate,
//                sortBy: [
//                    SortDescriptor(\TDMacSwiftDataListModel.taskSort,
//                                    order: self.settingManager.isTaskSortAscending ? .forward : .reverse)
//                ]
//            )
//            
//            let uncompletedTasks = try await TDModelContainer.shared.perform {
//                try TDModelContainer.shared.fetch(uncompletedDescriptor)
//            }
//            allTasks.append(contentsOf: uncompletedTasks)
//            
//            // 2. 如果需要显示已完成任务，批量查询已完成任务
//            if self.settingManager.showCompletedTasks {
//                let completedPredicate = #Predicate<TDMacSwiftDataListModel> { task in
//                    !task.delete &&
//                    task.complete &&
//                    task.userId == self.userId &&
//                    task.todoTime == timestamp
//                }
//                
//                let completedDescriptor = FetchDescriptor(
//                    predicate: completedPredicate,
//                    sortBy: [
//                        SortDescriptor(\TDMacSwiftDataListModel.taskSort,
//                                        order: self.settingManager.isTaskSortAscending ? .forward : .reverse)
//                    ]
//                )
//                
//                let completedTasks = try await TDModelContainer.shared.perform {
//                    try TDModelContainer.shared.fetch(completedDescriptor)
//                }
//                allTasks.append(contentsOf: completedTasks)
//            }
//            
//            // 3. 如果需要显示本地日历数据，异步获取日历事件
//            if self.settingManager.showLocalCalendarEvents {
//                let date = Date.fromTimestamp(timestamp)
//                let endDate = date.adding(days: 1)
//                
//                let localEvents = try await TDCalendarService.shared.fetchLocalEvents(
//                    from: date,
//                    to: endDate
//                )
//                allTasks.append(contentsOf: localEvents)
//            }
//            
//            return allTasks
//        }.value
//    }
//    
//    /// 异步获取最近待办任务（优化版本 - 批量处理）
//    private func queryRecentTasksAsync(categoryId: Int? = nil) async throws -> [TDMacSwiftDataListModel] {
//        return try await Task.detached {
//            let today = Date()
//            var allTasks: [TDMacSwiftDataListModel] = []
//            
//            // 构建基础查询条件
//            let basePredicate = #Predicate<TDMacSwiftDataListModel> { task in
//                !task.delete &&
//                task.userId == self.userId
//            }
//            
//            // 1. 批量获取所有任务
//            let descriptor = FetchDescriptor(
//                predicate: basePredicate,
//                sortBy: [
//                    SortDescriptor(\TDMacSwiftDataListModel.todoTime),
//                    SortDescriptor(\TDMacSwiftDataListModel.taskSort,
//                                 order: self.settingManager.isTaskSortAscending ? .forward : .reverse)
//                ]
//            )
//            
//            let allDbTasks = try await TDModelContainer.shared.perform {
//                try TDModelContainer.shared.fetch(descriptor)
//            }
//            
//            // 2. 在内存中进行高效过滤（如果是用户自定义分类）
//            let tasks = categoryId != nil && categoryId! > 0 ?
//                allDbTasks.filter { $0.standbyInt1 == categoryId } : allDbTasks
//            
//            // 3. 预计算时间戳，避免重复计算
//            let todayStart = today.startOfDayTimestamp
//            let tomorrowStart = today.adding(days: 1).startOfDayTimestamp
//            let dayAfterTomorrowStart = today.adding(days: 2).startOfDayTimestamp
//            let dayAfterTomorrowEnd = today.adding(days: 2).endOfDayTimestamp
//            let futureEndTimestamp = self.settingManager.getFutureEndTimestamp(from: today)
//            
//            // 4. 使用批量过滤，减少遍历次数
//            let (expiredCompleted, expiredUncompleted, todayTasks, tomorrowTasks, dayAfterTomorrowTasks, futureTasks, noDateTasks) =
//                self.batchFilterTasks(tasks,
//                                    todayStart: todayStart,
//                                    tomorrowStart: tomorrowStart,
//                                    dayAfterTomorrowStart: dayAfterTomorrowStart,
//                                    dayAfterTomorrowEnd: dayAfterTomorrowEnd,
//                                    futureEndTimestamp: futureEndTimestamp,
//                                    today: today)
//            
//            // 5. 批量添加任务到结果数组
//            if self.settingManager.expiredRangeCompleted != .hide {
//                allTasks.append(contentsOf: expiredCompleted)
//            }
//            
//            if self.settingManager.expiredRangeUncompleted != .hide {
//                allTasks.append(contentsOf: expiredUncompleted)
//            }
//            
//            allTasks.append(contentsOf: todayTasks)
//            allTasks.append(contentsOf: tomorrowTasks)
//            allTasks.append(contentsOf: dayAfterTomorrowTasks)
//            
//            // 6. 处理重复任务限制
//            if self.settingManager.repeatNum > 0 {
//                let limitedFutureTasks = self.applyRepeatTaskLimit(futureTasks)
//                allTasks.append(contentsOf: limitedFutureTasks)
//            } else {
//                allTasks.append(contentsOf: futureTasks)
//            }
//            
//            allTasks.append(contentsOf: noDateTasks)
//            
//            return allTasks
//        }.value
//    }
//    
//    /// 批量过滤任务（一次遍历完成所有分类）
//    private func batchFilterTasks(_ tasks: [TDMacSwiftDataListModel],
//                                todayStart: Int64,
//                                tomorrowStart: Int64,
//                                dayAfterTomorrowStart: Int64,
//                                dayAfterTomorrowEnd: Int64,
//                                futureEndTimestamp: Int64,
//                                today: Date) -> (
//                                    expiredCompleted: [TDMacSwiftDataListModel],
//                                    expiredUncompleted: [TDMacSwiftDataListModel],
//                                    todayTasks: [TDMacSwiftDataListModel],
//                                    tomorrowTasks: [TDMacSwiftDataListModel],
//                                    dayAfterTomorrowTasks: [TDMacSwiftDataListModel],
//                                    futureTasks: [TDMacSwiftDataListModel],
//                                    noDateTasks: [TDMacSwiftDataListModel]
//                                ) {
//        
//        var expiredCompleted: [TDMacSwiftDataListModel] = []
//        var expiredUncompleted: [TDMacSwiftDataListModel] = []
//        var todayTasks: [TDMacSwiftDataListModel] = []
//        var tomorrowTasks: [TDMacSwiftDataListModel] = []
//        var dayAfterTomorrowTasks: [TDMacSwiftDataListModel] = []
//        var futureTasks: [TDMacSwiftDataListModel] = []
//        var noDateTasks: [TDMacSwiftDataListModel] = []
//        
//        // 预计算过期范围时间戳
//        let expiredCompletedRangeStart = settingManager.expiredRangeCompleted != .hide ?
//            today.daysAgoStartTimestamp(settingManager.expiredRangeCompleted.rawValue) : 0
//        let expiredUncompletedRangeStart = settingManager.expiredRangeUncompleted != .hide ?
//            today.daysAgoStartTimestamp(settingManager.expiredRangeUncompleted.rawValue) : 0
//        
//        // 一次遍历完成所有分类
//        for task in tasks {
//            if task.todoTime == 0 {
//                // 无日期任务
//                if settingManager.showCompletedTasks || !task.complete {
//                    noDateTasks.append(task)
//                }
//            } else if task.todoTime < todayStart {
//                // 过期任务
//                if task.complete && settingManager.expiredRangeCompleted != .hide &&
//                   task.todoTime >= expiredCompletedRangeStart {
//                    expiredCompleted.append(task)
//                } else if !task.complete && settingManager.expiredRangeUncompleted != .hide &&
//                   task.todoTime >= expiredUncompletedRangeStart {
//                    expiredUncompleted.append(task)
//                }
//            } else if task.todoTime >= todayStart && task.todoTime < tomorrowStart {
//                // 今天的任务
//                if settingManager.showCompletedTasks || !task.complete {
//                    todayTasks.append(task)
//                }
//            } else if task.todoTime >= tomorrowStart && task.todoTime < dayAfterTomorrowStart {
//                // 明天的任务
//                if settingManager.showCompletedTasks || !task.complete {
//                    tomorrowTasks.append(task)
//                }
//            } else if task.todoTime >= dayAfterTomorrowStart && task.todoTime < dayAfterTomorrowEnd {
//                // 后天的任务
//                if settingManager.showCompletedTasks || !task.complete {
//                    dayAfterTomorrowTasks.append(task)
//                }
//            } else if task.todoTime > dayAfterTomorrowEnd && task.todoTime <= futureEndTimestamp {
//                // 后续日程
//                if settingManager.showCompletedTasks || !task.complete {
//                    futureTasks.append(task)
//                }
//            }
//        }
//        
//        // 批量排序所有分组
//        expiredCompleted.sort { $0.todoTime > $1.todoTime }
//        expiredUncompleted.sort { $0.todoTime < $1.todoTime }
//        
//        let isAscending = settingManager.isTaskSortAscending
//        
//        [&todayTasks, &tomorrowTasks, &dayAfterTomorrowTasks, &noDateTasks].forEach { taskArray in
//            taskArray.sort { task1, task2 in
//                if task1.complete != task2.complete {
//                    return !task1.complete // 未完成的在前
//                }
//                return isAscending ? task1.taskSort < task2.taskSort : task1.taskSort > task2.taskSort
//            }
//        }
//        
//        futureTasks.sort { task1, task2 in
//            if task1.complete != task2.complete {
//                return !task1.complete
//            }
//            if task1.todoTime != task2.todoTime {
//                return task1.todoTime < task2.todoTime
//            }
//            return isAscending ? task1.taskSort < task2.taskSort : task1.taskSort > task2.taskSort
//        }
//        
//        return (expiredCompleted, expiredUncompleted, todayTasks, tomorrowTasks, dayAfterTomorrowTasks, futureTasks, noDateTasks)
//    }
//    
//    /// 应用重复任务限制
//    private func applyRepeatTaskLimit(_ futureTasks: [TDMacSwiftDataListModel]) -> [TDMacSwiftDataListModel] {
//        // 按重复标识分组
//        var groupedByRepeat: [String: [TDMacSwiftDataListModel]] = [:]
//        var nonRepeatTasks: [TDMacSwiftDataListModel] = []
//        
//        for task in futureTasks {
//            if let repeatId = task.standbyStr1, !repeatId.isEmpty {
//                groupedByRepeat[repeatId, default: []].append(task)
//            } else {
//                nonRepeatTasks.append(task)
//            }
//        }
//        
//        // 处理每组重复任务
//        var limitedRepeatTasks: [TDMacSwiftDataListModel] = []
//        for (_, tasks) in groupedByRepeat {
//            let sortedTasks = tasks.sorted { task1, task2 in
//                if task1.complete != task2.complete {
//                    return !task1.complete
//                }
//                return task1.todoTime < task2.todoTime
//            }
//            limitedRepeatTasks.append(contentsOf: sortedTasks.prefix(settingManager.repeatNum))
//        }
//        
//        // 合并并排序
//        let allFutureTasks = (nonRepeatTasks + limitedRepeatTasks).sorted { task1, task2 in
//            if task1.complete != task2.complete {
//                return !task1.complete
//            }
//            if task1.todoTime != task2.todoTime {
//                return task1.todoTime < task2.todoTime
//            }
//            return settingManager.isTaskSortAscending ?
//                task1.taskSort < task2.taskSort :
//                task1.taskSort > task2.taskSort
//        }
//        
//        return allFutureTasks
//    }
//    
//    /// 异步获取待办箱任务
//    private func queryNoDateBoxTasksAsync() async throws -> [TDMacSwiftDataListModel] {
//        return try await Task.detached {
//            let predicate = #Predicate<TDMacSwiftDataListModel> { task in
//                !task.delete &&
//                !task.complete &&
//                task.userId == self.userId &&
//                task.todoTime == 0
//            }
//            
//            let descriptor = FetchDescriptor(
//                predicate: predicate,
//                sortBy: [
//                    SortDescriptor(\TDMacSwiftDataListModel.taskSort,
//                                    order: self.settingManager.isTaskSortAscending ? .forward : .reverse)
//                ]
//            )
//            
//            return try await TDModelContainer.shared.perform {
//                try TDModelContainer.shared.fetch(descriptor)
//            }
//        }.value
//    }
//    
//    /// 异步获取最近已完成任务
//    private func queryRecentCompletedTasksAsync() async throws -> [TDMacSwiftDataListModel] {
//        return try await Task.detached {
//            let predicate = #Predicate<TDMacSwiftDataListModel> { task in
//                !task.delete &&
//                task.complete &&
//                task.userId == self.userId
//            }
//            
//            let descriptor = FetchDescriptor(
//                predicate: predicate,
//                sortBy: [
//                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .reverse),
//                    SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
//                ]
//            )
//            
//            return try await TDModelContainer.shared.perform {
//                try TDModelContainer.shared.fetch(descriptor)
//            }
//        }.value
//    }
//    
//    /// 异步获取回收站任务
//    private func queryRecycleBinTasksAsync() async throws -> [TDMacSwiftDataListModel] {
//        return try await Task.detached {
//            let predicate = #Predicate<TDMacSwiftDataListModel> { task in
//                task.delete &&
//                task.userId == self.userId
//            }
//            
//            let descriptor = FetchDescriptor(
//                predicate: predicate,
//                sortBy: [
//                    SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .reverse)
//                ]
//            )
//            
//            return try await TDModelContainer.shared.perform {
//                try TDModelContainer.shared.fetch(descriptor)
//            }
//        }.value
//    }
//    
//    
//    /// 获取最近待办任务
//    private func queryRecentTasks(categoryId: Int? = nil) async throws -> [TDMacSwiftDataListModel] {
//        return try await Task.detached {
//            let today = Date()
//            var allTasks: [TDMacSwiftDataListModel] = []
//            
//            // 构建基础查询条件
//            let basePredicate = #Predicate<TDMacSwiftDataListModel> { task in
//                !task.delete &&
//                task.userId == self.userId
//    //            (categoryId ?? 0 <= 0 || (task.standbyInt1 ?? -1) == categoryId)
//            }
//            
//            // 1. 获取所有任务（过期和未来的）
//            let descriptor = FetchDescriptor(
//                predicate: basePredicate,
//                sortBy: [
//                    SortDescriptor(\TDMacSwiftDataListModel.todoTime),
//                    SortDescriptor(\TDMacSwiftDataListModel.taskSort,
//                                 order: self.settingManager.isTaskSortAscending ? .forward : .reverse)
//                ]
//            )
//            
//            let tasks = try await TDModelContainer.shared.perform {
//                try TDModelContainer.shared.fetch(descriptor)
//            }
//            // 如果是用户自定义分类，在内存中过滤
//            if categoryId ?? 0 > 0 {
//                return tasks.filter { task in
//                    task.standbyInt1 == categoryId
//                }
//            }
//            
//            // 2. 在内存中进行分组和过滤
//            let todayStart = today.startOfDayTimestamp
//            let tomorrowStart = today.adding(days: 1).startOfDayTimestamp
//            let dayAfterTomorrowStart = today.adding(days: 2).startOfDayTimestamp
//            let dayAfterTomorrowEnd = today.adding(days: 2).endOfDayTimestamp
//            let futureEndTimestamp = self.settingManager.getFutureEndTimestamp(from: today)
//            
//            // 过期任务
//            if self.settingManager.expiredRangeCompleted != .hide {
//                let rangeStart = today.daysAgoStartTimestamp(self.settingManager.expiredRangeCompleted.rawValue)
//                let expiredCompleted = tasks.filter { task in
//                    task.complete &&
//                    task.todoTime < todayStart &&
//                    task.todoTime >= rangeStart
//                }.sorted { $0.todoTime > $1.todoTime }
//                allTasks.append(contentsOf: expiredCompleted)
//            }
//            
//            if self.settingManager.expiredRangeUncompleted != .hide {
//                let rangeStart = today.daysAgoStartTimestamp(self.settingManager.expiredRangeUncompleted.rawValue)
//                let expiredUncompleted = tasks.filter { task in
//                    !task.complete &&
//                    task.todoTime < todayStart &&
//                    task.todoTime >= rangeStart
//                }.sorted { $0.todoTime < $1.todoTime }
//                allTasks.append(contentsOf: expiredUncompleted)
//            }
//        
//            // 今天、明天、后天的任务
//            let dateRanges = [
//                (todayStart, tomorrowStart),
//                (tomorrowStart, dayAfterTomorrowStart),
//                (dayAfterTomorrowStart, dayAfterTomorrowEnd)
//            ]
//            
//            for (start, end) in dateRanges {
//                let dayTasks = tasks.filter { task in
//                    task.todoTime >= start &&
//                    task.todoTime < end &&
//                    (self.settingManager.showCompletedTasks || !task.complete)
//                }.sorted { task1, task2 in
//                    if task1.complete != task2.complete {
//                        return !task1.complete // 未完成的在前
//                    }
//                    // 相同完成状态按taskSort排序
//                    return self.settingManager.isTaskSortAscending ?
//                        task1.taskSort < task2.taskSort :
//                        task1.taskSort > task2.taskSort
//                }
//                allTasks.append(contentsOf: dayTasks)
//            }
//            
//            // 后续日程
//            let futureTasks = tasks.filter { task in
//                task.todoTime > dayAfterTomorrowEnd &&
//                task.todoTime <= futureEndTimestamp &&
//                (self.settingManager.showCompletedTasks || !task.complete)
//            }
//        
//            // 处理重复任务
//            if self.settingManager.repeatNum > 0 {
//                // 按重复标识分组
//                var groupedByRepeat: [String: [TDMacSwiftDataListModel]] = [:]
//                var nonRepeatTasks: [TDMacSwiftDataListModel] = []
//                
//                for task in futureTasks {
//                    if let repeatId = task.standbyStr1, !repeatId.isEmpty {
//                        // 有重复标识的任务
//                        groupedByRepeat[repeatId, default: []].append(task)
//                    } else {
//                        // 无重复标识的任务
//                        nonRepeatTasks.append(task)
//                    }
//                }
//                
//                // 处理每组重复任务
//                var limitedRepeatTasks: [TDMacSwiftDataListModel] = []
//                for (_, tasks) in groupedByRepeat {
//                    let sortedTasks = tasks.sorted { task1, task2 in
//                        if task1.complete != task2.complete {
//                            return !task1.complete
//                        }
//                        return task1.todoTime < task2.todoTime
//                    }
//                    limitedRepeatTasks.append(contentsOf: sortedTasks.prefix(self.settingManager.repeatNum))
//                }
//                
//                // 合并非重复任务和限制后的重复任务
//                let allFutureTasks = (nonRepeatTasks + limitedRepeatTasks).sorted { task1, task2 in
//                    if task1.complete != task2.complete {
//                        return !task1.complete
//                    }
//                    if task1.todoTime != task2.todoTime {
//                        return task1.todoTime < task2.todoTime
//                    }
//                    return self.settingManager.isTaskSortAscending ?
//                        task1.taskSort < task2.taskSort :
//                        task1.taskSort > task2.taskSort
//                }
//                allTasks.append(contentsOf: allFutureTasks)
//            } else {
//                // 不限制重复任务数量
//                let sortedFutureTasks = futureTasks.sorted { task1, task2 in
//                    if task1.complete != task2.complete {
//                        return !task1.complete
//                    }
//                    if task1.todoTime != task2.todoTime {
//                        return task1.todoTime < task2.todoTime
//                    }
//                    return self.settingManager.isTaskSortAscending ?
//                        task1.taskSort < task2.taskSort :
//                        task1.taskSort > task2.taskSort
//                }
//                allTasks.append(contentsOf: sortedFutureTasks)
//            }
//        
//            // 无日期任务
//            let noDateTasks = tasks.filter { task in
//                task.todoTime == 0 &&
//                (self.settingManager.showCompletedTasks || !task.complete)
//            }.sorted { task1, task2 in
//                if task1.complete != task2.complete {
//                    return !task1.complete
//                }
//                return self.settingManager.isTaskSortAscending ?
//                    task1.taskSort < task2.taskSort :
//                    task1.taskSort > task2.taskSort
//            }
//            allTasks.append(contentsOf: noDateTasks)
//            
//            return allTasks
//        }.value
//    }
//    
//    /// 根据日期查询任务（公共接口，保持向后兼容）
//    func queryTasksByDate(timestamp: Int64) async throws -> [TDMacSwiftDataListModel] {
//        return try await queryTasksByDateAsync(timestamp: timestamp)
//    }
//    
//    /// 根据 taskId 和 userId 查询单个任务
//    func findTaskByTaskId(_ taskId: String) async throws -> TDMacSwiftDataListModel? {
//        // 构建查询条件：taskId 和 userId 匹配
//        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
//            task.taskId == taskId &&
//            task.userId == userId
//        }
//        
//        let descriptor = FetchDescriptor(
//            predicate: predicate
//        )
//        
//        // 获取任务
//        return try await TDModelContainer.shared.perform {
//            try TDModelContainer.shared.fetchOne(descriptor)
//        }
//    }
//    /// 获取所有未同步的任务并转为 JSON 字符串
//    func getAllUnsyncedTasksJson() async throws -> String {
//        // 构建查询条件：userId 匹配且 status 不是 "sync"
//        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
//            task.userId == userId &&
//            task.status != "sync"
//        }
//        
//        let descriptor = FetchDescriptor(
//            predicate: predicate,
//            sortBy: [SortDescriptor(\TDMacSwiftDataListModel.createTime, order: .forward)]
//        )
//        
//        // 获取未同步的任务
//        let unsyncedTasks = try await TDModelContainer.shared.perform {
//            try TDModelContainer.shared.fetch(descriptor)
//        }
//        
//        // 转换为 TDTaskModel 数组
//        let taskModels = unsyncedTasks.map { TDTaskModel(from: $0) }
//        // 使用 TDSwiftJsonUtil 将任务数组转换为 JSON 字符串
//        return TDSwiftJsonUtil.arrayToJson(taskModels) ?? "[]"
//    }
//    
//    
//    /// 根据同步结果更新本地任务状态
//    func updateLocalTasksAfterSync(results: [TDTaskSyncResultModel]) async throws {
//        for result in results {
//            guard result.succeed else { continue }
//            
//            // 查询本地任务
//            if let task = try await findTaskByTaskId(result.taskId) {
//                // 更新任务状态和版本
//                task.status = "sync"
//                task.version = result.version
//
//            }
//        }
//        
//        // 保存更改
//        try  TDModelContainer.shared.save()
//    }
//
//    
//    
//    /// 批量更新本地任务的所有字段
//    func updateLocalTaskFields(_ updatedTasks: [TDMacSwiftDataListModel]) async throws {
//        print("开始更新 \(updatedTasks.count) 条数据...")
//        
//        // 分批处理数据
//        let batchSize = 100
//        for i in stride(from: 0, to: updatedTasks.count, by: batchSize) {
//            let end = min(i + batchSize, updatedTasks.count)
//            let batch = updatedTasks[i..<end]
//            
//            // 处理这一批数据
//            for updatedTask in batch {
//                if let localTask = try await findTaskByTaskId(updatedTask.taskId) {
//                    // 更新所有字段
//                    localTask.id = updatedTask.id
//                    localTask.taskId = updatedTask.taskId
//                    localTask.taskContent = updatedTask.taskContent
//                    localTask.taskDescribe = updatedTask.taskDescribe
//                    localTask.complete = updatedTask.complete
//                    localTask.createTime = updatedTask.createTime
//                    localTask.delete = updatedTask.delete
//                    localTask.reminderTime = updatedTask.reminderTime
//                    localTask.snowAdd = updatedTask.snowAdd
//                    localTask.snowAssess = updatedTask.snowAssess
//                    localTask.standbyInt1 = updatedTask.standbyInt1
//                    localTask.standbyStr1 = updatedTask.standbyStr1
//                    localTask.standbyStr2 = updatedTask.standbyStr2
//                    localTask.standbyStr3 = updatedTask.standbyStr3
//                    localTask.standbyStr4 = updatedTask.standbyStr4
//                    localTask.syncTime = updatedTask.syncTime
//                    localTask.taskSort = updatedTask.taskSort
//                    localTask.todoTime = updatedTask.todoTime
//                    localTask.userId = updatedTask.userId
//                    localTask.version = updatedTask.version
//                    localTask.status = updatedTask.status
//                    localTask.isSubOpen = updatedTask.isSubOpen
//                    localTask.number = updatedTask.number
//                    localTask.standbyIntColor = updatedTask.standbyIntColor
//                    localTask.standbyIntName = updatedTask.standbyIntName
//                    localTask.reminderTimeString = updatedTask.reminderTimeString
//                    localTask.subTaskList = updatedTask.subTaskList
//                    localTask.attachmentList = updatedTask.attachmentList
//                }
//            }
//            
//            // 保存这一批的更改
//            try TDModelContainer.shared.save()
//            print("已更新 \(end)/\(updatedTasks.count) 条数据")
//        }
//        
//        print("数据更新完成")
//    }
//
//    
////    /// 获取最近待办任务
////    private func queryRecentTasks(categoryId: Int? = nil) async throws -> [TDMacSwiftDataListModel] {
////        let today = Date()
////        var allTasks: [TDMacSwiftDataListModel] = []
////        
////        // 1. 获取过期已完成任务
////        if settingManager.expiredRangeCompleted != .hide {
////            let rangeStartTimestamp = today.daysAgoStartTimestamp(settingManager.expiredRangeCompleted.rawValue)
////            
////            let expiredCompletedPredicate = #Predicate<TDMacSwiftDataListModel> { task in
////                !task.delete &&
////                task.complete &&
////                task.userId == userId &&
////                task.todoTime < today.startOfDayTimestamp &&
////                task.todoTime >= rangeStartTimestamp &&
////                (categoryId == nil || task.standbyInt1 == categoryId)
////            }
////            
////            let descriptor = FetchDescriptor(
////                predicate: expiredCompletedPredicate,
////                sortBy: [SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .reverse)]
////            )
////            
////            let expiredCompletedTasks = try await TDModelContainer.shared.perform {
////                try TDModelContainer.shared.fetch(descriptor)
////            }
////            allTasks.append(contentsOf: expiredCompletedTasks)
////        }
////        
////        // 2. 获取过期未完成任务
////        if settingManager.expiredRangeUncompleted != .hide {
////            let rangeStartTimestamp = today.daysAgoStartTimestamp(settingManager.expiredRangeUncompleted.rawValue)
////            
////            let expiredUncompletedPredicate = #Predicate<TDMacSwiftDataListModel> { task in
////                !task.delete &&
////                !task.complete &&
////                task.userId == userId &&
////                task.todoTime < today.startOfDayTimestamp &&
////                task.todoTime >= rangeStartTimestamp &&
////                (categoryId == nil || task.standbyInt1 == categoryId)
////            }
////            
////            let descriptor = FetchDescriptor(
////                predicate: expiredUncompletedPredicate,
////                sortBy: [SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward)]
////            )
////            
////            let expiredUncompletedTasks = try await TDModelContainer.shared.perform {
////                try TDModelContainer.shared.fetch(descriptor)
////            }
////            allTasks.append(contentsOf: expiredUncompletedTasks)
////        }
////        
////        // 3. 获取今天、明天、后天的任务
////        let dates = [
////            (today.startOfDayTimestamp, today.endOfDayTimestamp),
////            (today.adding(days: 1).startOfDayTimestamp, today.adding(days: 1).endOfDayTimestamp),
////            (today.adding(days: 2).startOfDayTimestamp, today.adding(days: 2).endOfDayTimestamp)
////        ]
////        
////        for (start, end) in dates {
////            // 先获取未完成任务
////            let uncompletedPredicate = #Predicate<TDMacSwiftDataListModel> { task in
////                !task.delete &&
////                !task.complete &&
////                task.userId == userId &&
////                task.todoTime >= start &&
////                task.todoTime <= end &&
////                (categoryId == nil || task.standbyInt1 == categoryId)
////            }
////            
////            let uncompletedDescriptor = FetchDescriptor(
////                predicate: uncompletedPredicate,
////                sortBy: [
////                    SortDescriptor(\TDMacSwiftDataListModel.taskSort,
////                                    order: settingManager.isTaskSortAscending ? .forward : .reverse)
////                ]
////            )
////            
////            let uncompletedTasks = try await TDModelContainer.shared.perform {
////                try TDModelContainer.shared.fetch(uncompletedDescriptor)
////            }
////            allTasks.append(contentsOf: uncompletedTasks)
////            
////            // 如果需要显示已完成任务
////            if settingManager.showCompletedTasks {
////                let completedPredicate = #Predicate<TDMacSwiftDataListModel> { task in
////                    !task.delete &&
////                    task.complete &&
////                    task.userId == userId &&
////                    task.todoTime >= start &&
////                    task.todoTime <= end &&
////                    (categoryId == nil || task.standbyInt1 == categoryId)
////                }
////                
////                let completedDescriptor = FetchDescriptor(
////                    predicate: completedPredicate,
////                    sortBy: [
////                        SortDescriptor(\TDMacSwiftDataListModel.taskSort,
////                                        order: settingManager.isTaskSortAscending ? .forward : .reverse)
////                    ]
////                )
////                
////                let completedTasks = try await TDModelContainer.shared.perform {
////                    try TDModelContainer.shared.fetch(completedDescriptor)
////                }
////                allTasks.append(contentsOf: completedTasks)
////            }
////        }
////    }
//    
//    
//    // MARK: - 私有查询方法
//    // MARK: - 辅助方法
//    
////    /// 构建任务排序描述符
////    private func buildTaskSortDescriptor() -> SortDescriptor<TDMacSwiftDataListModel> {
////        SortDescriptor(
////            \TDMacSwiftDataListModel.taskSort,
////             order: settingManager.isTaskSortAscending ? .forward : .reverse
////        )
////    }
////    /// 查询待办箱任务(无日期任务)
////    private func queryNoDateBoxTasks() async throws -> [TDMacSwiftDataListModel] {
////        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
////            !task.delete &&
////            !task.complete &&
////            task.userId == userId &&
////            task.todoTime == 0
////        }
////        
////        return try await fetchTasks(
////            predicate: predicate,
////            sortDescriptors: buildNoDateSortDescriptors()
////        )
////    }
////    /// 构建无日期任务的排序描述符
////       private func buildNoDateSortDescriptors() -> [SortDescriptor<TDMacSwiftDataListModel>] {
////           // 注意：不能直接用 complete 布尔值排序
////           // 我们在查询时已经分开获取了完成和未完成的任务
////           
////           // 1. 按用户设置的排序方式
////           let taskSortDescriptor = SortDescriptor(
////               \TDMacSwiftDataListModel.taskSort,
////               order: settingManager.isTaskSortAscending ? .forward : .reverse
////           )
////           
////           // 2. 按优先级排序
////           let priorityDescriptor = SortDescriptor(
////               \TDMacSwiftDataListModel.snowAssess,
////               order: .reverse
////           )
////           
////           // 3. 按创建时间排序
////           let createTimeDescriptor = SortDescriptor(
////               \TDMacSwiftDataListModel.createTime,
////               order: .reverse
////           )
////           
////           return [
////               taskSortDescriptor,     // 用户设置的排序
////               priorityDescriptor,     // 优先级
////               createTimeDescriptor    // 创建时间
////           ]
////       }
////    /// 查询最近已完成任务
////    private func queryRecentCompletedTasks() async throws -> [TDMacSwiftDataListModel] {
////        let thirtyDaysAgo = Date().daysAgoStartTimestamp(30)
////        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
////            !task.delete &&
////            task.complete &&
////            task.userId == userId &&
////            task.syncTime >= thirtyDaysAgo
////        }
////        
////        var descriptor = FetchDescriptor(
////            predicate: predicate,
////            sortBy: [SortDescriptor(\TDMacSwiftDataListModel.syncTime, order: .reverse)]
////        )
////        descriptor.fetchLimit = 300
////        
////        return try await TDModelContainer.shared.perform {
////            try TDModelContainer.shared.fetch(descriptor)
////        }
////    }
////    
////    /// 查询回收站任务
////    private func queryRecycleBinTasks() async throws -> [TDMacSwiftDataListModel] {
////        let thirtyDaysAgo = Date().daysAgoStartTimestamp(30)
////        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
////            task.delete &&
////            task.userId == userId &&
////            task.syncTime >= thirtyDaysAgo
////        }
////        
////        var descriptor = FetchDescriptor(
////            predicate: predicate,
////            sortBy: [SortDescriptor(\TDMacSwiftDataListModel.syncTime, order: .reverse)]
////        )
////        descriptor.fetchLimit = 300
////        
////        return try await TDModelContainer.shared.perform {
////            try TDModelContainer.shared.fetch(descriptor)
////        }
////    }
////
////    /// 通用的任务查询方法
////       private func fetchTasks(
////           predicate: Predicate<TDMacSwiftDataListModel>,
////           sortDescriptors: [SortDescriptor<TDMacSwiftDataListModel>]
////       ) async throws -> [TDMacSwiftDataListModel] {
////           let descriptor = FetchDescriptor(
////               predicate: predicate,
////               sortBy: sortDescriptors
////           )
////           
////           return try await TDModelContainer.shared.perform {
////               try TDModelContainer.shared.fetch(descriptor)
////           }
////       }
//}
