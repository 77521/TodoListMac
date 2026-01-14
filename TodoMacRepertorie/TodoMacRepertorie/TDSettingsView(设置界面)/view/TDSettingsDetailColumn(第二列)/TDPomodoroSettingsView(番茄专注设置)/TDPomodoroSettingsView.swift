//
//  TDPomodoroSettingsView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/9.
//

import SwiftUI

/// 番茄专注设置页：左侧切换到“番茄专注”时显示
struct TDPomodoroSettingsView: View {
    /// 主题管理器：用于文本/分割线/背景颜色
    @EnvironmentObject private var themeManager: TDThemeManager
    /// 设置管理器：统一读写番茄专注相关配置
    @EnvironmentObject private var settingManager: TDSettingManager
    
    /// 专注/休息时长候选（5~120 分钟，步长 1）
    private let durationOptions = Array(5...120)
    
    /// 番茄工作法指南链接
    private let pomodoroGuideURL = URL(string: "https://https7ny.evestudio.cn/TodoList%20Tomato%20Guide%20720p.mp4")!
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                TDSettingsCardContainer {
                    VStack(spacing: 0) {
                        // 番茄时长
                        durationRow(
                            title: "settings.pomodoro.focus_duration".localized,
                            selection: Binding(
                                get: { settingManager.focusDuration },
                                set: { settingManager.focusDuration = min(max($0, 5), 120) }
                            ),
                            labelBuilder: { value in
                                "\(value)\("common.minutes".localized)"
                            }
                        )
                        TDSettingsDivider()
                        // 休息时长
                        durationRow(
                            title: "settings.pomodoro.rest_duration".localized,
                            selection: Binding(
                                get: { settingManager.restDuration },
                                set: { settingManager.restDuration = min(max($0, 5), 120) }
                            ),
                            labelBuilder: { value in
                                "\(value)\("common.minutes".localized)"
                            }
                        )
                        TDSettingsDivider()
                        
                        // 专注时屏幕常亮
                        TDSettingsToggleRow(
                            title: "settings.pomodoro.keep_screen_on".localized,
                            isOn: Binding(
                                get: { settingManager.focusKeepScreenOn },
                                set: { settingManager.focusKeepScreenOn = $0 }
                            )
                        )
                        TDSettingsDivider()
                        // 推送通知
                        TDSettingsToggleRow(
                            title: "settings.pomodoro.push_notification".localized,
                            isOn: Binding(
                                get: { settingManager.focusPushEnabled },
                                set: { settingManager.focusPushEnabled = $0 }
                            )
                        )
                        // 说明文案
                        TDSettingsFooterText(text: "settings.pomodoro.push_notification.desc".localized)
                            .padding(.top, 2)
                        TDSettingsDivider()
                        // 播放完成提示音
                        TDSettingsToggleRow(
                            title: "settings.pomodoro.play_finish_sound".localized,
                            isOn: Binding(
                                get: { settingManager.focusPlayFinishSound },
                                set: { settingManager.focusPlayFinishSound = $0 }
                            )
                        )
                    }
                }
                
                // 第二组：学习链接
                TDSettingsCardContainer {
                    Button {
                        NSWorkspace.shared.open(pomodoroGuideURL)
                    } label: {
                        HStack {
                            Text("settings.pomodoro.learn".localized)
                                .foregroundColor(themeManager.titleTextColor)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(themeManager.descriptionTextColor)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 50)
        }
    }
    
    // MARK: - 行视图构造
    /// 可复用的时长选择行（自定义胶囊宽度）
    private func durationRow(
        title: String,
        selection: Binding<Int>,
        labelBuilder: @escaping (Int) -> String
    ) -> some View {
        HStack {
            Text(title)
                .foregroundColor(themeManager.titleTextColor)
            Spacer()
            Picker("", selection: selection) {
                ForEach(durationOptions, id: \.self) { value in
                    Text(labelBuilder(value)).tag(value)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: pillWidth(for: labelBuilder(selection.wrappedValue)))
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    
    /// 计算文本宽度，保证 Picker 胶囊长度与当前文案匹配
    private func pillWidth(for text: String) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 13, weight: .regular)
        let size = (text as NSString).size(withAttributes: [.font: font])
        let padding: CGFloat = 18 + 15 // 左右总 padding
        let minWidth: CGFloat = 64
        let maxWidth: CGFloat = 200
        return min(max(size.width + padding, minWidth), maxWidth)
    }
}

#Preview {
    TDPomodoroSettingsView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
}

