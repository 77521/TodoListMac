//
//  Date-Extension.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import LunarSwift
//import SwiftDate

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
    
    /// 判断是否为当月
    /// - Returns: 是否为当月
    var isCurrentMonth: Bool {
        let calendar = Calendar.current
        let today = Date()
        return calendar.component(.month, from: self) == calendar.component(.month, from: today) &&
               calendar.component(.year, from: self) == calendar.component(.year, from: today)
    }

    /// 判断是否已过期
    var isOverdue: Bool {
        self.compare(Calendar.current.startOfDay(for: Date())) == .orderedAscending
    }
    /// 格式化日期显示（仅年月）
    var formattedYearMonthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: self)
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
            return "today_short".localized
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
        formatter.dateFormat = isThisYear ? "date_format_short".localized : "date_format_full".localized
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

    // MARK: - 获取日期组件
    
    /// 获取年份
    /// - Returns: 年份 (例如: 2025)
    /// 使用示例: let year = Date().year
    var year: Int {
        Calendar.current.component(.year, from: self)
    }
    
    /// 获取月份
    /// - Returns: 月份 (1-12)
    /// 使用示例: let month = Date().month
    var month: Int {
        Calendar.current.component(.month, from: self)
    }
    
    /// 获取日期
    /// - Returns: 日期 (1-31)
    /// 使用示例: let day = Date().day
    var day: Int {
        Calendar.current.component(.day, from: self)
    }
    
    /// 获取小时
    /// - Returns: 小时 (0-23)
    /// 使用示例: let hour = Date().hour
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }
    
    /// 获取分钟
    /// - Returns: 分钟 (0-59)
    /// 使用示例: let minute = Date().minute
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }
    
    /// 获取秒数
    /// - Returns: 秒数 (0-59)
    /// 使用示例: let second = Date().second
    var second: Int {
        Calendar.current.component(.second, from: self)
    }

    
    /// 根据传入的数字生成日期
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份 (1-12)
    ///   - day: 日期 (1-31)
    ///   - hour: 小时 (0-23)
    ///   - minute: 分钟 (0-59)
    ///   - second: 秒数 (0-59)
    /// - Returns: 生成的 Date 对象，如果参数无效则返回当前日期
    /// 使用示例:
    /// let date1 = Date.createDate(year: 2025, month: 1, day: 21, hour: 15, minute: 30, second: 0)
    /// let date2 = Date.createDate(year: 2025, month: 12, day: 25) // 默认时分秒为 0:0:0
    static func createDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0, second: Int = 0) -> Date {
        let calendar = Calendar.current
        
        // 创建日期组件
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second
        
        // 根据组件生成日期
        if let date = calendar.date(from: dateComponents) {
            return date
        } else {
            // 如果参数无效，返回当前日期
            print("⚠️ 无效的日期参数: \(year)-\(month)-\(day) \(hour):\(minute):\(second)")
            return Date()
        }
    }

    // MARK: - 日期计算
    
    /// 增加指定天数
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// 减少指定天数
    func subtracting(days: Int) -> Date {
        adding(days: -days)
    }
    
    /// 增加指定月数
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
    
    /// 减少指定月数
    func subtracting(months: Int) -> Date {
        adding(months: -months)
    }
    
    /// 增加指定年数
    func adding(years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }
    
    /// 减少指定年数
    func subtracting(years: Int) -> Date {
        adding(years: -years)
    }
    
    /// 增加指定小时数
    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }
    
    /// 减少指定小时数
    func subtracting(hours: Int) -> Date {
        adding(hours: -hours)
    }
    
    /// 增加指定分钟数
    func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }
    
    /// 减少指定分钟数
    func subtracting(minutes: Int) -> Date {
        adding(minutes: -minutes)
    }
    
    /// 增加指定秒数
    func adding(seconds: Int) -> Date {
        Calendar.current.date(byAdding: .second, value: seconds, to: self) ?? self
    }
    
    /// 减少指定秒数
    func subtracting(seconds: Int) -> Date {
        adding(seconds: -seconds)
    }
    
    // MARK: - 日期比较
    /// 判断两个日期是否为同一天
    /// - Parameter otherDate: 要比较的另一个日期
    /// - Returns: 是否为同一天
    func isSameDay(as otherDate: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: otherDate)
    }

    /// 是否大于指定日期
    func isGreaterThan(_ date: Date) -> Bool {
        self.compare(date) == .orderedDescending
    }
    
    /// 是否大于等于指定日期
    func isGreaterThanOrEqual(to date: Date) -> Bool {
        self.compare(date) != .orderedAscending
    }
    
    /// 是否小于指定日期
    func isLessThan(_ date: Date) -> Bool {
        self.compare(date) == .orderedAscending
    }
    
    /// 是否小于等于指定日期
    func isLessThanOrEqual(to date: Date) -> Bool {
        self.compare(date) != .orderedDescending
    }
    
    /// 获取指定天数之前的日期的开始时间戳
    /// - Parameter days: 天数
    /// - Returns: 时间戳（毫秒）
    func daysAgoStartTimestamp(_ days: Int) -> Int64 {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -days, to: self) ?? self
        return date.startOfDayTimestamp
    }

    // MARK: - 星期显示相关
    
    // MARK: - 星期显示相关
    
    /// 根据日期获取星期显示（使用国际化）
    /// - Parameter date: 日期
    /// - Returns: 星期显示字符串，如 "Mon", "Tue" 等
    func weekdayDisplay() -> String {
        let weekday = Calendar.current.component(.weekday, from: self)
        let key: String
        
        switch weekday {
        case 1: key = "week_sun"
        case 2: key = "week_mon"
        case 3: key = "week_tue"
        case 4: key = "week_wed"
        case 5: key = "week_thu"
        case 6: key = "week_fri"
        case 7: key = "week_sat"
        default: key = "week_sun"
        }
        
        return key.localized
    }
    
    /// 根据日期获取星期显示（使用国际化）
    /// - Parameter date: 日期
    /// - Returns: 星期显示字符串，如 "Mon", "Tue" 等
    static func weekdayDisplay(for date: Date) -> String {
        return date.weekdayDisplay()
    }

    // MARK: - 重复计算相关方法（已合并到下方）
    
    /// 获取下一个工作日的日期（跳过周末）
    /// - Returns: 下一个工作日的日期
    func nextWorkday() -> Date {
        let calendar = Calendar.current
        var nextDate = self
        
        repeat {
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            let weekday = calendar.component(.weekday, from: nextDate)
            // 跳过周六(7)和周日(1)
            if weekday != 1 && weekday != 7 {
                break
            }
        } while true
        
        return nextDate
    }
    
    /// 获取今天是第几个星期几（自动使用当前日期的星期几）
    /// - Returns: 第几个（1-5）
    func weekdayOrdinal() -> Int {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: self)
        let dayOfMonth = calendar.component(.day, from: self)
        return (dayOfMonth - 1) / 7 + 1
    }

    
    /// 获取今天是几号
    /// - Returns: 日期数字（1-31）
    func dayOfMonth() -> Int {
        Calendar.current.component(.day, from: self)
    }
    
    /// 获取今天是几月
    /// - Returns: 月份数字（1-12）
    func monthOfYear() -> Int {
        Calendar.current.component(.month, from: self)
    }
    
    /// 获取今天是几月几日
    /// - Returns: 月日字符串，如 "8月28日"
    func monthDayString() -> String {
        let month = monthOfYear()
        let day = dayOfMonth()
        return "\(month)月\(day)日"
    }
    /// 获取当月第一天（开始时间）
    /// - Returns: 当月第一天的开始时间
    var firstDayOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// 获取当月最后一天（开始时间）
    /// - Returns: 当月最后一天的开始时间
    var lastDayOfMonth: Date {
        let calendar = Calendar.current
        let firstDay = self.firstDayOfMonth
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstDay) ?? firstDay
        return calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? self
    }

    
    
    // MARK: - 重复任务相关方法（合并版本）
    
    /// 获取下N个星期的同一天
    /// - Parameters:
    ///   - weekday: 星期几 (1=周日, 2=周一, ..., 7=周六)
    ///   - weeksLater: 几周后，默认为1
    /// - Returns: 下N个星期的同一天
    func nextWeekday(_ weekday: Int, weeksLater: Int = 1) -> Date {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: self)
        let daysToAdd = (weekday - currentWeekday + 7) % 7 + (weeksLater * 7)
        return calendar.date(byAdding: .day, value: daysToAdd, to: self) ?? self
    }
    
    /// 获取下N个月的同一天
    /// - Parameters:
    ///   - day: 几号
    ///   - monthsLater: 几个月后，默认为1
    /// - Returns: 下N个月的同一天
    func nextMonthDay(_ day: Int, monthsLater: Int = 1) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: self)
        components.month = (components.month ?? 1) + monthsLater
        components.day = day
        
        // 如果目标月份没有这一天，则使用该月的最后一天
        if let targetDate = calendar.date(from: components) {
            return targetDate
        } else {
            // 获取该月的最后一天
            let lastDay = calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(year: components.year, month: components.month)) ?? self)?.upperBound ?? 1
            components.day = lastDay - 1
            return calendar.date(from: components) ?? self
        }
    }
    
    /// 获取下个月最后一天
    /// - Parameter monthsLater: 几个月后，默认为1
    /// - Returns: 下个月最后一天的日期
    func nextMonthLastDay(monthsLater: Int = 1) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: self)
        components.month = (components.month ?? 1) + monthsLater + 1
        components.day = 0 // 0表示上个月的最后一天
        
        return calendar.date(from: components) ?? self
    }
    
    /// 获取下N个月的第N个星期几
    /// - Parameters:
    ///   - ordinal: 第几个 (1=第一个, 2=第二个, ...)
    ///   - weekday: 星期几 (1=周日, 2=周一, ..., 7=周六)
    ///   - monthsLater: 几个月后，默认为1
    /// - Returns: 下N个月的第N个星期几
    func nextMonthWeekday(ordinal: Int, weekday: Int, monthsLater: Int = 1) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: self)
        components.month = (components.month ?? 1) + monthsLater
        components.day = 1
        
        guard let firstDayOfMonth = calendar.date(from: components) else { return self }
        
        // 找到该月第一个目标星期几
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysToFirstTarget = (weekday - firstWeekday + 7) % 7
        
        // 计算第N个目标星期几
        let daysToAdd = daysToFirstTarget + (ordinal - 1) * 7
        return calendar.date(byAdding: .day, value: daysToAdd, to: firstDayOfMonth) ?? self
    }
    
    /// 获取下N年的同月日
    /// - Parameters:
    ///   - month: 月份
    ///   - day: 几号
    ///   - yearsLater: 几年后，默认为1
    /// - Returns: 下N年的同月日
    func nextYearMonthDay(month: Int, day: Int, yearsLater: Int = 1) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year], from: self)
        components.year = (components.year ?? 1) + yearsLater
        components.month = month
        components.day = day
        
        // 如果目标年份没有这一天（如2月29日），则使用该月的最后一天
        if let targetDate = calendar.date(from: components) {
            return targetDate
        } else {
            // 获取该月的最后一天
            let lastDay = calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(year: components.year, month: month)) ?? self)?.upperBound ?? 1
            components.day = lastDay - 1
            return calendar.date(from: components) ?? self
        }
    }
    
    
    // MARK: - 农历显示方法
    
    /// 获取农历月日显示
    /// - Returns: 农历月日显示文本
    var lunarMonthDay: String {
        return TDLunarCalendar.getLunarMonthDay(for: self)
    }

    /// 获取农历月份显示
    /// 如果是初一就显示月份，否则显示具体日期
    /// - Returns: 农历显示文本
    var lunarMonthDisplay: String {
        return TDLunarCalendar.getLunarMonthDisplay(for: self)
    }
    
    /// 智能显示日期信息
    /// 优先级：法定节假日 > 农历节假日 > 阳历节假日 > 24节气 > 农历
    /// - Returns: 显示文本
    var smartDisplay: String {
        return TDLunarCalendar.getSmartDisplay(for: self)
    }
    
    /// 转换为农历对象
    /// - Returns: 农历对象
    var toLunar: Lunar {
        return TDLunarCalendar.solarToLunar(self)
    }
    /// 根据农历日期创建阳历日期
    /// - Parameters:
    ///   - lunarYear: 农历年
    ///   - lunarMonth: 农历月
    ///   - lunarDay: 农历日
    /// - Returns: 阳历日期
    static func fromLunar(lunarYear: Int, lunarMonth: Int, lunarDay: Int) -> Date? {
        return TDLunarCalendar.lunarToSolar(lunarYear: lunarYear, lunarMonth: lunarMonth, lunarDay: lunarDay)
    }

    
    /// 获取下N年农历的同月日
    /// - Parameters:
    ///   - lunarMonth: 农历月份
    ///   - lunarDay: 农历几号
    ///   - yearsLater: 几年后，默认为1
    /// - Returns: 下N年农历的同月日
    func nextLunarYearMonthDay(lunarMonth: Int, lunarDay: Int, yearsLater: Int = 1) -> Date? {
        // 使用专业的农历库进行转换
        let currentYear = Calendar.current.component(.year, from: self)
        let targetYear = currentYear + yearsLater
        
        return TDLunarCalendar.lunarToSolar(lunarYear: targetYear, lunarMonth: lunarMonth, lunarDay: lunarDay)
    }

    /// 判断是否在节假日数据中
    /// - Returns: 是否在节假日数据中（包含节假日和调休）
    var isInHolidayData: Bool {
        let timestamp = self.startOfDayTimestamp
        let holidayList = TDHolidayManager.shared.getHolidayList()
        
        return holidayList.contains { $0.date == timestamp }
    }
    
    /// 判断是否为法定节假日
    /// - Returns: 是否为法定节假日
    
    var isHoliday: Bool {
        // 先判断是否在节假日数据中
        if !self.isInHolidayData {
            return false
        }
        
        let timestamp = self.startOfDayTimestamp
        let holidayList = TDHolidayManager.shared.getHolidayList()
        
        // 查找匹配的节假日数据
        if let holiday = holidayList.first(where: { $0.date == timestamp }) {
            // 返回 holiday 字段的值（true=法定节假日，false=调休工作日）
            return holiday.holiday
        }
        
        return false
    }


}

