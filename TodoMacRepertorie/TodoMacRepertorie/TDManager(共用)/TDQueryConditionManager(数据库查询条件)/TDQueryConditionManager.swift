//
//  TDQueryConditionManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI
import SwiftData

/// 查询条件管理器
/// 负责调用 TDCorrectQueryBuilder 获取本地数据，并处理服务器数据同步
@MainActor
class TDQueryConditionManager {
    
    
    // MARK: - 单例
    static let shared = TDQueryConditionManager()
    
//    private init() {}
    
    // MARK: - 根据日期查询任务
    
    /// 根据选择的日期查询任务数据
    /// - Parameters:
    ///   - selectedDate: 选择的日期
    ///   - context: SwiftData 上下文
    /// - Returns: 任务列表
    func getTasksByDate(selectedDate: Date, context: ModelContext) async throws -> [TDMacSwiftDataListModel] {
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getDayTodoQuery(selectedDate: selectedDate)
        let descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
            predicate: predicate,
            sortBy: sortDescriptors
        )
        return try context.fetch(descriptor)
    }

    // MARK: - 获取本地最大 version 值
    
    /// 获取本地最大 version 值（用于同步流程）
    /// 查询条件：userid = 本地登录用户 id，status = "sync"
    /// - Parameter context: SwiftData 上下文
    /// - Returns: 最大 version 值，如果没有数据返回 0
    func getLocalMaxVersion(context: ModelContext) async throws -> Int64 {
        // 确保在主线程执行数据库操作
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getLocalMaxVersionQuery()
        var fetchDescriptor = FetchDescriptor(predicate: predicate, sortBy: sortDescriptors)
        fetchDescriptor.fetchLimit = 1
        
        let tasks = try context.fetch(fetchDescriptor)
        return tasks.first?.version ?? 0
    }
    
    /// 获取本地最大 version 值（用于本地增删改）
    /// 查询条件：userid = 本地登录用户 id
    /// - Parameter context: SwiftData 上下文
    /// - Returns: 最大 version 值，如果没有数据返回 0
    func getLocalMaxVersionForLocal(context: ModelContext) async throws -> Int64 {
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getLocalMaxVersionForLocalQuery()
        var fetchDescriptor = FetchDescriptor(predicate: predicate, sortBy: sortDescriptors)
        fetchDescriptor.fetchLimit = 1
        
        let tasks = try context.fetch(fetchDescriptor)
        return tasks.first?.version ?? 0
    }

    /// 获取指定日期的最大 taskSort 值
    /// 查询条件：userid = 本地登录用户 id，delete = false，todoTime = 传入的时间戳
    /// - Parameters:
    ///   - todoTime: 日期时间戳
    ///   - context: SwiftData 上下文
    /// - Returns: 最大 taskSort 值，如果没有数据返回 0
    func getMaxTaskSortForDate(
        todoTime: Int64,
        context: ModelContext
    ) async throws -> Decimal {
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getMaxTaskSortForDateQuery(todoTime)
        var fetchDescriptor = FetchDescriptor(predicate: predicate, sortBy: sortDescriptors)
        fetchDescriptor.fetchLimit = 1
        
        let tasks = try context.fetch(fetchDescriptor)
        return tasks.first?.taskSort ?? 0
    }
    
    /// 获取指定日期的最小 taskSort 值
    /// 查询条件：userid = 本地登录用户 id，delete = false，todoTime = 传入的时间戳
    /// - Parameters:
    ///   - todoTime: 日期时间戳
    ///   - context: SwiftData 上下文
    /// - Returns: 最小 taskSort 值，如果没有数据返回 0
    func getMinTaskSortForDate(
        todoTime: Int64,
        context: ModelContext
    ) async throws -> Decimal {
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getMinTaskSortForDateQuery(todoTime)
        var fetchDescriptor = FetchDescriptor(predicate: predicate, sortBy: sortDescriptors)
        fetchDescriptor.fetchLimit = 1
        
        let tasks = try context.fetch(fetchDescriptor)
        return tasks.first?.taskSort ?? 0
    }


    
    // MARK: - 服务器数据同步
    
    /// 同步服务器数据到本地数据库
    /// 根据 taskId 查询本地数据，比较 syncTime 决定是否更新
    /// 优化处理大量数据（可能几十万条）
    /// - Parameters:
    ///   - serverTasks: 服务器获取的任务数组（已经是 TDMacSwiftDataListModel 类型）
    ///   - context: SwiftData 上下文
    ///   - progressCallback: 进度回调（仅在首次同步且数据量>=300时调用）
    /// - Returns: 同步结果统计
    func syncServerDataToLocal(
        serverTasks: [TDMacSwiftDataListModel],
        context: ModelContext,
        progressCallback: ((Int, Int) -> Void)? = nil
    ) async throws -> SyncResult {
        
        let startTime = Date()
        var insertCount = 0
        var updateCount = 0
        var skipCount = 0
        var errorCount = 0
        
        // 检查是否需要显示进度（首次同步且数据量>=300）
        let shouldShowProgress = await shouldShowSyncProgress(context: context, totalCount: serverTasks.count)

        // 批量处理，每批处理1000条数据
        let batchSize = 1000
        let totalCount = serverTasks.count
        
        print("开始同步服务器数据，总数：\(totalCount)")
        
        // 分批处理数据
        for batchIndex in stride(from: 0, to: totalCount, by: batchSize) {
            let endIndex = min(batchIndex + batchSize, totalCount)
            let batch = Array(serverTasks[batchIndex..<endIndex])
            
            // 处理当前批次
            let batchResult = try await processServerDataBatch(
                serverTasks: batch,
                context: context
            )
            
            // 累加统计结果
            insertCount += batchResult.insertCount
            updateCount += batchResult.updateCount
            skipCount += batchResult.skipCount
            errorCount += batchResult.errorCount
            
            // 每处理完一批，保存上下文
            try context.save()
            
            // 如果需要显示进度，调用回调
            if shouldShowProgress {
                progressCallback?(insertCount + updateCount, totalCount)
            }
            
            // 打印进度
            let progress = Double(endIndex) / Double(totalCount) * 100
            print("同步进度：\(String(format: "%.1f", progress))% (\(endIndex)/\(totalCount))")
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        print("同步完成，耗时：\(String(format: "%.2f", duration))秒")
        print("统计结果：插入 \(insertCount) 条，更新 \(updateCount) 条，跳过 \(skipCount) 条，错误 \(errorCount) 条")
        
        return SyncResult(
            insertCount: insertCount,
            updateCount: updateCount,
            skipCount: skipCount,
            errorCount: errorCount,
            duration: duration
        )
    }
    
    /// 处理服务器数据批次
    /// - Parameters:
    ///   - serverTasks: 服务器任务批次（已经是 TDMacSwiftDataListModel 类型）
    ///   - context: SwiftData 上下文
    /// - Returns: 批次处理结果
    private func processServerDataBatch(
        serverTasks: [TDMacSwiftDataListModel],
        context: ModelContext
    ) async throws -> SyncResult {
        
        var insertCount = 0
        var updateCount = 0
        var skipCount = 0
        var errorCount = 0
        
        for serverTask in serverTasks {
            do {
                let result = try await processSingleServerTask(
                    serverTask: serverTask,
                    context: context
                )
                
                switch result {
                case .inserted:
                    insertCount += 1
                case .updated:
                    updateCount += 1
                case .skipped:
                    skipCount += 1
                }
                
            } catch {
                errorCount += 1
                print("处理服务器任务失败，taskId: \(serverTask.taskId), 错误: \(error)")
            }
        }
        
        return SyncResult(
            insertCount: insertCount,
            updateCount: updateCount,
            skipCount: skipCount,
            errorCount: errorCount,
            duration: 0
        )
    }

    /// 处理单个服务器任务
    /// - Parameters:
    ///   - serverTask: 服务器任务（已经是 TDMacSwiftDataListModel 类型）
    ///   - context: SwiftData 上下文
    /// - Returns: 处理结果
    private func processSingleServerTask(
        serverTask: TDMacSwiftDataListModel,
        context: ModelContext
    ) async throws -> SyncAction {
        
        // 1. 根据 taskId 查询本地数据
        let localTask = try await getLocalTaskByTaskId(taskId: serverTask.taskId, context: context)
        
        // 2. 判断处理方式
        if localTask == nil {
            // 本地没有数据，直接插入
            context.insert(serverTask)
            // 同步时顺便建立/更新标签索引（不在这里 save，由批次末尾统一 save）
            try TDTagIndexService.shared.indexTask(serverTask, context: context)

            return .inserted
            
        } else {
            // 本地有数据，比较 syncTime
            guard let localTask = localTask else {
                throw SyncError.noLocalTaskFound
            }
            
            if serverTask.syncTime > localTask.syncTime {
                // 服务器数据更新，更新本地数据
                try updateLocalTaskWithServerData(localTask: localTask, serverTask: serverTask, context: context)
                return .updated
                
            } else {
                // 本地数据更新，跳过
                return .skipped
            }
        }
    }
    
    /// 用服务器数据更新本地任务
    /// - Parameters:
    ///   - localTask: 本地任务
    ///   - serverTask: 服务器任务（已经是 TDMacSwiftDataListModel 类型）
    private func updateLocalTaskWithServerData(
        localTask: TDMacSwiftDataListModel,
        serverTask: TDMacSwiftDataListModel,
        context: ModelContext
    ) throws {
        // 更新所有服务器字段
        localTask.taskContent = serverTask.taskContent
        localTask.taskDescribe = serverTask.taskDescribe
        localTask.complete = serverTask.complete
        localTask.createTime = serverTask.createTime
        localTask.delete = serverTask.delete
        localTask.reminderTime = serverTask.reminderTime
        localTask.snowAdd = serverTask.snowAdd
        localTask.snowAssess = serverTask.snowAssess
        localTask.standbyInt1 = serverTask.standbyInt1
        localTask.standbyStr1 = serverTask.standbyStr1
        localTask.standbyStr2 = serverTask.standbyStr2
        localTask.standbyStr3 = serverTask.standbyStr3
        localTask.standbyStr4 = serverTask.standbyStr4
        localTask.syncTime = serverTask.syncTime
        localTask.taskSort = serverTask.taskSort
        localTask.todoTime = serverTask.todoTime
        localTask.userId = serverTask.userId
        localTask.version = serverTask.version
        
        // 更新本地字段（保持本地设置）
        localTask.status = "sync"
        // 注意：number 字段不更新，这是本地显示用的排列字段
        localTask.isSubOpen = serverTask.isSubOpen
        localTask.standbyIntColor = serverTask.standbyIntColor
        localTask.standbyIntName = serverTask.standbyIntName
        localTask.reminderTimeString = serverTask.reminderTimeString
        localTask.subTaskList = serverTask.subTaskList
        localTask.attachmentList = serverTask.attachmentList
        
        // 同步更新标签索引（在 save 前写入同一个 context）
        try TDTagIndexService.shared.indexTask(localTask, context: context)

        // 保存到数据库
        try context.save()

    }
    
    /// 检查是否需要显示同步进度
    /// - Parameters:
    ///   - context: SwiftData 上下文
    ///   - totalCount: 服务器数据总数
    /// - Returns: 是否需要显示进度
    private func shouldShowSyncProgress(
        context: ModelContext,
        totalCount: Int
    ) async -> Bool {
        // 条件1：数据量 >= 300
        guard totalCount >= 300 else { return false }
        
        // 条件2：当前用户没有本地数据（只检查本地数据，不依赖登录历史）
        do {
            let localMaxVersion = try await getLocalMaxVersionForLocal(context: context)
            // 如果本地最大版本号为0，说明是首次同步
            return localMaxVersion == 0

        } catch {
            print("检查本地数据失败：\(error)")
            return false
        }
    }
    
    
    // MARK: - 获取数据的方法
    
    /// 获取指定日期的任务数据数组
    /// 查询条件：userid = 本地登录用户 id，delete = false，todoTime = 传入的日期时间戳
    /// 根据设置是否显示已完成事件，不显示的话添加 complete = false 条件
    /// - Parameters:
    ///   - selectedDate: 选择的日期
    ///   - context: SwiftData 上下文
    /// - Returns: 指定日期的任务数据数组
    func getDayTasks(
        selectedDate: Date,
        context: ModelContext
    ) async throws -> [TDMacSwiftDataListModel] {
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getDayTodoQuery(selectedDate: selectedDate)
        let fetchDescriptor = FetchDescriptor(predicate: predicate, sortBy: sortDescriptors)
        
        return try context.fetch(fetchDescriptor)
    }
    
    // MARK: - 获取未同步数据并转换成 JSON
    
    /// 获取本地所有未同步数据，转换成 TDTaskModel 数组，再转成 JSON
    /// - Parameter context: SwiftData 上下文
    /// - Returns: JSON 字符串，失败返回 nil
    func getLocalUnsyncedDataAsJson(context: ModelContext) async throws -> String? {
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getLocalUnsyncedDataQuery()
        let fetchDescriptor = FetchDescriptor(predicate: predicate, sortBy: sortDescriptors)
        let unsyncedTasks = try context.fetch(fetchDescriptor)
        let taskModels = unsyncedTasks.map { TDTaskModel(from: $0) }
        let jsonString = TDSwiftJsonUtil.arrayToJson(taskModels)
        
        print("获取未同步数据成功，共 \(taskModels.count) 条，JSON 长度: \(jsonString?.count ?? 0)")
        return jsonString
    }

    
    /// 根据 taskId 查询本地数据
    /// - Parameters:
    ///   - taskId: 任务ID
    ///   - context: SwiftData 上下文
    /// - Returns: 本地任务数据，如果不存在返回 nil
    func getLocalTaskByTaskId(taskId: String, context: ModelContext) async throws -> TDMacSwiftDataListModel? {
        let (predicate, _) = TDCorrectQueryBuilder.getLocalTaskByTaskIdQuery(taskId)
        let fetchDescriptor = FetchDescriptor(predicate: predicate)
        
        // 根据 taskId 查询，理论上只会有一个结果
        let localTasks = try context.fetch(fetchDescriptor)
        
        // 返回第一个（也是唯一一个）结果，如果没有则返回 nil
        return localTasks.first
    }
    
    /// 根据重复ID查询数据
    /// - Parameters:
    ///   - standbyStr1: 重复ID
    ///   - onlyUncompleted: 是否只查询未完成的任务
    ///   - context: SwiftData 上下文
    /// - Returns: 重复事件列表
    func getDuplicateTasks(
        standbyStr1: String,
        onlyUncompleted: Bool = false,
        context: ModelContext
    ) async throws -> [TDMacSwiftDataListModel] {
        
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getDuplicateTasksQuery(
            standbyStr1: standbyStr1,
            onlyUncompleted: onlyUncompleted
        )
        
        let descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
            predicate: predicate,
            sortBy: sortDescriptors
        )
        
        return try context.fetch(descriptor)
    }

    /// 根据标签 key 查询包含该标签的事件（标签管理弹窗专用）
    /// - Parameters:
    ///   - tagKey: 例如 "#爱你"
    ///   - context: SwiftData 上下文
    /// - Returns: 当前用户下，taskContent 包含该标签的任务数组
    func getTasksByTagKey(tagKey: String, context: ModelContext) async throws -> [TDMacSwiftDataListModel] {
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getTasksByTagKeyQuery(tagKey)
        let fetchDescriptor = FetchDescriptor(predicate: predicate, sortBy: sortDescriptors)
        return try context.fetch(fetchDescriptor)
    }
    

}

