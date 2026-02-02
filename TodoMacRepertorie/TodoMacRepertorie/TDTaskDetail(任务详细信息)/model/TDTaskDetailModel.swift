//
//  TDTaskDetailModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI

/// 任务详情数据模型 - 处理任务详情的所有逻辑
@MainActor
class TDTaskDetailModel: ObservableObject {
    
    // MARK: - 属性
    @Published var task: TDMacSwiftDataListModel
    
    // MARK: - 初始化
    init(task: TDMacSwiftDataListModel) {
        self.task = task
    }
    
    // MARK: - 计算属性
    
    /// iOS 同步逻辑：顶部 3 个 + menu 数据（参照 `td_getTopDisplayAndMenuDatasWithPriorityCategoryId:`）
    private var topDisplayAndMenuData: (display: [TDSliderBarModel], menu: [TDSliderBarModel]) {
        let priorityCategoryId = task.standbyInt1
        
        // 只取服务器真实数据，并过滤已删除
        let all = TDCategoryManager.shared.loadLocalCategories()
        let server = all.filter { item in
            item.categoryId > 0 && (item.delete == false || item.delete == nil)
        }
        
        let folderDatas = server.filter { $0.folderIs == true }
        let categoryDatas = server.filter { $0.folderIs != true }
        
        var displayArray: [TDSliderBarModel] = []
        var selectedCategoryIds = Set<Int>()
        
        if priorityCategoryId > 0,
           let priorityModel = categoryDatas.first(where: { $0.categoryId == priorityCategoryId }) {
            displayArray.append(priorityModel)
            selectedCategoryIds.insert(priorityModel.categoryId)
        }
        
        let orderedMenuEntries = sortedMenuEntries(folders: folderDatas, categories: categoryDatas)
        for entry in orderedMenuEntries {
            if displayArray.count >= 3 { break }
            if entry.isFolder {
                for child in (entry.children ?? []) {
                    if displayArray.count >= 3 { break }
                    if selectedCategoryIds.contains(child.categoryId) { continue }
                    displayArray.append(child)
                    selectedCategoryIds.insert(child.categoryId)
                }
            } else {
                if selectedCategoryIds.contains(entry.categoryId) { continue }
                displayArray.append(entry)
                selectedCategoryIds.insert(entry.categoryId)
            }
        }
        
        let remainingCategories = categoryDatas.filter { !selectedCategoryIds.contains($0.categoryId) }
        let sortedMenuResult = sortedMenuEntries(folders: folderDatas, categories: remainingCategories)
        
        return (Array(displayArray.prefix(3)), sortedMenuResult)
    }
    
    private func sortedMenuEntries(folders: [TDSliderBarModel], categories: [TDSliderBarModel]) -> [TDSliderBarModel] {
        let combined = folders + categories
        let processed = TDCategoryManager.shared.getFolderWithSubCategories(from: combined)
        return processed.filter { item in
            if item.isFolder {
                return !(item.children ?? []).isEmpty
            }
            return true
        }
    }
    
    /// 顶部展示分类（最多 3 个）
    var displayCategories: [TDSliderBarModel] {
        topDisplayAndMenuData.display
    }
    
    /// menu 数据（已排除顶部 3 个；含 folder 结构）
    var menuEntries: [TDSliderBarModel] {
        topDisplayAndMenuData.menu
    }
    
    /// 是否显示更多分类按钮
    var shouldShowMoreCategories: Bool {
        for entry in menuEntries {
            if entry.isFolder {
                if !(entry.children ?? []).isEmpty { return true }
            } else {
                return true
            }
        }
        return false
    }
    
    /// 是否显示未分类标签
    var shouldShowUncategorized: Bool {
        let allCategories = TDCategoryManager.shared.loadLocalCategories()
        // 只有当本地没有分类数据，且任务也没有分类时才显示
        return allCategories.isEmpty && task.standbyInt1 <= 0
    }
    
    /// 获取可用分类列表（用于更多分类菜单）
    var availableCategories: [TDSliderBarModel] {
        // iOS 逻辑下：menuEntries 已经是“剩余分类 + 文件夹结构”
        // 这里为了兼容旧调用，只返回顶级分类（不展开 folder children）
        menuEntries.filter { !$0.isFolder }
    }

    /// 获取复选框颜色
    var checkboxColor: Color {
        if task.standbyInt1 > 0 {
            // 有选中分类：显示当前选中分类的颜色
            let allCategories = TDCategoryManager.shared.loadLocalCategories()
            if let category = allCategories.first(where: { $0.categoryId == task.standbyInt1 }) {
                return Color.fromHex(category.categoryColor ?? "#007AFF")
            }
        }
        
        // 没有选中分类：显示主题颜色描述颜色
        return TDThemeManager.shared.descriptionTextColor
    }
    
    // MARK: - 方法
    
    /// 处理分类标签点击
    func handleCategoryTap(_ category: TDSliderBarModel) {
        if category.categoryId == 0 {
            // 点击未分类标签
            if task.standbyInt1 == 0 {
                // 如果当前已经是未选中状态，则不做任何操作
                print("当前已经是未分类状态")
            } else {
                // 取消当前选中的分类
                task.standbyInt1 = 0
                task.standbyIntName = ""
                task.standbyIntColor = ""
                print("取消选中分类，设置为未分类")
            }
        } else {
            // 点击分类标签
            if task.standbyInt1 == category.categoryId {
                // 如果点击的是当前已选中的分类，则取消选中
                task.standbyInt1 = 0
                task.standbyIntName = ""
                task.standbyIntColor = ""
                print("取消选中分类: \(category.categoryName)")
            } else {
                // 选中新分类
                task.standbyInt1 = category.categoryId
                task.standbyIntName = category.categoryName
                task.standbyIntColor = category.categoryColor ?? "#007AFF"
                print("选中分类: \(category.categoryName)")
            }
        }
    }
    
    /// 处理分类修改（从Menu选择）
    func handleModifyCategory(category: TDSliderBarModel?) {
        if let category = category {
            // 如果点击的是当前已选中的分类，则取消选中
            if task.standbyInt1 == category.categoryId {
                // 取消分类
                task.standbyInt1 = 0
                task.standbyIntName = ""
                task.standbyIntColor = ""
                print("取消选中分类: \(category.categoryName), 选中状态: \(task.standbyInt1)")
            } else {
                // 选中新分类
                task.standbyInt1 = category.categoryId
                task.standbyIntName = category.categoryName
                task.standbyIntColor = category.categoryColor ?? "#007AFF"
                print("选中分类: \(category.categoryName), 选中状态: \(task.standbyInt1)")
            }
        } else {
            // 取消分类
            task.standbyInt1 = 0
            task.standbyIntName = ""
            task.standbyIntColor = ""
            print("取消分类, 选中状态: \(task.standbyInt1)")
        }
    }
    
    /// 切换任务完成状态
    func toggleTaskCompletion() {
        print("切换任务完成状态: \(task.taskContent)")
        task.complete.toggle()
    }
}
