//
//  TDTaskAPI.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation


@MainActor
final class TDTaskAPI {
    /// 单例
    static let shared = TDTaskAPI()
    
    private init() {}
    
    /// 获取服务器当前最大版本号
    func getCurrentVersion() async throws -> Int {
        
        // 发起请求
        let response = try await TDNetworkManager.shared.request(
            endpoint: "getCurrentVersion",
            responseType: TDGetCurrentVersionModel.self
        )
        return response.maxVersion
    }
    
    /// 从服务器获取任务列表
    /// - Parameter version: 本地最大版本号
    /// - Returns: 任务列表
    func getTaskList(version: Int) async throws -> [TDMacSwiftDataListModel] {
        // 构建请求参数
        // 获取当前用户 ID
        let userId = TDUserManager.shared.userId
        // 检查是否首次同步
        let isFirst = TDUserSyncManager.shared.isFirstSync(userId: userId)
        let parameters: [String: Any] = [
            "syncNum": version,
            "isFirst": isFirst
        ]
        
        // 获取任务列表
        let taskList: [TDTaskModel] = try await TDNetworkManager.shared.fetchList(
            endpoint: "syncGetData",
            parameters: parameters
        )
        
//        // 转换为 SwiftData 模型
//        var swiftDataModels: [TDMacSwiftDataListModel] = []
//        for task in taskList {
//            let model = await task.toSwiftDataModel()
//            swiftDataModels.append(model)
//        }
        // 如果不是首次同步，标记为已完成首次同步
        if isFirst {
            TDUserSyncManager.shared.markSyncCompleted(userId: userId)
        }
        
        print("开始处理 \(taskList.count) 条数据...")
        
        // 分批处理数据，每批 100 条
        let batchSize = 100
        var result: [TDMacSwiftDataListModel] = []
        
        for i in stride(from: 0, to: taskList.count, by: batchSize) {
            let end = min(i + batchSize, taskList.count)
            let batch = taskList[i..<end]
            
            // 处理这一批数据
            let models = batch.compactMap { task -> TDMacSwiftDataListModel? in
                var processedTask = task
                
                // 处理所有数据
                processedTask.processAllData()
                
                // 转换为 SwiftData 模型
                return processedTask.toSwiftDataModel()
            }
            
            result.append(contentsOf: models)
            print("已处理 \(end)/\(taskList.count) 条数据")
            
            // 每处理一批数据后暂停一下，避免过度占用 CPU
            try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        }
        
        
        return result

    }
    
    
    /// 同步本地数据到服务器
    /// - Parameter tasksJson: 本地数组转 json数据
    /// - Returns: 返回的数据
    func syncPushData(tasksJson: String) async throws -> [TDTaskSyncResultModel] {
        let parameters: [String: Any] = ["tasksJson": tasksJson]
        let result: [TDTaskSyncResultModel] = try await TDNetworkManager.shared.fetchList(
            endpoint: "syncPushData",
            parameters: parameters
        )
        return result
    }

}


///// 任务相关的网络请求
//class TDTaskAPI {
//    /// 是否首次安装 app 是的话 获取数据的时候 为 Yes 否则的话 为 NO
////    @AppStorage("InitialInstallation") var isFirst: Bool = true
//
//    /// 获取服务器最大版本号
//    static func fetchServerMaxVersion() async throws -> Int64 {
//        return try await withCheckedThrowingContinuation { continuation in
//            TDNetworkManager.shared.request("getCurrentVersion") { (result: Result<TDGetCurrentVersionModel?, TDNetworkManager.TDNetworkError>) in
//                switch result {
//                case .success(let response):
//                    if let maxVersion = response?.maxVersion {
//                        continuation.resume(returning: maxVersion)
//                    } else {
//                        continuation.resume(returning: 0)
//                    }
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
//    
//    /// 双向同步任务（上传本地修改并获取服务器更新）
//    static func syncTasks(tasks: [TDMacHandyJsonListModel]) async throws -> [TDMacHandyJsonListModel] {
//        let jsonArray = tasks.toJSONString() ?? "[]"
//        return try await withCheckedThrowingContinuation { continuation in
//            TDNetworkManager.shared.requestList("syncPushData", parameters: ["tasksJson": jsonArray]) { (result: Result<[TDMacHandyJsonListModel], TDNetworkManager.TDNetworkError>) in
//                switch result {
//                case .success(let tasks):
//                    continuation.resume(returning: tasks)
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
//    
//    /// 获取任务列表
//    static func getTasks(isFirst: Bool = false, syncNum:Int) async throws -> [TDMacHandyJsonListModel] {
//        return try await withCheckedThrowingContinuation { continuation in
//            let parameters = ["isFirst": isFirst, "syncNum" : syncNum]
//
//            TDNetworkManager.shared.requestList("syncGetData", parameters: parameters) { (result: Result<[TDMacHandyJsonListModel], TDNetworkManager.TDNetworkError>) in
//                switch result {
//                case .success(let tasks):
//                    continuation.resume(returning: tasks)
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
//
//    
//    
//    /// 删除任务
////    static func deleteTask(taskId: String) async throws -> Bool {
////        return try await withCheckedThrowingContinuation { continuation in
////            TDNetworkManager.shared.request("/tasks/\(taskId)", method: .delete) { (result: Result<TDEmptyResponse?, TDNetworkManager.TDNetworkError>) in
////                switch result {
////                case .success(_):
////                    continuation.resume(returning: true)
////                case .failure(let error):
////                    continuation.resume(throwing: error)
////                }
////            }
////        }
////    }
//}
//
