//
//  TDDateManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/21.
//

import Foundation
import SwiftUI

@MainActor
final class TDDateManager: ObservableObject {
    /// 单例
    static let shared = TDDateManager()
    
    // MARK: - Published 属性
    
    /// 选中的日期
    @Published var selectedDate: Date = Date()
    
    /// 当前显示的周
    @Published var currentWeek: [Date] = []
    
    // MARK: - 私有属性
    private let settingManager = TDSettingManager.shared
    
    // MARK: - 初始化方法
    private init() {
        updateCurrentWeek()
    }
    
    // MARK: - 公共方法
    
    /// 更新当前周的日期数组
    func updateCurrentWeek() {
        currentWeek = selectedDate.datesOfWeek(firstDayIsMonday: settingManager.isFirstDayMonday)
    }
    
    /// 切换到上一周
    func previousWeek() {
        if let newDate = selectedDate.previousWeek() {
            selectedDate = newDate
            updateCurrentWeek()
            // 选中第一天
            selectDate(currentWeek[0])
        }
    }
    
    /// 切换到下一周
    func nextWeek() {
        if let newDate = selectedDate.nextWeek() {
            selectedDate = newDate
            updateCurrentWeek()
            // 选中最后一天
            selectDate(currentWeek[6])
        }
    }
    
    /// 返回今天
    func backToToday() {
        selectedDate = Date()
        updateCurrentWeek()
        selectDate(selectedDate)
    }
    
    /// 选择日期
    func selectDate(_ date: Date) {
        selectedDate = date
        updateCurrentWeek()
    }
    
    /// 设置选中日期（异步安全）
    @MainActor
    func setSelectedDate(_ date: Date) async {
        selectedDate = date
        updateCurrentWeek()
    }
    
    /// 获取默认日期（今天）
    func getDefaultDate() -> Date {
        return Date()
    }
    /// 获取日期的显示文本
    func getDateDisplayText(for date: Date) -> String {
        date.dayNumberString
    }
    
    /// 获取选中日期的时间戳（毫秒）
    func getSelectedDateTimestamp() -> Int64 {
        selectedDate.startOfDayTimestamp
    }
    
    /// 检查日期是否是今天
    func isToday(_ date: Date) -> Bool {
        date.isToday
    }
    
    /// 检查日期是否是选中的日期
    func isSelectedDate(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
}
