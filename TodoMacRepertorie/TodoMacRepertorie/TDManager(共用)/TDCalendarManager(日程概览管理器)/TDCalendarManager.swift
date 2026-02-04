//////
//////  TDCalendarManager.swift
//////  TodoMacRepertorie
//////
//////  Created by 赵浩 on 2025/3/4.
//////
////
////import Foundation
////
////@MainActor
////final class TDCalendarManager: ObservableObject {
////    static let shared = TDCalendarManager()
////
////    private let settingManager = TDSettingManager.shared
////    private let queryManager = TDQueryConditionManager.shared
////    private let calendar = Calendar.current
////
////    /// 当前选中日期
////    /// 当前选中日期
////    @Published var selectedDate = Date() {
////        didSet {
////            // 当日期变化时，自动更新日历数据
////            Task {
////                try? await updateCalendarData()
////            }
////        }
////    }
////    /// 当前月份的日期数据
////    @Published var calendarDates: [[TDCalendarDateModel]] = []
////    /// 当前视图高度
////    @Published var viewHeight: CGFloat = 0
////
////    private init() {}
////
////    /// 更新日历数据
////    func updateCalendarData() async throws {
////        // 1. 获取当月第一天和最后一天
////        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
////        let lastDayOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth)!
////
////        // 2. 计算需要显示的行数
////        let numberOfWeeks = calculateNumberOfWeeks(firstDay: firstDayOfMonth, lastDay: lastDayOfMonth)
////
////        // 3. 获取需要显示的所有日期
////        let allDates = generateDatesForCalendar(firstDay: firstDayOfMonth, numberOfWeeks: numberOfWeeks)
////
////        // 4. 获取农历和节日信息
////        let datesWithLunar = await addLunarAndHolidayInfo(to: allDates)
////
////        // 5. 获取任务数据
////        let datesWithTasks = try await addTasksToDate(dates: datesWithLunar)
////
////        // 6. 按周分组
////        calendarDates = groupByWeek(dates: datesWithTasks, numberOfWeeks: numberOfWeeks)
////    }
////
////    /// 计算需要显示的行数
////    private func calculateNumberOfWeeks(firstDay: Date, lastDay: Date) -> Int {
////        let firstWeekday = calendar.component(.weekday, from: firstDay)
////        let totalDays = calendar.component(.day, from: lastDay)
////        let firstWeekdayOfMonth = settingManager.isFirstDayMonday ?
////            (firstWeekday + 5) % 7 : (firstWeekday - 1)
////
////        let totalCells = firstWeekdayOfMonth + totalDays
////        return Int(ceil(Double(totalCells) / 7.0))
////    }
////
////    /// 生成日历需要显示的所有日期
////    private func generateDatesForCalendar(firstDay: Date, numberOfWeeks: Int) -> [Date] {
////        var dates: [Date] = []
////        let firstWeekday = calendar.component(.weekday, from: firstDay)
////        let offsetDays = settingManager.isFirstDayMonday ?
////            ((firstWeekday + 5) % 7) : (firstWeekday - 1)
////
////        // 添加上月日期
////        if offsetDays > 0 {
////            for day in (1...offsetDays).reversed() {
////                if let date = calendar.date(byAdding: .day, value: -day, to: firstDay) {
////                    dates.append(date)
////                }
////            }
////        }
////
////        // 添加当月日期
////        var currentDate = firstDay
////        while calendar.component(.month, from: currentDate) == calendar.component(.month, from: firstDay) {
////            dates.append(currentDate)
////            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
////        }
////
////        // 添加下月日期
////        let remainingDays = numberOfWeeks * 7 - dates.count
////        for day in 0..<remainingDays {
////            if let date = calendar.date(byAdding: .day, value: day, to: currentDate) {
////                dates.append(date)
////            }
////        }
////
////        return dates
////    }
////
////    /// 添加农历和节日信息
////    private func addLunarAndHolidayInfo(to dates: [Date]) async -> [TDCalendarDateModel] {
////        let chineseCalendar = Calendar(identifier: .chinese)
////        let today = Date()
////
////        return dates.map { date in
////            // 1. 创建基础模型
////            var model = TDCalendarDateModel(
////                date: date,
////                lunarDate: getLunarString(for: date, calendar: chineseCalendar),
////                isToday: calendar.isDate(date, inSameDayAs: today),
////                isCurrentMonth: calendar.component(.month, from: date) == calendar.component(.month, from: selectedDate)
////            )
////
////            // 2. 添加节日信息
////            let holidayInfo = getHolidayInfo(for: date)
////            model.holidayType = holidayInfo.type
////            model.holidayName = holidayInfo.name
////            model.isWorkday = holidayInfo.isWorkday
////            model.isHoliday = holidayInfo.isHoliday
////
////            return model
////        }
////    }
////
////    /// 获取农历日期字符串
////    private func getLunarString(for date: Date, calendar: Calendar) -> String {
////        let components = calendar.dateComponents([.year, .month, .day], from: date)
////        let lunarDay = getLunarDay(components.day ?? 1)
////
////        // 如果是初一，显示月份
////        if components.day == 1 {
////            let lunarMonth = getLunarMonth(components.month ?? 1)
////            return lunarMonth
////        }
////
////        return lunarDay
////    }
////
////    /// 获取农历日
////    private func getLunarDay(_ day: Int) -> String {
////        let lunarDays = ["初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
////                        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
////                        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]
////        return lunarDays[day - 1]
////    }
////
////    /// 获取农历月
////    private func getLunarMonth(_ month: Int) -> String {
////        let lunarMonths = ["正月", "二月", "三月", "四月", "五月", "六月",
////                          "七月", "八月", "九月", "十月", "冬月", "腊月"]
////        return lunarMonths[month - 1]
////    }
////
////    /// 获取节日信息
////    private func getHolidayInfo(for date: Date) -> (type: TDHolidayType, name: String, isWorkday: Bool, isHoliday: Bool) {
////        // TODO: 实现节日判断逻辑
////        // 这里需要添加一个节日数据源，包含：
////        // 1. 法定节假日
////        // 2. 公历节日
////        // 3. 农历节日
////        // 4. 24节气
////        // 5. 调休安排
////        return (.none, "", false, false)
////    }
////
////    /// 添加任务数据
////    private func addTasksToDate(dates: [TDCalendarDateModel]) async throws -> [TDCalendarDateModel] {
////        var updatedDates = dates
////
////        for (index, date) in dates.enumerated() {
////            let tasks = try await queryManager.queryTasksByDate(timestamp: date.date.startOfDayTimestamp)
////            updatedDates[index].tasks = tasks
////        }
////
////        return updatedDates
////    }
////
////    /// 按周分组
////    private func groupByWeek(dates: [TDCalendarDateModel], numberOfWeeks: Int) -> [[TDCalendarDateModel]] {
////        var weeks: [[TDCalendarDateModel]] = []
////        var currentWeek: [TDCalendarDateModel] = []
////
////        for date in dates {
////            currentWeek.append(date)
////            if currentWeek.count == 7 {
////                weeks.append(currentWeek)
////                currentWeek = []
////            }
////        }
////
////        return weeks
////    }
////
////    /// 更新视图高度
////    func updateViewHeight(_ height: CGFloat) {
////        viewHeight = height
////    }
////}
//
//
////
////  TDCalendarManager.swift
////  TodoMacRepertorie
////
////  Created by 赵浩 on 2025/3/4.
////
//
//import Foundation
//import SwiftUI
//import Combine
//
///// 日历管理器 - 负责日历数据的计算、农历转换、节日判断和任务加载
//final class TDCalendarManager: ObservableObject {
//    /// 单例实例
//    static let shared = TDCalendarManager()
//
//    /// 设置管理器
//    private let settingManager = TDSettingManager.shared
//
//    /// 日历实例
//    private let calendar = Calendar.current
//
//    /// 当前选中日期 - 从 TDScheduleOverviewViewModel 获取
//    private var selectedDate: Date {
//        TDScheduleOverviewViewModel.shared.currentDate
//    }
//
//    /// 当前月份的日期数据 - 按周分组的二维数组
//    @Published var calendarDates: [[TDCalendarDateModel]] = []
//
//    /// 当前视图高度 - 用于动态调整日历高度
//    @Published var viewHeight: CGFloat = 0
//    /// 当前显示的月份 - 用于判断是否需要重新计算日历数据
//    private var currentDisplayMonth: Date = Date()
//
//
//    /// 私有初始化方法
//    /// 私有初始化方法
//    private init() {
//        // 监听 TDScheduleOverviewViewModel 的 currentDate 变化
//        TDScheduleOverviewViewModel.shared.$currentDate
//            .sink { [weak self] newDate in
//                // 点击日历单元格时，只更新选中状态，不重新计算日历数据
//                guard let self = self else { return }
//
//                Task {
//                    try? await self.updateSelectedStateOnly()
//                }
//            }
//            .store(in: &cancellables)
//    }
//    /// 取消订阅
//    private var cancellables = Set<AnyCancellable>()
//
//    /// 只更新选中状态，不重新计算日历数据
//    @MainActor
//    private func updateSelectedStateOnly() async throws {
//        // 只更新现有日历数据中的选中状态
//        for weekIndex in 0..<calendarDates.count {
//            for dayIndex in 0..<calendarDates[weekIndex].count {
//                let date = calendarDates[weekIndex][dayIndex].date
//                let isSelected = date.isSameDay(as: selectedDate)
//                calendarDates[weekIndex][dayIndex].isSelected = isSelected
//            }
//        }
//    }
//
//
//    /// 更新日历数据 - 主要的数据更新方法
//    func updateCalendarData() async throws {
//        // 1. 获取当月第一天和最后一天
//        let firstDayOfMonth = selectedDate.firstDayOfMonth
//        let lastDayOfMonth = selectedDate.lastDayOfMonth
//
//        // 2. 计算需要显示的行数（5-6行）
//        let numberOfWeeks = calculateNumberOfWeeks(firstDay: firstDayOfMonth, lastDay: lastDayOfMonth)
//
//        // 3. 获取需要显示的所有日期（包括上月和下月的日期）
//        let allDates = generateDatesForCalendar(firstDay: firstDayOfMonth, numberOfWeeks: numberOfWeeks)
//
//        // 4. 获取农历和节日信息
//        let datesWithLunar = await addLunarAndHolidayInfo(to: allDates)
//
//
//        // 5. 按周分组（每行7天）
//        await MainActor.run {
//            calendarDates = groupByWeek(dates: datesWithLunar, numberOfWeeks: numberOfWeeks)
//
//        }
//
////        calendarDates = groupByWeek(dates: datesWithTasks, numberOfWeeks: numberOfWeeks)
//    }
//
//    /// 计算需要显示的行数 - 根据当月第一天和最后一天计算需要的周数
//    /// - Parameters:
//    ///   - firstDay: 当月第一天
//    ///   - lastDay: 当月最后一天
//    /// - Returns: 需要显示的行数（5-6行）
//    private func calculateNumberOfWeeks(firstDay: Date, lastDay: Date) -> Int {
//        let firstWeekday = calendar.component(.weekday, from: firstDay)
//        let totalDays = calendar.component(.day, from: lastDay)
//
//        // 根据设置计算当月第一天是周几（0=周日，1=周一...）
//        let firstWeekdayOfMonth = settingManager.isFirstDayMonday ?
//            (firstWeekday + 5) % 7 : (firstWeekday - 1)
//
//        // 计算总单元格数（上月填充 + 当月天数）
//        let totalCells = firstWeekdayOfMonth + totalDays
//
//        // 向上取整得到需要的行数
//        return Int(ceil(Double(totalCells) / 7.0))
//    }
//
//    /// 生成日历需要显示的所有日期 - 包括上月、当月、下月的日期
//    /// - Parameters:
//    ///   - firstDay: 当月第一天
//    ///   - numberOfWeeks: 需要显示的行数
//    /// - Returns: 所有需要显示的日期数组
//    private func generateDatesForCalendar(firstDay: Date, numberOfWeeks: Int) -> [Date] {
//        var dates: [Date] = []
//        let firstWeekday = calendar.component(.weekday, from: firstDay)
//
//        // 计算需要填充的上月日期数量
//        let offsetDays = settingManager.isFirstDayMonday ?
//            ((firstWeekday + 5) % 7) : (firstWeekday - 1)
//
//        // 添加上月日期（从后往前添加）
//        if offsetDays > 0 {
//            for day in (1...offsetDays).reversed() {
//                if let date = calendar.date(byAdding: .day, value: -day, to: firstDay) {
//                    dates.append(date)
//                }
//            }
//        }
//
//        // 添加当月所有日期
//        var currentDate = firstDay
//        while calendar.component(.month, from: currentDate) == calendar.component(.month, from: firstDay) {
//            dates.append(currentDate)
//            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
//        }
//
//        // 添加下月日期（填充剩余位置）
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
//
//
//    /// 添加农历和节日信息 - 为每个日期添加农历、节日、工作日等信息
//    /// - Parameter dates: 需要处理的日期数组
//    /// - Returns: 包含完整信息的日历日期模型数组
//    private func addLunarAndHolidayInfo(to dates: [Date]) async -> [TDCalendarDateModel] {
//
//        return dates.map { date in
//            // 1. 创建基础模型
//            let isCurrentMonth = calendar.component(.month, from: date) == calendar.component(.month, from: selectedDate)
//            let isToday = date.isToday
//
//            // 2. 获取智能显示信息（使用Date-Extension中的方法）
//            let smartDisplay = date.smartDisplay
//
//            // 3. 判断是否在节假日数据中
//            let isInHolidayData = date.isInHolidayData
//
//            // 4. 判断是否为节假日
//            let isHoliday = isInHolidayData ? date.isHoliday : false
//
//            // 5. 判断是否为选中状态（与当前选中日期比较）
//            let isSelected = date.isSameDay(as: selectedDate)
//
//            return TDCalendarDateModel(
//                date: date,
//                isToday: isToday,
//                isCurrentMonth: isCurrentMonth,
//                isHoliday: isHoliday,
//                isInHolidayData: isInHolidayData,
//                smartDisplay: smartDisplay,
//                isSelected: isSelected
//            )
//        }
//    }
//    /// 按周分组 - 将日期数组按每7天一组进行分组
//    /// - Parameters:
//    ///   - dates: 需要分组的日期数组
//    ///   - numberOfWeeks: 周数
//    /// - Returns: 按周分组的二维数组
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
//    /// 更新视图高度 - 用于动态调整日历高度
//    /// - Parameter height: 新的视图高度
//    func updateViewHeight(_ height: CGFloat) {
//        viewHeight = height
//    }
//    /// 选择日期 - 更新 TDScheduleOverviewViewModel 的 currentDate
//    /// - Parameter date: 要选中的日期
//    func selectDate(_ date: Date) {
//        TDScheduleOverviewViewModel.shared.updateCurrentDate(date)
//    }
//
//
//}
//


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


