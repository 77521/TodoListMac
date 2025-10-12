//
//  TDScheduleWeekdayView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/10.
//

import SwiftUI

/// 星期标题视图 - 根据设置显示周一到周日或周日到周六
struct TDScheduleWeekdayView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var settingManager: TDSettingManager
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(getWeekdayHeaders().enumerated()), id: \.offset) { index, weekday in
                Text(weekday)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.descriptionTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical,4)
                    .overlay(
                        // 除了最后一个，其他都有右边分割线
                        Group {
                            if index < getWeekdayHeaders().count - 1 {
                                Rectangle()
                                    .fill(themeManager.separatorColor)
                                    .frame(width: 1)
                                    .frame(maxHeight: .infinity)
                            }
                        },
                        alignment: .trailing
                    )
            }
        }
//        .padding(.horizontal, 4)
//        .padding(.vertical, 4)
        .background(themeManager.backgroundColor)
//        .background(.red)

    }
    
    /// 获取星期标题 - 根据设置返回不同的星期顺序
    /// - Returns: 星期标题数组
    private func getWeekdayHeaders() -> [String] {
        if settingManager.isFirstDayMonday {
            // 周一到周日
            return [
                "week_mon".localized,
                "week_tue".localized,
                "week_wed".localized,
                "week_thu".localized,
                "week_fri".localized,
                "week_sat".localized,
                "week_sun".localized
            ]
        } else {
            // 周日到周六
            return [
                "week_sun".localized,
                "week_mon".localized,
                "week_tue".localized,
                "week_wed".localized,
                "week_thu".localized,
                "week_fri".localized,
                "week_sat".localized
            ]
        }
    }
}

// MARK: - 预览
#Preview {
    TDScheduleWeekdayView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
}
