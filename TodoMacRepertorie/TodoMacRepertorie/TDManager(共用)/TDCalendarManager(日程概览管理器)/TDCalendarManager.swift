////
////  TDCalendarManager.swift
////  TodoMacRepertorie
////
////  Created by 赵浩 on 2025/3/4.
////
//
//import Foundation
//
//@MainActor
//final class TDCalendarManager: ObservableObject {
//    static let shared = TDCalendarManager()
//    
//    private let settingManager = TDSettingManager.shared
//    private let queryManager = TDQueryConditionManager.shared
//    private let calendar = Calendar.current
//    
//    /// 当前选中日期
//    /// 当前选中日期
//    @Published var selectedDate = Date() {
//        didSet {
//            // 当日期变化时，自动更新日历数据
//            Task {
//                try? await updateCalendarData()
//            }
//        }
//    }
//    /// 当前月份的日期数据
//    @Published var calendarDates: [[TDCalendarDateModel]] = []
//    /// 当前视图高度
//    @Published var viewHeight: CGFloat = 0
//    
//    private init() {}
//    
//    /// 更新日历数据
//    func updateCalendarData() async throws {
//        // 1. 获取当月第一天和最后一天
//        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
//        let lastDayOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth)!
//
//        // 2. 计算需要显示的行数
//        let numberOfWeeks = calculateNumberOfWeeks(firstDay: firstDayOfMonth, lastDay: lastDayOfMonth)
//        
//        // 3. 获取需要显示的所有日期
//        let allDates = generateDatesForCalendar(firstDay: firstDayOfMonth, numberOfWeeks: numberOfWeeks)
//        
//        // 4. 获取农历和节日信息
//        let datesWithLunar = await addLunarAndHolidayInfo(to: allDates)
//        
//        // 5. 获取任务数据
//        let datesWithTasks = try await addTasksToDate(dates: datesWithLunar)
//
//        // 6. 按周分组
//        calendarDates = groupByWeek(dates: datesWithTasks, numberOfWeeks: numberOfWeeks)
//    }
//    
//    /// 计算需要显示的行数
//    private func calculateNumberOfWeeks(firstDay: Date, lastDay: Date) -> Int {
//        let firstWeekday = calendar.component(.weekday, from: firstDay)
//        let totalDays = calendar.component(.day, from: lastDay)
//        let firstWeekdayOfMonth = settingManager.isFirstDayMonday ?
//            (firstWeekday + 5) % 7 : (firstWeekday - 1)
//        
//        let totalCells = firstWeekdayOfMonth + totalDays
//        return Int(ceil(Double(totalCells) / 7.0))
//    }
//    
//    /// 生成日历需要显示的所有日期
//    private func generateDatesForCalendar(firstDay: Date, numberOfWeeks: Int) -> [Date] {
//        var dates: [Date] = []
//        let firstWeekday = calendar.component(.weekday, from: firstDay)
//        let offsetDays = settingManager.isFirstDayMonday ?
//            ((firstWeekday + 5) % 7) : (firstWeekday - 1)
//        
//        // 添加上月日期
//        if offsetDays > 0 {
//            for day in (1...offsetDays).reversed() {
//                if let date = calendar.date(byAdding: .day, value: -day, to: firstDay) {
//                    dates.append(date)
//                }
//            }
//        }
//        
//        // 添加当月日期
//        var currentDate = firstDay
//        while calendar.component(.month, from: currentDate) == calendar.component(.month, from: firstDay) {
//            dates.append(currentDate)
//            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
//        }
//        
//        // 添加下月日期
//        let remainingDays = numberOfWeeks * 7 - dates.count
//        for day in 0..<remainingDays {
//            if let date = calendar.date(byAdding: .day, value: day, to: currentDate) {
//                dates.append(date)
//            }
//        }
//        
//        return dates
//    }
//    
//    /// 添加农历和节日信息
//    private func addLunarAndHolidayInfo(to dates: [Date]) async -> [TDCalendarDateModel] {
//        let chineseCalendar = Calendar(identifier: .chinese)
//        let today = Date()
//        
//        return dates.map { date in
//            // 1. 创建基础模型
//            var model = TDCalendarDateModel(
//                date: date,
//                lunarDate: getLunarString(for: date, calendar: chineseCalendar),
//                isToday: calendar.isDate(date, inSameDayAs: today),
//                isCurrentMonth: calendar.component(.month, from: date) == calendar.component(.month, from: selectedDate)
//            )
//            
//            // 2. 添加节日信息
//            let holidayInfo = getHolidayInfo(for: date)
//            model.holidayType = holidayInfo.type
//            model.holidayName = holidayInfo.name
//            model.isWorkday = holidayInfo.isWorkday
//            model.isHoliday = holidayInfo.isHoliday
//            
//            return model
//        }
//    }
//    
//    /// 获取农历日期字符串
//    private func getLunarString(for date: Date, calendar: Calendar) -> String {
//        let components = calendar.dateComponents([.year, .month, .day], from: date)
//        let lunarDay = getLunarDay(components.day ?? 1)
//        
//        // 如果是初一，显示月份
//        if components.day == 1 {
//            let lunarMonth = getLunarMonth(components.month ?? 1)
//            return lunarMonth
//        }
//        
//        return lunarDay
//    }
//    
//    /// 获取农历日
//    private func getLunarDay(_ day: Int) -> String {
//        let lunarDays = ["初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
//                        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
//                        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]
//        return lunarDays[day - 1]
//    }
//    
//    /// 获取农历月
//    private func getLunarMonth(_ month: Int) -> String {
//        let lunarMonths = ["正月", "二月", "三月", "四月", "五月", "六月",
//                          "七月", "八月", "九月", "十月", "冬月", "腊月"]
//        return lunarMonths[month - 1]
//    }
//    
//    /// 获取节日信息
//    private func getHolidayInfo(for date: Date) -> (type: TDHolidayType, name: String, isWorkday: Bool, isHoliday: Bool) {
//        // TODO: 实现节日判断逻辑
//        // 这里需要添加一个节日数据源，包含：
//        // 1. 法定节假日
//        // 2. 公历节日
//        // 3. 农历节日
//        // 4. 24节气
//        // 5. 调休安排
//        return (.none, "", false, false)
//    }
//    
//    /// 添加任务数据
//    private func addTasksToDate(dates: [TDCalendarDateModel]) async throws -> [TDCalendarDateModel] {
//        var updatedDates = dates
//        
//        for (index, date) in dates.enumerated() {
//            let tasks = try await queryManager.queryTasksByDate(timestamp: date.date.startOfDayTimestamp)
//            updatedDates[index].tasks = tasks
//        }
//        
//        return updatedDates
//    }
//    
//    /// 按周分组
//    private func groupByWeek(dates: [TDCalendarDateModel], numberOfWeeks: Int) -> [[TDCalendarDateModel]] {
//        var weeks: [[TDCalendarDateModel]] = []
//        var currentWeek: [TDCalendarDateModel] = []
//        
//        for date in dates {
//            currentWeek.append(date)
//            if currentWeek.count == 7 {
//                weeks.append(currentWeek)
//                currentWeek = []
//            }
//        }
//        
//        return weeks
//    }
//    
//    /// 更新视图高度
//    func updateViewHeight(_ height: CGFloat) {
//        viewHeight = height
//    }
//}
