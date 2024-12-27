//
//  TDTaskAPI.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/27.
//

import Foundation
import HandyJSON


/// 任务相关的网络请求
class TDTaskAPI {
    /// 是否首次安装 app 是的话 获取数据的时候 为 Yes 否则的话 为 NO
//    @AppStorage("InitialInstallation") var isFirst: Bool = true

    /// 获取服务器最大版本号
    static func fetchServerMaxVersion() async throws -> Int64 {
        return try await withCheckedThrowingContinuation { continuation in
            TDNetworkManager.shared.request("getCurrentVersion") { (result: Result<TDGetCurrentVersionModel?, TDNetworkManager.TDNetworkError>) in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response?.maxVersion ?? 0)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 双向同步任务（上传本地修改并获取服务器更新）
    static func syncTasks(tasks: [TDMacHandyJsonListModel]) async throws -> [TDMacHandyJsonListModel] {
        let jsonArray = tasks.toJSONString() ?? "[]"
        return try await withCheckedThrowingContinuation { continuation in
            TDNetworkManager.shared.requestList("syncPushData", parameters: ["tasksJson": jsonArray]) { (result: Result<[TDMacHandyJsonListModel], TDNetworkManager.TDNetworkError>) in
                switch result {
                case .success(let tasks):
                    continuation.resume(returning: tasks)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 获取任务列表
    static func getTasks(isFirst: Bool = false) async throws -> [TDMacHandyJsonListModel] {
        return try await withCheckedThrowingContinuation { continuation in
            let parameters = ["isFirst": isFirst]
            TDNetworkManager.shared.requestList("syncGetData", parameters: parameters) { (result: Result<[TDMacHandyJsonListModel], TDNetworkManager.TDNetworkError>) in
                switch result {
                case .success(let tasks):
                    continuation.resume(returning: tasks)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    
    
    /// 删除任务
//    static func deleteTask(taskId: String) async throws -> Bool {
//        return try await withCheckedThrowingContinuation { continuation in
//            TDNetworkManager.shared.request("/tasks/\(taskId)", method: .delete) { (result: Result<TDEmptyResponse?, TDNetworkManager.TDNetworkError>) in
//                switch result {
//                case .success(_):
//                    continuation.resume(returning: true)
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
}

