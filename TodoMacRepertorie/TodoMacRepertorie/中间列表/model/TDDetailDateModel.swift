//
//  TDDetailDateModel.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/20.
//

import Foundation
import SwiftDate

struct TDDetailDateModel: Hashable {
    let date: DateInRegion
    let isToday: Bool
    let isSelected: Bool
    
    init(date: DateInRegion, isSelected: Bool) {
        self.date = date
        self.isToday = date.isToday
        self.isSelected = isSelected
    }
    
    var day: Int {
        date.day
    }
    // 添加一个计算属性来决定显示的文本
    var displayText: String {
        isToday ? "今" : "\(day)"
    }

    var weekday: String {
        date.toFormat("E", locale: Locale(identifier: "zh_CN"))
    }
    
    var fullDateString: String {
//        date.toFormat("MM.dd EEEE", locale: Locale(identifier: "zh_CN"))
        date.toFormat("MM.dd E", locale: Locale(identifier: "zh_CN"))
    }
    
    // SwiftDate 提供的其他便利属性
    var isWeekend: Bool {
        let weekday = date.weekday
        return weekday == 1 || weekday == 7 // 1是周日，7是周六
    }
    
    var monthName: String {
        date.toFormat("MMM")
    }
}
