//
//  TDSettingManager.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/5.
//

import Foundation
import SwiftUI
import SwiftDate
import Combine

class TDAppSettings: ObservableObject {
    static let shared = TDAppSettings()
    
    //  主题颜色模式是否跟随系统
    @AppStorage("themeFollowSystem") var followSystem: Bool = true
    
    @AppStorage("weekStartsOnMonday") var weekStartsOnMonday: Bool = true {
        didSet {
            configureCalendar()
        }
    }
    
    private init() {
        configureCalendar()
    }
    
    var firstWeekday: Int {
        weekStartsOnMonday ? 2 : 1  // 1 = 周日, 2 = 周一
    }
    
    private func configureCalendar() {
        var calendar = Calendar.current
        calendar.firstWeekday = firstWeekday
        SwiftDate.defaultRegion = Region(
            calendar: calendar,
            zone: TimeZone.current,
            locale: Locale(identifier: "zh_CN")
        )
    }
}

