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
    // MARK: - 分类清单：新增/编辑/删除（把业务逻辑集中在 ViewModel）
    /// 当前正在编辑的分类/文件夹（用于 sheet(item:)）
    @Published var editingCategory: TDSliderBarModel?

    /// 当前准备删除的分类/文件夹（用于 alert）
    @Published var deletingCategory: TDSliderBarModel?

    /// 是否显示删除确认弹窗
    @Published var showDeleteAlert: Bool = false

    /// VIP 弹窗控制（供新建弹窗复用）
    @Published var showVipModal: Bool = false
    @Published var vipSubtitleKey: String = "settings.vip.modal.subtitle.theme"

    /// 是否显示标签筛选 Sheet
    @Published var showTagFilter = false
    
    /// 标签数组
    @Published var tagsArr: [TDSliderBarModel] = []
    
    /// 文件夹展开状态字典（key: folderId, value: 是否展开）
    @Published var folderExpandedStates: [Int: Bool] = [:]


    // MARK: - 初始化方法
    
    private init() {
        logger.info("📱 侧边栏ViewModel初始化开始")
        
        // 初始化默认系统分类
        items = TDSliderBarModel.defaultItems(settingManager: TDSettingManager.shared)

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
    
    // MARK: - 右键菜单：编辑/删除入口
    func beginEditCategory(_ category: TDSliderBarModel) {
        editingCategory = category
    }

    func requestDeleteCategory(_ category: TDSliderBarModel) {
        deletingCategory = category
        showDeleteAlert = true
    }

    func cancelDeleteCategory() {
        deletingCategory = nil
        showDeleteAlert = false
    }

    // MARK: - 删除分类/文件夹
    func confirmDeleteCategory() async {
        guard let category = deletingCategory else { return }
        let shouldSelectDayTodoAfterDelete = selectedCategory?.categoryId == category.categoryId
        do {
            try await TDCategoryAPI.shared.deleteCategory(categoryId: category.categoryId)
            let serverCategories = try await TDCategoryAPI.shared.getCategoryList()
            await TDCategoryManager.shared.saveCategories(serverCategories)
            updateCategories(serverCategories)
            if shouldSelectDayTodoAfterDelete,
               let dayTodo = items.first(where: { $0.categoryId == -100 }) {
                selectedCategory = dayTodo
            }
            TDToastCenter.shared.show("category.context.delete.success", type: .success, position: .bottom)
            cancelDeleteCategory()
        } catch {
            let message: String
            if let netError = error as? TDNetworkError {
                message = netError.errorMessage
            } else {
                message = error.localizedDescription
            }
            TDToastCenter.shared.show(message, type: .error, position: .bottom)
        }
    }

    // MARK: - 编辑分类/文件夹
    /// - Returns: 是否保存成功（成功后 View 可自行关闭 sheet）
    func saveCategoryChanges(categoryId: Int, name: String, color: String, isFolder: Bool, folderId: Int?) async -> Bool {
        do {
            try await TDCategoryAPI.shared.updateCategoryInfo(
                categoryId: categoryId,
                name: name,
                color: color,
                isFolder: isFolder ? true : nil,
                folderId: folderId
            )
            let serverCategories = try await TDCategoryAPI.shared.getCategoryList()
            await TDCategoryManager.shared.saveCategories(serverCategories)
            updateCategories(serverCategories)
            TDToastCenter.shared.show("category.context.update.success", type: .success, position: .bottom)
            return true
        } catch {
            let message: String
            if let netError = error as? TDNetworkError {
                message = netError.errorMessage
            } else {
                message = error.localizedDescription
            }
            TDToastCenter.shared.show(message, type: .error, position: .bottom)
            return false
        }
    }

    // MARK: - 新增分类/文件夹（含 VIP/重复色校验）
    /// - Returns: 是否创建成功（成功后 View 可自行关闭 sheet）
    func createCategory(name: String, color: String, isFolder: Bool, parentFolderId: Int?) async -> Bool {
        // VIP 限制：
        // 1）创建文件夹：必须是 VIP
        if isFolder, !TDUserManager.shared.isVIP {
            vipSubtitleKey = "settings.vip.modal.subtitle.add_folder"
            showVipModal = true
            return false
        }
        // 2）创建分类清单：非 VIP 最多 3 个
        if !isFolder, !TDUserManager.shared.isVIP {
            let count = TDCategoryManager.shared.userCreatedCategoryCount()
            if count >= 3 {
                vipSubtitleKey = "settings.vip.modal.subtitle.category_limit"
                showVipModal = true
                return false
            }
        }

        // 本地重复色值校验
        if TDCategoryManager.shared.hasDuplicateColor(color) {
            TDToastCenter.shared.show("category.new.toast.color_duplicate", type: .error, position: .bottom)
            return false
        }

        do {
            try await TDCategoryAPI.shared.addCategory(
                name: name,
                color: color,
                isFolder: isFolder,
                parentFolderId: parentFolderId
            )

            let serverCategories = try await TDCategoryAPI.shared.getCategoryList()
            await TDCategoryManager.shared.saveCategories(serverCategories)
            updateCategories(serverCategories)
            TDToastCenter.shared.show(
                isFolder ? "category.new.toast.add_folder_success" : "category.new.toast.add_category_success",
                type: .success,
                position: .bottom
            )
            return true
        } catch {
            let message: String
            if let netError = error as? TDNetworkError {
                message = netError.errorMessage
            } else {
                message = error.localizedDescription
            }
            TDToastCenter.shared.show(message, type: .error, position: .bottom)
            return false
        }
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
    
    /// 因设置变更（如日程概览开关）重建默认系统项，并合并用户分类
    func rebuildForSettingsChange() {
        let localCategories = TDCategoryManager.shared.loadLocalCategories()
        updateCategoryItems(localCategories)
        // 如果当前选中的是日程概览且已关闭，则切回 DayTodo
        if !TDSettingManager.shared.enableScheduleOverview,
           selectedCategory?.categoryId == -102 {
            if let dayTodo = items.first(where: { $0.categoryId == -100 }) {
                selectedCategory = dayTodo
            }
        }
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
        var newItems = TDSliderBarModel.defaultItems(settingManager: TDSettingManager.shared)

        // 在分类清单后插入用户创建的分类
        if let categoryListIndex = newItems.firstIndex(where: { $0.categoryId == -104 }) {
            // 使用新的逻辑处理分类清单数据（按照 iOS 逻辑）
            let processedCategories = TDCategoryManager.shared.getFolderWithSubCategories(from: categories)
            
            // 创建包含"未分类"的完整分类列表
            var fullCategories = [TDSliderBarModel.uncategorized] // 第一项永远是"未分类"
            fullCategories.append(contentsOf: processedCategories) // 后面是处理后的分类（包含文件夹和子分类）

            newItems.insert(contentsOf: fullCategories, at: categoryListIndex + 1)
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
        guard let selected = selectedCategory else { return }
        
        // 递归检查分类是否存在（包括文件夹的 children）
        let exists = findCategoryInItems(categoryId: selected.categoryId, in: items)
        
        if !exists {
            logger.warning("⚠️ 选中的分类不存在，重置为DayTodo: \(selected.categoryName) (ID: \(selected.categoryId))")
            
            // 选中 DayTodo
            if let dayTodo = items.first(where: { $0.categoryId == -100 }) {
                selectedCategory = dayTodo
            }
        }
    }
    
    /// 递归查找分类是否存在（包括文件夹的 children）
    /// - Parameters:
    ///   - categoryId: 要查找的分类ID
    ///   - items: 要搜索的分类数组
    /// - Returns: 是否存在
    private func findCategoryInItems(categoryId: Int, in items: [TDSliderBarModel]) -> Bool {
        // 先检查 items 数组本身
        for item in items {
            if item.categoryId == categoryId {
                return true
            }
            
            // 递归检查子分类
            if let children = item.children {
                if findCategoryInItems(categoryId: categoryId, in: children) {
                    return true
                }
            }
        }
        
        return false
    }

    /// 更新列表项的选中状态
    private func updateItemsSelection(_ category: TDSliderBarModel) {
        logger.debug("🔄 开始更新选中状态: \(category.categoryName) (ID: \(category.categoryId))")
        
        // 使用临时变量避免频繁触发 didSet
        var updatedItems = items
        var hasChanges = false
        var selectedItemName: String? = nil
        var deselectedItemNames: [String] = []
        
        // 遍历所有项，更新选中状态
        for i in 0..<updatedItems.count {
            // 更新当前项的选中状态
            let shouldSelect = updatedItems[i].categoryId == category.categoryId
            if updatedItems[i].isSelect != shouldSelect {
                updatedItems[i].isSelect = shouldSelect
                hasChanges = true
                if shouldSelect {
                    selectedItemName = updatedItems[i].categoryName
                } else {
                    // 记录被取消选中的项（这是正常的单选行为）
                    deselectedItemNames.append(updatedItems[i].categoryName)
                }
            }
            
            // 更新子分类的选中状态（重要：子分类在 children 数组中）
            if var children = updatedItems[i].children {
                var childrenChanged = false
                
                // 遍历子分类，更新选中状态
                for j in 0..<children.count {
                    let childShouldSelect = children[j].categoryId == category.categoryId
                    if children[j].isSelect != childShouldSelect {
                        children[j].isSelect = childShouldSelect
                        childrenChanged = true
                        if childShouldSelect {
                            selectedItemName = children[j].categoryName
                        } else {
                            // 记录被取消选中的子分类
                            deselectedItemNames.append(children[j].categoryName)
                        }
                    }
                }
                
                // 如果有变化，创建新的 children 数组并赋值（确保 SwiftUI 检测到变化）
                if childrenChanged {
                    updatedItems[i].children = children
                    hasChanges = true
                }
            }
        }
        
        // 输出清晰的日志
        if hasChanges {
            if let selected = selectedItemName {
                logger.debug("✅ 选中: \(selected) (ID: \(category.categoryId))")
            }
            if !deselectedItemNames.isEmpty {
                logger.debug("ℹ️ 取消选中其他项（单选行为）: \(deselectedItemNames.joined(separator: ", "))")
            }
            items = updatedItems
        } else {
            logger.debug("ℹ️ 没有需要更新的选中状态")
        }
    }
    /// 切换文件夹展开状态
    func toggleFolderExpanded(folderId: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            folderExpandedStates[folderId] = !(folderExpandedStates[folderId] ?? false)
        }
    }
    
    /// 获取文件夹是否展开
    func isFolderExpanded(folderId: Int) -> Bool {
        return folderExpandedStates[folderId] ?? false
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
