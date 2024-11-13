//
//  TDSettingManager.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/5.
//

import Foundation
import SwiftUI


class TDAppSettings: ObservableObject {
    static let shared = TDAppSettings()
    
    //  主题颜色模式是否跟随系统
    @AppStorage("themeFollowSystem") var followSystem: Bool = true 
//    
//    // 当前外观模式
//    @AppStorage("isDarkMode") var isDarkMode: Bool = false {
//        didSet {
//            if !followSystem {
//                updateAppearance()
//            }
//        }
//    }
    
//    private init() {
//        // 初始化时设置外观
//        updateAppearance()
//    }
//    
//    // 更新应用外观
//    private func updateAppearance() {
//        if followSystem {
//            NSApp.appearance = nil // 跟随系统
//        } else {
//            NSApp.appearance = NSAppearance(named: isDarkMode ? .darkAqua : .aqua)
//        }
//    }
}

