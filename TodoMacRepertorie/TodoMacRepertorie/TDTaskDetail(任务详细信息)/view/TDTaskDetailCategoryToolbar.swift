//
//  TDTaskDetailCategoryToolbar.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData

/// 任务详情顶部分类工具栏组件
struct TDTaskDetailCategoryToolbar: View {
    @Bindable var task: TDMacSwiftDataListModel
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    
    // 计算属性：根据任务分类状态和本地分类数据动态计算显示的分类
    private var displayCategories: [TDSliderBarModel] {
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
    
    // 计算属性：是否显示更多分类按钮
    private var shouldShowMoreCategories: Bool {
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
    
    // 计算属性：是否显示未分类标签
    private var shouldShowUncategorized: Bool {
        let allCategories = TDCategoryManager.shared.loadLocalCategories()
        // 只有当本地没有分类数据，且任务也没有分类时才显示
        return allCategories.isEmpty && task.standbyInt1 <= 0
    }
    
    // 计算属性：获取可用分类列表（用于更多分类菜单）
    private var availableCategories: [TDSliderBarModel] {
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
    
    // 计算属性：获取复选框颜色
    private var checkboxColor: Color {
        if task.standbyInt1 > 0 {
            // 有选中分类：显示当前选中分类的颜色
            let allCategories = TDCategoryManager.shared.loadLocalCategories()
            if let category = allCategories.first(where: { $0.categoryId == task.standbyInt1 }) {
                return Color.fromHex(category.categoryColor ?? "#007AFF")
            }
        }
        
        // 没有选中分类：显示主题颜色描述颜色
        return themeManager.descriptionTextColor
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // 动态分类标签
            ForEach(displayCategories, id: \.categoryId) { category in
                CategoryTagView(
                    category: category,
                    isSelected: task.standbyInt1 == category.categoryId, // 根据任务实际分类状态判断
                    onTap: {
                        handleModifyCategory(category: category)
                    }
                )
            }
            
            // 未分类标签（当任务没有分类且本地没有分类数据时显示）
            if shouldShowUncategorized {
                CategoryTagView(
                    category: TDSliderBarModel.uncategorized,
                    isSelected: task.standbyInt1 == 0, // Selected if no category is chosen
                    onTap: {
                        handleModifyCategory(category: TDSliderBarModel.uncategorized)
                    }
                )
            }
            
            // 下拉箭头（只有本地有分类数据时才显示）
            if shouldShowMoreCategories {
                Menu {
                    // MARK: - 新建分类选项
                    Button(action: {
                        // TODO: 实现新建分类功能
                        print("新建分类")
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(themeManager.color(level: 5))
                                .font(.system(size: 14))
                            Text("new_category".localized)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // MARK: - 不分类选项
                    Button(action: {
                        handleModifyCategory(category: nil)
                    }) {
                        HStack {
                            Image(systemName: "circle")
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                            Text("uncategorized".localized)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // MARK: - 现有分类列表（过滤掉外面已显示的分类）
                    if !availableCategories.isEmpty {
                        Divider()
                        
                        ForEach(availableCategories, id: \.categoryId) { category in
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
                        }
                    }
                } label: {
                    Text("选择分类")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.descriptionTextColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.secondaryBackgroundColor)
                        )
                }
                .menuStyle(.button)
                .frame(width: 80)
            }
            
            Spacer()
            
            // 复选框
            Button(action: {
                // 切换任务完成状态
                toggleTaskCompletion()
            }) {
                Image(systemName: task.complete ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundColor(checkboxColor)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.controlBackgroundColor))
        .onAppear {
            initializeSelectedState()
        }

    }
    
    // MARK: - 私有方法
    
    /// 处理分类修改
    private func handleModifyCategory(category: TDSliderBarModel?) {
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
    private func toggleTaskCompletion() {
        print("切换任务完成状态: \(task.taskContent)")
        // 直接修改 task 属性，由于使用 @Bindable，会自动同步到第二列
        task.complete.toggle()
    }
    
    /// 初始化选中状态
    private func initializeSelectedState() {
        // 根据任务的当前分类设置显示状态
        let taskCategoryId = task.standbyInt1
        
        // 打印当前任务的分类状态，用于调试
        if taskCategoryId > 0 {
            print("初始化显示状态: 任务有分类，分类ID = \(taskCategoryId)")
        } else {
            print("初始化显示状态: 任务无分类")
        }
    }
}

// MARK: - 辅助视图

/// 分类标签视图
private struct CategoryTagView: View {
    let category: TDSliderBarModel
    let isSelected: Bool
    let onTap: () -> Void
    
    @EnvironmentObject private var themeManager: TDThemeManager
    
    var body: some View {
        Button(action: onTap) {
            Text(category.categoryName)
                .font(.system(size: 12))
                .foregroundColor(getTextColor())
                .padding(.horizontal, 10) // 增加左右间距到10pt
                .padding(.vertical, 6)    // 增加上下间距到6pt
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(getBackgroundColor())
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 获取背景色
    private func getBackgroundColor() -> Color {
        if isSelected {
            // 选中的时候背景色使用当前分类的颜色
            return Color.fromHex(category.categoryColor ?? "#007AFF")
        } else {
            // 未选中的时候背景色使用主题颜色二级背景色
            return themeManager.secondaryBackgroundColor
        }
    }
    
    // 获取字体颜色
    private func getTextColor() -> Color {
        if isSelected {
            // 选中的时候字体颜色改为白色
            return .white
        } else {
            // 未选中的时候字体颜色使用主题颜色描述颜色
            return themeManager.descriptionTextColor
        }
    }
}

#Preview {
    TDTaskDetailCategoryToolbar(task: TDMacSwiftDataListModel(
        id: 1,
        taskId: "preview_task",
        taskContent: "预览任务",
        taskDescribe: "这是一个预览任务",
        complete: false,
        createTime: Date().startOfDayTimestamp,
        delete: false,
        reminderTime: 0,
        snowAdd: 0,
        snowAssess: 0,
        standbyInt1: 1, // 分类ID，在事件内使用standbyInt1
        standbyStr1: nil,
        standbyStr2: nil,
        standbyStr3: nil,
        standbyStr4: nil,
        syncTime: Date().startOfDayTimestamp,
        taskSort: Decimal(1),
        todoTime: Date().startOfDayTimestamp,
        userId: 1,
        version: 1,
        status: "sync",
        isSubOpen: true,
        standbyIntColor: "",
        standbyIntName: "",
        reminderTimeString: "",
        subTaskList: [],
        attachmentList: []
    ))
    .environmentObject(TDThemeManager.shared)
}
