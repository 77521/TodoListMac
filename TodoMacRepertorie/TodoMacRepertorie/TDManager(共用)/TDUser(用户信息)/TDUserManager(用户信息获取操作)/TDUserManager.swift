

//
//  TDUserManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI


class TDUserManager: ObservableObject {
    static let shared = TDUserManager()
    private let keychainManager = TDKeychainManager.shared
    
    /// 当前登录用户
    @Published var currentUser: TDUserModel?
    /// 当前是否已登录
    @Published var isLoggedIn = false
    /// 当前登录用户的 userId（Int 类型）
    @Published var currentUserId: Int? = nil
    /// 已登录过的用户ID列表的 UserDefaults key
    private let loggedInUserIdsKey = "logged_in_user_ids"

    private init() {
        loadUserFromKeychain()
    }
    
    // MARK: - 用户信息管理
    
    /// 从 Keychain 恢复用户信息
    private func loadUserFromKeychain() {
        
        // 直接用 Int 类型读取
        let lastUserId = UserDefaults.standard.integer(forKey: "last_login_userid")
        // 如果没存过，integer(forKey:) 会返回 0，这里要判断一下
        self.currentUserId = lastUserId == 0 ? nil : lastUserId

        if let userId = currentUserId,
           let userData = keychainManager.getUserInfo(for: userId),
           let user = try? JSONDecoder().decode(TDUserModel.self, from: userData) {
            self.currentUser = user
            self.isLoggedIn = true
            // 非会员则强制恢复默认主题，防止上次 VIP 主题残留
            TDThemeManager.shared.enforceVipTheme(isVip: user.isVIP)

        } else {
            self.currentUser = nil
            self.isLoggedIn = false
        }
    }
    
    /// 保存用户信息
    func saveUser(_ user: TDUserModel) {
        // 检查头像是否变更
        let oldAvatarURL = currentUser?.head
        let newAvatarURL = user.head
        
        if oldAvatarURL != newAvatarURL {
            // 如果头像URL变更，下载新头像
            if let avatarURL = URL(string: newAvatarURL) {
                Task {
                    try? await TDAvatarManager.shared.downloadAndCacheAvatar(from: avatarURL, userId: user.userId)
                }
            }
        }
        
        // 更新内存中的用户信息
        currentUser = user
        isLoggedIn = true
        
        // 保存到钥匙串（带 userId，支持多账号）
        if let userData = try? JSONEncoder().encode(user) {
            keychainManager.saveUserInfo(userData, for: user.userId)
            keychainManager.saveToken(user.token, for: user.userId)
        }
        
        // 记录当前登录的 userId 到 UserDefaults，方便下次自动登录
        UserDefaults.standard.set(user.userId, forKey: "last_login_userid")
        // 5. 新增到已登录账号列表（多账号管理核心）
        addLoggedInUserId(user.userId)

        // 发送用户登录通知
        NotificationCenter.default.post(name: .userDidLogin, object: nil)
        // 非会员则强制恢复默认主题，防止上次 VIP 主题残留
        TDThemeManager.shared.enforceVipTheme(isVip: user.isVIP)

        
        
        //        // 发送用户登录通知
        //        NotificationCenter.default.post(name: .userDidLogin, object: nil)
    }
    
    /// 更新用户信息
    func updateUserInfo(_ user: TDUserModel) {
        let oldAvatarURL = currentUser?.head
        let newAvatarURL = user.head
        
        if oldAvatarURL != newAvatarURL {
            if let avatarURL = URL(string: newAvatarURL) {
                Task {
                    try? await TDAvatarManager.shared.downloadAndCacheAvatar(from: avatarURL, userId: user.userId)
                }
            }
        }
        
        currentUser = user
        
        if let userData = try? JSONEncoder().encode(user) {
            keychainManager.saveUserInfo(userData, for: user.userId)
        }
    }
    
