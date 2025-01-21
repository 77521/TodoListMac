//
//  TDThemeColorBase.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import Foundation
import SwiftUI

/// 主题基础颜色
struct TDThemeBaseColors: Codable, Equatable {
    /// 背景色
    let background: TDDynamicColor
    /// 次要背景色（用于卡片、弹窗等）
    let secondaryBackground: TDDynamicColor
    /// 主要文字颜色
    let primaryText: TDDynamicColor
    /// 次要文字颜色
    let secondaryText: TDDynamicColor
    /// 描述文字颜色
    let descriptionText: TDDynamicColor
    /// 分割线颜色
    let separator: TDDynamicColor
    /// 边框颜色
    let border: TDDynamicColor
}

/// 动态颜色（深浅色模式）
struct TDDynamicColor: Codable, Equatable {
    let light: String
    let dark: String
    
    func color(isDark: Bool) -> Color {
        Color.fromHex(isDark ? dark : light)
//        Color(hex: isDark ? dark : light)
    }
}

/// 主题颜色层级
struct TDThemeColorLevel: Codable, Equatable {
    let level1: String  // 最浅色
    let level2: String
    let level3: String
    let level4: String
    let level5: String
    let level6: String
    let level7: String  // 最深色
    
    /// 获取指定层级的颜色
    func color(for level: Int, isDark: Bool) -> String {
        // 深色模式时，自动使用较浅的颜色（偏移2个层级）
        let adjustedLevel = isDark ? max(1, level - 2) : level
        
        switch adjustedLevel {
        case 1: return level1
        case 2: return level2
        case 3: return level3
        case 4: return level4
        case 5: return level5
        case 6: return level6
        case 7: return level7
        default: return level5  // 默认使用中间色
        }
    }
}

/// 主题定义
struct TDTheme: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let isBuiltin: Bool
    let colorLevels: TDThemeColorLevel
    let baseColors: TDThemeBaseColors
}
