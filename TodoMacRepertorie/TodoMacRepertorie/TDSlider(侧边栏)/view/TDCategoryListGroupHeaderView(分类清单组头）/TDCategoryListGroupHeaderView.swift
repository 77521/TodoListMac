//
//  TDCategoryGroupHeaderView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI

/// 侧滑栏「分类清单」分组头（抽离组件，减少 TDSliderBarView 复杂度）
struct TDCategoryListGroupHeaderView: View {
    @ObservedObject var themeManager: TDThemeManager

    @Binding var isExpanded: Bool

    let sidebarInterItemSpacing: CGFloat
    let sidebarDisclosureSide: CGFloat
    let sidebarIconSide: CGFloat
    let sidebarRowLeadingPadding: CGFloat
    let sidebarRowTrailingPadding: CGFloat

    let onAdd: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: sidebarInterItemSpacing) {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .foregroundColor(themeManager.descriptionTextColor)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: sidebarDisclosureSide, height: sidebarDisclosureSide, alignment: .center)

            Image(systemName: "folder")
                .foregroundColor(themeManager.color(level: 5))
                .font(.system(size: sidebarIconSide))
                .frame(width: sidebarIconSide, height: sidebarIconSide, alignment: .center)

            Text("分类清单")
                .font(.system(size: 13))
                .foregroundColor(themeManager.titleTextColor)

            Spacer()

            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(themeManager.color(level: 5))
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
            .opacity(isHovered ? 1 : 0)
        }
        .padding(.vertical, 8)
        .padding(.leading, sidebarRowLeadingPadding)
        .padding(.trailing, sidebarRowTrailingPadding)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }
}