// MARK: - 同步结果模型

/// 同步结果统计
struct SyncResult {
    let insertCount: Int
    let updateCount: Int
    let skipCount: Int
    let errorCount: Int
    let duration: TimeInterval
}

/// 同步操作类型
enum SyncAction {
    case inserted   // 插入新数据
    case updated    // 更新现有数据
    case skipped    // 跳过（本地数据更新）
}

/// 同步错误类型
enum SyncError: Error {
    case noLocalTaskFound
    case invalidServerData
    case contextSaveFailed
}


// MARK: - 本地数据操作

/// 本地数据操作结果
enum LocalDataAction {
    case added      // 添加成功
    case updated    // 更新成功
    case failed     // 操作失败
}

/// 本地数据操作错误
enum LocalDataError: Error {
    case taskNotFound
    case invalidData
    case contextSaveFailed
    case versionConflict
}

// MARK: - 本地数据操作方法

// MARK: - 本地数据操作方法

extension TDQueryConditionManager {
    
    /// 添加本地数据
    /// - Parameters:
    ///   - task: 要添加的任务数据
    ///   - context: SwiftData 上下文
    /// - Returns: 操作结果
    func addLocalTask(
        _ task: TDMacSwiftDataListModel,
        context: ModelContext
    ) async throws -> LocalDataAction {
        
        do {
            // 1. 获取本地最大 version 值（用于本地增删改）+1
            let maxVersion = try await getLocalMaxVersionForLocal(context: context)
            let newVersion = maxVersion + 1
            // 2. 计算智能 taskSort 值
            let calculatedTaskSort = try await calculateTaskSortForNewTask(
                todoTime: task.todoTime,
                context: context
            )

            // 3. 设置本地数据属性
            task.version = newVersion
            task.status = "add"
            task.userId = TDUserManager.shared.userId
            let currentTimestamp = Date.currentTimestamp // 使用 Date-Extension 的毫秒级时间戳
            task.createTime = currentTimestamp // 创建时间
            task.syncTime = currentTimestamp // 同步时间（新添加时与创建时间相同）
            task.taskSort = calculatedTaskSort // 设置计算出的排序值
            task.taskId = TDAppConfig.generateTaskId()  // 使用统一方法生成任务ID

            // 4. 插入到数据库
            context.insert(task)
            // 4.1 新增任务也要建立/更新标签索引（用于侧滑栏标签展示、标签管理等）
            try TDTagIndexService.shared.indexTask(task, context: context)

            // 5. 保存上下文
            try context.save()
            
            print("本地添加任务成功，taskId: \(task.taskId), version: \(newVersion)")
            return .added
            
        } catch {
            print("本地添加任务失败：\(error)")
            throw LocalDataError.contextSaveFailed
        }
    }
  
    
    /// 根据完整任务模型更新本地数据（通用方法）
    /// - Parameters:
    ///   - updatedTask: 包含更新数据的任务模型（包含 taskId）
    ///   - context: SwiftData 上下文
    /// - Returns: 操作结果
    func updateLocalTaskWithModel(
        updatedTask: TDMacSwiftDataListModel,
        context: ModelContext
    ) async throws -> LocalDataAction {

        do {
            // 1. 根据任务模型中的 taskId 查询本地数据
            guard let localTask = try await getLocalTaskByTaskId(taskId: updatedTask.taskId, context: context) else {
                throw LocalDataError.taskNotFound
            }

            // 2. 获取本地最大 version 值（用于本地增删改）+1
            let maxVersion = try await getLocalMaxVersionForLocal(context: context)
            let newVersion = maxVersion + 1
            
            // 3. 更新 version 和 status
            localTask.version = newVersion
            
            localTask.status = updatedTask.status == "delete" ? "delete" : "update"
            localTask.syncTime = Date.currentTimestamp // 更新到毫秒级别，createTime 保持不变
            
            // 4. 根据传入的模型更新所有字段
            localTask.taskContent = updatedTask.taskContent
            localTask.taskDescribe = updatedTask.taskDescribe
            localTask.todoTime = updatedTask.todoTime
            localTask.taskSort = updatedTask.taskSort
            localTask.complete = updatedTask.complete
            localTask.delete = updatedTask.delete
            localTask.standbyInt1 = updatedTask.standbyInt1
            localTask.standbyStr1 = updatedTask.standbyStr1
            localTask.standbyStr2 = updatedTask.standbyStr2
            localTask.standbyStr3 = updatedTask.standbyStr3
            localTask.standbyStr4 = updatedTask.standbyStr4
            localTask.reminderTime = updatedTask.reminderTime
            localTask.snowAdd = updatedTask.snowAdd
            localTask.snowAssess = updatedTask.snowAssess
            localTask.isSubOpen = updatedTask.isSubOpen
            localTask.standbyIntColor = updatedTask.standbyIntColor
            localTask.standbyIntName = updatedTask.standbyIntName
            localTask.reminderTimeString = updatedTask.reminderTimeString
            localTask.subTaskList = updatedTask.subTaskList
            localTask.attachmentList = updatedTask.attachmentList
            
            // 本地编辑也要同步更新标签索引
            try TDTagIndexService.shared.indexTask(localTask, context: context)

            print("本地更新任务（完整模型），taskId: \(updatedTask.taskId), version: \(newVersion)")
            
            // 5. 保存上下文
            try context.save()
            return .updated
            
        } catch {
            print("本地更新任务失败，taskId: \(updatedTask.taskId), 错误: \(error)")
            throw LocalDataError.contextSaveFailed
        }
    }
    

    
    /// 计算新任务的智能 taskSort 值
    /// - Parameters:
    ///   - todoTime: 任务的日期时间戳
    ///   - context: SwiftData 上下文
    /// - Returns: 计算出的 taskSort 值
    func calculateTaskSortForNewTask(
        todoTime: Int64,
        context: ModelContext
    ) async throws -> Decimal {
        
        // 获取设置中的添加位置偏好（暂时使用默认值，后续可以从设置中获取）
        let isAddToTop = TDSettingManager.shared.isNewTaskAddToTop

        do {
            let maxTaskSort = try await getMaxTaskSortForDate(todoTime: todoTime, context: context)
            let minTaskSort = try await getMinTaskSortForDate(todoTime: todoTime, context: context)
            if isAddToTop {
                // 添加在顶部逻辑
                if minTaskSort == 0 {
                    // 如果最小值为 0，使用默认值
                    return TDAppConfig.defaultTaskSort
                } else {
                    // 如果存在其他事件（taskSort > 0）
                    let randomValue = TDAppConfig.randomTaskSort()
                    let maxRangeValue = TDAppConfig.maxTaskSort
                    
                    if minTaskSort > maxRangeValue * 2.0 {
                        // 最小值大于区间最大值的2倍，用最小值减去随机值
                        return minTaskSort - randomValue
                    } else {
                        // 否则用最小值除以2.0
                        return minTaskSort / 2.0
                    }
                }
            } else {
                // 添加在底部逻辑
                if maxTaskSort == 0 {
                    // 如果最大值为 0，使用默认值
                    return TDAppConfig.defaultTaskSort
                } else {
                    // 如果最大值 > 0，用最大值加上随机值
                    let randomValue = TDAppConfig.randomTaskSort()
                    return maxTaskSort + randomValue
                }
            }
            
        } catch {
            print("计算 taskSort 失败：\(error)")
            // 如果计算失败，返回默认值
            return TDAppConfig.defaultTaskSort
        }
    }
        
