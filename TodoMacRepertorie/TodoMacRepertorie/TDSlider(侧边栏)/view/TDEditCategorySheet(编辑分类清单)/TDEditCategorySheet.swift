//
//  TDEditCategorySheet.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/26.
//

import SwiftUI

import AppKit

/// 编辑分类/文件夹（名称 + 颜色）
struct TDEditCategorySheet: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Binding var isPresented: Bool
    
    @StateObject private var viewModel = TDSliderBarViewModel.shared
    

    let category: TDSliderBarModel
    let onSaved: () -> Void
    
    @State private var name: String
    @State private var selectedColor: String
    @State private var customColor: Color
    /// 仅用于“编辑分类清单”（非文件夹）时：归属文件夹
    @State private var selectedFolderId: Int
    @State private var selectedParentFolder: TDSliderBarModel? = nil
    @State private var allFolders: [TDSliderBarModel] = []

    @State private var colorPanelObserver: ColorPanelObserver?
    
    // 预设颜色（与新建保持一致）
    private let presetColors = [
        "#018f90", "#ff6b6b", "#ff8b2b", "#377cb6", "#5B9AFF",
        "#f96f96", "#c3c3c3", "#00d26a", "#A259C7", "#E6E73B"
    ]
    
    init(isPresented: Binding<Bool>, category: TDSliderBarModel, onSaved: @escaping () -> Void) {
        self._isPresented = isPresented
        self.category = category
        self.onSaved = onSaved
        
        let initialName = category.categoryName
        let initialColor = category.categoryColor ?? "#018f90"
        self._name = State(initialValue: initialName)
        self._selectedColor = State(initialValue: initialColor)
        self._customColor = State(initialValue: Color.fromHex(initialColor))
        self._selectedFolderId = State(initialValue: category.folderId ?? 0)

    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            nameRow
            if !category.isFolder {
                folderPickerRow
            }

            colorPicker
            Spacer()
            footer
        }
        .padding(20)
        .frame(width: 420, height: 340)
        .background(themeManager.backgroundColor)
        .onAppear {
            loadFolders()
            if selectedFolderId > 0 {
                selectedParentFolder = allFolders.first(where: { $0.categoryId == selectedFolderId })
            } else {
                selectedParentFolder = nil
            }
        }
        .onChange(of: customColor) { _, newValue in
            selectedColor = newValue.toHexString(includeAlpha: true)
        }
    }
    
    private var header: some View {
        HStack {
            Text(category.isFolder ? "category.edit.folder.title".localized : "category.edit.category.title".localized)
                .font(.system(size: 15))
                .foregroundColor(themeManager.titleTextColor)
            Spacer()
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var nameRow: some View {
        HStack {
            if category.isFolder {
                Image(systemName: "folder.fill")
                    .foregroundColor(Color.fromHex(selectedColor))
                    .font(.system(size: 14))
            } else {
                Circle()
                    .fill(Color.fromHex(selectedColor))
                    .frame(width: 12, height: 12)
            }

            TextField("category.new.name.placeholder".localized, text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(themeManager.titleTextColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(themeManager.secondaryBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
   
    private var folderPickerRow: some View {
        Menu {
            // 不选择文件夹
            Button(action: {
                selectedParentFolder = nil
                selectedFolderId = 0
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
                        selectedFolderId = folder.categoryId
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
                    .font(.system(size: 14))

                Text("category.new.folder.parent".localized)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.titleTextColor)

                Text(selectedParentFolder?.categoryName ?? "category.new.folder.parent.none".localized)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.descriptionTextColor)

                Spacer()

                Image(systemName: "chevron.down")
                    .foregroundColor(themeManager.descriptionTextColor)
                    .font(.system(size: 12))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(themeManager.secondaryBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }


    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("category.edit.colorPicker.title".localized)
                .font(.system(size: 12))
                .foregroundColor(themeManager.descriptionTextColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                ForEach(presetColors, id: \.self) { color in
                    Button(action: {
                        selectedColor = color
                        customColor = Color.fromHex(color)
                    }) {
                        Circle()
                            .fill(Color.fromHex(color))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: { openColorPicker() }) {
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
    
    private var footer: some View {
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
                    handleSave()
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
    
    
    private func handleSave() {
        Task {
            let folderIdToSave: Int? = category.isFolder ? nil : selectedFolderId
            let ok = await viewModel.saveCategoryChanges(
                categoryId: category.categoryId,
                name: name,
                color: selectedColor,
                isFolder: category.isFolder,
                folderId: folderIdToSave
            )
            if ok {
                isPresented = false
                onSaved()
            }
        }
    }
    
    private func loadFolders() {
        let allCategories = TDCategoryManager.shared.loadLocalCategories()
        allFolders = TDCategoryManager.shared.getAllFolders(from: allCategories)
    }

    private func openColorPicker() {
        let colorPanel = NSColorPanel.shared
        let nsColor = NSColor(customColor)
        colorPanel.color = nsColor
        colorPanel.showsAlpha = true
        colorPanel.isContinuous = true
        
        let observer = ColorPanelObserver { newColor in
            DispatchQueue.main.async {
                self.customColor = newColor
            }
        }
        colorPanelObserver = observer
        colorPanel.setTarget(observer)
        colorPanel.setAction(#selector(ColorPanelObserver.colorChanged(_:)))
        colorPanel.orderFront(nil)
    }
}

