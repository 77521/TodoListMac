//
//  TDQueryConditionManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/17.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class TDQueryConditionManager: ObservableObject {
    /// 单例
    static let shared = TDQueryConditionManager()
    // MARK: - 私有属性
    private let settingManager = TDSettingManager.shared
    private let userId = TDUserManager.shared.userId
    
    private init() {}
    
    /// 获取已同步任务的最大时间戳
    func getMaxSyncVersion() async throws -> Int {
        // 在进入 Task.detached 之前捕获 userId
        let userId = self.userId
        
        return await Task.detached {
            var descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
                predicate: #Predicate<TDMacSwiftDataListModel> { task in
                    task.userId == userId &&
                    !task.delete &&
                    task.status == "sync"
                }, sortBy: [SortDescriptor(\TDMacSwiftDataListModel.version, order: .reverse)]
            )
            descriptor.fetchLimit = 1
            
            do {
                if let result = try await TDModelContainer.shared.fetchOne(descriptor) {
                    return result.version
                }
                return 0
            } catch {
                print("获取最大同步时间戳失败: \(error)")
                return 0
            }
        }.value
    }
    
    /// 查询本地是否存在指定任务
    func findLocalTask(taskId: String) async -> TDMacSwiftDataListModel? {
        return await Task.detached {
            let descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
                predicate: #Predicate<TDMacSwiftDataListModel> { task in
                    task.taskId == taskId
                }
            )
            
            do {
                return try await TDModelContainer.shared.fetchOne(descriptor)
            } catch {
                print("查询本地任务失败: \(error)")
                return nil
            }
        }.value
    }
    
    /// 保存任务数据到本地
    func saveTasks(_ tasks: [TDMacSwiftDataListModel], batchSize: Int = 100) async throws {
        print("开始保存 \(tasks.count) 条数据...")
        
        // 分批处理数据
        for i in stride(from: 0, to: tasks.count, by: batchSize) {
            let end = min(i + batchSize, tasks.count)
            let batch = tasks[i..<end]
            
            // 处理这一批数据
            for task in batch {
                if let existingTask = await findLocalTask(taskId: task.taskId) {
                    // 更新现有数据
                    existingTask.id = task.id
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
                    existingTask.userId = task.userId
                    existingTask.version = task.version
                    existingTask.status = task.status
                    existingTask.isSubOpen = task.isSubOpen
                    existingTask.number = task.number
                    existingTask.standbyIntColor = task.standbyIntColor
                    existingTask.standbyIntName = task.standbyIntName
                    existingTask.reminderTimeString = task.reminderTimeString
                    existingTask.subTaskList = task.subTaskList
                    existingTask.attachmentList = task.attachmentList
                } else {
                    // 插入新数据
                    TDModelContainer.shared.insert(task)
                }
            }
            
            try TDModelContainer.shared.save()
            print("已保存 \(end)/\(tasks.count) 条数据")
        }
        
        print("数据保存完成")
    }
    
    /// 根据日期查询任务
