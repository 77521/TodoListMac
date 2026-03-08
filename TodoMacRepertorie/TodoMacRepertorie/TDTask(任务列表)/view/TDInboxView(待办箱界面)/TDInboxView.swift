//
//  TDInboxView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData

/// 待办箱界面（无日期事件列表）
struct TDInboxView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var mainViewModel = TDMainViewModel.shared

    let category: TDSliderBarModel?

    @Query private var tasks: [TDMacSwiftDataListModel]

    // MARK: - Top Menus
    enum TDSortField: String, CaseIterable, Identifiable {
        case createTime
        case taskSort
        case snowAssess

        var id: String { rawValue }

        var title: String {
            switch self {
            case .createTime: return "inbox.sort.by_create_time".localized
            case .taskSort: return "inbox.sort.by_custom".localized
            case .snowAssess: return "inbox.sort.by_workload".localized
            }
        }
    }

    enum TDSortOrder: String, CaseIterable, Identifiable {
        case ascending
        case descending

        var id: String { rawValue }

        var title: String {
            switch self {
            case .ascending: return "tag.filter.order.asc".localized
            case .descending: return "tag.filter.order.desc".localized
            }
        }
    }

    enum TDCategoryFilter: Equatable {
        case all
        case uncategorized
        case category(TDSliderBarModel)
    }

    @State private var sortField: TDSortField = .createTime
    @State private var sortOrder: TDSortOrder = .ascending
    @State private var categoryFilter: TDCategoryFilter = .all
    
    private var categoryPickerSelectedCategory: TDSliderBarModel? {
        switch categoryFilter {
        case .all:
            return nil
        case .uncategorized:
            return nil
        case .category(let model):
            return model
        }
    }

    init(category: TDSliderBarModel? = nil) {
        self.category = category
        
        // 说明：所有查询逻辑统一收敛到 TDCorrectQueryBuilder（避免每个 View 重复写一份）
        let (predicate, _) = TDCorrectQueryBuilder.getInboxNoDateQuery()
        _tasks = Query(filter: predicate)
    }
    
    var body: some View {
        let filtered = applyCategoryFilter(tasks)
        let displayTasks = applySorting(filtered)

        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

            TDTaskInputView(todoTimeOverride: 0, showMoreMenu: false)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            if displayTasks.isEmpty {
                emptyState
            } else {
                taskList(displayTasks)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - UI

    private var topBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: category?.headerIcon ?? "tray.full.fill")
                    .foregroundColor(themeManager.color(level: 5))
                    .font(.system(size: 14, weight: .semibold))
                Text(category?.categoryName ?? "inbox".localized)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.titleTextColor)
            }

            Spacer()

            Menu {
                ForEach(TDSortField.allCases) { item in
                    Button {
                        sortField = item
                    } label: {
                        Text(item.title)
                    }
                }
            } label: {
                topMenuLabel(text: sortField.title, systemImage: "arrow.up.arrow.down")
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .pointingHandCursor()

            Menu {
                ForEach(TDSortOrder.allCases) { item in
                    Button {
                        sortOrder = item
                    } label: {
                        Text(item.title)
                    }
                }
            } label: {
                topMenuLabel(text: sortOrder.title, systemImage: "arrow.up.arrow.down.circle")
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .pointingHandCursor()

            categoryFilterMenu
        }
    }

    private func topMenuLabel(text: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeManager.titleTextColor)
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(themeManager.descriptionTextColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.secondaryBackgroundColor.opacity(0.7))
        )
        .overlay(alignment: .leading) {
            Image(systemName: systemImage)
                .font(.system(size: 12))
                .foregroundColor(themeManager.descriptionTextColor)
                .padding(.leading, -22)
                .opacity(0) // 仅占位，避免 label 变化导致跳动
        }
    }

    private var categoryFilterMenu: some View {
        TDCategoryPickerMenu(
            selectedCategory: categoryPickerSelectedCategory,
            isAllSelected: categoryFilter == .all,
            showAllItem: true,
            showCreateItem: false,
            showUncategorizedItem: true,
            labelStyle: .iconAndTextWithChevron,
            onAllSelected: {
                categoryFilter = .all
            },
            onUncategorizedSelected: {
                categoryFilter = .uncategorized
            },
            onCategorySelected: { category in
                categoryFilter = .category(category)
            }
        )
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("inbox.empty.title".localized)
                .font(.headline)
                .foregroundColor(.secondary)
            Text("inbox.empty.subtitle".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 50)
    }

    private func taskList(_ tasks: [TDMacSwiftDataListModel]) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(tasks.indices, id: \.self) { idx in
                        let task = tasks[idx]
                        TDInboxTaskRow(task: task, isLastRow: idx == tasks.count - 1)
                            .id(task.taskId)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .onAppear {
                if let id = mainViewModel.selectedTask?.taskId {
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
            .onChange(of: mainViewModel.selectedTask?.taskId) { _, newId in
                guard let newId else { return }
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(newId, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Data

    private var categoryMenuItems: [TDSliderBarModel] {
        let all = TDCategoryManager.shared.loadLocalCategories()
        let server = all.filter { $0.categoryId > 0 }
        let processed = TDCategoryManager.shared.getFolderWithSubCategories(from: server)
        return processed.filter { item in
            if item.isFolder { return !((item.children ?? []).isEmpty) }
            return true
        }
    }

    private func applyCategoryFilter(_ tasks: [TDMacSwiftDataListModel]) -> [TDMacSwiftDataListModel] {
        switch categoryFilter {
        case .all:
            return tasks
        case .uncategorized:
            return tasks.filter { $0.standbyInt1 == 0 }
        case .category(let model):
            return tasks.filter { $0.standbyInt1 == model.categoryId }
        }
    }

    private func applySorting(_ tasks: [TDMacSwiftDataListModel]) -> [TDMacSwiftDataListModel] {
        func decimalLess(_ a: Decimal, _ b: Decimal) -> Bool {
            (a as NSDecimalNumber).compare(b as NSDecimalNumber) == .orderedAscending
        }
        func decimalGreater(_ a: Decimal, _ b: Decimal) -> Bool {
            (a as NSDecimalNumber).compare(b as NSDecimalNumber) == .orderedDescending
        }

        return tasks.sorted { lhs, rhs in
            switch sortField {
            case .createTime:
                if lhs.createTime != rhs.createTime {
                    return sortOrder == .ascending ? (lhs.createTime < rhs.createTime) : (lhs.createTime > rhs.createTime)
                }
                // 兜底：同创建时间按 taskSort 升序（稳定）
                return decimalLess(lhs.taskSort, rhs.taskSort)
            case .taskSort:
                if lhs.taskSort != rhs.taskSort {
                    return sortOrder == .ascending ? decimalLess(lhs.taskSort, rhs.taskSort) : decimalGreater(lhs.taskSort, rhs.taskSort)
                }
                // 兜底：同 taskSort 按创建时间升序
                return lhs.createTime < rhs.createTime
            case .snowAssess:
                if lhs.snowAssess != rhs.snowAssess {
                    return sortOrder == .ascending ? (lhs.snowAssess < rhs.snowAssess) : (lhs.snowAssess > rhs.snowAssess)
                }
                // 你要求：工作量相同 → 再按 taskSort 升序
                if lhs.taskSort != rhs.taskSort {
                    return decimalLess(lhs.taskSort, rhs.taskSort)
                }
                return lhs.createTime < rhs.createTime
            }
        }
    }
}

#Preview {
    TDInboxView()
        .environmentObject(TDThemeManager.shared)
}

// MARK: - Row

private struct TDInboxTaskRow: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @ObservedObject private var mainViewModel = TDMainViewModel.shared
    @ObservedObject private var settingManager = TDSettingManager.shared

    let task: TDMacSwiftDataListModel
    let isLastRow: Bool

    @State private var isHovered: Bool = false

    var body: some View {
        // 说明：对齐与主任务列表一致
        // - 左侧难度条：上下各 2pt
        // - 标题：最多显示行数跟随设置（默认 2 行）
        HStack(alignment: .center, spacing: 0) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(task.difficultyColor)
                .frame(width: 3)
                .padding(.vertical, 2)
                // 说明：与 DayTodo/最近待办一致，难度条紧贴最左侧（只保留 1pt 安全边距）
                .padding(.leading, 1)

            // 任务标题（待办箱同样按“重要功能”渲染）：
            // - 有 #标签：显示胶囊（主题色 5 级），可点击弹窗进入标签模式
            // - 有链接：千草蓝 5 级，可点击打开
            TDTaskTitleRichTextView(
                rawTitle: task.taskContent,
                baseTextColor: task.taskTitleColor,
                fontSize: 14,
                lineLimit: settingManager.taskTitleLines,
                isStrikethrough: task.taskTitleStrikethrough,
                opacity: task.complete ? 0.65 : 1,
                onTapPlain: {
                    // 点击标题普通区域时也要与“点击整行”一致：打开第三列详情
                    mainViewModel.selectTask(task)
                }
            )
            // 标题区域的上下留白由这里控制（避免把 left bar 一起撑大）
            .padding(.vertical, 8)
            .padding(.leading, 12)
            .padding(.trailing, 16)

            Spacer(minLength: 0)
        }
        .background(background)
        .contentShape(Rectangle())
        .onTapGesture {
            mainViewModel.selectTask(task)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .overlay(alignment: .bottom) {
            if !isLastRow {
                Rectangle()
                    .fill(themeManager.separatorColor)
                    .frame(height: 1)
            }
        }
    }

    private var background: some View {
        Group {
            if mainViewModel.selectedTask?.taskId == task.taskId {
                themeManager.color(level: 1).opacity(0.2)
            } else if isHovered {
                themeManager.secondaryBackgroundColor.opacity(0.3)
            } else {
                themeManager.backgroundColor
            }
        }
    }
}