//
//  TDCalendarManager.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/3/4.
//

import Foundation
import SwiftUI
// Combine 目前未使用（历史上用于监听选中日期）

/// 日历管理器 - 负责日历数据的计算、农历转换、节日判断和任务加载
final class TDCalendarManager: ObservableObject {
    /// 单例实例
    static let shared = TDCalendarManager()
    
    /// 设置管理器
    private let settingManager = TDSettingManager.shared
    
    /// 日历实例
    private let calendar = Calendar.current
    
    /// 当前选中日期 - 从 TDScheduleOverviewViewModel 获取
    /// 注意：这里用于“日历网格月份计算”，所以使用 `displayMonth` 而不是 `currentDate`
    private var selectedDate: Date {
        TDScheduleOverviewViewModel.shared.displayMonth
    }

    /// 当前月份的日期数据 - 按周分组的二维数组
    @Published var calendarDates: [[TDCalendarDateModel]] = []
    
    /// 当前视图高度 - 用于动态调整日历高度
    @Published var viewHeight: CGFloat = 0
    /// 当前显示的月份 - 用于判断是否需要重新计算日历数据
    private var currentDisplayMonth: Date = Date()
    
    /// 日期信息缓存 - 使用时间戳作为key，避免重复计算
    private var dateInfoCache: [Int64: TDCalendarDateModel] = [:]
    
