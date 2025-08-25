//
//  TDSliderBarView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
//
//
//struct TDSliderBarView: View {
//    @StateObject private var viewModel = TDSliderBarViewModel()
//    @ObservedObject private var themeManager = TDThemeManager.shared
//    @ObservedObject private var settingManager = TDSettingManager.shared
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            
//            
//            // 顶部固定区域
//            VStack(spacing: 0) {
//                // 用户信息
//                HStack {
//                    Circle()
//                        .fill(Color.gray.opacity(0.3))
//                        .frame(width: 32, height: 32)
//                    
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text(TDUserManager.shared.nickname)
//                            .font(.system(size: settingManager.fontSize.size))
//                            .foregroundColor(themeManager.titleTextColor)
//                        Text("账号")
//                            .font(.system(size: settingManager.fontSize.size - 2))
//                            .foregroundColor(themeManager.descriptionTextColor)
//                    }
//                    
//                    Spacer()
//                }
//                .frame(height: 48)
//                .padding(.horizontal, 16)
//                Color.red.frame(height: 1)
//
//                // 同步状态
//                HStack {
//                    Image(systemName: "arrow.triangle.2.circlepath")
//                        .foregroundColor(themeManager.descriptionTextColor)
//                    Text(viewModel.isSyncing ? "正在同步..." : "同步完成")
//                        .font(.system(size: settingManager.fontSize.size))
//                        .foregroundColor(themeManager.titleTextColor)
//                    
//                    Spacer()
//                    
//                    if viewModel.isSyncing {
//                        ProgressView()
//                            .scaleEffect(0.4)
//                    }
//                }
//                .frame(height: 48)
//                .padding(.horizontal, 16)
//                .contentShape(Rectangle())
//                .onTapGesture {
//                    Task {
//                         viewModel.performSync()
//                    }
//                }
//            }
//            .background(
//                VStack(spacing: 0) {
//                    Color.clear
//                    Color.red.frame(height: 1)
//                }
//            )
//            //            .background(Color.clear)
////            .background(themeManager.backgroundColor)
//            
//            // 分类列表
//            List {
//                Group {
//                    // 1. DayTodo
//                    if let item = viewModel.items.first(where: { $0.categoryId == -100 }) {
//                        TDCategoryRowView(item: item)
//                            .onTapGesture {
//                                viewModel.selectCategory(item)
//                            }
//                    }
//                    
//                    // 2. 最近待办
//                    if let item = viewModel.items.first(where: { $0.categoryId == -101 }) {
//                        TDCategoryRowView(item: item)
//                            .onTapGesture {
//                                viewModel.selectCategory(item)
//                            }
//                    }
//                    
//                    // 3. 日程概览
//                    if let item = viewModel.items.first(where: { $0.categoryId == -102 }) {
//                        TDCategoryRowView(item: item)
//                            .onTapGesture {
//                                viewModel.selectCategory(item)
//                            }
//                    }
//                    
//                    // 4. 待办箱
//                    if let item = viewModel.items.first(where: { $0.categoryId == -103 }) {
//                        TDCategoryRowView(item: item)
//                            .onTapGesture {
//                                viewModel.selectCategory(item)
//                            }
//                    }
//                }
//                .listRowInsets(EdgeInsets())
//                .listRowBackground(Color.clear)
//                .listRowSeparator(.hidden)
//
//                // 5. 分类清单组
//                DisclosureGroup(
//                    isExpanded: $viewModel.isCategoryGroupExpanded,
//                    content: {
//                        ForEach(viewModel.items.filter { $0.categoryId >= -1 }) { item in
//                            TDCategoryRowView(item: item)
//                                .onTapGesture {
//                                    viewModel.selectCategory(item)
//                                }
//                                .listRowInsets(EdgeInsets())
//                                .listRowBackground(Color.clear)
//                                .listRowSeparator(.hidden)
//                        }
//                    },
//                    label: {
//                        TDCategoryGroupView(
//                            title: "分类清单",
//                            icon: "folder",
//                            showAddButton: true,
//                            showSettingButton: true,
//                            onAddTap: { viewModel.showSheet = true },
//                            onSettingTap: { viewModel.showSheet = true }
//                        )
//                    }
//                )
//                .listRowInsets(EdgeInsets())
//                .listRowBackground(Color.clear)
//                .listRowSeparator(.hidden)
//
//                // 6. 标签组
//                DisclosureGroup(
//                    isExpanded: $viewModel.isTagGroupExpanded,
//                    content: {
//                        // 标签内容视图
//                        ForEach(viewModel.tagsArr) { tag in
//                            TDCategoryRowView(item: tag)
//                                .onTapGesture {
//                                    viewModel.selectCategory(tag)
//                                }
//                                .listRowInsets(EdgeInsets())
//                                .listRowBackground(Color.clear)
//                                .listRowSeparator(.hidden)
//                        }
//                    },
//                    label: {
//                        TDCategoryGroupView(
//                            title: "标签",
//                            icon: "tag",
//                            showFilterButton: true,
//                            onFilterTap: { viewModel.showTagFilter = true }
//                        )
//                    }
//                )
//                .listRowInsets(EdgeInsets())
//                .listRowBackground(Color.clear)
//                .listRowSeparator(.hidden)
//
//                Group {
//                    // 7. 数据统计
//                    TDCategoryRowView(item: viewModel.items.first { $0.categoryId == -106 }!)
//                        .onTapGesture {
//                            if let item = viewModel.items.first(where: { $0.categoryId == -106 }) {
//                                viewModel.selectCategory(item)
//                            }
//                        }
//                    
//                    // 8. 最近已完成
//                    TDCategoryRowView(item: viewModel.items.first { $0.categoryId == -107 }!)
//                        .onTapGesture {
//                            if let item = viewModel.items.first(where: { $0.categoryId == -107 }) {
//                                viewModel.selectCategory(item)
//                            }
//                        }
//                    
//                    // 9. 回收站
//                    TDCategoryRowView(item: viewModel.items.first { $0.categoryId == -108 }!)
//                        .onTapGesture {
//                            if let item = viewModel.items.first(where: { $0.categoryId == -108 }) {
//                                viewModel.selectCategory(item)
//                            }
//                        }
//                }
//                .listRowInsets(EdgeInsets())
//                .listRowBackground(Color.clear)
//                .listRowSeparator(.hidden)
//            }
//            .listStyle(.sidebar)
//            .scrollContentBackground(.hidden)
//        }
//        .background(.ultraThinMaterial)
//        
//    }
//}
//
//
////struct TDSliderBarView: View {
////    @StateObject private var categoryManager = TDCategoryManager.shared
////    @Binding var selection: TDSliderBarModel?
////    @State private var hoveredGroupId: Int?
////    @State private var showingAddCategorySheet = false
////    @State private var showingEditCategorySheet = false
////
////    var body: some View {
//////        TDUserInfoView()
//////            .frame(height: 30)
////        List {
////            // 同步状态
////            HStack {
////                Image(systemName: "checkmark.circle")
////                    .foregroundColor(.green)
////                Text("同步完成")
////                    .foregroundColor(.secondary)
////                Spacer()
////                Button(action: {}) {
////                    Image(systemName: "arrow.clockwise")
////                        .foregroundColor(.secondary)
////                }
////                .buttonStyle(.borderless)
////            }
////            .padding(.vertical, 2)
////
////            // 固定组
////            ForEach(categoryManager.fixedItems, id: \.categoryId) { item in
////                TDCategoryRowView(item: item, selection: $selection)
////                    .tag(item)
////            }
////            .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))  // 移除行内边距
////            .listRowSeparator(.hidden)    // 隐藏分割线
////
////            // 分类清单组
////            if let categoryGroup = categoryManager.categoryGroup {
////                Section {
////                    ForEach(categoryGroup.categoryDatas, id: \.categoryId) { category in
////                        TDCategoryRowView(item: category, selection: $selection)
////                            .tag(category)
////                    }
////                    .listRowInsets(EdgeInsets(top: 5, leading: 8, bottom: 0, trailing: 0))  // 移除行内边距
////                    .listRowSeparator(.hidden)    // 隐藏分割线
////
////                } header: {
////                    TDCategoryGroupHeaderView(
////                        group: categoryGroup,
////                        isHovered: hoveredGroupId == categoryGroup.categoryId,
////                        onAddCategory: { showingAddCategorySheet = true },
////                        onEditCategory: { showingEditCategorySheet = true }
////                    )
////                }
////                .onHover { isHovered in
////                    hoveredGroupId = isHovered ? categoryGroup.categoryId : nil
////                }
////            }
////
////            // 标签组
////            if let tagGroup = categoryManager.tagGroup {
////                Section {
////                    VStack(alignment: .leading, spacing: 4) {
////                        ForEach(tagGroup.categoryDatas, id: \.categoryId) { tag in
////                            Text(tag.categoryName)
////                                .padding(.vertical, 4)
////                                .padding(.horizontal, 8)
////                                .background(Color.secondary.opacity(0.2))
////                                .cornerRadius(4)
////                        }
////                    }
////                } header: {
////                    TDTagGroupHeaderView(group: tagGroup, isHovered: hoveredGroupId == tagGroup.categoryId)
////                }
////            }
////
////            // 统计组
////            ForEach(categoryManager.statsItems, id: \.categoryId) { item in
////                TDCategoryRowView(item: item, selection: $selection)
////                    .tag(item)
////            }
////            .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))  // 移除行内边距
////            .listRowSeparator(.hidden)    // 隐藏分割线
////
////        }
////        .listStyle(.sidebar) // 指定为Source List样式
////        .onChange(of: categoryManager.selectedCategory) { oldValue, newValue in
////            selection = newValue
////        }
////
////    }
////}
////
////struct GroupButton: Identifiable {
////    let id = UUID()
////    let icon: String
////    let action: () -> Void
////}
////
////
////// MARK: - 同步按钮
////struct SyncButton: View {
////    @StateObject private var categoryManager = TDCategoryManager.shared
////    @State private var isSyncing = false
////
////    var body: some View {
////        Button(action: sync) {
////            HStack {
////                Spacer()
////                if isSyncing {
////                    ProgressView()
////                        .scaleEffect(0.7)
////                        .frame(width: 16, height: 16)
////                } else {
////                    Image(systemName: "arrow.triangle.2.circlepath")
////                }
////                Text("同步")
////            }
////        }
////        .padding(.horizontal)
////        .listStyle(.sidebar)
////        .background(NoSelectionStyle()) // 使用这个来移除默认的选中效果
////    }
////
////    private func sync() {
////        guard !isSyncing else { return }
////        isSyncing = true
////
////        Task {
////            await categoryManager.fetchCategories()
////            isSyncing = false
////        }
////    }
////}
////struct NoSelectionStyle: NSViewRepresentable {
////    func makeNSView(context: Context) -> NSView {
////        let view = NSView()
////        DispatchQueue.main.async {
////            if let tableView = view.enclosingScrollView?.documentView as? NSTableView {
////                tableView.selectionHighlightStyle = .none
////            }
////        }
////        return view
////    }
////
////    func updateNSView(_ nsView: NSView, context: Context) {}
////}
////// MARK: - 拖拽代理
////struct CategoryDropDelegate: DropDelegate {
////    let item: TDSliderBarModel
////    @Binding var draggedItem: TDSliderBarModel?
////    let categoryManager: TDCategoryManager
////
////    func performDrop(info: DropInfo) -> Bool {
////        guard let draggedItem = self.draggedItem,
////              draggedItem.categoryId != item.categoryId,
////              draggedItem.categoryId != 0 // 未分类不可拖动
////        else { return false }
////
////        Task {
////            // 获取分类清单组
////            if let index = categoryManager.menuData.firstIndex(where: { $0.categoryId == -104 }) {
////                var categories = categoryManager.menuData[index].categoryDatas
////
////                // 计算新的排序位置
////                if let fromIndex = categories.firstIndex(where: { $0.categoryId == draggedItem.categoryId }),
////                   let toIndex = categories.firstIndex(where: { $0.categoryId == item.categoryId }) {
////
////                    // 移动分类
////                    categories.move(fromOffsets: IndexSet(integer: fromIndex),
////                                    toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
////
////                    // 更新排序值
////                    for (index, var category) in categories.enumerated() where category.categoryId != 0 {
////                        category.listSort = Double((index + 1) * 100)
////                        categories[index] = category
////                    }
////
////                    // 保存排序
////                    try? await categoryManager.updateCategoriesSort(categories)
////                }
////            }
////        }
////
////        self.draggedItem = nil
////        return true
////    }
////
////    func dropEntered(info: DropInfo) {
////        // 可以在这里添加拖拽进入时的视觉反馈
////        guard let draggedItem = self.draggedItem,
////              draggedItem.categoryId != item.categoryId,
////              draggedItem.categoryId != 0,  // 未分类不可拖动
////              item.categoryId != 0  // 不可拖到未分类
////        else { return }
////
////        // 获取分类清单组
////        if let index = categoryManager.menuData.firstIndex(where: { $0.categoryId == -104 }) {
////            var categories = categoryManager.menuData[index].categoryDatas
////
////            // 计算拖拽位置
////            if let fromIndex = categories.firstIndex(where: { $0.categoryId == draggedItem.categoryId }),
////               let toIndex = categories.firstIndex(where: { $0.categoryId == item.categoryId }) {
////
////                // 临时更新UI显示顺序
////                withAnimation(.easeInOut(duration: 0.2)) {
////                    categories.move(fromOffsets: IndexSet(integer: fromIndex),
////                                    toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
////
////                    // 通过 Manager 更新数据
////                    categoryManager.updateCategoriesOrder(categories)
////                }
////            }
////        }
////
////
////    }
////
////    func dropUpdated(info: DropInfo) -> DropProposal? {
////        return DropProposal(operation: .move)
////    }
////
////    func validateDrop(info: DropInfo) -> Bool {
////        guard let draggedItem = self.draggedItem else { return false }
////        // 未分类不可作为拖拽目标
////        return item.categoryId != 0 && draggedItem.categoryId != item.categoryId
////    }
////}
////
////#Preview {
////    TDSliderBarView(selection: .constant(TDSliderBarModel()))
////}
////


