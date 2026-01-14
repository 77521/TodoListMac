//
//  TDGeneralModulesView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/4.
//

import SwiftUI

struct TDGeneralModulesView: View {
    // 主题管理
    @EnvironmentObject private var themeManager: TDThemeManager
    // 设置数据管理（用于持久化开关）
    @EnvironmentObject private var settingManager: TDSettingManager
    
    // 番茄专注模块开关
    @State private var enableTomato: Bool = true
    // 日程概览模块开关
    @State private var enableSchedule: Bool = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // 第一组：番茄专注模块
                TDSettingsCardContainer {
                    TDSettingsToggleRow(
                        title: "settings.general.tomato.title".localized,
                        isOn: $enableTomato
                    )
                }
                // 组尾文案
                TDSettingsFooterText(text: "settings.general.tomato.footer".localized)
                    .padding(.top,-7)
                
                // 第二组：日程概览模块
                TDSettingsCardContainer {
                    TDSettingsToggleRow(
                        title: "settings.general.schedule.title".localized,
                        isOn: $enableSchedule
                    )
                }
                // 组尾文案
                TDSettingsFooterText(text: "settings.general.schedule.footer".localized)
                    .padding(.top,-7)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 50)
        }
        .onAppear {
            // 初始化：从设置管理器读取开关状态（如无存储，可按需替换实际字段）
            enableTomato = settingManager.enableTomatoFocus
            enableSchedule = settingManager.enableScheduleOverview
        }
        .onChange(of: enableTomato) { _, newValue in
            settingManager.enableTomatoFocus = newValue
        }
        .onChange(of: enableSchedule) { _, newValue in
            settingManager.enableScheduleOverview = newValue
            TDSliderBarViewModel.shared.rebuildForSettingsChange()
        }
    }
    
}


#Preview {
    TDGeneralModulesView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
}
