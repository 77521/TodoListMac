//
//  TDUserInfoView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import AppKit

struct TDUserInfoView: View {
    @StateObject private var userManager = TDUserManager.shared
    @ObservedObject private var themeManager = TDThemeManager.shared
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack(spacing: 8) {
            TDHeaderImageView(avatarURL: userManager.avatarURL, userId: userManager.userId)

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
            
            // 设置菜单按钮
            // 设置菜单按钮
            Menu {
                // 显示手机号或账号（作为菜单标题）
                let displayText = getDisplayText()
                Text(displayText)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.titleTextColor)
                    .disabled(true)
                
                Divider()
                
                // 设置
                Button(action: {
                    TDSettingsWindowTracker.shared.presentSettingsWindow(using: openWindow)
                }) {
                    Text("user.menu.settings".localized)
                }
                
                // 反馈与建议
                Button(action: {
                    openFeedbackEmail()
                }) {
                    Text("user.menu.feedback".localized)
                }
                
                // 白马学院
                Button(action: {
                    if let url = URL(string: "https://www.evetech.top") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("user.menu.academy".localized)
                }
                
                // 关于
                Button(action: {
                    NSApplication.shared.orderFrontStandardAboutPanel(nil)
                }) {
                    Text("user.menu.about".localized)
                }
                
                Divider()
                
                // 退出登录
                Button(action: {
                    handleLogout()
                }) {
                    Text("user.menu.logout".localized)
                }
            } label: {
                Image(systemName: "gear")
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 16))
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()

        }
        .padding(.vertical, 8)  // 添加垂直内边距
    }
    
    // MARK: - 获取显示文本（手机号或账号）
    private func getDisplayText() -> String {
        if let phoneNumber = userManager.currentUser?.phoneNumber, phoneNumber > 0 {
            // 使用掩码格式显示手机号
            return String.maskedPhoneNumber(from: phoneNumber) ?? String(phoneNumber)
        }
        return userManager.currentUser?.userAccount ?? userManager.account
    }
    
    // MARK: - 打开反馈邮箱
    private func openFeedbackEmail() {
        let recipient = "contact@evestudio.cn"
        let userName = userManager.nickname
        let userId = String(userManager.userId)
        // 获取手机号或账号（用于主题）
        let phoneOrAccount: String
        if let phoneNumber = userManager.currentUser?.phoneNumber, phoneNumber > 0 {
            phoneOrAccount = String(phoneNumber)
        } else {
            phoneOrAccount = userManager.currentUser?.userAccount ?? userManager.account
        }
        let version = getAppVersion()
        
        let subject = "[Todo清单] 客服支持 (\(userName)/\(userId)/\(phoneOrAccount)/true/Mac/\(version))"
        let body = "Hi Todo清单，"
        
        // 构建 mailto URL
        var components = URLComponents(string: "mailto:\(recipient)")
        components?.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        
        if let url = components?.url {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - 获取应用版本号
    private func getAppVersion() -> String {
        let info = Bundle.main.infoDictionary
        let version = (info?["CFBundleShortVersionString"] as? String) ?? "1.0"
        let build = (info?["CFBundleVersion"] as? String) ?? "1"
        return "\(version) (\(build))"
    }
    
    // MARK: - 处理退出登录
    private func handleLogout() {
        Task { @MainActor in
            await TDSettingsDetailManager.shared.logout()
        }
    }

}

#Preview {
    TDUserInfoView()
}
