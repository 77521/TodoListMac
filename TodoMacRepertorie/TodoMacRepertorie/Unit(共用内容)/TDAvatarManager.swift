//
//  TDAvatarManager.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/18.
//

import Foundation

// 头像缓存管理器
class TDAvatarManager {
    static let shared = TDAvatarManager()
    
    private let fileManager = FileManager.default
    private let cacheFolderName = "AvatarCache"
    
    private init() {
        createCacheDirectory()
    }
    
    // 获取缓存目录路径
    private var cacheDirectory: URL? {
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        return cacheDir.appendingPathComponent(cacheFolderName)
    }
    
    // 创建缓存目录
    private func createCacheDirectory() {
        guard let cacheDirectory = cacheDirectory else { return }
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    // 获取头像缓存路径
    private func avatarCachePath(for userId: Int) -> URL? {
        return cacheDirectory?.appendingPathComponent("avatar_\(userId).jpg")
    }
    
    // 检查本地是否有缓存的头像
    func hasLocalAvatar(for userId: Int) -> Bool {
        guard let cachePath = avatarCachePath(for: userId) else { return false }
        return fileManager.fileExists(atPath: cachePath.path)
    }
    
    // 获取本地头像 URL
    func getLocalAvatarURL(for userId: Int) -> URL? {
        guard hasLocalAvatar(for: userId) else { return nil }
        return avatarCachePath(for: userId)
    }
    
    // 下载并缓存头像
    func downloadAndCacheAvatar(from url: URL, userId: Int) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        try await saveAvatarToCache(data: data, userId: userId)
    }
    
    // 保存头像到缓存
    private func saveAvatarToCache(data: Data, userId: Int) async throws {
        guard let cachePath = avatarCachePath(for: userId) else { return }
        try data.write(to: cachePath)
    }
    
    // 删除缓存的头像
    func deleteLocalAvatar(for userId: Int) {
        guard let cachePath = avatarCachePath(for: userId) else { return }
        try? fileManager.removeItem(at: cachePath)
    }
}

//// 修改 UserManager
//extension TDUserManager {
//    // 保存用户信息时下载头像
//    func saveHeader(_ user: TDUserModel) {
//        
//        // 下载头像到本地
//        if let avatarURL = URL(string: user.head ?? ""),
//           let userId = user.userId {
//            Task {
//                try? await TDAvatarManager.shared.downloadAndCacheAvatar(from: avatarURL, userId: userId)
//            }
//        }
//    }
//    
//    // 更新用户信息时检查头像是否需要更新
//    func updateUser(_ user: TDUserModel) {
//        // 检查头像是否变更
//        if let oldAvatarPath = currentUser?.head,
//           let newAvatarPath = user.head,
//           oldAvatarPath != newAvatarPath,
//           let userId = user.userId {
//            // 头像变更，删除旧的本地头像
//            TDAvatarManager.shared.deleteLocalAvatar(for: userId)
//            // 下载新头像
//            if let newURL = URL(string: newAvatarPath) {
//                Task {
//                    try? await TDAvatarManager.shared.downloadAndCacheAvatar(from: newURL, userId: userId)
//                }
//            }
//        }
//        
//        currentUser = user
//        if let userJson = user.toJSONString() {
//            keychainManager.saveUserInfo(userJson.data(using: .utf8)!)
//        }
//    }
//    
//    // 退出登录时清除本地头像
//    func clearUser() {
//        if let userId = currentUser?.userId {
//            TDAvatarManager.shared.deleteLocalAvatar(for: userId)
//        }
//        
//        currentUser = nil
//        isLoggedIn = false
//        keychainManager.clearAll()
//        TDCategoryManager.shared.clearData()
//        NotificationCenter.default.post(name: .userDidLogout, object: nil)
//    }
//}
