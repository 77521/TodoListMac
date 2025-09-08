//
//  Color-Extension.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI

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
    
    /// 将颜色转换为十六进制字符串
    func toHexString() -> String {
        guard let color = NSColor(self).usingColorSpace(.sRGB) else { return "#000000" }
        return String(format: "#%02X%02X%02X",
                      Int(color.redComponent * 255),
                      Int(color.greenComponent * 255),
                      Int(color.blueComponent * 255))
    }
    
    /// 获取颜色的反色
    func inverted() -> Color {
        guard let components = NSColor(self).cgColor.components else { return self }
        return Color(red: 1 - components[0], green: 1 - components[1], blue: 1 - components[2])
    }
    
    /// 根据夜间/白天模式返回不同的颜色
    /// - Parameters:
    ///   - lightModeColor: 白天模式的16进制颜色值
    ///   - darkModeColor: 夜间模式的16进制颜色值
    /// - Returns: 根据当前模式返回对应的颜色
    static func adaptive(light lightModeColor: String, dark darkModeColor: String) -> Color {
        // 使用 TDSettingManager 中的 isDarkMode 属性
        if TDSettingManager.shared.isDarkMode {
            return Color.fromHex(darkModeColor)
        } else {
            return Color.fromHex(lightModeColor)
        }
    }

}
