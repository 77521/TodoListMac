//
//  TDCategoryPickerMenu.swift
//  TodoMacRepertorie
//
//  Created by Cursor on 2026/2/1.
//

import SwiftUI

/// 分类选择入口展示所需的上下文（由外部决定如何渲染 label）
struct TDCategoryPickerLabelContext {
    /// 当前选中的分类模型（nil 表示未分类）
    let selectedCategory: TDSliderBarModel?
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

/// 可复用的"分类清单选择 Menu"
/// - 支持：新建、未分类、文件夹（子菜单）、过滤空文件夹
struct TDCategoryPickerMenu: View {
    @ObservedObject private var themeManager = TDThemeManager.shared
    @ObservedObject private var sliderViewModel = TDSliderBarViewModel.shared

    /// 当前选中的分类模型（nil 表示未分类）
    let selectedCategory: TDSliderBarModel?

    /// 是否显示"全部"（由外部传入控制，默认 false）
    var showAllItem: Bool = false

    /// 是否显示"新建"（由外部传入控制）
    let showCreateItem: Bool

    /// 是否显示"未分类"（由外部传入控制）
    let showUncategorizedItem: Bool

    /// 入口 label 的显示样式（默认：仅图片）
    var labelStyle: TDCategoryPickerLabelStyle = .iconOnly

    /// 点击"全部"时的回调
    var onAllSelected: (() -> Void)?

    /// 点击"新建"时的回调
    var onCreate: (() -> Void)?

    /// 点击"未分类"时的回调
    var onUncategorizedSelected: (() -> Void)?

    /// 点击分类时的回调（返回分类模型数据）
    var onCategorySelected: ((TDSliderBarModel) -> Void)?


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

    /// 根据 labelStyle 显示不同的 label 样式
    private var categoryLabelView: some View {
        let isUncategorized = (selectedCategory?.categoryId ?? 0) <= 0
        let iconSize = TDAppConfig.menuIconSize
        let fillHex = selectedCategory?.categoryColor ?? "#c3c3c3"
        let displayName = isUncategorized ? "uncategorized".localized : (selectedCategory?.categoryName ?? "uncategorized".localized)

       return HStack(spacing: 6) {
            // 图标：
            // - 未分类：空心圆
            // - 服务器分类（categoryId > 0）：实心圆，颜色使用分类自己的颜色
            if isUncategorized {
                Image.fromCircleColor(themeManager.color(level: 5), width: iconSize, height: iconSize, lineWidth: 1.5)
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
            } else {
                Image.fromHexColor(fillHex, width: iconSize, height: iconSize, cornerRadius: iconSize / 2)
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
            }

            // 文字：根据 labelStyle 决定是否显示
            if labelStyle == .iconAndText || labelStyle == .iconAndTextWithChevron {
                Text(displayName)
                    .font(.system(size: TDAppConfig.menuFontSize))
                    .foregroundColor(themeManager.titleTextColor)
                    .lineLimit(1)
            }

            // 展开箭头：根据 labelStyle 决定是否显示
            if labelStyle == .iconAndTextWithChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(themeManager.descriptionTextColor)
            }
        }
    }

    var body: some View {
        Menu {
            // 0) 全部（可选显示）
            if showAllItem {
                Button {
                    onAllSelected?()
                } label: {
                    Text("全部")
                        .font(.system(size: TDAppConfig.menuFontSize))
                }
                
                // 分割线：把"全部"与其他选项区分开
                if showCreateItem || showUncategorizedItem || !items.isEmpty {
                    Divider()
                }
            }

            // 1) 新建（可选显示）
            if showCreateItem {
                Button {
                    onCreate?() ?? sliderViewModel.showAddCategorySheet()
                } label: {
                    menuRow(icon: createIcon, title: "new_category".localized)
                }
            }

            // 2) 未分类（可选显示）
            if showUncategorizedItem {
                Button {
                    onUncategorizedSelected?()
                } label: {
                    menuRow(icon: uncategorizedIcon, title: "uncategorized".localized)
                }

                // 2.1 分割线：把"新建/未分类"与服务器分类清单区分开
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
                                // 子分类：回调返回模型数据
                                onCategorySelected?(child)
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
                        // 顶级分类：回调返回模型数据
                        onCategorySelected?(item)
                    } label: {
                        menuRow(
                            icon: categoryIcon(hex: item.categoryColor),
                            title: String(item.categoryName.prefix(8))
                        )
                    }
                }
            }
        } label: {
            // 入口展示：根据 labelStyle 显示不同的样式
            categoryLabelView
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }

    // MARK: - Row builder

    /// 菜单行：左侧图标 + 右侧标题
    private func menuRow(icon: some View, title: String) -> some View {
        HStack(spacing: 8) {
            icon
            Text(title)
                .font(.system(size: TDAppConfig.menuFontSize))
        }
    }

    // MARK: - Icons

    /// 新建：实心圆 + 加号
    private var createIcon: some View {
        // 使用"可着色的实心圆 + 加号"图片（避免在 Menu 内渲染风格不一致/丢色）
        Image.fromPlusCircleColor(themeManager.color(level: 5), width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize, plusSize: 6, plusWidth: 1.5)
            .resizable()
            .frame(width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize)
    }

    /// 未分类：空心圆
    private var uncategorizedIcon: some View {
        // 使用"可着色的空心圆图标"（避免 stroke 在 Menu 内渲染风格不一致）
        Image.fromCircleColor(themeManager.color(level: 5), width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize, lineWidth: 1.2)
            .resizable()
            .frame(width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize)
    }

    /// 分类（非文件夹）：按你给的样式显示
    /// - 左侧：用颜色生成的小方块（圆角=7，视觉上是圆形）
    /// - 右侧：名称最多展示 8 个字符
    private func categoryIcon(hex: String?) -> some View {
        Image.fromHexColor(hex ?? "#c3c3c3", width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize, cornerRadius: 7.0)
            .resizable()
            .frame(width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize)
    }

    /// 文件夹图标：有颜色则使用"带颜色的文件夹图标"，否则使用主题色
    private func folderIcon(folderColor: String?) -> some View {
        Group {
            if let folderColor, !folderColor.isEmpty {
                // 使用带颜色的文件夹图标
                Image.fromSystemName("folder.fill", hexColor: folderColor, size: TDAppConfig.menuIconSize)
            } else {
                // 使用默认文件夹图标（主题色）
                Image(systemName: "folder.fill")
                    .foregroundColor(themeManager.color(level: 5))
                    .font(.system(size: TDAppConfig.menuIconSize))
            }
        }
        .frame(width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize, alignment: .center)
    }
}
