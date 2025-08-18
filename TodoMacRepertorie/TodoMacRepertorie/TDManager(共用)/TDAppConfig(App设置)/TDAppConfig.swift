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

}