    /// 根据服务器返回结果批量更新本地数据状态为已同步
    /// 用于服务器返回数据后，将本地数据标记为已同步
    /// - Parameters:
    ///   - results: 服务器返回的同步结果数组
    ///   - context: SwiftData 上下文
    func markTasksAsSynced(results: [TDTaskSyncResultModel], context: ModelContext) async throws {
        for result in results {
            if result.succeed {
                // 只有服务器返回成功的才更新本地状态
                do {
                    guard let localTask = try await getLocalTaskByTaskId(taskId: result.taskId, context: context) else {
                        print("未找到本地任务，taskId: \(result.taskId)")
                        continue
                    }
                    
                    localTask.status = "sync"
                    print("任务标记为已同步成功，taskId: \(result.taskId)，version = \(localTask.version)")
                    
                } catch {
                    print("更新任务状态失败，taskId: \(result.taskId), 错误: \(error)")
                }
            } else {
                // 服务器返回失败，不更新本地状态
                print("服务器同步失败，不更新本地状态，taskId: \(result.taskId)")
            }
        }
        
        // 批量保存所有更改
        try context.save()
        
        print("批量更新完成")
    }

    /// 获取去重后的重复事件入口列表（每个重复ID只保留一条）
    /// - Parameter context: SwiftData 上下文
    /// - Returns: 去重后的事件数组
    func getUniqueDuplicateEntries(
        context: ModelContext
    ) async throws -> [TDMacSwiftDataListModel] {
        // 1. 使用基础查询获取所有含重复ID的事件（未删除、按时间排序）
        let descriptor = TDCorrectQueryBuilder.getUniqueDuplicateIdsQuery()
        let tasks = try context.fetch(descriptor)
        
        // 2. 在应用层去重：同一个 standbyStr1 只保留第一条
        var visitedIds = Set<String>()
        var uniqueEntries: [TDMacSwiftDataListModel] = []
        
        for task in tasks {
            guard let repeatId = task.standbyStr1, !repeatId.isEmpty else { continue }
            if visitedIds.insert(repeatId).inserted {
                uniqueEntries.append(task)
            }
        }
        
        return uniqueEntries
    }

}


