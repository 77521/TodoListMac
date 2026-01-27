//
//  TDSliderBarView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI

struct TDSliderBarView: View {
    @StateObject private var viewModel = TDSliderBarViewModel.shared
    @ObservedObject private var themeManager = TDThemeManager.shared
    @ObservedObject private var settingManager = TDSettingManager.shared
    
    // 悬停状态管理
    @State private var hoveredCategoryId: Int? = nil
    @State private var isCategoryGroupHovered: Bool = false

    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部固定区域（不滚动）
            topFixedArea
            
            // 可滚动的列表区域
            List {
                // 主要分类
                mainCategoriesSection
                
                // 分类清单组
                categoryListSection
                
                // 工具选项
                utilitySection
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            
            // 底部同步状态（不滚动）
            syncStatusView
            
        }
        .sheet(isPresented: $viewModel.showSheet) {
            TDNewCategorySheet(isPresented: $viewModel.showSheet)
                .environmentObject(themeManager)
        }
        .sheet(item: $viewModel.editingCategory) { item in
            TDEditCategorySheet(
                isPresented: Binding(
                    get: { viewModel.editingCategory != nil },
                    set: { if !$0 { viewModel.editingCategory = nil } }
                ),
                category: item,
                onSaved: {}
            )
            .environmentObject(themeManager)
        }
        .alert("common.alert.title".localized, isPresented: $viewModel.showDeleteAlert) {
            Button("delete".localized, role: .destructive) {
                Task { await viewModel.confirmDeleteCategory() }
            }
            Button("common.cancel".localized, role: .cancel) {
                viewModel.cancelDeleteCategory()
            }
        } message: {
            Text("category.context.delete.confirm".localizedFormat(viewModel.deletingCategory?.categoryName ?? ""))
        }

//        .background(Color(.clear))
    }
    

    
    // MARK: - 顶部固定区域
    private var topFixedArea: some View {
        VStack(spacing: 0) {
            // 用户信息
            TDUserInfoView()
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                TextField("搜索事件", text: .constant(""))
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 14))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // 分割线
            Divider()
                .padding(.horizontal, 16)
        }
