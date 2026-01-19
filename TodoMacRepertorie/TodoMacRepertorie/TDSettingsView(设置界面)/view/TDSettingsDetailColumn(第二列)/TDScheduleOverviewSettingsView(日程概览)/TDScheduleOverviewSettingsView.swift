//
//  TDScheduleOverviewSettingsView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/9.
//

import SwiftUI

/// 日程概览设置页（左侧第一栏切换到“日程概览”时显示）
struct TDScheduleOverviewSettingsView: View {
    /// 主题管理器（控制文字、分隔线、背景色）
    @EnvironmentObject private var themeManager: TDThemeManager
    /// 设置管理器（统一持久化所有开关/枚举）
    @EnvironmentObject private var settingManager: TDSettingManager
    
    /// Picker 选项：条目背景色（工作量/清单颜色）
    private let backgroundOptions: [(String, TDTaskBackgroundMode)] = [
        ("settings.schedule.background.workload".localized, .workload),
        ("settings.schedule.background.category".localized, .category)
    ]
    /// Picker 选项：清单颜色识别（仅当背景色选择“清单颜色”时展示）
    private let colorRecognitionOptions: [(String, TDCalendarTaskColorRecognition)] = [
        ("settings.schedule.color_recognition.auto".localized, .auto),
        ("settings.schedule.color_recognition.black".localized, .black),
        ("settings.schedule.color_recognition.white".localized, .white)
    ]
    /// Picker 选项：文字大小（对应 TDFontSize 枚举）
    private let fontSizeOptions: [(String, TDFontSize)] = [
        ("settings.schedule.font_size.small".localized, .size9),
        ("settings.schedule.font_size.default".localized, .size10),
        ("settings.schedule.font_size.large".localized, .size11),
        ("settings.schedule.font_size.xlarge".localized, .size12)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                TDSettingsCardContainer {
                    VStack(spacing: 0) {
                        // 条目背景色
                        HStack {
                            Text("settings.schedule.background".localized)
                                .foregroundColor(themeManager.titleTextColor)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { settingManager.calendarTaskBackgroundMode },
                                set: { settingManager.calendarTaskBackgroundMode = $0 }
                            )) {
                                ForEach(backgroundOptions, id: \.1) { item in
                                    Text(item.0).tag(item.1)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: pillWidth(for: currentBackgroundLabel))
                            .fixedSize(horizontal: true, vertical: false)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                        
                        TDSettingsDivider()
                        
                        // 当背景色选择“清单颜色”时，展示颜色识别方式
                        if settingManager.calendarTaskBackgroundMode == .category {
                            HStack {
                                Text("settings.schedule.color_recognition".localized)
                                    .foregroundColor(themeManager.titleTextColor)
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { settingManager.calendarTaskColorRecognition },
                                    set: { settingManager.calendarTaskColorRecognition = $0 }
                                )) {
                                    ForEach(colorRecognitionOptions, id: \.1) { item in
                                        Text(item.0).tag(item.1)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(width: pillWidth(for: currentColorRecognitionLabel))
                                .fixedSize(horizontal: true, vertical: false)
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                            
                            TDSettingsDivider()
                        }
                        
                        // 文字大小
                        HStack {
                            Text("settings.schedule.font_size".localized)
                                .foregroundColor(themeManager.titleTextColor)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { settingManager.fontSize },
                                set: { settingManager.fontSize = $0 }
                            )) {
                                ForEach(fontSizeOptions, id: \.1) { item in
                                    Text(item.0).tag(item.1)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: pillWidth(for: currentFontSizeLabel))
                            .fixedSize(horizontal: true, vertical: false)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                        
                        TDSettingsDivider()
                        
                        // 显示已完成事件
                        TDSettingsToggleRow(
                            title: "settings.event.show_completed".localized,
                            isOn: Binding(
                                get: { settingManager.showCompletedTasks },
                                set: { settingManager.showCompletedTasks = $0 }
                            )
                        )
                        
                        TDSettingsDivider()
                        
                        // 已完成事件删除线
                        TDSettingsToggleRow(
                            title: "settings.event.show_completed_strikethrough".localized,
                            isOn: Binding(
                                get: { settingManager.calendarShowCompletedSeparator },
                                set: { settingManager.calendarShowCompletedSeparator = $0 }
                            )
                        )
                        
                        TDSettingsDivider()
                        
                        // 最后一行显示剩余数量
                        TDSettingsToggleRow(
                            title: "settings.schedule.remaining_count".localized,
                            isOn: Binding(
                                get: { settingManager.calendarShowRemainingCount },
                                set: { settingManager.calendarShowRemainingCount = $0 }
                            )
                        )
                        
                        TDSettingsDivider()
                        
                        // 显示农历
                        TDSettingsToggleRow(
                            title: "settings.schedule.show_lunar".localized,
                            isOn: Binding(
                                get: { settingManager.showLunarCalendar },
                                set: { settingManager.showLunarCalendar = $0 }
                            )
                        )
                    }
                }
                
                // 第二组：分享/隐私
                VStack(spacing: 4) {
                    TDSettingsCardContainer {
//                        VStack(spacing: 0) {
//                            // 分享是否展示全部事件（数据保存，供后续分享逻辑使用）
//                            TDSettingsToggleRow(
//                                title: "settings.schedule.share_show_all".localized,
//                                isOn: Binding(
//                                    get: { settingManager.scheduleShareShowAllEvents },
//                                    set: { settingManager.scheduleShareShowAllEvents = $0 }
//                                )
//                            )
//                            TDSettingsDivider()
                            // 隐私晒图模式
                            TDSettingsToggleRow(
                                title: "settings.schedule.privacy_mode".localized,
                                isOn: Binding(
                                    get: { settingManager.isPrivacyModeEnabled },
                                    set: { settingManager.isPrivacyModeEnabled = $0 }
                                )
                            )
//                        }
                    }
                    TDSettingsFooterText(text: "settings.schedule.privacy_mode.desc".localized)

                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 50)
        }
    }
    
    // MARK: - 当前选中文案（用于动态宽度）
    private var currentBackgroundLabel: String {
        switch settingManager.calendarTaskBackgroundMode {
        case .workload:
            return "settings.schedule.background.workload".localized
        case .category:
            return "settings.schedule.background.category".localized
        }
    }
    
    private var currentColorRecognitionLabel: String {
        switch settingManager.calendarTaskColorRecognition {
        case .auto:
            return "settings.schedule.color_recognition.auto".localized
        case .black:
            return "settings.schedule.color_recognition.black".localized
        case .white:
            return "settings.schedule.color_recognition.white".localized
        }
    }
    
    private var currentFontSizeLabel: String {
        switch settingManager.fontSize {
        case .size9:
            return "settings.schedule.font_size.small".localized
        case .size10:
            return "settings.schedule.font_size.default".localized
        case .size11:
            return "settings.schedule.font_size.large".localized
        case .size12:
            return "settings.schedule.font_size.xlarge".localized
        }
    }
    
    /// 计算文本宽度，保证 Picker 胶囊长度与当前选项匹配
    private func pillWidth(for text: String) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 13, weight: .regular)
        let size = (text as NSString).size(withAttributes: [.font: font])
        let padding: CGFloat = 18 + 18 // 左右总 padding
        let minWidth: CGFloat = 64
        let maxWidth: CGFloat = 200
        return min(max(size.width + padding, minWidth), maxWidth)
    }
}


#Preview {
    TDScheduleOverviewSettingsView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
}
