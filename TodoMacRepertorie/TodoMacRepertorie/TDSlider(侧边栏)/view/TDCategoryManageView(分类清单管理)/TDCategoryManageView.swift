//
//  TDCategoryManageView.swift
//  TodoMacRepertorie
//
//  分类清单管理 Sheet：
//  - 展示逻辑与侧滑栏「分类清单」一致（复用 TDSliderBarViewModel 数据源）
//  - 拖拽排序 / 放入文件夹：完全复用侧滑栏 hoverMove + dropIntoFolder + listSort 算法
//  - 拖拽过程中仅更新 UI，松手后 commitCategoryListDrag 落盘同步
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - 分类管理 Sheet
//
// 文件夹展开/收起：不用 List + DisclosureGroup 那套——macOS 上 List 对"行高度变化"的动画
// 支持很不稳定，反复调试（自定义 DisclosureGroupStyle / 系统默认样式 / 各种 .animation 写法）
// 都拿不到平滑效果。改用最朴素、最可控的 SwiftUI 手法：普通 ScrollView + VStack，子分类
// 是否显示交给 `if expanded { ForEach {...} }`，外面套 .transition + .clipped，切换状态时
// 用 withAnimation 包一层——这是 SwiftUI 里"插入/移除视图"动画最稳的路径，不依赖 List 内部
// 的行管理机制。滴答清单/Finder 那种丝滑展开，本质上也是自己画一层可展开容器，而不是
// 硬套列表控件自带的行动画。

