//
//  TDScheduleMoreMenu.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/11.
//

import SwiftUI

/// 日程更多菜单组件
struct TDScheduleMoreMenu: View {
    /// 主题管理器
    @EnvironmentObject private var themeManager: TDThemeManager
    
    /// 设置管理器
    @EnvironmentObject private var settingManager: TDSettingManager

    /// 日程概览视图模型（用于切换月/周视图）
    @EnvironmentObject private var viewModel: TDScheduleOverviewViewModel
    
    var body: some View {
        Menu {
            // 0. 月/周视图切换（第一个，且可展开）
            Menu {
                Button(action: {
                    viewModel.displayMode = .month
                    settingManager.scheduleOverviewDefaultDisplayMode = .month
                }) {
                    HStack {
                        Text("schedule.overview.view_mode.month".localized)
                            .font(.system(size: TDAppConfig.menuFontSize))
                        Spacer()
                        if viewModel.displayMode == .month {
                            Image(systemName: "checkmark")
                                .font(.system(size: TDAppConfig.menuIconSize))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }

                Button(action: {
                    viewModel.displayMode = .week
                    settingManager.scheduleOverviewDefaultDisplayMode = .week
                }) {
                    HStack {
                        Text("schedule.overview.view_mode.week".localized)
                            .font(.system(size: TDAppConfig.menuFontSize))
                        Spacer()
                        if viewModel.displayMode == .week {
                            Image(systemName: "checkmark")
                                .font(.system(size: TDAppConfig.menuIconSize))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
            } label: {
                Text("schedule.overview.view_mode".localized)
                    .font(.system(size: 14))
            }

            // 下划线分割（和其他可展开项的视觉层级一致）
            Divider()

            // 1. 条目背景色
            Menu {
                Button(action: {
                    settingManager.calendarTaskBackgroundMode = .workload
                }) {
                    HStack {
                        Text("settings.schedule.background.workload".localized)
                            .font(.system(size: TDAppConfig.menuFontSize))
                        Spacer()
                        if settingManager.calendarTaskBackgroundMode == .workload {
                            Image(systemName: "checkmark")
                                .font(.system(size: TDAppConfig.menuIconSize))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
                
                Button(action: {
                    settingManager.calendarTaskBackgroundMode = .category
                }) {
                    HStack {
                        Text("settings.schedule.background.category".localized)
                            .font(.system(size: TDAppConfig.menuFontSize))
                        Spacer()
                        if settingManager.calendarTaskBackgroundMode == .category {
                            Image(systemName: "checkmark")
                                .font(.system(size: TDAppConfig.menuIconSize))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
            } label: {
                Text("settings.schedule.background".localized)
                    .font(.system(size: 14))
            }

            
            // 2. 清单颜色识别（仅当条目背景色为清单颜色时显示）
            if settingManager.calendarTaskBackgroundMode == .category {
                Menu {
                    Button(action: {
                        settingManager.calendarTaskColorRecognition = .auto
                    }) {
                        HStack {
                            Text("settings.schedule.color_recognition.auto".localized)
                                .font(.system(size: TDAppConfig.menuFontSize))
                            Spacer()
                            if settingManager.calendarTaskColorRecognition == .auto {
                                Image(systemName: "checkmark")
                                    .font(.system(size: TDAppConfig.menuIconSize))
                                    .foregroundColor(themeManager.color(level: 5))
                            }
                        }
                    }
                    
                    Button(action: {
                        settingManager.calendarTaskColorRecognition = .black
                    }) {
                        HStack {
                            Text("settings.schedule.color_recognition.black".localized)
                                .font(.system(size: TDAppConfig.menuFontSize))
                            Spacer()
                            if settingManager.calendarTaskColorRecognition == .black {
                                Image(systemName: "checkmark")
                                    .font(.system(size: TDAppConfig.menuIconSize))
                                    .foregroundColor(themeManager.color(level: 5))
                            }
                        }
                    }
                    
                    Button(action: {
                        settingManager.calendarTaskColorRecognition = .white
                    }) {
                        HStack {
                            Text("settings.schedule.color_recognition.white".localized)
                                .font(.system(size: TDAppConfig.menuFontSize))
                            Spacer()
                            if settingManager.calendarTaskColorRecognition == .white {
                                Image(systemName: "checkmark")
                                    .font(.system(size: TDAppConfig.menuIconSize))
                                    .foregroundColor(themeManager.color(level: 5))
                            }
                        }
                    }
                } label: {
                    Text("settings.schedule.color_recognition".localized)
                        .font(.system(size: 14))
                }
            }

            // 3. 字体大小
            Menu {
                Button(action: {
                    settingManager.fontSize = .size9
                }) {
                    HStack {
                        Text("settings.schedule.font_size.small".localized)
                            .font(.system(size: TDAppConfig.menuFontSize))
                        Spacer()
                        if settingManager.fontSize == .size9 {
                            Image(systemName: "checkmark")
                                .font(.system(size: TDAppConfig.menuIconSize))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
                
                Button(action: {
                    settingManager.fontSize = .size10
                }) {
                    HStack {
                        Text("settings.schedule.font_size.default".localized)
                            .font(.system(size: TDAppConfig.menuFontSize))
                        Spacer()
                        if settingManager.fontSize == .size10 {
                            Image(systemName: "checkmark")
                                .font(.system(size: TDAppConfig.menuIconSize))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
                
                Button(action: {
                    settingManager.fontSize = .size11
                }) {
                    HStack {
                        Text("settings.schedule.font_size.large".localized)
                            .font(.system(size: TDAppConfig.menuFontSize))
                        Spacer()
                        if settingManager.fontSize == .size11 {
                            Image(systemName: "checkmark")
                                .font(.system(size: TDAppConfig.menuIconSize))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
                
                Button(action: {
                    settingManager.fontSize = .size12
                }) {
                    HStack {
                        Text("settings.schedule.font_size.xlarge".localized)
                            .font(.system(size: TDAppConfig.menuFontSize))
                        Spacer()
                        if settingManager.fontSize == .size12 {
                            Image(systemName: "checkmark")
                                .font(.system(size: TDAppConfig.menuIconSize))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
            } label: {
                Text("settings.schedule.font_size".localized)
                    .font(.system(size: 14))
            }

            
            Divider()
            
            // 4. 显示已完成事件删除线
            Button(action: {
                settingManager.calendarShowCompletedSeparator.toggle()
            }) {
                HStack {
                    Image.fromSystemName(settingManager.calendarShowCompletedSeparator ? "checkmark.circle.fill" : "circle", hexColor: themeManager.color(level: 5).toHexString(), size: TDAppConfig.menuIconSize)

                    Text("settings.event.show_completed_strikethrough".localized)
                        .font(.system(size: TDAppConfig.menuFontSize))
                }
            }
            
            // 5. 最后一行显示剩余数量
            Button(action: {
                settingManager.calendarShowRemainingCount.toggle()
            }) {
                HStack {
                    Image.fromSystemName(settingManager.calendarShowRemainingCount ? "checkmark.circle.fill" : "circle", hexColor: themeManager.color(level: 5).toHexString(), size: TDAppConfig.menuIconSize)

                    
                    Text("settings.schedule.remaining_count".localized)
                        .font(.system(size: TDAppConfig.menuFontSize))
                }
            }
            
            // 6. 是否显示农历
            Button(action: {
                settingManager.showLunarCalendar.toggle()
            }) {
                HStack {
                    Image.fromSystemName(settingManager.showLunarCalendar ? "checkmark.circle.fill" : "circle", hexColor: themeManager.color(level: 5).toHexString(), size: TDAppConfig.menuIconSize)

                    Text("settings.schedule.show_lunar".localized)
                        .font(.system(size: TDAppConfig.menuFontSize))
                }
            }
            
            // 7. 隐私晒图模式
            Button(action: {
                settingManager.isPrivacyModeEnabled.toggle()
            }) {
                HStack {
                    Image.fromSystemName(settingManager.isPrivacyModeEnabled ? "checkmark.circle.fill" : "circle", hexColor: themeManager.color(level: 5).toHexString(), size: TDAppConfig.menuFontSize)

                    
                    Text("settings.schedule.privacy_mode".localized)
                        .font(.system(size: TDAppConfig.menuFontSize))
                }
            }
            
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 16))
                .foregroundColor(themeManager.titleTextColor)
//                .frame(width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize)
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }
}

// MARK: - 预览
#Preview {
    TDScheduleMoreMenu()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
        .environmentObject(TDScheduleOverviewViewModel.shared)
}

