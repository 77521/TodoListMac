//
//  TDWeekdaySelectorView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/1/21.
//

import SwiftUI

/// 周选择器视图
/// 用于选择每周的哪几天重复
struct TDWeekdaySelectorView: View {
    
    // MARK: - 数据绑定
    @EnvironmentObject private var themeManager: TDThemeManager  // 主题管理器
    @Binding var selectedWeekdays: Set<Int>  // 选中的星期几（1-7，1=周日，7=周六）
    
    // MARK: - 参数
    let taskTodoTime: Int64  // 任务的todoTime（时间戳）
    
    // MARK: - 初始化方法
    init(selectedWeekdays: Binding<Set<Int>>, taskTodoTime: Int64) {
        self._selectedWeekdays = selectedWeekdays
        self.taskTodoTime = taskTodoTime
    }
    
    // MARK: - 私有属性
    private let weekdays: [(Int, String, String)] = [
        (1, "日", "Sun"),
        (2, "一", "Mon"),
        (3, "二", "Tue"),
        (4, "三", "Wed"),
        (5, "四", "Thu"),
        (6, "五", "Fri"),
        (7, "六", "Sat")
    ]
    
    // MARK: - 主视图
    var body: some View {
        HStack(spacing: 8) {
                ForEach(getOrderedWeekdays(), id: \.0) { weekday in
                    Button(action: {
                        toggleWeekday(weekday.0)
                    }) {
                        Text(weekday.1)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedWeekdays.contains(weekday.0) ? .white : themeManager.color(level: 5))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(selectedWeekdays.contains(weekday.0) ? themeManager.color(level: 5) : themeManager.secondaryBackgroundColor)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
        }
        .onAppear {
            // 如果selectedWeekdays为空，则设置默认值
            if selectedWeekdays.isEmpty {
                let taskDate = Date.fromTimestamp(taskTodoTime)
                let calendar = Calendar.current
                let weekday = calendar.component(.weekday, from: taskDate)
                // Calendar.weekday: 1=周日, 2=周一, ..., 7=周六
                // 我们的格式: 1=周日, 2=周一, ..., 7=周六
                // 所以直接使用calendar的weekday值即可
                selectedWeekdays = [weekday]
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 获取排序后的星期数组
    /// 根据设置决定是周一开始还是周日开始
    private func getOrderedWeekdays() -> [(Int, String, String)] {
        if TDSettingManager.shared.isFirstDayMonday {
            // 周一开始：周一(2) 到 周日(1)
            return Array(weekdays[1...6]) + [weekdays[0]]
        } else {
            // 周日开始：周日(1) 到 周六(7)
            return weekdays
        }
    }
    
    /// 获取选中的星期文本
    private func getSelectedWeekdayText() -> String {
        if selectedWeekdays.count == 7 {
            return "weekday.everyday".localized
        } else if selectedWeekdays.count == 1 {
            let weekday = selectedWeekdays.first!
            return getWeekdayName(weekday)
        } else {
            let sortedWeekdays = selectedWeekdays.sorted()
            let weekdayNames = sortedWeekdays.map { getWeekdayName($0) }
            return weekdayNames.joined(separator: "、")
        }
    }
    
    /// 获取星期名称
    private func getWeekdayName(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "weekday.sunday".localized
        case 2: return "weekday.monday".localized
        case 3: return "weekday.tuesday".localized
        case 4: return "weekday.wednesday".localized
        case 5: return "weekday.thursday".localized
        case 6: return "weekday.friday".localized
        case 7: return "weekday.saturday".localized
        default: return ""
        }
    }
    
    /// 切换星期选择
    private func toggleWeekday(_ weekday: Int) {
        if selectedWeekdays.contains(weekday) {
            // 如果只剩一个选择，不能取消
            if selectedWeekdays.count > 1 {
                selectedWeekdays.remove(weekday)
            }
        } else {
            selectedWeekdays.insert(weekday)
        }
    }
}

// MARK: - 预览
#Preview {
    TDWeekdaySelectorView(selectedWeekdays: .constant([]), taskTodoTime: Date().startOfDayTimestamp)
        .environmentObject(TDThemeManager.shared)
}
