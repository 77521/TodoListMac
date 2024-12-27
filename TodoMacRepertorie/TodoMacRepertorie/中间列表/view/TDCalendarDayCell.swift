//
//  TDCalendarDayCell.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/10.
//

import SwiftUI
import SwiftDate
import LunarSwift

/// 日历单元格视图
public struct TDCalendarDayCell: View {
    /// 日期数据
    private let calendarDate: TDCalendarDate

    /// 是否被选中
    private let isSelected: Bool
    /// 主题配置
    private let theme: TDCalendarConfig.TDCalendarTheme
    
    public init(
        date: TDCalendarDate,
        isSelected: Bool,
        theme: TDCalendarConfig.TDCalendarTheme
    ) {
        self.calendarDate = date
        self.isSelected = isSelected
        self.theme = theme
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            // 阳历日期
            Text("\(calendarDate.day)")
                .font(.system(size: 16))
                .foregroundColor(textColor)
            
            // 农历日期
            Text(calendarDate.lunarText)
                .font(.system(size: 10))
                .foregroundColor(textColor)
        }
        .frame(width: 40, height: 40)
        .background(backgroundView)
    }
    
    /// 背景视图
    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            Circle()
                .fill(theme.selectedBackgroundColor)
        } else if Calendar.current.isDateInToday(calendarDate.date) {
            Circle()
                .fill(theme.todayBackgroundColor)
        }
    }
    
    /// 文字颜色
    private var textColor: Color {
        if isSelected {
            return theme.selectedTextColor
        }
        
        if !calendarDate.isCurrentMonth {
            return theme.inactiveTextColor
        }
        
//        if calendarDate.isWeekend {
//            return theme.weekendTextColor
//        }
        
        return theme.normalTextColor
    }
    
}


//#Preview {
//    // 普通日期
//    TDCalendarDayCell(
//        date: Date(),
//        isCurrentMonth: true,
//        isSelected: false,
//        theme: TDCalendarConfig.TDCalendarTheme()
//    )
//    
//    // 选中日期
//    TDCalendarDayCell(
//        date: Date(),
//        isCurrentMonth: true,
//        isSelected: true,
//        theme: TDCalendarConfig.TDCalendarTheme()
//    )
//    
//    // 非当月日期
//    TDCalendarDayCell(
//        date: Date() + 1.months,
//        isCurrentMonth: false,
//        isSelected: false,
//        theme: TDCalendarConfig.TDCalendarTheme()
//    )
//}
