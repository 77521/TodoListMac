//
//  TDCompletedDeletedView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData

/// 回收站界面（第二列）
/// 说明：
/// - 严格按截图样式：顶部“回收站 + 清空”，列表行展示恢复按钮
/// - 列表行本身不提供点击事件（不进入详情、不选中任务）
struct TDCompletedDeletedView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    
    let category: TDSliderBarModel
    
    @ObservedObject private var mainViewModel = TDMainViewModel.shared
    
    // MARK: - Data
    @State private var tasks: [TDMacSwiftDataListModel] = []
    @State private var isLoading: Bool = true
    
    // MARK: - UI State
    @State private var showClearConfirm: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var datePickerTask: TDMacSwiftDataListModel?
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if tasks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks, id: \.taskId) { task in
                            TDTrashRowView(
                                task: task,
                                dateBadgeText: dateBadgeText(for: task),
                                dateBadgeColor: dateBadgeColor(for: task),
                                onRestoreOriginalDate: { restore(task: task, to: task.todoTime) },
                                onRestoreToday: { restore(task: task, to: Date().startOfDayTimestamp) },
                                onPickDate: { presentDatePicker(for: task) },
                                showDatePicker: $showDatePicker,
                                datePickerTaskId: datePickerTask?.taskId,
                                selectedDate: $selectedDate,
                                onDateSelected: { date in
                                    restore(task: task, to: date.startOfDayTimestamp)
                                }
                            )
                            
                            Rectangle()
                                .fill(themeManager.separatorColor)
                                .frame(height: 1)
                                .opacity(0.9)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .background(Color(.windowBackgroundColor))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
        .task { await reload() }
        .confirmationDialog(
            "trash.clear.confirm.title".localized,
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("trash.clear.action".localized, role: .destructive) {
                Task { await clearTrash() }
            }
            Button("common.cancel".localized, role: .cancel) { }
        } message: {
            Text("trash.clear.confirm.message".localized)
        }
    }
}

// MARK: - Top Bar
private extension TDCompletedDeletedView {
    var headerView: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: category.headerIcon ?? "trash")
                    .foregroundColor(.red)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(category.categoryName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.titleTextColor)
            }
            
            Spacer(minLength: 0)
            
            Button {
                showClearConfirm = true
            } label: {
                Text("trash.clear.button".localized)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .disabled(tasks.isEmpty)
            .opacity(tasks.isEmpty ? 0.4 : 1.0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 14)
        .background(Color(.windowBackgroundColor))
        .shadow(color: .black.opacity(0.10), radius: 2, x: 0, y: 1)
        .zIndex(10)
    }
}

// MARK: - Empty
private extension TDCompletedDeletedView {
    var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "trash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("trash.empty.title".localizedFormat(category.categoryName))
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("trash.empty.subtitle".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 50)
    }
}

// MARK: - Actions & Data
private extension TDCompletedDeletedView {
    func reload() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let descriptor = TDCorrectQueryBuilder.getDeletedTasksFetchDescriptor()
            tasks = try modelContext.fetch(descriptor)
        } catch {
            tasks = []
            print("❌ 回收站数据加载失败: \(error)")
        }
    }
    
    func clearTrash() async {
        guard !tasks.isEmpty else { return }
        do {
            for t in tasks {
                modelContext.delete(t)
            }
            try modelContext.save()
            await mainViewModel.performSyncSeparately()
            await reload()
        } catch {
            print("❌ 清空回收站失败: \(error)")
        }
    }
    
    func presentDatePicker(for task: TDMacSwiftDataListModel) {
        datePickerTask = task
        selectedDate = Date()
        showDatePicker = true
    }
    
    func restore(task: TDMacSwiftDataListModel, to todoTime: Int64) {
        Task {
            do {
                let updatedTask = task
                updatedTask.delete = false
                updatedTask.status = "update"
                
                if updatedTask.todoTime != todoTime {
                    updatedTask.todoTime = todoTime
                    updatedTask.taskSort = try await computeTaskSortForMove(to: todoTime)
                }
                
                _ = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(
                    updatedTask: updatedTask,
                    context: modelContext
                )
                
                await mainViewModel.performSyncSeparately()
                await reload()
            } catch {
                print("❌ 回收站恢复失败: \(error)")
            }
        }
    }
    
    func computeTaskSortForMove(to todoTime: Int64) async throws -> Decimal {
        let maxSort = try await TDQueryConditionManager.shared.getMaxTaskSortForDate(
            todoTime: todoTime,
            context: modelContext
        )
        if maxSort == 0 {
            return TDAppConfig.defaultTaskSort
        }
        return maxSort + TDAppConfig.randomTaskSort()
    }
}

// MARK: - Date Badge
private extension TDCompletedDeletedView {
    func dateBadgeText(for task: TDMacSwiftDataListModel) -> String {
        if task.todoTime == 0 {
            return "no_date".localized
        }
        let date = Date.fromTimestamp(task.todoTime)
        let base = date.isToday ? "today".localized : date.dateAndWeekString
        if task.todoTime < Date().startOfDayTimestamp {
            return "trash.badge.overdue_prefix".localizedFormat(base)
        }
        return base
    }
    
    func dateBadgeColor(for task: TDMacSwiftDataListModel) -> Color {
        if task.todoTime != 0, task.todoTime < Date().startOfDayTimestamp {
            return themeManager.fixedColor(themeId: "new_year_red", level: 5)
        }
        return themeManager.descriptionTextColor
    }
}

// MARK: - Row UI
private struct TDTrashRowView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    
    let task: TDMacSwiftDataListModel
    let dateBadgeText: String
    let dateBadgeColor: Color
    
    let onRestoreOriginalDate: () -> Void
    let onRestoreToday: () -> Void
    let onPickDate: () -> Void
    
    // 只让“当前行”的【选择日期】按钮承载 popover（锚点才会贴着按钮）
    @Binding var showDatePicker: Bool
    let datePickerTaskId: String?
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    private var isRowDatePickerPresented: Binding<Bool> {
        Binding(
            get: { showDatePicker && datePickerTaskId == task.taskId },
            set: { newValue in
                // 关闭时只需要把总开关关掉即可
                if !newValue { showDatePicker = false }
            }
        )
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text(task.taskContent)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.titleTextColor)
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    TDTrashActionButton(title: "trash.action.restore_original".localized, action: onRestoreOriginalDate)
                    TDTrashActionButton(title: "trash.action.restore_today".localized, action: onRestoreToday)
                    TDTrashActionButton(title: "trash.action.pick_date".localized, action: onPickDate)
                        .popover(isPresented: isRowDatePickerPresented, arrowEdge: .top) {
                            TDCustomDatePickerView(
                                selectedDate: $selectedDate,
                                isPresented: isRowDatePickerPresented,
                                onDateSelected: { date in
                                    onDateSelected(date)
                                }
                            )
                            .frame(width: 280, height: 320)
                        }
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(dateBadgeText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(dateBadgeColor)
                .fixedSize(horizontal: true, vertical: false)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.windowBackgroundColor))
        // 关键：整行没有点击事件（只允许按钮交互）
        .contentShape(Rectangle())
    }
}

private struct TDTrashActionButton: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.color(level: 5))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(themeManager.color(level: 5).opacity(0.12))
                )
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
    }
}

#Preview {
    TDCompletedDeletedView(category: TDSliderBarModel(
        categoryId: -107,
        categoryName: "最近已完成",
        headerIcon: "checkmark.circle",
        categoryColor: nil,
        unfinishedCount: 0,
        isSelect: false
    ))
    .environmentObject(TDThemeManager.shared)
}
