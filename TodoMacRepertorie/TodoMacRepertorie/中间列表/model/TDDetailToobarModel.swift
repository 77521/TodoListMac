//
//  TDDetailToobarModel.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/20.
//

import Foundation
import SwiftDate
import SwiftUI
import Combine

class DateNavigationViewModel: ObservableObject {
    @Published var selectedDate: DateInRegion
    @ObservedObject private var settings = TDAppSettings.shared
    private var cancellables = Set<AnyCancellable>()
    
    private var today: DateInRegion {
        DateInRegion()
    }
    
    init() {
        self.selectedDate = DateInRegion()
        // 监听设置变化
        // 监听 settings 的变化
        settings.objectWillChange
            .sink { [weak self] _ in
                // 当设置改变时重新加载日期数据
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func datesOfWeek() -> [TDDetailDateModel] {
        // 获取当前周的第一天
        let calendar = SwiftDate.defaultRegion.calendar
        let weekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate.date)
        )?.in(region: .current) ?? selectedDate
        
        return (0...6).map { dayOffset in
            let date = weekStart + dayOffset.days
            return TDDetailDateModel(
                date: date,
                isSelected: date.compare(.isSameDay(selectedDate))
            )
        }
    }
    
    func moveWeek(by weeks: Int) {
        // 先获取当前选中日期所在周的第一天
        let calendar = SwiftDate.defaultRegion.calendar
        let currentWeekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate.date)
        )?.in(region: .current) ?? selectedDate
        
        // 计算目标周的第一天
        let targetWeekStart = currentWeekStart + weeks.weeks
        
        // 如果目标周包含今天，则选中今天
        if isDateInCurrentWeek(targetWeekStart) {
            selectedDate = today
        } else {
            // 否则选中目标周的第一天
            selectedDate = targetWeekStart
        }
    }
    
    // 检查日期是否在本周
    private func isDateInCurrentWeek(_ date: DateInRegion) -> Bool {
        let calendar = SwiftDate.defaultRegion.calendar
        return calendar.isDate(date.date, equalTo: today.date, toGranularity: .weekOfYear)
    }
    
    // 移动到今天
    func moveToToday() {
        selectedDate = today
    }

    // 获取当前周的范围
    var weekRange: (start: DateInRegion, end: DateInRegion) {
        let start = selectedDate.dateAtStartOf(.weekOfYear)
        let end = selectedDate.dateAtEndOf(.weekOfYear)
        return (start, end)
    }

}
