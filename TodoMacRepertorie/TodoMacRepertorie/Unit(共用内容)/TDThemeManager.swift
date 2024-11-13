//
//  TDThemeManager.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/5.
//

import Foundation
import SwiftUI

// 主题管理器
class TDThemeManager: ObservableObject {
    static let shared = TDThemeManager()
    
    @AppStorage("selectedThemeId") private var selectedThemeId: String?
    @AppStorage("followSystem") var followSystem: Bool = true
    
    @Published private(set) var themes: [TDTheme] = []
    @Published private(set) var currentTheme: TDTheme
    
    private init() {
        // 初始化为默认主题
        self.currentTheme = .default
        
        // 加载保存的主题
        loadThemes()
        
        // 恢复选中的主题
        if let id = selectedThemeId,
           let saved = (themes + TDTheme.presets).first(where: { $0.id.uuidString == id }) {
            self.currentTheme = saved
        }
    }
    
    // MARK: - 主题管理
    func addTheme(_ theme: TDTheme) {
        themes.append(theme)
        saveThemes()
    }
    
    func deleteTheme(_ theme: TDTheme) {
        themes.removeAll { $0.id == theme.id }
        saveThemes()
        
        if currentTheme.id == theme.id {
            setTheme(.default)
        }
    }
    
    func setTheme(_ theme: TDTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
            selectedThemeId = theme.id.uuidString
        }
    }
    
    // MARK: - 持久化存储
    private func loadThemes() {
        if let data = UserDefaults.standard.data(forKey: "savedThemes"),
           let decoded = try? JSONDecoder().decode([TDTheme].self, from: data) {
            themes = decoded
        }
    }
    
    private func saveThemes() {
        if let encoded = try? JSONEncoder().encode(themes) {
            UserDefaults.standard.set(encoded, forKey: "savedThemes")
        }
    }
}
