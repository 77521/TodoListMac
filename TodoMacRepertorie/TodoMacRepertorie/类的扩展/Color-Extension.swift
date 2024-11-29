//
//  Color-Extension.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/7/16.
//

import Foundation
import SwiftUI
import SwiftDate
import DynamicColor

/// 主题颜色
extension Color {
    
    
    /// 16进制颜色调整 带透明度的 透明度参数 在前后 都可以
    /// - Parameter hexString: 传进来的颜色字符串
    /// - Returns: 返回的颜色
    static func fromHex(_ hexString: String) -> Color {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        switch hex.count {
        case 8:
            // 先尝试按 AARRGGBB 格式解析
            let alpha = CGFloat((int & 0xFF000000) >> 24) / 255
            let red = CGFloat((int & 0x00FF0000) >> 16) / 255
            let green = CGFloat((int & 0x0000FF00) >> 8) / 255
            let blue = CGFloat(int & 0x000000FF) / 255
            
            // 如果解析出的颜色值看起来合理，就使用 AARRGGBB 格式
            if alpha <= 1.0 && red <= 1.0 && green <= 1.0 && blue <= 1.0 {
                return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
            }
            
            // 否则尝试 RRGGBBAA 格式
            let r = CGFloat((int & 0xFF000000) >> 24) / 255
            let g = CGFloat((int & 0x00FF0000) >> 16) / 255
            let b = CGFloat((int & 0x0000FF00) >> 8) / 255
            let a = CGFloat(int & 0x000000FF) / 255
            return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
            
        case 6: // RRGGBB
            let red = CGFloat((int & 0xFF0000) >> 16) / 255
            let green = CGFloat((int & 0x00FF00) >> 8) / 255
            let blue = CGFloat(int & 0x0000FF) / 255
            return Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
            
        default:
            return Color.gray
        }
    }
    
//    /// 主题颜色
//    /// - Parameter i: 主题颜色色号
//    /// - Returns: 返回的主题颜色
//    static func themeColor(i: Int) -> Color {
//        Color("\(SettingDataManager.themeColor)\(i)")
//    }
//    
//    
//    
//    /// 主题颜色 手动填充颜色名字
//    /// - Parameters:
//    ///   - themeString: 主题颜色名字
//    ///   - i: 主题颜色 色号
//    /// - Returns: 返回的主题颜色
//    static func themeColor(themeString: String , i: Int) -> Color {
//        Color("\(themeString)\(i)")
//    }
//    
//    
//    /// 字体颜色
//    /// - Parameter i: 字体颜色 色号
//    /// - Returns: 返回的字体颜色
//    static func themeLabelColor(i: Int) -> Color {
//        Color("LabelColor\(i)")
//    }
//    
//    /// 背景颜色
//    /// - Parameter i: 背景颜色 色号
//    /// - Returns: 返回的背景颜色
//    static func themeBackGroundColor(i: Int) -> Color {
//        Color("backgroundColor\(i)")
//    }
}


/// 主题颜色
extension Date {
    /// 时间戳转时间
    /// - Parameters:
    ///   - timeInterval: 时间戳
    ///   - format: 日期格式
    /// - Returns: 返回的日期
    static func timeIntervalForString(timeInterval: TimeInterval, format:String) -> String {
        let date = Date(timeIntervalSince1970: timeInterval / 1000)
        let formatter = DateFormatter()
        return date.toFormat(format, locale: Locale.current)

    }
    
    
    
}




// 主题定义
struct TDTheme: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var colors: TDThemeColors
    var isDark: Bool
    
    init(id: UUID = UUID(), name: String, colors: TDThemeColors, isDark: Bool = false) {
        self.id = id
        self.name = name
        self.colors = colors
        self.isDark = isDark
    }
}

// 主题颜色配置
struct TDThemeColors: Codable, Equatable {
    var primary: TDDynamicColor // 主要标题颜色
    var secondary: TDDynamicColor // 副标题颜色
    var background: TDDynamicColor // 背景色
    var surface: TDDynamicColor
    var text: TDDynamicColor
    var subtext: TDDynamicColor
}

// 动态颜色（深浅色模式）
struct TDDynamicColor: Codable, Equatable {
    var light: String
    var dark: String
    
    func color(for scheme: ColorScheme) -> Color {
        Color(TDSettingManager.shared.followSystem ? scheme == .dark ? dark : light : light)
    }
}

// 预设主题
extension TDTheme {
    // 默认蓝色主题
    static let `default` = TDTheme(
        name: "默认蓝",
        colors: TDThemeColors(
            primary: TDDynamicColor(light: "#007AFF", dark: "#0A84FF"),
            secondary: TDDynamicColor(light: "#5856D6", dark: "#6E6CD4"),
            background: TDDynamicColor(light: "#FFFFFF", dark: "#1C1C1E"),
            surface: TDDynamicColor(light: "#F2F2F7", dark: "#2C2C2E"),
            text: TDDynamicColor(light: "#000000", dark: "#FFFFFF"),
            subtext: TDDynamicColor(light: "#666666", dark: "#EBEBF5")
        )
    )
    
    // 暗夜主题
    static let dark = TDTheme(
        name: "暗夜黑",
        colors: TDThemeColors(
            primary: TDDynamicColor(light: "#FFFFFF", dark: "#FFFFFF"),
            secondary: TDDynamicColor(light: "#CCCCCC", dark: "#CCCCCC"),
            background: TDDynamicColor(light: "#000000", dark: "#000000"),
            surface: TDDynamicColor(light: "#1C1C1E", dark: "#1C1C1E"),
            text: TDDynamicColor(light: "#FFFFFF", dark: "#FFFFFF"),
            subtext: TDDynamicColor(light: "#CCCCCC", dark: "#CCCCCC")
        ),
        isDark: true
    )
    
    // 自然绿主题
    static let green = TDTheme(
        name: "自然绿",
        colors: TDThemeColors(
            primary: TDDynamicColor(light: "#34C759", dark: "#30D158"),
            secondary: TDDynamicColor(light: "#32D74B", dark: "#30DB5B"),
            background: TDDynamicColor(light: "#F0FFF0", dark: "#1A2E1A"),
            surface: TDDynamicColor(light: "#E1FFE1", dark: "#2A3E2A"),
            text: TDDynamicColor(light: "#006633", dark: "#FFFFFF"),
            subtext: TDDynamicColor(light: "#4A8C4A", dark: "#A5D6A7")
        )
    )
    
    // 紫色主题
    static let purple = TDTheme(
        name: "优雅紫",
        colors: TDThemeColors(
            primary: TDDynamicColor(light: "#BF5AF2", dark: "#C377E0"),
            secondary: TDDynamicColor(light: "#AF52DE", dark: "#BF5AF2"),
            background: TDDynamicColor(light: "#F5F0FF", dark: "#2B1B3B"),
            surface: TDDynamicColor(light: "#EBE0FF", dark: "#3B2B4B"),
            text: TDDynamicColor(light: "#4B0082", dark: "#FFFFFF"),
            subtext: TDDynamicColor(light: "#6A1B9A", dark: "#CE93D8")
        )
    )
    
    // 获取所有预设主题
    static var presets: [TDTheme] {
        [.default, .dark, .green, .purple]
    }
}

