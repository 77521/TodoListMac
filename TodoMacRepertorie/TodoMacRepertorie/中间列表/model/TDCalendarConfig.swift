//
//  TDCalendarConfig.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/2.
//

import Foundation
import SwiftUI



/// 日历配置类
public struct TDCalendarConfig {
    /// 日历主题配置
    public struct TDCalendarTheme {
        /// 当天日期背景色 (使用主题色的半透明版本)
        public var todayBackgroundColor: Color {
            .marrsGreenColor5.opacity(0.3)
//            TDThemeManager.shared.currentTheme.colors.background.color(for: .light).opacity(0.3)
        }
        
        /// 选中日期背景色 (使用主题色)
        public var selectedBackgroundColor: Color {
            .marrsGreenColor5

//            TDThemeManager.shared.currentTheme.colors.background.color(for: .light)
        }
        
        /// 正常日期文字颜色
        public var normalTextColor: Color
        /// 非当前月份日期文字颜色
        public var inactiveTextColor: Color
        /// 选中日期文字颜色
        public var selectedTextColor: Color
        /// 周末日期文字颜色
        public var weekendTextColor: Color
        
        public init(
            normalTextColor: Color = .primary,
            inactiveTextColor: Color = .gray,
            selectedTextColor: Color = .white,
            weekendTextColor: Color = .red
        ) {
            self.normalTextColor = normalTextColor
            self.inactiveTextColor = inactiveTextColor
            self.selectedTextColor = selectedTextColor
            self.weekendTextColor = weekendTextColor
        }
    }
    
    /// 主题配置
    public var calendarTheme: TDCalendarTheme
    
    public init(calendarTheme: TDCalendarTheme = TDCalendarTheme()) {
        self.calendarTheme = calendarTheme
    }
}

//public struct TDCalendarConfig {
//    // 日历设置
////    public struct Settings {
////        // 周起始日 (1 = 周日, 2 = 周一)
////        public var firstWeekday: Int = 1
////        
////        // 是否显示农历
////        public var showLunar: Bool = true
////        
////        // 是否显示节日
////        public var showFestivals: Bool = true
////        
////        // 是否显示节气
////        public var showSolarTerms: Bool = true
////        
////        // 是否高亮显示周末
////        public var highlightWeekends: Bool = true
////        
////        public init() {}
////    }
//    
//    // 主题设置
//    public struct TDCalendarTheme {
//        // 颜色
//        public var dateTextColor: Color = .primary
//        public var lunarTextColor: Color = .secondary
//        public var todayBackgroundColor: Color = Color(red: 0.2, green: 0.7, blue: 0.9)
//        public var selectedBackgroundColor: Color = .blue.opacity(0.2)
//        public var holidayTextColor: Color = .red
//        public var weekendTextColor: Color = .blue
//        public var otherMonthTextColor: Color = .gray.opacity(0.5)
//        public var festivalTextColor: Color = .orange
//        public var solarTermTextColor: Color = .green
//        
//        // 字体
//        public var dateFontSize: CGFloat = 16
//        public var lunarFontSize: CGFloat = 11
//        public var weekdayFontSize: CGFloat = 12
//        public var titleFontSize: CGFloat = 16
//        
//        // 布局
//        public var cellWidth: CGFloat = 40
//        public var cellHeight: CGFloat = 50
//        public var cellSpacing: CGFloat = 2
//        
//        public init() {}
//    }
//    
////    public var settings: Settings = Settings()
//    public var theme: TDCalendarTheme = TDCalendarTheme()
//    
//    public init() {}
//}
//    public var settings: Settings = Settings()

