//
//  TDSliderBarViewModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import Foundation
import SwiftUI


@MainActor
class TDSliderBarViewModel: ObservableObject {
    // MARK: - Published 属性
    
    /// 是否正在同步
    @Published var isSyncing = false {
        didSet {
            // 同步主视图模型的加载状态
            if isSyncing != mainViewModel.isLoading {
                isSyncing = mainViewModel.isLoading
            }
        }
    }
    
    /// 所有分类项（包括系统默认分类和用户创建的分类）
    @Published var items: [TDSliderBarModel] = [] {
        didSet {
            updateSelectedCategory()
        }
    }
    
    /// 选中的分类
    @Published var selectedCategory: TDSliderBarModel? {
        didSet {
            if let category = selectedCategory {
                updateItemsSelection(category)
            }
        }
    }
    
    /// DayTodo 未完成数量
    @Published var dayTodoUnfinishedCount: Int = 0
    
    /// 分类组是否展开
    @Published var isCategoryGroupExpanded = true
    
    /// 标签组是否展开
    @Published var isTagGroupExpanded = true
    
    /// 是否显示添加分类或设置 Sheet
    @Published var showSheet = false
    
    /// 是否显示标签筛选 Sheet
    @Published var showTagFilter = false
    
    /// 标签
    @Published var tagsArr: [TDSliderBarModel] = []
    
    // MARK: - 私有属性
    private let mainViewModel = TDMainViewModel.shared
    
    // MARK: - 初始化方法
    init() {
        // 初始化默认系统分类
        items = TDSliderBarModel.defaultItems
        // 默认选中 DayTodo
        if let dayTodo = items.first(where: { $0.categoryId == -100 }) {
            var dayTodoItem = dayTodo
            dayTodoItem.isSelect = true
            items[0] = dayTodoItem
            selectedCategory = dayTodoItem
            mainViewModel.selectCategory(dayTodoItem)
        }
        // 订阅主视图模型的变化
        setupBindings()
    }
    
    // MARK: - 公共方法
    
    /// 选择分类
    func selectCategory(_ category: TDSliderBarModel) {
        var selectedItem = category
        selectedItem.isSelect = true
        
        // 2. 更新所有项的选中状态
        for i in 0..<items.count {
            var item = items[i]
            item.isSelect = item.categoryId == category.categoryId
            items[i] = item
        }
        
        // 3. 更新选中的分类
        selectedCategory = selectedItem
        mainViewModel.selectCategory(selectedItem)
    }
    
    /// 切换分类组展开状态
    func toggleCategoryGroup() {
        isCategoryGroupExpanded.toggle()
    }
    
    /// 切换标签组展开状态
    func toggleTagGroup() {
        isTagGroupExpanded.toggle()
    }
    
    /// 手动同步数据
    func sync() async {
        await mainViewModel.sync()
    }
    
    // MARK: - 私有方法
    
    /// 设置数据绑定
    private func setupBindings() {
        // 监听主视图模型的分类数据变化
        Task {
            for await categories in mainViewModel.$categories.values {
                updateCategoryItems(categories)
            }
        }
        
        // 监听主视图模型的选中分类变化
        Task {
            for await category in mainViewModel.$selectedCategory.values {
                if category?.categoryId != selectedCategory?.categoryId {
                    if let category = category {
                        // 找到对应的本地分类项
                        if let localCategory = items.first(where: { $0.categoryId == category.categoryId }) {
                            selectedCategory = localCategory
                        }
                    } else {
                        selectedCategory = nil
                    }
                }
            }
        }
        
        // 监听主视图模型的加载状态变化
        Task {
            for await isLoading in mainViewModel.$isLoading.values {
                if isLoading != isSyncing {
                    isSyncing = isLoading
                }
            }
        }
    }
    
