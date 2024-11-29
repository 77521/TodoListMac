//
//  TDCalendarDataManager.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/27.
//

import Foundation
import SwiftUI
import SwiftDate
import OSLog
import LunarSwift

// MARK: - 日历数据管理器
// MARK: - 日历数据管理器
actor TDCalendarDataManager {
    static let shared = TDCalendarDataManager()
    
    private var calendarCache: [String: [TDCalendarDay]] = [:]
    private var isInitialized = false
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TDCalendar", category: "Calendar")
    
    private init() {}
    
    // MARK: - 公共方法
    
    /// 初始化日历数据
    func initialize() async throws {
        guard !isInitialized else { return }
        
        logger.info("开始初始化日历数据: \(TDCalendarConstants.minimumYear)-\(TDCalendarConstants.maximumYear)")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 尝试从缓存加载
        do {
            if let cached = try TDCalendarCacheManager.shared.loadCache() {
                self.calendarCache = cached
                isInitialized = true
                logger.info("从缓存加载日历数据成功")
                return
            }
        } catch {
            logger.error("加载缓存失败: \(error.localizedDescription)")
        }
        
        // 生成所有年份的数据
        var progress = 0
        let totalYears = TDCalendarConstants.maximumYear - TDCalendarConstants.minimumYear + 1
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for year in TDCalendarConstants.minimumYear...TDCalendarConstants.maximumYear {
                group.addTask {
                    try await self.generateYearData(year)
                    progress += 1
                    let percentage = Double(progress) / Double(totalYears) * 100
                    self.logger.info("数据生成进度: \(String(format: "%.1f%%", percentage))")
                }
            }
            
            try await group.waitForAll()
        }
        
        // 保存到缓存
        do {
            try TDCalendarCacheManager.shared.saveCache(calendarCache)
            logger.info("保存缓存成功")
        } catch {
            logger.error("保存缓存失败: \(error.localizedDescription)")
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("日历数据初始化完成，耗时: \(String(format: "%.2f", timeElapsed))秒")
        
        isInitialized = true
    }
    
    /// 获取指定月份的日历数据
    func getDaysForMonth(year: Int, month: Int) async throws -> [TDCalendarDay] {
        let key = "\(year)-\(month)"
        
        if let cachedDays = calendarCache[key] {
            return cachedDays.map { updateDayStatus($0) }
        }
        
        // 如果缓存中没有，尝试生成数据
        let days = try await generateMonthData(year: year, month: month)
        calendarCache[key] = days
        return days
    }
    // MARK: - 私有方法
    
    /// 更新日期状态（主要是更新 isToday 标记）
    private func updateDayStatus(_ day: TDCalendarDay) -> TDCalendarDay {
        let isToday = day.date.isToday
        if day.isToday != isToday {
            return TDCalendarDay(
                id: day.id,
                date: day.date,
                solarDay: day.solarDay,
                lunarDay: day.lunarDay,
                lunarMonth: day.lunarMonth,
                isLunarFirstDay: day.isLunarFirstDay,
                solarTerm: day.solarTerm,
                festival: day.festival,
                workdayType: day.workdayType,
                isToday: isToday,
                isCurrentMonth: day.isCurrentMonth,
                isWeekend: day.isWeekend
            )
        }
        return day
    }
    
    /// 生成指定年份的数据
    private func generateYearData(_ year: Int) async throws {
        for month in 1...12 {
            let key = "\(year)-\(month)"
            if calendarCache[key] == nil {
                let days = try await generateMonthData(year: year, month: month)
                calendarCache[key] = days
            }
        }
    }
    
    /// 生成指定月份的数据
    private func generateMonthData(year: Int, month: Int) async throws -> [TDCalendarDay] {
        // 使用 try? 来处理可能的初始化失败
//        let monthStart = DateInRegion(
//            components: DateComponents(year: year, month: month, day: 1),
//            region: .current
//        )
        guard let monthStart = DateInRegion(
                components: DateComponents(year: year, month: month, day: 1),
                region: .current
            ) else {
                throw TDCalendarError.invalidDate
            }
//        guard let monthStart = monthStart else {
//            throw TDCalendarError.invalidDate
//        }

        var days: [TDCalendarDay] = []
        let calendar = Calendar.current
        let firstWeekday = TDSettingManager.shared.firstWeekday

        // 获取这个月的第一天是星期几
        let firstWeekdayOfMonth = calendar.component(.weekday, from: monthStart.date)
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart.date)?.count ?? 30

        // 添加上个月的日期
        let previousMonthDays = (firstWeekdayOfMonth - firstWeekday + 7) % 7
        if previousMonthDays > 0 {
                // 直接计算上个月的年月
                let previousDate = monthStart.date.addingTimeInterval(-86400 * 15) // 确保在上个月
                let previousMonth = DateInRegion(previousDate, region: .current)
                
                let previousMonthDaysCount = calendar.range(of: .day, in: .month, for: previousMonth.date)?.count ?? 30
                let startDay = previousMonthDaysCount - previousMonthDays + 1
                
            for day in startDay...previousMonthDaysCount {
                        guard let date = DateInRegion(
                            components: DateComponents(
                                year: previousMonth.year,
                                month: previousMonth.month,
                                day: day
                            ),
                            region: .current
                        ) else { continue }
                        
                        days.append(try await createCalendarDay(date: date, isCurrentMonth: false))
                    }
            }
        
        // 添加当前月的日期
        for day in 1...daysInMonth {
            guard let date = DateInRegion(
                components: DateComponents(
                    year: year,
                    month: month,
                    day: day
                ),
                region: .current
            ) else { continue }
            
            days.append(try await createCalendarDay(date: date, isCurrentMonth: true))
        }
        
        // 添加下个月的日期以填满6行
        let remainingDays = 42 - days.count
        if remainingDays > 0 {
            // 直接计算下个月的年月
            let nextDate = monthStart.date.addingTimeInterval(86400 * 32) // 确保在下个月
            let nextMonth = DateInRegion(nextDate, region: .current)
            
            for day in 1...remainingDays {
                guard let date = DateInRegion(
                    components: DateComponents(
                        year: nextMonth.year,
                        month: nextMonth.month,
                        day: day
                    ),
                    region: .current
                ) else { continue }
                
                days.append(try await createCalendarDay(date: date, isCurrentMonth: false))
            }
        }
        
        return days
    }
    /// 创建日历日期对象
    private func createCalendarDay(date: DateInRegion, isCurrentMonth: Bool) async throws -> TDCalendarDay {
        let solar = Solar(year: date.year, month: date.month, day: date.day)
        let lunar = solar.lunar
        
        // 获取节日信息（包括农历节日和节气）
        let festival = try await TDFestivalManager.shared.getFestival(
            solarDate: date,
            lunar: lunar
        )
        
        return TDCalendarDay(
            id: UUID(),
            date: date,
            solarDay: date.day,
            lunarDay: lunar.dayInChinese,
            lunarMonth: lunar.monthInChinese,
            isLunarFirstDay: lunar.day == 1,
            solarTerm: lunar.jieQi.isEmpty ? nil : lunar.jieQi,
            festival: festival,
            workdayType: festival?.isHoliday == true ? .holiday : (date.date.isWeekend ? .weekend : .normal),
            isToday: date.isToday,
            isCurrentMonth: isCurrentMonth,
            isWeekend: date.date.isWeekend
        )
    }}