    /// 清除用户信息
    func clearUserInfo() {
        // 清除同步状态
        TDUserSyncManager.shared.clearAllSyncStatus()
        
        // 清除内存中的用户信息
        let userId = currentUser?.userId
        currentUser = nil
        isLoggedIn = false
        
        // 清除钥匙串（只清除当前用户）
        if let userId = userId {
            keychainManager.removeUserInfo(for: userId)
            keychainManager.removeToken(for: userId)
        }
        // 清除本地分类数据
        TDCategoryManager.shared.clearLocalCategories()
        // 清除“记忆的上次分类清单选择”（退出登录后永远默认未分类）
        if let userId {
            TDSettingManager.shared.clearCategoryJsonData(for: userId)
        }

        // 清除当前登录 userId
        UserDefaults.standard.removeObject(forKey: "last_login_userid")
        // 发送用户退出登录通知
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
    
    /// 切换到指定 userId 的账号
    func switchToUser(userId: Int) {
        self.currentUserId = userId
        UserDefaults.standard.set(userId, forKey: "last_login_userid")
        if let userData = keychainManager.getUserInfo(for: userId),
           let user = try? JSONDecoder().decode(TDUserModel.self, from: userData) {
            self.currentUser = user
            self.isLoggedIn = true
            // 非会员则强制恢复默认主题，防止上次 VIP 主题残留
            TDThemeManager.shared.enforceVipTheme(isVip: user.isVIP)

        } else {
            self.currentUser = nil
            self.isLoggedIn = false
        }
    }

    /// 退出当前账号
    func logoutCurrentUser() {
        if let userId = currentUserId {
            keychainManager.removeUserInfo(for: userId)
            keychainManager.removeToken(for: userId)
            removeLoggedInUserId(userId)
        }
        self.currentUser = nil
        self.isLoggedIn = false
        self.currentUserId = nil
        // 清除“记忆的上次分类清单选择”（退出登录后永远默认未分类）
        TDSettingManager.shared.clearCategoryJsonData(for: userId)
        UserDefaults.standard.removeObject(forKey: "last_login_userid")
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }

    // MARK: - 账号列表管理

    /// 获取所有已登录过的用户ID列表
    func getAllLoggedInUserIds() -> [Int] {
        let array = UserDefaults.standard.array(forKey: loggedInUserIdsKey) as? [Int] ?? []
        return array
    }

    /// 新增一个已登录用户ID
    func addLoggedInUserId(_ userId: Int) {
        var userIds = getAllLoggedInUserIds()
        if !userIds.contains(userId) {
            userIds.append(userId)
            UserDefaults.standard.set(userIds, forKey: loggedInUserIdsKey)
        }
    }
    

    /// 移除一个已登录用户ID
    func removeLoggedInUserId(_ userId: Int) {
        var userIds = getAllLoggedInUserIds()
        if let index = userIds.firstIndex(of: userId) {
            userIds.remove(at: index)
            UserDefaults.standard.set(userIds, forKey: loggedInUserIdsKey)
        }
    }

    
    // MARK: - 用户状态检查
    
    /// 检查是否登录
    var isUserLoggedIn: Bool {
        return isLoggedIn && currentUser != nil && !currentUser!.token.isEmpty
    }
    
    // MARK: - 用户信息获取
    
    /// 获取用户ID
    var userId: Int {
        return currentUser?.userId ?? -1
    }
    
    /// 获取用户Token
    var token: String {
        return currentUser?.token ?? ""
    }
    
    /// 获取用户昵称
    var nickname: String {
        return currentUser?.userName ?? "未设置昵称"
    }
    
    /// 获取用户账号
    var account: String {
        if let phoneNumber = currentUser?.phoneNumber, phoneNumber > 0 {
            return String(phoneNumber)
        }
        return currentUser?.userAccount ?? ""
    }
    
    /// 获取用户头像URL
    var avatarURL: URL? {
        if let userId = currentUser?.userId,
           let localURL = TDAvatarManager.shared.getLocalAvatarURL(for: userId) {
            return localURL
        }
        guard let avatarPath = currentUser?.head,
              !avatarPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        return URL(string: avatarPath)
    }
    
    /// 检查是否是VIP
    var isVIP: Bool {
        return currentUser?.isVIP ?? false
    }
    
    
}






////
////  TDUserManager.swift
////  TodoMacRepertorie
////
////  Created by 孬孬 on 2024/12/28.
////
//
//import Foundation
//import SwiftUI
//
//class TDUserManager: ObservableObject {
//    static let shared = TDUserManager()
//    private let keychainManager = TDKeychainManager.shared
//    
//    @Published var currentUser: TDUserModel?
//    @Published var isLoggedIn = false
//    
//    private init() {
//        loadUserFromKeychain()
//    }
//    
//    // MARK: - 用户信息管理
//    
//    /// 从 Keychain 恢复用户信息
//    private func loadUserFromKeychain() {
//        
//        if let userData = keychainManager.getUserInfo(),
//           let user = try? JSONDecoder().decode(TDUserModel.self, from: userData) {
//            self.currentUser = user
//            self.isLoggedIn = true
//            
//            // 检查是否是首次同步
//            if let userId = user.userId {
//                if TDUserSyncManager.shared.isFirstSync(userId: userId) {
//                    // 如果是首次同步，将在同步时处理
//                    print("用户 \(userId) 需要首次同步")
//                }
//            }
//        }
//
//        
//        if let userData = keychainManager.getUserInfo(),
//           let jsonString = String(data: userData, encoding: .utf8),
//           let user = TDUserModel.deserialize(from: jsonString) {
//            self.currentUser = user
//            self.isLoggedIn = true
//            
//
//        }
//    }
//    
//    /// 保存用户信息
//    func saveUser(_ user: TDUserModel) {
//        currentUser = user
//        isLoggedIn = true
//        
//        // 保存到钥匙串
//        if let userJson = user.toJSONString() {
//            keychainManager.saveUserInfo(userJson.data(using: .utf8)!)
//            keychainManager.saveToken(user.token ?? "")
//        }
//        let oldAvatarPath = currentUser?.head
//        let newAvatarPath = user.head
//        if oldAvatarPath != newAvatarPath {
//            // 如果头像地址不一样 清除旧头像的缓存
//            // 下载头像到本地
//            if let avatarURL = URL(string: user.head ?? "")
//            {
//                Task {
//                    try? await TDAvatarManager.shared.downloadAndCacheAvatar(from: avatarURL, userId: currentUser?.userId ?? 0)
//                }
//            }
//        }
//        
//        
//        //        // 发送用户登录通知
//        //        NotificationCenter.default.post(name: .userDidLogin, object: nil)
//    }
//    
//    /// 更新用户信息
//    func updateUser(_ user: TDUserModel) {
//        // 检查头像是否变更
//        // 检查头像是否变更
//        let oldAvatarPath = currentUser?.head
//        let newAvatarPath = user.head
//        if oldAvatarPath != newAvatarPath {
//            // 如果头像地址不一样 清除旧头像的缓存
//            // 下载头像到本地
//            if let avatarURL = URL(string: user.head ?? "")
//            {
//                Task {
//                    try? await TDAvatarManager.shared.downloadAndCacheAvatar(from: avatarURL, userId: currentUser?.userId ?? 0)
//                }
//            }
//        }
//        currentUser = user
//        if let userJson = user.toJSONString() {
//            keychainManager.saveUserInfo(userJson.data(using: .utf8)!)
//        }
//        
//        
//    }
//    
//    /// 退出登录清空数据
//    func clearUser() {
//        // 清除内存中的用户信息
//        // 清除同步状态
//        TDUserSyncManager.shared.clearAllSyncStatus()
//        
//
//        currentUser = nil
//        isLoggedIn = false
//        // 清除钥匙串
//        keychainManager.clearAll()
//        // 清除分类数据
////        TDCategoryManager.shared.clearData()
//        // 发送用户退出登录通知
//        NotificationCenter.default.post(name: .userDidLogout, object: nil)
//    }
//    
//    // MARK: - 用户状态检查
//    
//    /// 检查是否登录
//    var isUserLoggedIn: Bool {
//        return isLoggedIn && currentUser != nil && keychainManager.getToken() != nil
//    }
//    
//    /// 检查用户Token是否有效
//    //    func validateToken() async -> Bool {
//    //        guard let token = keychainManager.getToken() else {
//    //            return false
//    //        }
//    //
//    //        do {
//    //            let userInfo = try await TDLoginAPI.shared.getUserInfo()
//    //            if userInfo.token == token {
//    //                return true
//    //            } else {
//    //                // Token 已变更，更新用户信息
//    //                saveUser(userInfo)
//    //                return true
//    //            }
//    //        } catch {
//    //            if let networkError = error as? TDNetworkError, networkError.needRelogin {
//    //                logout()
//    //            }
//    //            return false
//    //        }
//    //    }
//    
//    
//    // MARK: - 用户信息获取
//    
//    /// 获取用户ID
//    var userId: Int? {
//        return currentUser?.userId
//    }
//    
//    /// 获取用户昵称
//    var nickname: String {
//        return currentUser?.userName ?? "未设置昵称"
//    }
//    
//    /// 获取账号
//    var account: String {
//        return currentUser?.phoneNumber ?? 0 > 0 ?
//        String(currentUser?.phoneNumber ?? 0) :
//        currentUser?.userAccount ?? ""
//    }
//    
//    /// 获取用户头像URL
//    var avatarURL: URL? {
//        guard let avatarPath = currentUser?.head else { return nil }
//        return URL(string: avatarPath)
//    }
//    
//    
//    
//}
//
