//
//  TDTomatoAPI.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/7/29.
//

import Foundation
import OSLog

actor TDTomatoAPI {
    static let shared = TDTomatoAPI()
    private init() {}
    
    // MARK: - 获取今日番茄数据
    func getTodayTomato() async throws -> TDTomatoModel {
        return try await TDNetworkManager.shared.request(
            endpoint: "getTodayTomato",
            responseType: TDTomatoModel.self
        )
    }
    
    // MARK: - 获取番茄钟记录列表
    func getTomatoRecord() async throws -> [TDTomatoRecordModel] {
        return try await TDNetworkManager.shared.fetchList(
            endpoint: "getTomatoRecord"
        )
    }
}

/// 番茄数据模型
struct TDTomatoModel: Codable {
    let tomatoNum: Int
    let tomatoSnowAdd: Int
} 
