//
//  TDCategoryRowView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI

// MARK: - 分类行视图
/// 分类行视图
struct TDCategoryRowView: View {
    let item: TDSliderBarModel
    @State private var isHovered = false
    @ObservedObject private var themeManager = TDThemeManager.shared
    @ObservedObject private var settingManager = TDSettingManager.shared
    
    var body: some View {
        HStack(spacing: 8) {
            // 1. 左侧图标
            leadingIcon
            
            // 2. 名称
            Text(item.categoryName)
                .font(.system(size: settingManager.fontSize.size))
                .foregroundColor(textColor)
            
            Spacer()
            
            // 3. 未完成数量(仅 DayTodo 显示)
            if item.categoryId == -100 && item.unfinishedCount ?? 0 > 0 {
                Text("\(String(describing: item.unfinishedCount))")
                    .font(.system(size: settingManager.fontSize.size - 2))
                    .foregroundColor(item.isSelect ?? false ? .white : themeManager.primaryTextColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(item.isSelect ?? false ? Color.white.opacity(0.2) : themeManager.color(level: 5).opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            backgroundStyle
                .cornerRadius(6)
//                .padding(.horizontal, 8)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    // MARK: - 视图组件
    
    private var leadingIcon: some View {
        Group {
            if let color = item.categoryColor {
                // 使用颜色圆点
                Circle()
                    .fill(Color.fromHex(color))
                    .frame(width: 12, height: 12)
            } else if item.categoryId == 0 {
                // 未分类使用问号图标
                Image(systemName: "questionmark.circle")
                    .foregroundColor(iconColor)
            } else {
                // 使用系统图标
                Image(systemName: item.headerIcon ?? "")
                    .foregroundColor(iconColor)
            }
        }
    }
    
    // MARK: - 样式属性
    
    private var iconColor: Color {
        if item.categoryId == -108 {
            // 回收站使用默认文字颜色
            if item.isSelect ?? false {
                // 选中状态使用白色
                return .white
            }
            return themeManager.primaryTextColor
        }
        if item.isSelect ?? false {
            // 选中状态使用白色
            return .white
        }
        // 未选中状态使用主题色
        return themeManager.color(level: 5)
    }
    
    private var textColor: Color {
        if item.categoryId == -108 {
            // 回收站使用默认文字颜色
            if item.isSelect ?? false {
                // 选中状态使用白色
                return .white
            }
            return themeManager.primaryTextColor
        }
        if item.isSelect ?? false {
            // 选中状态使用白色
            return .white
        }
        // 未选中状态使用默认文字颜色
        return themeManager.primaryTextColor
    }
    
    private var backgroundStyle: Color {
        if item.isSelect ?? false {
            // 选中状态使用主题色
            return themeManager.color(level: 5)
        }
        if isHovered {
            // hover 状态使用半透明主题色
            return themeManager.color(level: 5).opacity(0.2)
        }
        return .clear
    }
}
//// MARK: - 分类行
//struct TDCategoryRowView: View {
//    let item: TDSliderBarModel
//    @Binding var selection: TDSliderBarModel?
//    @State private var isHovered = false
//
//    var body: some View {
//        Button(action: {
//            // 只在未选中时进行选中操作
//            if selection?.categoryId != item.categoryId {
//                selection = item
//            }
//            // 如果已经选中，不做任何处理
//
//        }) {
//            HStack(spacing: 2) {
//                Label {
//                    Text(item.categoryName)
//                        .font(.system(size: 13))
//                    if item.dayTodoNoFinishNumber > 0 && item.categoryId == -100{
//                        Spacer()
//                        Text("\(item.dayTodoNoFinishNumber)")
//                            .foregroundColor(isSelected ? .white : .greyColor6)
//                            .font(.caption)
//                    }
//                } icon: {
//
//                    if item.categoryId <= 0 {
//                        // 未分类使用普通图标
//                        Image(systemName: item.headerIcon)
//                            .foregroundColor(isSelected ? .white : .marrsGreenColor6)
//                    } else {
//                        // 其他分类使用彩色圆点
//                        Image(systemName: "circle.fill")
//                            .foregroundColor(Color.fromHex(item.categoryColor).opacity(0.7))
//                    }
//
//
//                }
//                Spacer()
//            }
//            .padding(.leading,9)
//            .frame(height: 25)
////            .padding(.horizontal, 8)
////            .padding(.vertical, 2)
//        }
//        .buttonStyle(SidebarButtonStyle(isSelected: isSelected, isHovered: isHovered))
//        .onHover { hovering in
//            withAnimation(.easeInOut(duration: 0.15)) {
//                isHovered = hovering
//            }
//        }
//    }
//
//    private var isSelected: Bool {
//        selection?.categoryId == item.categoryId
//    }
//
//}
//// 自定义按钮样式
//struct SidebarButtonStyle: ButtonStyle {
//    let isSelected: Bool
//    let isHovered: Bool
//
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .frame(maxWidth: .infinity)
//            .background(
//                RoundedRectangle(cornerRadius: 6)
//                    .fill(backgroundColor(configuration.isPressed))
//            )
//            .foregroundColor(isSelected ? .white : .greyColor6)
//    }
//
//    private func backgroundColor(_ isPressed: Bool) -> Color {
//        if isSelected {
//            return .marrsGreenColor6
//        } else if isPressed {
//            return .greyColor1
//        } else if isHovered {
//            return .greyColor1
//        }
//        return .clear
//    }
//}
//
////#Preview {
////    TDCategoryRowView(item: TDSliderBarModel(), selection: .constant(TDSliderBarModel()))
////}
