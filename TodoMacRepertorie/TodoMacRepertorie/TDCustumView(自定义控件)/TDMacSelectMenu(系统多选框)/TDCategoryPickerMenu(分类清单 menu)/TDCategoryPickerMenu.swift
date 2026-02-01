//
//  TDCategoryPickerMenu.swift
//  TodoMacRepertorie
//
//  Created by Cursor on 2026/2/1.
//

import SwiftUI

/// 分类选择入口展示所需的上下文（由外部决定如何渲染 label）
struct TDCategoryPickerLabelContext {
    /// 当前选中的分类 id（0 表示未分类）
    let selectedCategoryId: Int
    /// 当前选中的分类模型（若已删除/不存在则为 nil）
    let selectedCategory: TDSliderBarModel?
    /// 是否选中了“分类清单”（categoryId > 0）
    let isCategoryList: Bool
    /// 入口显示用的颜色（未分类：主题色；清单：清单颜色）
    let displayColor: Color
    /// 入口显示用的文字（未分类：国际化；清单：清单名）
    let displayName: String
}

/// 分类选择入口（label）显示样式
/// 你提到的三种情况：
/// 1) 图片 + 文字
/// 2) 仅图片
/// 3) 图片 + 文字 + 展开箭头
enum TDCategoryPickerLabelStyle {
    case iconAndText
    case iconOnly
    case iconAndTextWithChevron
}

/// 可复用的“分类清单选择 Menu”
/// - 支持：新建、未分类、文件夹（子菜单）、过滤空文件夹
struct TDCategoryPickerMenu: View {
    @ObservedObject private var themeManager = TDThemeManager.shared
    @ObservedObject private var sliderViewModel = TDSliderBarViewModel.shared

    /// 当前选中的分类 id（0 表示未分类）
    @Binding var selectedCategoryId: Int

    /// 是否显示“新建”（由外部传入控制）
    let showCreateItem: Bool

    /// 是否显示“未分类”（由外部传入控制）
    let showUncategorizedItem: Bool

    /// 点击“新建”
    var onCreate: (() -> Void)?

    /// 入口 label 的显示样式（默认：仅图片）
    var labelStyle: TDCategoryPickerLabelStyle = .iconOnly

    /// 自定义入口 label 的渲染（可选）
    /// - 作用：当你需要“其它图片”或更复杂的布局时可传入
    /// - 注意：如果传了这个，会优先使用它，忽略 `labelStyle`
    var labelBuilder: ((TDCategoryPickerLabelContext) -> AnyView)? = nil

    /// 分类数据源：默认从本地分类里按文件夹结构组织（与侧滑栏一致）
    var items: [TDSliderBarModel] {
        // 1) 只取服务器真实数据（含文件夹/分类，id>0）
        let all = TDCategoryManager.shared.loadLocalCategories()
        let server = all.filter { $0.categoryId > 0 }
        // 2) 按 iOS 逻辑组装文件夹 + 子分类结构
        let processed = TDCategoryManager.shared.getFolderWithSubCategories(from: server)

        // 3) 过滤：文件夹内无数据则不显示（你要求：先不展示空文件夹）
        return processed.filter { item in
            if item.isFolder {
                return !(item.children ?? []).isEmpty
            }
            return true
        }
    }

    /// 是否选择了某个清单（categoryId > 0）
    private var selectedIsCategoryList: Bool {
        selectedCategoryId > 0
    }

    /// 当前显示的颜色（未分类：主题色；自定义清单：清单色）
    private var selectedColor: Color {
        if selectedCategoryId > 0, let c = resolvedSelectedCategory?.categoryColor {
            return Color.fromHex(c)
        }
        return themeManager.color(level: 5)
    }

    /// 当前选中的分类模型（如果分类被删除/不存在，则返回 nil）
    private var resolvedSelectedCategory: TDSliderBarModel? {
        guard selectedCategoryId > 0 else { return nil }
        // 从本地分类清单中查找最新数据（保证：颜色修改能实时跟随）
        let all = TDCategoryManager.shared.loadLocalCategories()
        return all.first { item in
            item.categoryId == selectedCategoryId &&
            (item.delete == false || item.delete == nil) &&
            item.folderIs != true
        }
    }

    /// 当前入口显示的文字（未分类/分类名）
    private var selectedDisplayName: String {
        if let resolvedSelectedCategory {
            return resolvedSelectedCategory.categoryName
        }
        return "uncategorized".localized
    }

    /// 入口渲染上下文（给外部 labelBuilder 使用）
    private var labelContext: TDCategoryPickerLabelContext {
        TDCategoryPickerLabelContext(
            selectedCategoryId: selectedCategoryId,
            selectedCategory: resolvedSelectedCategory,
            isCategoryList: selectedIsCategoryList,
            displayColor: selectedColor,
            displayName: selectedDisplayName
        )
    }

