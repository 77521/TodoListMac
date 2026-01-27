//
//  TDNewCategorySheet.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/26.
//

import SwiftUI
import AppKit

/// 新建分类/文件夹的 Tab 类型
enum TDNewCategoryTab {
    case category  // 分类清单
    case folder     // 文件夹
}

struct TDNewCategorySheet: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Binding var isPresented: Bool
    
    @StateObject private var viewModel = TDSliderBarViewModel.shared

    @State private var currentTab: TDNewCategoryTab = .category
    @State private var categoryName: String = ""
    @State private var selectedParentFolder: TDSliderBarModel? = nil
    @State private var selectedColor: String = "#018f90"
    @State private var customColor: Color = .blue
    @State private var colorPanelObserver: ColorPanelObserver?
    
    // 所有文件夹数据
    @State private var allFolders: [TDSliderBarModel] = []
    
    private let vipImageName: String = "openvip_default_icon"

    
    // 预设的分类名称（国际化）
    private var suggestedNames: [String] {
        [
            "category.new.suggest.work".localized,
            "category.new.suggest.life".localized,
            "category.new.suggest.study".localized,
            "category.new.suggest.media".localized,
            "category.new.suggest.project".localized
        ]
    }
    
    // 预设颜色
    private let presetColors = [
        "#018f90", "#ff6b6b", "#ff8b2b", "#377cb6", "#5B9AFF",
        "#f96f96", "#c3c3c3", "#5B9AFF", "#00d26a", "#A259C7", "#E6E73B"
    ]
    
    var body: some View {
        ZStack {
            
            VStack(alignment: .leading, spacing: 20) {
                // 标题和关闭按钮
                HStack {
                    Text("category.new.title".localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.titleTextColor)
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                }
                
                // Tab 切换器
                Picker("", selection: $currentTab) {
                    Text("category.new.tab.category".localized).tag(TDNewCategoryTab.category)
                    Text("category.new.tab.folder".localized).tag(TDNewCategoryTab.folder)
                }
                .pickerStyle(.segmented)
                .frame(minWidth: 100, maxWidth: 380, alignment: .leading)
                
                // 内容区域
                if currentTab == .category {
                    categoryContent
                } else {
                    folderContent
                }
                
                Spacer()
                
                // 底部按钮（放在右边）
                HStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button("common.cancel".localized) {
                            isPresented = false
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(themeManager.titleTextColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(themeManager.secondaryBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        Button("common.confirm".localized) {
                            handleConfirm()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(themeManager.color(level: 5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .padding(20)
            .frame(width: 480, height: 500)
            .background(themeManager.backgroundColor)
            .onAppear {
                loadFolders()
                // 初始化 customColor 为当前选中的颜色
                customColor = Color.fromHex(selectedColor)
            }
            .onChange(of: customColor) { _, newValue in
                // 当 customColor 改变时，同步更新 selectedColor
                selectedColor = newValue.toHexString(includeAlpha: true)
            }

            // VIP 弹窗覆盖层
            TDOpenVipModal(
                isPresented: $viewModel.showVipModal,
                imageName: vipImageName,
                subtitleKey: viewModel.vipSubtitleKey
            )
            .environmentObject(themeManager)
            .environmentObject(TDSettingsSidebarStore.shared)

        }
    }
    
    // MARK: - 分类内容
    private var categoryContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 归属文件夹选择（Menu）
            Menu {
                // 不选择分类选项
                Button(action: {
                    selectedParentFolder = nil
                }) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(themeManager.descriptionTextColor)
                            .font(.system(size: 12))
                        Text("category.new.folder.parent.none".localized)
                    }
                }
                
                if !allFolders.isEmpty {
                    Divider()
                    
                    ForEach(allFolders, id: \.categoryId) { folder in
                        Button(action: {
                            selectedParentFolder = folder
                        }) {
                            HStack {
                                if let folderColor = folder.categoryColor {
                                    // 使用带颜色的文件夹图标
                                    Image.fromSystemName("folder.fill", hexColor: folderColor, size: 16)
                                } else {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(themeManager.color(level: 5))
                                        .font(.system(size: 12))
                                }
                                Text(folder.categoryName)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    // 文件夹图标（根据选中的文件夹显示对应颜色）
                    Image(systemName: "folder.fill")
                        .foregroundColor(
                            selectedParentFolder?.categoryColor.flatMap { Color.fromHex($0) } ?? themeManager.titleTextColor
                        )
                        .font(.system(size: 12))

                    
                    Text("category.new.folder.parent".localized)
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.titleTextColor)
                    
                    Text(selectedParentFolder?.categoryName ?? "category.new.folder.parent.none".localized)
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.titleTextColor)
                                        
                    Image(systemName: "arrowtriangle.down.fill")
                        .foregroundColor(themeManager.descriptionTextColor)
                        .font(.system(size: 10))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(themeManager.secondaryBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            
            // 分类名称输入
            HStack {
                Circle()
                    .fill(Color.fromHex(selectedColor))
                    .frame(width: 12, height: 12)
                
                TextField("category.new.name.placeholder".localized, text: $categoryName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.titleTextColor)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(themeManager.secondaryBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // 建议标签
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestedNames, id: \.self) { name in
                        Button(action: {
                            categoryName = name
                        }) {
                            Text(name)
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.titleTextColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(themeManager.secondaryBackgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // 颜色选择器（不需要选中效果，只更新圆形背景颜色）
            VStack(alignment: .leading, spacing: 8) {
                Text("category.edit.colorPicker.title".localized)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.descriptionTextColor)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                    ForEach(presetColors, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                            customColor = Color.fromHex(color) // 同步更新 customColor
                        }) {
                            Circle()
                                .fill(Color.fromHex(color))
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // 自定义颜色选择器（使用 Button 触发系统颜色选择器）
                    Button(action: {
                        openColorPicker()
                    }) {
                        ZStack {
                            Circle()
                                .fill(themeManager.secondaryBackgroundColor)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "paintpalette")
                                .foregroundColor(themeManager.color(level: 5))
                                .font(.system(size: 14))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - 文件夹内容
    private var folderContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 文件夹名称输入
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(Color.fromHex(selectedColor))
                    .font(.system(size: 14))


                
                TextField("category.new.name.placeholder".localized, text: $categoryName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.titleTextColor)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(themeManager.secondaryBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // 颜色选择器（文件夹也需要颜色，不需要选中效果）
            VStack(alignment: .leading, spacing: 8) {
                Text("选择颜色")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.descriptionTextColor)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                    ForEach(presetColors, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                            customColor = Color.fromHex(color) // 同步更新 customColor
                        }) {
                            Circle()
                                .fill(Color.fromHex(color))
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // 自定义颜色选择器（使用 Button 触发系统颜色选择器）
                    Button(action: {
                        openColorPicker()
                    }) {
                        ZStack {
                            Circle()
                                .fill(themeManager.secondaryBackgroundColor)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "paintpalette")
                                .foregroundColor(themeManager.descriptionTextColor)
                                .font(.system(size: 14))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - 操作方法
    private func loadFolders() {
        // 从本地加载所有分类数据
        let allCategories = TDCategoryManager.shared.loadLocalCategories()
        // 获取所有文件夹
        allFolders = TDCategoryManager.shared.getAllFolders(from: allCategories)
    }
    
    private func openColorPicker() {
        let colorPanel = NSColorPanel.shared
        
        // 设置当前颜色
        let nsColor = NSColor(customColor)
        colorPanel.color = nsColor
        
        // 支持透明度
        colorPanel.showsAlpha = true
        
        // 启用连续更新
        colorPanel.isContinuous = true
        
        // 创建观察者来监听颜色变化
        let observer = ColorPanelObserver { newColor in
            DispatchQueue.main.async {
                self.customColor = newColor
            }
        }
        colorPanelObserver = observer
        
        // 设置目标和方法
        colorPanel.setTarget(observer)
        colorPanel.setAction(#selector(ColorPanelObserver.colorChanged(_:)))
        
        // 打开颜色选择器
        colorPanel.orderFront(nil)
    }
    
    private func handleConfirm() {
        let isFolder = currentTab == .folder
        let parentFolderId = selectedParentFolder?.categoryId
        
        Task {
            let ok = await viewModel.createCategory(
                name: categoryName,
                color: selectedColor,
                isFolder: isFolder,
                parentFolderId: parentFolderId
            )
            if ok {
                isPresented = false
            }
        }
    }

}

// MARK: - ColorPanelObserver
/// 颜色选择器观察者，用于监听 NSColorPanel 的颜色变化
class ColorPanelObserver: NSObject {
    private let onColorChanged: (Color) -> Void
    
    init(onColorChanged: @escaping (Color) -> Void) {
        self.onColorChanged = onColorChanged
        super.init()
    }
    
    @objc func colorChanged(_ sender: NSColorPanel) {
        // 将 NSColor 转换为 SwiftUI Color
        let nsColor = sender.color.usingColorSpace(.sRGB) ?? sender.color
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let newColor = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
        onColorChanged(newColor)
    }
}
