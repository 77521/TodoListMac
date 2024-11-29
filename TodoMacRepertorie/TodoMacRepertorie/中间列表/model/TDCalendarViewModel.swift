//
//  TDCalendarViewModel.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/27.
//

import Foundation
import SwiftDate
import SwiftUI
import OSLog

// MARK: - 日历视图模型
class TDCalendarViewModel: ObservableObject {
    @Published var currentDate: DateInRegion
    @Published var calendarDays: [TDCalendarDay] = []
    @Published var showYearPicker: Bool = false
    @ObservedObject private var settingManager = TDSettingManager.shared

    private let dataManager = TDCalendarDataManager.shared
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TDCalendar", category: "CalendarViewModel")
    
    init() {
        self.currentDate = DateInRegion()
        Task {
            await loadCurrentMonth()
        }
    }
    // 修改初始化方法，添加 initialDate 参数
    init(initialDate: DateInRegion = DateInRegion()) {
        self.currentDate = initialDate
        Task {
            await loadCurrentMonth()
        }
    }
    // MARK: - 公共方法
    
    /// 加载当前月份数据
    @MainActor
    func loadCurrentMonth() async {
        do {
            let days = try await dataManager.getDaysForMonth(
                year: currentDate.year,
                month: currentDate.month
            )
            self.calendarDays = days
        } catch {
            logger.error("加载当前月份数据失败: \(error.localizedDescription)")
        }
    }
    
    /// 切换月份
    @MainActor
    func changeMonth(by value: Int) async {
         let newDate = currentDate + value.months
            currentDate = newDate
            await loadCurrentMonth()
        
    }
    
    /// 切换年份
    @MainActor
    func changeYear(by value: Int) async {
        // 计算新的年份
        let targetYear = currentDate.year + value
        
        // 确保年份在有效范围内
        guard targetYear >= TDCalendarConstants.minimumYear &&
                targetYear <= TDCalendarConstants.maximumYear else {
            return
        }
        
        // 使用当前日期的月份和日期创建新日期
        let newDate = DateInRegion(
            year: targetYear,
            month: currentDate.month,
            day: 1,  // 使用月初避免月份天数问题
            region: .current
        )
        currentDate = newDate
        await loadCurrentMonth()
        
    }
    
    /// 跳转到指定年份
    @MainActor
    func changeYear(to year: Int) async {
        // 确保年份在有效范围内
        guard year >= TDCalendarConstants.minimumYear &&
                year <= TDCalendarConstants.maximumYear else {
            return
        }
        
        let newDate = DateInRegion(
            year: year,
            month: currentDate.month,
            day: 1,  // 使用月初避免月份天数问题
            region: .current
        )
        currentDate = newDate
        await loadCurrentMonth()
        
    }

    
    /// 跳转到今天
    @MainActor
    func jumpToToday() async {
        currentDate = DateInRegion()
        await loadCurrentMonth()
    }
}
