//
//  TDCategoryRowView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/13.
//

import SwiftUI
import DynamicColor

// MARK: - 分类行
struct TDCategoryRowView: View {
    let category: TDSliderBarModel
    let isHovered: Bool
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category.displayIcon)
                .foregroundColor(foregroundColor)
                .frame(width: 16)
            
            Text(category.categoryName)
                .lineLimit(1)
                .foregroundColor(foregroundColor)
            
            Spacer()
            
            if category.dayTodoNoFinishNumber > 0 {
                Text("\(category.dayTodoNoFinishNumber)")
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
        )
    }
    
    // 前景色（图标和文字）
    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else {
            return category.categoryId == 0 ? .primary : (category.categoryColor.isEmpty ? .primary : Color(category.categoryColor))
        }
    }
    
    // 背景色
    private var backgroundColor: Color {
        if isSelected {
            // 未分类使用主题色，其他使用自己的分类颜色
            if category.categoryId == 0 {
                return Color.accentColor
            } else {
                // 如果没有设置颜色，使用默认主题色
                let baseColor = category.categoryColor.isEmpty ? Color.accentColor : Color(hexString: category.categoryColor)
                return baseColor.opacity(0.8)
            }
        } else if isHovered {
            return Color.gray.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}


#Preview {
    TDCategoryRowView(category: TDSliderBarModel(), isHovered: false, isSelected: false)
}
