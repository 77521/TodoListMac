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

    
    // MARK: - 分类清单拖拽状态
    @State private var draggedCategoryListItemId: Int? = nil
    @State private var highlightedFolderId: Int? = nil

    // 侧边栏图标统一占位（让整列图标竖向对齐）
    /// 行内元素间距（箭头↔图标、图标↔文字）固定为 8
    private let sidebarInterItemSpacing: CGFloat = 8
    /// 子分类相对文件夹额外缩进 8
    private let sidebarChildIndent: CGFloat = 15
    /// 行内容整体靠左（不是 listRowInsets 整行缩进）
    private let sidebarRowLeadingPadding: CGFloat = 6
    private let sidebarRowTrailingPadding: CGFloat = 10 // 右侧额外 +13（在原基础上再 +5）
    /// 左侧图标：字号 14，容器 20×20
    private let sidebarIconFontSize: CGFloat = 14
    private let sidebarIconFrameSide: CGFloat = 20
    /// 展开/收起按钮：放最右侧（字号 11，容器 20×20）
    private let sidebarDisclosureFontSize: CGFloat = 11
    private let sidebarDisclosureFrameSide: CGFloat = 20

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
                // 标签管理组（在分类清单下面）
                tagManageSection

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
        // 点击「所有标签」后弹出标签管理弹窗（见：TDSliderBarViewModel.handleTagTap）
        .sheet(isPresented: $viewModel.showTagFilter) {
            TDTagFilterSheet(isPresented: $viewModel.showTagFilter)
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
        Group {
            // 自定义组头（避免 DisclosureGroup 自带箭头/缩进影响对齐）
            TDCategoryListGroupHeaderView(
                themeManager: themeManager,
                isExpanded: $viewModel.isCategoryGroupExpanded,
                sidebarInterItemSpacing: sidebarInterItemSpacing,
                sidebarDisclosureFontSize: sidebarDisclosureFontSize,
                sidebarDisclosureFrameSide: sidebarDisclosureFrameSide,
                sidebarIconFontSize: sidebarIconFontSize,
                sidebarIconFrameSide: sidebarIconFrameSide,
                sidebarRowLeadingPadding: sidebarRowLeadingPadding,
                sidebarRowTrailingPadding: sidebarRowTrailingPadding,
                onAdd: { viewModel.showSheet = true }
            )
            .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            if viewModel.isCategoryGroupExpanded {
                // 用户分类列表（排除新建和管理）
                ForEach(viewModel.items.filter { $0.categoryId >= -1 && $0.categoryId != -2000 && $0.categoryId != -2001 }) { category in
                    if category.isFolder {
                        // 文件夹：自定义展开（避免 DisclosureGroup 自带缩进导致不对齐）
                        let expanded = viewModel.isFolderExpanded(folderId: category.categoryId)

                        folderRowView(category, isExpanded: expanded) {
                            viewModel.toggleFolderExpanded(folderId: category.categoryId)
                        }
                        .onDrag {
                            // 长按/拖拽文件夹：如果当前是展开状态，先关闭（避免拖拽时 children 抖动/误触）
                            viewModel.collapseFolderIfExpanded(folderId: category.categoryId)
                            viewModel.beginCategoryListDragIfNeeded()
                            draggedCategoryListItemId = category.categoryId
                            return NSItemProvider(object: "\(category.categoryId)" as NSString)
                        }
                        .onDrop(of: [.text], delegate: SidebarCategoryListDropDelegate(
                            destinationId: category.categoryId,
                            destinationIsFolder: true,
                            viewModel: viewModel,
                            draggedId: $draggedCategoryListItemId,
                            highlightedFolderId: $highlightedFolderId
                        ))
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                        if expanded, let children = category.children, !children.isEmpty {
                            ForEach(children) { child in
                                categoryRowView(child, leadingIndent: sidebarChildIndent, enableCategoryListReorder: true)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                        }
                    } else {
                        // 普通分类或顶级分类
                        categoryRowView(category, enableCategoryListReorder: true)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                // 仅在拖拽分类清单时启用平滑移动动画（避免影响普通选中/数量刷新）
                .animation(draggedCategoryListItemId == nil ? nil : .easeInOut(duration: 0.12), value: viewModel.items)
            }
        }
    }
    
    // MARK: - 标签管理组
    private var tagManageSection: some View {
        Group {
            TDTagManageGroupHeaderView(
                themeManager: themeManager,
                isExpanded: $viewModel.isTagGroupExpanded,
                sortOption: $viewModel.tagSortOption,
                sidebarInterItemSpacing: sidebarInterItemSpacing,
                sidebarDisclosureFontSize: sidebarDisclosureFontSize,
                sidebarDisclosureFrameSide: sidebarDisclosureFrameSide,
                sidebarIconFontSize: sidebarIconFontSize,
                sidebarIconFrameSide: sidebarIconFrameSide,
                sidebarRowLeadingPadding: sidebarRowLeadingPadding,
                sidebarRowTrailingPadding: sidebarRowTrailingPadding
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            
            if viewModel.isTagGroupExpanded {
                // 标签列表（第一个永远是“所有标签”）
                TDTagFlowLayout(spacing: 6, lineSpacing: 6) {
                    ForEach(viewModel.sortedTagsArr, id: \.sidebarUniqueId) { tag in
                        let isAllTags = tag.tagKey == TDSliderBarModel.allTags.tagKey
                        let isSelected = (!isAllTags && tag.tagKey != nil && tag.tagKey == viewModel.selectedTagKey)
                        Button {
                            viewModel.handleTagTap(tag)
                        } label: {
                            Text(tag.categoryName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isSelected ? .white : themeManager.color(level: 5))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isSelected ? themeManager.color(level: 5) : themeManager.secondaryBackgroundColor)
                                )
                        }
                        .buttonStyle(.plain)
                        .pointingHandCursor()

                    }
                }
                // 与分组标题对齐：跳过“图标 + 图标↔文字间距”
                .padding(.leading, sidebarIconFrameSide + sidebarInterItemSpacing)
                .padding(.trailing, sidebarRowTrailingPadding)
                .padding(.vertical, 6)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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
    private func folderRowView(_ folder: TDSliderBarModel, isExpanded: Bool, onToggle: @escaping () -> Void) -> some View {
        let childCategoryCount = (folder.children ?? []).filter { !$0.isFolder }.count
        return SidebarFolderRowView(
            folder: folder,
            isExpanded: isExpanded,
            childCategoryCount: childCategoryCount,
            themeManager: themeManager,
            iconFontSize: sidebarIconFontSize,
            iconFrameSide: sidebarIconFrameSide,
            disclosureFontSize: sidebarDisclosureFontSize,
            disclosureFrameSide: sidebarDisclosureFrameSide,
            interItemSpacing: sidebarInterItemSpacing,
            rowLeadingPadding: sidebarRowLeadingPadding,
            rowTrailingPadding: sidebarRowTrailingPadding,
            isHighlighted: highlightedFolderId == folder.categoryId,
            onToggle: onToggle
        )
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
    }
    
    // MARK: - 分类行视图
    private func categoryRowView(_ category: TDSliderBarModel, leadingIndent: CGFloat = 0, enableCategoryListReorder: Bool = false) -> some View {
        SidebarCategoryRowView(
            category: category,
            leadingIndent: leadingIndent,
            themeManager: themeManager,
            iconFontSize: sidebarIconFontSize,
            iconFrameSide: sidebarIconFrameSide,
            interItemSpacing: sidebarInterItemSpacing,
            rowLeadingPadding: sidebarRowLeadingPadding,
            rowTrailingPadding: sidebarRowTrailingPadding,
            onTap: {
                // 新建和管理项的特殊处理
                if category.categoryId == -2000 {
                    viewModel.showAddCategorySheet()
                } else if category.categoryId == -2001 {
                    viewModel.showAddCategorySheet()
                } else {
                    viewModel.selectCategory(category)
                }
            }
        )
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
        .modifier(CategoryListDragDropModifier(
            enable: enableCategoryListReorder,
            category: category,
            viewModel: viewModel,
            draggedId: $draggedCategoryListItemId,
            highlightedFolderId: $highlightedFolderId
        ))
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

// MARK: - 分类清单拖拽：DropDelegate

private struct SidebarCategoryListDropDelegate: DropDelegate {
    let destinationId: Int
    let destinationIsFolder: Bool
    let viewModel: TDSliderBarViewModel
    @Binding var draggedId: Int?
    @Binding var highlightedFolderId: Int?

    func dropEntered(info: DropInfo) {
        guard let draggedId, draggedId > 0, draggedId != destinationId else { return }

        // 目标是文件夹：分类悬停仅高亮，实际“放入文件夹”在 performDrop 做
        if destinationIsFolder {
            if let draggedItem = viewModel.categorySource.first(where: { $0.categoryId == draggedId }),
               draggedItem.isFolder == false {
                highlightedFolderId = destinationId
                return
            }
            // 拖拽的是文件夹：按顶级排序实时移动
            highlightedFolderId = nil
            viewModel.hoverMoveCategoryListItem(draggedId: draggedId, destinationId: destinationId)
            return
        }

        highlightedFolderId = nil
        viewModel.hoverMoveCategoryListItem(draggedId: draggedId, destinationId: destinationId)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedId, draggedId > 0 else {
            highlightedFolderId = nil
            return true
        }

        if destinationIsFolder {
            // 放入文件夹：默认末尾
            viewModel.dropCategoryIntoFolder(draggedId: draggedId, folderId: destinationId)
        }

        highlightedFolderId = nil
        self.draggedId = nil

        Task {
            await viewModel.commitCategoryListDrag()
        }
        return true
    }

    func dropExited(info: DropInfo) {
        if destinationIsFolder, highlightedFolderId == destinationId {
            highlightedFolderId = nil
        }
    }
}

// MARK: - 分类清单拖拽：统一 modifier（只对“分类清单”启用）

private struct CategoryListDragDropModifier: ViewModifier {
    let enable: Bool
    let category: TDSliderBarModel
    let viewModel: TDSliderBarViewModel
    @Binding var draggedId: Int?
    @Binding var highlightedFolderId: Int?

    func body(content: Content) -> some View {
        guard enable else { return AnyView(content) }

        // 仅允许拖拽服务器分类清单（categoryId > 0）；未分类(0)和系统项(负数)不允许拖拽
        let canDrag = category.isServerCategoryListItem && category.categoryId != 0

        if canDrag {
            return AnyView(
                content
                    .onDrag {
                        viewModel.beginCategoryListDragIfNeeded()
                        draggedId = category.categoryId
                        return NSItemProvider(object: "\(category.categoryId)" as NSString)
                    }
                    .onDrop(of: [.text], delegate: SidebarCategoryListDropDelegate(
                        destinationId: category.categoryId,
                        destinationIsFolder: false,
                        viewModel: viewModel,
                        draggedId: $draggedId,
                        highlightedFolderId: $highlightedFolderId
                    ))
            )
        } else {
            return AnyView(
                content
                    .onDrop(of: [.text], delegate: SidebarCategoryListDropDelegate(
                        destinationId: category.categoryId,
                        destinationIsFolder: false,
                        viewModel: viewModel,
                        draggedId: $draggedId,
                        highlightedFolderId: $highlightedFolderId
                    ))
            )
        }
    }
}

// MARK: - Sidebar Row Views (每行独立悬停状态，避免互相影响)

private struct SidebarFolderRowView: View {
    let folder: TDSliderBarModel
    let isExpanded: Bool
    let childCategoryCount: Int
    let themeManager: TDThemeManager
    let iconFontSize: CGFloat
    let iconFrameSide: CGFloat
    let disclosureFontSize: CGFloat
    let disclosureFrameSide: CGFloat
    let interItemSpacing: CGFloat
    let rowLeadingPadding: CGFloat
    let rowTrailingPadding: CGFloat
    let isHighlighted: Bool
    let onToggle: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: interItemSpacing) {
            Image(systemName: "folder.fill")
                .foregroundColor(folder.categoryColor.flatMap { Color.fromHex($0) } ?? themeManager.color(level: 5))
                .font(.system(size: iconFontSize))
                .frame(width: iconFrameSide, height: iconFrameSide, alignment: .center)

            Text(folder.categoryName)
                .font(.system(size: 13))
                .foregroundColor(themeManager.titleTextColor)

            Spacer()

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
                    .opacity(isHovered ? 1 : 0)
                    .allowsHitTesting(false)
            }

            HStack(alignment: .center, spacing: 10) {
                Text("\(childCategoryCount)")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.descriptionTextColor)
                    .opacity(isHovered ? 1 : 0)
                    .allowsHitTesting(false)

                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(themeManager.descriptionTextColor)
                        .font(.system(size: disclosureFontSize, weight: .semibold))
                        .frame(width: disclosureFrameSide, height: disclosureFrameSide, alignment: .center)
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                .opacity(isHovered ? 1 : 0)
                .allowsHitTesting(isHovered)
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, rowLeadingPadding)
        .padding(.trailing, rowTrailingPadding)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isHighlighted ? themeManager.color(level: 5) : Color.clear, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }

    private var backgroundColor: Color {
        guard isHovered else { return .clear }
        if let categoryColor = folder.categoryColor {
            return Color.fromHex(categoryColor).opacity(0.2)
        }
        return themeManager.color(level: 5).opacity(0.2)
    }
}

private struct SidebarCategoryRowView: View {
    let category: TDSliderBarModel
    let leadingIndent: CGFloat
    let themeManager: TDThemeManager
    let iconFontSize: CGFloat
    let iconFrameSide: CGFloat
    let interItemSpacing: CGFloat
    let rowLeadingPadding: CGFloat
    let rowTrailingPadding: CGFloat
    let onTap: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: interItemSpacing) {
            if leadingIndent > 0 {
                Color.clear.frame(width: leadingIndent)
            }

            iconView

            Text(category.categoryName)
                .font(.system(size: 13))
                .foregroundColor(themeManager.titleTextColor)

            Spacer()

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
                    .opacity(isHovered ? 1 : 0)
                    .allowsHitTesting(false)
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, rowLeadingPadding)
        .padding(.trailing, rowTrailingPadding)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }

    private var isSelected: Bool { category.isSelect ?? false }

    private var iconView: some View {
        Group {
            if category.categoryId == 0 {
                Circle()
                    .stroke(themeManager.color(level: 6), lineWidth: 1)
                    .frame(width: iconFontSize, height: iconFontSize)
                    .frame(width: iconFrameSide, height: iconFrameSide, alignment: .center)
            } else if category.categoryId > 0, let categoryColor = category.categoryColor {
                Circle()
                    .fill(Color.fromHex(categoryColor))
                    .frame(width: iconFontSize, height: iconFontSize)
                    .frame(width: iconFrameSide, height: iconFrameSide, alignment: .center)
            } else {
                Image(systemName: category.headerIcon ?? "circle")
                    .foregroundColor(themeManager.color(level: 5))
                    .font(.system(size: iconFontSize))
                    .frame(width: iconFrameSide, height: iconFrameSide, alignment: .center)
            }
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            if category.categoryId >= 0, let categoryColor = category.categoryColor {
                return Color.fromHex(categoryColor).opacity(0.3)
            }
            return themeManager.color(level: 5).opacity(0.3)
        }

        if isHovered {
            if category.categoryId >= 0, let categoryColor = category.categoryColor {
                return Color.fromHex(categoryColor).opacity(0.2)
            }
            return themeManager.color(level: 5).opacity(0.2)
        }

        return .clear
    }
}


#Preview {
    TDSliderBarView()
        .frame(width: 280)
}
