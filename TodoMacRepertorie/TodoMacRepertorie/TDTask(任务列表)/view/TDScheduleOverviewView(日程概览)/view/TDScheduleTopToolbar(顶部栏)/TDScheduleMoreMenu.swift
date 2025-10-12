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
    
    var body: some View {
        Menu {
            // 1. 条目背景色
            Menu {
                Button(action: {
                    settingManager.calendarTaskBackgroundMode = .workload
                }) {
                    HStack {
                        Text("事件工作量")
                            .font(.system(size: 12))
                        Spacer()
                        if settingManager.calendarTaskBackgroundMode == .workload {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
                
                Button(action: {
                    settingManager.calendarTaskBackgroundMode = .category
                }) {
                    HStack {
                        Text("清单颜色")
                            .font(.system(size: 12))
                        Spacer()
                        if settingManager.calendarTaskBackgroundMode == .category {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
            } label: {
                Text("条目背景色")
                    .font(.system(size: 12))
            }

            
            // 2. 清单颜色识别（仅当条目背景色为清单颜色时显示）
            if settingManager.calendarTaskBackgroundMode == .category {
                Menu {
                    Button(action: {
                        settingManager.calendarTaskColorRecognition = .auto
                    }) {
                        HStack {
                            Text("自动识别")
                                .font(.system(size: 12))
                            Spacer()
                            if settingManager.calendarTaskColorRecognition == .auto {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.color(level: 5))
                            }
                        }
                    }
                    
                    Button(action: {
                        settingManager.calendarTaskColorRecognition = .black
                    }) {
                        HStack {
                            Text("黑色")
                                .font(.system(size: 12))
                            Spacer()
                            if settingManager.calendarTaskColorRecognition == .black {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.color(level: 5))
                            }
                        }
                    }
                    
                    Button(action: {
                        settingManager.calendarTaskColorRecognition = .white
                    }) {
                        HStack {
                            Text("白色")
                                .font(.system(size: 12))
                            Spacer()
                            if settingManager.calendarTaskColorRecognition == .white {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.color(level: 5))
                            }
                        }
                    }
                } label: {
                    Text("清单颜色识别")
                        .font(.system(size: 12))
                }
            }

            // 3. 字体大小
            Menu {
                Button(action: {
                    settingManager.fontSize = .size9
                }) {
                    HStack {
                        Text("小")
                            .font(.system(size: 12))
                        Spacer()
                        if settingManager.fontSize == .size9 {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
                
                Button(action: {
                    settingManager.fontSize = .size10
                }) {
                    HStack {
                        Text("默认")
                            .font(.system(size: 12))
                        Spacer()
                        if settingManager.fontSize == .size10 {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
                
                Button(action: {
                    settingManager.fontSize = .size11
                }) {
                    HStack {
                        Text("较大")
                            .font(.system(size: 12))
                        Spacer()
                        if settingManager.fontSize == .size11 {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
                
                Button(action: {
                    settingManager.fontSize = .size12
                }) {
                    HStack {
                        Text("最大")
                            .font(.system(size: 12))
                        Spacer()
                        if settingManager.fontSize == .size12 {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
            } label: {
                Text("字体大小")
                    .font(.system(size: 12))
            }

            
            Divider()
            
            // 4. 显示已完成事件删除线
            Button(action: {
                settingManager.calendarShowCompletedSeparator.toggle()
            }) {
                HStack {
                    Image(systemName: settingManager.calendarShowCompletedSeparator ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.color(level: 5))
                    Text("显示已完成事件删除线")
                        .font(.system(size: 12))
                }
            }
            
            // 5. 最后一行显示剩余数量
            Button(action: {
                settingManager.calendarShowRemainingCount.toggle()
            }) {
                HStack {
                    Image(systemName: settingManager.calendarShowRemainingCount ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.color(level: 5))
                    Text("最后一行显示剩余数量")
                        .font(.system(size: 12))
                }
            }
            
            // 6. 是否显示农历
            Button(action: {
                settingManager.showLunarCalendar.toggle()
            }) {
                HStack {
                    Image(systemName: settingManager.showLunarCalendar ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.color(level: 5))
                    Text("是否显示农历")
                        .font(.system(size: 12))
                }
            }
            
            // 7. 隐私晒图模式
            Button(action: {
                settingManager.isPrivacyModeEnabled.toggle()
            }) {
                HStack {
                    Image(systemName: settingManager.isPrivacyModeEnabled ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.color(level: 5))
                    Text("隐私晒图模式")
                        .font(.system(size: 12))
                }
            }
            
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 16))
                .foregroundColor(themeManager.titleTextColor)
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
}

