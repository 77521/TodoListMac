//
//  TDThemeManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import Foundation
import SwiftUI

/// 主题管理器
class TDThemeManager: ObservableObject {
    static let shared = TDThemeManager()
    // 使用 App Group 的 UserDefaults
    private let sharedDefaults: UserDefaults

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
        primaryBackground: TDDynamicColor(light: "#FFFFFF", dark: "#000000"),
        secondaryBackground: TDDynamicColor(light: "#F5F4F5", dark: "#111111"),
        tertiaryBackground: TDDynamicColor(light: "#F5F4F5", dark: "#303030"),
        
        titleText: TDDynamicColor(light: "#303030", dark: "#F5F4F5"),
        descriptionText: TDDynamicColor(light: "#AAAAAA", dark: "#797979"),
        subtaskText: TDDynamicColor(light: "#595959", dark: "#F5F4F5"),
        
        titleFinishText: TDDynamicColor(light: "#AAAAAA", dark: "#797979"),
        descriptionFinishText: TDDynamicColor(light: "#AAAAAA", dark: "#797979"),
        subtaskFinishText: TDDynamicColor(light: "#B3B3B3", dark: "#AAAAAA"),
        
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
        
        // 初始化 App Group 的 UserDefaults
        guard let sharedDefaults = UserDefaults(suiteName:TDAppConfig.appGroupId) else {
            fatalError("无法初始化 App Group UserDefaults")
        }
        self.sharedDefaults = sharedDefaults
        
        // 从 App Group 加载主题 ID
        if let savedThemeId = sharedDefaults.string(forKey: "td_selected_theme_id") {
            selectedThemeId = savedThemeId
        }
        
        loadThemes()
    }
    
    // MARK: - 主题管理
    
    /// 切换主题
    func switchTheme(to themeId: String) {
        guard (themes + Self.defaultThemes).contains(where: { $0.id == themeId }) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedThemeId = themeId
            // 同步到 App Group
            sharedDefaults.set(themeId, forKey: "td_selected_theme_id")
            sharedDefaults.synchronize()
            objectWillChange.send()
        }
    }
   
    /// 添加新主题
//    func addTheme(_ theme: TDTheme) {
//        guard !themes.contains(where: { $0.id == theme.id }) else { return }
//        themes.append(theme)
//        saveThemes()
//    }
    /// 添加新主题
    func addTheme(_ theme: TDTheme) {
        guard !themes.contains(where: { $0.id == theme.id }) else { return }
        themes.append(theme)
        saveThemes()
        // 通知小组件更新
//        NotificationCenter.default.post(name: .themeDidChange, object: nil)
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
        // 通知小组件更新
//        NotificationCenter.default.post(name: .themeDidChange, object: nil)
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
    
    /// 获取指定主题的指定层级颜色（完全固定，不受主题和模式影响）
    /// 用于需要固定颜色的UI元素，如"过期未达成"分组始终使用新年红
    func fixedColor(themeId: String, level: Int) -> Color {
        // 查找指定主题
        let allThemes = themes + Self.defaultThemes
        guard let theme = allThemes.first(where: { $0.id == themeId }) else {
            // 如果找不到指定主题，返回当前主题的颜色
            return color(level: level)
        }
        
        // 始终使用浅色模式的颜色，确保颜色完全固定
        let hexColor = theme.colorLevels.color(for: level, isDark: false)
        return Color.fromHex(hexColor)
    }
    
    /// 获取主题颜色
    private func themeColor(_ keyPath: KeyPath<TDThemeBaseColors, TDDynamicColor>) -> Color {
        currentTheme.baseColors[keyPath: keyPath].color(isDark: TDSettingManager.shared.isDarkMode)
    }

    /// 获取一级背景色
    var backgroundColor: Color {
        themeColor(\.primaryBackground)
    }
    
    /// 获取二级背景色
    var secondaryBackgroundColor: Color {
        themeColor(\.secondaryBackground)
    }
    
    /// 获取三级背景色
    var tertiaryBackgroundColor: Color {
        themeColor(\.tertiaryBackground)
    }
    
    /// 获取标题文字颜色
    var titleTextColor: Color {
        themeColor(\.titleText)
    }
    
    /// 获取描述文字颜色
    var descriptionTextColor: Color {
        themeColor(\.descriptionText)
    }
    
    /// 获取子任务文字颜色
    var subtaskTextColor: Color {
        themeColor(\.subtaskText)
    }
    
    /// 获取标题已完成颜色
    var titleFinishTextColor: Color {
        themeColor(\.titleFinishText)
    }
    
    /// 获取描述已完成颜色
    var descriptionFinishTextColor: Color {
        themeColor(\.descriptionFinishText)
    }
    
    /// 获取子任务已完成颜色
    var subtaskFinishTextColor: Color {
        themeColor(\.subtaskFinishText)
    }
    
    /// 获取分割线颜色
    var separatorColor: Color {
        themeColor(\.separator)
    }
    
    /// 获取边框颜色
    var borderColor: Color {
        themeColor(\.border)
    }
    
    /// 获取选中背景颜色
    var selectedBackgroundColor: Color {
        // 使用主题色的浅色版本作为选中背景
        color(level: 1).opacity(0.3)
    }

    
    // MARK: - 持久化存储
    
    /// 主题文件URL
    private var themesFileURL: URL {
        guard let url = TDAppConfig.themesFileURL else {
            fatalError("无法获取主题文件 URL")
        }
        return url
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
    
    
    // MARK: - 设置界面扩展色值
    
    /// 设置行默认图标背景（用于缺省的圆角方块）
    var settingsIconDefaultBackgroundHex: String {
        TDSettingManager.shared.isDarkMode ? "#2F2F31" : "#E8EAED"
    }
    
    /// 设置行默认图标前景色
    var settingsIconDefaultForegroundHex: String {
        TDSettingManager.shared.isDarkMode ? "#F5F5F5" : "#1C1C1E"
    }

    
}
