//
//  TDLoginItemManager.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/21.
//

import Foundation
import ServiceManagement

/// 开机自启动管理（基于 SMAppService.mainApp，仅 macOS 13+ 可用）
final class TDLoginItemManager: ObservableObject {
    static let shared = TDLoginItemManager()
    
    @Published private(set) var isEnabled: Bool = false
    
    private init() {
        refreshStatus()
    }
    
    var isSupported: Bool {
        if #available(macOS 13.0, *) {
            return true
        }
        return false
    }
    
    /// 读取当前状态（主线程调用）
    func refreshStatus() {
        guard isSupported else {
            isEnabled = false
            return
        }
        if #available(macOS 13.0, *) {
            isEnabled = (SMAppService.mainApp.status == .enabled)
        }
    }
    
    /// 切换开机自启
    func setEnabled(_ enabled: Bool) throws {
        guard isSupported else {
            throw TDLoginItemError.notSupported
        }
        if #available(macOS 13.0, *) {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            isEnabled = enabled
        }
    }
    
    enum TDLoginItemError: Error {
        case notSupported
    }
}
