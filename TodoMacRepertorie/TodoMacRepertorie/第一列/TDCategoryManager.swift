//
//  TDCategoryManager.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/13.
//

import Foundation
import SwiftUI

class TDCategoryManager: ObservableObject {
    // MARK: - 属性
    static let shared = TDCategoryManager()
    
    @Published private(set) var menuData: [TDSliderBarModel] = []{
        didSet {
            print("菜单数据已更新: \(menuData.map { $0.categoryName })")
        }
    }
    @Published var selectedCategory: TDSliderBarModel?
    @Published var draggedCategory: TDSliderBarModel?
    
    private let userDefaults = UserDefaults.standard
    private let storageKey = "MenuData"
    
    
    
    // MARK: - 初始化
    private init() {
        loadDefaultData()
        print("初始菜单数据: \(menuData)")  // 添加这行来调试
        Task {
            await fetchCategories()
        }
    }
    
    // MARK: - 公共方法
    
    /// 获取分类清单数据
    @MainActor
    func fetchCategories() async {
        // 1. 先加载本地数据
        if let localData = loadFromLocal() {
            // 找到分类清单组
            if let index = localData.firstIndex(where: { $0.categoryId == -104 }),
               !localData[index].categoryDatas.isEmpty {
                self.menuData = localData
                setupDefaultStates()
            }
        }
        
        // 2. 再请求网络数据
        do {
            let categories = try await TDCategoryAPI.getCategories()
            
            // 确保未分类存在且在第一位
            var finalCategories = categories
            if !finalCategories.contains(where: { $0.categoryId == 0 }) {
                let uncategorized = TDSliderBarModel(
                    categoryId: 0,
                    categoryName: "未分类",
                    categoryColor : "#c3c3c3",
                    listSort: 0,
                    headerIcon: "tray"
                )
                finalCategories.insert(uncategorized, at: 0)
            }
            
            // 按listSort排序（未分类除外）
            let uncategorized = finalCategories.removeFirst()
            finalCategories.sort { $0.listSort < $1.listSort }
            finalCategories.insert(uncategorized, at: 0)
            
            // 更新分类清单组数据
            if let index = menuData.firstIndex(where: { $0.categoryId == -104 }) {
                // 如果数据有变化才更新
                if menuData[index].categoryDatas != finalCategories {
                    menuData[index].categoryDatas = finalCategories
                    // 保存到本地
                    saveToLocal()
                    setupDefaultStates()

                }
            }
        } catch {
            print("获取分类失败: \(error.localizedDescription)")
            // 网络请求失败时已经使用了本地数据，不需要额外处理
        }
    }
    private func setupDefaultStates() {
        // 默认选中 DayTodo
        if let dayTodo = menuData.first(where: { $0.categoryId == -100 }) {
            selectedCategory = dayTodo
        }
        
        // 分类清单默认展开
        if let categoryIndex = menuData.firstIndex(where: { $0.categoryId == -104 }) {
            menuData[categoryIndex].isSelect = true
        }
        
        // 标签组根据是否有数据决定展开状态
        if let tagIndex = menuData.firstIndex(where: { $0.categoryId == -105 }) {
            menuData[tagIndex].isSelect = !menuData[tagIndex].categoryDatas.isEmpty
        }
    }

    /// 更新分类
    @MainActor
    func updateCategory(_ category: TDSliderBarModel) async throws {
        // 不能修改未分类
        guard category.categoryId != 0 else { return }
        
        try await TDCategoryAPI.updateCategory(category)
        
        // 更新本地数据
        if let groupIndex = menuData.firstIndex(where: { $0.categoryId == -104 }),
           let categoryIndex = menuData[groupIndex].categoryDatas.firstIndex(where: { $0.categoryId == category.categoryId }) {
            menuData[groupIndex].categoryDatas[categoryIndex] = category
            saveToLocal()
        }
        
        // 更新成功后刷新列表
        await fetchCategories()
    }
    
    /// 删除分类
    @MainActor
    func deleteCategory(_ categoryId: Int) async throws {
        // 不能删除未分类
        guard categoryId != 0 else { return }
        
        try await TDCategoryAPI.deleteCategory(categoryId)
        
        // 更新本地数据
        if let groupIndex = menuData.firstIndex(where: { $0.categoryId == -104 }) {
            menuData[groupIndex].categoryDatas.removeAll { $0.categoryId == categoryId }
            saveToLocal()
        }
        
        // 删除成功后刷新列表
        await fetchCategories()
    }
    
