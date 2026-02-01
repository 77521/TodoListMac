//
//  TDLunarCalendar.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import LunarSwift

/// 农历工具类 - 基于 LunarSwift 库的农历转换
class TDLunarCalendar {
    
    // MARK: - Private helpers
    
    /// 将 `Date` 可靠地转换为 `Solar`（强制使用公历，避免 `Calendar.current` 非公历时组件异常）
    private static func makeSolar(from date: Date) -> Solar {
        let gregorian = Calendar(identifier: .gregorian)
        let components = gregorian.dateComponents(in: TimeZone.current, from: date)
        
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = components.second ?? 0
        
        // 兜底：LunarSwift 内部对非法日期可能直接 fatalError，这里先挡住明显非法的输入
        guard (1...9999).contains(year),
              (1...12).contains(month),
              (1...31).contains(day),
              (0...23).contains(hour),
              (0...59).contains(minute),
              (0...59).contains(second) else {
            return Solar.fromYmdHms(year: 1970, month: 1, day: 1, hour: 0, minute: 0, second: 0)
        }
        
        return Solar.fromYmdHms(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
    }

    
    // MARK: - 阳历转农历
    
    static func solarToLunar(_ date: Date) -> Lunar {
        // 注意：不要直接用 Solar.fromDate(date:)（它可能依赖 Calendar.current，某些场景会取到异常组件导致偶发崩溃）
        let solar = makeSolar(from: date)
        let lunar = Lunar.fromSolar(solar: solar)
        
        return lunar
    }

    // MARK: - 农历转阳历
    
    /// 根据传入的农历日期，转成阳历日期
    /// - Parameters:
    ///   - lunarYear: 农历年
    ///   - lunarMonth: 农历月
    ///   - lunarDay: 农历日
    /// - Returns: 阳历日期
    static func lunarToSolar(lunarYear: Int, lunarMonth: Int, lunarDay: Int) -> Date? {
        // 使用 LunarSwift 库的 Lunar 方法
        let lunar = Lunar.fromYmdHms(lunarYear: lunarYear, lunarMonth: lunarMonth, lunarDay: lunarDay)
        let solar = lunar.solar
        
        return Date.createDate(year: solar.year, month: solar.month, day: solar.day)
    }
    
    // MARK: - 农历显示方法
    /// 获取农历月日显示
    /// - Parameter date: 阳历日期
    /// - Returns: 农历月日显示文本
    static func getLunarMonthDay(for date: Date) -> String {
        let lunar = solarToLunar(date)
        return "\(lunar.monthInChinese)\(lunar.dayInChinese)"
    }

    /// 获取当前农历月份显示
    /// 如果是初一就显示月份，否则显示具体日期
    /// - Parameter date: 阳历日期
    /// - Returns: 农历显示文本
    static func getLunarMonthDisplay(for date: Date) -> String {
        let lunar = solarToLunar(date)
        // 如果是初一，显示月份
        if lunar.day == 1 {
            return lunar.monthInChinese + "月"
        } else {
            // 其他日期显示具体日期
            return "\(lunar.dayInChinese)"
        }
    }

    /// 智能显示日期信息
    /// 优先级：法定节假日 > 农历节假日 > 阳历节假日 > 24节气 > 农历
    /// - Parameter date: 阳历日期
    /// - Returns: 显示文本
    static func getSmartDisplay(for date: Date) -> String {
        let lunar = solarToLunar(date)
        let solar = makeSolar(from: date)

        // 1. 优先检查法定节假日（这里需要接入法定节假日API，暂时跳过）
        // TODO: 接入法定节假日API
        
        // 2. 检查农历节假日
        let lunarFestivals = lunar.festivals
        if !lunarFestivals.isEmpty {
            return lunarFestivals.first!
        }
        
        // 3. 检查农历其他节日
        let lunarOtherFestivals = lunar.otherFestivals
        if !lunarOtherFestivals.isEmpty {
            return lunarOtherFestivals.first!
        }
        
        // 4. 检查阳历节假日
        let solarFestivals = solar.festivals
        if !solarFestivals.isEmpty {
            return solarFestivals.first!
        }
        
//        // 5. 检查阳历其他节日
//        let solarOtherFestivals = solar.otherFestivals
//        if !solarOtherFestivals.isEmpty {
//            return solarOtherFestivals.first!
//        }
        
        // 6. 检查24节气
        let jieQi = lunar.jieQi
        if !jieQi.isEmpty {
            return jieQi
        }
        
        // 7. 最后显示农历        
        return getLunarMonthDisplay(for: date)

    }

    
}