// MARK: - 附件数据查询与分组
extension TDQueryConditionManager {
    
    /// 获取包含附件的任务，并根据附件类型（图片/非图片）拆分返回
    /// - Parameters:
    ///   - filterDuplicates: 是否按 standbyStr1 去重（只保留同一重复ID的第一条）
    ///   - context: SwiftData 上下文
    /// - Returns: (图片附件任务数组, 非图片附件任务数组)
    /// - Note: 基础查询已过滤：当前用户 + 未删除 + standbyStr4 非空/非"null"，且在持久层不再判 attachmentList
    func getTasksWithAttachments(
        filterDuplicates: Bool = false,
        context: ModelContext
    ) async throws -> ([TDMacSwiftDataListModel], [TDMacSwiftDataListModel]) {
        
        // 1) 获取基础查询描述符（已保证 standbyStr4 合规）
        let fetchDescriptor = TDCorrectQueryBuilder.getTasksWithAttachmentsFetchDescriptor()
        let tasks = try context.fetch(fetchDescriptor)
        
        // 2) 如需按 standbyStr1 去重：standbyStr1 非空时只保留第一条
        var filtered = tasks
        if filterDuplicates {
            var visited = Set<String>()
            filtered = filtered.filter { task in
                if let rid = task.standbyStr1, !rid.isEmpty {
                    if visited.contains(rid) { return false }
                    visited.insert(rid)
                }
                return true
            }
        }
        
        // 3) 根据附件 isPhoto 属性拆分：含图片附件的任务、含非图片附件的任务
        var photoTasks: [TDMacSwiftDataListModel] = []
        var fileTasks: [TDMacSwiftDataListModel] = []
        
        for task in filtered {
            let attachments = task.attachmentList
            let hasPhoto = attachments.contains { $0.isPhoto }
            let hasFile = attachments.contains { !$0.isPhoto }
            
            if hasPhoto { photoTasks.append(task) }
            if hasFile { fileTasks.append(task) }
        }
        
        return (photoTasks, fileTasks)
    }
}