//    func queryTasksByDate(timestamp: Int64) async throws -> [TDMacSwiftDataListModel] {
//        let sortOrder: SortOrder = settingManager.isTaskSortAscending ? .forward : .reverse
//        
//        // 1. 查询未完成的任务
//        let uncompletedPredicate = #Predicate<TDMacSwiftDataListModel> { task in
//            task.todoTime == timestamp &&
//            !task.delete &&
//            !task.complete &&
//            task.userId == userId
//        }
//        
//        let uncompletedDescriptor = FetchDescriptor(
//            predicate: uncompletedPredicate,
//            sortBy: [SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: sortOrder)]
//        )
//        
//        var allTasks = try await TDModelContainer.shared.perform {
//            try TDModelContainer.shared.fetch(uncompletedDescriptor)
//        }
//        
//        // 2. 如果需要显示已完成任务
//        if settingManager.showCompletedTasks {
//            let completedPredicate = #Predicate<TDMacSwiftDataListModel> { task in
//                task.todoTime == timestamp &&
//                !task.delete &&
//                task.complete &&
//                task.userId == userId
//            }
//            
//            let completedDescriptor = FetchDescriptor(
//                predicate: completedPredicate,
//                sortBy: [SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: sortOrder)]
//            )
//            
//            let completedTasks = try await TDModelContainer.shared.perform {
//                try TDModelContainer.shared.fetch(completedDescriptor)
//            }
//            
//            allTasks.append(contentsOf: completedTasks)
//        }
//        
//        // 3. 如果需要显示本地日历数据
//        if settingManager.showLocalCalendarEvents {
//            let calendar = Calendar.current
//            let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
//            let startOfDay = calendar.startOfDay(for: date)
//            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
//            
//            let localEvents = try await TDCalendarService.shared.fetchLocalEvents(
//                from: startOfDay,
//                to: startOfDay
//            )
//            
//            allTasks.append(contentsOf: localEvents)
//        }
//        
//        return allTasks
//    }
    
    /// 获取本地任务数据
    func queryLocalTasks(categoryId: Int) async throws -> [TDMacSwiftDataListModel] {
        switch categoryId {
        case -100: // DayTodo
            return try await queryTasksByDate(timestamp: Date().startOfDayTimestamp)
            
        case -101: // 最近待办
            return try await queryRecentTasks()

        case -103: // 待办箱(无日期任务)
//            return try await queryNoDateBoxTasks()
            return []

        case -107: // 最近已完成
//            return try await queryRecentCompletedTasks()
            return []

        case -108: // 回收站
//            return try await queryRecycleBinTasks()
            return []

        case _ where categoryId >= 0: // 自定义分类
            return try await queryRecentTasks(categoryId: categoryId)

        default:
            return []
        }
    }
    
    /// 根据日期查询任务
    func queryTasksByDate(timestamp: Int64) async throws -> [TDMacSwiftDataListModel] {
        var allTasks: [TDMacSwiftDataListModel] = []
        
        // 1. 查询未完成的任务
        let uncompletedPredicate = #Predicate<TDMacSwiftDataListModel> { task in
            !task.delete &&
            !task.complete &&
            task.userId == userId &&
            task.todoTime == timestamp
        }
        
        let uncompletedDescriptor = FetchDescriptor(
            predicate: uncompletedPredicate,
            sortBy: [
                SortDescriptor(\TDMacSwiftDataListModel.taskSort,
                                order: settingManager.isTaskSortAscending ? .forward : .reverse)
            ]
        )
        
        allTasks = try await TDModelContainer.shared.perform {
            try TDModelContainer.shared.fetch(uncompletedDescriptor)
        }
        
        // 2. 如果需要显示已完成任务
        if settingManager.showCompletedTasks {
            let completedPredicate = #Predicate<TDMacSwiftDataListModel> { task in
                !task.delete &&
                task.complete &&
                task.userId == userId &&
                task.todoTime == timestamp
            }
            
            let completedDescriptor = FetchDescriptor(
                predicate: completedPredicate,
                sortBy: [
                    SortDescriptor(\TDMacSwiftDataListModel.taskSort,
                                    order: settingManager.isTaskSortAscending ? .forward : .reverse)
                ]
            )
            
            let completedTasks = try await TDModelContainer.shared.perform {
                try TDModelContainer.shared.fetch(completedDescriptor)
            }
            
            allTasks.append(contentsOf: completedTasks)
        }
        
        // 3. 如果需要显示本地日历数据
        if settingManager.showLocalCalendarEvents {
            let date = Date.fromTimestamp(timestamp)
            let endDate = date.adding(days: 1)
            
            let localEvents = try await TDCalendarService.shared.fetchLocalEvents(
                from: date,
                to: endDate
            )
            
            allTasks.append(contentsOf: localEvents)
        }
        
        return allTasks
    }
    
    
    /// 获取最近待办任务
    private func queryRecentTasks(categoryId: Int? = nil) async throws -> [TDMacSwiftDataListModel] {
        let today = Date()
        var allTasks: [TDMacSwiftDataListModel] = []
        
        // 构建基础查询条件
        let basePredicate = #Predicate<TDMacSwiftDataListModel> { task in
            !task.delete &&
            task.userId == userId 
//            (categoryId ?? 0 <= 0 || (task.standbyInt1 ?? -1) == categoryId)
        }
        
        // 1. 获取所有任务（过期和未来的）
        let descriptor = FetchDescriptor(
            predicate: basePredicate,
            sortBy: [
                SortDescriptor(\TDMacSwiftDataListModel.todoTime),
                SortDescriptor(\TDMacSwiftDataListModel.taskSort,
                             order: settingManager.isTaskSortAscending ? .forward : .reverse)
            ]
        )
        
        let tasks = try await TDModelContainer.shared.perform {
            try TDModelContainer.shared.fetch(descriptor)
        }
        // 如果是用户自定义分类，在内存中过滤
        if categoryId ?? 0 > 0 {
            return tasks.filter { task in
                task.standbyInt1 == categoryId
            }
        }
        
        // 2. 在内存中进行分组和过滤
        let todayStart = today.startOfDayTimestamp
        let tomorrowStart = today.adding(days: 1).startOfDayTimestamp
        let dayAfterTomorrowStart = today.adding(days: 2).startOfDayTimestamp
        let dayAfterTomorrowEnd = today.adding(days: 2).endOfDayTimestamp
        let futureEndTimestamp = settingManager.getFutureEndTimestamp(from: today)
        
        // 过期任务
        if settingManager.expiredRangeCompleted != .hide {
            let rangeStart = today.daysAgoStartTimestamp(settingManager.expiredRangeCompleted.rawValue)
            let expiredCompleted = tasks.filter { task in
                task.complete &&
                task.todoTime < todayStart &&
                task.todoTime >= rangeStart
            }.sorted { $0.todoTime > $1.todoTime }
            allTasks.append(contentsOf: expiredCompleted)
        }
        
        if settingManager.expiredRangeUncompleted != .hide {
            let rangeStart = today.daysAgoStartTimestamp(settingManager.expiredRangeUncompleted.rawValue)
            let expiredUncompleted = tasks.filter { task in
                !task.complete &&
                task.todoTime < todayStart &&
                task.todoTime >= rangeStart
            }.sorted { $0.todoTime < $1.todoTime }
            allTasks.append(contentsOf: expiredUncompleted)
        }
        
        // 今天、明天、后天的任务
        let dateRanges = [
            (todayStart, tomorrowStart),
            (tomorrowStart, dayAfterTomorrowStart),
            (dayAfterTomorrowStart, dayAfterTomorrowEnd)
        ]
        
        for (start, end) in dateRanges {
            let dayTasks = tasks.filter { task in
                task.todoTime >= start &&
                task.todoTime < end &&
                (settingManager.showCompletedTasks || !task.complete)
            }.sorted { task1, task2 in
                if task1.complete != task2.complete {
                    return !task1.complete // 未完成的在前
                }
                // 相同完成状态按taskSort排序
                return settingManager.isTaskSortAscending ?
                    task1.taskSort < task2.taskSort :
                    task1.taskSort > task2.taskSort
            }
            allTasks.append(contentsOf: dayTasks)
        }
        
        // 后续日程
        let futureTasks = tasks.filter { task in
            task.todoTime > dayAfterTomorrowEnd &&
            task.todoTime <= futureEndTimestamp &&
            (settingManager.showCompletedTasks || !task.complete)
        }
        
        // 处理重复任务
        if settingManager.repeatNum > 0 {
            // 按重复标识分组
            var groupedByRepeat: [String: [TDMacSwiftDataListModel]] = [:]
            var nonRepeatTasks: [TDMacSwiftDataListModel] = []
            
            for task in futureTasks {
                if let repeatId = task.standbyStr1, !repeatId.isEmpty {
                    // 有重复标识的任务
                    groupedByRepeat[repeatId, default: []].append(task)
                } else {
                    // 无重复标识的任务
                    nonRepeatTasks.append(task)
                }
            }
            
            // 处理每组重复任务
            var limitedRepeatTasks: [TDMacSwiftDataListModel] = []
            for (_, tasks) in groupedByRepeat {
                let sortedTasks = tasks.sorted { task1, task2 in
                    if task1.complete != task2.complete {
                        return !task1.complete
                    }
                    return task1.todoTime < task2.todoTime
                }
                limitedRepeatTasks.append(contentsOf: sortedTasks.prefix(settingManager.repeatNum))
            }
            
            // 合并非重复任务和限制后的重复任务
            let allFutureTasks = (nonRepeatTasks + limitedRepeatTasks).sorted { task1, task2 in
                if task1.complete != task2.complete {
                    return !task1.complete
                }
                if task1.todoTime != task2.todoTime {
                    return task1.todoTime < task2.todoTime
                }
                return settingManager.isTaskSortAscending ?
                    task1.taskSort < task2.taskSort :
                    task1.taskSort > task2.taskSort
            }
            allTasks.append(contentsOf: allFutureTasks)
        } else {
            // 不限制重复任务数量
            let sortedFutureTasks = futureTasks.sorted { task1, task2 in
                if task1.complete != task2.complete {
                    return !task1.complete
                }
                if task1.todoTime != task2.todoTime {
                    return task1.todoTime < task2.todoTime
                }
                return settingManager.isTaskSortAscending ?
                    task1.taskSort < task2.taskSort :
                    task1.taskSort > task2.taskSort
            }
            allTasks.append(contentsOf: sortedFutureTasks)
        }
        
        // 无日期任务
        let noDateTasks = tasks.filter { task in
            task.todoTime == 0 &&
            (settingManager.showCompletedTasks || !task.complete)
        }.sorted { task1, task2 in
            if task1.complete != task2.complete {
                return !task1.complete
            }
            return settingManager.isTaskSortAscending ?
                task1.taskSort < task2.taskSort :
                task1.taskSort > task2.taskSort
        }
        allTasks.append(contentsOf: noDateTasks)
        
        return allTasks
    }
