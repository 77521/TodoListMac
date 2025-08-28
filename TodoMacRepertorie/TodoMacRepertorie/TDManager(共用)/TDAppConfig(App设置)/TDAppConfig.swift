//
//  TDAppConfig.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/5/7.
//

import Foundation
import SwiftUI

struct TDAppConfig {
    /// App Group ID
    static let appGroupId = "group.com.Mac.Todolist.TodoMacRepertorie"
    /// 安全密钥
    static let securityKey = "naonao520a@163.com"
    /// SwiftData 数据库文件名
    static let swiftDataDBName = "SwiftDataDB"
    /// 主题文件名
    static let themesFileName = "custom_themes.json"

    // MARK: - TaskSort 相关配置
    
    /// 添加数据时 taskSort 默认值，就是当天没有数据的时候的默认值
    static let defaultTaskSort: Decimal = 5000.0
    /// 添加数据时 taskSort 取值范围的最小值
    static let minTaskSort: Decimal = 100.0
    /// 添加数据时 taskSort 取值范围的最大值
    static let maxTaskSort: Decimal = 300.0
    /// 在 taskSort 范围内生成随机排序值
    /// - Returns: 在 minTaskSort 到 maxTaskSort 范围内的随机整数（Decimal类型）
    static func randomTaskSort() -> Decimal {
        let minInt = Int(truncating: minTaskSort as NSDecimalNumber)
        let maxInt = Int(truncating: maxTaskSort as NSDecimalNumber)
        let randomInt = Int.random(in: minInt...maxInt)
        return Decimal(randomInt)
    }
    
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

    // MARK: - TaskId 生成相关配置
    
    /// 生成唯一的任务ID
    /// 格式：当前登录用户ID + 当前时间戳（毫秒）+ 32位随机字符串
    /// - Returns: 唯一的任务ID字符串
    static func generateTaskId() -> String {
        let userId = TDUserManager.shared.userId
        let timestamp = Date.currentTimestamp
        let randomString = generateRandomString(length: 32)
        
        return "\(userId)_\(timestamp)_\(randomString)"
    }
    
    /// 生成指定长度的随机字符串
    /// 包含数字 0-9、小写字母 a-z、大写字母 A-Z
    /// - Parameter length: 字符串长度
    /// - Returns: 随机字符串
    private static func generateRandomString(length: Int) -> String {
        let characters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String((0..<length).map { _ in characters.randomElement()! })
    }

    
    
}
