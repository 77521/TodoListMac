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
    
    /// 根据任务分类状态和本地分类数据动态计算显示的分类
    var displayCategories: [TDSliderBarModel] {
        var categories: [TDSliderBarModel] = []
        
        // 从 TDCategoryManager 获取本地分类数据
        let allCategories = TDCategoryManager.shared.loadLocalCategories()
        
        // 获取任务的分类ID
        let taskCategoryId = task.standbyInt1
        
        if taskCategoryId > 0 {
            // 任务有分类：第一个显示当前分类，后面两个显示其他分类
            if let currentCategory = allCategories.first(where: { $0.categoryId == taskCategoryId }) {
                categories.append(currentCategory)
            }
            
            // 添加其他分类（最多2个）
            let otherCategories = allCategories
                .filter { $0.categoryId > 0 && $0.categoryId != taskCategoryId }
                .prefix(2)
            categories.append(contentsOf: otherCategories)
        } else {
            // 任务无分类：显示前三个本地分类
            let firstThreeCategories = allCategories
                .filter { $0.categoryId > 0 }
                .prefix(3)
            categories.append(contentsOf: firstThreeCategories)
        }
        
        return Array(categories.prefix(3))
    }
    
    /// 是否显示更多分类按钮
    var shouldShowMoreCategories: Bool {
        let allCategories = TDCategoryManager.shared.loadLocalCategories()
        let taskCategoryId = task.standbyInt1
        
        if taskCategoryId > 0 {
            // 任务有分类：检查是否还有其他分类未显示
            let remainingCategories = allCategories.filter { category in
                category.categoryId > 0 &&
                !displayCategories.contains { $0.categoryId == category.categoryId }
            }
            return !remainingCategories.isEmpty
        } else {
            // 任务无分类：检查是否还有其他分类未显示
            let remainingCategories = allCategories.filter { category in
                category.categoryId > 0 &&
                !displayCategories.contains { $0.categoryId == category.categoryId }
            }
            return !remainingCategories.isEmpty
        }
    }
    
    /// 是否显示未分类标签
    var shouldShowUncategorized: Bool {
        let allCategories = TDCategoryManager.shared.loadLocalCategories()
        // 只有当本地没有分类数据，且任务也没有分类时才显示
        return allCategories.isEmpty && task.standbyInt1 <= 0
    }
    
    /// 获取可用分类列表（用于更多分类菜单）
    var availableCategories: [TDSliderBarModel] {
        let allCategories = TDCategoryManager.shared.loadLocalCategories()
        let taskCategoryId = task.standbyInt1
        
        if taskCategoryId > 0 {
            // 任务有分类：返回除了已显示的三个分类之外的所有分类
            return allCategories.filter { category in
                category.categoryId > 0 &&
                !displayCategories.contains { $0.categoryId == category.categoryId }
            }
        } else {
            // 任务无分类：返回除了已显示的三个分类之外的所有分类
            return allCategories.filter { category in
                category.categoryId > 0 &&
                !displayCategories.contains { $0.categoryId == category.categoryId }
            }
        }
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