//        .background(Color(.clear))
    }
    
    // MARK: - 主要分类区域
    private var mainCategoriesSection: some View {
        Group {
            // DayTodo
            if let dayTodo = viewModel.items.first(where: { $0.categoryId == -100 }) {
                categoryRowView(dayTodo)
            }
            
            // 最近待办
            if let recentTodo = viewModel.items.first(where: { $0.categoryId == -101 }) {
                categoryRowView(recentTodo)
            }
            
            // 日程概览
            if let schedule = viewModel.items.first(where: { $0.categoryId == -102 }) {
                categoryRowView(schedule)
            }
            
            // 待办箱
            if let inbox = viewModel.items.first(where: { $0.categoryId == -103 }) {
                categoryRowView(inbox)
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    // MARK: - 分类清单组
    private var categoryListSection: some View {
        DisclosureGroup(
            isExpanded: $viewModel.isCategoryGroupExpanded,
            content: {
                // 用户分类列表（排除新建和管理）
                ForEach(viewModel.items.filter { $0.categoryId >= -1 && $0.categoryId != -2000 && $0.categoryId != -2001 }) { category in
                    if category.isFolder {
                        // 文件夹：使用 DisclosureGroup 展示子分类（即使没有子分类也要显示）
                        let isExpanded = Binding(
                            get: { viewModel.isFolderExpanded(folderId: category.categoryId) },
                            set: { _ in viewModel.toggleFolderExpanded(folderId: category.categoryId) }
                        )
                        
                        DisclosureGroup(
                            isExpanded: isExpanded,
                            content: {
                                if let children = category.children, !children.isEmpty {
                                    ForEach(children) { child in
                                        categoryRowView(child)
                                            .listRowInsets(EdgeInsets(top: 0, leading: -11, bottom: 0, trailing: 0))
                                            .listRowBackground(Color.clear)
                                            .listRowSeparator(.hidden)
                                    }
                                }
                            },
                            label: {
                                folderRowView(category, folderId: category.categoryId, isExpanded: isExpanded)
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        // 普通分类或顶级分类
                        categoryRowView(category)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                
                // 新建和管理项（在最后）
//                categoryRowView(TDSliderBarModel.newCategory)
//                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
//                    .listRowBackground(Color.clear)
//                    .listRowSeparator(.hidden)
//                
//                categoryRowView(TDSliderBarModel.manageCategory)
//                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
//                    .listRowBackground(Color.clear)
//                    .listRowSeparator(.hidden)
            },
            label: {
                categoryGroupHeaderView
            }
        )
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    
    // MARK: - 分类组头部
    private var categoryGroupHeaderView: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(themeManager.color(level: 5))
                .font(.system(size: 14))
            
            Text("分类清单")
                .font(.system(size: 14))
                .foregroundColor(themeManager.titleTextColor)
            
            Spacer()
            
            // 按钮组（鼠标悬停时显示）
            HStack(spacing: 10) {
                Button(action: {
                    viewModel.showSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()

                Button(action: {
                    viewModel.showSheet = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.titleTextColor)
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
                
            }
            .opacity(isCategoryGroupHovered ? 1 : 0)
        }
        .padding(.vertical, 8)
        .padding(.leading, 8)
        .contentShape(Rectangle())
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.2)) {
                isCategoryGroupHovered = isHovered
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.isCategoryGroupExpanded.toggle()
            }
        }
    }

    
    // MARK: - 工具选项区域
    private var utilitySection: some View {
        Group {
            // 数据统计
            if let stats = viewModel.items.first(where: { $0.categoryId == -106 }) {
                categoryRowView(stats)
            }
            
            // 最近已完成
            if let completed = viewModel.items.first(where: { $0.categoryId == -107 }) {
                categoryRowView(completed)
            }
            
            // 回收站
            if let trash = viewModel.items.first(where: { $0.categoryId == -108 }) {
                categoryRowView(trash)
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    // MARK: - 文件夹行视图（点击只展开/关闭，不选中）
    private func folderRowView(_ folder: TDSliderBarModel, folderId: Int, isExpanded: Binding<Bool>) -> some View {
        HStack(spacing: 6) {
            // 文件夹图标
            Image(systemName: "folder.fill")
                .foregroundColor(
                    folder.categoryColor.flatMap { Color.fromHex($0) } ?? themeManager.color(level: 5)
                )
                .font(.system(size: 14))

            // 文件夹名称
            Text(folder.categoryName)
                .font(.system(size: 14))
                .foregroundColor(themeManager.titleTextColor)
            
            Spacer()
            
            // 数量标签
            if let count = folder.unfinishedCount, count > 0 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeManager.color(level: 5))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.color(level: 1))
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, 8)
        .padding(.trailing, 16)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColorForCategory(folder))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            // 点击整个文件夹行时触发展开/关闭
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.wrappedValue.toggle()
            }
        }
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoveredCategoryId = isHovered ? folder.categoryId : nil
            }
        }
        .contextMenu {
            if folder.isServerCategoryListItem {
                Button("common.edit".localized) {
                    viewModel.beginEditCategory(folder)
                }
                Button("delete".localized, role: .destructive) {
                    viewModel.requestDeleteCategory(folder)
                }
            }
        }

        // 注意：文件夹的点击事件由 DisclosureGroup 处理，这里不需要 onTapGesture
    }

    // MARK: - 分类行视图
    private func categoryRowView(_ category: TDSliderBarModel) -> some View {
        HStack(spacing: 8) {
            // 图标或颜色圆圈
            if category.categoryId == 0 {
                // 未分类：使用空心圆圈
                Circle()
                    .stroke(themeManager.color(level: 6), lineWidth: 1)
                    .frame(width: 12, height: 12)
            } else if category.categoryId > 0, let categoryColor = category.categoryColor {
                // 服务器分类：使用实心颜色圆圈
                Circle()
                    .fill(Color.fromHex(categoryColor))
                    .frame(width: 12, height: 12)
            } else {
                // 系统分类：使用图标
                Image(systemName: category.headerIcon ?? "circle")
                    .foregroundColor(themeManager.color(level: 5))
                    .font(.system(size: 14))
            }

            // 分类名称
            Text(category.categoryName)
                .font(.system(size: 14))
                .foregroundColor(themeManager.titleTextColor)
            
            Spacer()
            
            // 数量标签
            if let count = category.unfinishedCount, count > 0 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeManager.color(level: 5))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.color(level: 1))
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColorForCategory(category))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            // 新建和管理项的特殊处理
            if category.categoryId == -2000 {
                // 新建
                viewModel.showAddCategorySheet()
            } else if category.categoryId == -2001 {
                // 管理
                viewModel.showAddCategorySheet() // 暂时使用同一个 sheet，后续可以改为管理界面
            } else {
                // 普通分类
                viewModel.selectCategory(category)
            }
        }
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoveredCategoryId = isHovered ? category.categoryId : nil
            }
        }
        .contextMenu {
            if category.isServerCategoryListItem {
                Button("common.edit".localized) {
                    viewModel.beginEditCategory(category)
                }
                Button("delete".localized, role: .destructive) {
                    viewModel.requestDeleteCategory(category)
                }
            }
        }

    }
    

    // MARK: - 背景色计算
    private func backgroundColorForCategory(_ category: TDSliderBarModel) -> Color {
        let isSelected = category.isSelect ?? false
        let isHovered = hoveredCategoryId == category.categoryId
        
        // 如果选中了，优先显示选中背景色
        if isSelected {
            if category.categoryId >= 0, let categoryColor = category.categoryColor {
                // 服务器分类：使用分类颜色 + 0.3 透明度
                return Color.fromHex(categoryColor).opacity(0.3)
            } else {
                // 系统分类：使用主题颜色 + 0.3 透明度
                return themeManager.color(level: 5).opacity(0.3)
            }
        }
        
        // 如果未选中但鼠标悬停
        if isHovered {
            if category.categoryId >= 0, let categoryColor = category.categoryColor {
                // 服务器分类：使用分类颜色 + 0.2 透明度
                return Color.fromHex(categoryColor).opacity(0.2)
            } else {
                // 系统分类：使用主题颜色 + 0.2 透明度
                return themeManager.color(level: 5).opacity(0.2)
            }
        }
        
        // 默认：无背景色
        return Color.clear
    }
    
    // MARK: - 同步状态视图
    private var syncStatusView: some View {
        VStack(spacing: 0) {
            // 分割线
            Divider()
                .padding(.horizontal, 16)
            
            // 同步状态内容
            HStack {
                Image(systemName: viewModel.isSyncing ? "arrow.triangle.2.circlepath" : "checkmark.circle")
                    .foregroundColor(viewModel.isSyncing ? .orange : .green)
                    .font(.system(size: 14))
                
                Text(viewModel.isSyncing ? "同步中..." : "已同步")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.descriptionTextColor)
                
                Spacer()
                
                if viewModel.isSyncing {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)
                } else {
                    Button(action: {
                        Task {
                            await TDMainViewModel.shared.performSyncSeparately()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()

                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(themeManager.secondaryBackgroundColor.opacity(0.8))
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
//        .ignoresSafeArea(.container, edges: .all)
        .background(Color(.clear))
    }

}


#Preview {
    TDSliderBarView()
        .frame(width: 280)
}
