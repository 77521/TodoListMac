//
//  TDCalendarDateModel.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/3/4.
//

import Foundation
import SwiftUI

/// 日历日期模型
struct TDCalendarDateModel: Identifiable {
    let id = UUID()
    /// 公历日期
    let date: Date
    /// 农历日期
    let lunarDate: String
    /// 节日类型
    var holidayType: TDHolidayType = .none
    /// 节日名称
    var holidayName: String = ""
    /// 是否是今天
    var isToday: Bool = false
    /// 是否是当前月份
    var isCurrentMonth: Bool = true
    /// 是否调休
    var isWorkday: Bool = false
    /// 是否放假
    var isHoliday: Bool = false
    /// 任务列表
    var tasks: [TDMacSwiftDataListModel] = []
}

/// 节日类型
enum TDHolidayType {
    case none           // 无节日
    case legal         // 法定节假日
    case solar         // 公历节日
    case lunar         // 农历节日
    case solarTerm     // 24节气
    
    var color: Color {
        switch self {
        case .legal: return .red
        case .solar: return .blue
        case .lunar: return .green
        case .solarTerm: return .orange
        case .none: return .primary
        }
    }
}