//    /// 获取最近待办任务
//    private func queryRecentTasks(categoryId: Int? = nil) async throws -> [TDMacSwiftDataListModel] {
//        let today = Date()
//        var allTasks: [TDMacSwiftDataListModel] = []
//        
//        // 1. 获取过期已完成任务
//        if settingManager.expiredRangeCompleted != .hide {
//            let rangeStartTimestamp = today.daysAgoStartTimestamp(settingManager.expiredRangeCompleted.rawValue)
//            
//            let expiredCompletedPredicate = #Predicate<TDMacSwiftDataListModel> { task in
//                !task.delete &&
//                task.complete &&
//                task.userId == userId &&
//                task.todoTime < today.startOfDayTimestamp &&
//                task.todoTime >= rangeStartTimestamp &&
//                (categoryId == nil || task.standbyInt1 == categoryId)
//            }
//            
//            let descriptor = FetchDescriptor(
//                predicate: expiredCompletedPredicate,
//                sortBy: [SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .reverse)]
//            )
//            
//            let expiredCompletedTasks = try await TDModelContainer.shared.perform {
//                try TDModelContainer.shared.fetch(descriptor)
//            }
//            allTasks.append(contentsOf: expiredCompletedTasks)
//        }
//        
//        // 2. 获取过期未完成任务
//        if settingManager.expiredRangeUncompleted != .hide {
//            let rangeStartTimestamp = today.daysAgoStartTimestamp(settingManager.expiredRangeUncompleted.rawValue)
//            
//            let expiredUncompletedPredicate = #Predicate<TDMacSwiftDataListModel> { task in
//                !task.delete &&
//                !task.complete &&
//                task.userId == userId &&
//                task.todoTime < today.startOfDayTimestamp &&
//                task.todoTime >= rangeStartTimestamp &&
//                (categoryId == nil || task.standbyInt1 == categoryId)
//            }
//            
//            let descriptor = FetchDescriptor(
//                predicate: expiredUncompletedPredicate,
//                sortBy: [SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward)]
//            )
//            
//            let expiredUncompletedTasks = try await TDModelContainer.shared.perform {
//                try TDModelContainer.shared.fetch(descriptor)
//            }
//            allTasks.append(contentsOf: expiredUncompletedTasks)
//        }
//        
//        // 3. 获取今天、明天、后天的任务
//        let dates = [
//            (today.startOfDayTimestamp, today.endOfDayTimestamp),
//            (today.adding(days: 1).startOfDayTimestamp, today.adding(days: 1).endOfDayTimestamp),
//            (today.adding(days: 2).startOfDayTimestamp, today.adding(days: 2).endOfDayTimestamp)
//        ]
//        
//        for (start, end) in dates {
//            // 先获取未完成任务
//            let uncompletedPredicate = #Predicate<TDMacSwiftDataListModel> { task in
//                !task.delete &&
//                !task.complete &&
//                task.userId == userId &&
//                task.todoTime >= start &&
//                task.todoTime <= end &&
//                (categoryId == nil || task.standbyInt1 == categoryId)
//            }
//            
//            let uncompletedDescriptor = FetchDescriptor(
//                predicate: uncompletedPredicate,
//                sortBy: [
//                    SortDescriptor(\TDMacSwiftDataListModel.taskSort,
//                                    order: settingManager.isTaskSortAscending ? .forward : .reverse)
//                ]
//            )
//            
//            let uncompletedTasks = try await TDModelContainer.shared.perform {
//                try TDModelContainer.shared.fetch(uncompletedDescriptor)
//            }
//            allTasks.append(contentsOf: uncompletedTasks)
//            
//            // 如果需要显示已完成任务
//            if settingManager.showCompletedTasks {
//                let completedPredicate = #Predicate<TDMacSwiftDataListModel> { task in
//                    !task.delete &&
//                    task.complete &&
//                    task.userId == userId &&
//                    task.todoTime >= start &&
//                    task.todoTime <= end &&
//                    (categoryId == nil || task.standbyInt1 == categoryId)
//                }
//                
//                let completedDescriptor = FetchDescriptor(
//                    predicate: completedPredicate,
//                    sortBy: [
//                        SortDescriptor(\TDMacSwiftDataListModel.taskSort,
//                                        order: settingManager.isTaskSortAscending ? .forward : .reverse)
//                    ]
//                )
//                
//                let completedTasks = try await TDModelContainer.shared.perform {
//                    try TDModelContainer.shared.fetch(completedDescriptor)
//                }
//                allTasks.append(contentsOf: completedTasks)
//            }
//        }
//    }
    
    
    // MARK: - 私有查询方法
    // MARK: - 辅助方法
    
