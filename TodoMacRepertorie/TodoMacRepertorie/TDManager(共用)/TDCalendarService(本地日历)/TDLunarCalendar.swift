//
//  TDLunarCalendar.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation

/// 农历工具类 - 处理农历转换、24节气、节日等
class TDLunarCalendar {
    
    // MARK: - 农历数据结构
    
    /// 农历日期数据结构
    struct TDLunarDate {
        let year: Int           // 农历年
        let month: Int          // 农历月
        let day: Int            // 农历日
        let isLeapMonth: Bool   // 是否闰月
        let yearName: String    // 天干地支年名
        let monthName: String   // 农历月名
        let dayName: String     // 农历日名
        let zodiacAnimal: String // 生肖
    }
    
    /// 节气信息
    struct TDSolarTerm {
        let name: String        // 节气名称
        let date: Date         // 节气日期
        let description: String // 节气描述
    }
    
    /// 节日信息
    struct TDFestival {
        let name: String        // 节日名称
        let date: Date         // 节日日期
        let type: TDFestivalType // 节日类型
        let description: String // 节日描述
    }
    
    /// 节日类型
    enum TDFestivalType {
        case solarFestival     // 阳历节日
        case lunarFestival     // 农历节日
        case solarTerm         // 24节气
        case traditional       // 传统节日
        case modern           // 现代节日
    }
    
    // MARK: - 农历数据
    
    /// 农历月份名称
    private static let lunarMonths = [
        "正月", "二月", "三月", "四月", "五月", "六月",
        "七月", "八月", "九月", "十月", "冬月", "腊月"
    ]
    
