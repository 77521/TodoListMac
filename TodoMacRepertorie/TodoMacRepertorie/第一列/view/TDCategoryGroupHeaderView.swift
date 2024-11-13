//
//  TDCategoryGroupHeaderView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/13.
//

import SwiftUI

struct TDCategoryGroupHeaderView: View {
    let item: TDSliderBarModel
    let isHovered: Bool
    let onAddTap: () -> Void
    let onSettingsTap: () -> Void
    
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
                    Button(action: onAddTap) {
                        Image(systemName: "plus")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("新增分类")  // 添加提示
                    
                    Button(action: onSettingsTap) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("分类设置")  // 添加提示
                    
                    Image(systemName: item.isSelect ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .frame(width: 12)  // 固定宽度，避免切换时抖动
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
    TDCategoryGroupHeaderView(item: TDSliderBarModel(), isHovered: false, onAddTap: {}, onSettingsTap: {})
}
