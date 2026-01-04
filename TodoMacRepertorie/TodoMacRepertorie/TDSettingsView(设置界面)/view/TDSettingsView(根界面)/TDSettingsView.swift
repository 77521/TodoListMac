//
//  TDSettingsView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/12/5.
//

import SwiftUI

struct TDSettingsView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var settingManager: TDSettingManager
    @EnvironmentObject private var sidebarStore: TDSettingsSidebarStore
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    private let sidebarWidth: CGFloat = 240

    var body: some View {
        ZStack {
            TDVisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .overlay(Color.black.opacity(settingManager.isDarkMode ? 0.35 : 0.08))
                .ignoresSafeArea()
            
            
            NavigationSplitView(columnVisibility: $columnVisibility) {
                TDSidebarSettingsColumn()
                    .frame(minWidth: sidebarWidth, maxWidth: sidebarWidth)
                    .navigationSplitViewColumnWidth(min: sidebarWidth, ideal: sidebarWidth,max: sidebarWidth)
                    .ignoresSafeArea(edges: .top)
            } detail: {
                detailContent
                    .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                    .background(themeManager.secondaryBackgroundColor)
                    .ignoresSafeArea(edges: .top)
//                    .background(
//                        TDVisualEffectView(material: .underWindowBackground, blendingMode: .withinWindow)
//                            .overlay(Color.black.opacity(0.04))
//                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
//                    )
//                    .padding(.horizontal, 24)
//                    .padding(.vertical, 24)
            }
            .navigationSplitViewStyle(.balanced)
            .frame(minWidth: 700, minHeight: 700)
            .ignoresSafeArea(.container, edges: .all)
        }
        .onAppear {
            sidebarStore.TDPrepareSidebarDataIfNeeded()
        }
    }
    
    // MARK: - 右侧详情内容
    @ViewBuilder
    private var detailContent: some View {
        // 当前选中的侧边栏 item
        let selected = sidebarStore.selectedItemId
        switch selected {
        case .accountSecurity:
            TDAccountSecurityView()
        case .general:
            TDGeneralSettingsView()
        default:
            TDSettingsPlaceholderColumn()
        }
    }

}


private struct TDSettingsPlaceholderColumn: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "macwindow")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(themeManager.descriptionTextColor)
            
            Text("settings.detail.placeholder.title".localized)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeManager.titleTextColor)
            
            Text("settings.detail.placeholder.subtitle".localized)
                .font(.system(size: 14))
                .foregroundColor(themeManager.descriptionTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            TDVisualEffectView(material: .underWindowBackground, blendingMode: .withinWindow)
                .overlay(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
    }
}

#Preview {
    TDSettingsView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
        .environmentObject(TDSettingsSidebarStore.shared)
        .frame(width: 900, height: 600)
}
