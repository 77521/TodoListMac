//
//  TDAppConfig.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/5/7.
//

import Foundation

struct TDAppConfig {
    /// App Group ID
    static let appGroupId = "group.com.Mac.Todolist.TodoMacRepertorie"
    /// 安全密钥
    static let securityKey = "naonao520a@163.com"
    /// SwiftData 数据库文件名
    static let swiftDataDBName = "SwiftDataDB"
    /// 主题文件名
    static let themesFileName = "custom_themes.json"

    /// SwiftData 数据库完整路径（App Group 目录下）
    static var swiftDataDBURL: URL? {
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return nil
        }
        return appGroupURL.appendingPathComponent(swiftDataDBName)
    }
    /// 主题文件完整路径（App Group 目录下）
    static var themesFileURL: URL? {
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return nil
        }
        return appGroupURL.appendingPathComponent(themesFileName)
    }

}
