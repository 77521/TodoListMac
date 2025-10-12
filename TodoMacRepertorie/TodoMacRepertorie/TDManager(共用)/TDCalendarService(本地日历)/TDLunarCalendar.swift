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
    
    
    // MARK: - 阳历转农历
    
    static func solarToLunar(_ date: Date) -> Lunar {
        // 使用 LunarSwift 库的 Solar 和 Lunar 方法
        let solar = Solar.fromDate(date: date)
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
        let solar = Solar.fromDate(date: date)
        
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
