//
//  TDTaskDetailView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData


/// 任务详情视图 - 第三列
struct TDTaskDetailView: View {
    @Bindable var task: TDMacSwiftDataListModel
    
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var mainViewModel: TDMainViewModel
    @Environment(\.modelContext) private var modelContext
    
    // 焦点状态管理
    @FocusState private var isDescriptionFocused: Bool

    // MARK: - #标签弹窗状态（标题输入框）
    // 已改为统一组件 `TDHashtagEditor`，这里不再需要额外状态

    // 计算属性：用于处理任务描述的绑定（和标题完全一样的逻辑）
    private var taskDescribeBinding: Binding<String> {
        Binding(
            get: { task.taskDescribe ?? "" },
            set: { newValue in
                task.taskDescribe = newValue.isEmpty ? nil : newValue
            }
        )
    }

    
    var body: some View {
        
        ZStack {
            Color(themeManager.backgroundColor)
                .ignoresSafeArea(.container, edges: .all)
            
            VStack (alignment: .leading, spacing: 0){
                // 顶部分类工具栏
                TDTaskDetailCategoryToolbar(task: task)
                    .frame(height: 44)
                    .overlay(
                        Rectangle()
                            .fill(themeManager.separatorColor)
                            .frame(height: 1.0)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    )
                
                ScrollView {
                    LazyVStack (spacing: 0){
                        
                        // 标题
                        TDHashtagEditor(
                            text: $task.taskContent,
                            placeholder: "task.detail.title.placeholder".localized,
                            fontSize: 13,
                            onCommit: {
                                // 与原逻辑一致：回车同步一次
                                syncTaskData(operation: "任务标题")
                            }
                        )
                        .environmentObject(themeManager)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)


                        // 描述
                        TextField("task.detail.description.placeholder".localized, text: taskDescribeBinding, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.descriptionTextColor)
                            .fixedSize(horizontal: false, vertical: true) // 固定垂直尺寸
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .focused($isDescriptionFocused)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
//                                    .fill(Color.blue)
                                    .fill(Color.clear)

                            )
                            .onChange(of: task.taskDescribe) { _, newValue in
                                // 实时检查并截取超过80个字符的内容
                                if let describe = newValue, describe.count > 80 {
                                    task.taskDescribe = String(describe.prefix(80))
                                }
                            }
//                            .onSubmit {
//                                // 结束编辑时同步数据
//                                syncTaskData(operation: "任务描述")
//                            }
                            .onChange(of: isDescriptionFocused) { _, isFocused in
                                // 当描述输入框失去焦点时同步数据
                                if !isFocused {
                                    syncTaskData(operation: "任务描述")
                                }
                            }

                        // 日期选择行
                        TDTaskDetailDateRow(
                            selectedDate: task.taskDate,
                            onDateSelected: { selectedDate in
                                
                                var newTodoTime: Int64
                                
                                // 更新任务的日期
                                if let date = selectedDate {
                                    // 转换为所选日期的开始时间戳
                                    newTodoTime = date.startOfDayTimestamp
                                } else {
                                    newTodoTime = 0
                                }
                                // 判断是否需要更新
                                if newTodoTime == task.todoTime {
                                    print("📅 日期未变化，跳过更新")
                                    return
                                }
                                task.todoTime = newTodoTime
                                // 调用更新本地数据方法
                                syncTaskData(operation: "日期更改")
                            }
                        )
//                        .background(.pink)
                        
                        // 子任务列表
                        TDSubtaskListView(task: task)
//                            .background(.red)
                        

                        
                        // 子任务输入框（永远在底部）
                        TDSubtaskInputView(
                            currentCount: task.subTaskList.count,
                            onAddSubtask: { content in
                                let newSubTask = TDMacSwiftDataListModel.SubTask(
                                    isComplete: false,
                                    content: content
                                )
                                task.subTaskList.append(newSubTask)
                                syncTaskData(operation: "新加子任务")
                            }
                        )
//                        .background(.yellow)
                        
                        // 工作量选择
                        TDTaskDetailWorkloadView(
                            task: task,
                            onWorkloadChanged: { newValue in
                                // 工作量变化时触发同步更新
                                task.snowAssess = newValue
                                syncTaskData(operation: "工作量")
                            }
                        )
                        
                        // 附件
                        TDTaskDetailAttachmentView(task: task) {
                            // 附件删除后的同步逻辑
                            syncTaskData(operation: "附件更新")
                        }
                        .padding(.top,20)
//                        Test1()

                    }
                }
                // 底部工具栏
                TDTaskDetailBottomToolbar(task: task)
//                    .frame(height: 44)
                
            }
        }
        .ignoresSafeArea(.container, edges: .all)
        .background(themeManager.backgroundColor)

    }
    
    // MARK: - 私有方法
    
    /// 同步任务数据到数据库和服务器
    /// - Parameter operation: 操作描述，用于日志输出
    private func syncTaskData(operation: String) {
        Task {
            do {
                _ = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(
                    updatedTask: task,
                    context: modelContext
                )
                
                // 执行同步
                await TDMainViewModel.shared.performSyncSeparately()
                
                print("✅ \(operation)更新成功")
            } catch {
                print("❌ \(operation)更新失败: \(error)")
            }
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



///// 任务详情视图 - 第三列
//struct TDTaskDetailView: View {
//    @Bindable var task: TDMacSwiftDataListModel
//
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @EnvironmentObject private var mainViewModel: TDMainViewModel
//    @Environment(\.modelContext) private var modelContext
//
//    // 状态变量
//    @State private var showCategoryPicker = false
//
//    // 计算属性：根据任务分类状态和本地分类数据动态计算显示的分类
//    private var displayCategories: [TDSliderBarModel] {
//        var categories: [TDSliderBarModel] = []
//
//        // 从 TDCategoryManager 获取本地分类数据
//        let allCategories = TDCategoryManager.shared.loadLocalCategories()
//
//        // 获取任务的分类ID
//        let taskCategoryId = task.standbyInt1
//
//        if taskCategoryId > 0 {
//            // 任务有分类：第一个显示当前分类，后面两个显示其他分类
//            if let currentCategory = allCategories.first(where: { $0.categoryId == taskCategoryId }) {
//                categories.append(currentCategory)
//            }
//
//            // 添加其他分类（最多2个）
//            let otherCategories = allCategories
//                .filter { $0.categoryId > 0 && $0.categoryId != taskCategoryId }
//                .prefix(2)
//            categories.append(contentsOf: otherCategories)
//        } else {
//            // 任务无分类：显示前三个本地分类
//            let firstThreeCategories = allCategories
//                .filter { $0.categoryId > 0 }
//                .prefix(3)
//            categories.append(contentsOf: firstThreeCategories)
//        }
//
//        return Array(categories.prefix(3))
//    }
//
//    // 计算属性：是否显示更多分类按钮
//    private var shouldShowMoreCategories: Bool {
//        let allCategories = TDCategoryManager.shared.loadLocalCategories()
//        let taskCategoryId = task.standbyInt1
//
//        if taskCategoryId > 0 {
//            // 任务有分类：检查是否还有其他分类未显示
//            let remainingCategories = allCategories.filter { category in
//                category.categoryId > 0 &&
//                !displayCategories.contains { $0.categoryId == category.categoryId }
//            }
//            return !remainingCategories.isEmpty
//        } else {
//            // 任务无分类：检查是否还有其他分类未显示
//            let remainingCategories = allCategories.filter { category in
//                category.categoryId > 0 &&
//                !displayCategories.contains { $0.categoryId == category.categoryId }
//            }
//            return !remainingCategories.isEmpty
//        }
//    }
//
//    // 计算属性：是否显示未分类标签
//    private var shouldShowUncategorized: Bool {
//        let allCategories = TDCategoryManager.shared.loadLocalCategories()
//        // 只有当本地没有分类数据，且任务也没有分类时才显示
//        return allCategories.isEmpty && task.standbyInt1 <= 0
//    }
//
//    // 计算属性：获取可用分类列表（用于更多分类菜单）
//    private var availableCategories: [TDSliderBarModel] {
//        let allCategories = TDCategoryManager.shared.loadLocalCategories()
//        let taskCategoryId = task.standbyInt1
//
//        if taskCategoryId > 0 {
//            // 任务有分类：返回除了已显示的三个分类之外的所有分类
//            return allCategories.filter { category in
//                category.categoryId > 0 &&
//                !displayCategories.contains { $0.categoryId == category.categoryId }
//            }
//        } else {
//            // 任务无分类：返回除了已显示的三个分类之外的所有分类
//            return allCategories.filter { category in
//                category.categoryId > 0 &&
//                !displayCategories.contains { $0.categoryId == category.categoryId }
//            }
//        }
//    }
//
//    /// 处理分类标签点击
//    private func handleCategoryTap(_ category: TDSliderBarModel) {
//        if category.categoryId == 0 {
//            // 点击未分类标签
//            if task.standbyInt1 == 0 {
//                // 如果当前已经是未选中状态，则不做任何操作
//                print("当前已经是未分类状态")
//            } else {
//                // 取消当前选中的分类
//                task.standbyInt1 = 0
//                task.standbyIntName = ""
//                task.standbyIntColor = ""
//                print("取消选中分类，设置为未分类")
//            }
//        } else {
//            // 点击分类标签
//            if task.standbyInt1 == category.categoryId {
//                // 如果点击的是当前已选中的分类，则取消选中
//                task.standbyInt1 = 0
//                task.standbyIntName = ""
//                task.standbyIntColor = ""
//                print("取消选中分类: \(category.categoryName)")
//            } else {
//                // 选中新分类
//                task.standbyInt1 = category.categoryId
//                task.standbyIntName = category.categoryName
//                task.standbyIntColor = category.categoryColor ?? "#007AFF"
//                print("选中分类: \(category.categoryName)")
//            }
//        }
//    }
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // 顶部分类工具栏
//            categoryToolbar
//
//            // 中间区域 - 暂时不写
//            Spacer()
//
//            // 底部工具栏
//            bottomToolbar
//        }
//        .background(Color(.windowBackgroundColor))
//    }
//
//    // MARK: - 顶部分类工具栏
//    private var categoryToolbar: some View {
//        HStack(spacing: 8) {
//            // 动态分类标签
//            ForEach(displayCategories, id: \.categoryId) { category in
//                CategoryTagView(
//                    category: category,
//                    isSelected: task.standbyInt1 == category.categoryId, // 根据任务实际分类状态判断
//                    onTap: {
//                        handleCategoryTap(category)
//                    }
//                )
//            }
//
//            // 未分类标签（当任务没有分类且本地没有分类数据时显示）
//            if shouldShowUncategorized {
//                CategoryTagView(
//                    category: TDSliderBarModel.uncategorized,
//                    isSelected: task.standbyInt1 == 0, // Selected if no category is chosen
//                    onTap: {
//                        handleCategoryTap(TDSliderBarModel.uncategorized)
//                    }
//                )
//            }
//
//            // 下拉箭头（只有本地有分类数据时才显示）
//            if shouldShowMoreCategories {
//                Menu {
//                    // MARK: - 新建分类选项
//                    Button(action: {
//                        // TODO: 实现新建分类功能
//                        print("新建分类")
//                    }) {
//                        HStack {
//                            Image(systemName: "plus.circle.fill")
//                                .foregroundColor(themeManager.color(level: 5))
//                                .font(.system(size: 14))
//                            Text("new_category".localized)
//                        }
//                    }
//                    .buttonStyle(PlainButtonStyle())
//
//                    // MARK: - 不分类选项
//                    Button(action: {
//                        handleModifyCategory(category: nil)
//                    }) {
//                        HStack {
//                            Image(systemName: "circle")
//                                .foregroundColor(.red)
//                                .font(.system(size: 14))
//                            Text("uncategorized".localized)
//                        }
//                    }
//                    .buttonStyle(PlainButtonStyle())
//
//                    // MARK: - 现有分类列表（过滤掉外面已显示的分类）
//                    if !availableCategories.isEmpty {
//                        Divider()
//
//                        ForEach(availableCategories, id: \.categoryId) { category in
//                            Button(action: {
//                                handleModifyCategory(category: category)
//                            }) {
//                                HStack {
//                                    Image.fromHexColor(category.categoryColor ?? "#c3c3c3", width: 14, height: 14, cornerRadius: 7.0)
//                                        .resizable()
//                                        .frame(width: 14.0, height: 14.0)
//
//                                    Text(String(category.categoryName.prefix(8)))
//                                        .font(.system(size: 12))
//                                }
//                            }
//                            .buttonStyle(PlainButtonStyle())
//                        }
//                    }
//                } label: {
//                    Text("选择分类")
//                        .font(.system(size: 12))
//                        .foregroundColor(themeManager.descriptionTextColor)
//                        .padding(.horizontal, 12)
//                        .padding(.vertical, 6)
//                        .background(
//                            RoundedRectangle(cornerRadius: 12)
//                                .fill(themeManager.secondaryBackgroundColor)
//                        )
//                }
//                .menuStyle(.button)
//                .frame(width: 80)
//            }
//
//            Spacer()
//
//            // 复选框
//            Button(action: {
//                // 切换任务完成状态
//                toggleTaskCompletion()
//            }) {
//                Image(systemName: task.complete ? "checkmark.square.fill" : "square")
//                    .font(.system(size: 16))
//                    .foregroundColor(getCheckboxColor())
//            }
//            .buttonStyle(PlainButtonStyle())
//        }
//        .padding(.horizontal, 16)
//        .padding(.vertical, 12)
//        .background(Color(.controlBackgroundColor))
//        .onAppear {
//            // 不再需要初始化选中状态，因为现在直接使用task的分类状态
//        }
//    }
//
//    // 获取复选框颜色
//    private func getCheckboxColor() -> Color {
//        let allCategories = TDCategoryManager.shared.loadLocalCategories()
//        if task.standbyInt1 > 0 {
//            // 有选中分类：显示当前选中分类的颜色
//            if let category = allCategories.first(where: { $0.categoryId == task.standbyInt1 }) {
//                return Color.fromHex(category.categoryColor ?? "#007AFF")
//            }
//        }
//
//        // 没有选中分类：显示主题颜色描述颜色
//        return themeManager.descriptionTextColor
//    }
//
//    // MARK: - 底部工具栏
//    private var bottomToolbar: some View {
//        HStack(spacing: 16) {
//            // 复制按钮
//            Button(action: {
////                handleCreateCopy(copyType: .normal)
//            }) {
//                Image(systemName: "doc.on.doc")
//                    .font(.system(size: 16))
//                    .foregroundColor(.secondary)
//            }
//            .buttonStyle(PlainButtonStyle())
//            .help("创建副本")
//
//            Spacer()
//
//            // 删除按钮
//            Button(action: {
//                // TODO: 删除任务
//                print("删除任务: \(task.taskContent)")
//            }) {
//                Image(systemName: "trash")
//                    .font(.system(size: 16))
//                    .foregroundColor(.red)
//            }
//            .buttonStyle(PlainButtonStyle())
//            .help("删除任务")
//
//            // 更多选项按钮
//            Menu {
//                // 复制内容
//                Button("复制内容") {
//                    // TODO: 实现复制内容功能
//                    print("复制内容: \(task.taskContent)")
//                }
//
//                // 创建副本
//                Menu("创建副本") {
//                    Button("创建副本") {
//                        // TODO: 实现创建副本功能
//                        // 创建副本 - 保持原日期
////                        handleCreateCopy(copyType: .normal)
//                    }
//
//                    // 根据当前任务的日期判断是否显示"创建到今天"
////                    if !isToday {
////                        Button("创建到今天") {
////                            // TODO: 实现创建到今天功能
////                            // 创建副本到今天
//////                            handleCreateCopy(copyType: .toToday)
////                        }
////                    }
//
//                    Button("创建到指定日期") {
//                        // TODO: 实现创建到指定日期功能
//                        // 创建副本到指定日期 - 显示日期选择器
////                        showDatePickerForCopy = true
//                    }
//                }
//
//                // 描述转为子任务
//                Button("描述转为子任务") {
//                    // TODO: 实现描述转为子任务功能
//                    print("描述转为子任务")
//                }
//
//                // 子任务转为描述
//                Button("子任务转为描述") {
//                    // TODO: 实现子任务转为描述功能
//                    print("子任务转为描述")
//                }
//
//                Divider()
//
//                // 删除
//                Button("删除") {
//                    // TODO: 实现删除功能
//                    print("删除任务: \(task.taskContent)")
//                }
//                .foregroundColor(.red)
//            } label: {
//                Text("更多")
//                    .font(.system(size: 12))
//                    .foregroundColor(themeManager.descriptionTextColor)
//                    .padding(.horizontal, 12)
//                    .padding(.vertical, 6)
//                    .background(
//                        RoundedRectangle(cornerRadius: 12)
//                            .fill(themeManager.secondaryBackgroundColor)
//                    )
//            }
//            .menuStyle(.button)
//        }
//        .padding(.horizontal, 16)
//        .padding(.vertical, 12)
//        .background(Color(.controlBackgroundColor))
//        .overlay(
//            Rectangle()
//                .frame(height: 1)
//                .foregroundColor(themeManager.separatorColor),
//            alignment: .top
//        )
////        .popover(isPresented: $showDatePickerForCopy) {
////            // 日期选择器弹窗
////            VStack(spacing: 16) {
////                Text("选择日期")
////                    .font(.headline)
////
////                DatePicker("选择日期", selection: $selectedCopyDate, displayedComponents: .date)
////                    .datePickerStyle(.graphical)
////
////                HStack(spacing: 12) {
////                    Button("取消") {
////                        showDatePickerForCopy = false
////                    }
////                    .buttonStyle(.bordered)
////
////                    Button("确定") {
////                        handleCreateCopy(copyType: .toSpecificDate)
////                        showDatePickerForCopy = false
////                    }
////                    .buttonStyle(.borderedProminent)
////                }
////            }
////            .padding()
////            .frame(width: 300, height: 400)
////        }
//    }
//
//    // MARK: - 私有方法
//
//    /// 切换任务完成状态
//    private func toggleTaskCompletion() {
//        Task {
//            do {
//                let updatedTask = task
//                updatedTask.complete = !task.complete
//
//                let queryManager = TDQueryConditionManager()
//                let result = try await queryManager.updateLocalTaskWithModel(
//                    updatedTask: updatedTask,
//                    context: modelContext
//                )
//
//                if result == .updated {
//                    print("切换任务状态成功: \(task.taskContent)")
//                    await TDMainViewModel.shared.performSyncSeparately()
//                }
//            } catch {
//                print("切换任务状态失败: \(error)")
//            }
//        }
//    }
//
//    /// 处理分类修改
//    private func handleModifyCategory(category: TDSliderBarModel?) {
//        if let category = category {
//            // 如果点击的是当前已选中的分类，则取消选中
//            if task.standbyInt1 == category.categoryId {
//                // 取消分类
//                task.standbyInt1 = 0
//                task.standbyIntName = ""
//                task.standbyIntColor = ""
//                print("取消选中分类: \(category.categoryName), 选中状态: \(task.standbyInt1)")
//            } else {
//                // 选中新分类
//                task.standbyInt1 = category.categoryId
//                task.standbyIntName = category.categoryName
//                task.standbyIntColor = category.categoryColor ?? "#007AFF"
//                print("选中分类: \(category.categoryName), 选中状态: \(task.standbyInt1)")
//            }
//        } else {
//            // 取消分类
//            task.standbyInt1 = 0
//            task.standbyIntName = ""
//            task.standbyIntColor = ""
//            print("取消分类, 选中状态: \(task.standbyInt1)")
//        }
//    }
//
//    /// 初始化选中状态
//    private func initializeSelectedState() {
//        // 根据任务的当前分类设置选中状态
//        let taskCategoryId = task.standbyInt1
//
//        // 只有当任务确实有分类时，才设置选中状态
//        if taskCategoryId > 0 {
//            task.standbyInt1 = taskCategoryId
//            print("初始化选中状态: 任务有分类，分类ID = \(taskCategoryId), 选中状态 = \(taskCategoryId)")
//        } else {
//            // 任务没有分类，所有分类标签都应该是未选中状态
//            task.standbyInt1 = 0
//            print("初始化选中状态: 任务无分类，选中状态 = \(task.standbyInt1)")
//        }
//    }
//}
//
//// MARK: - 辅助视图
//
///// 分类标签视图
//private struct CategoryTagView: View {
//    let category: TDSliderBarModel
//    let isSelected: Bool
//    let onTap: () -> Void
//
//    @EnvironmentObject private var themeManager: TDThemeManager
//
//    var body: some View {
//        Button(action: onTap) {
//            Text(category.categoryName)
//                .font(.system(size: 12))
//                .foregroundColor(getTextColor())
//                .padding(.horizontal, 10) // 增加左右间距到10pt
//                .padding(.vertical, 6)    // 增加上下间距到6pt
//                .background(
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(getBackgroundColor())
//                )
//        }
//        .buttonStyle(PlainButtonStyle())
//    }
//
//    // 获取背景色
//    private func getBackgroundColor() -> Color {
//        if isSelected {
//            // 选中的时候背景色使用当前分类的颜色
//            return Color.fromHex(category.categoryColor ?? "#007AFF")
//        } else {
//            // 未选中的时候背景色使用主题颜色二级背景色
//            return themeManager.secondaryBackgroundColor
//        }
//    }
//
//    // 获取字体颜色
//    private func getTextColor() -> Color {
//        if isSelected {
//            // 选中的时候字体颜色改为白色
//            return .white
//        } else {
//            // 未选中的时候字体颜色使用主题颜色描述颜色
//            return themeManager.descriptionTextColor
//        }
//    }
//}

#Preview {
    TDTaskDetailView(task: TDMacSwiftDataListModel(
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
    .environmentObject(TDMainViewModel.shared)
}
