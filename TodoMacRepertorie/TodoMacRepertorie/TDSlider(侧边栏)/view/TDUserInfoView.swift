//
//  TDUserInfoView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI

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
            
            // 设置按钮
            Button(action: {
                // 设置按钮点击事件
                TDSettingsWindowTracker.shared.presentSettingsWindow(using: openWindow)
            }) {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 14))
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()

        }
        .padding(.vertical, 8)  // 添加垂直内边距
    }
}

#Preview {
    TDUserInfoView()
}