    /// 节假日数据索引 - 使用时间戳作为key，快速查找
    private var holidayIndex: [Int64: TDHolidayItem] = [:]
    
    /// 上次更新节假日索引的月份 - 用于判断是否需要重新构建索引
    private var lastHolidayIndexMonth: Date?

    /// 私有初始化方法
    private init() {
        // 说明：
        // 选中态不再通过“写回 calendarDates”实现（那会导致全量发布/重渲染）。
        // 现在由 UI 层直接基于 `TDScheduleOverviewViewModel.shared.currentDate` 计算是否选中。
    }
    // 预留：未来如需订阅可在此添加 Combine cancellables
    
    /// 清理缓存 - 在内存警告时调用
    func clearCache() {
        dateInfoCache.removeAll()
        // 保留节假日索引，因为它很小且经常使用
    }

    
    /// 更新日历数据 - 主要的数据更新方法
    func updateCalendarData() async throws {
        // 1. 获取当月第一天和最后一天
        let firstDayOfMonth = selectedDate.firstDayOfMonth
        let lastDayOfMonth = selectedDate.lastDayOfMonth

        // 2. 计算需要显示的行数（5-6行）
        let numberOfWeeks = calculateNumberOfWeeks(firstDay: firstDayOfMonth, lastDay: lastDayOfMonth)
        
        // 3. 获取需要显示的所有日期（包括上月和下月的日期）
        let allDates = generateDatesForCalendar(firstDay: firstDayOfMonth, numberOfWeeks: numberOfWeeks)
        
        // 4. 获取农历和节日信息
        let datesWithLunar = await addLunarAndHolidayInfo(to: allDates)
        

        // 5. 按周分组（每行7天）
        await MainActor.run {
            calendarDates = groupByWeek(dates: datesWithLunar, numberOfWeeks: numberOfWeeks)

        }

//        calendarDates = groupByWeek(dates: datesWithTasks, numberOfWeeks: numberOfWeeks)
    }
    
