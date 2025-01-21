//
//  Date-Extension.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftDate

// MARK: - 日期工具扩展
extension Date {
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
