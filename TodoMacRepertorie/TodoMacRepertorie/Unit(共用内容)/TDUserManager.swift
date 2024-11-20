//
//  TDUserManager.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/5.
//

import Foundation
import SwiftUI

class TDUserManager: ObservableObject {
    static let shared = TDUserManager()
    private let keychainManager = TDKeychainManager.shared
    
    @Published var currentUser: TDUserModel?
    @Published var isLoggedIn = false
    
    private init() {
//        clearUser()
        loadUserFromKeychain()
    }
    
    // MARK: - 用户信息管理
    
    /// 从 Keychain 恢复用户信息
    private func loadUserFromKeychain() {
        if let userData = keychainManager.getUserInfo(),
           let jsonString = String(data: userData, encoding: .utf8),
           let user = TDUserModel.deserialize(from: jsonString) {
            self.currentUser = user
            self.isLoggedIn = true
        }
    }
    
    /// 保存用户信息
    func saveUser(_ user: TDUserModel) {
        currentUser = user
        isLoggedIn = true
        
        // 保存到钥匙串
        if let userJson = user.toJSONString() {
            keychainManager.saveUserInfo(userJson.data(using: .utf8)!)
            keychainManager.saveToken(user.token ?? "")
        }
        let oldAvatarPath = currentUser?.head
        let newAvatarPath = user.head
        if oldAvatarPath != newAvatarPath {
            // 如果头像地址不一样 清除旧头像的缓存
            // 下载头像到本地
            if let avatarURL = URL(string: user.head ?? "")
            {
                Task {
                    try? await TDAvatarManager.shared.downloadAndCacheAvatar(from: avatarURL, userId: currentUser?.userId ?? 0)
                }
            }
        }
        
        
        //        // 发送用户登录通知
        //        NotificationCenter.default.post(name: .userDidLogin, object: nil)
    }
    
    /// 更新用户信息
    func updateUser(_ user: TDUserModel) {
        // 检查头像是否变更
        // 检查头像是否变更
        let oldAvatarPath = currentUser?.head
        let newAvatarPath = user.head
        if oldAvatarPath != newAvatarPath {
            // 如果头像地址不一样 清除旧头像的缓存
            // 下载头像到本地
            if let avatarURL = URL(string: user.head ?? "")
            {
                Task {
                    try? await TDAvatarManager.shared.downloadAndCacheAvatar(from: avatarURL, userId: currentUser?.userId ?? 0)
                }
            }
        }
        currentUser = user
        if let userJson = user.toJSONString() {
            keychainManager.saveUserInfo(userJson.data(using: .utf8)!)
        }
        
        
    }
    
    /// 退出登录清空数据
    func clearUser() {
        // 清除内存中的用户信息
        currentUser = nil
        isLoggedIn = false
        // 清除钥匙串
        keychainManager.clearAll()
        // 清除分类数据
        TDCategoryManager.shared.clearData()
        // 发送用户退出登录通知
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
    
    // MARK: - 用户状态检查
    
    /// 检查是否登录
    var isUserLoggedIn: Bool {
        return isLoggedIn && currentUser != nil && keychainManager.getToken() != nil
    }
    
    /// 检查用户Token是否有效
    //    func validateToken() async -> Bool {
    //        guard let token = keychainManager.getToken() else {
    //            return false
    //        }
    //
    //        do {
    //            let userInfo = try await TDLoginAPI.shared.getUserInfo()
    //            if userInfo.token == token {
    //                return true
    //            } else {
    //                // Token 已变更，更新用户信息
    //                saveUser(userInfo)
    //                return true
    //            }
    //        } catch {
    //            if let networkError = error as? TDNetworkError, networkError.needRelogin {
    //                logout()
    //            }
    //            return false
    //        }
    //    }
    
    
    // MARK: - 用户信息获取
    
    /// 获取用户ID
    var userId: Int? {
        return currentUser?.userId
    }
    
    /// 获取用户昵称
    var nickname: String {
        return currentUser?.userName ?? "未设置昵称"
    }
    
    /// 获取账号
    var account: String {
        return currentUser?.phoneNumber ?? 0 > 0 ?
        String(currentUser?.phoneNumber ?? 0) :
        currentUser?.userAccount ?? ""
    }
    
    /// 获取用户头像URL
    var avatarURL: URL? {
        guard let avatarPath = currentUser?.head else { return nil }
        return URL(string: avatarPath)
    }
    
    
    
}