    /// 计算需要显示的行数 - 根据当月第一天和最后一天计算需要的周数
    /// - Parameters:
    ///   - firstDay: 当月第一天
    ///   - lastDay: 当月最后一天
    /// - Returns: 需要显示的行数（5-6行）
    private func calculateNumberOfWeeks(firstDay: Date, lastDay: Date) -> Int {
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let totalDays = calendar.component(.day, from: lastDay)
        
        // 根据设置计算当月第一天是周几（0=周日，1=周一...）
        let firstWeekdayOfMonth = settingManager.isFirstDayMonday ?
            (firstWeekday + 5) % 7 : (firstWeekday - 1)
        
        // 计算总单元格数（上月填充 + 当月天数）
        let totalCells = firstWeekdayOfMonth + totalDays
        
        // 向上取整得到需要的行数
        return Int(ceil(Double(totalCells) / 7.0))
    }
    
    /// 生成日历需要显示的所有日期 - 包括上月、当月、下月的日期
    /// - Parameters:
    ///   - firstDay: 当月第一天
    ///   - numberOfWeeks: 需要显示的行数
    /// - Returns: 所有需要显示的日期数组
    private func generateDatesForCalendar(firstDay: Date, numberOfWeeks: Int) -> [Date] {
        var dates: [Date] = []
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        
        // 计算需要填充的上月日期数量
        let offsetDays = settingManager.isFirstDayMonday ?
            ((firstWeekday + 5) % 7) : (firstWeekday - 1)
        
        // 添加上月日期（从后往前添加）
        if offsetDays > 0 {
            for day in (1...offsetDays).reversed() {
                if let date = calendar.date(byAdding: .day, value: -day, to: firstDay) {
                    dates.append(date)
                }
            }
        }
        
        // 添加当月所有日期
        var currentDate = firstDay
        while calendar.component(.month, from: currentDate) == calendar.component(.month, from: firstDay) {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // 添加下月日期（填充剩余位置）
        let remainingDays = numberOfWeeks * 7 - dates.count
        for day in 0..<remainingDays {
            if let date = calendar.date(byAdding: .day, value: day, to: currentDate) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    
    
    /// 添加农历和节日信息 - 为每个日期添加农历、节日、工作日等信息
    /// - Parameter dates: 需要处理的日期数组
    /// - Returns: 包含完整信息的日历日期模型数组
    private func addLunarAndHolidayInfo(to dates: [Date]) async -> [TDCalendarDateModel] {
        
        return dates.map { date in
            // 1. 创建基础模型
            let isCurrentMonth = calendar.component(.month, from: date) == calendar.component(.month, from: selectedDate)
            let isToday = date.isToday
            
            // 2. 获取智能显示信息（使用Date-Extension中的方法）
            let smartDisplay = date.smartDisplay
            
            // 3. 判断是否在节假日数据中
            let isInHolidayData = date.isInHolidayData
            
            // 4. 判断是否为节假日
            let isHoliday = isInHolidayData ? date.isHoliday : false
            
            // 5. 判断是否为选中状态
            // 注意：此处仅用于初始生成；真正的选中态由 UI 层动态计算，避免写回造成的全量更新
            let isSelected = false

            return TDCalendarDateModel(
                date: date,
                isToday: isToday,
                isCurrentMonth: isCurrentMonth,
                isHoliday: isHoliday,
                isInHolidayData: isInHolidayData,
                smartDisplay: smartDisplay,
                isSelected: isSelected
            )
        }
    }
    /// 按周分组 - 将日期数组按每7天一组进行分组
    /// - Parameters:
    ///   - dates: 需要分组的日期数组
    ///   - numberOfWeeks: 周数
    /// - Returns: 按周分组的二维数组
    private func groupByWeek(dates: [TDCalendarDateModel], numberOfWeeks: Int) -> [[TDCalendarDateModel]] {
        var weeks: [[TDCalendarDateModel]] = []
        var currentWeek: [TDCalendarDateModel] = []
        
        for date in dates {
            currentWeek.append(date)
            if currentWeek.count == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }
        }
        
        return weeks
    }
    
    /// 更新视图高度 - 用于动态调整日历高度
    /// - Parameter height: 新的视图高度
    func updateViewHeight(_ height: CGFloat) {
        viewHeight = height
    }
    /// 选择日期 - 更新 TDScheduleOverviewViewModel 的 currentDate
    /// - Parameter date: 要选中的日期
    func selectDate(_ date: Date) {
        TDScheduleOverviewViewModel.shared.updateCurrentDate(date)
    }


}