    /// 更新分类列表数据
    private func updateCategoryItems(_ categories: [TDSliderBarModel]) {
        // 1. 将系统默认分类和用户创建的分类合并
        var newItems = TDSliderBarModel.defaultItems
        
        // 2. 找到分类清单的位置
        if let categoryListIndex = newItems.firstIndex(where: { $0.categoryId == -104 }) {
            // 3. 在分类清单后面插入用户创建的分类
            newItems.insert(contentsOf: categories, at: categoryListIndex + 1)
        }
        
        // 4. 保持选中状态
        if let selectedId = selectedCategory?.categoryId {
            for i in 0..<newItems.count {
                newItems[i].isSelect = newItems[i].categoryId == selectedId
            }
        } else if let index = newItems.firstIndex(where: { $0.categoryId == -100 }) {
            // 如果没有选中项，默认选中 DayTodo
            newItems[index].isSelect = true
            selectedCategory = newItems[index]
            mainViewModel.selectCategory(newItems[index])
        }
        
        // 5. 更新界面数据
        items = newItems
    }
    
    /// 更新选中的分类
    private func updateSelectedCategory() {
        // 如果当前选中的分类在新数据中不存在，选中 DayTodo
        if let selected = selectedCategory,
           !items.contains(where: { $0.categoryId == selected.categoryId }),
           let dayTodo = items.first(where: { $0.categoryId == -100 }) {
            selectCategory(dayTodo)
        }
    }
    
    /// 更新列表项的选中状态
    private func updateItemsSelection(_ category: TDSliderBarModel) {
        for i in 0..<items.count {
            var item = items[i]
            item.isSelect = item.categoryId == category.categoryId
            items[i] = item
        }
    }
}