    /// 更新排序
    @MainActor
    func updateCategoriesSort(_ categories: [TDSliderBarModel]) async throws {
        // 过滤掉未分类，保持其他分类的排序
        let sortedCategories = categories.filter { $0.categoryId != 0 }
        try await TDCategoryAPI.updateCategorySort(sortedCategories)
        
        // 更新本地数据
        if let index = menuData.firstIndex(where: { $0.categoryId == -104 }) {
            // 保持未分类在第一位
            let uncategorized = menuData[index].categoryDatas.first { $0.categoryId == 0 }
            var newCategories = sortedCategories
            if let uncategorized = uncategorized {
                newCategories.insert(uncategorized, at: 0)
            }
            
            menuData[index].categoryDatas = newCategories
            saveToLocal()
        }
        
        // 更新成功后刷新列表
        await fetchCategories()
    }
    /// 临时更新分类顺序（用于拖拽预览）
    @MainActor
    func updateCategoriesOrder(_ categories: [TDSliderBarModel]) {
        if let index = menuData.firstIndex(where: { $0.categoryId == -104 }) {
            var updatedMenu = menuData
            updatedMenu[index].categoryDatas = categories
            menuData = updatedMenu
        }
    }
    // 在 TDCategoryManager 中修改 toggleGroup 方法
    func toggleGroup(_ categoryId: Int) {
        if let index = menuData.firstIndex(where: { $0.categoryId == categoryId }) {
            menuData[index].isSelect.toggle()
            saveToLocal()
        }
    }
    /// 根据ID获取分类
    func category(for categoryId: Int) -> TDSliderBarModel? {
        for group in menuData {
            if group.categoryId == categoryId { return group }
            if let category = group.categoryDatas.first(where: { $0.categoryId == categoryId }) {
                return category
            }
        }
        return nil
    }
    
    // MARK: - 私有方法
    
    /// 保存到本地
    private func saveToLocal() {
        if let data = try? JSONEncoder().encode(menuData) {
            userDefaults.set(data, forKey: storageKey)
        }
    }
    
    /// 从本地加载
    private func loadFromLocal() -> [TDSliderBarModel]? {
        guard let data = userDefaults.data(forKey: storageKey),
              let savedData = try? JSONDecoder().decode([TDSliderBarModel].self, from: data) else {
            return nil
        }
        return savedData
    }
    
    /// 初始化默认数据
    private func loadDefaultData() {
        menuData = [
            // 固定组
            TDSliderBarModel(categoryId: -100, categoryName: "DayTodo", headerIcon: "sun.min"),
            TDSliderBarModel(categoryId: -101, categoryName: "最近待办", headerIcon: "note.text"),
            TDSliderBarModel(categoryId: -102, categoryName: "日程概览", headerIcon: "calendar"),
            TDSliderBarModel(categoryId: -103, categoryName: "待办箱", headerIcon: "tray.full.fill"),
            
            // 分类清单组
            TDSliderBarModel(categoryId: -104, categoryName: "分类清单", headerIcon: "scroll", isSelect: true),
            
            // 标签组
            TDSliderBarModel(categoryId: -105, categoryName: "标签", headerIcon: "tag"),
            
            // 统计组
            TDSliderBarModel(categoryId: -106, categoryName: "数据统计", headerIcon: "chart.pie"),
            TDSliderBarModel(categoryId: -107, categoryName: "最近已完成", headerIcon: "checkmark.square"),
            TDSliderBarModel(categoryId: -108, categoryName: "回收站", headerIcon: "trash")
        ]
    }
    
    
    /// 清除所有分类数据
    func clearData() {
        Task { @MainActor in
            // 重置为默认数据
            loadDefaultData()
            // 清除选中状态
            selectedCategory = nil
            draggedCategory = nil
            // 清除本地存储的数据
            userDefaults.removeObject(forKey: storageKey)
            // 确保分类清单组是空的
            if let index = menuData.firstIndex(where: { $0.categoryId == -104 }) {
                menuData[index].categoryDatas = []
            }
        }
    }
}


extension TDCategoryManager {
    // 固定组项目 (DayTodo,最近待办，日程概览，待办箱)
    var fixedItems: [TDSliderBarModel] {
        menuData.filter { item in
            (-103...(-100)).contains(item.categoryId)
        }.sorted { $0.categoryId > $1.categoryId }
    }
    
    // 分类清单组
    var categoryGroup: TDSliderBarModel? {
        menuData.first { $0.categoryId == -104 }
    }
    
    // 标签组
    var tagGroup: TDSliderBarModel? {
        menuData.first { $0.categoryId == -105 }
    }
    
    // 统计组项目 (数据统计，最近已完成，回收站)
    var statsItems: [TDSliderBarModel] {
        menuData.filter { item in
            (-108...(-106)).contains(item.categoryId)
        }.sorted { $0.categoryId > $1.categoryId }
    }
}
