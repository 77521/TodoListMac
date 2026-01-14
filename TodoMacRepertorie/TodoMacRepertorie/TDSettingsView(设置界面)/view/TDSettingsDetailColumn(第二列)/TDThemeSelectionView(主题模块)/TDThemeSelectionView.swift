//
//  TDThemeSelectionView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/5.
//

import SwiftUI

/// 主题颜色选择界面
struct TDThemeSelectionView: View {
    // 主题管理
    @EnvironmentObject private var themeManager: TDThemeManager
    // 用户信息（用于判断是否会员）
    @ObservedObject private var userManager = TDUserManager.shared
    
    // 控制 VIP 弹窗展示
    @State private var showVipModal: Bool = false
    // 弹窗副标题 key（根据场景传递国际化 key）
    @State private var vipSubtitleKey: String = "settings.vip.modal.subtitle.theme"
    // 弹窗顶部图片名称（默认或场景图）
    @State private var vipImageName: String = "openvip_default_icon"

    
    /// 所有可用主题（自定义 + 内置，按 ID 去重）
    private var allThemes: [TDTheme] {
        var visited = Set<String>()
        return (themeManager.themes + TDThemeManager.defaultThemes).filter { theme in
            guard !visited.contains(theme.id) else { return false }
            visited.insert(theme.id)
            return true
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                
                ForEach(allThemes) { theme in
                    TDThemeOptionRow(
                        theme: theme,
                        isSelected: theme.id == themeManager.currentTheme.id,
                        displayName: localizedName(for: theme),
                        description: localizedDescription(for: theme),
                        colorSample: Color.fromHex(theme.colorLevels.color(for: 5, isDark: false))
                    ) {
                        handleThemeTap(theme)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 22)
        }
        // VIP 弹窗覆盖层
        .overlay {
            TDOpenVipModal(
                isPresented: $showVipModal,
                imageName: vipImageName,
                subtitleKey: vipSubtitleKey
            )
            .environmentObject(themeManager)
            .environmentObject(TDSettingsSidebarStore.shared)
        }

    }
    
    /// 顶部说明区域：标题 + 副标题 + 会员提示
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("settings.theme.page.title".localized)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(themeManager.titleTextColor)
            
            Text("settings.theme.page.subtitle".localized)
                .font(.system(size: 13))
                .foregroundColor(themeManager.descriptionTextColor)
            
//            // 会员提示，提前说明切换限制
//            HStack(spacing: 8) {
//                Image(systemName: "crown.fill")
//                    .font(.system(size: 14, weight: .semibold))
//                    .foregroundColor(themeManager.color(level: 5))
//                Text("settings.theme.vip_hint".localized)
//                    .font(.system(size: 12))
//                    .foregroundColor(themeManager.descriptionTextColor)
//                Spacer()
//            }
//            .padding(.horizontal, 12)
//            .padding(.vertical, 10)
//            .background(
//                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                    .fill(themeManager.color(level: 1).opacity(0.4))
//            )
        }
    }
    
    /// 处理主题点击：会员才能切换，非会员预留弹窗逻辑
    private func handleThemeTap(_ theme: TDTheme) {
        // 已选中的主题直接返回
        guard theme.id != themeManager.currentTheme.id else { return }
        
        // 非会员拦截
        guard userManager.isVIP else {
            // TODO: 非会员点击时弹出升级会员弹窗
            // 设置弹窗参数：传递主题场景的图片和副标题 key
            vipImageName = "openvip_theme_icon"
            vipSubtitleKey = "settings.vip.modal.subtitle.theme"
            // 展示 VIP 弹窗
            showVipModal = true

            return
        }
        
        // 会员允许切换主题
        themeManager.switchTheme(to: theme.id)
    }
    
    /// 主题名国际化，找不到时回退到主题自带名称
    private func localizedName(for theme: TDTheme) -> String {
        let key = "settings.theme.option.\(theme.id).name"
        let value = key.localized
        return value == key ? theme.name : value
    }
    
    /// 主题描述国际化，找不到时返回空字符串
    private func localizedDescription(for theme: TDTheme) -> String {
        let key = "settings.theme.option.\(theme.id).desc"
        let value = key.localized
        return value == key ? "" : value
    }
}

/// 单行主题展示卡片
private struct TDThemeOptionRow: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    
    let theme: TDTheme
    let isSelected: Bool
    let displayName: String
    let description: String
    let colorSample: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 14) {
                // 主题色块
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorSample)
                    .frame(width: 64, height: 64)
                
                // 标题与描述
                VStack(alignment: .leading, spacing: 6) {
                    Text(displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.titleTextColor)
                    if !description.isEmpty {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.descriptionTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
                
                // 选中状态
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isSelected ? themeManager.color(level: 5) : themeManager.descriptionTextColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeManager.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                isSelected ? themeManager.color(level: 5).opacity(0.4) : themeManager.borderColor.opacity(0.4),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TDThemeSelectionView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
}
