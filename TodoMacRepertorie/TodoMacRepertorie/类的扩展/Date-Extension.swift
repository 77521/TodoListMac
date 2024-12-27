//
//  Date-Extension.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/27.
//

import Foundation

// MARK: - 日期工具扩展
extension Date {
//    var startOfDay: Date {
//        return Calendar.current.startOfDay(for: self)
//    }
//    
//    var endOfDay: Date {
//        var components = DateComponents()
//        components.day = 1
//        components.second = -1
//        return Calendar.current.date(byAdding: components, to: startOfDay)!
//    }
//    
//    var startOfMonth: Date {
//        let components = Calendar.current.dateComponents([.year, .month], from: self)
//        return Calendar.current.date(from: components)!
//    }
//    
//    var endOfMonth: Date {
//        var components = DateComponents()
//        components.month = 1
//        components.second = -1
//        return Calendar.current.date(byAdding: components, to: startOfMonth)!
//    }
//    
//    var isWeekend: Bool {
//        let weekday = Calendar.current.component(.weekday, from: self)
//        return weekday == 1 || weekday == 7
//    }
//    
//    func isSameDay(_ date: Date) -> Bool {
//        return Calendar.current.isDate(self, inSameDayAs: date)
//    }
//    
//    func isSameMonth(_ date: Date) -> Bool {
//        let comp1 = Calendar.current.dateComponents([.year, .month], from: self)
//        let comp2 = Calendar.current.dateComponents([.year, .month], from: date)
//        return comp1 == comp2
//    }
//    
//    func adding(_ component: Calendar.Component, value: Int) -> Date {
//        return Calendar.current.date(byAdding: component, value: value, to: self)!
//    }
    
    /// 判断是否是后天
       var isDayAfterTomorrow: Bool {
           return self.compare(toDate: Date().addingTimeInterval(2.days.timeInterval), granularity: .day) == .orderedSame
       }
       
       /// 判断是否已过期
       var isOverdue: Bool {
           return self.compare(toDate: Date().dateAtStartOf(.day), granularity: .day) == .orderedAscending
       }
    
    /// 格式化日期显示
       var formattedString: String {
           if self.compare(.isThisYear) {
               return self.toFormat("MM月dd日", locale: Locale.current)
           } else {
               return self.toFormat("yyyy年MM月dd日", locale: Locale.current)
           }
       }
}


extension Int64 {
    /// 将时间戳转换为日期
    var toDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(self / 1000))
    }
}
