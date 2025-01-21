//
//  TDSettingEnum.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import Foundation

/// 主题模式
enum TDThemeMode: Int, Codable {
    /// 跟随系统
    case system = 1
    /// 白天模式
    case light = 2
    /// 夜间模式
    case dark = 3
}
/// 文字大小
enum TDFontSize: Int, Codable {
    /// 跟随系统
    case system = 1
    /// 小号 (13pt)
    case small = 2
    /// 大号 (15pt)
    case large = 3
    
    var size: CGFloat {
        switch self {
        case .system:
            return 14 // 系统默认大小
        case .small:
            return 13
        case .large:
            return 15
        }
    }
}

/// 语言设置
enum TDLanguage: Int, Codable {
    /// 跟随系统
    case system = 1
    /// 中文
    case chinese = 2
    /// 英文
    case english = 3
}
