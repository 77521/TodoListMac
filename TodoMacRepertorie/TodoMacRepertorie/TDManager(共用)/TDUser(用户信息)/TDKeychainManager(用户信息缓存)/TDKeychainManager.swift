//
//  TDKeychainManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI
import Security

// Managers/KeychainManager.swift
/// Keychain 管理器，支持多账号信息存储与切换
class TDKeychainManager {
    /// 单例对象
    static let shared = TDKeychainManager()
    
    /// Keychain 服务标识，建议用 bundleId 保证唯一性
    private let service = Bundle.main.bundleIdentifier ?? "com.TodoMacRepertorie.app"
    
    // MARK: - 通用 Keychain 操作
    
    /// 保存数据到 Keychain
    /// - Parameters:
    ///   - value: 要保存的字符串
    ///   - key: 唯一 key
    /// - Returns: 是否保存成功
    func save(value: String, for key: String) -> Bool {
        // 将字符串转为 Data
        guard let data = value.data(using: .utf8) else { return false }
        // 构建查询条件
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword, // 密码类型
            kSecAttrService as String: service,            // 服务标识
            kSecAttrAccount as String: key,                // 账号（唯一 key）
            kSecValueData as String: data                  // 要保存的数据
        ]
        // 先删除旧数据，避免重复
        SecItemDelete(query as CFDictionary)
        // 添加新数据
        let status = SecItemAdd(query as CFDictionary, nil)
        // 返回是否成功
        return status == errSecSuccess
    }
    
    /// 从 Keychain 获取数据
    /// - Parameter key: 唯一 key
    /// - Returns: 字符串或 nil
    func getValue(for key: String) -> String? {
        // 构建查询条件
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword, // 密码类型
            kSecAttrService as String: service,            // 服务标识
            kSecAttrAccount as String: key,                // 账号（唯一 key）
            kSecReturnData as String: true,                // 返回数据
            kSecMatchLimit as String: kSecMatchLimitOne    // 只查找一个
        ]
        var result: AnyObject?
        // 查询数据
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        // 判断是否成功并解析为字符串
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }
    
    /// 删除 Keychain 数据
    /// - Parameter key: 唯一 key
    /// - Returns: 是否删除成功
    func remove(for key: String) -> Bool {
        // 构建查询条件
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword, // 密码类型
            kSecAttrService as String: service,            // 服务标识
            kSecAttrAccount as String: key                 // 账号（唯一 key）
        ]
        // 删除数据
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    /// 更新 Keychain 数据
    /// - Parameters:
    ///   - value: 新值
    ///   - key: 唯一 key
    /// - Returns: 是否更新成功
    func update(value: String, for key: String) -> Bool {
        // 将字符串转为 Data
        guard let data = value.data(using: .utf8) else { return false }
        // 构建查询条件
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword, // 密码类型
            kSecAttrService as String: service,            // 服务标识
            kSecAttrAccount as String: key                 // 账号（唯一 key）
        ]
        // 要更新的内容
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        // 执行更新
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        // 如果不存在则添加
        if status == errSecItemNotFound {
            return save(value: value, for: key)
        }
        return status == errSecSuccess
    }
    
    /// 检查 Keychain 是否存在某个 key
    /// - Parameter key: 唯一 key
    /// - Returns: 是否存在
    func exists(for key: String) -> Bool {
        // 构建查询条件
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword, // 密码类型
            kSecAttrService as String: service,            // 服务标识
            kSecAttrAccount as String: key,                // 账号（唯一 key）
            kSecReturnData as String: false                // 不返回数据
        ]
        // 查询
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - 多账号支持（以 userId 作为 key 后缀区分）
    
    /// 保存用户 Token（支持多账号）
    /// - Parameters:
    ///   - token: token 字符串
    ///   - userId: 用户唯一 id
    func saveToken(_ token: String, for userId: Int) {
        // 用 user_token_用户id 作为 key
        _ = save(value: token, for: "user_token_\(userId)")
    }
    
    /// 获取用户 Token
    /// - Parameter userId: 用户唯一 id
    /// - Returns: token 字符串或 nil
    func getToken(for userId: Int) -> String? {
        return getValue(for: "user_token_\(userId)")
    }
    
    /// 删除用户 Token
    /// - Parameter userId: 用户唯一 id
    func removeToken(for userId: Int) {
        _ = remove(for: "user_token_\(userId)")
    }
    
    /// 保存用户信息（支持多账号）
    /// - Parameters:
    ///   - userInfo: 用户信息 Data
    ///   - userId: 用户唯一 id
    func saveUserInfo(_ userInfo: Data, for userId: Int) {
        // 先转为 base64 字符串再存储
        _ = save(value: userInfo.base64EncodedString(), for: "user_info_\(userId)")
    }

    /// 获取用户信息
    /// - Parameter userId: 用户唯一 id
    /// - Returns: 用户信息 Data 或 nil
    func getUserInfo(for userId: Int) -> Data? {
        // 先取出 base64 字符串再转为 Data
        guard let base64String = getValue(for: "user_info_\(userId)") else {
            return nil
        }
        return Data(base64Encoded: base64String)
    }

    /// 删除用户信息
    /// - Parameter userId: 用户唯一 id
    func removeUserInfo(for userId: Int) {
        _ = remove(for: "user_info_\(userId)")
    }
    
    // MARK: - 其他操作
    
    /// 清除所有 Keychain 数据（慎用！会清空所有本服务下的内容）
    func clearAll() {
        // 构建查询条件
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword, // 密码类型
            kSecAttrService as String: service             // 服务标识
        ]
        // 删除所有数据
        _ = SecItemDelete(query as CFDictionary)
    }
}
