//
//  TDIAPModels.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/5/11.
//

import Foundation
import StoreKit

// MARK: - 内购产品 ID 枚举（与开发者后台保持一致）
enum TDIAPProductID: String, CaseIterable {
    /// 月度会员 12元
    case month12        = "todolist_mac_vip_month12"
    /// 季度会员 40元
    case quarter40      = "todolist_mac_vip_quarter40"
    /// 年度会员 118元
    case year118        = "todolist_mac_vip_year118"
    /// 永久会员 168元
    case forever168     = "todolist_mac_vip_forever168"
    /// 年度升级包（已是低级会员可升级）
    case yearUpdate     = "todolist_amc_vip_year_update"

    /// 所有产品 ID 字符串集合（用于向 StoreKit 请求）
    static var allIDs: Set<String> {
        Set(TDIAPProductID.allCases.map(\.rawValue))
    }
}

// MARK: - 内购错误类型
enum TDIAPError: Error, LocalizedError {
    /// 用户未登录，无法购买
    case notLoggedIn
    /// 当前设备不支持内购
    case purchaseNotAllowed
    /// 没有找到对应商品
    case productNotFound
    /// 用户取消购买
    case userCancelled
    /// 购买等待（需要家长审核等）
    case purchasePending
    /// StoreKit 返回未知状态
    case unknownPurchaseResult
    /// 服务端收据校验失败
    case verificationFailed(String)
    /// 网络错误
    case networkError(String)
    /// 恢复购买时无可恢复项目
    case nothingToRestore
    /// 其他错误
    case other(Error)

    var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "请先登录账号再购买"
        case .purchaseNotAllowed:
            return "当前设备不支持内购，请检查设置"
        case .productNotFound:
            return "未找到对应商品，请稍后重试"
        case .userCancelled:
            return "已取消购买"
        case .purchasePending:
            return "购买正在审核中，请稍后查看"
        case .unknownPurchaseResult:
            return "购买结果未知，请联系客服"
        case .verificationFailed(let msg):
            return "服务端校验失败：\(msg)"
        case .networkError(let msg):
            return "网络错误：\(msg)"
        case .nothingToRestore:
            return "未找到可恢复的购买记录"
        case .other(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - 购买流程状态
enum TDIAPPurchaseState: Equatable {
    /// 空闲（未在购买中）
    case idle
    /// 正在请求商品列表
    case loadingProducts
    /// 正在进行购买（附带产品 ID，用于在 UI 上标记哪个商品 loading）
    case purchasing(productID: String)
    /// 正在向服务端校验
    case verifying
    /// 正在恢复购买
    case restoring
    /// 购买成功
    case success
    /// 购买失败
    case failed(String)
}

// MARK: - 服务端收据校验请求体
struct TDIAPVerifyRequest: Codable {
    /// 当前登录用户 ID
    let userId: Int
    /// StoreKit 2 Transaction ID（唯一交易号）
    let transactionID: String
    /// JWS 格式的收据（Transaction.jwsRepresentation）
    let receipt: String
}

// MARK: - 服务端收据校验响应体
/// 后端返回的是通用 TDBaseResponse<TDEmptyResponse>，此处直接复用，不需要额外模型
