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
    // MARK: - 单例
    static let shared = TDSliderBarViewModel()

    // MARK: - 日志系统
    private let logger = Logger(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDSliderBarViewModel")
    
    // MARK: - Published 属性
    
    /// 是否正在同步
    @Published var isSyncing = false
    /// 同步进度信息
    @Published var syncProgress: String = ""

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
    

    // MARK: - 初始化方法
    
    private init() {
        logger.info("📱 侧边栏ViewModel初始化开始")
        
        // 初始化默认系统分类
        items = TDSliderBarModel.defaultItems
        
        // 选择默认分类
        if let dayTodo = items.first(where: { $0.categoryId == -100 }) {
            selectedCategory = dayTodo
        }
        // 立即加载本地分类数据（确保即使网络失败也能显示本地数据）
        loadLocalCategories()

        logger.info("📱 侧边栏ViewModel初始化完成")
    }

    // MARK: - 公共方法
    
    /// 选择分类 - 极简版本
    func selectCategory(_ category: TDSliderBarModel) {
        logger.info("🎯 用户选择分类: \(category.categoryName) (ID: \(category.categoryId))")        
        // 使用 Task 来避免在 View 更新过程中修改 @Published 属性
        Task { @MainActor in
            selectedCategory = category
        }
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
            await TDMainViewModel.shared.performSyncSeparately()
        }
    }
    /// 开始同步
    func startSync(isFirstTime: Bool = false) {
        isSyncing = true
        syncProgress = isFirstTime ? "首次同步中..." : "同步中..."
        logger.info("🔄 开始同步")
    }
    
    /// 更新同步进度
    func updateSyncProgress(current: Int, total: Int, isFirstTime: Bool = false) {
        syncProgress = isFirstTime ? "Todo：首次同步中 \(current)/\(total)" : "同步中 \(current)/\(total)"
        logger.info("📊 同步进度: \(current)/\(total)")
    }
    
    /// 完成同步
    func completeSync() {
        isSyncing = false
        syncProgress = ""
        logger.info("✅ 同步完成")
    }

    /// 显示添加分类弹窗
    func showAddCategorySheet() {
        showSheet = true
    }
    
    /// 显示标签筛选弹窗
    func showTagFilterSheet() {
        showTagFilter = true
    }
    
    /// 更新分类数据（供 TDMainViewModel 调用）
    func updateCategories(_ categories: [TDSliderBarModel]) {
        logger.debug("🔄 更新分类数据，共\(categories.count)项")
        updateCategoryItems(categories)
    }
    /// 加载本地分类数据
    private func loadLocalCategories() {
        logger.debug("💾 加载本地分类数据")
        
        let localCategories = TDCategoryManager.shared.loadLocalCategories()
        if !localCategories.isEmpty {
            updateCategoryItems(localCategories)
            logger.debug("💾 本地分类数据加载完成，共\(localCategories.count)项")
        } else {
            logger.debug("💾 本地没有分类数据")
        }
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
