//
//  TDRecentCompletedView.swift
//  TodoMacRepertorie
//
//  Created by Assistant on 2026/3/8.
//

import SwiftUI
import SwiftData

/// 最近已完成界面（第二栏独立页面）
/// 你要求的规则（逐条写清楚，方便后续维护）：
/// 1) 数据范围：包含今天在内的最近 30 天（不包含明天/后天/后续日程/无日期）
/// 2) 数量上限：最多展示 300 条（避免历史过多导致列表卡顿）
/// 3) 分组方式：按日期（todoTime 的“当天”）分组，从近到远排序
/// 4) 交互：点击事件与 DayTodo/最近待办一致（复用 `TDTaskRowView` 的点击逻辑）
/// 5) 标题右上角：鼠标悬停显示提示弹窗（文案按截图 + 国际化）
struct TDRecentCompletedView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @ObservedObject private var mainViewModel = TDMainViewModel.shared

    let category: TDSliderBarModel

    // 说明：最近已完成只需要一条 Query（避免多次查询造成切换卡顿）
    @Query private var tasks: [TDMacSwiftDataListModel]

    // MARK: - UI State
    @State private var showInfoPopover: Bool = false

    init(category: TDSliderBarModel) {
        self.category = category
        
        // 说明：所有查询逻辑统一收敛到 TDCorrectQueryBuilder
        // - 如果未来你觉得范围/排序不对，只改 builder，所有使用方会一起生效
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getRecentCompletedQuery(days: 30)
        _tasks = Query(filter: predicate, sort: sortDescriptors)
    }

    var body: some View {
        let limited = Array(tasks.prefix(300))
        let rows = buildRows(from: limited)

        VStack(spacing: 0) {
            headerView

            if rows.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // 你要求：最近已完成“不需要分组头”
                            // - 但仍需要按日期做“右侧日期标签”显示（与复选框居中对齐、距右 10pt）
                            ForEach(rows.indices, id: \.self) { idx in
                                let row = rows[idx]
                                TDRecentCompletedRow(
                                    task: row.task,
                                    category: category,
                                    showDateBadge: row.showDateBadge,
                                    dateBadgeTimestamp: row.dayStartTimestamp
                                )
                                .id(row.task.taskId)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .onAppear {
                        // 说明：保持第二栏列表与第三栏详情联动体验一致（选中任务时自动滚到可见位置）
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Top Bar
    /// 顶部 Header（独立 View + 底部黑色阴影）
    /// 你要求：
    /// - 顶部放在一个 view 内
    /// - 底部要有黑色阴影
    private var headerView: some View {
        topBar
            // 你要求：标题文案离最左边 10pt
            .padding(.horizontal, 10)
            .padding(.vertical, 14)
            .background(Color(.windowBackgroundColor))
            // 你要求：顶部阴影仿照 DayTodo 顶部（轻阴影、下方投影）
            .shadow(color: .black.opacity(0.10), radius: 2, x: 0, y: 1)
            .zIndex(10) // 确保阴影盖在列表上方
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: category.headerIcon ?? "checkmark.square")
                    .foregroundColor(themeManager.color(level: 5))
                    .font(.system(size: 14, weight: .semibold))

                Text("recent_completed.title".localized)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.titleTextColor)

                // 说明：你要的“标题右上角提示弹窗（鼠标悬停显示）”
                // - 这里用 popover 的原因：支持多行、样式更接近截图的气泡
                // - 规则：只在 hover 时显示，不点击
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.descriptionTextColor)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.12)) {
                            showInfoPopover = hovering
                        }
                    }
                    .popover(isPresented: $showInfoPopover, arrowEdge: .top) {
                        Text("recent_completed.tooltip".localized)
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.titleTextColor)
                            .multilineTextAlignment(.leading)
                            .padding(12)
                            .frame(width: 300, alignment: .leading)
                    }
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Empty
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("recent_completed.empty.title".localized)
                .font(.headline)
                .foregroundColor(.secondary)

            Text("recent_completed.empty.subtitle".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 50)
    }
}

// MARK: - Date Sections

private extension TDRecentCompletedView {
    /// 列表行渲染模型（避免 UI 内部反复计算“是否首条日期”）
    struct TDRowRenderModel {
        let task: TDMacSwiftDataListModel
        let dayStartTimestamp: Int64
        let showDateBadge: Bool
    }

    /// 你要求：不显示分组头，但“每一条”都需要在右侧显示日期（今天显示“今天”）
    func buildRows(from tasks: [TDMacSwiftDataListModel]) -> [TDRowRenderModel] {
        tasks.map { task in
            let dayStart = Date.fromTimestamp(task.todoTime).startOfDayTimestamp
            return TDRowRenderModel(task: task, dayStartTimestamp: dayStart, showDateBadge: true)
        }
    }
}

// MARK: - Row Wrapper（右侧日期标签）

/// 最近已完成：单行包装（在行右侧叠加“日期 + 周几”标签）
private struct TDRecentCompletedRow: View {
    @EnvironmentObject private var themeManager: TDThemeManager

    let task: TDMacSwiftDataListModel
    let category: TDSliderBarModel
    let showDateBadge: Bool
    let dateBadgeTimestamp: Int64

    var body: some View {
        let date = Date.fromTimestamp(dateBadgeTimestamp)
        let badgeText: String? = showDateBadge ? (date.isToday ? "today".localized : date.dateAndWeekString) : nil
        let badgeRole: TDTaskRowRightBadgeColorRole? = {
            guard showDateBadge else { return nil }
            if date.isToday { return .themeLevel5 }
            if date.isOverdue { return .newYearRedLevel5 }
            return .titleText
        }()

        TDTaskRowView(
            task: task,
            category: category,
            orderNumber: nil,
            isFirstRow: false,
            isLastRow: false,
            // 你要求：右侧已经显示日期，所以行内不再显示日期文字行
            showInlineDate: false,
            // 你要求：日期与完成按钮同一层级，且只显示一次（由 showDateBadge 控制）
            rightBadgeText: badgeText,
            rightBadgeColorRole: badgeRole,
            onCopySuccess: {
                // 说明：与其它列表保持一致，复制成功走统一 Toast
                TDToastCenter.shared.show(
                    "copy_success_simple",
                    type: .success,
                    position: .bottom
                )
            },
            onEnterMultiSelect: { }
        )
    }

    /// 颜色规则（按你要求写死）
    /// - 今天：主题色 5 级（列表里已隐藏今天标签，这里仍保底）
    /// - 过期：新年红 5 级
    /// - 其它：标题字体颜色
    private func displayColor(for date: Date) -> Color {
        if date.isToday {
            return themeManager.color(level: 5)
        }
        if date.isOverdue {
            return themeManager.fixedColor(themeId: "new_year_red", level: 5)
        }
        return themeManager.titleTextColor
    }
}

#Preview {
    TDRecentCompletedView(category: TDSliderBarModel(categoryId: -107, categoryName: "最近已完成", headerIcon: "checkmark.square", unfinishedCount: 0))
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDMainViewModel.shared)
}