    var body: some View {
        Menu {
            // 1) 新建（可选显示）
            if showCreateItem {
                Button {
                    (onCreate ?? { sliderViewModel.showAddCategorySheet() })()
                } label: {
                    menuRow(icon: createIcon, title: "new_category".localized)
                }
            }

            // 2) 未分类（可选显示）
            if showUncategorizedItem {
                Button {
                    selectedCategoryId = 0
                } label: {
                    menuRow(icon: uncategorizedIcon, title: "uncategorized".localized)
                }

                // 2.1 分割线：把“新建/未分类”与服务器分类清单区分开
                if !items.isEmpty {
                    Divider()
                }
            }

            // 3) 分类清单：支持文件夹（子菜单）
            ForEach(items) { item in
                if item.isFolder, let children = item.children, !children.isEmpty {
                    Menu {
                        ForEach(children) { child in
                            Button {
                                // 子分类：直接记录子分类 id
                                selectedCategoryId = child.categoryId
                            } label: {
                                menuRow(
                                    icon: categoryIcon(hex: child.categoryColor),
                                    title: String(child.categoryName.prefix(8))
                                )
                            }
                        }
                    } label: {
                        menuRow(
                            icon: folderIcon(folderColor: item.categoryColor),
                            title: item.categoryName
                        )
                    }
                } else {
                    Button {
                        // 顶级分类：直接记录分类 id
                        selectedCategoryId = item.categoryId
                    } label: {
                        menuRow(
                            icon: categoryIcon(hex: item.categoryColor),
                            title: String(item.categoryName.prefix(8))
                        )
                    }
                }
            }
        } label: {
            // 入口展示：优先用外部自定义；否则按内置三种样式渲染
            let builder = labelBuilder ?? TDCategoryPickerMenu.builder(for: labelStyle)
            builder(labelContext)
                .contentShape(Rectangle()) // 扩大可点区域
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }

    // MARK: - 入口 label：三种内置样式
    /// 根据样式返回对应的 label builder
    static func builder(for style: TDCategoryPickerLabelStyle) -> (TDCategoryPickerLabelContext) -> AnyView {
        switch style {
        case .iconOnly:
            return labelIconOnly
        case .iconAndText:
            return labelIconAndText
        case .iconAndTextWithChevron:
            return labelIconAndTextWithChevron
        }
    }

    /// 1) 仅图片
    static func labelIconOnly(_ ctx: TDCategoryPickerLabelContext) -> AnyView {
        AnyView(
            categoryIndicatorView(ctx: ctx, showText: false, showChevron: false)
        )
    }

    /// 2) 图片 + 文字
    static func labelIconAndText(_ ctx: TDCategoryPickerLabelContext) -> AnyView {
        AnyView(
            categoryIndicatorView(ctx: ctx, showText: true, showChevron: false)
        )
    }

    /// 3) 图片 + 文字 + 展开箭头
    static func labelIconAndTextWithChevron(_ ctx: TDCategoryPickerLabelContext) -> AnyView {
        AnyView(
            categoryIndicatorView(ctx: ctx, showText: true, showChevron: true)
        )
    }

    /// 入口“图片/文字/箭头”的统一渲染（避免三处重复）
    private static func categoryIndicatorView(
        ctx: TDCategoryPickerLabelContext,
        showText: Bool,
        showChevron: Bool
    ) -> some View {
        let theme = TDThemeManager.shared

        return HStack(spacing: 6) {
            // 图标：未分类空心圆 / 清单实心圆（清单颜色）
            if ctx.isCategoryList {
                Circle()
                    .fill(ctx.displayColor)
                    .frame(width: 14, height: 14)
            } else {
                Image.fromCircleColor(theme.color(level: 5), width: 14, height: 14, lineWidth: 1.5)
                    .resizable()
                    .frame(width: 14, height: 14)
            }

            // 文字：由外部样式决定是否显示
            if showText {
                Text(ctx.displayName)
                    .font(.system(size: 13))
                    .foregroundColor(theme.titleTextColor)
                    .lineLimit(1)
            }

            // 展开箭头：由外部样式决定是否显示
            if showChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(theme.descriptionTextColor)
            }
        }
    }

    // MARK: - Row builder

    /// 菜单行：左侧图标 + 右侧标题
    private func menuRow(icon: some View, title: String) -> some View {
        HStack(spacing: 8) {
            icon
            Text(title)
                .font(.system(size: 12))
        }
    }

    // MARK: - Icons

    /// 新建：实心圆 + 加号
    private var createIcon: some View {
        // 使用“可着色的实心圆 + 加号”图片（避免在 Menu 内渲染风格不一致/丢色）
        Image.fromPlusCircleColor(themeManager.color(level: 5), width: 14, height: 14, plusSize: 6, plusWidth: 1.5)
            .resizable()
            .frame(width: 14, height: 14)
    }

    /// 未分类：空心圆
    private var uncategorizedIcon: some View {
        // 使用“可着色的空心圆图标”（避免 stroke 在 Menu 内渲染风格不一致）
        Image.fromCircleColor(themeManager.color(level: 5), width: 14, height: 14, lineWidth: 1.2)
            .resizable()
            .frame(width: 14, height: 14)
    }

    /// 分类（非文件夹）：按你给的样式显示
    /// - 左侧：用颜色生成的小方块（圆角=7，视觉上是圆形）
    /// - 右侧：名称最多展示 8 个字符
    private func categoryIcon(hex: String?) -> some View {
        Image.fromHexColor(hex ?? "#c3c3c3", width: 14, height: 14, cornerRadius: 7.0)
            .resizable()
            .frame(width: 14.0, height: 14.0)
    }

    /// 文件夹图标：有颜色则使用“带颜色的文件夹图标”，否则使用主题色
    private func folderIcon(folderColor: String?) -> some View {
        Group {
            if let folderColor, !folderColor.isEmpty {
                // 使用带颜色的文件夹图标
                Image.fromSystemName("folder.fill", hexColor: folderColor, size: 16)
            } else {
                // 使用默认文件夹图标（主题色）
                Image(systemName: "folder.fill")
                    .foregroundColor(themeManager.color(level: 5))
                    .font(.system(size: 12))
            }
        }
        .frame(width: 16, height: 16, alignment: .center)
    }
}

