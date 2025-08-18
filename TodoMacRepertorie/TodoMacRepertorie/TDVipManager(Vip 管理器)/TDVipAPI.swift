//
//  TDVipAPI.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/7/29.
//

import Foundation
import OSLog

actor TDVipAPI {
    static let shared = TDVipAPI()
    private init() {}
    
    // MARK: - 获取VIP商品窗口数据
    func getVipGoodsWindow() async throws -> TDVipModel {
        return try await TDNetworkManager.shared.request(
            endpoint: "getVipGoodsWindow",
            responseType: TDVipModel.self
        )
    }
}

/// VIP数据模型
struct TDVipModel: Codable {
    let goodsList: [TDVipGoodsModel]
    let vipDeadTimeStr: String
    let vipMineSubTitle: String
    let vipMineTitle: String
}

/// VIP商品模型
struct TDVipGoodsModel: Codable {
    let appleId: String
    let coinSign: String
    let giftPicUrl: String?
    let giftPriceStr: String?
    let giftSubStr: String?
    let giftTitle: String?
    let goodsName: String
    let goodsType: Int
    let marketingBanner: String?
    let marketingStr: String?
    let marketingTip: String?
    let originalPrice: Int
    let price: Int
    let rechargeTypeId: Int
    let ticketEndTime: Int
    let ticketName: String?
    let ticketStr: String?
    let vipButtonTip: String?
} 
