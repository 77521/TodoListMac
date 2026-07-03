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
            // 标签图标（次要灰色）
            Image(systemName: "number.circle")
                .foregroundColor(.secondary)
                .font(.system(size: sidebarIconFontSize))
                .frame(width: sidebarIconFrameSide, height: sidebarIconFrameSide, alignment: .center)

            Text("tag.manage.group.title".localized)
                .font(.system(size: 13))
                .foregroundColor(themeManager.titleTextColor)

            Spacer()

            HStack(spacing: 6) {
                // 排序菜单（hover 才显示）
                if isHovered {
                    Menu {
                        Button {
                            sortOption = .time
                        } label: {
                            HStack(spacing: 8) {
                                if sortOption == .time { Image(systemName: "checkmark") }
                                Text("tag.manage.sort.by_time".localized)
                            }
                        }
                        Button {
                            sortOption = .count
                        } label: {
                            HStack(spacing: 8) {
                                if sortOption == .count { Image(systemName: "checkmark") }
                                Text("tag.manage.sort.by_count".localized)
                            }
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.color(level: 5))
                    }
                    .menuStyle(.button)
                    .menuIndicator(.hidden)
                    .buttonStyle(PlainButtonStyle())
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }

                // chevron 始终可见
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
