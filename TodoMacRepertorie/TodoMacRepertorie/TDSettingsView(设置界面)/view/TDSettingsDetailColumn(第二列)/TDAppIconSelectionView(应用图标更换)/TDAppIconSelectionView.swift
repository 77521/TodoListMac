//
//  TDAppIconSelectionView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/6.
//

import SwiftUI

struct TDAppIconSelectionView: View {
    // 主题管理
    @EnvironmentObject private var themeManager: TDThemeManager
    // 设置管理
    @EnvironmentObject private var settingManager: TDSettingManager
    // 侧边栏（用于切到 VIP）
    @EnvironmentObject private var sidebarStore: TDSettingsSidebarStore
    // 用户信息
    @ObservedObject private var userManager = TDUserManager.shared
    // 应用图标管理
    @StateObject private var appIconManager = TDAppIconManager.shared
    
    // VIP 弹窗控制
    @State private var showVipModal = false
    private let vipSubtitleKey = "settings.vip.modal.subtitle.appicon"
    private let vipImageName = "openvip_default_icon"
    
    // 页面标题/副标题/底部文案
    private let pageTitleKey = "settings.appicon.page.title"
    private let pageSubtitleKey = "settings.appicon.page.subtitle"
    private let pageFooterKey = "settings.appicon.page.footer"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // 顶部标题与副标题
                VStack(alignment: .leading, spacing: 6) {
                    Text(pageTitleKey.localized)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(themeManager.titleTextColor)
                    Text(pageSubtitleKey.localized)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.descriptionTextColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                
                // 顶部 Dock 开关分组
                TDSettingsCardContainer {
                    dockIconToggleRow
                    TDSettingsDivider()
                    dockBadgeToggleRow
                }
                
                // 应用图标列表
                ForEach(appIconManager.icons) { icon in
                    TDAppIconRow(
                        icon: icon,
                        isSelected: icon.id == settingManager.appIconId,
                        onTap: { handleTap(icon: icon) }
                    )
                }
                // 底部提示文案
                TDSettingsFooterText(text: pageFooterKey.localized)

            }
            .padding(.horizontal, 18)
            .padding(.vertical, 22)
        }
        // VIP 弹窗
        .overlay {
            TDOpenVipModal(
                isPresented: $showVipModal,
                imageName: vipImageName,
                subtitleKey: vipSubtitleKey
            )
            .environmentObject(themeManager)
            .environmentObject(sidebarStore)
        }
        .onAppear {
            // 同步当前图标与 Dock 开关状态
            appIconManager.syncFromSettings()
        }
        // Dock 显示开关
        .onChange(of: settingManager.showDockIcon) { _, newValue in
            appIconManager.applyDockVisibility(show: newValue)
        }
        // Dock 角标开关
        .onChange(of: settingManager.showDockBadge) { _, _ in
            appIconManager.updateDockBadge(count: nil) // 清空再按需刷新
        }
    }
    
    /// Dock 显示开关行
    private var dockIconToggleRow: some View {
        TDSettingsToggleRow(
            title: "settings.appicon.dock.show_icon".localized,
            isOn: Binding(
                get: { settingManager.showDockIcon },
                set: { settingManager.showDockIcon = $0 }
            )
        )
    }
    
    /// Dock 角标开关行
    private var dockBadgeToggleRow: some View {
        TDSettingsToggleRow(
            title: "settings.appicon.dock.show_badge".localized,
            isOn: Binding(
                get: { settingManager.showDockBadge },
                set: { settingManager.showDockBadge = $0 }
            )
        )
    }
    
    /// 处理图标点击：会员才能切换，非会员弹窗
    private func handleTap(icon: TDAppIconItem) {
        guard icon.id != settingManager.appIconId else { return }
        guard userManager.isVIP else {
            showVipModal = true
            return
        }
        appIconManager.applyIcon(iconId: icon.id)
    }
}

/// 单行应用图标展示
private struct TDAppIconRow: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    let icon: TDAppIconItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // 左侧真实图标预览（优先 Asset 图片，其次颜色块兜底）
                iconPreview
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(icon.titleKey.localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.titleTextColor)
                    Text(icon.descKey.localized)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.descriptionTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isSelected ? themeManager.color(level: 5) : themeManager.descriptionTextColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeManager.backgroundColor)
            )
        }
        .buttonStyle(.plain)
    }
    
    /// 预览色块（背景色 + 白色马头像）
    @ViewBuilder
    private var iconPreview: some View {
        if let imageName = icon.imageName, !imageName.isEmpty, NSImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .scaledToFit()
        } else {
            // 兜底：颜色块 + 白色马头像
            ZStack {
                Color.fromHex(icon.colorHex)
                Image(systemName: "hare.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .padding(12)
            }
        }
    }
}

#Preview {
    TDAppIconSelectionView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
        .environmentObject(TDSettingsSidebarStore.shared)
}

