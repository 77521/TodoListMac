//
//  TDNetWorkManager.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/5.
//

import Foundation
import SwiftUI
import HandyJSON
import Alamofire


class TDNetworkManager {
    static let shared = TDNetworkManager()
    private let baseURL = "https://www.evestudio.cn/todoList/"
    private let reachability = NetworkReachabilityManager()
    private let timeoutInterval: TimeInterval = 15
    
    private var isHandlingTokenExpired = false
    
    // MARK: - 状态码定义
    enum StatusCode: Int {
        case success = 0
        case unregistered = 204
        case tokenExpired = 401
        case serverError = 500
        case parameterError = 400
        case forbidden = 403
        case notFound = 404
    }
    
    // MARK: - 错误定义
    enum TDNetworkError: LocalizedError {
        case network(String)
        case server(String)
        case unregistered
        case tokenExpired
        case parameterError
        case noNetwork
        case parseError
        case emptyData

        var errorDescription: String? {
            switch self {
            case .network(let message): return message
            case .server(let message): return message
            case .unregistered: return "用户未注册"
            case .tokenExpired: return "登录已过期，请重新登录"
            case .parameterError: return "参数错误"
            case .noNetwork: return "网络连接不可用"
            case .parseError: return "数据解析失败"
            case .emptyData: return "数据为空"
            }
        }
    }
    
    // MARK: - 初始化
    init() {
        setupReachability()
    }
    
    private func setupReachability() {
        reachability?.startListening { [weak self] status in
            guard let self = self else { return }
            
            let isReachable = status == .reachable(.ethernetOrWiFi) || status == .reachable(.cellular)
            
            #if DEBUG
            print("🌐 网络状态: \(isReachable ? "已连接" : "已断开")")
            #endif
            
            if !isReachable {
                NotificationCenter.default.post(name: .networkStatusChanged, object: nil)
            }
        }
    }
    
    // MARK: - 默认参数
    private var defaultParameters: Parameters {
        [
            "tdChannelCode": "MAC",
            "versionCode": String((Double(TDDeviceManager.shared.appVersion) ?? 1.0) * 100),
            "packageName": Bundle.main.bundleIdentifier ?? "",
            "appName": "Todo清单",
            "token": TDUserManager.shared.currentUser?.token ?? "",
            "userId": TDUserManager.shared.userId ?? -1,
        ]
    }
    
    // MARK: - 网络请求方法
    /// 普通请求方法
    @discardableResult
    func request<T: HandyJSON>(_ path: String,
                              method: HTTPMethod = .post,
                              parameters: Parameters? = nil,
                              completion: @escaping (Result<T?, TDNetworkError>) -> Void) -> DataRequest? {
        
        // 网络检查
        guard reachability?.isReachable ?? false else {
            completion(.failure(.noNetwork))
            return nil
        }
        
        // 参数合并
        var finalParameters = defaultParameters
        if let customParameters = parameters {
            finalParameters.merge(customParameters) { _, new in new }
        }
        
        // URL 检查
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion(.failure(.network("无效的URL")))
            return nil
        }
        
        // 创建请求
        let request = AF.request(baseURL + encodedPath,
                               method: method,
                               parameters: finalParameters,
                               encoding: URLEncoding.default)
            .validate()
            .responseData(queue: .global(qos: .userInitiated)) { [weak self] response in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.handleResponse(response, path: path, parameters: finalParameters, completion: completion)
                }
            }
        return request
    }
    
    /// 数组请求方法
    @discardableResult
    func requestList<T: HandyJSON>(_ path: String,
                                  method: HTTPMethod = .post,
                                  parameters: Parameters? = nil,
                                  completion: @escaping (Result<[T], TDNetworkError>) -> Void) -> DataRequest? {
        
        // 合并参数
        var finalParameters = defaultParameters
        if let customParameters = parameters {
            finalParameters.merge(customParameters) { _, new in new }
        }

        let request = AF.request(baseURL + path,
                               method: method,
                               parameters: finalParameters,
                               encoding: URLEncoding.default)
            .validate()
            .responseData(queue: .global(qos: .userInitiated)) { [weak self] response in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch response.result {
                    case .success(let data):
                        guard let jsonString = String(data: data, encoding: .utf8) else {
                            completion(.failure(.parseError))
                            return
                        }
                        
                        #if DEBUG
                        print("原始 JSON: \(jsonString)")
                        #endif
                        
                        // 检查空数据情况
                        if jsonString.contains("\"data\":null") ||
                            jsonString.contains("\"data\":{}") {
                            completion(.success([]))
                            return
                        }
                        
                        // 直接解析为正确的结构
                        guard let baseResponse = TDBaseResponse<TDListData<T>>.deserialize(from: jsonString) else {
                            completion(.failure(.parseError))
                            return
                        }
                        
                        #if DEBUG
                        print("解析后的数据: \(baseResponse)")
                        #endif
                        
                        // 检查业务状态
                        if baseResponse.ret && baseResponse.code == 0 {
                            if baseResponse.data == nil {
                                completion(.success([]))
                            } else {
                                let list = baseResponse.data?.list ?? []
                                completion(.success(list))
                            }
                        } else {
                            completion(.failure(.server(baseResponse.msg)))
                        }
                        
                    case .failure(let error):
                        let message = error.isTimeout ? "请求超时" :
                                     error.isCancelled ? "请求已取消" :
                                     error.localizedDescription
                        completion(.failure(.network(message)))
                    }
                }
            }
        
        return request
        // 直接使用 request 方法，它内部会调用 handleResponse
