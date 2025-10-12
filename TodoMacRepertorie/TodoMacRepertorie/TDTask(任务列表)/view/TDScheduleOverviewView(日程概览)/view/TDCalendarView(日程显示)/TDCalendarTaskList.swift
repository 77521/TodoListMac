//
//  TDCalendarTaskList.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/11.
//

import SwiftUI

/// 日历任务列表组件
struct TDCalendarTaskList: View {
    /// 任务列表
    let tasks: [TDMacSwiftDataListModel]
    /// 单元格宽度
    let cellWidth: CGFloat
    /// 单元格高度
    let cellHeight: CGFloat
    /// 最大显示任务数量
    let maxTasks: Int
    /// 设置管理器
    @EnvironmentObject private var settingManager: TDSettingManager
    /// 主题管理器
    @EnvironmentObject private var themeManager: TDThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            // 根据设置决定显示逻辑
            if settingManager.calendarShowRemainingCount && tasks.count > maxTasks {
                // 显示剩余数量：显示前(maxTasks-1)个任务 + 剩余数量提示
                let displayTasks = min(maxTasks - 1, tasks.count)
                let remainingCount = tasks.count - displayTasks - 1
                
                // 显示任务
                ForEach(Array(tasks.prefix(displayTasks).enumerated()), id: \.offset) { index, task in
                    Text(truncateText(task.taskContent))
                        .font(.system(size: settingManager.fontSize.size))
                        .foregroundColor(getTaskTextColor(task: task))
                        .strikethrough(task.complete && settingManager.calendarShowCompletedSeparator)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 1)
//                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(getTaskBackgroundColor(task: task))
                        )
                        .onTapGesture {
                            print("点击了任务: \(task.taskContent)")
                        }
                }
                
                // 显示剩余数量
                if remainingCount > 0 {
                    Text("+\(remainingCount)")
                        .font(.system(size: settingManager.fontSize.size))
                        .foregroundColor(themeManager.color(level: 5))
                }
            } else {
                // 不显示剩余数量：显示所有可显示的任务
                ForEach(Array(tasks.prefix(maxTasks).enumerated()), id: \.offset) { index, task in
                    Text(truncateText(task.taskContent))
                        .font(.system(size: settingManager.fontSize.size))
                        .foregroundColor(getTaskTextColor(task: task))
                        .strikethrough(task.complete && settingManager.calendarShowCompletedSeparator)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 1)
//                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(getTaskBackgroundColor(task: task))
                        )
                        .onTapGesture {
                            print("点击了任务: \(task.taskContent)")
                        }
                }
            }
        }
    }
    
    // MARK: - 文本截断方法
    
    /// 截断文本 - 根据隐私保护模式处理
    /// - Parameters:
    ///   - text: 原始文本
    /// - Returns: 处理后的文本
    private func truncateText(_ text: String) -> String {
        let maxChars = maxCharsPerLine()
        if settingManager.isPrivacyModeEnabled {
            // 隐私保护模式：显示第一个字符，其余用*号
            if text.count <= 1 {
                return text
            } else {
                let firstChar = String(text.prefix(1))
                // 确保至少显示一个字符，其余用*号填充到最大字符数
                let remainingChars = max(1, maxChars - 1) // 至少保留1个字符位置
                let asterisks = String(repeating: "*", count: min(text.count - 1, remainingChars))
                return firstChar + asterisks
            }
        } else {
            // 正常模式：根据长度截断
            if text.count <= maxChars {
                return text
            }
            return String(text.prefix(maxChars))
        }
    }
    
    /// 计算每行任务的最大字符数（根据设置内的字体大小动态计算）
    private func maxCharsPerLine() -> Int {
        // 使用传入的宽度
        let actualWidth = cellWidth
        // 减去左右间距（各1pt）
        let availableWidth = actualWidth - 2
        // 根据字体大小计算字符宽度
        let fontSize = settingManager.fontSize.size
        // 中文字符宽度约为字体大小的1.0倍，英文字符约为字体大小的0.6倍，取平均值
        let avgCharWidth = fontSize // 平均字符宽度
        let maxChars = Int(availableWidth / avgCharWidth) - 1
        return maxChars
    }
    
    
    // MARK: - 任务颜色方法
    
    /// 获取任务文字颜色
    /// - Parameter task: 任务对象
    /// - Returns: 文字颜色
    private func getTaskTextColor(task: TDMacSwiftDataListModel) -> Color {
        // 根据背景模式判断
        switch settingManager.calendarTaskBackgroundMode {
        case .workload:
            // 事件工作量模式：根据工作量设置颜色
            return getWorkloadTextColor(task: task)
        case .category:
            // 清单颜色模式：根据清单设置颜色
            return getCategoryTextColor(task: task)
        }
    }
    
    /// 获取工作量模式的文字颜色
    /// - Parameter task: 任务对象
    /// - Returns: 文字颜色
    private func getWorkloadTextColor(task: TDMacSwiftDataListModel) -> Color {
        if task.complete {
            return themeManager.descriptionTextColor
        } else {
            return themeManager.titleTextColor
        }
    }
    
    /// 获取清单模式的文字颜色
    /// - Parameter task: 任务对象
    /// - Returns: 文字颜色
    private func getCategoryTextColor(task: TDMacSwiftDataListModel) -> Color {
        // 检查是否有清单ID
        if task.standbyInt1 > 0 {
            // 有清单：根据设置判断颜色识别方式
            switch settingManager.calendarTaskColorRecognition {
            case .auto:
                // 自动识别：使用清单颜色的反色
                let categoryColor = Color.fromHex(task.standbyIntColor)
                if categoryColor.isLight() {
                    // 浅色背景：使用更暗的颜色作为文字
                    return categoryColor.darkened(amount: 1.0)
                } else {
                    // 深色背景：使用更亮的颜色作为文字
                    return categoryColor.lighter(amount: 0.75)
                }
            case .black:
                // 强制黑色
                return .black
            case .white:
                // 强制白色
                return .white
            }
        } else {
            // 没有清单：使用默认颜色
            if task.complete {
                return themeManager.descriptionTextColor
            } else {
                return themeManager.titleTextColor
            }
        }
    }

    /// 获取任务背景颜色
    /// - Parameter task: 任务对象
    /// - Returns: 背景颜色
    private func getTaskBackgroundColor(task: TDMacSwiftDataListModel) -> Color {
        // 根据背景模式判断
        switch settingManager.calendarTaskBackgroundMode {
        case .workload:
            // 事件工作量模式：根据工作量设置背景色
            return getWorkloadBackgroundColor(task: task)
        case .category:
            // 清单颜色模式：根据清单设置背景色
            return getCategoryBackgroundColor(task: task)
        }
    }
    
    /// 获取工作量模式的背景颜色
    /// - Parameter task: 任务对象
    /// - Returns: 背景颜色
    private func getWorkloadBackgroundColor(task: TDMacSwiftDataListModel) -> Color {
        let workload = task.snowAssess
        
        if workload < 5 {
            return themeManager.tertiaryBackgroundColor
        } else if workload < 9 {
            return TDThemeManager.shared.fixedColor(themeId: "wish_orange", level: 3) // 心想事橙，6级
        } else {
            return TDThemeManager.shared.fixedColor(themeId: "new_year_red", level: 3) // 新年红，6级
        }
    }
    
    /// 获取清单模式的背景颜色
    /// - Parameter task: 任务对象
    /// - Returns: 背景颜色
    private func getCategoryBackgroundColor(task: TDMacSwiftDataListModel) -> Color {
        // 检查是否有清单颜色
        if task.standbyInt1 > 0 {
            return Color.fromHex(task.standbyIntColor)
        } else {
            // 没有清单颜色：使用三级背景色
            return themeManager.tertiaryBackgroundColor
        }
    }

}

// MARK: - 预览
#Preview {
    TDCalendarTaskList(
        tasks: [],
        cellWidth: 100,
        cellHeight: 100,
        maxTasks: 5
    )
    .environmentObject(TDSettingManager.shared)
    .environmentObject(TDThemeManager.shared)
}
