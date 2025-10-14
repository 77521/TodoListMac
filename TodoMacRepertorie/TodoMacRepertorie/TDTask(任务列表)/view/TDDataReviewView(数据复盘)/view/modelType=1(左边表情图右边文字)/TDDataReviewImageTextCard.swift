//
//  TDDataReviewImageTextCard.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/14.
//

import SwiftUI

/// 图片文本卡片
struct TDDataReviewImageTextCard: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    let item: TDDataReviewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧图标
            if let iconUrl = item.imageUrl, !iconUrl.isEmpty {
                AsyncImage(url: URL(string: iconUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    // 默认图标
                    Image(systemName: "face.smiling")
                        .font(.system(size: 26))
                        .foregroundColor(.purple)
                }
                .frame(width: 25, height: 25)
            } else {
                // 默认图标
                Image(systemName: "face.smiling")
                    .font(.system(size: 26))
                    .foregroundColor(.purple)
                    .frame(width: 25, height: 25)
            }
            
            // 右侧文本内容
            if let content = item.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.titleTextColor)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.separatorColor, lineWidth: 1)
                )
        )
    }
}

// MARK: - 预览
#Preview {
    TDDataReviewImageTextCard(
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
    .environmentObject(TDSettingManager.shared)
    .padding()
}
