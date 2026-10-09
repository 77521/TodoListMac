//
//  TDTaskGroupHeaderView.swift
//  TodoMacRepertorie
//
//  从 TDTaskListView.swift 提取，供多个列表视图复用

import SwiftUI

/// 任务分组组头视图（TDTaskListView / 未来其他列表视图通用）
struct TDTaskGroupHeaderView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @ObservedObject private var settingManager = TDSettingManager.shared
    @Environment(\.openWindow) private var openWindow

    let type: TDTaskGroupType
    /// 分组基础标题（已国际化，displayTitle 会自动追加天数/星期等信息）
    let title: String
    let tasks: [TDMacSwiftDataListModel]
    let totalCount: Int
    @Binding var isExpanded: Bool
    /// 过期未达成「重新安排」：由父视图注入，组头不再订阅整个 mainViewModel
    var onReschedule: (() -> Void)? = nil
    /// false 时只展示组头，不自己切展开状态（给外层统一处理时用）
    var handlesTapToToggle: Bool = true

    @State private var isHovering: Bool = false

    var body: some View {
        Button {
            guard handlesTapToToggle else { return }
            isExpanded.toggle()
        } label: {
            HStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text(displayTitle)
                        .font(.system(size: 14))
                        .foregroundColor(titleColor)

                    if type.needsSettingsIcon {
                        Button {
                            TDSettingsSidebarStore.shared.TDHandleSettingSelection(.eventSettings)
                            TDSettingsWindowTracker.shared.presentSettingsWindow(using: openWindow)
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(themeManager.color(level: 5))
                                .frame(width: 20, height: 20, alignment: .center)
                        }
                        .buttonStyle(.plain)
                        .pointingHandCursor()
                        .opacity(isHovering ? 1 : 0)
                        .allowsHitTesting(isHovering)
                        .accessibilityHidden(!isHovering)
                    }
                }

                Spacer()

                if shouldShowCount {
                    Text("\(displayCount)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(countColor)
                }

                if type.needsRescheduleButton {
                    Button {
                        if !isExpanded { isExpanded = true }
                        onReschedule?()
                    } label: {
                        Text("task.group.reschedule".localized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                    .opacity(isHovering ? 1 : 0)
                    .allowsHitTesting(isHovering)
                    .accessibilityHidden(!isHovering)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(chevronColor)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.timingCurve(0.22, 1.0, 0.36, 1.0, duration: 0.32), value: isExpanded)
                    .frame(width: 14, height: 20)
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .frame(height: 36)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) { isHovering = hovering }
        }
    }

    // MARK: - 标题构建

    private var displayTitle: String {
        switch type {
        case .overdueCompleted:
            return title + withinDaysSuffix(settingManager.expiredRangeCompleted.rawValue)
        case .overdueUncompleted:
            return title + withinDaysSuffix(settingManager.expiredRangeUncompleted.rawValue)
        case .today:
            return "\(title) \(Date().weekdayDisplay())"
        case .tomorrow:
            return "\(title) \(Date().adding(days: 1).weekdayDisplay())"
        case .dayAfterTomorrow:
            return "\(title) \(Date().adding(days: 2).weekdayDisplay())"
        case .upcomingSchedule, .noDate:
            return title
        }
    }

    private func withinDaysSuffix(_ days: Int) -> String {
        guard days > 0 else { return "" }
        return "task.group.within_days".localizedFormat(days)
    }

    // MARK: - 数量规则

    private var shouldShowCount: Bool {
        type != .overdueUncompleted && totalCount > 0
    }

    private var displayCount: Int {
        if type == .dayAfterTomorrow {
            return tasks.reduce(0) { $0 + ($1.complete ? 0 : 1) }
        }
        return totalCount
    }

    // MARK: - 颜色规则

    private var titleColor: Color {
        switch type {
        case .today, .tomorrow, .dayAfterTomorrow, .upcomingSchedule:
            return themeManager.color(level: 5)
        case .overdueUncompleted:
            return themeManager.fixedColor(themeId: "new_year_red", level: 5)
        case .overdueCompleted, .noDate:
            return themeManager.titleTextColor
        }
    }

    private var countColor: Color {
        switch type {
        case .today, .tomorrow, .dayAfterTomorrow, .upcomingSchedule:
            return themeManager.color(level: 5)
        case .overdueCompleted, .noDate:
            return themeManager.titleTextColor
        case .overdueUncompleted:
            return themeManager.fixedColor(themeId: "new_year_red", level: 5)
        }
    }

    private var chevronColor: Color {
        switch type {
        case .today, .tomorrow, .dayAfterTomorrow, .upcomingSchedule:
            return themeManager.color(level: 5)
        case .overdueUncompleted:
            return themeManager.fixedColor(themeId: "new_year_red", level: 5)
        case .overdueCompleted, .noDate:
            return themeManager.descriptionTextColor
        }
    }

    private var backgroundColor: Color {
        switch type {
        case .overdueCompleted, .noDate:
            return themeManager.secondaryBackgroundColor
        case .overdueUncompleted:
            return themeManager.fixedColor(themeId: "new_year_red", level: 2)
        case .today, .tomorrow, .dayAfterTomorrow, .upcomingSchedule:
            return themeManager.color(level: 2)
        }
    }
}

// MARK: - TDTaskGroupType 本地化标题扩展

extension TDTaskGroupType {
    /// 国际化基础标题（不含天数/星期动态信息，TDTaskGroupHeaderView 会自动追加）
    var localizedBaseTitle: String {
        switch self {
        case .overdueCompleted:   return "overdue_completed".localized
        case .overdueUncompleted: return "overdue_uncompleted".localized
        case .today:              return "today".localized
        case .tomorrow:           return "tomorrow".localized
        case .dayAfterTomorrow:   return "day_after_tomorrow".localized
        case .upcomingSchedule:   return "upcoming_schedule".localized
        case .noDate:             return "no_date".localized
        }
    }
}
