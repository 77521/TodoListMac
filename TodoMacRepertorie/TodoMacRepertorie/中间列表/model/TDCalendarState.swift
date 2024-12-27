//
//  TDCalendarState.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/2.
//

import Foundation
import SwiftUI
import Combine
import SwiftDate

/// 日历状态管理
public class TDCalendarState: ObservableObject {
    /// 当前显示的月份
    @Published public private(set) var currentMonth: Date {
        didSet {
            // 当月份改变时，立即更新日期数据
            updateDatesIfNeeded()
        }
    }
    
    /// 选中的日期
    @Published public private(set) var selectedDate: Date
    
    /// 是否显示年份选择器
    @Published public var isYearPickerPresented: Bool = false
    
    /// 日历配置
    public let config: TDCalendarConfig
    
    /// 日期选中回调
    public var onDateSelected: ((Date) -> Void)?
    
    /// 当前月份的所有日期数据
    @Published public private(set) var dates: [TDCalendarDate] = []
    
    /// 缓存的年份数组
    private lazy var yearsCache: [Int] = {
        let currentYear = currentMonth.year
        return Array((currentYear - 10)...(currentYear + 10))
    }()
    /// 缓存的日历实例
    private static let calendar = Calendar.current
    
    /// 预计算的一周天数
    private static let daysInWeek = 7
    
    /// 预计算的总行数
    private static let numberOfWeeks = 6
    
    /// 预计算的总天数
    private static let totalDays = numberOfWeeks * daysInWeek
    
    /// 日期缓存
    private var dateCache: NSCache<NSString, NSArray> = {
        let cache = NSCache<NSString, NSArray>()
        cache.countLimit = 12 // 只缓存12个月
        return cache
    }()

    /// 初始化
    /// - Parameters:
    ///   - date: 初始日期，默认为今天
    ///   - config: 日历配置
    ///   - onDateSelected: 日期选中回调
    public init(
        date: Date = Date(),
        config: TDCalendarConfig = TDCalendarConfig(),
        onDateSelected: ((Date) -> Void)? = nil
    ) {
        self.currentMonth = date
        self.selectedDate = date
        self.config = config
        self.onDateSelected = onDateSelected
        // 初始化时直接计算日期数据
        updateDatesIfNeeded()
    }
    
    /// 根据需要更新日期数据
    private func updateDatesIfNeeded() {
        let key = "\(currentMonth.year)-\(currentMonth.month)" as NSString
        
        if let cachedDates = dateCache.object(forKey: key) as? [TDCalendarDate] {
            dates = cachedDates
            return
        }
        
        let firstWeekday = TDSettingManager.shared.firstWeekday
        let newDates = generateDatesForMonth(DateInRegion(currentMonth), firstWeekday: firstWeekday)
        dateCache.setObject(newDates as NSArray, forKey: key)
        dates = newDates
    }
    
    
    /// 生成月份日期（优化版本）
        private func generateDatesForMonth(_ month: DateInRegion, firstWeekday: Int) -> [TDCalendarDate] {
            let calendar = Self.calendar
            
            // 获取月份信息
            let monthStart = month.dateAtStartOf(.month)
            let monthStartWeekday = calendar.component(.weekday, from: monthStart.date)
            let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart.date)?.count ?? 30
            
            // 预分配数组
            var dates = [TDCalendarDate]()
            dates.reserveCapacity(Self.totalDays)
            
            // 计算前置天数
            let prefixDays = (monthStartWeekday - firstWeekday + Self.daysInWeek) % Self.daysInWeek
            
            // 添加上月日期
            if prefixDays > 0 {
                let previousMonth = monthStart - 1.months
                let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth.date)?.count ?? 30
                let startDay = daysInPreviousMonth - prefixDays + 1
                
                for day in startDay...daysInPreviousMonth {
                    let date = previousMonth.dateBySet([.day: day]) ?? previousMonth
                    dates.append(TDCalendarDate(date: date.date, isCurrentMonth: false))
                }
            }
            
            // 添加当月日期
            for day in 1...daysInMonth {
                let date = monthStart.dateBySet([.day: day]) ?? monthStart
                dates.append(TDCalendarDate(date: date.date, isCurrentMonth: true))
            }
            
            // 添加下月日期
            let remainingDays = Self.totalDays - dates.count
            if remainingDays > 0 {
                let nextMonth = monthStart + 1.months
                for day in 1...remainingDays {
                    let date = nextMonth.dateBySet([.day: day]) ?? nextMonth
                    dates.append(TDCalendarDate(date: date.date, isCurrentMonth: false))
                }
            }
            
            return dates
        }
    
    /// 选择日期
    /// - Parameter date: 要选择的日期
    public func selectDate(_ date: Date) {
        selectedDate = date
        
        // 如果选中的日期不在当前月份，切换到对应月份
        if !date.compare(.isSameMonth(currentMonth)){
            currentMonth = date
        }
        onDateSelected?(date)
    }
    
    /// 切换到上个月
    public func previousMonth() {
        let newMonth = currentMonth - 1.months
        currentMonth = newMonth
    }
    
    /// 切换到下个月
    public func nextMonth() {
        let newMonth = currentMonth + 1.months
        currentMonth = newMonth
    }
    
    /// 切换到上一年
    public func previousYear() {
        let newDate = currentMonth - 1.years
        switchToYear(newDate.year)
    }
    
    /// 切换到下一年
    public func nextYear() {
        let newDate = currentMonth + 1.years
        switchToYear(newDate.year)
    }
    
    /// 切换到指定年份
    /// - Parameter year: 目标年份
    public func switchToYear(_ year: Int) {
        if let newDate = currentMonth.dateBySet([.year: year]) {
            currentMonth = newDate
        }
    }
    
    /// 获取可选择的年份范围
    /// - Returns: 年份数组（前后10年）
    public func availableYears() -> [Int] {
        // 使用缓存的年份数组
        yearsCache
    }
}
