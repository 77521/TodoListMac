import SwiftUI
import SwiftData

/// 第二栏：搜索结果界面（侧边栏输入 -> 此处展示）
/// - 顶部：日期范围 / 所有分类 / 达成状态 / 重置筛选（样式对齐你截图）
/// - 内容：独立的搜索 cell（`TDTaskSearchRowView`），命中高亮用主题色
struct TDTaskSearchView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext

    @ObservedObject private var mainViewModel = TDMainViewModel.shared
    @ObservedObject private var settingManager = TDSettingManager.shared

    @Query private var allTasks: [TDMacSwiftDataListModel]

    @StateObject private var viewModel = TDTaskSearchViewModel()
    @State private var snapshots: [TDTaskSearchViewModel.TaskSnapshot] = []
    @State private var tasksById: [String: TDMacSwiftDataListModel] = [:]

    // MARK: - Filters（对齐截图：日期范围 / 分类 / 达成状态）
    enum DateRangeFilter: Int, CaseIterable, Identifiable {
        case all = 0
        case days7 = 7
        case days30 = 30
        case halfYear = 6
        case oneYear = 1

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .all: return "日期范围"
            case .days7: return "近7天"
            case .days30: return "近30天"
            case .halfYear: return "近半年"
            case .oneYear: return "近1年"
            }
        }

        /// 用于查询：TDCorrectQueryBuilder 里用 0/7/30/6/1 表示
        var queryValue: Int { rawValue }
    }

    enum CompleteFilter: Int, CaseIterable, Identifiable {
        case all = 0
        case completed = 1
        case uncompleted = 2

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .all: return "达成状态"
            case .completed: return "已达成"
            case .uncompleted: return "未达成"
            }
        }
    }

    enum CategoryFilter: Equatable, Identifiable {
        case all
        case uncategorized
        case category(TDSliderBarModel)

        var id: String {
            switch self {
            case .all: return "all"
            case .uncategorized: return "uncategorized"
            case .category(let c): return "cat_\(c.categoryId)"
            }
        }

        var title: String {
            switch self {
            case .all: return "所有分类"
            case .uncategorized: return "未分类"
            case .category(let c): return c.categoryName
            }
        }

        var categoryId: Int? {
            switch self {
            case .all: return nil
            case .uncategorized: return 0
            case .category(let c): return c.categoryId
            }
        }
    }

    @State private var dateRange: DateRangeFilter = .all
    @State private var categoryFilter: CategoryFilter = .all
    @State private var completeFilter: CompleteFilter = .all

    init() {
        let userId = TDUserManager.shared.userId
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && !task.delete
        }
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .reverse),
            SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
        ]
        _allTasks = Query(filter: predicate, sort: sortDescriptors)
    }

    var body: some View {
        let keyword = mainViewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedHits: [(TDTaskSearchViewModel.Hit, TDMacSwiftDataListModel)] = viewModel.hits.compactMap { hit in
            guard let task = tasksById[hit.taskId] else { return nil }
            return (hit, task)
        }

        VStack(spacing: 0) {
            topBar(resultCount: resolvedHits.count, keyword: keyword)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

            Divider()

            if keyword.isEmpty {
                emptyState(icon: "magnifyingglass", title: "请输入关键词搜索", subtitle: "支持中文、拼音、首字母缩写")
            } else if viewModel.isSearching && resolvedHits.isEmpty {
                searchingState
            } else if resolvedHits.isEmpty {
                emptyState(icon: "doc.text.magnifyingglass", title: "未找到相关事件", subtitle: "尝试更换关键词，或调整顶部筛选条件")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(resolvedHits, id: \.0.taskId) { pair in
                            let hit = pair.0
                            let task = pair.1
                            TDTaskSearchRowView(
                                task: task,
                                titleText: hit.titleText,
                                titleMatch: hit.titleMatch,
                                subtitleText: hit.subtitleText,
                                subtitleMatch: hit.subtitleMatch
                            )
                            .environmentObject(themeManager)

                            Divider()
                                .opacity(0.25)
                        }
                    }
                }
                .background(Color(.windowBackgroundColor))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
        .task {
            rebuildIndex()
            refreshSearch()
        }
        .onChange(of: mainViewModel.searchText) { _, _ in
            refreshSearch()
        }
        .onChange(of: dateRange) { _, _ in
            refreshSearch()
        }
        .onChange(of: categoryFilter) { _, _ in
            refreshSearch()
        }
        .onChange(of: completeFilter) { _, _ in
            refreshSearch()
        }
        .onReceive(NotificationCenter.default.publisher(for: .taskDataChanged)) { _ in
            rebuildIndex()
            refreshSearch()
        }
    }

    // MARK: - TopBar

    private func topBar(resultCount: Int, keyword: String) -> some View {
        HStack(spacing: 14) {
            // 日期范围：按 Inbox 顶部菜单样式
            Menu {
                ForEach(DateRangeFilter.allCases) { opt in
                    Button {
                        dateRange = opt
                    } label: {
                        Text(opt.title)
                    }
                }
            } label: {
                topMenuLabel(text: dateRange.title, systemImage: "calendar")
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .pointingHandCursor()

            // 所有分类：复用你写好的 TDCategoryPickerMenu（与 Inbox 一致）
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

            // 达成状态：按 Inbox 顶部菜单样式
            Menu {
                ForEach(CompleteFilter.allCases) { opt in
                    Button {
                        completeFilter = opt
                    } label: {
                        Text(opt.title)
                    }
                }
            } label: {
                topMenuLabel(text: completeFilter.title, systemImage: "checkmark.circle")
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .pointingHandCursor()

            Button {
                resetFilters()
            } label: {
                Text("重置筛选")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeManager.color(level: 5))
            }
            .buttonStyle(.plain)
            .pointingHandCursor()

            Spacer()

            // 右侧“X 条结果”：与顶部一行中心对齐，位置保持最右
            if !keyword.isEmpty {
                Group {
                    if viewModel.isSearching {
                        Text("搜索中…")
                    } else {
                        Text("\(resultCount) 条结果")
                    }
                }
                .font(.system(size: 13))
                .foregroundColor(themeManager.descriptionTextColor)
            }
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
                .opacity(0) // 仅占位，避免 label 变化导致跳动（与 Inbox 一致）
        }
    }

    private func resetFilters() {
        dateRange = .all
        categoryFilter = .all
        completeFilter = .all
    }

    // MARK: - Suggestion

    // MARK: - Category menu bridge (TDCategoryPickerMenu)

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

    // MARK: - Search plumbing (debounced + background)

    private func rebuildIndex() {
        // 把 SwiftData 模型转成轻量 snapshot（可用于后台计算），避免在输入时遍历 Model/触发主线程卡顿
        var dict: [String: TDMacSwiftDataListModel] = [:]
        dict.reserveCapacity(allTasks.count)

        var snaps: [TDTaskSearchViewModel.TaskSnapshot] = []
        snaps.reserveCapacity(allTasks.count)

        for t in allTasks {
            dict[t.taskId] = t
            snaps.append(
                TDTaskSearchViewModel.TaskSnapshot(
                    taskId: t.taskId,
                    title: t.taskContent,
                    desc: t.taskDescribe ?? "",
                    subtasks: t.subTaskList.map(\.content),
                    todoTime: t.todoTime,
                    standbyInt1: t.standbyInt1,
                    complete: t.complete
                )
            )
        }

        tasksById = dict
        snapshots = snaps
    }

    private func refreshSearch() {
        let f = TDTaskSearchViewModel.Filters(
            dateRangeRaw: dateRange.queryValue,
            categoryId: categoryFilter.categoryId,
            completeFilterRaw: completeFilter.rawValue
        )
        viewModel.update(keyword: mainViewModel.searchText, snapshots: snapshots, filters: f)
    }

    // MARK: - Empty

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(themeManager.descriptionTextColor.opacity(0.8))
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.titleTextColor)
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(themeManager.descriptionTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }

    private var searchingState: some View {
        VStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.9)
            Text("正在搜索…")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.titleTextColor)
            Text("支持中文、拼音、首字母缩写")
                .font(.system(size: 12))
                .foregroundColor(themeManager.descriptionTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

