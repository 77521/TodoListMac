//
//  TDNetworkModels.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/8.
//

import Foundation

// MARK: - 网络请求错误枚举
enum TDNetworkError: Error {
    case invalidURL
    case requestFailed(String)
    case decodingError(String)
    case tokenExpired
    case needRegister
    case notVIPMember
    case wechatBound
    case needBindWeChatOrQQ
    case needForceBindPhone   // 手机号被其他账号绑定，需强制绑定确认
    case needBindPhone
    case needVIP
    case emptyData
    case networkTimeout
    
    var errorMessage: String {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .requestFailed(let message):
            return message
        case .decodingError(let message):
            return "数据解析错误: \(message)"
        case .tokenExpired:
            return "登录已过期"
        case .needRegister:
            return "账号未注册"
        case .notVIPMember:
            return "需要会员权限"
        case .wechatBound:
            return "微信号已被绑定"
        case .needBindWeChatOrQQ:
            return "需要绑定微信或QQ"
        case .needForceBindPhone:
            return "手机号已被绑定"
        case .needBindPhone:
            return "需要绑定手机号"
        case .needVIP:
            return "需要购买VIP"
        case .emptyData:
            return "暂无数据"
        case .networkTimeout:
            return "网络请求超时"
        }
    }
}

// MARK: - 基础响应模型
struct TDBaseResponse<T: Codable>: Codable {
    let code: Int
    let data: T?
    let msg: String
    let ret: Bool
   
}

// MARK: - 列表响应模型
struct TDListResponse<T: Codable>: Codable {
    let list: [T]
}

// MARK: - 空响应模型（用于不需要返回数据的接口）
struct TDEmptyResponse: Codable {}