struct TDCategoryManageView: View {
    @ObservedObject private var viewModel = TDSliderBarViewModel.shared
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.dismiss) private var dismiss

    /// 当前被拖拽的分类 ID（与侧滑栏一致）
    @State private var draggedCategoryListItemId: Int? = nil
    /// 拖拽悬停文件夹时高亮的目标文件夹 ID
    @State private var highlightedFolderId: Int? = nil
    /// Hover 行（用于显示编辑/删除按钮）
    @State private var hoveredCategoryId: Int? = nil

    /// 管理弹窗自己的文件夹展开状态：视图本地 @State，与侧滑栏 viewModel.folderExpandedStates 完全独立
    @State private var manageFolderExpandedStates: [Int: Bool] = [:]

    /// 子分类相对文件夹的缩进
    private let childIndent: CGFloat = 20
    /// 文件夹左侧展开箭头的宽度（顶层普通分类没有箭头，要补同宽占位才能让图标对齐在同一列）
    private let folderChevronWidth: CGFloat = 12

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            categoryList
        }
        .frame(width: 500, height: 580)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // 管理页默认展开所有文件夹，方便拖入空文件夹（只写本地状态，不动侧滑栏）
            var states: [Int: Bool] = [:]
            for folder in manageItems where folder.isFolder {
                states[folder.categoryId] = true
            }
            manageFolderExpandedStates = states
        }
    }

    // MARK: - 标题栏

    private var headerBar: some View {
        HStack(spacing: 0) {
            Text("category.manage.title".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.color(level: 5))
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(NSColor.tertiaryLabelColor))
            }
            .buttonStyle(.plain)
            .help("common.close".localized)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - 分类列表（结构与侧滑栏 categoryListSection 一致）

    /// 过滤掉「未分类」(categoryId == 0)，管理页只显示用户创建的分类和文件夹
    private var manageItems: [TDSliderBarModel] {
        viewModel.filteredCategoryListItems.filter { $0.categoryId != 0 }
    }

    private var categoryList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 4) {
                // 首部 drop 区：非拖拽时 0pt（不占空间），拖拽时 20pt 便于命中最前位置
                topDropZone

                ForEach(manageItems) { category in
                    if category.isFolder {
                        folderSection(category)
                    } else {
                        // 顶层普通分类跟文件夹同级，图标要跟文件夹图标对齐（补展开箭头的占位）
                        categoryRow(category, leadingIndent: 0, alignWithFolder: true)
                            .padding(.horizontal, 8)
                    }
                }

                // 尾部 drop 区（调用专用"移到末尾"方法）
                bottomDropZone
            }
            .padding(.vertical, 8)
        }
    }

    /// 顶部 drop 区：非拖拽时高度 0（不占空间），拖拽时撑高 20pt 便于命中
    private var topDropZone: some View {
        let isDragging = draggedCategoryListItemId != nil
        return Rectangle()
            .fill(Color.clear)
            .frame(maxWidth: .infinity)
            .frame(height: isDragging ? 20 : 0)
            .contentShape(Rectangle())
            .onDrop(of: [.text], delegate: ManageCategoryListDropDelegate(
                destinationId: 0,  // 0 → insertAtTopOfTopLevel = true
                destinationIsFolder: false,
                viewModel: viewModel,
                draggedId: $draggedCategoryListItemId,
                highlightedFolderId: $highlightedFolderId
            ))
    }

    /// 底部 drop 区：调用专用"移到末尾"方法，而非 hoverMove（hoverMove 只能插到目标之前）
    private var bottomDropZone: some View {
        let isDragging = draggedCategoryListItemId != nil
        return Rectangle()
            .fill(Color.clear)
            .frame(maxWidth: .infinity)
            .frame(height: isDragging ? 20 : 2)
            .contentShape(Rectangle())
            .onDrop(of: [.text], delegate: ManageBottomDropDelegate(
                viewModel: viewModel,
                draggedId: $draggedCategoryListItemId
            ))
    }

    // MARK: - 文件夹区块（文件夹行 + 子分类 / 空文件夹占位）

    /// 该文件夹在管理弹窗内是否展开（未记录过默认展开）
    private func isManageFolderExpanded(_ folderId: Int) -> Bool {
        manageFolderExpandedStates[folderId] ?? true
    }

    /// 切换展开状态：withAnimation 包一层，触发子分类 VStack 的插入/移除动画（见 folderSection）
    private func toggleManageFolder(_ folderId: Int) {
        withAnimation(.easeInOut(duration: 0.25)) {
            manageFolderExpandedStates[folderId] = !isManageFolderExpanded(folderId)
        }
    }

    @ViewBuilder
    private func folderSection(_ folder: TDSliderBarModel) -> some View {
        let expanded = isManageFolderExpanded(folder.categoryId)
        let children = folder.children ?? []
        let isHighlighted = highlightedFolderId == folder.categoryId

        VStack(spacing: 4) {
            folderRow(folder, isExpanded: expanded, isHighlighted: isHighlighted) {
                toggleManageFolder(folder.categoryId)
            }
            .padding(.horizontal, 8)
            .onDrag {
                // 拖拽文件夹本体时先在本地把它收起，避免子分类跟着抖动
                if isManageFolderExpanded(folder.categoryId) {
                    manageFolderExpandedStates[folder.categoryId] = false
                }
                viewModel.beginCategoryListDragIfNeeded()
                draggedCategoryListItemId = folder.categoryId
                return NSItemProvider(object: "\(folder.categoryId)" as NSString)
            }
            .onDrop(of: [.text], delegate: ManageCategoryListDropDelegate(
                destinationId: folder.categoryId,
                destinationIsFolder: true,
                viewModel: viewModel,
                draggedId: $draggedCategoryListItemId,
                highlightedFolderId: $highlightedFolderId
            ))

            // 子分类 / 空文件夹占位：只在展开时插入这段 VStack，配合 .transition + 外层 withAnimation
            // 做展开/收起动画。
            // ⚠️ 这里只能用 .opacity，不能加 .move(edge:)：.move 会让这段内容整体带着位移
            // 动画（从上方偏移的位置滑到最终位置），而 .clipped() 只裁剪它自己的边界、
            // 不会阻止这个偏移中的色块盖住它上方的文件夹行——那就是之前"顶部透出去、
            // 内容从上面漏下来"的原因。只用 .opacity 就没有任何位置偏移，高度变化本身
            // 已经在 withAnimation 事务里跟着平滑展开，不需要再叠加位移效果。
            if expanded {
                VStack(spacing: 4) {
                    if children.isEmpty {
                        emptyFolderDropZone(folderId: folder.categoryId)
                            .padding(.leading, 8 + childIndent)
                            .padding(.trailing, 8)
                    } else {
                        ForEach(children) { child in
                            categoryRow(child, leadingIndent: childIndent)
                                .padding(.horizontal, 8)
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        // 双重保险：整个文件夹区块也裁一刀，防止任何动画中间帧的内容溢出到相邻文件夹上
        .clipped()
    }

    // MARK: - 空文件夹拖放占位

    private func emptyFolderDropZone(folderId: Int) -> some View {
        let isTarget = highlightedFolderId == folderId
        return Text("category.manage.drop.into.folder".localized)
            .font(.system(size: 12))
            .foregroundColor(themeManager.descriptionTextColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        isTarget ? themeManager.color(level: 5) : themeManager.descriptionTextColor.opacity(0.3),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isTarget ? themeManager.color(level: 5).opacity(0.08) : Color.clear)
                    )
            )
            .onDrop(of: [.text], delegate: ManageCategoryListDropDelegate(
                destinationId: folderId,
                destinationIsFolder: true,
                viewModel: viewModel,
                draggedId: $draggedCategoryListItemId,
                highlightedFolderId: $highlightedFolderId
            ))
    }

    // MARK: - 文件夹行

    private func folderRow(
        _ folder: TDSliderBarModel,
        isExpanded: Bool,
        isHighlighted: Bool,
        onToggle: @escaping () -> Void
    ) -> some View {
        let isHovered = hoveredCategoryId == folder.categoryId
        return HStack(spacing: 10) {
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(NSColor.tertiaryLabelColor))
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .frame(width: folderChevronWidth, height: 16)

            Image(systemName: "folder.fill")
                .font(.system(size: 16))
                .foregroundColor(folder.categoryColor.flatMap { Color.fromHex($0) } ?? .secondary)
                .frame(width: 24, height: 24)

            Text(folder.categoryName)
                .font(.system(size: 14))
                .foregroundColor(Color(NSColor.labelColor))
                .lineLimit(1)

            Spacer()

            if isHovered && draggedCategoryListItemId == nil {
                rowActionButtons(for: folder)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered && draggedCategoryListItemId == nil
                      ? Color(NSColor.controlBackgroundColor) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHighlighted ? themeManager.color(level: 5) : Color.clear, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
        .onHover { hoveredCategoryId = $0 ? folder.categoryId : nil }
    }

    // MARK: - 普通分类行

    @ViewBuilder
    private func categoryRow(
        _ category: TDSliderBarModel,
        leadingIndent: CGFloat,
        alignWithFolder: Bool = false
    ) -> some View {
        let isHovered = hoveredCategoryId == category.categoryId
        let canDrag = category.isServerCategoryListItem && category.categoryId != 0

        HStack(spacing: 10) {
            if leadingIndent > 0 {
                Color.clear.frame(width: leadingIndent)
            } else if alignWithFolder {
                // 跟文件夹同级时，补一段跟展开箭头等宽的占位，让图标落在同一列上
                Color.clear.frame(width: folderChevronWidth)
            }
            itemIconView(category)

            Text(category.categoryName)
                .font(.system(size: 14))
                .foregroundColor(Color(NSColor.labelColor))
                .lineLimit(1)

            Spacer()

            if isHovered && draggedCategoryListItemId == nil {
                rowActionButtons(for: category)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered && draggedCategoryListItemId == nil
                      ? Color(NSColor.controlBackgroundColor) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hoveredCategoryId = $0 ? category.categoryId : nil }
        .modifier(ManageCategoryDragDropModifier(
            enable: true,
            category: category,
            canDrag: canDrag,
            viewModel: viewModel,
            draggedId: $draggedCategoryListItemId,
            highlightedFolderId: $highlightedFolderId
        ))
    }

    // MARK: - 编辑 / 删除按钮

    @ViewBuilder
    private func rowActionButtons(for item: TDSliderBarModel) -> some View {
        HStack(spacing: 8) {
            Button { viewModel.beginEditCategory(item) } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.color(level: 5))
            }
            .buttonStyle(.plain)
            .help("common.edit".localized)

            if item.isServerCategoryListItem {
                Button { viewModel.requestDeleteCategory(item) } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("delete".localized)
            }
        }
        .transition(.opacity)
    }

    // MARK: - 图标

    @ViewBuilder
    private func itemIconView(_ item: TDSliderBarModel) -> some View {
        if item.categoryId == 0 {
            Image(systemName: "circle")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
        } else if let hex = item.categoryColor {
            Circle()
                .fill(Color.fromHex(hex))
                .frame(width: 14, height: 14)
                .frame(width: 24, height: 24)
        } else {
            Image(systemName: item.headerIcon ?? "circle")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
        }
    }
}

// MARK: - 拖拽 DropDelegate（与侧滑栏 SidebarCategoryListDropDelegate 逻辑完全一致）

private struct ManageCategoryListDropDelegate: DropDelegate {
    let destinationId: Int
    let destinationIsFolder: Bool
    let viewModel: TDSliderBarViewModel
    @Binding var draggedId: Int?
    @Binding var highlightedFolderId: Int?

    func dropEntered(info: DropInfo) {
        guard let draggedId, draggedId > 0, draggedId != destinationId else { return }

        // 目标是文件夹：分类悬停仅高亮，实际「放入文件夹」在 performDrop 执行
        if destinationIsFolder {
            if let draggedItem = viewModel.categorySource.first(where: { $0.categoryId == draggedId }),
               !draggedItem.isFolder {
                highlightedFolderId = destinationId
                return
            }
            // 拖拽的是文件夹：按顶级排序实时移动（就地 withAnimation，替代原先 List 上的 value:items 动画）
            highlightedFolderId = nil
            withAnimation(.easeInOut(duration: 0.12)) {
                viewModel.hoverMoveCategoryListItem(draggedId: draggedId, destinationId: destinationId)
            }
            return
        }

        highlightedFolderId = nil
        withAnimation(.easeInOut(duration: 0.12)) {
            viewModel.hoverMoveCategoryListItem(draggedId: draggedId, destinationId: destinationId)
        }
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
            // 放入文件夹末尾（listSort 由 applyMove 按 iOS 规则计算）
            viewModel.dropCategoryIntoFolder(draggedId: draggedId, folderId: destinationId)
        }

        highlightedFolderId = nil
        self.draggedId = nil

        Task { await viewModel.commitCategoryListDrag() }
        return true
    }

    func dropExited(info: DropInfo) {
        if destinationIsFolder, highlightedFolderId == destinationId {
            highlightedFolderId = nil
        }
    }
}

// MARK: - 底部专用 DropDelegate（调用"移到末尾"方法）

private struct ManageBottomDropDelegate: DropDelegate {
    let viewModel: TDSliderBarViewModel
    @Binding var draggedId: Int?

    func dropEntered(info: DropInfo) {
        guard let draggedId, draggedId > 0 else { return }
        // 实时预览：将拖拽项移到顶级末尾（就地 withAnimation）
        withAnimation(.easeInOut(duration: 0.12)) {
            viewModel.moveCategoryListItemToEnd(draggedId: draggedId)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedId, draggedId > 0 else { return true }
        viewModel.moveCategoryListItemToEnd(draggedId: draggedId)
        self.draggedId = nil
        Task { await viewModel.commitCategoryListDrag() }
        return true
    }
}

// MARK: - 拖拽 modifier（与侧滑栏 CategoryListDragDropModifier 一致）

private struct ManageCategoryDragDropModifier: ViewModifier {
    let enable: Bool
    let category: TDSliderBarModel
    let canDrag: Bool
    let viewModel: TDSliderBarViewModel
    @Binding var draggedId: Int?
    @Binding var highlightedFolderId: Int?

    func body(content: Content) -> some View {
        guard enable else { return AnyView(content) }

        if canDrag {
            return AnyView(
                content
                    .onDrag {
                        viewModel.beginCategoryListDragIfNeeded()
                        draggedId = category.categoryId
                        return NSItemProvider(object: "\(category.categoryId)" as NSString)
                    }
                    .onDrop(of: [.text], delegate: ManageCategoryListDropDelegate(
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
                    .onDrop(of: [.text], delegate: ManageCategoryListDropDelegate(
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
