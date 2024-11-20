//
//  TDTagGroupHeaderView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/13.
//

import SwiftUI

struct TDTagGroupHeaderView: View {
    let group: TDSliderBarModel
    let isHovered: Bool
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
                    Button(action: {}) {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    Button(action: { categoryManager.toggleGroup(group.categoryId) }) {
                        Image(systemName: group.isSelect ? "chevron.down" : "chevron.right")
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading,10)
        .frame(height: 28)
    }
}

#Preview {
    TDTagGroupHeaderView(group: TDSliderBarModel(), isHovered: false)
}
