//
//  TDAvatarManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
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
        // 覆盖前先清掉旧文件，避免命中旧缓存
        if fileManager.fileExists(atPath: cachePath.path) {
            try? fileManager.removeItem(at: cachePath)
        }
        try data.write(to: cachePath)
    }

    
    // 删除缓存的头像
    func deleteLocalAvatar(for userId: Int) {
        guard let cachePath = avatarCachePath(for: userId) else { return }
        try? fileManager.removeItem(at: cachePath)
    }
}

