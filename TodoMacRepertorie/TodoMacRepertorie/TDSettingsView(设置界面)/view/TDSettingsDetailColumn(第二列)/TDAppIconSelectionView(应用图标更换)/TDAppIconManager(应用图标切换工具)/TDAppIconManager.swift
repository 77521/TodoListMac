//
//  TDAppIconManager.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/6.
//

import Foundation
import SwiftUI
import AppKit

/// 应用图标项
struct TDAppIconItem: Identifiable, Hashable {
    let id: String
    let titleKey: String
    let descKey: String
    let colorHex: String
    /// 预留自定义图片名称（若存在，可直接使用资源图）
    let imageName: String?
}

/// 应用图标管理器
@MainActor
final class TDAppIconManager: ObservableObject {
    static let shared = TDAppIconManager()
    
    /// 可选图标列表（颜色与主题对应）
    @Published private(set) var icons: [TDAppIconItem] = [
        // 约定：imageName 与 id 一致，使用本地 Asset 中对应的 Image Set
        TDAppIconItem(id: "mars_green", titleKey: "settings.appicon.option.mars_green.title", descKey: "settings.appicon.option.mars_green.desc", colorHex: "#11abac", imageName: "mars_green"),
        TDAppIconItem(id: "new_year_red", titleKey: "settings.appicon.option.new_year_red.title", descKey: "settings.appicon.option.new_year_red.desc", colorHex: "#ef655b", imageName: "new_year_red"),
        TDAppIconItem(id: "coral_red", titleKey: "settings.appicon.option.coral_red.title", descKey: "settings.appicon.option.coral_red.desc", colorHex: "#cc3831", imageName: "coral_red"),
        TDAppIconItem(id: "wish_orange", titleKey: "settings.appicon.option.wish_orange.title", descKey: "settings.appicon.option.wish_orange.desc", colorHex: "#ff8b2b", imageName: "wish_orange"),
        TDAppIconItem(id: "grass_blue", titleKey: "settings.appicon.option.grass_blue.title", descKey: "settings.appicon.option.grass_blue.desc", colorHex: "#1490b3", imageName: "grass_blue"),
        TDAppIconItem(id: "peach_pink", titleKey: "settings.appicon.option.peach_pink.title", descKey: "settings.appicon.option.peach_pink.desc", colorHex: "#f96f96", imageName: "peach_pink"),
        TDAppIconItem(id: "classic_blue", titleKey: "settings.appicon.option.classic_blue.title", descKey: "settings.appicon.option.classic_blue.desc", colorHex: "#1968a9", imageName: "classic_blue"),
        TDAppIconItem(id: "premium_gray", titleKey: "settings.appicon.option.premium_gray.title", descKey: "settings.appicon.option.premium_gray.desc", colorHex: "#767676", imageName: "premium_gray"),
        TDAppIconItem(id: "time_ring", titleKey: "settings.appicon.option.time_ring.title", descKey: "settings.appicon.option.time_ring.desc", colorHex: "#09b6c7", imageName: "time_ring")
    ]
    
    /// 记录当前 Dock 角标数字，便于开关切换时恢复
    private var lastBadgeCount: Int?
    
    private init() {}
    
    // MARK: - 对外方法
    
    /// 切换应用图标
    /// - Parameter iconId: 目标图标 ID
    func applyIcon(iconId: String) {
        guard let item = icons.first(where: { $0.id == iconId }) else { return }
        // 生成/获取 NSImage
        let iconImage = makeIconImage(for: item)
        NSApplication.shared.applicationIconImage = iconImage
        // 存储选中
        TDSettingManager.shared.appIconId = iconId
    }
    
    /// 根据当前设置恢复图标
    func syncFromSettings() {
        applyIcon(iconId: TDSettingManager.shared.appIconId)
        applyDockVisibility(show: TDSettingManager.shared.showDockIcon)
        updateDockBadge(count: lastBadgeCount)
    }
    
    /// Dock 图标显示/隐藏
    func applyDockVisibility(show: Bool) {
        // 切换 ActivationPolicy，默认 .regular 显示，.accessory 隐藏 Dock 图标
        let policy: NSApplication.ActivationPolicy = show ? .regular : .accessory
        NSApp.setActivationPolicy(policy)
        if show {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    /// 更新 Dock 角标
    /// - Parameter count: 今天未完成数量（nil 代表不显示数字，只清空）
    func updateDockBadge(count: Int?) {
        lastBadgeCount = count
        guard TDSettingManager.shared.showDockBadge else {
            NSApp.dockTile.badgeLabel = nil
            return
        }
        if let count, count > 0 {
            NSApp.dockTile.badgeLabel = "\(count)"
        } else {
            NSApp.dockTile.badgeLabel = nil
        }
    }
    
    // MARK: - 内部工具
    
    /// 获取应用图标图像：只使用本地 Asset 图，禁止代码生成
    private func makeIconImage(for item: TDAppIconItem) -> NSImage {
        // 只允许使用本地 Asset；如果未找到，兜底使用当前应用图标
        if let imageName = item.imageName, let img = NSImage(named: imageName) {
            return img
        }
        return NSApplication.shared.applicationIconImage ?? NSImage()
    }
}

private extension Color {
    /// 转换为 NSColor，兜底灰色
    var nsColor: NSColor {
        return NSColor(self)
    }
}

