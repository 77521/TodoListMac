//
//  TDKeychainManager.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/6.
//

import Foundation
import SwiftUI
import Security

// Managers/KeychainManager.swift
class TDKeychainManager {
    static let shared = TDKeychainManager()
    
    private let service = Bundle.main.bundleIdentifier ?? "com.TodoMacRepertorie.app"
    
    // 保存数据
    func save(value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        
        // 查询条件
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // 先删除旧数据
        SecItemDelete(query as CFDictionary)
        
        // 保存新数据
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // 获取数据
    func getValue(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    // 删除数据
    func remove(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // 更新数据
    func update(value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        if status == errSecItemNotFound {
            // 如果不存在，则添加
            return save(value: value, for: key)
        }
        
        return status == errSecSuccess
    }
    
    // 检查是否存在
    func exists(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // 保存用户Token
    func saveToken(_ token: String) {
        _ = save(value: token, for: "user_token")
    }
    
    // 获取用户Token
    func getToken() -> String? {
        return getValue(for: "user_token")
    }
    
    // 删除用户Token
    func removeToken() {
        _ = remove(for: "user_token")
    }
    
    // 保存用户信息
    func saveUserInfo(_ userInfo: Data) {
        _ = save(value: userInfo.base64EncodedString(), for: "user_info")
    }
    
    // 获取用户信息
    func getUserInfo() -> Data? {
        guard let base64String = getValue(for: "user_info") else {
            return nil
        }
        return Data(base64Encoded: base64String)
    }
    
    // 清除所有数据
    func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        _ = SecItemDelete(query as CFDictionary)
    }}

