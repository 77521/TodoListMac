//
//  TDIAPVerifyAPI.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/5/11.
//

import Foundation
import StoreKit

/// 内购收据服务端校验接口
actor TDIAPVerifyAPI {
    static let shared = TDIAPVerifyAPI()
    private init() {}

    // MARK: - 发送收据到服务端校验（Mac 版）
    /// - Parameters:
    ///   - transaction:      StoreKit 2 已解包的 Transaction 对象（取 transactionID）
    ///   - jwsRepresentation:VerificationResult.jwsRepresentation（苹果签名的 JWS 原文）
    ///   - userId:           当前登录用户 ID
    @MainActor
    func verifyTransaction(
        _ transaction: Transaction,
        jwsRepresentation: String,
        userId: Int
    ) async throws {
        // 1. 构造请求参数
        //    receipt 使用 JWS 原文，服务端可直接用苹果公钥验签，无需额外 Base64 处理
        let params: TDNetworkManager.Parameters = [
            "transactionID": String(transaction.id),
            "receipt":       jwsRepresentation,
        ]

        // 3. 请求后端校验接口（Mac 版端点为 macPay）
        _ = try await TDNetworkManager.shared.request(
            endpoint: "macPay",
            parameters: params,
            responseType: TDEmptyResponse.self
        )
        // 若 ret==false，TDNetworkManager 会自动抛出 TDNetworkError，由上层处理
    }
}
