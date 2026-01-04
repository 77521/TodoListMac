//
//  TDSettingAPI.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/12/18.
//

import Foundation

actor TDSettingAPI {
    static let shared = TDSettingAPI()
    private init() {}
    
    /// 修改用户信息（昵称/头像/性别）
    /// - Parameters:
    ///   - nickname: 昵称
    ///   - head: 头像 URL，为空则传 "null"
    ///   - sex: 性别，约定 1 男 / 0 女
    @discardableResult
    func editUser(nickname: String, head: String?, sex: Int) async throws -> TDEmptyResponse {
        
        // 头像为空或空串时按需求传 "null"
        let normalizedHead: String = {
            let trimmed = head?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? "null" : trimmed
        }()

        
        let params: [String: Any] = [
            "userName": nickname,
            "userHead": normalizedHead,
            "sex": sex
        ]
        
        return try await TDNetworkManager.shared.request(
            endpoint: "editUser",
            parameters: params,
            responseType: TDEmptyResponse.self
        )
    }
    
    
    /// 退出登录
    @discardableResult
    func logout() async throws -> TDEmptyResponse {
        return try await TDNetworkManager.shared.request(
            endpoint: "loginOut",
            responseType: TDEmptyResponse.self
        )
    }
    
    /// 注销账号
    /// - Parameters:
    ///   - phoneNumber: 手机号（有值则传）
    ///   - code: 验证码（有值则传）
    ///   - nowPassword: 当前密码（有值则传）
    @discardableResult
    func deleteAccount(phoneNumber: Int?, code: String?, nowPassword: String?) async throws -> TDEmptyResponse {
        var params: [String: Any] = [:]
        if let phone = phoneNumber, phone > 0 {
            params["phoneNumber"] = phone
        }
        if let code, !code.isEmpty {
            params["code"] = code
        }
        if let nowPassword, !nowPassword.isEmpty {
            params["nowPassword"] = nowPassword
        }
        
        return try await TDNetworkManager.shared.request(
            endpoint: "deleteAccount",
            parameters: params,
            responseType: TDEmptyResponse.self
        )
    }

    
    /// 获取绑定/更换手机号验证码
    @discardableResult
    func getSmsCodeByBind(phoneNumber: String) async throws -> TDEmptyResponse {
        let params: [String: Any] = ["phoneNumber": phoneNumber]
        return try await TDNetworkManager.shared.request(
            endpoint: "getSmsCodeByBind",
            parameters: params,
            responseType: TDEmptyResponse.self
        )
    }
    
    /// 绑定/更换手机号
    /// - Returns: 通用空响应；如需读取业务 code 请在调用端解析 TDNetworkManager 的错误/响应结构
    @discardableResult
    func bindPhoneNumber(phoneNumber: String, code: Int) async throws -> TDEmptyResponse {
        let params: [String: Any] = [
            "phoneNumber": phoneNumber,
            "code": code
        ]
        return try await TDNetworkManager.shared.request(
            endpoint: "bindPhoneNumber",
            parameters: params,
            responseType: TDEmptyResponse.self
        )
    }

    /// 强制绑定/更换手机号
    @discardableResult
    func bindPhoneNumberForce(phoneNumber: String, code: Int) async throws -> TDEmptyResponse {
        let params: [String: Any] = [
            "phoneNumber": phoneNumber,
            "code": code
        ]
        return try await TDNetworkManager.shared.request(
            endpoint: "bindPhoneNumberForce",
            parameters: params,
            responseType: TDEmptyResponse.self
        )
    }
    
    // MARK: - 账号更改相关
    
    /// 获取更改账号的短信验证码（使用当前手机号）
    @discardableResult
    func sendSmsCodeByChangeAccount(phoneNumber: Int) async throws -> TDEmptyResponse {
        let params: [String: Any] = [
            "phoneNumber": phoneNumber
        ]
        return try await TDNetworkManager.shared.request(
            endpoint: "sendSmsCodeByChangeAccount",
            parameters: params,
            responseType: TDEmptyResponse.self
        )
    }
    
    /// 获取老邮箱验证码（更改账号）
    @discardableResult
    func sendOldEmailCodeByChangeAccount() async throws -> TDEmptyResponse {
        let params: [String: Any] = [
            "deviceType": String.currentDeviceIdentifier()
        ]
        return try await TDNetworkManager.shared.request(
            endpoint: "sendOldEmailCodeByChangeAccount",
            parameters: params,
            responseType: TDEmptyResponse.self
        )
    }
    
    /// 获取新邮箱验证码（更改账号）
    @discardableResult
    func sendNewEmailCodeByChangeAccount(newAccount: String) async throws -> TDEmptyResponse {
        let params: [String: Any] = [
            "deviceType": String.currentDeviceIdentifier(),
            "newAccount": newAccount
        ]
        return try await TDNetworkManager.shared.request(
            endpoint: "sendNewEmailCodeByChangeAccount",
            parameters: params,
            responseType: TDEmptyResponse.self
        )
    }
    
    /// 确认更改账号
    @discardableResult
    func changeAccount(password: String,
                       newAccount: String,
                       newEmailCode: Int,
                       smsCode: Int?,
                       oldEmailCode: Int?) async throws -> TDEmptyResponse {
        var params: [String: Any] = [
            "password": password,
            "newAccount": newAccount,
            "newEmailCode": newEmailCode
        ]
        if let smsCode {
            params["smsCode"] = smsCode
        }
        if let oldEmailCode {
            params["oldEmailCode"] = oldEmailCode
        }
        return try await TDNetworkManager.shared.request(
            endpoint: "changeAccount",
            parameters: params,
            responseType: TDEmptyResponse.self
        )
    }
    
    /// 绑定/设置账号密码
    @discardableResult
    func configAccount(setAccount: String, setPassword: String) async throws -> TDEmptyResponse {
        let params: [String: Any] = [
            "setAccount": setAccount,
            "setPassword": setPassword
        ]
        return try await TDNetworkManager.shared.request(
            endpoint: "configAccount",
            parameters: params,
            responseType: TDEmptyResponse.self
        )
    }

    // MARK: - 修改密码
    /// 通过旧密码修改密码
    @discardableResult
    func changePassword(oldPassword: String, newPassword: String) async throws -> TDEmptyResponse {
        let params: [String: Any] = [
            "oldPassword": oldPassword,
            "newPassword": newPassword
        ]
        return try await TDNetworkManager.shared.request(
            endpoint: "changePassword",
            parameters: params,
            responseType: TDEmptyResponse.self
        )
    }
    
    /// 通过手机号验证码修改密码
    @discardableResult
    func changePasswordByPhone(code: String, newPassword: String) async throws -> TDEmptyResponse {
        let params: [String: Any] = [
            "code": code,
            "newPassword": newPassword
        ]
        return try await TDNetworkManager.shared.request(
            endpoint: "changePasswordByPhone",
            parameters: params,
            responseType: TDEmptyResponse.self
        )
    }
    
    /// 通过邮箱验证码修改密码
    @discardableResult
    func changePasswordByEmail(code: String, newPassword: String) async throws -> TDEmptyResponse {
        let params: [String: Any] = [
            "code": code,
            "newPassword": newPassword
        ]
        return try await TDNetworkManager.shared.request(
            endpoint: "changePasswordByEmail",
            parameters: params,
            responseType: TDEmptyResponse.self
        )
    }

}
