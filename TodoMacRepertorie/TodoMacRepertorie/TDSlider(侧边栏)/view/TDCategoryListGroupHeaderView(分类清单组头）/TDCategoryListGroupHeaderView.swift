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
    let sidebarDisclosureFontSize: CGFloat
    let sidebarDisclosureFrameSide: CGFloat
    let sidebarIconFontSize: CGFloat
    let sidebarIconFrameSide: CGFloat
    let sidebarRowLeadingPadding: CGFloat
    let sidebarRowTrailingPadding: CGFloat

    let onAdd: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: sidebarInterItemSpacing) {
            // 分类清单图标（次要灰色，未选中状态）
            Image(systemName: "scroll")
                .foregroundColor(.secondary)
                .font(.system(size: sidebarIconFontSize))
                .frame(width: sidebarIconFrameSide, height: sidebarIconFrameSide, alignment: .center)

            // 分类清单标题（国际化）
            Text("sidebar.category.list".localized)
                .font(.system(size: 13))
                .foregroundColor(themeManager.titleTextColor)

            Spacer()

            HStack(spacing: 6) {
                // 新建分类按钮（hover 才显示）
                if isHovered {
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.color(level: 5))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }

                // chevron 始终可见（用户可感知展开/收起状态）
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .foregroundColor(themeManager.descriptionTextColor)
                    .font(.system(size: sidebarDisclosureFontSize, weight: .semibold))
                    .frame(width: sidebarDisclosureFrameSide, height: sidebarDisclosureFrameSide, alignment: .center)
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, sidebarRowLeadingPadding)
        .padding(.trailing, sidebarRowTrailingPadding)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.18)) {
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

