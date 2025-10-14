//
//  TDDataReviewWeekRangeMenu.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/14.
//

import SwiftUI

/// 周报时间范围选择菜单
struct TDDataReviewWeekRangeMenu: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @StateObject private var viewModel = TDDataReviewViewModel.shared
    
    /// 当前选中的周报时间范围
    private var selectedWeekRange: TDDataReviewWeekRange {
        viewModel.selectedWeekRange
    }
    
    var body: some View {
        Menu {
            ForEach(TDDataReviewWeekRange.allCases, id: \.self) { range in
                Button(action: {
                    viewModel.updateWeekRange(range)
                }) {
                    HStack {
                        Text(range.rawValue)
                            .font(.system(size: 12))
                        if selectedWeekRange == range {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .medium))
                        }
                    }
                }
            }
        } label: {
            Text(selectedWeekRange.getDisplayText())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.titleTextColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(themeManager.secondaryBackgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(themeManager.separatorColor, lineWidth: 1)
                        )
                )
        }
        .menuStyle(ButtonMenuStyle())
        .pointingHandCursor()
    }
}

// MARK: - 预览
#Preview {
    TDDataReviewWeekRangeMenu()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
        .environmentObject(TDDataReviewViewModel.shared)
}