    /// 农历日期名称
    private static let lunarDays = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]
    
    /// 天干地支
    private static let heavenlyStems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    private static let earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    
    /// 生肖
    private static let zodiacAnimals = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]
    
    // MARK: - 24节气数据
    
    /// 24节气名称
    private static let solarTerms = [
        "立春", "雨水", "惊蛰", "春分", "清明", "谷雨",
        "立夏", "小满", "芒种", "夏至", "小暑", "大暑",
        "立秋", "处暑", "白露", "秋分", "寒露", "霜降",
        "立冬", "小雪", "大雪", "冬至", "小寒", "大寒"
    ]
    
    /// 24节气描述
    private static let solarTermDescriptions = [
        "立春": "春季开始，万物复苏",
        "雨水": "降雨开始，雨量渐增",
        "惊蛰": "春雷始鸣，惊醒蛰伏的昆虫",
        "春分": "昼夜平分，春季中期",
        "清明": "天气清和，草木茂盛",
        "谷雨": "雨生百谷，播种的好时节",
        "立夏": "夏季开始，万物生长",
        "小满": "麦类等夏熟作物籽粒开始饱满",
        "芒种": "有芒的麦子快收，有芒的稻子可种",
        "夏至": "白昼最长，太阳直射北回归线",
        "小暑": "暑气上升，天气开始炎热",
        "大暑": "一年中最热的时期",
        "立秋": "秋季开始，暑去凉来",
        "处暑": "暑气终止，天气转凉",
        "白露": "天气转凉，露凝而白",
        "秋分": "昼夜平分，秋季中期",
        "寒露": "露气寒冷，将凝结",
        "霜降": "天气渐冷，开始有霜",
        "立冬": "冬季开始，万物收藏",
        "小雪": "开始下雪，雪量不大",
        "大雪": "雪量增大，地面积雪",
        "冬至": "白昼最短，太阳直射南回归线",
        "小寒": "开始进入一年中最寒冷的日子",
        "大寒": "一年中最冷的时期"
    ]
    
    // MARK: - 节日数据
    
    /// 阳历节日
    private static let solarFestivals: [(month: Int, day: Int, name: String, type: TDFestivalType)] = [
        (1, 1, "元旦", .modern),
        (2, 14, "情人节", .modern),
        (3, 8, "妇女节", .modern),
        (3, 12, "植树节", .modern),
        (4, 1, "愚人节", .modern),
        (4, 5, "清明节", .traditional), // 清明节（阳历）
        (5, 1, "劳动节", .modern),
        (5, 4, "青年节", .modern),
        (6, 1, "儿童节", .modern),
        (7, 1, "建党节", .modern),
        (8, 1, "建军节", .modern),
        (9, 10, "教师节", .modern),
        (10, 1, "国庆节", .modern),
        (12, 24, "平安夜", .modern), // 平安夜
        (12, 25, "圣诞节", .modern)
        // 感恩节不在这里定义，因为需要动态计算（11月第四个星期四）
    ]
    
    /// 农历节日
    private static let lunarFestivals: [(month: Int, day: Int, name: String, type: TDFestivalType)] = [
        (1, 1, "春节", .traditional),
        (1, 15, "元宵节", .traditional),
        (2, 2, "龙抬头", .traditional),
        (3, 3, "上巳节", .traditional), // 上巳节
        (5, 5, "端午节", .traditional),
        (6, 6, "天贶节", .traditional), // 天贶节
        (7, 7, "七夕节", .traditional),
        (7, 15, "中元节", .traditional),
        (8, 15, "中秋节", .traditional),
        (9, 9, "重阳节", .traditional),
        (10, 1, "寒衣节", .traditional), // 寒衣节
        (12, 8, "腊八节", .traditional),
        (12, 23, "小年", .traditional)
        // 除夕不在这里定义，因为需要动态计算（可能是29日或30日）
    ]
    
    // MARK: - 阳历转农历
    
    /// 阳历转农历
    /// - Parameter date: 阳历日期
    /// - Returns: 农历日期信息
    static func solarToLunar(_ date: Date) -> TDLunarDate {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        // 简化的农历转换算法（实际应用中建议使用专业的农历库）
        let lunarInfo = convertSolarToLunar(solarYear: year, solarMonth: month, solarDay: day)
        
        return TDLunarDate(
            year: lunarInfo.year,
            month: lunarInfo.month,
            day: lunarInfo.day,
            isLeapMonth: lunarInfo.isLeapMonth,
            yearName: getLunarYearName(lunarInfo.year),
            monthName: lunarMonths[lunarInfo.month - 1],
            dayName: lunarDays[lunarInfo.day - 1],
            zodiacAnimal: zodiacAnimals[(lunarInfo.year - 4) % 12]
        )
    }
    
    // MARK: - 农历转阳历
    
    /// 农历转阳历
    /// - Parameters:
    ///   - lunarYear: 农历年
    ///   - lunarMonth: 农历月
    ///   - lunarDay: 农历日
    ///   - isLeapMonth: 是否闰月
    /// - Returns: 阳历日期
    static func lunarToSolar(lunarYear: Int, lunarMonth: Int, lunarDay: Int, isLeapMonth: Bool = false) -> Date? {
        // 简化的农历转阳历算法
        let solarInfo = convertLunarToSolar(lunarYear: lunarYear, lunarMonth: lunarMonth, lunarDay: lunarDay, isLeapMonth: isLeapMonth)
        
        var components = DateComponents()
        components.year = solarInfo.year
        components.month = solarInfo.month
        components.day = solarInfo.day
        
        return Calendar.current.date(from: components)
    }
    
    // MARK: - 24节气相关
    
    /// 获取指定年份的24节气
    /// - Parameter year: 年份
    /// - Returns: 24节气数组
    static func getSolarTerms(for year: Int) -> [TDSolarTerm] {
        var solarTerms: [TDSolarTerm] = []
        
        // 简化的24节气计算（实际应用中建议使用专业的节气库）
        for (index, termName) in TDLunarCalendar.solarTerms.enumerated() {
            let month = (index / 2) + 1
            let day = 5 + (index % 2) * 15 // 简化的日期计算
            
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            
            if let date = Calendar.current.date(from: components) {
                let description = solarTermDescriptions[termName] ?? ""
                solarTerms.append(TDSolarTerm(name: termName, date: date, description: description))
            }
        }
        
        return solarTerms
    }
    
    /// 获取指定日期的节气信息
    /// - Parameter date: 日期
    /// - Returns: 节气信息（如果当天是节气）
    static func getSolarTerm(for date: Date) -> TDSolarTerm? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        let solarTerms = getSolarTerms(for: year)
        
        for term in solarTerms {
            let termMonth = calendar.component(.month, from: term.date)
            let termDay = calendar.component(.day, from: term.date)
            
            if month == termMonth && day == termDay {
                return term
            }
        }
        
        return nil
    }
    
    // MARK: - 节日相关
    
    /// 获取指定年份的所有节日
    /// - Parameter year: 年份
    /// - Returns: 节日数组
    static func getFestivals(for year: Int) -> [TDFestival] {
        var festivals: [TDFestival] = []
        
        // 阳历节日
        for festival in solarFestivals {
            var components = DateComponents()
            components.year = year
            components.month = festival.month
            components.day = festival.day
            
            if let date = Calendar.current.date(from: components) {
                festivals.append(TDFestival(
                    name: festival.name,
                    date: date,
                    type: festival.type,
                    description: "\(festival.name)节日"
                ))
            }
        }
        
        // 动态阳历节日
        festivals.append(contentsOf: getDynamicSolarFestivals(for: year))
        
        // 农历节日（需要转换为阳历）
        for festival in lunarFestivals {
            if let date = lunarToSolar(lunarYear: year, lunarMonth: festival.month, lunarDay: festival.day) {
                festivals.append(TDFestival(
                    name: festival.name,
                    date: date,
                    type: festival.type,
                    description: "\(festival.name)节日"
                ))
            }
        }
        
        // 动态农历节日
        festivals.append(contentsOf: getDynamicLunarFestivals(for: year))
        
        // 24节气
        let solarTerms = getSolarTerms(for: year)
        for term in solarTerms {
            festivals.append(TDFestival(
                name: term.name,
                date: term.date,
                type: .solarTerm,
                description: term.description
            ))
        }
        
        return festivals.sorted { $0.date < $1.date }
    }
    
    /// 获取指定日期的节日信息
    /// - Parameter date: 日期
    /// - Returns: 节日信息（如果当天是节日）
    static func getFestival(for date: Date) -> TDFestival? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        let festivals = getFestivals(for: year)
        
        for festival in festivals {
            let festivalMonth = calendar.component(.month, from: festival.date)
            let festivalDay = calendar.component(.day, from: festival.date)
            
            if month == festivalMonth && day == festivalDay {
                return festival
            }
        }
        
        return nil
    }
    
    // MARK: - 智能显示方法
    
    /// 智能显示日期信息
    /// 优先级：阳历节假日 > 农历节假日 > 24节气 > 农历显示
    /// - Parameter date: 日期
    /// - Returns: 显示信息
    static func getSmartDisplay(for date: Date) -> TDSmartDisplayInfo {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        // 1. 优先检查阳历节假日
        for festival in solarFestivals {
            if month == festival.month && day == festival.day {
                return TDSmartDisplayInfo(
                    displayText: festival.name,
                    type: .solarFestival,
                    description: "\(festival.name)节日",
                    priority: 1
                )
            }
        }
        
        // 2. 检查农历节假日
        let lunar = solarToLunar(date)
        for festival in lunarFestivals {
            if lunar.month == festival.month && lunar.day == festival.day {
                return TDSmartDisplayInfo(
                    displayText: festival.name,
                    type: .lunarFestival,
                    description: "\(festival.name)节日",
                    priority: 2
                )
            }
        }
        
        // 3. 检查24节气
        if let solarTerm = getSolarTerm(for: date) {
            return TDSmartDisplayInfo(
                displayText: solarTerm.name,
                type: .solarTerm,
                description: solarTerm.description,
                priority: 3
            )
        }
        
        // 4. 农历显示
        let lunarDisplay = getLunarDisplay(for: date)
        return TDSmartDisplayInfo(
            displayText: lunarDisplay,
            type: .lunarDate,
            description: "农历\(lunarDisplay)",
            priority: 4
        )
    }
    
    /// 获取农历显示文本
    /// - Parameter date: 日期
    /// - Returns: 农历显示文本
    static func getLunarDisplay(for date: Date) -> String {
        let lunar = solarToLunar(date)
        return getLunarDisplay(lunarDate: lunar)
    }
    
    /// 获取农历显示文本
    /// - Parameter lunarDate: 农历日期
    /// - Returns: 农历显示文本
    static func getLunarDisplay(lunarDate: TDLunarDate) -> String {
        // 如果是初一，显示月份
        if lunarDate.day == 1 {
            let leapPrefix = lunarDate.isLeapMonth ? "闰" : ""
            return "\(leapPrefix)\(lunarDate.monthName)"
        } else {
            // 其他日期显示农历日期
            return lunarDate.dayName
        }
    }
    
    /// 智能显示信息结构
    struct TDSmartDisplayInfo {
        let displayText: String      // 显示文本
        let type: TDDisplayType      // 显示类型
        let description: String      // 描述信息
        let priority: Int           // 优先级（1最高）
    }
    
    /// 显示类型
    enum TDDisplayType {
        case solarFestival          // 阳历节假日
        case lunarFestival          // 农历节假日
        case solarTerm              // 24节气
        case lunarDate              // 农历日期
    }
    
    // MARK: - 辅助方法
    
    /// 获取农历年份名称（天干地支）
    private static func getLunarYearName(_ year: Int) -> String {
        let stemIndex = (year - 4) % 10
        let branchIndex = (year - 4) % 12
        return "\(heavenlyStems[stemIndex])\(earthlyBranches[branchIndex])"
    }
    
    /// 阳历转农历（简化算法）
    private static func convertSolarToLunar(solarYear: Int, solarMonth: Int, solarDay: Int) -> (year: Int, month: Int, day: Int, isLeapMonth: Bool) {
        // 这是一个简化的算法，实际应用中建议使用专业的农历库
        // 这里提供一个基础的转换逻辑
        
        // 农历1900年正月初一对应阳历1900年1月31日
        let baseSolarDate = Date(timeIntervalSince1970: -2208988800) // 1900-01-31
        let baseLunarYear = 1900
        let baseLunarMonth = 1
        let baseLunarDay = 1
        
        let currentDate = Date(timeIntervalSince1970: TimeInterval(solarYear - 1970) * 365.25 * 24 * 3600 +
                              TimeInterval(solarMonth - 1) * 30.44 * 24 * 3600 +
                              TimeInterval(solarDay - 1) * 24 * 3600)
        
        let daysDiff = Int(currentDate.timeIntervalSince(baseSolarDate) / (24 * 3600))
        
        // 简化的农历计算（实际算法更复杂）
        let lunarYear = baseLunarYear + daysDiff / 365
        let lunarMonth = (daysDiff % 365) / 30 + 1
        let lunarDay = (daysDiff % 365) % 30 + 1
        
        return (year: lunarYear, month: min(lunarMonth, 12), day: min(lunarDay, 30), isLeapMonth: false)
    }
    
    /// 农历转阳历（简化算法）
    private static func convertLunarToSolar(lunarYear: Int, lunarMonth: Int, lunarDay: Int, isLeapMonth: Bool) -> (year: Int, month: Int, day: Int) {
        // 这是一个简化的算法，实际应用中建议使用专业的农历库
        
        // 农历1900年正月初一对应阳历1900年1月31日
        let baseLunarYear = 1900
        let baseLunarMonth = 1
        let baseLunarDay = 1
        let baseSolarYear = 1900
        let baseSolarMonth = 1
        let baseSolarDay = 31
        
        // 简化的转换计算
        let yearDiff = lunarYear - baseLunarYear
        let monthDiff = lunarMonth - baseLunarMonth
        let dayDiff = lunarDay - baseLunarDay
        
        let totalDays = yearDiff * 365 + monthDiff * 30 + dayDiff
        
        let solarYear = baseSolarYear + totalDays / 365
        let solarMonth = (totalDays % 365) / 30 + 1
        let solarDay = (totalDays % 365) % 30 + 1
        
        return (year: solarYear, month: min(solarMonth, 12), day: min(solarDay, 31))
    }
    
    // MARK: - 动态节日计算方法
    
    /// 获取动态阳历节日
    /// - Parameter year: 年份
    /// - Returns: 动态阳历节日数组
    private static func getDynamicSolarFestivals(for year: Int) -> [TDFestival] {
        var festivals: [TDFestival] = []
        
        // 感恩节：11月第四个星期四
        if let thanksgivingDate = getThanksgivingDate(for: year) {
            festivals.append(TDFestival(
                name: "感恩节",
                date: thanksgivingDate,
                type: .modern,
                description: "感恩节"
            ))
        }
        
        return festivals
    }
    
    /// 获取动态农历节日
    /// - Parameter year: 年份
    /// - Returns: 动态农历节日数组
    private static func getDynamicLunarFestivals(for year: Int) -> [TDFestival] {
        var festivals: [TDFestival] = []
        
        // 除夕：农历十二月最后一天（可能是29日或30日）
        if let newYearEveDate = getNewYearEveDate(for: year) {
            festivals.append(TDFestival(
                name: "除夕",
                date: newYearEveDate,
                type: .traditional,
                description: "除夕"
            ))
        }
        
        return festivals
    }
    
    /// 获取感恩节日期（11月第四个星期四）
    /// - Parameter year: 年份
    /// - Returns: 感恩节日期
    private static func getThanksgivingDate(for year: Int) -> Date? {
        // 11月1日
        var components = DateComponents()
        components.year = year
        components.month = 11
        components.day = 1
        
        guard let november1st = Calendar.current.date(from: components) else { return nil }
        
        // 找到11月第一个星期四
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: november1st)
        let daysToFirstThursday = (5 - weekday + 7) % 7 // 5 = 星期四
        
        guard let firstThursday = calendar.date(byAdding: .day, value: daysToFirstThursday, to: november1st) else { return nil }
        
        // 第四个星期四 = 第一个星期四 + 21天
        return calendar.date(byAdding: .day, value: 21, to: firstThursday)
    }
    
    /// 获取除夕日期（农历十二月最后一天）
    /// - Parameter year: 年份
    /// - Returns: 除夕日期
    private static func getNewYearEveDate(for year: Int) -> Date? {
        // 获取下一年的正月初一
        let nextYear = year + 1
        guard let nextYearSpringFestival = lunarToSolar(lunarYear: nextYear, lunarMonth: 1, lunarDay: 1) else { return nil }
        
        // 除夕 = 正月初一的前一天
        return Calendar.current.date(byAdding: .day, value: -1, to: nextYearSpringFestival)
    }
}

