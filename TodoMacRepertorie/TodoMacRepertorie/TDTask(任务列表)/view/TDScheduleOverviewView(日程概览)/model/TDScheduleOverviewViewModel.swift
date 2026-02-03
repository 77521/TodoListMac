//
//  TDScheduleOverviewViewModel.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/9/23.
//

import Foundation
import SwiftUI
import OSLog

class TDScheduleOverviewViewModel: ObservableObject {
    
    // MARK: - Published 属性
    /// 单例
    static let shared = TDScheduleOverviewViewModel()

    /// 当前选中的日期
    @Published var currentDate: Date = Date()
    
    /// 选中的分类
    @Published var selectedCategory: TDSliderBarModel? = nil
    
    /// 可用的分类列表
    @Published var availableCategories: [TDSliderBarModel] = []
    
    /// 标签筛选
    @Published var tagFilter: String = ""
    
    /// 排序类型 0:默认 1:提醒时间 2:添加时间a-z 3:添加时间z-a 4:工作量a-z 5:工作量z-a
    @Published var sortType: Int = 0

    /// 是否显示日期选择器
    @Published var showDatePicker: Bool = false
    
    /// 是否显示筛选器
    @Published var showFilter: Bool = false
    
    /// 是否显示更多选项
    @Published var showMoreOptions: Bool = false
    


    // MARK: - 私有属性
    
    private let logger = OSLog(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDScheduleOverviewViewModel")
    
    // MARK: - 初始化
    
    init() {
        loadCategories()
    }
    
    // MARK: - 公共方法
    
    /// 更新当前日期
    /// - Parameter date: 新的日期
    func updateCurrentDate(_ date: Date) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentDate = date
        }
//        // 通知日历管理器更新数据
//        Task {
//            try? await TDCalendarManager.shared.updateCalendarData()
//        }

        os_log(.info, log: logger, "📅 更新当前日期: %@", date.formattedString)
    }
    /// 只更新选中状态，不触发日历数据重新计算
    /// - Parameter date: 要选中的日期
    func selectDateOnly(_ date: Date) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentDate = date
        }
        os_log(.info, log: logger, "📅 选中日期: %@", date.formattedString)
    }
    
    /// 上一个月
    func previousMonth() {
        let newDate = currentDate.adding(months: -1)
        // 智能选择日期：如果是当月选中今天，否则选中1日
        let targetDate = getSmartSelectedDate(for: newDate)
        // 直接更新日期并重新计算日历数据
        withAnimation(.easeInOut(duration: 0.3)) {
            currentDate = targetDate
        }
        // 手动触发日历数据重新计算
        Task {
            try? await TDCalendarManager.shared.updateCalendarData()
        }
        os_log(.info, log: logger, "📅 切换到上一个月: %@", targetDate.formattedString)
    }
    
    /// 下一个月
    func nextMonth() {
        let newDate = currentDate.adding(months: 1)
        // 智能选择日期：如果是当月选中今天，否则选中1日
        let targetDate = getSmartSelectedDate(for: newDate)
        // 直接更新日期并重新计算日历数据
        withAnimation(.easeInOut(duration: 0.3)) {
            currentDate = targetDate
        }
        // 手动触发日历数据重新计算
        Task {
            try? await TDCalendarManager.shared.updateCalendarData()
        }
        os_log(.info, log: logger, "📅 切换到下一个月: %@", targetDate.formattedString)
    }

    /// 获取智能选中的日期
    /// - Parameter targetDate: 目标月份中的任意日期
    /// - Returns: 智能选中的日期
    private func getSmartSelectedDate(for targetDate: Date) -> Date {
        // 判断是否切换到当前月份
        if targetDate.isCurrentMonth {
            // 切换到当前月份，默认选中今天
            return Date()
        } else {
            // 切换到其他月份，默认选中该月第一天
            return targetDate.firstDayOfMonth
        }
    }

    /// 回到今天
    func backToToday() {
        // 直接更新日期并重新计算日历数据
        withAnimation(.easeInOut(duration: 0.3)) {
            currentDate = Date()
        }
        // 手动触发日历数据重新计算
        Task {
            try? await TDCalendarManager.shared.updateCalendarData()
        }
        os_log(.info, log: logger, "📅 回到今天: %@", Date().formattedString)
    }

    /// 更新选中的分类
    /// - Parameter category: 分类对象，nil 表示未分类
    func updateSelectedCategory(_ category: TDSliderBarModel?) {
        selectedCategory = category
        updateCurrentDate(currentDate)
        os_log(.info, log: logger, "🏷️ 更新选中分类: %@", category?.categoryName ?? "未分类")
    }
    /// 更新标签筛选
    /// - Parameter tag: 标签筛选条件
    func updateTagFilter(_ tag: String) {
        tagFilter = tag
        updateCurrentDate(currentDate)
        os_log(.info, log: logger, "🏷️ 更新标签筛选: %@", tag)
    }
    
    /// 更新排序类型
    /// - Parameter sort: 排序类型
    func updateSortType(_ sort: Int) {
        sortType = sort
        updateCurrentDate(currentDate)
        os_log(.info, log: logger, "📊 更新排序类型: %d", sort)
    }

    /// 显示日期选择器
    func showDatePickerView() {
        showDatePicker = true
    }
    
    /// 隐藏日期选择器
    func hideDatePickerView() {
        showDatePicker = false
    }
    
    /// 显示筛选器
    func showFilterView() {
        showFilter = true
    }
    
    /// 隐藏筛选器
    func hideFilterView() {
        showFilter = false
    }
    
    /// 显示更多选项
    func showMoreOptionsView() {
        showMoreOptions = true
    }
    
    /// 隐藏更多选项
    func hideMoreOptionsView() {
        showMoreOptions = false
    }
    
    
    // MARK: - 私有方法
    
    /// 加载分类数据
    private func loadCategories() {
        let allCategories = TDCategoryManager.shared.loadLocalCategories()
        availableCategories = allCategories
        os_log(.info, log: logger, "📂 加载分类数据: %d 个分类", allCategories.count)
    }
}
