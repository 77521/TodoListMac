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

    private init() {}
    
    /// 获取已同步任务的最大时间戳
    func getMaxSyncVersion() async -> Int {
        let userId = TDUserManager.shared.userId

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
    }}
