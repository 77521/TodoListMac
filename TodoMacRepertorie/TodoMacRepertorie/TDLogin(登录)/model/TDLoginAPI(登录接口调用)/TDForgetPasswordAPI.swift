//
//  TDForgetPasswordAPI.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2026/7/1.
//  仅主 App Target 使用，不参与 Widget 共享

import Foundation

// MARK: - 找回密码信息返回模型
/// 服务端返回的账号找回密码信息（脱敏手机号 / 邮箱）
struct TDForgetPasswordInfoModel: Codable {
    /// 脱敏手机号，如 "181****5257"；未绑定时为 nil 或空字符串
    var phoneNumber: String?
    /// 邮箱账号；账号本身不是邮箱格式时为 nil 或空字符串
    var userAccount: String?
}

// MARK: - 找回密码相关接口（扩展 TDLoginAPI）
extension TDLoginAPI {

    // MARK: - 查询账号是否存在及绑定的找回密码方式
    /// 接口：todoList/queryAccountExist
    /// 传入登录账号，返回脱敏手机号（"0" 表示未绑定）和邮箱（账号本身是邮箱时有值）
    /// - Parameter account: 用户在登录框中输入的账号（邮箱或普通账号）
    func queryAccountExist(account: String) async throws -> TDForgetPasswordInfoModel {
        let parameters: [String: Any] = [
            "userAccount": account
        ]
        return try await TDNetworkManager.shared.request(
            endpoint: "queryAccountExist",
            parameters: parameters,
            responseType: TDForgetPasswordInfoModel.self
        )
    }

    // MARK: - 获取手机短信验证码（找回密码）
    /// 接口：getSmsCodeByForget
    /// - Parameter phone: 手机号（11位）
    func getForgetPasswordSmsCode(phone: String) async throws {
        let parameters: [String: Any] = [
            "phoneNumber": phone
        ]
        _ = try await TDNetworkManager.shared.request(
            endpoint: "getSmsCodeByForget",
            parameters: parameters,
            responseType: TDEmptyResponse.self
        )
    }

    // MARK: - 获取邮箱验证码（找回密码）
    /// 接口：sendMailCodeByForgetPassword
    /// - Parameter email: 邮箱账号
    func getForgetPasswordEmailCode(email: String) async throws {
        let parameters: [String: Any] = [
            "userAccount": email
        ]
        _ = try await TDNetworkManager.shared.request(
            endpoint: "sendMailCodeByForgetPassword",
            parameters: parameters,
            responseType: TDEmptyResponse.self
        )
    }

    // MARK: - 通过手机号设置新密码
    /// 手机验证码找回密码
    /// - Parameters:
    ///   - phone: 手机号（11位）
    ///   - code: 短信验证码
    ///   - newPassword: 新密码
    func resetPasswordByPhone(phone: String, code: String, newPassword: String) async throws {
        let parameters: [String: Any] = [
            "phoneNumber": phone,
            "code": code,
            "newPassword": newPassword
        ]
        _ = try await TDNetworkManager.shared.request(
            endpoint: "setForgetPassword",
            parameters: parameters,
            responseType: TDEmptyResponse.self
        )
    }

    // MARK: - 通过邮箱设置新密码
    /// 邮箱验证码找回密码
    /// - Parameters:
    ///   - email: 邮箱账号
    ///   - code: 邮箱验证码
    ///   - newPassword: 新密码
    func resetPasswordByEmail(email: String, code: String, newPassword: String) async throws {
        let parameters: [String: Any] = [
            "userAccount": email,
            "code": code,
            "newPassword": newPassword
        ]
        _ = try await TDNetworkManager.shared.request(
            endpoint: "setForgetPasswordByEmail",
            parameters: parameters,
            responseType: TDEmptyResponse.self
        )
    }
}
