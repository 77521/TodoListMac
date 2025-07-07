//
//  TDSliderBarViewModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import Foundation
import SwiftUI

import OSLog

/// 侧边栏视图模型 - 极简高性能版本
/// 优化重点：
/// 1. 去掉缓存机制，简化逻辑
/// 2. 立即响应分类切换
/// 3. 减少复杂的异步操作
/// 4. 专注核心功能
@MainActor
class TDSliderBarViewModel: ObservableObject {
    
    // MARK: - 日志系统
    private let logger = Logger(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDSliderBarViewModel")
    
    // MARK: - Published 属性
    
    /// 是否正在同步
    @Published var isSyncing = false
    
    /// 所有分类项（包括系统默认分类和用户创建的分类）
    @Published var items: [TDSliderBarModel] = [] {
        didSet {
            validateSelectedCategory()
        }
    }
    
    /// 选中的分类
    @Published var selectedCategory: TDSliderBarModel? {
        didSet {
            if let category = selectedCategory,
               oldValue?.categoryId != category.categoryId {  // 只有当分类真正改变时才处理
                updateItemsSelection(category)
                // 直接通知主视图模型
                TDMainViewModel.shared.selectCategory(category)
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
    
    /// 标签数组
    @Published var tagsArr: [TDSliderBarModel] = []
    
    /// 错误信息
    @Published var errorMessage: String?

    // MARK: - 初始化方法
    
    init() {
        logger.info("📱 侧边栏ViewModel初始化开始")
        
        // 初始化默认系统分类
        items = TDSliderBarModel.defaultItems
        
        // 选择默认分类
        if let dayTodo = items.first(where: { $0.categoryId == -100 }) {
            selectedCategory = dayTodo
        }
        
        // 异步加载数据
        Task {
            await loadInitialData()
        }
        
        logger.info("📱 侧边栏ViewModel初始化完成")
    }
    
    // MARK: - 公共方法
    
    /// 选择分类 - 极简版本
    func selectCategory(_ category: TDSliderBarModel) {
        logger.info("🎯 用户选择分类: \(category.categoryName) (ID: \(category.categoryId))")
        
        // 直接更新选中分类
        selectedCategory = category
    }
    
    /// 切换分类组展开状态
    func toggleCategoryGroup() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isCategoryGroupExpanded.toggle()
        }
    }
    
    /// 切换标签组展开状态
    func toggleTagGroup() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isTagGroupExpanded.toggle()
        }
    }
    
    /// 执行同步
    func performSync() {
        Task {
            await performSyncOperation()
        }
    }
    
    /// 显示添加分类弹窗
    func showAddCategorySheet() {
        showSheet = true
    }
    
    /// 显示标签筛选弹窗
    func showTagFilterSheet() {
        showTagFilter = true
    }
    
    // MARK: - 私有方法
    
    /// 加载初始数据
    private func loadInitialData() async {
        logger.info("📚 加载初始数据")
        
        // 从本地加载分类数据
        await loadCategoriesFromLocal()
        
        // 尝试从服务器获取最新数据
        do {
            try await loadCategoriesFromServer()
        } catch {
            logger.error("❌ 加载服务器分类失败: \(error.localizedDescription)")
        }
    }
    
    /// 从本地加载分类数据
    private func loadCategoriesFromLocal() async {
        logger.debug("💾 从本地加载分类数据")
        
        let localCategories = TDCategoryManager.shared.loadLocalCategories()
        updateCategoryItems(localCategories)
        
        logger.debug("💾 本地分类数据加载完成，共\(localCategories.count)项")
    }
    
    /// 从服务器加载分类数据
    private func loadCategoriesFromServer() async throws {
        logger.debug("🌐 从服务器加载分类数据")
        
        // 获取服务器分类数据
        let serverCategories = try await TDCategoryAPI.shared.getCategoryList()
        
        // 保存到本地
        await TDCategoryManager.shared.saveCategories(serverCategories)
        
        // 更新UI
        updateCategoryItems(serverCategories)
        
        logger.info("✅ 服务器分类数据加载完成，共\(serverCategories.count)项")
    }
    
    /// 执行同步操作
    private func performSyncOperation() async {
        isSyncing = true
        errorMessage = nil
        
        do {
            // 执行同步
            await TDMainViewModel.shared.sync()
            
            // 重新加载分类数据
            try await loadCategoriesFromServer()
            
            logger.info("✅ 同步完成")
            
        } catch {
            logger.error("❌ 同步失败: \(error.localizedDescription)")
            errorMessage = "同步失败: \(error.localizedDescription)"
        }
        
        isSyncing = false
    }
    
    /// 更新分类列表数据
    private func updateCategoryItems(_ categories: [TDSliderBarModel]) {
        logger.debug("🔄 更新分类列表数据")
        
        // 合并系统默认分类和用户创建的分类
        var newItems = TDSliderBarModel.defaultItems
        
        // 在分类清单后插入用户创建的分类
        if let categoryListIndex = newItems.firstIndex(where: { $0.categoryId == -104 }) {
            newItems.insert(contentsOf: categories, at: categoryListIndex + 1)
        }
        
        // 保持选中状态
        if let selectedId = selectedCategory?.categoryId {
            for i in 0..<newItems.count {
                newItems[i].isSelect = newItems[i].categoryId == selectedId
            }
        }
        
        // 更新界面数据
        items = newItems
        
        logger.debug("✅ 分类列表更新完成，共\(newItems.count)项")
    }
    
    /// 验证选中的分类是否还有效
    private func validateSelectedCategory() {
        if let selected = selectedCategory,
           !items.contains(where: { $0.categoryId == selected.categoryId }) {
            
            logger.warning("⚠️ 选中的分类不存在，重置为DayTodo")
            
            // 选中 DayTodo
            if let dayTodo = items.first(where: { $0.categoryId == -100 }) {
                selectedCategory = dayTodo
            }
        }
    }
    
    /// 更新列表项的选中状态
    private func updateItemsSelection(_ category: TDSliderBarModel) {
        // 使用临时变量避免频繁触发 didSet
        var updatedItems = items
        var hasChanges = false
        
        for i in 0..<updatedItems.count {
            let shouldSelect = updatedItems[i].categoryId == category.categoryId
            if updatedItems[i].isSelect != shouldSelect {
                updatedItems[i].isSelect = shouldSelect
                hasChanges = true
            }
        }
        
        // 只有在真正有变化时才更新
        if hasChanges {
            items = updatedItems
        }
    }
    
    // MARK: - 清理方法
    
    deinit {
        logger.info("🗑️ 侧边栏ViewModel销毁")
    }
}

// MARK: - 扩展：错误处理

extension TDSliderBarViewModel {
    
    /// 清除错误信息
    func clearError() {
        errorMessage = nil
    }
    
    /// 重试操作
    func retry() async {
        clearError()
        do {
            try await loadCategoriesFromServer()
        } catch {
            logger.error("❌ 重试失败: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "重试失败: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - 扩展：调试支持

#if DEBUG
extension TDSliderBarViewModel {
    
    /// 打印调试信息
    func printDebugInfo() {
        logger.debug("""
        📊 侧边栏调试信息:
        - 分类数量: \(self.items.count)
        - 选中分类: \(self.selectedCategory?.categoryName ?? "无")
        - 同步状态: \(self.isSyncing ? "进行中" : "空闲")
        """)
    }
}
#endif