//class TDSliderBarViewModel: ObservableObject {
//    // MARK: - Published 属性
//    
//    /// 是否正在同步
//    @Published var isSyncing = false
//    
//    /// 所有分类项（包括系统默认分类和用户创建的分类）
//    @Published var items: [TDSliderBarModel] = []
//    
//    /// 选中的分类
//    @Published var selectedCategory: TDSliderBarModel?
//    
//    /// DayTodo 未完成数量
//    @Published var dayTodoUnfinishedCount: Int = 0
//    
//    /// 分类组是否展开
//    @Published var isCategoryGroupExpanded = true
//    
//    /// 标签组是否展开
//    @Published var isTagGroupExpanded = true
//    
//    /// 是否显示添加分类或设置 Sheet
//    @Published var showSheet = false
//    
//    /// 是否显示标签筛选 Sheet
//    @Published var showTagFilter = false
//    /// 标签
//    @Published var tagsArr : [TDSliderBarModel] = []
//
//    // MARK: - 初始化
//    
//    init() {
//        // 初始化默认系统分类
//        items = TDSliderBarModel.defaultItems
//        // 默认选中 DayTodo
//        if let dayTodo = items.first(where: { $0.categoryId == -100 }) {
//            selectCategory(dayTodo)
//        }
//    }
//
//    // MARK: - 公共方法
//    /// 登录后同步数据
//    func syncAfterLogin() async {
//        await MainActor.run {
//            isSyncing = true
//        }
//        do {
//            // 1. 在异步线程获取服务器分类清单数据
//            let serverCategories = try await Task.detached {
//                return try await TDCategoryAPI.shared.getCategoryList()
//            }.value
//            
//            // 2. 在异步线程保存到本地
//            await Task.detached {
//                await TDCategoryManager.shared.saveCategories(serverCategories)
//            }.value
//            
//            // 3. 在主线程更新界面数据
//            await MainActor.run {
//                updateCategoryItems(serverCategories)
//            }
//            // 同步服务器数据到本地数据库
//            await syncServerDataToLocal()
//            
//            await MainActor.run {
//                isSyncing = false
//            }
//
//        } catch {
//            print("登录后同步失败: \(error)")
//            await MainActor.run {
//                isSyncing = false
//            }
//        }
//    }
//
//    /// 启动后同步数据
//    func syncAfterLaunch() async {
////        await MainActor.run {
////            isSyncing = true
////        }
//        // 1. 在异步线程加载本地数据
//        let localCategories = await Task.detached {
//            return TDCategoryManager.shared.loadLocalCategories()
//        }.value
//        
//        // 2. 在主线程更新界面
//        await MainActor.run {
//            updateCategoryItems(localCategories)
//            isSyncing = true
//        }
//        
//        do {
//            let serverCategories = try await Task.detached {
//                return try await TDCategoryAPI.shared.getCategoryList()
//            }.value
//            
//            await Task.detached {
//                await TDCategoryManager.shared.saveCategories(serverCategories)
//            }.value
//            
//            // 3. 在主线程更新界面数据
//            await MainActor.run {
//                updateCategoryItems(serverCategories)
//            }
//            // 同步服务器数据到本地数据库
//            await syncServerDataToLocal()
//            
//            await MainActor.run {
//                isSyncing = false
//            }
//        } catch {
//            print("启动后同步失败: \(error)")
//            await MainActor.run {
//                isSyncing = false
//            }
//        }
//    }
//    
//    /// 手动同步数据
//    func sync() async {
//        await MainActor.run {
//            isSyncing = true
//        }
//        do {
//            let serverCategories = try await Task.detached {
//                return try await TDCategoryAPI.shared.getCategoryList()
//            }.value
//            
//            await Task.detached {
//                await TDCategoryManager.shared.saveCategories(serverCategories)
//            }.value
//            
//            // 3. 在主线程更新界面数据
//            await MainActor.run {
//                updateCategoryItems(serverCategories)
//            }
//            // 同步服务器数据到本地数据库
//            await syncServerDataToLocal()
//            
//            await MainActor.run {
//                isSyncing = false
//            }
//        } catch {
//            print("手动同步失败: \(error)")
//            await MainActor.run {
//                isSyncing = false
//            }
//        }
//    }
//
//    
//    /// 选择分类
//    func selectCategory(_ category: TDSliderBarModel) {
//        // 更新选中状态
//        selectedCategory = category
//        
//        // 更新列表项的选中状态
//        for i in 0..<items.count {
//            var item = items[i]
//            item.isSelect = item.categoryId == category.categoryId
//            items[i] = item
//        }
//    }
//    
//    /// 切换分类组展开状态
//    func toggleCategoryGroup() {
//        isCategoryGroupExpanded.toggle()
//    }
//    
//    /// 切换标签组展开状态
//    func toggleTagGroup() {
//        isTagGroupExpanded.toggle()
//    }
//    
//    // MARK: - 私有方法
//    
//    
//    /// 从服务器获取分类清单数据
//    private func fetchServerCategories() async throws -> [TDSliderBarModel] {
//        // TODO: 实现服务器请求
//        return []
//    }
//    
//   
//    
//    /// 更新分类列表数据
//    private func updateCategoryItems(_ categories: [TDSliderBarModel]) {
//        // 1. 将系统默认分类和用户创建的分类合并
//        var newItems = TDSliderBarModel.defaultItems
//        
//        // 2. 找到分类清单的位置
//        if let categoryListIndex = newItems.firstIndex(where: { $0.categoryId == -104 }) {
//            // 3. 在分类清单后面插入用户创建的分类
//            newItems.insert(contentsOf: categories, at: categoryListIndex + 1)
//        }
//        
//        // 4. 更新界面数据
//        items = newItems
//        
//        // 5. 如果当前选中的分类在新数据中不存在,则选中 DayTodo
//        if let selectedCategory = selectedCategory,
//           !newItems.contains(where: { $0.categoryId == selectedCategory.categoryId }) {
//            if let dayTodo = newItems.first(where: { $0.categoryId == -100 }) {
//                selectCategory(dayTodo)
//            }
//        }
//    }
//
//    /// 同步服务器数据到本地数据库
//    private func syncServerDataToLocal() async {
//        // TODO: 实现数据同步
//    }
//}



