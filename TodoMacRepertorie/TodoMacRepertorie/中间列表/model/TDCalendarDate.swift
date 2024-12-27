//
//  TDCalendarDate.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/2.
//

import Foundation
import SwiftDate
import LunarSwift

/// 日历日期数据模型
public struct TDCalendarDate: Identifiable, Equatable {
    /// 唯一标识符
    public let id = UUID()
    
    /// 日期
    public let date: Date

    /// 是否是当前月份的日期
    public let isCurrentMonth: Bool
    /// 缓存的日历实例
    private static let calendar = Calendar.current
    /// 缓存的日期格式化器
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    /// 获取日期的天数
    var day: Int {
        Self.calendar.component(.day, from: date)
    }

    /// 农历日期信息
    public var lunarInfo: TDLunarDateInfo {
        let solar = Solar(date: date.date)
        let lunar = solar.lunar

        return TDLunarDateInfo(
            monthName: lunar.monthInChinese,
            dayName: lunar.dayInChinese,
            isFirstDayOfMonth: lunar.day == 1,
            festivals: lunar.festivals,
            solarTerms: lunar.jieQi
        )
    }
    
    /// 农历日期展示文本
    /// 农历日期展示文本
    public var lunarText: String {
        let solar = Solar(date: date)
        let lunar = solar.lunar
        
        // 优先级：阳历节日 > 农历节日 > 24节气 > 农历日期（初一显示月份）
        if let festival = lunar.festivals.first {
            return festival
        }
        
        let term = lunar.jieQi
        if !term.isEmpty {
            return term
        }
        
        if lunar.day == 1 {
            return lunar.monthInChinese + "月"
        }
        
        return lunar.dayInChinese
    }
    public init(date: Date, isCurrentMonth: Bool) {
        self.date = date
        self.isCurrentMonth = isCurrentMonth
    }
}

/// 农历日期信息
public struct TDLunarDateInfo {
    /// 农历月份名称
    public let monthName: String
    /// 农历日期名称
    public let dayName: String
    /// 是否是初一
    public let isFirstDayOfMonth: Bool
    /// 节日（包括阳历节日和农历节日）
    public let festivals: [String]
    /// 24节气
    public let solarTerms: String?
}

extension TDCalendarDate {
    /// 创建指定月份的日历数据（包括上月末和下月初的补充日期）
    /// - Parameters:
    ///   - date: 指定月份的任意日期
    ///   - firstWeekday: 每周的第一天（0表示周日，1表示周一）
    /// - Returns: 包含6行7列共42个日期的数组
    public static func datesForMonth(containing date: Date, firstWeekday: Int) -> [TDCalendarDate] {
        let calendar = Self.calendar
        var components = calendar.dateComponents([.year, .month], from: date)
        
        // 预分配数组
        var dates = [TDCalendarDate]()
        dates.reserveCapacity(42)
        
        // 获取当月第一天
        guard let firstDayOfMonth = calendar.date(from: components) else { return [] }
        
        // 计算当月天数
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count ?? 30
        
        // 计算第一天是星期几
        let firstWeekdayOfMonth = calendar.component(.weekday, from: firstDayOfMonth)
        
        // 计算需要显示的上月天数
        let numberOfPreviousDays = (firstWeekdayOfMonth - firstWeekday + 7) % 7
        
        // 添加上月日期
        if numberOfPreviousDays > 0 {
            components.month! -= 1
            if let previousMonth = calendar.date(from: components) {
                let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)?.count ?? 30
                let startDay = daysInPreviousMonth - numberOfPreviousDays + 1
                
                for day in startDay...daysInPreviousMonth {
                    components.day = day
                    if let date = calendar.date(from: components) {
                        dates.append(TDCalendarDate(date: date, isCurrentMonth: false))
                    }
                }
            }
        }
        
        // 添加当月日期
        components.month! += 1
        for day in 1...daysInMonth {
            components.day = day
            if let date = calendar.date(from: components) {
                dates.append(TDCalendarDate(date: date, isCurrentMonth: true))
            }
        }
        
        // 计算需要显示的下月天数
        let remainingDays = 42 - dates.count
        
        // 添加下月日期
        if remainingDays > 0 {
            components.month! += 1
            for day in 1...remainingDays {
                components.day = day
                if let date = calendar.date(from: components) {
                    dates.append(TDCalendarDate(date: date, isCurrentMonth: false))
                }
            }
        }
        
        return dates
    }
}


//public struct TDLunarInfo {
//    public let dayName: String
//    public let monthName: String
//    public let yearName: String
//    public let solarTerm: String?
//    public let festival: String?
//    public let lunarFestival: String?
//
//    init(date: Date) {
//        // 创建农历日期对象
//        let solar = Solar(date: date)
//        let lunar = solar.lunar
//        // 获取农历日期名称(如:初一、初二等)
//        self.dayName = lunar.dayInChinese
//        // 获取农历月份名称(如:正月、二月等)
//        self.monthName = lunar.monthInChinese
//        // 获取农历年份名称(如:甲子年等)
//        self.yearName = lunar.yearInChinese
//        // 获取节气信息(如:立春、雨水等),可能为nil
//        self.solarTerm = lunar.jieQi
//        // 获取公历节日(如:元旦、春节等),通过静态方法获取
//        self.festival = solar.festivals.first
//        // 获取农历节日(如:除夕、元宵等),可能为nil
//        self.lunarFestival = lunar.festivals.first
//    }
//
//
//}