//            return request(path, method: method, parameters: parameters) { (result: Result<TDListResponse<T>?, TDNetworkError>) in
//                switch result {
//                case .success(let response):
//                    // 从 response 中提取列表数据
//                    let list = response?.data?.list ?? []
//                    completion(.success(list))
//                    
//                case .failure(let error):
//                    completion(.failure(error))
//                }
//            }
    }
    // MARK: - 响应处理
    private func handleResponse<T: HandyJSON>(_ response: AFDataResponse<Data>,
                                            path: String,
                                            parameters: Parameters,
                                            completion: (Result<T?, TDNetworkError>) -> Void) {
        #if DEBUG
        printDebugInfo(response, path: path, parameters: parameters)
        #endif
        
        switch response.result {
        case .success(let data):
            guard let jsonString = String(data: data, encoding: .utf8) else {
                completion(.failure(.parseError))
                return
            }
#if DEBUG
            print("原始 JSON 字符串: \(jsonString)")
#endif

            // 解析基础响应
            guard let baseResponse = TDBaseResponse<T>.deserialize(from: jsonString) else {
                completion(.failure(.parseError))
                return
            }
            
#if DEBUG
print("解析后的 baseResponse: \(baseResponse)")
print("ret 值: \(baseResponse.ret)")
print("data 值: \(String(describing: baseResponse.data))")
#endif


            // 处理状态码
            switch StatusCode(rawValue: baseResponse.code) {
            case .success:
                // 处理空数据的情况
                if baseResponse.ret {
                    if T.self == TDEmptyResponse.self {
                        // 如果是 EmptyResponse 类型，直接返回成功
                        completion(.success(nil))
                    } else if jsonString.contains("\"data\":null") ||
                                jsonString.contains("\"data\":{}") ||
                                baseResponse.data == nil {
                        // 数据为空的情况
                        completion(.success(nil))
                    } else {
                        // 有数据的情况
                        completion(.success(baseResponse.data))
                    }
                } else {
                    completion(.failure(.server(baseResponse.msg)))
                }
            case .unregistered:
                completion(.failure(.unregistered))
                
            case .tokenExpired:
                handleTokenExpired()
                completion(.failure(.tokenExpired))
                
            case .parameterError:
                completion(.failure(.parameterError))
                
            case .forbidden:
                completion(.failure(.server("无权访问")))
                
            case .notFound:
                completion(.failure(.server("接口不存在")))
                
            case .serverError:
                completion(.failure(.server("服务器内部错误")))
                
            default:
                completion(.failure(.server(baseResponse.msg)))
            }
            
        case .failure(let error):
            let message = error.isTimeout ? "请求超时" :
                         error.isCancelled ? "请求已取消" :
                         error.localizedDescription
            completion(.failure(.network(message)))
        }
    }
    
    // MARK: - Token过期处理
    private func handleTokenExpired() {
        guard !isHandlingTokenExpired else { return }
        isHandlingTokenExpired = true
        DispatchQueue.main.async { [weak self] in
            // 清除用户数据
            TDUserManager.shared.clearUser()
            // 发送通知
            NotificationCenter.default.post(name: .userTokenExpired, object: nil)
            // 重置标志
            self?.isHandlingTokenExpired = false
        }
    }
    
    // MARK: - 调试信息
    private func printDebugInfo(_ response: AFDataResponse<Data>, path: String, parameters: Parameters) {
        let timestamp = DateFormatter.networkDateFormatter.string(from: Date())
        print("""
        
        ==================== 网络请求 ====================
        ⏰ 时间: \(timestamp)
        🌐 URL: \(baseURL + path)
        📝 参数: \(parameters)
        📫 响应: \(String(data: response.data ?? Data(), encoding: .utf8) ?? "")
        \(response.error.map { "❌ 错误: \($0)" } ?? "")
        ================================================
        
        """)
    }

}

// MARK: - 基础模型定义
/// 基础响应模型
struct TDBaseResponse<T: HandyJSON>: HandyJSON {
    var ret: Bool = false
    var code: Int = 0
    var msg: String = ""
    var data: T?
    
    init() {}
}
// 简化后的数据模型，只包含 list 数组
struct TDListData<T: HandyJSON>: HandyJSON {
    var list: [T]?              // 实际的数据数组
    init() {}
}
// 空响应模型
struct TDEmptyResponse: HandyJSON {
    init() {}  // HandyJSON 需要空初始化器
}



// MARK: - 扩展
private extension DateFormatter {
    static let networkDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}
// MARK: - AFError 扩展
extension AFError {
    var isTimeout: Bool {
        if case .sessionTaskFailed(let error as URLError) = self,
           error.code == .timedOut {
            return true
        }
        return false
    }
    
    var isCancelled: Bool {
        if case .sessionTaskFailed(let error as URLError) = self,
           error.code == .cancelled {
            return true
        }
        return false
    }
}
