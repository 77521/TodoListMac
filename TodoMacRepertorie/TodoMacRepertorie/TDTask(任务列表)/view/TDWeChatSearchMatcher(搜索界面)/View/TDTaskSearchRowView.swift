import SwiftUI
import SwiftData

/// 搜索结果行（独立 cell，不复用最近待办列表行）
/// - 视觉对齐你截图：左侧勾选/多选圆圈 + 标题 + 描述(或子任务) + 右侧日期
/// - 命中高亮：主题色 level 5
struct TDTaskSearchRowView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext

    @ObservedObject private var mainViewModel = TDMainViewModel.shared
    @ObservedObject private var settingManager = TDSettingManager.shared

    let task: TDMacSwiftDataListModel

    let titleText: String
    let titleMatch: TDWeChatSearchMatcher.MatchResult?

    let subtitleText: String?
    let subtitleMatch: TDWeChatSearchMatcher.MatchResult?

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // 难度指示条（与列表保持一致）
            RoundedRectangle(cornerRadius: 1.5)
                .fill(task.difficultyColor)
                .frame(width: 3)
                .padding(.vertical, 2)
                .padding(.leading, 1)
                .frame(maxHeight: .infinity)

            HStack(alignment: .top, spacing: 12) {
                checkButton
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    // 标题（高亮）
                    Text(
                        TDWeChatSearchMatcher.highlightedAttributedString(
                            text: titleText,
                            match: titleMatch,
                            normalColor: task.taskTitleColor,
                            highlightColor: themeManager.color(level: 5)
                        )
                    )
                    .font(.system(size: 14))
                    .lineLimit(settingManager.taskTitleLines)
                    .strikethrough(task.complete ? settingManager.showCompletedTaskStrikethrough : false)
                    .opacity(task.complete ? 0.6 : 1.0)

                    // 描述 / 子任务（高亮）
                    if settingManager.showTaskDescription, let subtitleText, !subtitleText.isEmpty {
                        Text(
                            TDWeChatSearchMatcher.highlightedAttributedString(
                                text: subtitleText,
                                match: subtitleMatch,
                                normalColor: themeManager.descriptionTextColor,
                                highlightColor: themeManager.color(level: 5)
                            )
                        )
                        .font(.system(size: 13))
                        .lineLimit(settingManager.taskDescriptionLines)
                        .opacity(task.complete ? 0.7 : 1.0)
                    }
                }

                Spacer(minLength: 12)

                // 右侧日期（与列表一致）
                if !task.taskDateConditionalString.isEmpty {
                    Text(task.taskDateConditionalString)
                        .font(.system(size: 11))
                        .foregroundColor(task.taskDateColor)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(backgroundColor)
        .contentShape(Rectangle())
        .onTapGesture {
            if mainViewModel.isMultiSelectMode {
                toggleSelection()
            } else {
                mainViewModel.selectTask(task)
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var backgroundColor: Color {
        if mainViewModel.selectedTask?.taskId == task.taskId {
            return themeManager.color(level: 1).opacity(0.2)
        }
        if isHovered {
            return themeManager.secondaryBackgroundColor.opacity(0.3)
        }
        return themeManager.backgroundColor
    }

    private var checkButton: some View {
        Button {
            if mainViewModel.isMultiSelectMode {
                toggleSelection()
            } else {
                toggleTaskCompletion()
            }
        } label: {
            ZStack {
                if mainViewModel.isMultiSelectMode {
                    Circle()
                        .stroke(themeManager.color(level: 5), lineWidth: 1.5)
                        .frame(width: 18, height: 18)

                    if mainViewModel.selectedTasks.contains(where: { $0.taskId == task.taskId }) {
                        Circle()
                            .fill(themeManager.color(level: 5))
                            .frame(width: 18, height: 18)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(task.checkboxColor, lineWidth: 1.5)
                        .frame(width: 18, height: 18)

                    if task.complete {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(task.checkboxColor)
                            .frame(width: 18, height: 18)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
    }

    private func toggleSelection() {
        let isSelected = mainViewModel.selectedTasks.contains { $0.taskId == task.taskId }
        mainViewModel.updateSelectedTask(task: task, isSelected: !isSelected)
    }

    private func toggleTaskCompletion() {
        Task {
            if !task.complete {
                TDAudioManager.shared.playCompletionSound()
            }
            do {
                let updatedTask = task
                updatedTask.complete = !task.complete

                let result = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(
                    updatedTask: updatedTask,
                    context: modelContext
                )
                if result == .updated {
                    await TDMainViewModel.shared.performSyncSeparately()
                }
            } catch {
                print("搜索行：切换任务状态失败 \(error)")
            }
        }
    }
}

