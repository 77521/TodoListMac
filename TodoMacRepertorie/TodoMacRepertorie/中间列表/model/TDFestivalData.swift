//
//  TDLunarCalendar.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/20.
//

import Foundation
import LunarSwift
import SwiftDate
import SwiftUI


// MARK: - 节日数据管理
// MARK: - 节日管理器
// MARK: - 节日管理器
actor TDFestivalManager {
    static let shared = TDFestivalManager()
    
    private init() {}
    
    /// 获取节日信息
    func getFestival(solarDate: DateInRegion, lunar: Lunar) async throws -> TDFestival? {
        // 1. 检查农历节日（包括节气）
        if let lunarFestival = getLunarFestival(lunar: lunar) {
            return lunarFestival
        }
        
        // 2. 检查阳历节日
        if let solarFestival = getSolarFestival(solar: lunar.solar) {
            return solarFestival
        }
        
        return nil
    }
    
    /// 获取阳历节日
    private func getSolarFestival(solar: Solar) -> TDFestival? {
        let festivals = solar.festivals
        guard !festivals.isEmpty else { return nil }
        
        let festivalName = festivals[0]
        
        switch festivalName {
        case "元旦":
            return TDFestival(name: festivalName, type: .legal, isHoliday: true, duration: 1, remark: nil)
        case "劳动节":
            return TDFestival(name: festivalName, type: .legal, isHoliday: true, duration: 3, remark: nil)
        case "国庆节":
            return TDFestival(name: festivalName, type: .legal, isHoliday: true, duration: 7, remark: nil)
        case "情人节", "圣诞节", "平安夜", "愚人节":
            return TDFestival(name: festivalName, type: .foreign, isHoliday: false, duration: 1, remark: nil)
        default:
            return TDFestival(name: festivalName, type: .solar, isHoliday: false, duration: 1, remark: nil)
        }
    }
    
    /// 获取农历节日和节气
    private func getLunarFestival(lunar: Lunar) -> TDFestival? {
        // 1. 检查节气
        let jieQi = lunar.jieQi
        if !jieQi.isEmpty {
            return TDFestival(
                name: jieQi,
                type: .solarTerm,
                isHoliday: false,
                duration: 1,
                remark: nil
            )
        }
        
        // 2. 检查农历节日
        let festivals = lunar.festivals
        guard !festivals.isEmpty else { return nil }
        
        let festivalName = festivals[0]
        
        switch festivalName {
        case "春节":
            return TDFestival(name: festivalName, type: .legal, isHoliday: true, duration: 3, remark: nil)
        case "端午节", "中秋节":
            return TDFestival(name: festivalName, type: .legal, isHoliday: true, duration: 1, remark: nil)
        case "除夕":
            return TDFestival(name: festivalName, type: .legal, isHoliday: true, duration: 1, remark: nil)
        default:
            return TDFestival(name: festivalName, type: .lunar, isHoliday: false, duration: 1, remark: nil)
        }
    }
}
