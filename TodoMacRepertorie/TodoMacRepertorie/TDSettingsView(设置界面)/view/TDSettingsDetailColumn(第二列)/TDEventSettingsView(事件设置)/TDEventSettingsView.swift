//
//  TDEventSettingsView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/8.
//

import SwiftUI

import SwiftUI

struct TDEventSettingsView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var settingManager: TDSettingManager
    @Environment(\.openURL) private var openURL
    
    // picker 选项
    private let weekStartOptions: [(String, Bool)] = [
        ("settings.event.week_start.sunday".localized, false),
        ("settings.event.week_start.monday".localized, true)
    ]
    
    private let newEventPositionOptions: [(String, Bool)] = [
        ("settings.event.position.bottom".localized, false),
        ("settings.event.position.top".localized, true)
    ]
    
    private let descLinesOptions = Array(1...5)
    
    private let reminderOptions = TDDefaultReminder.allCases
    private let soundOptions = TDSoundType.allCases
    private let expiredRangeOptions = TDExpiredRange.allCases
    private let futureRangeOptions = TDFutureDateRange.allCases
    private let repeatLimitOptions = TDRepeatTasksLimit.allCases
    private let reminderGuideURL = URL(string: "https://www.evetech.top/?p=971")!
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection

                // 第一组：事件设置
                VStack(spacing: 4) {
                    Text("settings.event.title".localized)
                        .foregroundColor(themeManager.color(level: 5))
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)

                    TDSettingsCardContainer {
//                        TDSettingsToggleRow(
//                            title: "settings.event.today_badge".localized,
//                            isOn: Binding(
//                                get: { settingManager.showTodayBadge },
//                                set: { settingManager.showTodayBadge = $0 }
//                            )
//                        )
//                        TDSettingsDivider()
                        TDSettingsToggleRow(
                            title: "settings.event.checkbox_follow_color".localized,
                            isOn: Binding(
                                get: { settingManager.checkboxFollowCategoryColor },
                                set: { settingManager.checkboxFollowCategoryColor = $0 }
                            )
                        )
                        TDSettingsDivider()
                        TDSettingsToggleRow(
                            title: "settings.event.remember_last_category".localized,
                            isOn: Binding(
                                get: { settingManager.rememberLastCategory },
                                set: { settingManager.rememberLastCategory = $0 }
                            )
                        )
                        TDSettingsDivider()
                        HStack {
                            Text("settings.event.new_event_position".localized)
                                .foregroundColor(themeManager.titleTextColor)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { settingManager.isNewTaskAddToTop },
                                set: { settingManager.isNewTaskAddToTop = $0 }
                            )) {
                                Text("settings.event.position.bottom".localized).tag(false)
                                Text("settings.event.position.top".localized).tag(true)
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: pillWidth(for: currentNewEventPositionLabel))
                            .fixedSize(horizontal: true, vertical: false)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                        TDSettingsDivider()
                        HStack {
                            Text("settings.event.new_event_position".localized)
                                .foregroundColor(themeManager.titleTextColor)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { settingManager.isNewTaskAddToTop },
                                set: { settingManager.isNewTaskAddToTop = $0 }
                            )) {
                                Text("settings.event.position.bottom".localized).tag(false)
                                Text("settings.event.position.top".localized).tag(true)
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: pillWidth(for: currentNewEventPositionLabel))
                            .fixedSize(horizontal: true, vertical: false)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                        TDSettingsDivider()
                        TDSettingsToggleRow(
                            title: "settings.event.show_completed".localized,
                            isOn: Binding(
                                get: { settingManager.showCompletedTasks },
                                set: { settingManager.showCompletedTasks = $0 }
                            )
                        )
                        TDSettingsDivider()
                        TDSettingsToggleRow(
                            title: "settings.event.show_completed_strikethrough".localized,
                            isOn: Binding(
                                get: { settingManager.showCompletedTaskStrikethrough },
                                set: { settingManager.showCompletedTaskStrikethrough = $0 }
                            )
                        )
                        TDSettingsDivider()
                        TDSettingsToggleRow(
                            title: "settings.event.show_order_number".localized,
                            isOn: Binding(
                                get: { settingManager.showDayTodoOrderNumber },
                                set: { settingManager.showDayTodoOrderNumber = $0 }
                            )
                        )
                        TDSettingsDivider()
                        TDSettingsToggleRow(
                            title: "settings.event.show_description".localized,
                            isOn: Binding(
                                get: { settingManager.showTaskDescription },
                                set: { settingManager.showTaskDescription = $0 }
                            )
                        )
                        TDSettingsDivider()
                        TDSettingsToggleRow(
                            title: "settings.event.show_holiday_mark".localized,
                            isOn: Binding(
                                get: { settingManager.showHolidayMark },
                                set: { settingManager.showHolidayMark = $0 }
                            )
                        )
                        TDSettingsDivider()
                        HStack {
                            Text("settings.event.description_lines".localized)
                                .foregroundColor(themeManager.titleTextColor)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { settingManager.taskDescriptionLines },
                                set: { settingManager.taskDescriptionLines = $0 }
                            )) {
                                ForEach(descLinesOptions, id: \.self) { value in
                                    Text("settings.event.lines.\(value)".localized).tag(value)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: pillWidth(for: currentDescLinesLabel))
                            .fixedSize(horizontal: true, vertical: false)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                        TDSettingsDivider()
                        TDSettingsToggleRow(
                            title: "settings.event.subtask_expand".localized,
                            isOn: Binding(
                                get: { settingManager.expandSubtask },
                                set: { settingManager.expandSubtask = $0 }
                            )
                        )
                        TDSettingsDivider()
                        TDSettingsToggleRow(
                            title: "settings.event.subtask_auto_complete".localized,
                            isOn: Binding(
                                get: { settingManager.autoCompleteWhenSubtasksDone },
                                set: { settingManager.autoCompleteWhenSubtasksDone = $0 }
                            )
                        )
                        TDSettingsDivider()
                        HStack {
                            Text("settings.event.sound".localized)
                                .foregroundColor(themeManager.titleTextColor)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { settingManager.soundType },
                                set: { settingManager.soundType = $0 }
                            )) {
                                ForEach(soundOptions, id: \.self) { option in
                                    Text(option.displayName).tag(option)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: pillWidth(for: currentSoundLabel))
                            .fixedSize(horizontal: true, vertical: false)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                }
                
                VStack(spacing: 6) {
                    // 默认提醒时间（单独分组 + 组尾）
                    TDSettingsCardContainer {
                        HStack {
                            Text("settings.event.default_reminder".localized)
                                .foregroundColor(themeManager.titleTextColor)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { settingManager.defaultReminderOffset },
                                set: { settingManager.defaultReminderOffset = $0 }
                            )) {
                                ForEach(reminderOptions, id: \.self) { option in
                                    Text(option.title.localized).tag(option)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: pillWidth(for: currentReminderLabel))
                            .fixedSize(horizontal: true, vertical: false)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        TDSettingsFooterText(text: "settings.event.reminder.desc".localized)
                        Button {
                            openURL(reminderGuideURL)
                        } label: {
                            Text("settings.event.reminder.guide".localized)
                                .foregroundColor(themeManager.color(level: 5))
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                        .padding(.leading,12)
                        .pointingHandCursor()
                        .padding(.top,-3)
                    }
                }
                
                // 列表清单设置分组
                VStack(spacing: 4) {
                    Text("settings.event.list.header".localized)
                        .foregroundColor(themeManager.color(level: 5))
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                    TDSettingsCardContainer {
                        VStack(spacing: 0) {
                            HStack(alignment: .center, spacing: 12) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("settings.event.list.past_range".localized)
                                        .foregroundColor(themeManager.titleTextColor)
                                    Text("settings.event.list.past_desc".localized)
                                        .font(.system(size: 12))
                                        .foregroundColor(themeManager.descriptionTextColor)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { settingManager.expiredRangeCompleted },
                                    set: { settingManager.expiredRangeCompleted = $0 }
                                )) {
                                    ForEach(expiredRangeOptions, id: \.self) { option in
                                        Text(option.description.localized).tag(option)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(width: pillWidth(for: currentExpiredCompletedLabel))
                                .fixedSize(horizontal: true, vertical: false)
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
//                            TDSettingsFooterText(text: "settings.event.list.past_desc".localized)
//                                .padding(.top, 2)
                            TDSettingsDivider()
                            HStack {
                                Text("settings.event.list.overdue_range".localized)
                                    .foregroundColor(themeManager.titleTextColor)
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { settingManager.expiredRangeUncompleted },
                                    set: { settingManager.expiredRangeUncompleted = $0 }
                                )) {
                                    ForEach(expiredRangeOptions, id: \.self) { option in
                                        Text(option.description.localized).tag(option)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(width: pillWidth(for: currentExpiredUncompletedLabel))
                                .fixedSize(horizontal: true, vertical: false)
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                            TDSettingsDivider()
                            HStack {
                                Text("settings.event.list.future_range".localized)
                                    .foregroundColor(themeManager.titleTextColor)
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { settingManager.futureDateRange },
                                    set: { settingManager.futureDateRange = $0 }
                                )) {
                                    ForEach(futureRangeOptions, id: \.self) { option in
                                        Text(option.title.localized).tag(option)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(width: pillWidth(for: currentFutureRangeLabel))
                                .fixedSize(horizontal: true, vertical: false)
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                            TDSettingsDivider()
                            HStack {
                                Text("settings.event.list.repeat_limit".localized)
                                    .foregroundColor(themeManager.titleTextColor)
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { settingManager.repeatTasksLimit },
                                    set: { settingManager.repeatTasksLimit = $0 }
                                )) {
                                    ForEach(repeatLimitOptions, id: \.self) { option in
                                        Text(option.title.localized).tag(option)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(width: pillWidth(for: currentRepeatLimitLabel))
                                .fixedSize(horizontal: true, vertical: false)
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                            TDSettingsDivider()
                            TDSettingsToggleRow(
                                title: "settings.event.list.show_inbox_no_date".localized,
                                isOn: Binding(
                                    get: { settingManager.showNoDateEvents },
                                    set: { settingManager.showNoDateEvents = $0 }
                                )
                            )
                            TDSettingsDivider()
                            TDSettingsToggleRow(
                                title: "settings.event.list.show_completed_no_date".localized,
                                isOn: Binding(
                                    get: { settingManager.showCompletedNoDateEvents },
                                    set: { settingManager.showCompletedNoDateEvents = $0 }
                                )
                            )
                        }
                    }
                    TDSettingsFooterText(text: "settings.event.lock_privacy.desc".localized)

                }
//                .padding(.top, 8)
                
//                VStack(spacing: 4) {
//                    // 锁屏小组件分组 + 组尾
//                    TDSettingsCardContainer {
//                        TDSettingsToggleRow(
//                            title: "settings.event.list.lock_privacy".localized,
//                            isOn: Binding(
//                                get: { settingManager.isPrivacyModeEnabled },
//                                set: { settingManager.isPrivacyModeEnabled = $0 }
//                            )
//                        )
//                    }
////                    TDSettingsFooterText(text: "settings.event.lock_privacy.desc".localized)
//
//                }
                // 侧滑栏工作量热力图分组
                TDSettingsCardContainer {
                    TDSettingsToggleRow(
                        title: "settings.event.list.sidebar_heatmap".localized,
                        isOn: Binding(
                            get: { settingManager.showSidebarHeatmap },
                            set: { settingManager.showSidebarHeatmap = $0 }
                        )
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 50)
        }
    }
    // MARK: - 头部说明
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("settings.event.header.title".localized)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(themeManager.titleTextColor)
            
            Text("settings.event.header.subtitle".localized)
                .font(.system(size: 13))
                .foregroundColor(themeManager.descriptionTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var currentWeekStartLabel: String {
        settingManager.isFirstDayMonday ? "settings.event.week_start.monday".localized : "settings.event.week_start.sunday".localized
    }
    
    private var currentNewEventPositionLabel: String {
        settingManager.isNewTaskAddToTop ? "settings.event.position.top".localized : "settings.event.position.bottom".localized
    }
    
    private var currentDescLinesLabel: String {
        "settings.event.lines.\(settingManager.taskDescriptionLines)".localized
    }
    
    private var currentSoundLabel: String {
        settingManager.soundType.displayName
    }
    
    private var currentReminderLabel: String {
        settingManager.defaultReminderOffset.title.localized
    }
    
    private var currentExpiredCompletedLabel: String {
        settingManager.expiredRangeCompleted.description.localized
    }
    
    private var currentExpiredUncompletedLabel: String {
        settingManager.expiredRangeUncompleted.description.localized
    }
    
    private var currentFutureRangeLabel: String {
        settingManager.futureDateRange.title.localized
    }
    
    private var currentRepeatLimitLabel: String {
        settingManager.repeatTasksLimit.title.localized
    }
    
    /// 计算文本宽度，保证胶囊长度与当前文案匹配
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
    TDEventSettingsView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
}

