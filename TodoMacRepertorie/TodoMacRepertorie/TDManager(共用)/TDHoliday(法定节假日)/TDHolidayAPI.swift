//
//  TDHolidayAPI.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/21.
//

import Foundation
import OSLog

actor TDHolidayAPI {
    static let shared = TDHolidayAPI()
    private init() {}
    
    // MARK: - 获取节假日列表
    func getHolidayList() async throws -> [TDHolidayItem] {
        return try await TDNetworkManager.shared.fetchList(
            endpoint: "getHolidayList"
        )
    }
}

// MARK: - 数据模型

/// 节假日项目
struct TDHolidayItem: Codable {
    let date: Int64        // 时间戳（毫秒）
    let holiday: Bool      // true=法定节假日, false=调休工作日
    let name: String       // 节假日名称
    
    /// 转换为Date对象
    var dateValue: Date {
        return Date.fromTimestamp(date)
    }
}
