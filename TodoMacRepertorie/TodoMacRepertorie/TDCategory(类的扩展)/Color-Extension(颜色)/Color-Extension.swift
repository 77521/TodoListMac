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
    
    
    /// 从十六进制字符串创建颜色
//       init(hex: String) {
//           let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//           var int: UInt64 = 0
//           Scanner(string: hex).scanHexInt64(&int)
//           let a, r, g, b: UInt64
//           switch hex.count {
//           case 3: // RGB (12-bit)
//               (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
//           case 6: // RGB (24-bit)
//               (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
//           case 8: // ARGB (32-bit)
//               (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
//           default:
//               (a, r, g, b) = (255, 0, 0, 0)
//           }
//           self.init(
//               .sRGB,
//               red: Double(r) / 255,
//               green: Double(g) / 255,
//               blue: Double(b) / 255,
//               opacity: Double(a) / 255
//           )
//       }
//       
//       /// 获取颜色的半透明版本
//       func withAlpha(_ alpha: Double) -> Color {
//           self.opacity(alpha)
//       }
    
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
}
