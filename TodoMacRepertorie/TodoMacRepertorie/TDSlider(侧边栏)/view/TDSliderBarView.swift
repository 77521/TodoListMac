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
    // 注意：不在此处观察 mainViewModel。
    // 搜索框已抽离为 TDSidebarSearchBar，由它自己订阅 mainViewModel，
    // 避免任务选择/日期切换等高频事件触发整个侧边栏重绘。

    
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

    /// macOS 26 Liquid Glass 标题栏高度（约 36pt），用于按钮浮层 frame
    /// 使按钮中心 = frame/2 ≈ 18pt，与 traffic lights 垂直居中对齐
    private let titleBarHeight: CGFloat = 36
    /// 侧边栏内容顶部间距（头像区域距顶部的距离）
    private let contentTopSpacing: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // macOS 26 hiddenTitleBar：内容从 y=0 开始渲染，
            // 预留 20pt 顶部空白让 traffic lights 区域不被内容覆盖
            Color.clear.frame(height: contentTopSpacing)

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
        // 整体使用毛玻璃背景，透出主窗口内容，产生侧滑栏「磨砂玻璃」半透明效果
        .background(.ultraThinMaterial)
        // ⊙ ⚙ 按钮浮层：不用系统 .toolbar{}，避免 macOS 26 Liquid Glass 强制注入玻璃背景。
        // 直接 overlay 在 VStack 右上角，绕过工具栏渲染管线，按钮纯图标无背景。
        // ignoresSafeArea：突破 macOS 安全区顶部内缩，令按钮与 traffic lights 同行对齐（y=0）
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 10) {
                // ⊙ 更多选项（设计稿要求）
                Button {
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .help("更多选项")

                // ⚙ 设置菜单
                TDSidebarSettingsMenu()
            }
            .frame(height: titleBarHeight)
            // 设计稿：按钮靠右，右侧留 8pt 边距
            .padding(.trailing, 8)
            // 突破顶部安全区（macOS title bar safe area），对齐 traffic lights 所在行
            .ignoresSafeArea(.container, edges: .top)
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
            
            // 搜索框（独立子视图，订阅 mainViewModel，不污染侧边栏主视图的渲染树）
            TDSidebarSearchBar()
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
                // 使用 ViewModel 缓存好的过滤数组，避免每次渲染重复 filter
                ForEach(viewModel.filteredCategoryListItems) { category in
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
    
    // MARK: - 同步状态视图（设计图：扁平底部条，顶部分隔线 + 全宽内容行）
    private var syncStatusView: some View {
        VStack(spacing: 0) {
            // 顶部分隔线（与列表区域划分）
            Divider()

            // 同步状态内容行
            HStack(spacing: 8) {
                // 图标：同步中用旋转箭头，已同步用绿色圆形勾选（匹配设计图）
                Image(systemName: viewModel.isSyncing ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill")
                    .foregroundColor(viewModel.isSyncing ? .secondary : .green)
                    .font(.system(size: 14))

                // 同步状态文字
                Text(viewModel.isSyncing ? "sidebar.sync.syncing".localized : "sidebar.sync.synced".localized)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.descriptionTextColor)

                Spacer()

                // 右侧：同步中显示 spinner，已同步显示手动刷新按钮
                if viewModel.isSyncing {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)
                } else {
                    Button(action: {
                        Task { await TDMainViewModel.shared.performSyncSeparately() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
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
            // 文件夹图标：有自定义颜色则用对应颜色，否则用次要灰色
            Image(systemName: "folder.fill")
                .foregroundColor(folder.categoryColor.flatMap { Color.fromHex($0) } ?? Color.secondary)
                .font(.system(size: iconFontSize))
                .frame(width: iconFrameSide, height: iconFrameSide, alignment: .center)

            Text(folder.categoryName)
                .font(.system(size: 13))
                .foregroundColor(themeManager.titleTextColor)

            Spacer()

            // 文件夹 badge：常驻显示
            if let count = folder.unfinishedCount, count > 0 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(themeManager.color(level: 5))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(themeManager.color(level: 1)))
                    .allowsHitTesting(false)
            }

            HStack(alignment: .center, spacing: 6) {
                // hover 时展示子分类数量
                Text("\(childCategoryCount)")
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.descriptionTextColor)
                    .opacity(isHovered ? 1 : 0)
                    .allowsHitTesting(false)

                // chevron 始终显示（用户可以感知文件夹是否可展开）
                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(themeManager.descriptionTextColor)
                        .font(.system(size: disclosureFontSize, weight: .semibold))
                        .frame(width: disclosureFrameSide, height: disclosureFrameSide, alignment: .center)
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
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

    // MARK: - 是否处于选中状态
    private var isSelected: Bool { category.isSelect ?? false }

    // MARK: - 图标/文字颜色（系统分类选中时变白，未选中用次要灰；用户分类彩色圆点不走此逻辑）
    private var iconColor: Color {
        guard category.categoryId < 0 else { return .clear } // 用户分类用彩色圆点，不用此颜色
        return isSelected ? .white : .secondary
    }

    private var textColor: Color {
        isSelected ? .white : themeManager.titleTextColor
    }

    // MARK: - badge 颜色（选中时用半透明白，否则用主题浅底色）
    private var badgeForeground: Color {
        isSelected ? .white : themeManager.color(level: 5)
    }
    private var badgeBackground: Color {
        isSelected ? Color.white.opacity(0.25) : themeManager.color(level: 1)
    }

    // MARK: - 行背景色
    /// 系统分类（categoryId < 0）选中时用主题实色；用户分类选中时用其分类色 30% 透明度
    private var backgroundColor: Color {
        if isSelected {
            if category.categoryId >= 0, let hex = category.categoryColor {
                return Color.fromHex(hex).opacity(0.3)
            }
            return themeManager.color(level: 5) // 系统分类：实色背景
        }
        if isHovered {
            if category.categoryId >= 0, let hex = category.categoryColor {
                return Color.fromHex(hex).opacity(0.2)
            }
            return themeManager.color(level: 5).opacity(0.15)
        }
        return .clear
    }

    var body: some View {
        HStack(spacing: interItemSpacing) {
            // 子分类缩进占位
            if leadingIndent > 0 {
                Color.clear.frame(width: leadingIndent)
            }

            // 图标
            iconView

            // 名称
            Text(category.categoryName)
                .font(.system(size: 13))
                .foregroundColor(textColor)
                .lineLimit(1)

            Spacer(minLength: 4)

            // badge：事件数量，始终显示（设计稿中常驻，不依赖 hover 状态）
            if let count = category.unfinishedCount, count > 0 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(badgeForeground)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(badgeBackground))
                    .allowsHitTesting(false)
            }
        }
        .padding(.vertical, 7)
        .padding(.leading, rowLeadingPadding)
        .padding(.trailing, rowTrailingPadding)
        .background(RoundedRectangle(cornerRadius: 6).fill(backgroundColor))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHovered = hovering }
        }
    }

    // MARK: - 图标视图
    /// 优先级：自定义图片资源 > 用户分类彩色圆点 > 未分类空心圆 > SF Symbol
    @ViewBuilder
    private var iconView: some View {
        if category.isCustomIcon == true, let name = category.headerIcon {
            // 自定义图片资源：将图片放入 Assets.xcassets，名称与 headerIcon 保持一致
            // 使用 .template 渲染模式，支持用 foregroundColor 着色（单色矢量图标）
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(iconColor)
                .frame(width: iconFontSize, height: iconFontSize)
                .frame(width: iconFrameSide, height: iconFrameSide, alignment: .center)
        } else if category.categoryId == 0 {
            // 未分类：空心圆
            Circle()
                .stroke(isSelected ? Color.white : themeManager.color(level: 6), lineWidth: 1.2)
                .frame(width: iconFontSize - 2, height: iconFontSize - 2)
                .frame(width: iconFrameSide, height: iconFrameSide, alignment: .center)
        } else if category.categoryId > 0, let hex = category.categoryColor {
            // 用户创建的分类：彩色实心圆（始终保持分类颜色，不随选中变白）
            Circle()
                .fill(Color.fromHex(hex))
                .frame(width: iconFontSize - 2, height: iconFontSize - 2)
                .frame(width: iconFrameSide, height: iconFrameSide, alignment: .center)
        } else {
            // 系统分类：SF Symbol（选中时变白）
            Image(systemName: category.headerIcon ?? "circle")
                .foregroundColor(iconColor)
                .font(.system(size: iconFontSize))
                .frame(width: iconFrameSide, height: iconFrameSide, alignment: .center)
        }
    }
}


// MARK: - 搜索框独立子视图
/// 将搜索框抽离为独立 View，自行订阅 TDMainViewModel。
/// 这样 mainViewModel 的高频事件（任务选中、日期切换等）只会触发此子视图重绘，
/// 而不会导致整个 TDSliderBarView 及其所有子行重新渲染，显著降低 CPU 开销。
private struct TDSidebarSearchBar: View {
    @ObservedObject private var mainViewModel = TDMainViewModel.shared

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14))

            TextField("sidebar.search.placeholder".localized, text: $mainViewModel.searchText, onEditingChanged: { editing in
                if editing { mainViewModel.isSearchActive = true }
            })
            .textFieldStyle(PlainTextFieldStyle())
            .font(.system(size: 14))
            .onTapGesture {
                mainViewModel.isSearchActive = true
            }
            .onChange(of: mainViewModel.searchText) { _, newValue in
                if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    mainViewModel.isSearchActive = true
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    TDSliderBarView()
        .frame(width: 280)
}
