//
//  TDMacSelectMenu.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI

/// 分类选择菜单组件 - 用于多选模式下修改任务的分类
/// 包含：新建分类、设置为未分类、选择现有分类等功能
struct TDMacSelectMenu: View {
    // 主题管理器 - 用于获取颜色和样式
    @EnvironmentObject private var themeManager: TDThemeManager
    // SwiftData 上下文 - 用于数据库操作
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - 传入的参数
    /// 选中的任务数组 - 需要修改分类的任务列表
    let selectedTasks: [TDMacSwiftDataListModel]
    /// 分类选择完成后的回调函数 - 用于通知外部分类修改已完成
    let onCategorySelected: () -> Void
    /// 新建分类的回调函数 - 用于处理新建分类的逻辑
    let onNewCategory: () -> Void
    
    var body: some View {
        // 修改分类菜单 - 包含新建、未分类、现有分类等选项
        Menu("modify_category".localized) {
            // MARK: - 新建分类选项
            Button(action: onNewCategory) {
                HStack {
                    // 新建图标 - 使用系统图标
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(themeManager.color(level: 5))
                        .font(.system(size: 14))
                    Text("new_category".localized)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()

            // 不分类选项
            Button(action: {
                handleModifyCategory(category: nil)
            }) {
                HStack {
                    // 不分类图标 - 使用系统图标
                    Image(systemName: "circle")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                    Text("uncategorized".localized)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()

            // 只有当有分类数据时才显示分割线和分类列表
            let categories = TDCategoryManager.shared.loadLocalCategories()
            if !categories.isEmpty {
                Divider()
                
                // 现有分类列表
                ForEach(categories, id: \.categoryId) { category in
                    Button(action: {
                        handleModifyCategory(category: category)
                    }) {
                        HStack {
                            Image.fromHexColor(category.categoryColor ?? "#c3c3c3", width: 14, height: 14, cornerRadius: 7.0)
                                .resizable()
                                .frame(width: 14.0, height: 14.0)
                            
                            Text(String(category.categoryName.prefix(8)))
                                .font(.system(size: 12))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                }
            }
        }
    }
    
    /// 修改选中任务的分类
    /// - Parameter category: 分类数据，nil表示未分类
    private func handleModifyCategory(category: TDSliderBarModel?) {
        let categoryId = category?.categoryId ?? 0
        print("🏷️ 开始修改分类，目标分类ID: \(categoryId)，选中任务数量: \(selectedTasks.count)")
        
        Task {
            do {
                for task in selectedTasks {
                    // 如果任务已经是目标分类，则跳过
                    if task.standbyInt1 == categoryId {
                        print("⏭️ 跳过已为目标分类的任务，taskId: \(task.taskId), 当前分类: \(task.standbyInt1)")
                        continue
                    }
                    
                    let updatedTask = task
                    
                    if categoryId == 0 {
                        // 设置为未分类
                        updatedTask.standbyInt1 = 0
                        updatedTask.standbyIntColor = TDThemeManager.shared.borderColor.toHexString()
                        updatedTask.standbyIntName = "uncategorized".localized
                        print("📝 设置任务为未分类，taskId: \(task.taskId)")
                    } else {
                        // 设置为指定分类 - 直接使用传入的分类数据
                        if let category = category {
                            updatedTask.standbyInt1 = category.categoryId
                            updatedTask.standbyIntColor = category.categoryColor ?? "#c3c3c3"
                            updatedTask.standbyIntName = category.categoryName
                            print("📝 设置任务分类为: \(category.categoryName)，taskId: \(task.taskId)")
                        }
                    }
                    
                    // 更新本地数据
                    let queryManager = TDQueryConditionManager()
                    let result = try await queryManager.updateLocalTaskWithModel(
                        updatedTask: updatedTask,
                        context: modelContext
                    )
                    
                    print("✅ 成功更新任务分类，taskId: \(task.taskId), 结果: \(result)")
                }
                // 调用回调函数
                await MainActor.run {
                    onCategorySelected()
                }
                
                // 同步数据
                await TDMainViewModel.shared.performSyncSeparately()
                
                
                print("✅ 修改分类完成，共处理 \(selectedTasks.count) 个任务")
                
            } catch {
                print("❌ 修改分类失败: \(error)")
            }
        }
    }
}
