//
//  TDCategoryGroupHeaderView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI

/// 分类清单组视图
struct TDCategoryGroupView: View {
    let title: String
    let icon: String
    var showAddButton = false
    var showSettingButton = false
    var showFilterButton = false
    var onAddTap: (() -> Void)?
    var onSettingTap: (() -> Void)?
    var onFilterTap: (() -> Void)?
    
    @State private var isHovered = false
    @ObservedObject private var themeManager = TDThemeManager.shared
    @ObservedObject private var settingManager = TDSettingManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(themeManager.color(level: 5))
            Text(title)
                .font(.system(size: settingManager.fontSize.size))
                .foregroundColor(themeManager.titleTextColor)
            
            Spacer()
            
            if isHovered {
                HStack(spacing: 4) {
                    if showAddButton {
                        Button(action: { onAddTap?() }) {
                            Image(systemName: "plus")
                                .foregroundColor(themeManager.color(level: 5))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if showSettingButton {
                        Button(action: { onSettingTap?() }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(themeManager.color(level: 5))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if showFilterButton {
                        Button(action: { onFilterTap?() }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(themeManager.color(level: 5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}


//struct TDCategoryGroupHeaderView: View {
//    let group: TDSliderBarModel
//    var isHovered: Bool
//    let onAddCategory: () -> Void
//    let onEditCategory: () -> Void
//    @StateObject private var categoryManager = TDCategoryManager.shared
//    
//    var body: some View {
//        
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
//                    Button(action: onAddCategory) {
//                        Image(systemName: "plus")
//                            .font(.system(size: 13))
//                    }
//                    Button(action: onEditCategory) {
//                        Image(systemName: "gear")
//                            .font(.system(size: 13))
//                    }
//                    
//                }
//                .buttonStyle(.plain)
//                
//            }
//        }
//        .padding(.leading,10)
//        
////        Button(action: {}) {
////            HStack {
////                Label {
////                    Text(group.categoryName)
////                        .font(.system(size: 13))
////                        .foregroundStyle(.greyColor6)
////
////                } icon: {
////                    Image(systemName: group.headerIcon)
////                        .font(.system(size: 13))
////                        .foregroundStyle(.marrsGreenColor6)
////
////                }
////                Spacer()
////                if isHovered {
////                    HStack(spacing: 8) {
////                        Button(action: onAddCategory) {
////                            Image(systemName: "plus")
////                                .font(.system(size: 13))
////                        }
////                        Button(action: onEditCategory) {
////                            Image(systemName: "gear")
////                                .font(.system(size: 13))
////                        }
////
////                    }
////                    .buttonStyle(.borderless)
////                }
////            }
////            .frame(height: 28)
////        }
////        .buttonStyle(SidebarButtonStyle(isSelected: false, isHovered: false))
////        .background(.red)
//        
//    }
//}
//
//
////
////#Preview {
////    TDCategoryGroupHeaderView(item: TDSliderBarModel(), isHovered: false, onAddTap: {}, onSettingsTap: {})
////}
