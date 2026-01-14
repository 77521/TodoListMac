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
    @State private var previousLanguage: TDLanguage = .system
    @State private var showSystemLanguageAlert = false
    // 悬停与展开状态用于自定义样式
    @State private var isLanguageHover = false

    // 音效开关
    @State private var enableSound: Bool = false
    // 主题模式
    @State private var themeMode: TDThemeMode = .system
    @State private var isThemeHover = false

    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                TDSettingsCardContainer {
                    languageRow

                    TDSettingsDivider()
                    TDSettingsToggleRow(
                        title: "settings.general.sound".localized,
                        isOn: $enableSound
                    )

                }
                
                TDSettingsCardContainer {
                   themeRow

                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 50) // 原10 + 顶部额外15
        }
        .onAppear {
            // 初始化状态
            languageSelection = settingManager.language
            previousLanguage = settingManager.language
            enableSound = settingManager.enableSound
            themeMode = settingManager.themeMode
        }
        // 语言变更
        .onChange(of: languageSelection) { _, newValue in
            let finalValue = adjustSystemLanguageIfNeeded(newValue)
            // 回写状态，确保 UI 与实际存储一致
            // 若选择“跟随系统”，提示需重登
            if finalValue == .system && settingManager.language != .system {
                previousLanguage = settingManager.language
                showSystemLanguageAlert = true
                return
            }
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
        // 更改语言需重登提示
        .alert("settings.general.language.relogin.title".localized, isPresented: $showSystemLanguageAlert) {
            Button("common.cancel".localized) {
                // 恢复原语言
                languageSelection = previousLanguage
            }
            Button("common.confirm".localized) {
                Task {
                    settingManager.language = .system
                    await detailManager.logout()
                }
            }
        }

    }
    
//    // MARK: - 行视图
    private var languageRow: some View {
        HStack(spacing: 12) {
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
                .frame(width: pillWidth(for: currentLanguageLabel))
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
                .toggleStyle(ThemedSwitchToggleStyle(onColor: themeManager.color(level: 5)))

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
            .frame(width: pillWidth(for: currentThemeLabel))
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
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
    
    // 当前语言显示文案
    private var currentLanguageLabel: String {
        switch languageSelection {
        case .system:
            return "settings.general.follow_system".localized
        case .chinese:
            return "settings.general.language.chinese".localized
        case .english:
            return "settings.general.language.english".localized
        }
    }
    
    // 当前主题显示文案
    private var currentThemeLabel: String {
        switch themeMode {
        case .system:
            return "settings.general.follow_system".localized
        case .light:
            return "settings.general.theme.light".localized
        case .dark:
            return "settings.general.theme.dark".localized
        }
    }
    
    /// 计算文本宽度，保证胶囊长度与文字匹配，设置上下限
    private func pillWidth(for text: String) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 13, weight: .regular)
        let size = (text as NSString).size(withAttributes: [.font: font])
        let padding: CGFloat = 18 + 15// 左右总 padding
        let minWidth: CGFloat = 64
        let maxWidth: CGFloat = 200
        return min(max(size.width + padding, minWidth), maxWidth)
    }


}

#Preview {
    TDGeneralSettingsView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
}
