//
//  TDScheduleFilterMenu.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/11.
//

import SwiftUI

/// 日程筛选菜单组件
struct TDScheduleFilterMenu: View {
    /// 主题管理器
    @EnvironmentObject private var themeManager: TDThemeManager
    
    /// 设置管理器
    @EnvironmentObject private var settingManager: TDSettingManager
    
    /// 日程概览视图模型
    @StateObject private var viewModel = TDScheduleOverviewViewModel.shared
    
    /// 选中的分类回调
    let onCategorySelected: (TDSliderBarModel?) -> Void
    
    /// 标签筛选回调
    let onTagFiltered: (String) -> Void
    
    /// 排序类型回调
    let onSortChanged: (Int) -> Void
    
    /// 取消筛选回调
    let onClearFilter: () -> Void
    
    var body: some View {
        Menu {
            // 分类筛选部分
            Menu("选择分类") {
                // 全部分类
                Button("全部") {
                    onCategorySelected(nil)
                }
                
                Divider()
                
                // 分类列表
                ForEach(viewModel.availableCategories, id: \.categoryId) { category in
                    Button(action: {
                        onCategorySelected(category)
                    }) {
                        HStack {
                            Image.fromHexColor(category.categoryColor ?? "#c3c3c3", width: 14, height: 14, cornerRadius: 7.0)
                                .resizable()
                                .frame(width: 14.0, height: 14.0)
                            
                            Text(String(category.categoryName.prefix(8)))
                                .font(.system(size: 12))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                }
            }
            
            Divider()
            
//            // 标签筛选部分
//            Menu("标签筛选") {
//                Button("全部") {
//                    onTagFiltered("")
//                }
//                
//                Divider()
//                
//                // 常用标签（这里可以后续从数据中获取）
//                let commonTags = ["紧急", "重要", "工作", "生活", "学习"]
//                ForEach(commonTags, id: \.self) { tag in
//                    Button(tag) {
//                        onTagFiltered(tag)
//                    }
//                }
//            }
//            
//            Divider()
            
            // 排序选项
                        Menu("排序方式") {
                            Button(action: {
                                onSortChanged(0)
                            }) {
                                HStack {
                                    Text("默认排序")
                                    Spacer()
                                    if viewModel.sortType == 0 {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(themeManager.color(level: 5))
                                    }
                                }
                            }
                            
                            Button(action: {
                                onSortChanged(1)
                            }) {
                                HStack {
                                    Text("提醒时间")
                                    Spacer()
                                    if viewModel.sortType == 1 {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(themeManager.color(level: 5))
                                    }
                                }
                            }
                            
                            Button(action: {
                                onSortChanged(2)
                            }) {
                                HStack {
                                    Text("添加时间 (早→晚)")
                                    Spacer()
                                    if viewModel.sortType == 2 {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(themeManager.color(level: 5))
                                    }
                                }
                            }
                            
                            Button(action: {
                                onSortChanged(3)
                            }) {
                                HStack {
                                    Text("添加时间 (晚→早)")
                                    Spacer()
                                    if viewModel.sortType == 3 {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(themeManager.color(level: 5))
                                    }
                                }
                            }
                            
                            Button(action: {
                                onSortChanged(4)
                            }) {
                                HStack {
                                    Text("工作量 (少→多)")
                                    Spacer()
                                    if viewModel.sortType == 4 {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(themeManager.color(level: 5))
                                    }
                                }
                            }
                            
                            Button(action: {
                                onSortChanged(5)
                            }) {
                                HStack {
                                    Text("工作量 (多→少)")
                                    Spacer()
                                    if viewModel.sortType == 5 {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(themeManager.color(level: 5))
                                    }
                                }
                            }
                        }
            Divider()
            
            // 取消筛选
            Button("取消筛选") {
                onClearFilter()
            }
            .foregroundColor(.red)
            
        } label: {
            ZStack {
                // 主图标
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.titleTextColor)
                
                // 右下角小圆圈 - 根据选中分类显示颜色
                if let selectedCategory = viewModel.selectedCategory,
                   let categoryColor = selectedCategory.categoryColor {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.fromHex(categoryColor))
                                .frame(width: 8, height: 8)
                        }
                    }
                }

            }
            .contentShape(Rectangle()) // 让整个单元格区域都可以点击
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
        .frame(width: 32, height: 32)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(themeManager.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(themeManager.borderColor, lineWidth: 1)
                )
        )
    }
}

// MARK: - 预览
#Preview {
    TDScheduleFilterMenu(
        onCategorySelected: { _ in },
        onTagFiltered: { _ in },
        onSortChanged: { _ in },
        onClearFilter: { }
    )
    .environmentObject(TDThemeManager.shared)
    .environmentObject(TDSettingManager.shared)
}

