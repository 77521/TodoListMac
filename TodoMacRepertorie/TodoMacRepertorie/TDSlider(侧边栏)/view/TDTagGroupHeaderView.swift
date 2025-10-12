//
//  TDTagGroupHeaderView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI

/// 标签组视图
struct TDTagGroupView: View {
    // MARK: - Properties
    
    let isExpanded: Bool
    @State private var isHovered = false
    @ObservedObject private var themeManager = TDThemeManager.shared
    @ObservedObject private var settingManager = TDSettingManager.shared
    
    // 操作回调
    var onToggleExpand: () -> Void
    var onFilter: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 8) {
            // 1. 展开/折叠图标
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .foregroundColor(themeManager.titleTextColor)
                .frame(width: 12)
            
            // 2. 标签图标
            Image(systemName: "tag")
                .foregroundColor(themeManager.titleTextColor)
            
            // 3. 标题
            Text("标签")
                .font(.system(size: settingManager.fontSize.size))
                .foregroundColor(themeManager.titleTextColor)
            
            Spacer()
            
            // 4. 筛选按钮
            if isHovered {
                Button(action: onFilter) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(themeManager.descriptionTextColor)
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isHovered ? themeManager.color(level: 5).opacity(0.1) : .clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onToggleExpand()
        }
    }
}

//struct TDTagGroupHeaderView: View {
//    let group: TDSliderBarModel
//    let isHovered: Bool
//    @StateObject private var categoryManager = TDCategoryManager.shared
//    
//    var body: some View {
//        HStack {
//            
//            Label {
//                Text(group.categoryName)
//                    .font(.system(size: 13))
//                    .foregroundStyle(.greyColor6)
//
//            } icon: {
//                Image(systemName: group.headerIcon)
//                    .font(.system(size: 13))
//                    .foregroundColor(.marrsGreenColor6)
//            }
//            Spacer()
//            if isHovered {
//                HStack(spacing: 8) {
//                    Button(action: {}) {
//                        Image(systemName: "line.3.horizontal.decrease")
//                    }
//                    Button(action: { categoryManager.toggleGroup(group.categoryId) }) {
//                        Image(systemName: group.isSelect ? "chevron.down" : "chevron.right")
//                    }
//                }
//                .buttonStyle(.plain)
//            }
//        }
//        .padding(.leading,10)
//        .frame(height: 28)
//    }
//}
//
//#Preview {
//    TDTagGroupHeaderView(group: TDSliderBarModel(), isHovered: false)
//}
