//
//  TDThemeManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import Foundation
import SwiftUI

/// 主题管理器
@MainActor
class TDThemeManager: ObservableObject {
    static let shared = TDThemeManager()
    
    // MARK: - AppStorage
    @AppStorage("td_selected_theme_id") private var selectedThemeId: String = "mars_green"
    
    // MARK: - Published
    @Published private(set) var themes: [TDTheme] = []
    
    /// 当前主题
    var currentTheme: TDTheme {
        (themes + Self.defaultThemes).first { $0.id == selectedThemeId } ?? Self.defaultThemes[0]
    }
    
    /// 基础文字颜色配置（使用普通灰主题色）
    private static let baseTextColors = TDThemeBaseColors(
        background: TDDynamicColor(light: "#FFFFFF", dark: "#111111"),
        secondaryBackground: TDDynamicColor(light: "#F5F4F5", dark: "#111111"),
        primaryText: TDDynamicColor(light: "#303030", dark: "#F5F4F5"),
        secondaryText: TDDynamicColor(light: "#AAAAAA", dark: "#797979"),
        descriptionText: TDDynamicColor(light: "#A0A0A0", dark: "#797979"),
        separator: TDDynamicColor(light: "#F5F4F5", dark: "#111111"),
        border: TDDynamicColor(light: "#C3C3C3", dark: "#4F4F4F")
    )
    
    // MARK: - 预设主题
    static let defaultThemes: [TDTheme] = [
        // 马尔斯绿（默认主题）
        TDTheme(
            id: "mars_green",
            name: "马尔斯绿",
            isBuiltin: true,
            colorLevels: TDThemeColorLevel(
                level1: "#90c7e4e4",
                level2: "#c7e4e4",
                level3: "#7edadb",
                level4: "#32bebf",
                level5: "#11abac",
                level6: "#018f90",
                level7: "#016d6e"
            ),
            baseColors: baseTextColors
        ),
        // 新年红
        TDTheme(
            id: "new_year_red",
            name: "新年红",
            isBuiltin: true,
            colorLevels: TDThemeColorLevel(
                level1: "#90f2d7d5",
                level2: "#f2d7d5",
                level3: "#f6aba6",
                level4: "#f28a82",
                level5: "#ef655b",
                level6: "#d8473d",
                level7: "#b73228"
            ),
            baseColors: baseTextColors
        ),
        // 珊瑚红
        TDTheme(
            id: "coral_red",
            name: "珊瑚红",
            isBuiltin: true,
            colorLevels: TDThemeColorLevel(
                level1: "#90e7d1ce",
                level2: "#eec9c7",
                level3: "#e79591",
                level4: "#df5c56",
                level5: "#cc3831",
                level6: "#ba2720",
                level7: "#a0130c"
            ),
            baseColors: baseTextColors
        ),
        // 心想事橙
        TDTheme(
            id: "wish_orange",
            name: "心想事橙",
            isBuiltin: true,
            colorLevels: TDThemeColorLevel(
                level1: "#90f1e6dd",
                level2: "#f1e6dd",
                level3: "#f2b888",
                level4: "#f49a4f",
                level5: "#ff8b2b",
                level6: "#e47215",
                level7: "#c55a02"
            ),
            baseColors: baseTextColors
        ),
        // 千草蓝
        TDTheme(
            id: "grass_blue",
            name: "千草蓝",
            isBuiltin: true,
            colorLevels: TDThemeColorLevel(
                level1: "#90cae1e7",
                level2: "#cae1e7",
                level3: "#87cfe3",
                level4: "#40aac9",
                level5: "#1490b3",
                level6: "#007698",
                level7: "#005c77"
            ),
            baseColors: baseTextColors
        ),
        // 经典蓝
        TDTheme(
            id: "classic_blue",
            name: "经典蓝",
            isBuiltin: true,
            colorLevels: TDThemeColorLevel(
                level1: "#90cfdce7",
                level2: "#cfdce7",
                level3: "#6ea9da",
                level4: "#2e7ab9",
                level5: "#1968a9",
                level6: "#08528e",
                level7: "#014176"
            ),
            baseColors: baseTextColors
        ),
        // 高级灰
        TDTheme(
            id: "premium_gray",
            name: "高级灰",
            isBuiltin: true,
            colorLevels: TDThemeColorLevel(
                level1: "#90d1d1d1",
                level2: "#d1d1d1",
                level3: "#afafaf",
                level4: "#8f8f8f",
                level5: "#767676",
                level6: "#5e5e5e",
                level7: "#434343"
            ),
            baseColors: baseTextColors
        ),
        // 桃桃粉
        TDTheme(
            id: "peach_pink",
            name: "桃桃粉",
            isBuiltin: true,
            colorLevels: TDThemeColorLevel(
                level1: "#90f7e0e6",
                level2: "#f7e0e6",
                level3: "#f6b0c3",
                level4: "#e685a0",
                level5: "#f96f96",
                level6: "#eb5f87",
                level7: "#d5416b"
            ),
            baseColors: baseTextColors
        )
    ]
    
