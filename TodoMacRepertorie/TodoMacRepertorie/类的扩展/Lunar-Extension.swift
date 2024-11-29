//
//  Lunar-Extension.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/27.
//

import Foundation
import SwiftDate
import LunarSwift

// MARK: - 农历核心封装
struct LunarCore {
    // 阳历转农历
    static func solarToLunar(year: Int, month: Int, day: Int) -> Lunar {
        return Lunar(lunarYear: year, lunarMonth: month, lunarDay: day)
    }
    
    // Date 转农历
    static func solarToLunar(date: Date) -> Lunar {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return Lunar(lunarYear: components.year!,
                     lunarMonth: components.month!,
                     lunarDay: components.day!)
    }
    
    // 农历转阳历
    static func lunarToSolar(year: Int, month: Int, day: Int, isLeapMonth: Bool = false) -> Solar {
        
        let lunar = Lunar(lunarYear: year, lunarMonth: month, lunarDay: day)  // 创建农历对象
        return lunar.solar  // 获取对应的阳历
    }
}

// MARK: - Lunar 扩展
extension Lunar {
    var lunarYearString: String {
        return self.yearInChinese
    }
    
    var lunarMonthString: String {
        return self.monthInChinese
    }
    
    var lunarDayString: String {
        return self.dayInChinese
    }
    
    var yearGanZhi: String {
        return "\(self.yearGan)\(self.yearZhi)"
    }
    
    var monthGanZhi: String {
        return "\(self.monthGan)\(self.monthZhi)"
    }
    
    var dayGanZhi: String {
        return "\(self.dayGan)\(self.dayZhi)"
    }

}
