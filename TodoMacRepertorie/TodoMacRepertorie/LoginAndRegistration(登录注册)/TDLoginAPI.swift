//
//  TDLoginAPI.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/6.
//

import Foundation
import HandyJSON
import Alamofire

class TDLoginAPI {
    
    static let shared = TDLoginAPI()
    private let network = TDNetworkManager.shared
        
    enum TDLoginType: String {
        case account = "account"
        case phone = "phone"
        case qrcode = "qrcode"
    }
    
    enum TDLoginError: Error {
        case invalidParams
        case invalidResponse
        case networkError(String)
    }
    
    // MARK: - 账号登录相关
    
    // 账号密码登录（async）
    static func login(account: String, password: String, url: String) async throws -> TDUserModel {
        return try await withCheckedThrowingContinuation { continuation in
            let parameters: [String: Any] = [
                "userAccount": account,
                "userPassword": password
            ]
            
            TDNetworkManager.shared.request(url, parameters: parameters) { (result: Result<TDUserModel?, TDNetworkManager.TDNetworkError>) in
                switch result {
                case .success(let response):
                    if let userModel = response {
                        continuation.resume(returning: userModel)
                    } else {
                        continuation.resume(throwing: TDNetworkManager.TDNetworkError.emptyData)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    // 手机号登录（async）
    static func login(phone: String, smsCode: String) async throws -> TDUserModel {
        return try await withCheckedThrowingContinuation { continuation in
            let parameters: [String: Any] = [
                "phoneNumber": phone,
                "code": smsCode
            ]
            
            TDNetworkManager.shared.request("login", parameters: parameters) { (result: Result<TDUserModel?, TDNetworkManager.TDNetworkError>) in
                switch result {
                case .success(let response):
                    if let userModel = response {
                        continuation.resume(returning: userModel)
                    } else {
                        continuation.resume(throwing: TDNetworkManager.TDNetworkError.emptyData)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - 短信验证码
    static func sendSmsCode(to phone: String, url: String) async throws -> (Bool, String) {
        return try await withCheckedThrowingContinuation { continuation in
            TDNetworkManager.shared.request(url,
                                            parameters: ["phoneNumber": phone]) { (result: Result<TDEmptyResponse?, TDNetworkManager.TDNetworkError>) in
                switch result {
                case .success:
                    // 发送成功
                    continuation.resume(returning: (true, "验证码发送成功"))
                case .failure(let error):
                    switch error {
                    case .unregistered:
                        // 未注册用户也算发送成功
                        continuation.resume(returning: (true, "验证码发送成功"))
                    case .server(let message):
                        continuation.resume(returning: (false, message))
                    default:
                        continuation.resume(returning: (false, error.localizedDescription))
                    }
                }
            }
        }
    }
    
    // MARK: - 扫码登录
    
    // 获取二维码
    static func getQRCode() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            TDNetworkManager.shared.request("qrcode/get",
                                            parameters: nil) { (result: Result<TDBaseResponse<TDQRCodeResponse>?, TDNetworkManager.TDNetworkError>) in
                switch result {
                case .success(let response):
                    if let qrCode = response?.data?.qrCode {
                        continuation.resume(returning: qrCode)
                    } else {
                        continuation.resume(throwing: TDNetworkManager.TDNetworkError.server("获取二维码失败"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // 轮询二维码状态
    static func checkQRCodeStatus(qrCode: String) async throws -> TDQRCodeStatus {
        return try await withCheckedThrowingContinuation { continuation in
            TDNetworkManager.shared.request("qrcode/check",
                                            parameters: ["qrCode": qrCode]) { (result: Result<TDBaseResponse<TDQRCodeStatusResponse>?, TDNetworkManager.TDNetworkError>) in
                switch result {
                case .success(let response):
                    if let status = response?.data?.status {
                        continuation.resume(returning: TDQRCodeStatus(rawValue: status) ?? .invalid)
                    } else {
                        continuation.resume(throwing: TDNetworkManager.TDNetworkError.server("获取状态失败"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // 确认登录
    static func confirmQRCodeLogin(qrCode: String) async throws -> TDUserModel {
        return try await withCheckedThrowingContinuation { continuation in
            TDNetworkManager.shared.request("qrcode/confirm",
                                            parameters: ["qrCode": qrCode]) { (result: Result<TDBaseResponse<TDUserModel>?, TDNetworkManager.TDNetworkError>) in
                switch result {
                case .success(let response):
                    if let user = response?.data {
                        continuation.resume(returning: user)
                    } else {
                        continuation.resume(throwing: TDNetworkManager.TDNetworkError.server("登录失败"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 退出登录
    static func logout() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            TDNetworkManager.shared.request(
                "user/logout",
                method: .post
            ) { (result: Result<TDEmptyResponse?, TDNetworkManager.TDNetworkError>) in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Response Models
struct TDSmsResponse: HandyJSON {
    var success: Bool = false
    var expireTime: Int = 0  // 验证码有效期（秒）
}

// 二维码相关模型
struct TDQRCodeResponse: HandyJSON {
    var qrCode: String?
    var expireTime: Int?
    
    init() {}
}

struct TDQRCodeStatusResponse: HandyJSON {
    var status: Int?
    var token: String?
    
    init() {}
}

enum TDQRCodeStatus: Int {
    case invalid = -1      // 无效或过期
    case waiting = 0       // 等待扫码
    case scanned = 1       // 已扫码
    case confirmed = 2     // 已确认
    case cancelled = 3     // 已取消
    
    var description: String {
        switch self {
        case .invalid: return "二维码已失效"
        case .waiting: return "等待扫码"
        case .scanned: return "已扫码"
        case .confirmed: return "已确认登录"
        case .cancelled: return "已取消"
        }
    }
}
