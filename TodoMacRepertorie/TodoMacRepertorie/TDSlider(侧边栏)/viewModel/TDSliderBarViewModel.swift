//
//  TDSliderBarViewModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import Foundation
import SwiftUI

import OSLog

// MARK: - 标签排序方式
enum TDTagSortOption: String, CaseIterable, Codable {
    case time
    case count
}


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
            // 同步更新分类清单过滤缓存，避免 View 渲染时重复 filter
            filteredCategoryListItems = items.filter {
                $0.categoryId >= -1 && $0.categoryId != -2000 && $0.categoryId != -2001
            }
        }
    }
    
    /// 最近一次从本地/网络加载到的“服务器分类清单原始数据”（仅 categoryId > 0）
    /// 说明：侧滑栏展示会基于该数组做分组（文件夹 children），但拖拽排序/归属变更应回写到这份源数据再重建 items。
    @Published private(set) var categorySource: [TDSliderBarModel] = []
    

    /// 选中的分类
    @Published var selectedCategory: TDSliderBarModel? {
        didSet {
            if let category = selectedCategory,
               oldValue?.categoryId != category.categoryId {  // 只有当分类真正改变时才处理
                // 选择分类时：清空标签选中态（区分“点标签”和“点分类”）
                selectedTagKey = nil
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
    /// 标签排序方式（默认：按时间，切换时自动重建排序缓存）
    @Published var tagSortOption: TDTagSortOption = .time {
        didSet { rebuildSortedTags() }
    }
    

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
    
    /// 标签原始数组（变化时自动重建排序缓存）
    @Published var tagsArr: [TDSliderBarModel] = [] {
        didSet { rebuildSortedTags() }
    }
    /// 当前选中的标签（仅针对具体标签；“所有标签”不参与选中态）
    @Published var selectedTagKey: String? = nil

    // MARK: - 渲染层缓存（避免每次 View 渲染都重复 sort/filter）

    /// 排序后的标签数组（@Published 缓存，避免每帧重新排序）
    /// 由 tagsArr / tagSortOption 变化时统一重建，View 直接绑定此属性
    @Published private(set) var sortedTagsArr: [TDSliderBarModel] = []

    /// 分类清单展示项缓存（过滤掉 -2000/-2001 特殊占位项）
    /// 由 items 变化时统一重建
    @Published private(set) var filteredCategoryListItems: [TDSliderBarModel] = []

    /// 文件夹展开状态字典（key: folderId, value: 是否展开）
    @Published var folderExpandedStates: [Int: Bool] = [:]

    // MARK: - 分类清单拖拽（用于“拖动过程只更新 UI，落下时再同步/落盘”）
    private var categoryDragBaseline: [TDSliderBarModel]? = nil

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
        // 立即加载本地标签索引（保证“所有标签”永远存在）
        loadLocalTags()

        logger.info("📱 侧边栏ViewModel初始化完成")
    }

    // MARK: - 渲染缓存重建

    /// 重建标签排序缓存
    /// 仅在 tagsArr / tagSortOption 变化时调用，避免每帧重复排序
    private func rebuildSortedTags() {
        // "所有标签"项永远排第一，不参与排序
        let allItem = tagsArr.first(where: { $0.categoryId == TDSliderBarModel.allTags.categoryId })
        let others = tagsArr.filter { $0.categoryId != TDSliderBarModel.allTags.categoryId }

        let sorted: [TDSliderBarModel]
        switch tagSortOption {
        case .time:
            // 按创建时间倒序，时间相同则按名称升序
            sorted = others.sorted {
                let t1 = $0.createTime ?? 0
                let t2 = $1.createTime ?? 0
                if t1 != t2 { return t1 > t2 }
                return $0.categoryName < $1.categoryName
            }
        case .count:
            // 按未完成数量倒序，数量相同则按名称升序
            sorted = others.sorted {
                let c1 = $0.unfinishedCount ?? 0
                let c2 = $1.unfinishedCount ?? 0
                if c1 != c2 { return c1 > c2 }
                return $0.categoryName < $1.categoryName
            }
        }
        sortedTagsArr = allItem.map { [$0] + sorted } ?? sorted
    }

    // MARK: - 公共方法

    /// 选择分类 - 极简版本
    func selectCategory(_ category: TDSliderBarModel) {
        logger.info("🎯 用户选择分类: \(category.categoryName) (ID: \(category.categoryId))")        
        // 使用 Task 来避免在 View 更新过程中修改 @Published 属性
        Task { @MainActor in
            // 点分类：退出标签模式
            selectedTagKey = nil

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
        // 同步完成后，刷新一次标签索引展示
        loadLocalTags()

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
    
    /// 点击标签（侧滑栏）
    /// - 规则：
    ///   - 点击“所有标签”：只弹窗，不改变选中态
    ///   - 点击其他标签：更新选中态，并取消所有分类选中（第二栏切到“标签模式”）
    func handleTagTap(_ tag: TDSliderBarModel) {
        if tag.tagKey == TDSliderBarModel.allTags.tagKey {
            showTagFilterSheet()
            return
        }
        if let key = tag.tagKey, !key.isEmpty {
            clearAllCategorySelections()
            selectedCategory = nil
            selectedTagKey = key
            TDMainViewModel.shared.selectTag(tagKey: key)
        }
    }
    
    /// 标签弹窗里点击某个标签（非“所有标签”）
    /// - 需求：行为要与侧滑栏点击普通标签一致，并且点击后弹窗关闭
    /// - 注意：关闭弹窗由 View 层控制（isPresented=false），这里仅处理“选中标签”的业务逻辑
    @MainActor
    func selectTagFromSheet(tagKey: String) {
        let key = tagKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        clearAllCategorySelections()
        selectedCategory = nil
        selectedTagKey = key
        TDMainViewModel.shared.selectTag(tagKey: key)
    }

    
    /// 清空侧滑栏所有分类项的选中态（含子分类）
    private func clearAllCategorySelections() {
        var updated = items
        var changed = false
        for i in 0..<updated.count {
            if updated[i].isSelect == true {
                updated[i].isSelect = false
                changed = true
            }
            if var children = updated[i].children {
                var childrenChanged = false
                for j in 0..<children.count {
                    if children[j].isSelect == true {
                        children[j].isSelect = false
                        childrenChanged = true
                    }
                }
                if childrenChanged {
                    updated[i].children = children
                    changed = true
                }
            }
        }
        if changed {
            items = updated
        }
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

    /// 加载本地标签索引（来自 SwiftData：TDTagModel）
    /// - 约定：tagsArr 第一个永远是 “所有标签”
    private func loadLocalTags() {
        let context = TDModelContainer.shared.mainContext
        let tags = TDTagManager.shared.fetchAllTags(context: context)

        // 映射为侧边栏展示模型
        var result: [TDSliderBarModel] = [TDSliderBarModel.allTags]
        result.reserveCapacity(1 + tags.count)
        for tag in tags {
            // 使用稳定的负数 id（仅用于 UI 列表区分；业务筛选请用 tagKey/display）
            let id = TDTagManager.shared.stableSidebarId(for: tag.key)
            result.append(
                TDSliderBarModel(
                    categoryId: id,
                    categoryName: tag.display,
                    headerIcon: "tag",
                    createTime: tag.createTime,
                    unfinishedCount: tag.taskCount,
                    tagKey: tag.key
                )
            )
        }

        tagsArr = result
    }


    /// 更新分类列表数据
    private func updateCategoryItems(_ categories: [TDSliderBarModel]) {
        logger.debug("🔄 更新分类列表数据")
        // 仅保留服务器真实数据（正数 id）；避免本地加载失败回退 defaultItems 时污染
        categorySource = categories.filter { $0.categoryId > 0 }

        // 合并系统默认分类和用户创建的分类
        var newItems = TDSliderBarModel.defaultItems(settingManager: TDSettingManager.shared)

        // 在分类清单后插入用户创建的分类
        // 在分类清单后插入用户创建的分类
        if let categoryListIndex = newItems.firstIndex(where: { $0.categoryId == -104 }) {
            // 使用新的逻辑处理分类清单数据（按照 iOS 逻辑）
            let processedCategories = TDCategoryManager.shared.getFolderWithSubCategories(from: categorySource)
            
            // 文件夹默认展开：
            // - 只对“未曾设置过状态”的文件夹补默认值 true
            // - 清理已不存在的 folder 状态，避免字典无限增长
            let currentFolderIds = Set(processedCategories.filter { $0.isFolder }.map(\.categoryId))
            folderExpandedStates = folderExpandedStates.filter { currentFolderIds.contains($0.key) }
            for fid in currentFolderIds where folderExpandedStates[fid] == nil {
                folderExpandedStates[fid] = true
            }

            // 创建包含"未分类"的完整分类列表
            var fullCategories = [TDSliderBarModel.uncategorized] // 第一项永远是"未分类"
            fullCategories.append(contentsOf: processedCategories) // 后面是处理后的分类（包含文件夹和子分类）

            newItems.insert(contentsOf: fullCategories, at: categoryListIndex + 1)
        }
        

        
        // 保持选中状态
        if let selectedId = selectedCategory?.categoryId {
            for i in 0..<newItems.count {
                // 顶级项选中
                newItems[i].isSelect = newItems[i].categoryId == selectedId

                // 子分类选中（关键：分类清单的子项在 children 里）
                if var children = newItems[i].children {
                    var changed = false
                    for j in 0..<children.count {
                        let shouldSelect = children[j].categoryId == selectedId
                        if children[j].isSelect != shouldSelect {
                            children[j].isSelect = shouldSelect
                            changed = true
                        }
                    }
                    if changed {
                        newItems[i].children = children
                    }
                }
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
    
//    /// 获取文件夹是否展开
//    func isFolderExpanded(folderId: Int) -> Bool {
//        return folderExpandedStates[folderId] ?? false
//    }

    
    // MARK: - 分类清单：拖拽排序/归属变更

    /// 开始一次分类清单拖拽（只会记录一次 baseline）
    func beginCategoryListDragIfNeeded() {
        if categoryDragBaseline == nil {
            categoryDragBaseline = categorySource
        }
    }

    /// 结束拖拽：将当前 categorySource 与 baseline 做 diff，同步到本地与服务器
    func commitCategoryListDrag() async {
        guard let baseline = categoryDragBaseline else { return }
        categoryDragBaseline = nil

        // 1) 先落盘（主程序/小组件共用）
        await TDCategoryManager.shared.saveCategories(categorySource)

        // 2) diff 并同步到服务器（仅同步变化项）
        let beforeById = Dictionary(uniqueKeysWithValues: baseline.map { ($0.categoryId, $0) })
        let afterById = Dictionary(uniqueKeysWithValues: categorySource.map { ($0.categoryId, $0) })

        var changedFolderId: [(id: Int, folderId: Int)] = []
        var changedSort: [(id: Int, sort: Double)] = []

        for (id, after) in afterById {
            guard let before = beforeById[id] else { continue }
            let beforeFolder = before.folderId ?? 0
            let afterFolder = after.folderId ?? 0
            if beforeFolder != afterFolder {
                changedFolderId.append((id: id, folderId: afterFolder))
            }
            let beforeSort = before.listSort ?? 0
            let afterSort = after.listSort ?? 0
            if beforeSort != afterSort {
                changedSort.append((id: id, sort: afterSort))
            }
        }

        do {
            // 先同步 folderId（归属）——需要后端落到正确分组
            for change in changedFolderId {
                // 只对“分类清单”更新 folderId；文件夹本身不应该有 folderId
                guard let item = afterById[change.id] else { continue }
                // 理论上分类清单一定有颜色；如果缺失则跳过避免把空值写回服务器
                guard let color = item.categoryColor else { continue }
                try await TDCategoryAPI.shared.updateCategoryInfo(
                    categoryId: change.id,
                    name: item.categoryName,
                    color: color,
                    isFolder: nil,
                    folderId: change.folderId
                )
            }

            // 再同步排序
            for change in changedSort {
                try await TDCategoryAPI.shared.updateCategorySort(categoryId: change.id, newSort: change.sort)
            }

            // 刷新一次服务器数据，保证本地与服务端一致
            let serverCategories = try await TDCategoryAPI.shared.getCategoryList()
            await TDCategoryManager.shared.saveCategories(serverCategories)
            updateCategories(serverCategories)
        } catch {
            // 同步失败不影响本地顺序；提示即可
            let message: String
            if let netError = error as? TDNetworkError {
                message = netError.errorMessage
            } else {
                message = error.localizedDescription
            }
            TDToastCenter.shared.show(message, type: .error, position: .bottom)
        }
    }

    /// 拖拽过程中：将 dragged 移动到 destination 位置（实时更新 UI，不做网络同步）
    func hoverMoveCategoryListItem(draggedId: Int, destinationId: Int) {
        guard draggedId > 0, draggedId != destinationId else { return }
        guard let dragged = categorySource.first(where: { $0.categoryId == draggedId }) else { return }

        // destinationId == 0 表示“未分类”占位：把 dragged 放到顶级列表最前（UI 上仍在“未分类”下方）
        if destinationId == 0 {
            applyMove(
                dragged: dragged,
                destination: nil,
                dropIntoFolderId: nil,
                insertAtTopOfTopLevel: true
            )
            return
        }

        guard let destination = categorySource.first(where: { $0.categoryId == destinationId }) else { return }

        // 如果目标是文件夹，hover 阶段不做“放入文件夹”的动作（由 performDrop 决定）
        if destination.isFolder, !dragged.isFolder {
            return
        }

        applyMove(dragged: dragged, destination: destination, dropIntoFolderId: nil, insertAtTopOfTopLevel: false)
    }

    /// 落到文件夹行：把 dragged 分类放到该文件夹底部（实时更新 UI，不做网络同步）
    func dropCategoryIntoFolder(draggedId: Int, folderId: Int) {
        guard draggedId > 0 else { return }
        guard let dragged = categorySource.first(where: { $0.categoryId == draggedId }) else { return }
        guard !dragged.isFolder else { return }
        guard categorySource.contains(where: { $0.categoryId == folderId && $0.isFolder }) else { return }

        applyMove(dragged: dragged, destination: nil, dropIntoFolderId: folderId, insertAtTopOfTopLevel: false)
    }

    // MARK: - 内部：移动与重排（不触发网络）

    private enum _Location: Equatable {
        case topLevel
        case folderChild(folderId: Int)
    }

    private func location(for item: TDSliderBarModel, folderIds: Set<Int>) -> _Location {
        if item.isFolder { return .topLevel }
        let fid = item.folderId ?? 0
        if fid > 0, folderIds.contains(fid) {
            return .folderChild(folderId: fid)
        }
        return .topLevel
    }

    private func applyMove(
        dragged: TDSliderBarModel,
        destination: TDSliderBarModel?,
        dropIntoFolderId: Int?,
        insertAtTopOfTopLevel: Bool
    ) {
        var updated = categorySource
        let folderIds = Set(updated.filter { $0.isFolder }.map(\.categoryId))

        guard let draggedIndex = updated.firstIndex(where: { $0.categoryId == dragged.categoryId }) else { return }

        let fromLoc = location(for: dragged, folderIds: folderIds)

        // 计算目标位置
        let toLoc: _Location
        if let dropIntoFolderId {
            toLoc = .folderChild(folderId: dropIntoFolderId)
        } else if let destination {
            // 目标是子分类：进入目标的 folder；目标是顶级：进入顶级
            if destination.isFolder {
                toLoc = .topLevel
            } else {
                toLoc = location(for: destination, folderIds: folderIds)
            }
        } else {
            toLoc = .topLevel
        }

        // 不允许文件夹进入文件夹（也不允许把文件夹当作子分类）
        if dragged.isFolder, case .folderChild = toLoc {
            return
        }

        // 更新 dragged 的 folderId（仅分类清单需要）
        var newDragged = updated[draggedIndex]
        switch toLoc {
        case .topLevel:
            if !newDragged.isFolder {
                newDragged.folderId = 0
            }
        case .folderChild(let folderId):
            if !newDragged.isFolder {
                newDragged.folderId = folderId
            }
        }
        updated[draggedIndex] = newDragged

        // 构建 topLevel/children 序列（使用 id）
        func topLevelIds(_ arr: [TDSliderBarModel]) -> [Int] {
            let folderIds = Set(arr.filter { $0.isFolder }.map(\.categoryId))
            return arr
                .filter { item in
                    if item.isFolder { return true }
                    let fid = item.folderId ?? 0
                    if fid == 0 { return true }
                    return !folderIds.contains(fid)
                }
                .sorted { ($0.listSort ?? 0) < ($1.listSort ?? 0) }
                .map(\.categoryId)
        }

        func childIds(folderId: Int, _ arr: [TDSliderBarModel]) -> [Int] {
            return arr
                .filter { !$0.isFolder && (($0.folderId ?? 0) == folderId) }
                .sorted { ($0.listSort ?? 0) < ($1.listSort ?? 0) }
                .map(\.categoryId)
        }

        // 1) 先算当前序列
        var topIds = topLevelIds(updated)
        var folderToChildIds: [Int: [Int]] = [:]
        for fid in folderIds {
            folderToChildIds[fid] = childIds(folderId: fid, updated)
        }

        // 2) 执行移动
        if case .topLevel = fromLoc {
            topIds.removeAll(where: { $0 == dragged.categoryId })
        } else if case .folderChild(let fid) = fromLoc {
            folderToChildIds[fid, default: []].removeAll(where: { $0 == dragged.categoryId })
        }

        if let dropIntoFolderId {
            // 放入文件夹：默认末尾
            folderToChildIds[dropIntoFolderId, default: []].append(dragged.categoryId)
        } else if let destination, destination.isFolder, !dragged.isFolder {
            // hover 阶段已经拦截，理论不会走到这里
        } else if let destination {
            if dragged.isFolder {
                // 文件夹：始终在顶级序列移动；若目标是子分类，则用其父文件夹作为锚点
                let anchorId: Int
                if destination.isFolder {
                    anchorId = destination.categoryId
                } else {
                    let destFid = destination.folderId ?? 0
                    anchorId = (destFid > 0 && folderIds.contains(destFid)) ? destFid : destination.categoryId
                }
                let destIndex = topIds.firstIndex(of: anchorId) ?? topIds.endIndex
                topIds.insert(dragged.categoryId, at: destIndex)
            } else {
                // 分类：根据目标所在位置插入
                switch location(for: destination, folderIds: folderIds) {
                case .topLevel:
                    let destIndex = topIds.firstIndex(of: destination.categoryId) ?? topIds.endIndex
                    topIds.insert(dragged.categoryId, at: destIndex)
                case .folderChild(let fid):
                    let destIndex = folderToChildIds[fid, default: []].firstIndex(of: destination.categoryId) ?? folderToChildIds[fid, default: []].endIndex
                    folderToChildIds[fid, default: []].insert(dragged.categoryId, at: destIndex)
                }
            }
        } else if insertAtTopOfTopLevel {
            topIds.insert(dragged.categoryId, at: 0)
        }

        // 3) 只计算“被拖动项”的 listSort（按 iOS 逻辑，不重置其他项）
        func sortValue(for id: Int) -> Double {
            updated.first(where: { $0.categoryId == id })?.listSort ?? 0
        }

        func computeNewSort(in ids: [Int], movedId: Int) -> Double? {
            guard let idx = ids.firstIndex(of: movedId) else { return nil }
            // 只有自己一个：给个 0（后续再移动会继续按规则生成）
            if ids.count == 1 { return 0 }

            if idx == 0 {
                // 移动到最顶端：取“下一个”的排序值 / 2
                let nextId = ids[1]
                let nextSort = sortValue(for: nextId)
                return nextSort / 2.0
            }

            if idx == ids.count - 1 {
                // 移动到最后：取“上一个”的排序值 + 100
                let prevId = ids[ids.count - 2]
                let prevSort = sortValue(for: prevId)
                return prevSort + 100.0
            }

            // 中间：取上下两个排序值相加 / 2
            let prevId = ids[idx - 1]
            let nextId = ids[idx + 1]
            let prevSort = sortValue(for: prevId)
            let nextSort = sortValue(for: nextId)
            return (prevSort + nextSort) / 2.0
        }

        if let newSort = computeNewSort(in: topIds, movedId: dragged.categoryId),
           let i = updated.firstIndex(where: { $0.categoryId == dragged.categoryId }) {
            updated[i].listSort = newSort
        } else {
            // 可能是移动到了某个文件夹的 children
            for (_, ids) in folderToChildIds {
                if ids.contains(dragged.categoryId),
                   let newSort = computeNewSort(in: ids, movedId: dragged.categoryId),
                   let i = updated.firstIndex(where: { $0.categoryId == dragged.categoryId }) {
                    updated[i].listSort = newSort
                    // 只会出现在一个序列里，算到就停
                    break
                }
            }
        }



        // 4) 写回并重建 items（UI 即时生效）
        // 拖拽过程中频繁触发，使用短动画让行平滑平移
        withAnimation(.easeInOut(duration: 0.12)) {
            categorySource = updated
            updateCategoryItems(updated)
        }
    }

    
    /// 获取文件夹是否展开
    func isFolderExpanded(folderId: Int) -> Bool {
        // 默认展开：如果从未设置过状态，则视为展开
        return folderExpandedStates[folderId] ?? true
    }

    /// 拖拽文件夹开始时：如果文件夹当前展开，则收起
    func collapseFolderIfExpanded(folderId: Int) {
        guard isFolderExpanded(folderId: folderId) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            folderExpandedStates[folderId] = false
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
