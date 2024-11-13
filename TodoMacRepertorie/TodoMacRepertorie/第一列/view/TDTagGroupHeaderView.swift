//
//  TDTagGroupHeaderView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/13.
//

import SwiftUI

struct TDTagGroupHeaderView: View {
    let item: TDSliderBarModel
    let isHovered: Bool
    @State private var showTagFilter = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.displayIcon)
                .foregroundColor(.primary)
                .frame(width: 16)
            
            Text(item.categoryName)
                .lineLimit(1)
                .font(.headline)  // 加粗显示组标题
            
            Spacer()
            
            if isHovered {
                HStack(spacing: 12) {
                    Button(action: { showTagFilter.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("标签筛选")  // 添加提示
                    .popover(isPresented: $showTagFilter) {
//                        TagFilterView()
                    }
                    
                    Image(systemName: item.isSelect ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .frame(width: 12)
                }
            } else {
                // 不悬停时也显示箭头，保持布局稳定
                Image(systemName: item.isSelect ? "chevron.down" : "chevron.right")
                    .foregroundColor(.secondary)
                    .frame(width: 12)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    TDTagGroupHeaderView(item: TDSliderBarModel(), isHovered: false)
}
