//
//  TDSliderBarView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/13.
//

import SwiftUI

struct TDSliderBarView: View {
    @StateObject private var categoryManager = TDCategoryManager.shared
    @State private var draggedCategory: TDSliderBarModel?
    @State private var hoveredCategoryId: Int?
    @State private var showAddCategorySheet = false
    @State private var showCategorySettings = false
    
    var body: some View {
        List {
            ForEach(categoryManager.menuData) { item in
                Group {
                    if item.type == .category {
                        // 分类清单组（可折叠）
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { item.isSelect },
                                set: { _ in categoryManager.toggleGroup(item.categoryId) }
                            )
                        ) {
                            // 子分类列表
                            ForEach(item.categoryDatas) { category in
                                TDCategoryRowView(category: category,
                                            isHovered: hoveredCategoryId == category.categoryId,
                                            isSelected: categoryManager.selectedCategory?.categoryId == category.categoryId)
                                .onTapGesture {
                                    categoryManager.selectedCategory = category
                                }
                                .onDrag {
                                    if category.categoryId != 0 {
                                        self.draggedCategory = category
                                        return NSItemProvider(object: String(category.categoryId) as NSString)
                                    }
                                    return NSItemProvider()
                                }
                                .onDrop(of: [.text], delegate: CategoryDropDelegate(
                                    item: category,
                                    draggedItem: $draggedCategory,
                                    categoryManager: categoryManager)
                                )
                            }
                        } label: {
                            TDCategoryGroupHeaderView(
                                item: item,
                                isHovered: hoveredCategoryId == item.categoryId,
                                onAddTap: { showAddCategorySheet = true },
                                onSettingsTap: { showCategorySettings = true }
                            )
                        }
                    } else if item.type == .tag {
                        // 标签组（可折叠）
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { item.isSelect },
                                set: { _ in categoryManager.toggleGroup(item.categoryId) }
                            )
                        ) {
                            // 标签列表内容
                        } label: {
                            TDTagGroupHeaderView(
                                item: item,
                                isHovered: hoveredCategoryId == item.categoryId
                            )
                        }
                    } else {
                        // 其他固定组
                        TDCategoryRowView(category: item,
                                    isHovered: hoveredCategoryId == item.categoryId,
                                    isSelected: categoryManager.selectedCategory?.categoryId == item.categoryId)
                        .onTapGesture {
                            categoryManager.selectedCategory = item
                        }
                    }
                }
                .onHover { isHovered in
                    hoveredCategoryId = isHovered ? item.categoryId : nil
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200, maxWidth: 300)
        .task {
            await categoryManager.fetchCategories()
        }
        .sheet(isPresented: $showAddCategorySheet) {
//            AddCategoryView()
        }
        .sheet(isPresented: $showCategorySettings) {
//            CategorySettingsView()
        }
    }
}


// MARK: - 拖拽代理
struct CategoryDropDelegate: DropDelegate {
    let item: TDSliderBarModel
    @Binding var draggedItem: TDSliderBarModel?
    let categoryManager: TDCategoryManager
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = self.draggedItem,
              draggedItem.categoryId != item.categoryId,
              draggedItem.categoryId != 0 // 未分类不可拖动
        else { return false }
        
        Task {
            // 获取分类清单组
            if let index = categoryManager.menuData.firstIndex(where: { $0.categoryId == -104 }) {
                var categories = categoryManager.menuData[index].categoryDatas
                
                // 计算新的排序位置
                if let fromIndex = categories.firstIndex(where: { $0.categoryId == draggedItem.categoryId }),
                   let toIndex = categories.firstIndex(where: { $0.categoryId == item.categoryId }) {
                    
                    // 移动分类
                    categories.move(fromOffsets: IndexSet(integer: fromIndex),
                                 toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                    
                    // 更新排序值
                    for (index, var category) in categories.enumerated() where category.categoryId != 0 {
                        category.listSort = Double((index + 1) * 100)
                        categories[index] = category
                    }
                    
                    // 保存排序
                    try? await categoryManager.updateCategoriesSort(categories)
                }
            }
        }
        
        self.draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // 可以在这里添加拖拽进入时的视觉反馈
        guard let draggedItem = self.draggedItem,
              draggedItem.categoryId != item.categoryId,
              draggedItem.categoryId != 0,  // 未分类不可拖动
              item.categoryId != 0  // 不可拖到未分类
        else { return }
        
        // 获取分类清单组
        if let index = categoryManager.menuData.firstIndex(where: { $0.categoryId == -104 }) {
            var categories = categoryManager.menuData[index].categoryDatas
            
            // 计算拖拽位置
            if let fromIndex = categories.firstIndex(where: { $0.categoryId == draggedItem.categoryId }),
               let toIndex = categories.firstIndex(where: { $0.categoryId == item.categoryId }) {
                
                // 临时更新UI显示顺序
                withAnimation(.easeInOut(duration: 0.2)) {
                    categories.move(fromOffsets: IndexSet(integer: fromIndex),
                                 toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                    
                    // 通过 Manager 更新数据
                    categoryManager.updateCategoriesOrder(categories)
                }
            }
        }


    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        guard let draggedItem = self.draggedItem else { return false }
        // 未分类不可作为拖拽目标
        return item.categoryId != 0 && draggedItem.categoryId != item.categoryId
    }
}

#Preview {
    TDSliderBarView()
}
