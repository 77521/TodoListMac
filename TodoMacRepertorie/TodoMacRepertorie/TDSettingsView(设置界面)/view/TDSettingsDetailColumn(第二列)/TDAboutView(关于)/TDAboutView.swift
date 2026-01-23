//
//  TDAboutView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/21.
//

import SwiftUI

/// 设置 - 关于界面（单独页面，固定文案，不需要国际化）
struct TDAboutView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    
    /// 版本号 + Build（形如 1.0.0 (100)）
    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = (info?["CFBundleShortVersionString"] as? String) ?? "1.0"
        let build = (info?["CFBundleVersion"] as? String) ?? "1"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Logo
            Image("mars_green")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            // 标题
            Text("Todo 清单")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeManager.titleTextColor)
            
            // 版本号
            Text(versionText)
                .font(.system(size: 13))
                .foregroundColor(themeManager.descriptionTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
        .background(themeManager.secondaryBackgroundColor)
    }
}

#Preview {
    TDAboutView()
        .environmentObject(TDThemeManager.shared)
}

