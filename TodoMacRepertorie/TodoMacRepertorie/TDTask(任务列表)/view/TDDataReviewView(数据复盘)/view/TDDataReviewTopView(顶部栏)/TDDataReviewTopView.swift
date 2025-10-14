//
//  TDDataReviewTopView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/13.
//

import SwiftUI

/// 数据复盘顶部统计视图
struct TDDataReviewTopView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var settingManager: TDSettingManager
    @StateObject private var viewModel = TDDataReviewViewModel.shared

    /// 选中的统计类型
    @State private var selectedStatType: StatType = .yesterday

    /// 统计类型枚举
    enum StatType: String, CaseIterable {
        case yesterday = "昨日小结"
        case events = "事件统计"
        case tomato = "番茄统计"
        case weekly = "周报"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Picker("", selection: Binding(
                    get: { viewModel.selectedStatType },
                    set: { viewModel.updateStatType($0) }
                )) {
                    ForEach(StatType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .accentColor(themeManager.color(level: 5)) // 选中时的颜色
                .background(Color.white) // 尝试设置背景色
                .foregroundColor(themeManager.color(level: 5)) // 字体颜色

                Spacer()
                
                // 右侧按钮
                // 时间范围选择菜单（只在事件统计和番茄统计时显示）
                if viewModel.selectedStatType == .events || viewModel.selectedStatType == .tomato {
                    TDDataReviewTimeRangeMenu()
                }
                // 周报时间范围选择菜单（只在周报时显示）
                if viewModel.selectedStatType == .weekly {
                    TDDataReviewWeekRangeMenu()
                }

            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(themeManager.backgroundColor)
            .overlay(
                Rectangle()
                    .fill(themeManager.separatorColor)
                    .frame(height: 1),
                alignment: .bottom
            )
            
        }
        .background(themeManager.backgroundColor)
    }
}


// MARK: - 预览
#Preview {
    TDDataReviewTopView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
}
