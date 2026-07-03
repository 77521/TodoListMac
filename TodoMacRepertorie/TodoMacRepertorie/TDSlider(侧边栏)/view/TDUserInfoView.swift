//
//  TDUserInfoView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import AppKit

/// 侧边栏顶部用户信息视图（头像 + 昵称 + 账号）
/// 设置按钮已移至标题栏工具栏区域（TDSliderBarView .toolbar{}），与设计稿一致。
struct TDUserInfoView: View {
    @StateObject private var userManager = TDUserManager.shared
    @ObservedObject private var themeManager = TDThemeManager.shared

    var body: some View {
        HStack(spacing: 8) {
            TDHeaderImageView(
                avatarURL: userManager.avatarURL,
                userId: userManager.userId,
                nickname: userManager.nickname
            )

            VStack(alignment: .leading, spacing: 0) {
                Text(userManager.nickname)
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 12))
                    .lineLimit(1)
                
                Text(userManager.account)
                    .foregroundColor(themeManager.descriptionTextColor)
                    .font(.system(size: 12))
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
}

// MARK: - 侧边栏标题栏设置菜单（用于 .toolbar{}）
/// 放在标题栏工具栏区域的 ⚙ 设置菜单，与设计稿中按钮位置保持一致。
struct TDSidebarSettingsMenu: View {
    @StateObject private var userManager = TDUserManager.shared
    @ObservedObject private var themeManager = TDThemeManager.shared
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Menu {
            // 当前登录账号（手机号或邮箱，作为菜单标题信息）
            Text(displayText)
                .font(.system(size: 12))
                .disabled(true)

            Divider()

            Button("user.menu.settings".localized) {
                TDSettingsWindowTracker.shared.presentSettingsWindow(using: openWindow)
            }

            Button("user.menu.feedback".localized) {
                openFeedbackEmail()
            }

            Button("user.menu.academy".localized) {
                if let url = URL(string: "https://www.evetech.top") {
                    NSWorkspace.shared.open(url)
                }
            }

            Button("user.menu.about".localized) {
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
            }

            Divider()

            Button("user.menu.logout".localized) {
                Task { @MainActor in
                    await TDSettingsDetailManager.shared.logout()
                }
            }
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.primary)
        }
        // 在 overlay 上下文（非 system toolbar）中，borderlessButton 只渲染图标，无胶囊背景
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    // MARK: - 私有辅助

    /// 优先显示掩码手机号，否则显示账号
    private var displayText: String {
        if let phone = userManager.currentUser?.phoneNumber, phone > 0 {
            return String.maskedPhoneNumber(from: phone) ?? String(phone)
        }
        return userManager.currentUser?.userAccount ?? userManager.account
    }

    private func openFeedbackEmail() {
        let recipient = "contact@evestudio.cn"
        let name = userManager.nickname
        let uid = String(userManager.userId)
        let phoneOrAccount: String
        if let phone = userManager.currentUser?.phoneNumber, phone > 0 {
            phoneOrAccount = String(phone)
        } else {
            phoneOrAccount = userManager.currentUser?.userAccount ?? userManager.account
        }
        let info = Bundle.main.infoDictionary
        let ver = (info?["CFBundleShortVersionString"] as? String) ?? "1.0"
        let build = (info?["CFBundleVersion"] as? String) ?? "1"
        let version = "\(ver) (\(build))"
        let subject = "[Todo清单] 客服支持 (\(name)/\(uid)/\(phoneOrAccount)/true/Mac/\(version))"
        var components = URLComponents(string: "mailto:\(recipient)")
        components?.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: "Hi Todo清单，")
        ]
        if let url = components?.url { NSWorkspace.shared.open(url) }
    }
}

#Preview {
    TDUserInfoView()
}
