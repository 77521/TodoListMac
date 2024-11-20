//
//  TDCategoryGroupHeaderView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/13.
//

import SwiftUI

struct TDCategoryGroupHeaderView: View {
    let group: TDSliderBarModel
    var isHovered: Bool
    let onAddCategory: () -> Void
    let onEditCategory: () -> Void
    @StateObject private var categoryManager = TDCategoryManager.shared
    
    var body: some View {
        
        HStack {
            
            Label {
                Text(group.categoryName)
                    .font(.system(size: 13))
                    .foregroundStyle(.greyColor6)

            } icon: {
                Image(systemName: group.headerIcon)
                    .font(.system(size: 13))
                    .foregroundColor(.marrsGreenColor6)
            }
            Spacer()
            if isHovered {
                HStack(spacing: 8) {
                    Button(action: onAddCategory) {
                        Image(systemName: "plus")
                            .font(.system(size: 13))
                    }
                    Button(action: onEditCategory) {
                        Image(systemName: "gear")
                            .font(.system(size: 13))
                    }
                    
                }
                .buttonStyle(.plain)
                
            }
        }
        .padding(.leading,10)
        
//        Button(action: {}) {
//            HStack {
//                Label {
//                    Text(group.categoryName)
//                        .font(.system(size: 13))
//                        .foregroundStyle(.greyColor6)
//
//                } icon: {
//                    Image(systemName: group.headerIcon)
//                        .font(.system(size: 13))
//                        .foregroundStyle(.marrsGreenColor6)
//
//                }
//                Spacer()
//                if isHovered {
//                    HStack(spacing: 8) {
//                        Button(action: onAddCategory) {
//                            Image(systemName: "plus")
//                                .font(.system(size: 13))
//                        }
//                        Button(action: onEditCategory) {
//                            Image(systemName: "gear")
//                                .font(.system(size: 13))
//                        }
//                        
//                    }
//                    .buttonStyle(.borderless)
//                }
//            }
//            .frame(height: 28)
//        }
//        .buttonStyle(SidebarButtonStyle(isSelected: false, isHovered: false))
//        .background(.red)
        
    }
}


//
//#Preview {
//    TDCategoryGroupHeaderView(item: TDSliderBarModel(), isHovered: false, onAddTap: {}, onSettingsTap: {})
//}
