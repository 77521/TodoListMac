//
//  TDCountdownAPI.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/7/29.
//

import Foundation
import OSLog


actor TDCountdownAPI {
    static let shared = TDCountdownAPI()
    private init() {}
    
    // MARK: - 获取倒计时列表
    func getCountdownDayList() async throws -> [TDCountdownModel] {
        return try await TDNetworkManager.shared.fetchList(
            endpoint: "getCountdownDayList"
        )
    }
    
    
}

/// 倒计时数据模型
struct TDCountdownModel: Codable {
    /// 用户ID
    let userId: Int
    /// 倒计时ID
    let id: Int
    /// 名称
    let countdownName: String
    /// 清单颜色值背景颜色
    let countdownColor: String?
    /// 背景图片
    let countdownPicUrl: String
    /// 计数文字颜色
    let fontColor: String
    /// 目标日期时间戳
    let aimDay: Int64
    /// 是否为每年重复
    let yearRepeat: Bool
    /// 排序，从小到大，从100开始，每次增加100
    let listSort: Decimal
    /// 背景样式 样式类型，0：颜色，1：图片
    let styleType: Int
    /// 选择事件关联的ID
    let linkTaskId: String
    /// 选择事件关联的标题
    let taskCount: String?
    /// 重复是否为阳历 默认阳历
    let repeatSolar: Bool
    /// 创建时间
    let createTime: Int64
}

