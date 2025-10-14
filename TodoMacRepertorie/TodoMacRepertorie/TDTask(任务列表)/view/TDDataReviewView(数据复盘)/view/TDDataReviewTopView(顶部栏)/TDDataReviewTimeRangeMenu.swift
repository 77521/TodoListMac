//
//  TDDataReviewTimeRangeMenu.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/14.
//

import SwiftUI

/// 数据复盘时间范围选择菜单
struct TDDataReviewTimeRangeMenu: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @StateObject private var viewModel = TDDataReviewViewModel.shared
    
    /// 当前选中的时间范围
    private var selectedTimeRange: TDDataReviewTimeRange {
        viewModel.selectedTimeRange
    }
    
    var body: some View {
        Menu {
            ForEach(TDDataReviewTimeRange.allCases, id: \.self) { range in
                Button(action: {
                    viewModel.updateTimeRange(range)
                }) {
                    HStack {
                        Text(range.rawValue)
                            .font(.system(size: 12))
                        if selectedTimeRange == range {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .medium))
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedTimeRange.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.titleTextColor)
                
//                Image(systemName: "chevron.down")
//                    .font(.system(size: 10, weight: .medium))
//                    .foregroundColor(themeManager.descriptionTextColor)
            }
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
    TDDataReviewTimeRangeMenu()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
}
