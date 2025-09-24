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
    
    /// 是否显示日期选择器
    @Published var showDatePicker: Bool = false
    
    /// 是否显示筛选器
    @Published var showFilter: Bool = false
    
    /// 是否显示更多选项
    @Published var showMoreOptions: Bool = false
    
    /// 输入框文本
    @Published var inputText: String = ""
    
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
        os_log(.info, log: logger, "📅 更新当前日期: %@", date.formattedString)
    }
    
    /// 上一个月
    func previousMonth() {
        let newDate = currentDate.adding(months: -1)
        updateCurrentDate(newDate)
    }
    
    /// 下一个月
    func nextMonth() {
        let newDate = currentDate.adding(months: 1)
        updateCurrentDate(newDate)
    }
    
    /// 更新选中的分类
    /// - Parameter category: 分类对象，nil 表示未分类
    func updateSelectedCategory(_ category: TDSliderBarModel?) {
        selectedCategory = category
        os_log(.info, log: logger, "🏷️ 更新选中分类: %@", category?.categoryName ?? "未分类")
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
    
    /// 创建任务
    func createTask() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        os_log(.info, log: logger, "➕ 创建任务: %@", inputText)
        
        // TODO: 实现创建任务逻辑
        // 这里可以调用数据管理器来保存任务
        
        // 清空输入框
        inputText = ""
    }
    
    // MARK: - 私有方法
    
    /// 加载分类数据
    private func loadCategories() {
        let allCategories = TDCategoryManager.shared.loadLocalCategories()
        availableCategories = allCategories
        os_log(.info, log: logger, "📂 加载分类数据: %d 个分类", allCategories.count)
    }
}
