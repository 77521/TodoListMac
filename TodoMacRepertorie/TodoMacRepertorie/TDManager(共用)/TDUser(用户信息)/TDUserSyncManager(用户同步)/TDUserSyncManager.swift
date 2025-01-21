//
//  TDUserSyncManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
/// 用户同步状态管理
class TDUserSyncManager {
    static let shared = TDUserSyncManager()
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    /// 获取用户是否首次同步的键
    private func firstSyncKey(for userId: Int) -> String {
        return "user_first_sync_\(userId)"
    }
    
    /// 检查用户是否是首次同步
    func isFirstSync(userId: Int) -> Bool {
        return !userDefaults.bool(forKey: firstSyncKey(for: userId))
    }
    
    /// 标记用户已完成首次同步
    func markSyncCompleted(userId: Int) {
        userDefaults.set(true, forKey: firstSyncKey(for: userId))
    }
    
    /// 重置用户同步状态（用于切换用户时）
    func resetSyncStatus(userId: Int) {
        userDefaults.set(false, forKey: firstSyncKey(for: userId))
    }
    
    /// 清除所有用户的同步状态（用于登出时）
    func clearAllSyncStatus() {
        if let bundleId = Bundle.main.bundleIdentifier {
            userDefaults.removePersistentDomain(forName: bundleId)
        }
    }
}
