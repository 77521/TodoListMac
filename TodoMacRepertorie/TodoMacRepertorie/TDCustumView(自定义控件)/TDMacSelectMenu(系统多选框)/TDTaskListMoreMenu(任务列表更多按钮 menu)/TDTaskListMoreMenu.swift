//
//  TDTaskListMoreMenu.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/2/1.
//

import SwiftUI

/// 任务列表“更多”菜单（用于输入框右侧）
/// 参考：截图 2
struct TDTaskListMoreMenu: View {
    @ObservedObject private var themeManager = TDThemeManager.shared
    @ObservedObject private var settingManager = TDSettingManager.shared

    /// 当前排序方式的文案（用于展示在“排序（xxx）”里）
    private var sortTitle: String {
        switch settingManager.taskListSortType {
        case 1: return "task.list.sort.reminder_time".localized
        case 2: return "task.list.sort.create_time_asc".localized
        case 3: return "task.list.sort.create_time_desc".localized
        case 4: return "task.list.sort.workload_asc".localized
        case 5: return "task.list.sort.workload_desc".localized
        default: return "task.list.sort.custom".localized
        }
    }

    var body: some View {
        Menu {
            // 1) 排序：子菜单
            Menu("task.list.more.sort.menu".localizedFormat(sortTitle)) {
                // 1.1 自定义排序（taskSort）
                sortItem(title: "task.list.sort.custom".localized, sortType: 0)
                // 1.2 提醒时间排序
                sortItem(title: "task.list.sort.reminder_time".localized, sortType: 1)
                // 1.3 添加时间（早→晚）
                sortItem(title: "task.list.sort.create_time_asc".localized, sortType: 2)
                // 1.4 添加时间（晚→早）
                sortItem(title: "task.list.sort.create_time_desc".localized, sortType: 3)
                // 1.5 工作量（少→多）
                sortItem(title: "task.list.sort.workload_asc".localized, sortType: 4)
                // 1.6 工作量（多→少）
                sortItem(title: "task.list.sort.workload_desc".localized, sortType: 5)
            }

            Divider()

            // 2) 显示设置：是否显示已完成
            toggleItem(
                title: "task.list.more.show_completed".localized,
                isOn: settingManager.showCompletedTasks,
                onToggle: { settingManager.showCompletedTasks.toggle() }
            )

            // 3) 显示设置：勾选框是否跟随清单颜色
            toggleItem(
                title: "task.list.more.checkbox_follow_category_color".localized,
                isOn: settingManager.checkboxFollowCategoryColor,
                onToggle: { settingManager.checkboxFollowCategoryColor.toggle() }
            )

            Divider()

            // 4) 打印（当前暂未接入，先置灰）
            Button(action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: "printer")
                        .font(.system(size: TDAppConfig.menuIconSize))
                        .foregroundColor(.secondary)
                    Text("task.list.more.print_current_list".localized)
                        .font(.system(size: TDAppConfig.menuFontSize))
                }
            }
            .disabled(true)

            // 5) 更多事件设置（后续接入设置页）
            Button(action: {
                // TODO: 后续接入“事件设置”入口（目前仅保留菜单占位）
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape")
                        .font(.system(size: TDAppConfig.menuIconSize))
                        .foregroundColor(.secondary)
                    Text("task.list.more.event_settings".localized)
                        .font(.system(size: TDAppConfig.menuFontSize))
                }
            }
        } label: {
            // 右侧按钮样式：三个点（隐藏系统默认 menu 指示器）
            Image(systemName: "ellipsis.circle")
                .foregroundColor(themeManager.titleTextColor)
                .font(.system(size: 18))
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }

    // MARK: - Builders

    /// 构建排序项（右侧显示对勾）
    private func sortItem(title: String, sortType: Int) -> some View {
        Button(action: {
            // 修改排序方式：会触发 @Query 重建，从而刷新列表
            settingManager.taskListSortType = sortType
        }) {
            HStack {
                Text(title)
                    .font(.system(size: TDAppConfig.menuFontSize))
                Spacer()
                if settingManager.taskListSortType == sortType {
                    Image(systemName: "checkmark")
                        .font(.system(size: TDAppConfig.menuIconSize))
                        .foregroundColor(themeManager.color(level: 5))
                }
            }
        }
    }

    /// 构建开关项（左侧显示勾选框）
    private func toggleItem(title: String, isOn: Bool, onToggle: @escaping () -> Void) -> some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: isOn ? "checkmark.square" : "square")
                    .font(.system(size: TDAppConfig.menuIconSize))
                    .foregroundColor(themeManager.color(level: 5))
                Text(title)
                    .font(.system(size: TDAppConfig.menuFontSize))
            }
        }
    }
}


