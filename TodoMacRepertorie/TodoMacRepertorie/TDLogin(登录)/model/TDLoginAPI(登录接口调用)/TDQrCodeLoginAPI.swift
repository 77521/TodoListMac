//
//  TDQrCodeLoginAPI.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//
//  ⚠️ 注意：此文件仅属于主应用 Target（TodoMacRepertorie），
//  请勿添加至小组件 Extension Target，以避免编译错误。

import Foundation

// MARK: - TDLoginAPI 扫码登录扩展

extension TDLoginAPI {

    // MARK: - 获取扫一扫登录二维码

    /// 请求获取用于扫码登录的二维码
    /// - 切换到扫一扫 Tab 时调用
    /// - codeType 桌面端固定传 3
    /// - deviceType 与其他登录接口保持一致，传 "mac"
    /// - Returns: 包含 id 和 qrCode 代码串的二维码数据模型
    func getTodoQrCode() async throws -> TDQrCodeModel {
        let parameters: [String: Any] = [
            "codeType": 3,
            "deviceType": "mac"
        ]
        return try await TDNetworkManager.shared.request(
            endpoint: "getTodoQrCode",
            parameters: parameters,
            responseType: TDQrCodeModel.self
        )
    }

    // MARK: - 查询二维码验证结果

    /// 轮询查询二维码验证结果
    /// - 获取到二维码后，每隔5秒（上次请求返回后）调用一次
    /// - Parameter qrCodeId: 获取二维码接口返回的 id
    /// - Parameter qrCodeStr: 获取二维码接口返回的 qrCode 代码串
    /// - Returns: 包含验证结果（qrVerify）和登录用户（okUser）的数据模型
    func getQrVerifyResult(qrCodeId: Int, qrCodeStr: String) async throws -> TDQrCodeModel {
        let parameters: [String: Any] = [
            "qrCodeId": qrCodeId,
            "qrCodeStr": qrCodeStr
        ]
        return try await TDNetworkManager.shared.request(
            endpoint: "getQrVerifyResult",
            parameters: parameters,
            responseType: TDQrCodeModel.self
        )
    }
}
