//
//  Date-Extension.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftDate

// MARK: - 日期工具扩展
extension Date {
    /// 判断是否是今年
    var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    /// 判断是否是今天
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// 判断是否是明天
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    /// 判断是否是后天
    var isDayAfterTomorrow: Bool {
        let calendar = Calendar.current
        guard let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: Date()) else { return false }
        return calendar.isDate(self, inSameDayAs: dayAfterTomorrow)
    }
    
    /// 判断是否已过期
    var isOverdue: Bool {
        self.compare(Calendar.current.startOfDay(for: Date())) == .orderedAscending
    }
    
    /// 获取格式化的日期和星期字符串
    var dateAndWeekString: String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        let weekdayKey = String(format: "week_%@", ["sun", "mon", "tue", "wed", "thu", "fri", "sat"][weekday - 1])
        
        // 获取日期格式
        let dateFormat = isThisYear ? "date_format_short" : "date_format_full"
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat.localized
        let dateString = formatter.string(from: self)
        
        // 组合日期和星期
        return "date_format_with_week".localizedFormat(dateString, weekdayKey.localized)
    }
    /// 获取日期数字显示
    var dayNumberString: String {
        if isToday {
            return "今"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }
    
    /// 格式化日期显示
    var formattedString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = isThisYear ? "MM月dd日" : "yyyy年MM月dd日"
        return formatter.string(from: self)
    }
    
    /// 获取本周的日期数组
    func datesOfWeek(firstDayIsMonday: Bool) -> [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = firstDayIsMonday ? 2 : 1 // 1表示周日，2表示周一
        
        // 获取本周第一天的日期
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        components.weekday = calendar.firstWeekday
        
        guard let startOfWeek = calendar.date(from: components) else { return [] }
        
        // 生成一周的日期
        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: startOfWeek)
        }
    }
    
    /// 获取上一周的同一天
    func previousWeek() -> Date? {
        Calendar.current.date(byAdding: .day, value: -7, to: self)
    }
    
    /// 获取下一周的同一天
    func nextWeek() -> Date? {
        Calendar.current.date(byAdding: .day, value: 7, to: self)
    }
    
    /// 获取日期的开始时间戳（毫秒）- 不包含时分秒
    var startOfDayTimestamp: Int64 {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: self)
        return Int64(startOfDay.timeIntervalSince1970 * 1000)
    }
    
    /// 获取日期的结束时间戳（毫秒）- 不包含时分秒
    var endOfDayTimestamp: Int64 {
        let calendar = Calendar.current
        var components = DateComponents()
        components.day = 1
        components.second = -1
        guard let endOfDay = calendar.date(byAdding: components, to: calendar.startOfDay(for: self)) else {
            return startOfDayTimestamp
        }
        return Int64(endOfDay.timeIntervalSince1970 * 1000)
    }
    
    /// 获取完整的时间戳（毫秒）- 包含时分秒
    var fullTimestamp: Int64 {
        Int64(self.timeIntervalSince1970 * 1000)
    }
    
    /// 获取当前时区的时间戳（毫秒）- 包含时分秒
    static var currentTimestamp: Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    
    
    /// 将日期格式化为指定格式的字符串
    /// - Parameter format: 日期格式，例如："yyyy-MM-dd HH:mm:ss"、"MM月dd日 HH:mm" 等
    /// /使用示例
    /// let date = Date()
    /// let str1 = date.toString(format: "yyyy-MM-dd HH:mm:ss")  // "2024-01-18 15:30:45"
    /// let str2 = date.toString(format: "MM月dd日 HH:mm")       // "01月18日 15:30"
    func toString(format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    /// 将时间戳转换为指定格式的日期字符串
    /// - Parameters:
    ///   - timestamp: 时间戳（毫秒）
    ///   - format: 日期格式，例如："yyyy-MM-dd HH:mm:ss"、"MM月dd日 HH:mm" 等
    /// 使用示例
    /// let timestamp: Int64 = 1705555555000
    /// let str1 = Date.timestampToString(timestamp: timestamp, format: "yyyy-MM-dd HH:mm:ss")
    /// let str2 = Date.timestampToString(timestamp: timestamp, format: "MM月dd日 HH:mm")
    static func timestampToString(timestamp: Int64, format: String) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        return date.toString(format: format)
    }
    
    /// 将时间戳转换为Date对象 静态方法
    /// - Parameter timestamp: 时间戳（毫秒）
    /// let timestamp: Int64 = 1705555555000
    /// let date = Date.fromTimestamp(timestamp)
    static func fromTimestamp(_ timestamp: Int64) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
    }

}

