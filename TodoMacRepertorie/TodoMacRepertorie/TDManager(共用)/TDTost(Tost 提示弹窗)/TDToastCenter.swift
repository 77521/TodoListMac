//
//  TDToastCenter.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/9.
//

import SwiftUI

/// 全局 Toast 中心（可观察单例）
final class TDToastCenter: ObservableObject {
    static let shared = TDToastCenter()
    @Published var isPresenting: Bool = false
    @Published var isSettingPresenting: Bool = false

    @Published var message: String = ""
    @Published var type: TDToastType = .regular
    // 默认底部显示
    @Published var position: TDToastPosition = .bottom
    
    /// 便捷触发全局 Toast（覆盖式重触发）
    func show(_ message: String, type: TDToastType = .regular, position: TDToastPosition = .bottom) {
        DispatchQueue.main.async {
            self.message = message
            self.type = type
            self.position = position
            // 覆盖式重触发，避免重复消息不显示
//            self.isPresenting = false
            self.isPresenting = true
        }
    }
    
    /// 便捷触发全局 Toast（覆盖式重触发）
    func td_settingShow(_ message: String, type: TDToastType = .regular, position: TDToastPosition = .bottom) {
        DispatchQueue.main.async {
            self.message = message
            self.type = type
            self.position = position
            // 覆盖式重触发，避免重复消息不显示
//            self.isPresenting = false
            self.isSettingPresenting = true
        }
    }

}