//    /// 构建任务排序描述符
//    private func buildTaskSortDescriptor() -> SortDescriptor<TDMacSwiftDataListModel> {
//        SortDescriptor(
//            \TDMacSwiftDataListModel.taskSort,
//             order: settingManager.isTaskSortAscending ? .forward : .reverse
//        )
//    }
//    /// 查询待办箱任务(无日期任务)
//    private func queryNoDateBoxTasks() async throws -> [TDMacSwiftDataListModel] {
//        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
//            !task.delete &&
//            !task.complete &&
//            task.userId == userId &&
//            task.todoTime == 0
//        }
//        
//        return try await fetchTasks(
//            predicate: predicate,
//            sortDescriptors: buildNoDateSortDescriptors()
//        )
//    }
//    /// 构建无日期任务的排序描述符
//       private func buildNoDateSortDescriptors() -> [SortDescriptor<TDMacSwiftDataListModel>] {
//           // 注意：不能直接用 complete 布尔值排序
//           // 我们在查询时已经分开获取了完成和未完成的任务
//           
//           // 1. 按用户设置的排序方式
//           let taskSortDescriptor = SortDescriptor(
//               \TDMacSwiftDataListModel.taskSort,
//               order: settingManager.isTaskSortAscending ? .forward : .reverse
//           )
//           
//           // 2. 按优先级排序
//           let priorityDescriptor = SortDescriptor(
//               \TDMacSwiftDataListModel.snowAssess,
//               order: .reverse
//           )
//           
//           // 3. 按创建时间排序
//           let createTimeDescriptor = SortDescriptor(
//               \TDMacSwiftDataListModel.createTime,
//               order: .reverse
//           )
//           
//           return [
//               taskSortDescriptor,     // 用户设置的排序
//               priorityDescriptor,     // 优先级
//               createTimeDescriptor    // 创建时间
//           ]
//       }
//    /// 查询最近已完成任务
//    private func queryRecentCompletedTasks() async throws -> [TDMacSwiftDataListModel] {
//        let thirtyDaysAgo = Date().daysAgoStartTimestamp(30)
//        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
//            !task.delete &&
//            task.complete &&
//            task.userId == userId &&
//            task.syncTime >= thirtyDaysAgo
//        }
//        
//        var descriptor = FetchDescriptor(
//            predicate: predicate,
//            sortBy: [SortDescriptor(\TDMacSwiftDataListModel.syncTime, order: .reverse)]
//        )
//        descriptor.fetchLimit = 300
//        
//        return try await TDModelContainer.shared.perform {
//            try TDModelContainer.shared.fetch(descriptor)
//        }
//    }
//    
//    /// 查询回收站任务
//    private func queryRecycleBinTasks() async throws -> [TDMacSwiftDataListModel] {
//        let thirtyDaysAgo = Date().daysAgoStartTimestamp(30)
//        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
//            task.delete &&
//            task.userId == userId &&
//            task.syncTime >= thirtyDaysAgo
//        }
//        
//        var descriptor = FetchDescriptor(
//            predicate: predicate,
//            sortBy: [SortDescriptor(\TDMacSwiftDataListModel.syncTime, order: .reverse)]
//        )
//        descriptor.fetchLimit = 300
//        
//        return try await TDModelContainer.shared.perform {
//            try TDModelContainer.shared.fetch(descriptor)
//        }
//    }
//
//    /// 通用的任务查询方法
//       private func fetchTasks(
//           predicate: Predicate<TDMacSwiftDataListModel>,
//           sortDescriptors: [SortDescriptor<TDMacSwiftDataListModel>]
//       ) async throws -> [TDMacSwiftDataListModel] {
//           let descriptor = FetchDescriptor(
//               predicate: predicate,
//               sortBy: sortDescriptors
//           )
//           
//           return try await TDModelContainer.shared.perform {
//               try TDModelContainer.shared.fetch(descriptor)
//           }
//       }
}
