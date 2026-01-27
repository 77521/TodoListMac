//
//  TDOpenVipModal.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/6.
//

import SwiftUI

/// VIP 开通弹窗（只包含顶部图片、大标题、副标题、立即开通按钮）
struct TDOpenVipModal: View {
    // 主题管理（控制颜色）
    @EnvironmentObject private var themeManager: TDThemeManager
    // 左侧设置栏（用于切到“高级会员”）
    @EnvironmentObject private var sidebarStore: TDSettingsSidebarStore
    // 打开新窗口的动作（用来唤起设置窗口）
    @Environment(\.openWindow) private var openWindow
    
    /// 是否展示弹窗
    @Binding var isPresented: Bool
    /// 顶部图片名称（默认图：openvip_default_icon；可传特定图，如 openvip_theme_icon）
    let imageName: String
    /// 副标题对应的国际化 key（外部传入）
    let subtitleKey: String
    
    var body: some View {
        if isPresented {
            ZStack {
                // 半透明背景，点击关闭
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }
                
                // 弹窗主体
                modalContent
                    .frame(maxWidth: 420)
            }
            .transition(.opacity.combined(with: .scale))
            .animation(.easeInOut(duration: 0.2), value: isPresented)
            .zIndex(2000)
        }
    }
    
    /// 弹窗内容：图片 + 标题 + 副标题 + CTA
    private var modalContent: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Image(imageName.isEmpty ? "openvip_default_icon" : imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                
                // 右上角关闭按钮（避免只能开通不能关闭）
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.35))
                        )
                }
                .buttonStyle(.plain)
                .padding(12)
            }

            // 文案与按钮区
            VStack(spacing: 16) {
                // 大标题（写死文案，但走国际化）
                Text("settings.vip.modal.title".localized)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeManager.titleTextColor)
                    .multilineTextAlignment(.center)
                
                // 副标题（外部传入 key，国际化后展示）
                Text(subtitleKey.localized)
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.descriptionTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
                
                // 立即开通按钮
                Button(action: handleUpgrade) {
                    Text("settings.vip.modal.cta".localized)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(themeManager.color(level: 5))
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(themeManager.backgroundColor)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(themeManager.backgroundColor)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(themeManager.borderColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 22, x: 0, y: 12)
    }
    
    /// 处理“立即开通”：唤起设置窗口并切到“高级会员”选项
    private func handleUpgrade() {
        // 1）先关闭弹窗
        isPresented = false
        // 2）唤起/前置设置窗口
        TDSettingsWindowTracker.shared.presentSettingsWindow(using: openWindow)
        // 3）切换到左侧“高级会员”栏目
        sidebarStore.TDHandleSettingSelection(.premium)
    }
}

#Preview {
    TDOpenVipModal(
        isPresented: .constant(true),
        imageName: "openvip_default_icon",
        subtitleKey: "settings.vip.modal.subtitle.theme"
    )
    .environmentObject(TDThemeManager.shared)
    .environmentObject(TDSettingsSidebarStore.shared)
}
