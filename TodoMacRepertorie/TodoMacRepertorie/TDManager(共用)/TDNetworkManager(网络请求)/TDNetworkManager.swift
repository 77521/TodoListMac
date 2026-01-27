//
//  TDNetworkManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI

actor TDNetworkManager {
    static let shared = TDNetworkManager()
    private let baseURL = "https://www.evestudio.cn/todoList/"
    private let timeout: TimeInterval = 30
    
    // MARK: - 类型别名
    typealias Parameters = [String: Any]
    
    private init() {}
    
    // MARK: - 默认请求参数
    private var defaultParameters: [String: Any] {
        [
            "tdChannelCode": "iOS",
            "versionCode": String(Int((Double(TDDeviceManager.shared.appVersion) ?? 1) * 100)),
            
            "packageName": Bundle.main.bundleIdentifier ?? "",
            "appName": "Todo清单",
            "token": TDUserManager.shared.currentUser?.token ?? "",
            "userId": TDUserManager.shared.userId,
        ]
    }

    
    // MARK: - 通用请求方法
    @MainActor
    func request<T: Codable>(
        endpoint: String,
        parameters: Parameters = [:],
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw TDNetworkError.invalidURL
        }
        
        // 合并默认参数和自定义参数
        var finalParameters = await defaultParameters
        parameters.forEach { finalParameters.updateValue($0.value, forKey: $0.key) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // 将参数转换为查询字符串格式
        let queryItems = finalParameters.map { key, value in
            return "\(key)=\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        }.joined(separator: "&")
        
        request.httpBody = queryItems.data(using: .utf8)
        
        // 打印请求参数
        print("Request Parameters: \(queryItems)")

        // 使用 URLComponents 处理参数，自动处理URL编码
        var components = URLComponents()
        components.queryItems = finalParameters.map { key, value in
            URLQueryItem(name: key, value: "\(value)")
        }
        
        request.httpBody = components.query?.data(using: .utf8)
        
        // 打印请求参数
        print("Request Parameters: \(components.query ?? "")")

        var responseData: Data?
        var requestError: Error?
                
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            print("服务器原始响应：", String(data: data, encoding: .utf8) ?? "无内容")
            // 打印调试信息
//            await printDebugInfo(url: url, parameters: finalParameters, responseData: data, error: nil)
            
            // 解析基础响应
            let baseResponse = try JSONDecoder().decode(TDBaseResponse<T>.self, from: data)
            
            // 检查请求状态
            if baseResponse.ret {
                // 请求成功，直接返回data（即使为nil）
                if let responseData = baseResponse.data {
                    return responseData
                } else {
                    // 如果data为nil，但请求成功，创建一个空的实例
                    // 这里使用 TDEmptyResponse 作为特殊情况
                    if T.self == TDEmptyResponse.self {
                        return TDEmptyResponse() as! T
                    }
                    // 对于其他类型，尝试创建空实例
                    return try JSONDecoder().decode(T.self, from: "{}".data(using: .utf8)!)
                }
            } else {
                // ret = 0，请求失败，根据 code 处理不同的错误状态
                switch baseResponse.code {
                case 100, 101:
                    // Token过期，清除用户信息
                    await MainActor.run {
                        TDUserManager.shared.clearUserInfo()
                    }
                    throw TDNetworkError.tokenExpired
                case 204:
                    throw TDNetworkError.needRegister
                case 115:
                    throw TDNetworkError.notVIPMember
                case 220:
                    throw TDNetworkError.wechatBound
                case 113, 114:
                    throw TDNetworkError.needForceBindPhone
                case 300:
                    throw TDNetworkError.needBindPhone
                case 5580:
                    throw TDNetworkError.needVIP
                default:
                    throw TDNetworkError.requestFailed(baseResponse.msg)
                }
            }
        } catch is URLError {
            requestError = TDNetworkError.networkTimeout
            // 打印调试信息
            await printDebugInfo(url: url, parameters: finalParameters, responseData: responseData, error: requestError)
            throw TDNetworkError.networkTimeout
        } catch let error as TDNetworkError {
            // 已经是 TDNetworkError，直接抛出
            requestError = error
            await printDebugInfo(url: url, parameters: finalParameters, responseData: responseData, error: requestError)
            throw error
        } catch {
            requestError = error
            // 打印调试信息
            await printDebugInfo(url: url, parameters: finalParameters, responseData: responseData, error: requestError)
            // 如果是解码错误，提供更友好的错误信息
            if let decodingError = error as? DecodingError {
                throw TDNetworkError.decodingError(decodingError.localizedDescription)
            }
            throw TDNetworkError.requestFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 发送验证码示例
//    @MainActor
//    func sendVerificationCode(phone: String) async throws {
//        let parameters = ["phone": phone]
//        _ = try await request(
//            endpoint: "sendCode",
//            parameters: parameters,
//            responseType: TDEmptyResponse.self
//        )
//    }
//    
    // MARK: - 处理列表数据示例
    @MainActor
    func fetchList<T: Codable>(endpoint: String, parameters: [String: Any] = [:]) async throws -> [T] {
        let response = try await request(
            endpoint: endpoint,
            parameters: parameters,
            responseType: TDListResponse<T>.self
        )
        return response.list
    }
    
    // MARK: - 调试信息打印
    private func printDebugInfo(url: URL, parameters: [String: Any], responseData: Data?, error: Error?) {
        #if DEBUG
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let responseString = responseData.flatMap { String(data: $0, encoding: .utf8) } ?? "无数据"
        let errorMessage = error.map { "❌ 错误: \($0)" } ?? ""
        
        print("""
        
        ==================== 网络请求 ====================
        ⏰ 时间: \(timestamp)
        🌐 URL: \(url)
        📝 参数: \(parameters)
        📫 响应: \(responseString)
        \(errorMessage)
        ================================================
        
        """)
        #endif
    }

}
