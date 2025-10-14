//
//  TDDataReviewDualColumnCard.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/14.
//

import SwiftUI

/// 双列统计卡片
struct TDDataReviewDualColumnCard: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    let item: TDDataReviewModel
    
    var body: some View {
        HStack(spacing: 20) {
            // 左侧卡片
            // 左侧卡片
            VStack(alignment: .leading, spacing: 8) {
                // 标题
                Text(item.leftTitle ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                // 主要内容和比较信息水平对齐
                HStack(alignment: .center) {
                    // 主要内容
                    Text(item.leftContent ?? "")
                        .font(.system(size: 24,))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    
                    // 右侧比较信息
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.leftDataExplain ?? "")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        
                        Text(item.leftDataRate ?? "")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(getLeftBackgroundColor())
            )
            
            // 右侧卡片
            VStack(alignment: .leading, spacing: 8) {
                // 标题
                Text(item.rightTitle ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()

                // 主要内容和比较信息水平对齐
                HStack(alignment: .center) {
                    // 主要内容
                    Text(item.rightContent ?? "")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    
                    // 右侧比较信息
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.rightDataExplain ?? "")
                            .font(.system(size: 12))
                            .foregroundColor(.white)

                        Text(item.rightDataRate ?? "")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(getRightBackgroundColor())
            )
        }
    }
    
    /// 获取左侧背景颜色
    private func getLeftBackgroundColor() -> Color {
        if let leftBackColor = item.leftBackColor, !leftBackColor.isEmpty {
            return Color.fromHex(leftBackColor)
        }
        // 默认颜色
        return TDThemeManager.shared.fixedColor(themeId: "wish_orange", level: 6)
    }
    
    /// 获取右侧背景颜色
    private func getRightBackgroundColor() -> Color {
        if let rightBackColor = item.rightBackColor, !rightBackColor.isEmpty {
            return Color.fromHex(rightBackColor)
        }
        // 默认颜色
        return TDThemeManager.shared.fixedColor(themeId: "new_year_red", level: 6)
    }
}

// MARK: - 预览
#Preview {
    TDDataReviewDualColumnCard(
        item: TDDataReviewModel(
            modelType: 2,
            layoutId: nil,
            title: nil,
            subTitle: nil,
            content: nil,
            summary: nil,
            imageUrl: nil,
            jumpUrl: nil,
            backColor: nil,
            tomato: false,
            leftTitle: "事件工作量",
            leftContent: "0",
            leftDataExplain: "相比前天",
            leftDataRate: "NaN",
            leftBackColor: "#11abac",
            rightTitle: "番茄专注时长",
            rightContent: "0h",
            rightDataExplain: "相比前天",
            rightDataRate: "NaN",
            rightBackColor: "#ef655b",
            chartList: nil
        )
    )
    .environmentObject(TDThemeManager.shared)
    .padding()
}
