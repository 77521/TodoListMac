//
//  TDGeneralSettingsView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/2.
//

import SwiftUI

struct TDGeneralSettingsView: View {
    // 主题管理
    @EnvironmentObject private var themeManager: TDThemeManager
    // 设置数据管理（用于持久化语言 / 主题 / 音效）
    @EnvironmentObject private var settingManager: TDSettingManager
    // 详情管理（预留，如后续需要接口调用）
    private let detailManager = TDSettingsDetailManager.shared
    
    // 语言选择
    @State private var languageSelection: TDLanguage = .system
    // 音效开关
    @State private var enableSound: Bool = false
    // 主题模式
    @State private var themeMode: TDThemeMode = .system

    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                cardContainer {
                    languageRow
                    themedDivider
                    soundRow
                }
                
                cardContainer {
                    themeRow
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
        .onAppear {
            // 初始化状态
            languageSelection = settingManager.language
            enableSound = settingManager.enableSound
            themeMode = settingManager.themeMode
        }
        // 语言变更
        .onChange(of: languageSelection) { _, newValue in
            let finalValue = adjustSystemLanguageIfNeeded(newValue)
            // 回写状态，确保 UI 与实际存储一致
            languageSelection = finalValue
            settingManager.language = finalValue
        }
        // 音效变更
        .onChange(of: enableSound) { _, newValue in
            settingManager.enableSound = newValue
        }
        // 主题变更
        .onChange(of: themeMode) { _, newValue in
            settingManager.themeMode = newValue
        }

    }
    
    // MARK: - 行视图
    private var languageRow: some View {
        HStack {
            Text("settings.general.language".localized)
                .foregroundColor(themeManager.titleTextColor)
            Spacer()
            Picker("", selection: $languageSelection) {
                Text("settings.general.follow_system".localized).tag(TDLanguage.system)
                Text("settings.general.language.chinese".localized).tag(TDLanguage.chinese)
                Text("settings.general.language.english".localized).tag(TDLanguage.english)
            }
            .labelsHidden()
            .pickerStyle(.menu)
//            .tint(themeManager.titleTextColor)
//            .accentColor(themeManager.titleTextColor) // macOS 兼容
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    
    private var soundRow: some View {
        HStack {
            Text("settings.general.sound".localized)
                .foregroundColor(themeManager.titleTextColor)
            Spacer()
            Toggle("", isOn: $enableSound)
                .toggleStyle(.switch)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    
    private var themeRow: some View {
        HStack {
            Text("settings.general.theme".localized)
                .foregroundColor(themeManager.titleTextColor)
            Spacer()
            Picker("", selection: $themeMode) {
                Text("settings.general.follow_system".localized).tag(TDThemeMode.system)
                Text("settings.general.theme.light".localized).tag(TDThemeMode.light)
                Text("settings.general.theme.dark".localized).tag(TDThemeMode.dark)
            }
            .labelsHidden()
            .pickerStyle(.menu)
//            .tint(themeManager.titleTextColor)
//            .accentColor(themeManager.titleTextColor) // macOS 兼容
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    
    // MARK: - 视图辅助
    private var themedDivider: some View {
        Rectangle()
            .fill(themeManager.separatorColor)
            .frame(height: 1)
            .padding(.leading, 0)
    }
    
    private func cardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(themeManager.backgroundColor)
        )
    }
    
    // MARK: - 语言跟随系统兜底
    /// 当选择跟随系统但系统语言不是中/英时，默认用中文
    private func adjustSystemLanguageIfNeeded(_ value: TDLanguage) -> TDLanguage {
        guard value == .system else { return value }
        let preferred = Locale.preferredLanguages.first ?? ""
        let lower = preferred.lowercased()
        let isChinese = lower.contains("zh")
        let isEnglish = lower.contains("en")
        if !isChinese && !isEnglish {
            return .chinese
        }
        return .system
    }
}

#Preview {
    TDGeneralSettingsView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
}
