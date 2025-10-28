//
//  TDDataReviewCenterTitleCard.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/14.
//

import SwiftUI

/// 居中标题卡片
struct TDDataReviewCenterTitleCard: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    let item: TDDataReviewModel
    
    var body: some View {
        VStack(spacing: 8) {
            // 标题
            if let title = item.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 25))
                    .foregroundColor(getTitleColor())
                    .lineLimit(1)
            }
            
            // 副标题
            if let subTitle = item.subTitle, !subTitle.isEmpty {
                Text(subTitle)
                    .font(.system(size: 14))
                    .foregroundColor(getSubTitleColor())
                    .lineLimit(0)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(getBackgroundColor())
        )
    }
    
    /// 获取背景颜色
    private func getBackgroundColor() -> Color {
        if let backColor = item.backColor, !backColor.isEmpty {
            return Color.fromHex(backColor)
        }
        // 默认透明背景
        return themeManager.backgroundColor
    }
    
    /// 获取标题颜色
    private func getTitleColor() -> Color {
        if let backColor = item.backColor, !backColor.isEmpty {
            // 有背景色时，使用白色
            return .white
        } else {
            // 无背景色时，使用主题颜色
            return themeManager.titleTextColor
        }
    }
    
    /// 获取副标题颜色
    private func getSubTitleColor() -> Color {
        if let backColor = item.backColor, !backColor.isEmpty {
            // 有背景色时，使用白色
            return .white
        } else {
            // 无背景色时，使用主题颜色
            return themeManager.descriptionTextColor
        }
    }
}

// MARK: - 预览
//#Preview {
//    TDDataReviewCenterTitleCard(
//        item: TDDataReviewModel(
//            modelType: 2,
//            layoutId: nil,
//            title: nil,
//            subTitle: nil,
//            content: nil,
//            summary: nil,
//            imageUrl: nil,
//            jumpUrl: nil,
//            backColor: nil,
//            tomato: false,
//            leftTitle: "事件工作量",
//            leftContent: "0",
//            leftDataExplain: "相比前天",
//            leftDataRate: "NaN",
//            leftBackColor: "#11abac",
//            rightTitle: "番茄专注时长",
//            rightContent: "0h",
//            rightDataExplain: "相比前天",
//            rightDataRate: "NaN",
//            rightBackColor: "#ef655b",
//            chartList: nil
//        )
//    )
//    .environmentObject(TDThemeManager.shared)
//    .environmentObject(TDSettingManager.shared)
//    .padding()
//}