//@MainActor
//class TDSliderBarViewModel: ObservableObject {
//    // MARK: - Published 属性
//    
//    /// 所有分类项
//    @Published var items: [TDSliderBarModel] = []
//    
//    /// 选中的分类ID
//    @Published var selectedCategoryId: Int?
//    
//    /// DayTodo 未完成数量
//    @Published var dayTodoUnfinishedCount: Int = 0
//    
//    /// 分类组是否展开
//    @Published var isCategoryGroupExpanded = true
//    
//    /// 标签组是否展开
//    @Published var isTagGroupExpanded = true
//    
//    /// 是否显示添加分类 Sheet
//    @Published var showAddCategorySheet = false
//    
//    /// 是否显示分类设置 Sheet
//    @Published var showCategorySettings = false
//    
//    /// 是否显示标签筛选 Sheet
//    @Published var showTagFilter = false
//    
//    /// 是否显示 Toast
//    @Published var showToast = false
//    
//    /// Toast 消息
//    @Published var toastMessage = ""
//    @Published var isLoading = false
//
//    init() {
//        // 初始化默认数据
//        self.items = TDSliderBarModel.defaultItems
//    }
//    
//    // MARK: - 数据同步
//    
//    /// 登录后的数据同步
//    func syncCategoriesAfterLogin() async {
//        isLoading = true
//        defer { isLoading = false }
//        
//        do {
//            // 1. 获取服务器分类数据
//            let categories = try await TDCategoryAPI.shared.getCategoryList()
//            
//            // 2. 保存到本地文件
//            await TDCategoryManager.shared.saveCategories(categories)
//
//            // 3. 更新分类清单数据
//            await MainActor.run {
//                updateCategoryList(with: categories)
//            }
//
//        } catch {
//            // 登录场景下的同步失败，显示错误提示
//            toastMessage = "同步数据失败：\(error.localizedDescription)"
//            showToast = true
//        }
//    }
//    
//    /// App 重新启动后的数据同步
//    func syncCategoriesAfterLaunch() async {
//        isLoading = true
//        defer { isLoading = false }
//        Task {
//            // 1. 先加载本地分类清单数据
//            let localCategories = TDCategoryManager.shared.loadLocalCategories()
//            if !localCategories.isEmpty {
//                await MainActor.run {
//                    updateCategoryList(with: localCategories)
//                }
//            }
//            
//            do {
//                // 2. 获取服务器最新分类数据
//                let categories = try await TDCategoryAPI.shared.getCategoryList()
//                
//                // 3. 保存到本地文件
//                await TDCategoryManager.shared.saveCategories(categories)
//                
//                // 4. 更新分类清单数据
//                await MainActor.run {
//                    updateCategoryList(with: categories)
//                }
//            } catch {
//                // 重启场景下的同步失败，继续使用本地数据
//                print("同步服务器数据失败：\(error.localizedDescription)")
//            }
//
//        }
//    }
//    
//    
//    /// 添加分类
//    func addCategory(name: String, color: String) async {
//        isLoading = true
//        
//        do {
//            // 添加分类
//            try await TDCategoryAPI.shared.addCategory(name: name, color: color)
//            // 重新获取分类列表
//            let categories = try await TDCategoryAPI.shared.getCategoryList()
//            // 3. 保存到本地文件
//            await TDCategoryManager.shared.saveCategories(categories)
//            // 4. 更新分类清单数据
//            await MainActor.run {
//                updateCategoryList(with: categories)
//                toastMessage = "添加分类成功"
//                showToast = true
//            }            // 显示成功提示
//        } catch let error as TDNetworkError {
//            if case .requestFailed(let message) = error {
//                toastMessage = message
//                showToast = true
//            }
//        } catch {
//            toastMessage = error.localizedDescription
//            showToast = true
//        }
//        
//        isLoading = false
//    }
//    
//    /// 更新分类信息
//    func updateCategoryInfo(categoryId: Int, name: String, color: String) async {
//        isLoading = true
//        
//        do {
//            // 更新分类信息
//            try await TDCategoryAPI.shared.updateCategoryInfo(
//                categoryId: categoryId,
//                name: name,
//                color: color
//            )
//            // 重新获取分类列表
//            let categories = try await TDCategoryAPI.shared.getCategoryList()
//            // 3. 保存到本地文件
//            await TDCategoryManager.shared.saveCategories(categories)
//            
//            // 4. 更新分类清单数据
//            await MainActor.run {
//                updateCategoryList(with: categories)
//                toastMessage = "更新分类成功"
//                showToast = true
//            }
//        } catch let error as TDNetworkError {
//            if case .requestFailed(let message) = error {
//                toastMessage = message
//                showToast = true
//            }
//        } catch {
//            toastMessage = error.localizedDescription
//            showToast = true
//        }
//        
//        isLoading = false
//    }
//    
//    /// 更新分类排序
//    func updateCategorySort(categoryId: Int, newSort: Int) async {
//        isLoading = true
//        
//        do {
//            // 更新分类排序
//            try await TDCategoryAPI.shared.updateCategorySort(
//                categoryId: categoryId,
//                newSort: newSort
//            )
//            // 重新获取分类列表
//            let categories = try await TDCategoryAPI.shared.getCategoryList()
//            // 3. 保存到本地文件
//            await TDCategoryManager.shared.saveCategories(categories)
//            
//            // 4. 更新分类清单数据
//            await MainActor.run {
//                updateCategoryList(with: categories)
//                toastMessage = "更新排序成功"
//                showToast = true
//            }
//            // 显示成功提示
//        } catch let error as TDNetworkError {
//            if case .requestFailed(let message) = error {
//                toastMessage = message
//                showToast = true
//            }
//        } catch {
//            toastMessage = error.localizedDescription
//            showToast = true
//        }
//        
//        isLoading = false
//    }
//    
//    /// 删除分类
//    func deleteCategory(categoryId: Int) async {
//        isLoading = true
//        
//        do {
//            // 删除分类
//            try await TDCategoryAPI.shared.deleteCategory(categoryId: categoryId)
//            // 重新获取分类列表
//            let categories = try await TDCategoryAPI.shared.getCategoryList()
//            // 3. 保存到本地文件
//            await TDCategoryManager.shared.saveCategories(categories)
//            
//            // 4. 更新分类清单数据
//            await MainActor.run {
//                updateCategoryList(with: categories)
//                toastMessage = "删除分类成功"
//                showToast = true
//            }
//            // 显示成功提示
//        } catch let error as TDNetworkError {
//            if case .requestFailed(let message) = error {
//                toastMessage = message
//                showToast = true
//            }
//        } catch {
//            toastMessage = error.localizedDescription
//            showToast = true
//        }
//        
//        isLoading = false
//    }
//    
//    // MARK: - 私有方法
//    
//    /// 更新分类清单数据
//    private func updateCategoryList(with categories: [TDSliderBarModel]) {
//        // 找到分类清单组的索引
//        if let index = items.firstIndex(where: { $0.categoryId == -104 }) {
//            // 创建新的分类列表，始终保持"未分类"在第一位
//            var newCategories = [TDSliderBarModel(categoryId: 0, categoryName: "未分类", headerIcon: "questionmark.circle")]
//            
//            // 添加服务器返回的分类
//            newCategories.append(contentsOf: categories)
//            
//            // 更新分类清单组的子项
//            var updatedCategoryGroup = items[index]
//            updatedCategoryGroup.children = newCategories
//            
//            // 更新数组
//            items[index] = updatedCategoryGroup
//        }
//    }
//    
//    // MARK: - 用户交互
//    
//    /// 切换分类组展开状态
//    func toggleCategoryGroup() {
//        isCategoryGroupExpanded.toggle()
//        toggleExpanded(for: -104)
//    }
//    
//    /// 切换标签组展开状态
//    func toggleTagGroup() {
//        isTagGroupExpanded.toggle()
//        toggleExpanded(for: -105)
//    }
//    
//    // MARK: - 私有方法
//    
//    /// 切换指定分类的展开状态
//    private func toggleExpanded(for categoryId: Int) {
//        if let index = items.firstIndex(where: { $0.categoryId == categoryId }) {
//            var item = items[index]
//            item.isExpanded!.toggle()
//            items[index] = item
//        }
//    }
//
//    
//    /// 选择分类
//    func selectCategory(categoryId: Int) {
//        // 如果点击的是分类清单或标签组，则只切换展开状态，不选中
//        if categoryId == -104 || categoryId == -105 {
//            toggleExpanded(for: categoryId)
//            return
//        }
//        
//        // 更新选中状态
//        selectedCategoryId = categoryId
//        
//        // 更新列表项的选中状态
//        for i in 0..<items.count {
//            var item = items[i]
//            
//            // 分类组本身不需要处理选中状态
//            if item.categoryId == -104 || item.categoryId == -105 {
//                if let children = item.children {
//                    item.children = children.map { child in
//                        var updatedChild = child
//                        updatedChild.isSelect = child.categoryId == categoryId
//                        return updatedChild
//                    }
//                }
//            } else {
//                // 其他所有项目（包括 DayTodo 等）都可以被选中
//                item.isSelect = item.categoryId == categoryId
//                if let children = item.children {
//                    item.children = children.map { child in
//                        var updatedChild = child
//                        updatedChild.isSelect = child.categoryId == categoryId
//                        return updatedChild
//                    }
//                }
//            }
//            items[i] = item
//        }
//    }
//
//}
