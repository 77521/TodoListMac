//
//  TDCalendarDateModel.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/1/29.
//

import Foundation
import SwiftUI

/// 日历日期模型 - 用于存储日历中每个日期的完整信息
struct TDCalendarDateModel: Identifiable, Equatable {
    /// 唯一标识符
    /// 使用当天开始时间戳作为稳定 id（避免每次重建模型都生成新 UUID 导致整个月份格子全量重绘）
    let id: Int64

    /// 阳历日期
    let date: Date
    
    /// 是否为今天
    let isToday: Bool
    
    /// 是否为当前月份（用于区分上月和下月的日期显示）
    let isCurrentMonth: Bool
    
    /// 是否为休息日/节假日
    let isHoliday: Bool
    
    /// 是否在节假日数据中
    let isInHolidayData: Bool
    
    /// 智能显示信息（优先级：法定节假日 > 农历节假日 > 公历节假日 > 24节气 > 农历）
    let smartDisplay: String
    /// 是否为选中状态
    var isSelected: Bool

    /// 该日期的任务列表
    var tasks: [TDMacSwiftDataListModel] = []
    
    /// 初始化方法
    /// - Parameters:
    ///   - date: 阳历日期
    ///   - isToday: 是否为今天
    ///   - isCurrentMonth: 是否为当前月份
    ///   - isHoliday: 是否为休息日/节假日
    ///   - isInHolidayData: 是否在节假日数据中
    ///   - smartDisplay: 智能显示信息
    ///   - tasks: 任务列表
    init(date: Date, isToday: Bool, isCurrentMonth: Bool, isHoliday: Bool = false, isInHolidayData: Bool = false, smartDisplay: String = "", isSelected: Bool = false, tasks: [TDMacSwiftDataListModel] = []) {
        self.id = date.startOfDayTimestamp
        self.date = date
        self.isToday = isToday
        self.isCurrentMonth = isCurrentMonth
        self.isHoliday = isHoliday
        self.isInHolidayData = isInHolidayData
        self.smartDisplay = smartDisplay
        self.isSelected = isSelected
        self.tasks = tasks
    }
    
    static func == (lhs: TDCalendarDateModel, rhs: TDCalendarDateModel) -> Bool {
        // 仅比较影响 UI 的关键字段；不比较 tasks（避免大数组比较引发卡顿/频繁刷新）
        return lhs.id == rhs.id
            && lhs.isToday == rhs.isToday
            && lhs.isCurrentMonth == rhs.isCurrentMonth
            && lhs.isHoliday == rhs.isHoliday
            && lhs.isInHolidayData == rhs.isInHolidayData
            && lhs.smartDisplay == rhs.smartDisplay
            && lhs.isSelected == rhs.isSelected
    }

}
