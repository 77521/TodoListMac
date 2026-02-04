//
//  TDTagGroupHeaderView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI

/// 侧滑栏「标签管理」分组头（带排序菜单）
struct TDTagManageGroupHeaderView: View {
    @ObservedObject var themeManager: TDThemeManager

    @Binding var isExpanded: Bool
    @Binding var sortOption: TDTagSortOption

    let sidebarInterItemSpacing: CGFloat
    let sidebarDisclosureFontSize: CGFloat
    let sidebarDisclosureFrameSide: CGFloat
    let sidebarIconFontSize: CGFloat
    let sidebarIconFrameSide: CGFloat
    let sidebarRowLeadingPadding: CGFloat
    let sidebarRowTrailingPadding: CGFloat

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: sidebarInterItemSpacing) {
//            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
//                .foregroundColor(themeManager.descriptionTextColor)
//                .font(.system(size: 11, weight: .semibold))
//                .frame(width: sidebarDisclosureSide, height: sidebarDisclosureSide, alignment: .center)

            Image(systemName: "number.circle")
                .foregroundColor(themeManager.color(level: 5))
                .font(.system(size: sidebarIconFontSize))
                .frame(width: sidebarIconFrameSide, height: sidebarIconFrameSide, alignment: .center)

            HStack(spacing: 8) {
                Text("tag.manage.group.title".localized)
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.titleTextColor)

                Menu {
                    Button {
                        sortOption = .time
                    } label: {
                        HStack(spacing: 8) {
                            if sortOption == .time {
                                Image(systemName: "checkmark")
                            }
                            Text("tag.manage.sort.by_time".localized)
                        }
                    }

                    Button {
                        sortOption = .count
                    } label: {
                        HStack(spacing: 8) {
                            if sortOption == .count {
                                Image(systemName: "checkmark")
                            }
                            Text("tag.manage.sort.by_count".localized)
                        }
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.color(level: 5))
                }
                .menuStyle(.button)
                .menuIndicator(.hidden)  // 隐藏菜单指示器
                .buttonStyle(PlainButtonStyle())
                // 只在鼠标悬停到「标签管理」组头时显示筛选/排序按钮
                .opacity(isHovered ? 1 : 0)
                .allowsHitTesting(isHovered)
                .accessibilityHidden(!isHovered)
                
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .foregroundColor(themeManager.descriptionTextColor)
                    .font(.system(size: sidebarDisclosureFontSize, weight: .semibold))
                    .frame(width: sidebarDisclosureFrameSide, height: sidebarDisclosureFrameSide, alignment: .center)
                // 悬停才显示
                .opacity(isHovered ? 1 : 0)
                .allowsHitTesting(isHovered)


            }

            Spacer()
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
        // 只对“标题区域”响应点击展开/收起，避免误触菜单
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }
}
