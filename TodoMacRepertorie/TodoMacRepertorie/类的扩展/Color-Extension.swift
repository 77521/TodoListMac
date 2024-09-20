//
//  Color-Extension.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/7/16.
//

import Foundation
import SwiftUI

/// 主题颜色
extension Color {
    
    
    /// 主题颜色
    /// - Parameter i: 主题颜色色号
    /// - Returns: 返回的主题颜色
    static func themeColor(i: Int) -> Color {
        Color("\(SettingDataManager.themeColor)\(i)")
    }
    
    
    
    /// 主题颜色 手动填充颜色名字
    /// - Parameters:
    ///   - themeString: 主题颜色名字
    ///   - i: 主题颜色 色号
    /// - Returns: 返回的主题颜色
    static func themeColor(themeString: String , i: Int) -> Color {
        Color("\(themeString)\(i)")
    }
    
    
    /// 字体颜色
    /// - Parameter i: 字体颜色 色号
    /// - Returns: 返回的字体颜色
    static func themeLabelColor(i: Int) -> Color {
        Color("LabelColor\(i)")
    }
    
    /// 背景颜色
    /// - Parameter i: 背景颜色 色号
    /// - Returns: 返回的背景颜色
    static func themeBackGroundColor(i: Int) -> Color {
        Color("backgroundColor\(i)")
    }
}


