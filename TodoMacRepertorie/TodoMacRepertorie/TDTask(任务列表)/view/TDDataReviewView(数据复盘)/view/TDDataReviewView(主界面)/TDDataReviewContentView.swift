//
//  TDDataReviewContentView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/14.
//

import SwiftUI

/// 数据复盘内容展示容器
struct TDDataReviewContentView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @StateObject private var viewModel = TDDataReviewViewModel.shared
    
    var body: some View {
        
        ZStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(viewModel.currentData, id: \.modelType) { item in
                        // 根据不同类型显示不同的视图
                        if item.isDualColumnStats {
                            TDDataReviewDualColumnCard(item: item)
                        } else if item.isImageTextCardWithIcon {
                            TDDataReviewImageTextCard(item: item)
                        } else if item.isImageTextCardWithCenterTitle {
                            TDDataReviewCenterTitleCard(item: item)
                        } else if item.isLineChart {
                            TDDataReviewLineChartCard(item: item)
                        } else if item.isPieChart {
                            //                        TDDataReviewPieChartCard(item: item)
                        } else if item.isRadarChart {
                            //                        TDDataReviewRadarChartCard(item: item)
                        } else if item.isNoVipCard {
                            //                        TDDataReviewNoVipCard(item: item)
                        } else if item.isHeatMap {
                            //                        TDDataReviewHeatMapCard(item: item)
                        } else {
                            // 默认显示
                            //                        TDDataReviewDefaultCard(item: item)
                        }
                    }
                }
                .frame(width: 750) // 固定宽度
                .frame(maxWidth: .infinity) // 在 ScrollView 中居中
                .padding(.vertical, 20)
            }
            .background(themeManager.secondaryBackgroundColor)
            
            // Loading 状态
            if viewModel.isLoading {
                VStack(spacing: 5) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.color(level: 5)))
                    
                    Text("加载中...")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.descriptionTextColor)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(themeManager.backgroundColor.opacity(0.8))
            }

            
        }
    }
}

// MARK: - 预览
#Preview {
    TDDataReviewContentView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
        .environmentObject(TDDataReviewViewModel.shared)
}
