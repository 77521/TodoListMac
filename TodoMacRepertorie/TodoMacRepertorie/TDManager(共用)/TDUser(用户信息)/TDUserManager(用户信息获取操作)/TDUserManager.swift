

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
    
    
    /// 是否运行在 Widget Extension 进程中（避免 extension 冷启动时误清空 AppGroup 里给小组件用的用户文件）
    private var isRunningInWidgetExtension: Bool {
        Bundle.main.bundleURL.pathExtension == "appex"
            || (Bundle.main.bundleIdentifier?.contains("TDMacWidget") ?? false)
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
            // 写入 AppGroup：给小组件读取（TDUserModel JSON）
            TDWidgetUserInfoBridge.write(user: user)

        } else {
            self.currentUser = nil
            self.isLoggedIn = false
            // Widget Extension 冷启动时 Keychain/last_login_userid 可能为空，但 AppGroup 用户文件仍应保留，
            // 否则首次点击小组件按钮会触发 TDUserManager 初始化并把小组件用户文件清空，导致 UI 变成“未登录”。
            if !isRunningInWidgetExtension {
                TDWidgetUserInfoBridge.clear()
            }

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

        TDWidgetUserInfoBridge.write(user: user)
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
        TDWidgetUserInfoBridge.write(user: user)

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
        
        TDWidgetUserInfoBridge.clear()

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
        
        TDWidgetUserInfoBridge.clear()

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
