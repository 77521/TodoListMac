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
    @ObservedObject private var sliderViewModel = TDSliderBarViewModel.shared

    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        // 单一来源：直接复用 TDTaskDetailModel 内的 iOS 逻辑
        let detailModel = TDTaskDetailModel(task: task)
        
        HStack(spacing: 8) {
            // 动态分类标签
            ForEach(detailModel.displayCategories, id: \.categoryId) { category in
                CategoryTagView(
                    category: category,
                    isSelected: task.standbyInt1 == category.categoryId, // 根据任务实际分类状态判断
                    onTap: {
                        detailModel.handleModifyCategory(category: category)
                    }
                )
            }
            
            // 未分类标签（当任务没有分类且本地没有分类数据时显示）
            if detailModel.shouldShowUncategorized {
                CategoryTagView(
                    category: TDSliderBarModel.uncategorized,
                    isSelected: task.standbyInt1 == 0, // Selected if no category is chosen
                    onTap: {
                        detailModel.handleModifyCategory(category: nil)
                    }
                )
            }
            
            // 下拉箭头（只有本地有分类数据时才显示）
            if detailModel.shouldShowMoreCategories {
                Menu {
                    // MARK: - 新建分类选项
                    Button {
                       sliderViewModel.showAddCategorySheet()
                    } label: {
                        menuRow(icon: createIcon, title: "new_category".localized)
                    }

                    // MARK: - 不分类选项
                    Button {
                        detailModel.handleModifyCategory(category: nil)
                    } label: {
                        menuRow(icon: uncategorizedIcon, title: "uncategorized".localized)
                    }


                    // MARK: - 现有分类列表（iOS 逻辑：排除顶部 3 个，并保留文件夹结构）
                    if !detailModel.menuEntries.isEmpty {
                        Divider()
                        
                        ForEach(detailModel.menuEntries, id: \.categoryId) { entry in
                            if entry.isFolder, let children = entry.children, !children.isEmpty {
                                Menu {
                                    ForEach(children, id: \.categoryId) { child in
                                        
                                        Button {
                                            // 子分类：回调返回模型数据
                                            detailModel.handleModifyCategory(category: child)
                                        } label: {
                                            menuRow(
                                                icon: categoryIcon(hex: child.categoryColor),
                                                title: String(child.categoryName.prefix(8))
                                            )
                                        }
                                    }
                                } label: {
                                    menuRow(
                                        icon: folderIcon(folderColor: entry.categoryColor),
                                        title: entry.categoryName
                                    )

                                    
                                }
                            } else {
                                Button {
                                    // 顶级分类：回调返回模型数据
                                    detailModel.handleModifyCategory(category: entry)
                                } label: {
                                    menuRow(
                                        icon: categoryIcon(hex: entry.categoryColor),
                                        title: String(entry.categoryName.prefix(8))
                                    )
                                }

                            }
                        }
                    }
                } label: {
//                    Image.fromSystemName("arrow/*triangle.down.fill", hexColor: themeManager.color(level: 5).toHexString(), size: TDAppConfig.menuIconSize)*/
                    
                    // 倒三角 + 圆形背景（对齐 iOS 样式）
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(themeManager.color(level: 5))
                        .frame(width: 25, height: 25)
                        .background(
                            Circle()
                                .fill(themeManager.secondaryBackgroundColor)
                        )

                    
                }
                .menuStyle(.button)
                .menuIndicator(.hidden)
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
            }
            
            Spacer()
            
            // 复选框
            Button(action: {
                // 切换任务完成状态
                toggleTaskCompletion()
            }) {
                Image(systemName: task.complete ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundColor(detailModel.checkboxColor)
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
            
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.controlBackgroundColor))
        .onAppear {
            initializeSelectedState()
        }
        
    }
    
    /// 新建：实心圆 + 加号
    private var createIcon: some View {
        // 使用"可着色的实心圆 + 加号"图片（避免在 Menu 内渲染风格不一致/丢色）
        Image.fromPlusCircleColor(themeManager.color(level: 5), width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize, plusSize: 6, plusWidth: 1.5)
            .resizable()
            .frame(width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize)
    }

    /// 未分类：空心圆
    private var uncategorizedIcon: some View {
        // 使用"可着色的空心圆图标"（避免 stroke 在 Menu 内渲染风格不一致）
        Image.fromCircleColor(themeManager.color(level: 5), width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize, lineWidth: 1.2)
            .resizable()
            .frame(width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize)
    }

    /// 菜单行：左侧图标 + 右侧标题
    private func menuRow(icon: some View, title: String) -> some View {
        HStack(spacing: 8) {
            icon
            Text(title)
                .font(.system(size: TDAppConfig.menuFontSize))
        }
    }
    /// 分类（非文件夹）：按你给的样式显示
    /// - 左侧：用颜色生成的小方块（圆角=7，视觉上是圆形）
    /// - 右侧：名称最多展示 8 个字符
    private func categoryIcon(hex: String?) -> some View {
        Image.fromHexColor(hex ?? "#c3c3c3", width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize, cornerRadius: 7.0)
            .resizable()
            .frame(width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize)
    }
    
    /// 文件夹图标：有颜色则使用"带颜色的文件夹图标"，否则使用主题色
    private func folderIcon(folderColor: String?) -> some View {
        Group {
            if let folderColor, !folderColor.isEmpty {
                // 使用带颜色的文件夹图标
                Image.fromSystemName("folder.fill", hexColor: folderColor, size: TDAppConfig.menuIconSize)
            } else {
                // 使用默认文件夹图标（主题色）
                Image(systemName: "folder.fill")
                    .foregroundColor(themeManager.color(level: 5))
                    .font(.system(size: TDAppConfig.menuIconSize))
            }
        }
        .frame(width: TDAppConfig.menuIconSize, height: TDAppConfig.menuIconSize, alignment: .center)
    }


    // MARK: - 私有方法
    
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
        .pointingHandCursor()
        
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
