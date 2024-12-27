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

class TDSettingManager: ObservableObject {
    static let shared = TDSettingManager()
    
    // 主题颜色模式是否跟随系统
    @AppStorage("themeFollowSystem") var followSystem: Bool = true
    
    // 添加事件 是置顶 还是置底 显示是升序还是 降序 默认 置顶
    @AppStorage("isTop") var isTop: Bool = true
    
    // 是否允许订阅日历 是的话 就获取本地日历数据
    @AppStorage("isSubscription") var isSubscription: Bool = true
    
    // 列表是否展示 已完成数据
    @AppStorage("isShowFinishData") var isShowFinishData: Bool = false

    // 最近待办 未分类 清单数据 展示 过期已完成的数据 日期范围 0：不显示， 7天 30天 100天
    @AppStorage("expiredRangeCompleted") var expiredRangeCompleted: Int = 7

    // 最近待办 未分类 清单数据 展示 过期未完成的数据 日期范围 0：不显示， 7天 30天 100天
    @AppStorage("expiredRangeUncompleted") var expiredRangeUncompleted: Int = 30
    // 最近待办 未分类 清单数据 展示 过期未完成的数据 日期范围 0： 全部， 1、2、5、10条
    @AppStorage("repeatNum") var repeatNum: Int = 5
    
    // 最近待办 未分类 清单数据 是否显示没有日期的事件 默认显示
    @AppStorage("isShowNoDateData") var isShowNoDateData: Bool = true

    // 最近待办 未分类 清单数据 是否显示已完成的无日期事件 默认显示
    @AppStorage("isShowNoDateFinishData") var isShowNoDateFinishData: Bool = true

    
    /// 待办箱内 清单分类的筛选 0 所有类 >0 根据id 筛选
    @Published var noDateCategoryId : Int = 0
    
    /// 待办箱内 筛选类型 noDateSortState = 0：按创建日期，1：按自定义排序， 2：按工作量
    @Published var noDateSortState : Int = 0
    /// 待办箱内 筛选类型 排序方式 升序降序
    @Published var noDateSort : Bool = false

    
    // 每周的第一天 是否是 周一
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

