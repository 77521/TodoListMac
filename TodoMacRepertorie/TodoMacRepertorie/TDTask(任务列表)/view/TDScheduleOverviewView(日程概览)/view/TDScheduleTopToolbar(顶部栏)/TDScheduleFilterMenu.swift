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
    
    /// 当前用户的标签数据
    @State private var allTags: [TDTagModel] = []
    
    /// 分类数据源：使用和 TDCategoryPickerMenu 相同的逻辑
    private var categoryItems: [TDSliderBarModel] {
        // 1) 只取服务器真实数据（含文件夹/分类，id>0）
        let all = TDCategoryManager.shared.loadLocalCategories()
        let server = all.filter { $0.categoryId > 0 }
        // 2) 按 iOS 逻辑组装文件夹 + 子分类结构
        let processed = TDCategoryManager.shared.getFolderWithSubCategories(from: server)
        // 3) 过滤：文件夹内无数据则不显示
        return processed.filter { item in
            if item.isFolder {
                return !(item.children ?? []).isEmpty
            }
            return true
        }
    }
    
    var body: some View {
        Menu {
            // 分类筛选部分 - 使用和 TDCategoryPickerMenu 相同的逻辑
            Menu("选择分类") {
                // 全部选项（带勾选状态）
                Button {
                    onCategorySelected(nil)
                } label: {
                    HStack {
                        Text("全部")
                            .font(.system(size: TDAppConfig.menuFontSize))
                        Spacer()
                        if viewModel.selectedCategory == nil && viewModel.tagFilter.isEmpty {
                            Image(systemName: "checkmark")
                                .font(.system(size: TDAppConfig.menuIconSize))
                        }
                    }
                }
                
                // 分割线：把"全部"与分类清单区分开
                if !categoryItems.isEmpty {
                    Divider()
                }
                
                // 分类清单：支持文件夹（子菜单）- 使用和 TDCategoryPickerMenu 相同的逻辑
                ForEach(categoryItems) { item in
                    if item.isFolder, let children = item.children, !children.isEmpty {
                        Menu {
                            ForEach(children) { child in
                                Button {
                                    onCategorySelected(child)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image.fromHexColor(child.categoryColor ?? "#c3c3c3", width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize, cornerRadius: 7.0)
                                            .resizable()
                                            .frame(width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize)
                                        Text(String(child.categoryName.prefix(8)))
                                            .font(.system(size: TDAppConfig.menuFontSize))
                                        Spacer()
                                        if viewModel.selectedCategory?.categoryId == child.categoryId {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: TDAppConfig.menuIconSize))
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if let folderColor = item.categoryColor, !folderColor.isEmpty {
                                    Image.fromSystemName("folder.fill", hexColor: folderColor, size: TDAppConfig.menuIconSize)
                                } else {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(themeManager.color(level: 5))
                                        .font(.system(size: TDAppConfig.menuIconSize))
                                }
                                Text(item.categoryName)
                                    .font(.system(size: TDAppConfig.menuFontSize))
                            }
                        }
                    } else {
                        Button {
                            onCategorySelected(item)
                        } label: {
                            HStack(spacing: 8) {
                                Image.fromHexColor(item.categoryColor ?? "#c3c3c3", width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize, cornerRadius: 7.0)
                                    .resizable()
                                    .frame(width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize)
                                Text(String(item.categoryName.prefix(8)))
                                    .font(.system(size: TDAppConfig.menuFontSize))
                                Spacer()
                                if viewModel.selectedCategory?.categoryId == item.categoryId {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: TDAppConfig.menuIconSize))
                                }
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // 标签筛选部分（与分类互斥：选标签会清除分类，选分类会清除标签）
            Menu("标签筛选") {
                Button {
                    onTagFiltered("")
                } label: {
                    HStack {
                        Text("全部")
                            .font(.system(size: TDAppConfig.menuFontSize))
                        Spacer()
                        if viewModel.tagFilter.isEmpty {
                            Image(systemName: "checkmark")
                                .font(.system(size: TDAppConfig.menuIconSize))
                        }
                    }
                }
                
                if !allTags.isEmpty {
                    Divider()
                    ForEach(allTags.prefix(30), id: \.persistentModelID) { tag in
                        Button {
                            onTagFiltered(tag.key)
                        } label: {
                            HStack {
                                Text(tag.display)
                                    .font(.system(size: TDAppConfig.menuFontSize))
                                Spacer()
                                if viewModel.tagFilter == tag.key {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: TDAppConfig.menuIconSize))
                                }
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // 排序选项
            Menu("排序方式") {
                Button(action: {
                    onSortChanged(0)
                }) {
                    HStack {
                        Text("默认排序")
                            .font(.system(size: TDAppConfig.menuFontSize))
                        Spacer()
                        if viewModel.sortType == 0 {
                            Image(systemName: "checkmark")
                                .font(.system(size: TDAppConfig.menuIconSize))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
                
                Button(action: {
                    onSortChanged(1)
                }) {
                    HStack {
                        Text("提醒时间")
                            .font(.system(size: TDAppConfig.menuFontSize))
                        Spacer()
                        if viewModel.sortType == 1 {
                            Image(systemName: "checkmark")
                                .font(.system(size: TDAppConfig.menuIconSize))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
                
                Button(action: {
                    onSortChanged(2)
                }) {
                    HStack {
                        Text("添加时间 (早→晚)")
                            .font(.system(size: TDAppConfig.menuFontSize))
                        Spacer()
                        if viewModel.sortType == 2 {
                            Image(systemName: "checkmark")
                                .font(.system(size: TDAppConfig.menuIconSize))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
                
                Button(action: {
                    onSortChanged(3)
                }) {
                    HStack {
                        Text("添加时间 (晚→早)")
                            .font(.system(size: TDAppConfig.menuFontSize))
                        Spacer()
                        if viewModel.sortType == 3 {
                            Image(systemName: "checkmark")
                                .font(.system(size: TDAppConfig.menuIconSize))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
                
                Button(action: {
                    onSortChanged(4)
                }) {
                    HStack {
                        Text("工作量 (少→多)")
                            .font(.system(size: TDAppConfig.menuFontSize))
                        Spacer()
                        if viewModel.sortType == 4 {
                            Image(systemName: "checkmark")
                                .font(.system(size: TDAppConfig.menuIconSize))
                                .foregroundColor(themeManager.color(level: 5))
                        }
                    }
                }
                
                Button(action: {
                    onSortChanged(5)
                }) {
                    HStack {
                        Text("工作量 (多→少)")
                            .font(.system(size: TDAppConfig.menuFontSize))
                        Spacer()
                        if viewModel.sortType == 5 {
                            Image(systemName: "checkmark")
                                .font(.system(size: TDAppConfig.menuIconSize))
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
                    .font(.system(size: TDAppConfig.menuIconSize))
                    .foregroundColor(themeManager.titleTextColor)
                
                // 右下角小圆圈：仅在选中分类时显示分类颜色，选标签时不显示圆点（两者互斥）
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
            .contentShape(Rectangle())
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .pointingHandCursor()
        .frame(width: 40, height: 40)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(themeManager.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(themeManager.borderColor, lineWidth: 1)
                )
        )
        .onAppear {
            loadTags()
        }
    }
    
    // MARK: - 私有方法
    
    /// 加载当前用户的标签数据
    private func loadTags() {
        let userId = TDUserManager.shared.userId
        let context = TDModelContainer.shared.mainContext
        // 按使用数量降序，取最多 30 个常用标签
        allTags = TDTagManager.shared.fetchAllTags(userId: userId, context: context)
            .sorted { $0.taskCount > $1.taskCount }
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

