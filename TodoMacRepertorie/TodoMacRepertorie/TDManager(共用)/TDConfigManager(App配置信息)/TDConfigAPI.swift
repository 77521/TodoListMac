//
//  TDConfigAPI.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/7/29.
//

import Foundation
import OSLog

actor TDConfigAPI {
    static let shared = TDConfigAPI()
    private init() {}
    
    // MARK: - 获取应用配置
    func getConfig() async throws -> TDConfigModel {
        return try await TDNetworkManager.shared.request(
            endpoint: "getConfig",
            responseType: TDConfigModel.self
        )
    }
}

/// 应用配置数据模型
struct TDConfigModel: Codable {
    let activity101OImageUrl1: String?
    let activity101OImageUrl2: String?
    let activity101OImageUrl3: String?
    let activity101OImageUrl4: String?
    let activity101OText: String?
    let activity101Open: Bool
    let activityGiftOpen: Bool
    let androidBackGuideUrl: String?
    let appleIdForever: String?
    let appleIdMonth: String?
    let appleIdQuarter: String?
    let appleIdYear: String?
    let applePriceForever: Int
    let applePriceMonth: Int
    let applePriceQuarter: Int
    let applePriceYear: Int
    let downloadUrl: String?
    let fileFunctionOpen: Bool
    let fileFunctionTestUerId: String?
    let giftSubTitle: String?
    let giftTitle: String?
    let id: Int
    let iosCheckMode: Bool
    let kup: Int
    let lotteryGiftRule: String?
    let lotteryGiftTitle: String?
    let maxSnowGetFromTask: Int
    let maxSnowGetFromTomato: Int
    let mediaOpen: Bool
    let mp4Url: String?
    let priceForever: Int
    let priceForeverSubText1: String?
    let priceForeverSubText2: String?
    let priceMonth: Int
    let priceQuarter: Int
    let priceQuarterSubText1: String?
    let priceQuarterSubText2: String?
    let priceYear: Int
    let priceYearSubText1: String?
    let priceYearSubText2: String?
    let questionnaireOpen: Bool
    let questionnaireUrl: String?
    let speechLimitDay: Int
    let speechLimitTotal: Int
    let tomatoVideoUrl: String?
    let versionCode: Int
    let versionName: String?
    let versionText: String?
    let vipSaleEndTime: Int64
}
