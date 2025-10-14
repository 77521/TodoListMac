//
//  TDDataReviewAPI.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/14.
//

import Foundation

/// 数据复盘 API 管理器
class TDDataReviewAPI {
    static let shared = TDDataReviewAPI()
    
    private init() {}
    
    // MARK: - 昨日小结接口
    /// 获取昨日小结数据
    /// - Returns: 昨日小结数据列表
    func getReportYesterdaySummary() async throws -> [TDDataReviewModel] {
        let parameters: [String: Any] = [
            "showTomato": TDSettingManager.shared.showFocusFeature
        ]
        
        return try await TDNetworkManager.shared.fetchList(
            endpoint: "getReportYesterdaySummary",
            parameters: parameters
        )
    }
    
    // MARK: - 事件统计接口
    /// 获取事件统计数据
    /// - Parameters:
    ///   - startTime: 开始时间戳
    ///   - endTime: 结束时间戳
    /// - Returns: 事件统计数据列表
    func getReportTask(startTime: Int64, endTime: Int64) async throws -> [TDDataReviewModel] {
        let parameters: [String: Any] = [
            "startTime": startTime,
            "endTime": endTime
        ]
        
        return try await TDNetworkManager.shared.fetchList(
            endpoint: "getReportTask",
            parameters: parameters
        )
    }
    
    // MARK: - 番茄统计接口
    /// 获取番茄统计数据
    /// - Parameters:
    ///   - startTime: 开始时间戳
    ///   - endTime: 结束时间戳
    /// - Returns: 番茄统计数据列表
    func getReportTomato(startTime: Int64, endTime: Int64) async throws -> [TDDataReviewModel] {
        let parameters: [String: Any] = [
            "startTime": startTime,
            "endTime": endTime,
            "showTomato": TDSettingManager.shared.showFocusFeature
        ]
        
        return try await TDNetworkManager.shared.fetchList(
            endpoint: "getReportTomato",
            parameters: parameters
        )
    }
    
    // MARK: - 周报接口
    /// 获取周报数据
    /// - Parameters:
    ///   - diyEndTime: 自定义结束时间戳
    ///   - weekStartSun: 是否从周日开始（true: 周日开始，false: 周一开始）
    /// - Returns: 周报数据列表
    func getReportWeek(diyEndTime: Int64, weekStartSun: Bool) async throws -> [TDDataReviewModel] {
        let parameters: [String: Any] = [
            "showTomato": TDSettingManager.shared.showFocusFeature,
            "diyEndTime": diyEndTime,
            "weekStartSun": weekStartSun
        ]
        
        return try await TDNetworkManager.shared.fetchList(
            endpoint: "getReportWeek",
            parameters: parameters
        )
    }
}