struct TDSliderBarView: View {
    @StateObject private var viewModel = TDSliderBarViewModel.shared
    @ObservedObject private var themeManager = TDThemeManager.shared
    @ObservedObject private var settingManager = TDSettingManager.shared
    
    // 悬停状态管理
    @State private var hoveredCategoryId: Int? = nil
    @State private var isCategoryGroupHovered: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // 顶部固定区域（不滚动）
            topFixedArea
            
            // 可滚动的列表区域
            List {
                // 主要分类
                mainCategoriesSection
                
                // 分类清单组
                categoryListSection
                
                // 工具选项
                utilitySection
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            
            // 底部同步状态（不滚动）
            syncStatusView
            
        }
        .background(Color(.windowBackgroundColor))
    }
    

    
    // MARK: - 顶部固定区域
    private var topFixedArea: some View {
        VStack(spacing: 0) {
            // 用户信息
            TDUserInfoView()
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                TextField("搜索事件", text: .constant(""))
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 14))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // 分割线
            Divider()
                .padding(.horizontal, 16)
        }
        .background(Color(.windowBackgroundColor))
    }
    
    // MARK: - 主要分类区域
    private var mainCategoriesSection: some View {
        Group {
            // DayTodo
            if let dayTodo = viewModel.items.first(where: { $0.categoryId == -100 }) {
                categoryRowView(dayTodo)
            }
            
            // 最近待办
            if let recentTodo = viewModel.items.first(where: { $0.categoryId == -101 }) {
                categoryRowView(recentTodo)
            }
            
            // 日程概览
            if let schedule = viewModel.items.first(where: { $0.categoryId == -102 }) {
                categoryRowView(schedule)
            }
            
            // 待办箱
            if let inbox = viewModel.items.first(where: { $0.categoryId == -103 }) {
                categoryRowView(inbox)
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    // MARK: - 分类清单组
    private var categoryListSection: some View {
        DisclosureGroup(
            isExpanded: $viewModel.isCategoryGroupExpanded,
            content: {
                ForEach(viewModel.items.filter { $0.categoryId >= -1 }) { category in
                    categoryRowView(category)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            },
            label: {
                categoryGroupHeaderView
            }
        )
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    // MARK: - 分类组头部
    private var categoryGroupHeaderView: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(themeManager.color(level: 5))
                .font(.system(size: 14))
            
            Text("分类清单")
                .font(.system(size: 14))
                .foregroundColor(themeManager.titleTextColor)
            
            Spacer()
            
            // 按钮组（鼠标悬停时显示）
            HStack(spacing: 4) {
                Button(action: {
                    viewModel.showSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    viewModel.showSheet = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .opacity(isCategoryGroupHovered ? 1 : 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.2)) {
                isCategoryGroupHovered = isHovered
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.isCategoryGroupExpanded.toggle()
            }
        }
    }

    
    // MARK: - 工具选项区域
    private var utilitySection: some View {
        Group {
            // 数据统计
            if let stats = viewModel.items.first(where: { $0.categoryId == -106 }) {
                categoryRowView(stats)
            }
            
            // 最近已完成
            if let completed = viewModel.items.first(where: { $0.categoryId == -107 }) {
                categoryRowView(completed)
            }
            
            // 回收站
            if let trash = viewModel.items.first(where: { $0.categoryId == -108 }) {
                categoryRowView(trash)
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    // MARK: - 分类行视图
    private func categoryRowView(_ category: TDSliderBarModel) -> some View {
        HStack(spacing: 8) {
            // 图标或颜色圆圈
            if category.categoryId == 0 {
                // 未分类：使用空心圆圈
                Circle()
                    .stroke(themeManager.color(level: 6), lineWidth: 1)
                    .frame(width: 12, height: 12)
            } else if category.categoryId > 0, let categoryColor = category.categoryColor {
                // 服务器分类：使用实心颜色圆圈
                Circle()
                    .fill(Color.fromHex(categoryColor))
                    .frame(width: 12, height: 12)
            } else {
                // 系统分类：使用图标
                Image(systemName: category.headerIcon ?? "circle")
                    .foregroundColor(themeManager.color(level: 5))
                    .font(.system(size: 14))
            }

            // 分类名称
            Text(category.categoryName)
                .font(.system(size: 14))
                .foregroundColor(themeManager.titleTextColor)
            
            Spacer()
            
            // 数量标签
            if let count = category.unfinishedCount, count > 0 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeManager.color(level: 5))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.color(level: 1))
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColorForCategory(category))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectCategory(category)
        }
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoveredCategoryId = isHovered ? category.categoryId : nil
            }
        }
    }
    
    // MARK: - 背景色计算
    private func backgroundColorForCategory(_ category: TDSliderBarModel) -> Color {
        let isSelected = category.isSelect ?? false
        let isHovered = hoveredCategoryId == category.categoryId
        
        // 如果选中了，优先显示选中背景色
        if isSelected {
            if category.categoryId >= 0, let categoryColor = category.categoryColor {
                // 服务器分类：使用分类颜色 + 0.3 透明度
                return Color.fromHex(categoryColor).opacity(0.3)
            } else {
                // 系统分类：使用主题颜色 + 0.3 透明度
                return themeManager.color(level: 5).opacity(0.3)
            }
        }
        
        // 如果未选中但鼠标悬停
        if isHovered {
            if category.categoryId >= 0, let categoryColor = category.categoryColor {
                // 服务器分类：使用分类颜色 + 0.2 透明度
                return Color.fromHex(categoryColor).opacity(0.2)
            } else {
                // 系统分类：使用主题颜色 + 0.2 透明度
                return themeManager.color(level: 5).opacity(0.2)
            }
        }
        
        // 默认：无背景色
        return Color.clear
    }
    
    // MARK: - 同步状态视图
    private var syncStatusView: some View {
        VStack(spacing: 0) {
            // 分割线
            Divider()
                .padding(.horizontal, 16)
            
            // 同步状态内容
            HStack {
                Image(systemName: viewModel.isSyncing ? "arrow.triangle.2.circlepath" : "checkmark.circle")
                    .foregroundColor(viewModel.isSyncing ? .orange : .green)
                    .font(.system(size: 14))
                
                Text(viewModel.isSyncing ? "同步中..." : "已同步")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.descriptionTextColor)
                
                Spacer()
                
                if viewModel.isSyncing {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)
                } else {
                    Button(action: {
                        Task {
                            await TDMainViewModel.shared.performSyncSeparately()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(themeManager.secondaryBackgroundColor.opacity(0.8))
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .ignoresSafeArea(.container, edges: .all)
        .background(Color(.windowBackgroundColor))
    }

}


#Preview {
    TDSliderBarView()
        .frame(width: 280)
}
