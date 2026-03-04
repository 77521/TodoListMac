//
//  TDScheduleOverviewView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData

/// 日程概览视图
struct TDScheduleOverviewView: View {
    @EnvironmentObject private var viewModel: TDScheduleOverviewViewModel

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            TDScheduleTopToolbar()
                .zIndex(1) // 确保在最上层，阴影效果可见
            
            // 日历组件
            if viewModel.displayMode == .month {
                TDCalendarView()
            } else {
                TDWeekCalendarView()
            }
            
            // 内容区域
//            Spacer()
        }

    }
}

#Preview {
    TDScheduleOverviewView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
        .environmentObject(TDScheduleOverviewViewModel.shared)
}
