//
//  TDUniversalSettingsView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/21.
//

import SwiftUI

/// 设置 - 通用（目前仅开机自启动）
struct TDUniversalSettingsView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var settingManager: TDSettingManager
    
    @ObservedObject private var loginItemManager = TDLoginItemManager.shared
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                
                TDSettingsCardContainer {
                    HStack {
                        Text("settings.universal.auto_launch.title".localized)
                            .foregroundColor(themeManager.titleTextColor)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { loginItemManager.isEnabled },
                            set: { newValue in toggleAutoLaunch(newValue) }
                        ))
                        .disabled(!loginItemManager.isSupported || isProcessing)
                            .toggleStyle(ThemedSwitchToggleStyle(onColor: themeManager.color(level: 5)))
                    }
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                
                if !loginItemManager.isSupported {
                    Text("settings.universal.auto_launch.unsupported".localized)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.descriptionTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 22)
        }
        .onAppear {
            loginItemManager.refreshStatus()
        }
    }
    
    // MARK: - 头部说明
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("settings.universal.header.title".localized)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(themeManager.titleTextColor)
            
            Text("settings.universal.header.subtitle".localized)
                .font(.system(size: 13))
                .foregroundColor(themeManager.descriptionTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Actions
    private func toggleAutoLaunch(_ enabled: Bool) {
        guard loginItemManager.isSupported else { return }
        isProcessing = true
        errorMessage = nil
        do {
            try loginItemManager.setEnabled(enabled)
        } catch {
            loginItemManager.refreshStatus() // revert
            errorMessage = "settings.universal.auto_launch.failed".localized
        }
        isProcessing = false
    }
}

#Preview {
    TDUniversalSettingsView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
}
