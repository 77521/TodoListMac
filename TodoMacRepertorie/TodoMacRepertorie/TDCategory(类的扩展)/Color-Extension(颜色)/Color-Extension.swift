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
    
    
    
    /// 将颜色转换为 RGBA 分量（基于苹果色彩理论）
    /// - Returns: 包含红、绿、蓝、透明度的元组
    func toRGBAComponents() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        // 使用 NSColor 的 sRGB 色彩空间，确保颜色转换的一致性
        let nsColor = NSColor(self)
        
        // 转换为 sRGB 色彩空间，这是苹果推荐的标准色彩空间
        guard let sRGBColor = nsColor.usingColorSpace(.sRGB) else {
            // 如果转换失败，使用默认值
            print("⚠️ 颜色转换失败，使用默认值")
            return (0.5, 0.5, 0.5, 1.0)
        }
        
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        
        // 获取 RGBA 分量
        sRGBColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        // 确保值在有效范围内
        r = max(0.0, min(1.0, r))
        g = max(0.0, min(1.0, g))
        b = max(0.0, min(1.0, b))
        a = max(0.0, min(1.0, a))
        
        return (r, g, b, a)
    }

        
    /// 判断颜色是否为浅色（基于苹果色彩理论）
    /// - Returns: true 表示浅色（应使用黑色文字），false 表示深色（应使用白色文字）
    func isLight() -> Bool {
        let components = toRGBAComponents()
        
        // 使用简单的亮度计算（苹果推荐的方法）
        // 基于人眼对不同颜色的敏感度
        let r = components.r
        let g = components.g
        let b = components.b
        
        // 计算感知亮度（苹果标准算法）
        let brightness = (r * 0.299) + (g * 0.587) + (b * 0.114)
        
        // 使用更合理的阈值：0.5 表示中等亮度
        // 大于 0.5 为浅色，小于 0.5 为深色
        return brightness > 0.65
    }

        /// 创建一个更亮的颜色版本（基于苹果色彩理论）
        /// - Parameter amount: 亮度增加量 (0.0 - 1.0)，默认 0.3
        /// - Returns: 更亮的颜色
        func lighter(amount: CGFloat = 0.3) -> Color {
            let components = toRGBAComponents()
            
            // 使用苹果的色彩混合算法
            // 向白色混合，但保持色相和饱和度
//            let mixFactor = min(amount, 0.8) // 限制最大混合比例
            let mixFactor = amount // 不限制混合比例

            let newRed = components.r + (1.0 - components.r) * mixFactor
            let newGreen = components.g + (1.0 - components.g) * mixFactor
            let newBlue = components.b + (1.0 - components.b) * mixFactor
            
            return Color(red: newRed, green: newGreen, blue: newBlue, opacity: components.a)
        }
        
        /// 创建一个更暗的颜色版本（基于苹果色彩理论）
        /// - Parameter amount: 亮度减少量 (0.0 - 1.0)，默认 0.3
        /// - Returns: 更暗的颜色
        func darkened(amount: CGFloat = 0.3) -> Color {
            let components = toRGBAComponents()
            
            // 使用苹果的色彩混合算法
            // 向黑色混合，但保持色相和饱和度
//            let mixFactor = min(amount, 0.8) // 限制最大混合比例
            let mixFactor = amount // 不限制混合比例

            let newRed = components.r * (1.0 - mixFactor)
            let newGreen = components.g * (1.0 - mixFactor)
            let newBlue = components.b * (1.0 - mixFactor)
            
            return Color(red: newRed, green: newGreen, blue: newBlue, opacity: components.a)
        }

}