    private init() {
        loadThemes()
    }
    
    // MARK: - 主题管理
    
    /// 切换主题
    func switchTheme(to themeId: String) {
        guard (themes + Self.defaultThemes).contains(where: { $0.id == themeId }) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedThemeId = themeId
            objectWillChange.send()
        }
    }
    
    /// 添加新主题
    func addTheme(_ theme: TDTheme) {
        guard !themes.contains(where: { $0.id == theme.id }) else { return }
        themes.append(theme)
        saveThemes()
    }
    
    /// 删除主题
    func deleteTheme(_ themeId: String) {
        // 内置主题不能删除
        guard let theme = themes.first(where: { $0.id == themeId }),
              !theme.isBuiltin else { return }
        
        themes.removeAll { $0.id == themeId }
        saveThemes()
        
        // 如果删除的是当前主题，切换到默认主题
        if selectedThemeId == themeId {
            switchTheme(to: Self.defaultThemes[0].id)
        }
    }
    
    /// 退出登录时重置主题
    func resetToDefaultTheme() {
        if selectedThemeId != "mars_green" {
            switchTheme(to: "mars_green")
        }
    }
    
    // MARK: - 颜色获取
    
    /// 获取指定层级的颜色
    func color(level: Int) -> Color {
        let isDark = TDSettingManager.shared.isDarkMode
        let hexColor = currentTheme.colorLevels.color(for: level, isDark: isDark)
        return Color.fromHex(hexColor)
    }
    
    /// 获取背景色
    var backgroundColor: Color {
        currentTheme.baseColors.background.color(isDark: TDSettingManager.shared.isDarkMode)
    }
    
    /// 获取次要背景色
    var secondaryBackgroundColor: Color {
        currentTheme.baseColors.secondaryBackground.color(isDark: TDSettingManager.shared.isDarkMode)
    }
    
    /// 获取主要文字颜色
    var primaryTextColor: Color {
        currentTheme.baseColors.primaryText.color(isDark: TDSettingManager.shared.isDarkMode)
    }
    
    /// 获取次要文字颜色
    var secondaryTextColor: Color {
        currentTheme.baseColors.secondaryText.color(isDark: TDSettingManager.shared.isDarkMode)
    }
    
    /// 获取描述文字颜色
    var descriptionTextColor: Color {
        currentTheme.baseColors.descriptionText.color(isDark: TDSettingManager.shared.isDarkMode)
    }
    
    /// 获取分割线颜色
    var separatorColor: Color {
        currentTheme.baseColors.separator.color(isDark: TDSettingManager.shared.isDarkMode)
    }
    
    /// 获取边框颜色
    var borderColor: Color {
        currentTheme.baseColors.border.color(isDark: TDSettingManager.shared.isDarkMode)
    }
    
    // MARK: - 持久化存储
    
    /// 主题文件URL
    private var themesFileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appSupportURL = documentsDirectory.appendingPathComponent("TodoList", isDirectory: true)
        
        // 确保目录存在
        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        
        return appSupportURL.appendingPathComponent("custom_themes.json")
    }
    
    /// 加载保存的主题
     func loadThemes() {
        if let data = try? Data(contentsOf: themesFileURL),
           let decoded = try? JSONDecoder().decode([TDTheme].self, from: data) {
            themes = decoded
        }
    }
    
    /// 保存自定义主题
    private func saveThemes() {
        if let encoded = try? JSONEncoder().encode(themes) {
            try? encoded.write(to: themesFileURL)
        }
    }
}
