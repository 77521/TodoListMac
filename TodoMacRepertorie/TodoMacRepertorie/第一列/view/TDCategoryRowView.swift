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
    let item: TDSliderBarModel
    @Binding var selection: TDSliderBarModel?
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            // 只在未选中时进行选中操作
            if selection?.categoryId != item.categoryId {
                selection = item
            }
            // 如果已经选中，不做任何处理

        }) {
            HStack(spacing: 2) {
                Label {
                    Text(item.categoryName)
                        .font(.system(size: 13))
                    if item.dayTodoNoFinishNumber > 0 && item.categoryId == -100{
                        Spacer()
                        Text("\(item.dayTodoNoFinishNumber)")
                            .foregroundColor(isSelected ? .white : .greyColor6)
                            .font(.caption)
                    }
                } icon: {
                    
                    if item.categoryId <= 0 {
                        // 未分类使用普通图标
                        Image(systemName: item.headerIcon)
                            .foregroundColor(isSelected ? .white : .marrsGreenColor6)
                    } else {
                        // 其他分类使用彩色圆点
                        Image(systemName: "circle.fill")
                            .foregroundColor(Color.fromHex(item.categoryColor).opacity(0.7))
                    }

                    
                }
                Spacer()
            }
            .padding(.leading,9)
            .frame(height: 25)
//            .padding(.horizontal, 8)
//            .padding(.vertical, 2)
        }
        .buttonStyle(SidebarButtonStyle(isSelected: isSelected, isHovered: isHovered))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private var isSelected: Bool {
        selection?.categoryId == item.categoryId
    }

}
// 自定义按钮样式
struct SidebarButtonStyle: ButtonStyle {
    let isSelected: Bool
    let isHovered: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor(configuration.isPressed))
            )
            .foregroundColor(isSelected ? .white : .greyColor6)
    }
    
    private func backgroundColor(_ isPressed: Bool) -> Color {
        if isSelected {
            return .marrsGreenColor6
        } else if isPressed {
            return .greyColor1
        } else if isHovered {
            return .greyColor1
        }
        return .clear
    }
}

#Preview {
    TDCategoryRowView(item: TDSliderBarModel(), selection: .constant(TDSliderBarModel()))
}