// MARK: - Date 扩展方法

extension Date {
    
    /// 转换为农历
    /// - Returns: 农历日期信息
    func toLunar() -> TDLunarCalendar.TDLunarDate {
        return TDLunarCalendar.solarToLunar(self)
    }
    
    /// 获取农历月日字符串
    /// - Returns: 农历月日字符串，如 "闰六月初四"
    func lunarMonthDayString() -> String {
        let lunar = self.toLunar()
        let leapPrefix = lunar.isLeapMonth ? "闰" : ""
        return "\(leapPrefix)\(lunar.monthName)\(lunar.dayName)"
    }
    
    /// 获取农历年月日字符串
    /// - Returns: 农历年月日字符串，如 "甲子年闰六月初四"
    func lunarFullString() -> String {
        let lunar = self.toLunar()
        let leapPrefix = lunar.isLeapMonth ? "闰" : ""
        return "\(lunar.yearName)年\(leapPrefix)\(lunar.monthName)\(lunar.dayName)"
    }
    
    /// 获取生肖
    /// - Returns: 生肖名称
    func zodiacAnimal() -> String {
        let lunar = self.toLunar()
        return lunar.zodiacAnimal
    }
    
    /// 获取下一年农历同月日的阳历日期
    /// - Parameters:
    ///   - lunarMonth: 农历月
    ///   - lunarDay: 农历日
    ///   - isLeapMonth: 是否闰月
    /// - Returns: 下一年农历同月日的阳历日期
    func nextLunarYearMonthDay(lunarMonth: Int, lunarDay: Int, isLeapMonth: Bool = false) -> Date? {
        let currentLunar = self.toLunar()
        let nextLunarYear = currentLunar.year + 1
        
        return TDLunarCalendar.lunarToSolar(lunarYear: nextLunarYear, lunarMonth: lunarMonth, lunarDay: lunarDay, isLeapMonth: isLeapMonth)
    }
    
    /// 获取当天的节日信息
    /// - Returns: 节日信息（如果当天是节日）
    func getFestival() -> TDLunarCalendar.TDFestival? {
        return TDLunarCalendar.getFestival(for: self)
    }
    
    /// 获取当天的节气信息
    /// - Returns: 节气信息（如果当天是节气）
    func getSolarTerm() -> TDLunarCalendar.TDSolarTerm? {
        return TDLunarCalendar.getSolarTerm(for: self)
    }
    
    /// 获取智能显示信息
    /// 优先级：阳历节假日 > 农历节假日 > 24节气 > 农历显示
    /// - Returns: 智能显示信息
    func getSmartDisplay() -> TDLunarCalendar.TDSmartDisplayInfo {
        return TDLunarCalendar.getSmartDisplay(for: self)
    }
    
    /// 获取智能显示文本
    /// - Returns: 显示文本
    func smartDisplayText() -> String {
        return getSmartDisplay().displayText
    }
}
