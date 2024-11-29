//
//  Notification-Extension.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/6.
//

import Foundation

extension Notification.Name {
    // 用户相关
    static let userTokenExpired = Notification.Name("userTokenExpired")
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let userInfoDidUpdate = Notification.Name("userInfoDidUpdate")
    
    // 网络状态
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
    static let networkTimeout = Notification.Name("networkTimeout")
    
    // 应用状态
    static let appDidBackground = Notification.Name("appDidBackground")
    static let appWillTerminate = Notification.Name("appWillTerminate")
    
    // 数据同步
    static let dataSyncStarted = Notification.Name("dataSyncStarted")
    static let dataSyncCompleted = Notification.Name("dataSyncCompleted")
    static let dataSyncFailed = Notification.Name("dataSyncFailed")

    // 日历切换
    static let tdFrequentCalendarDataLoaded = Notification.Name("tdFrequentCalendarDataLoaded")
    static let tdFullCalendarDataLoaded = Notification.Name("tdFullCalendarDataLoaded")

}
