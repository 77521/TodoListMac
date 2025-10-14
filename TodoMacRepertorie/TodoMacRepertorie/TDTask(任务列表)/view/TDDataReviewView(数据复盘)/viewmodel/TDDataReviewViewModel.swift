//
//  TDDataReviewViewModel.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/14.
//

import Foundation
import SwiftUI

/// 数据复盘视图模型
class TDDataReviewViewModel: ObservableObject {
    static let shared = TDDataReviewViewModel()
    
    /// 当前选中的统计类型
    @Published var selectedStatType: TDDataReviewTopView.StatType = .yesterday
    
    /// 当前选中的时间范围
    @Published var selectedTimeRange: TDDataReviewTimeRange = .sevenDays
    /// 当前选中的周报时间范围
    @Published var selectedWeekRange: TDDataReviewWeekRange = .lastWeek

    
    /// 当前数据
    @Published var currentData: [TDDataReviewModel] = []

    /// 是否正在加载数据
    @Published var isLoading: Bool = false

    private init() {
        // 初始化时自动加载默认数据（昨日小结）
        Task {
            await loadData()
        }
    }

    /// 更新统计类型
    func updateStatType(_ type: TDDataReviewTopView.StatType) {
        // 如果类型没有改变，不重新加载
        guard selectedStatType != type else { return }

        DispatchQueue.main.async {
            self.selectedStatType = type
        }
        // 统计类型改变时，重新获取数据
        Task {
            await loadData()
        }
    }
    
    /// 更新时间范围
    func updateTimeRange(_ range: TDDataReviewTimeRange) {
        // 如果时间范围没有改变，不重新加载
        guard selectedTimeRange != range else { return }

        DispatchQueue.main.async {
            self.selectedTimeRange = range
        }
        // 时间范围改变时，重新获取数据
        Task {
            await loadData()
        }
    }
    
    /// 更新周报时间范围
    func updateWeekRange(_ range: TDDataReviewWeekRange) {
        // 如果周报时间范围没有改变，不重新加载
        guard selectedWeekRange != range else { return }

        DispatchQueue.main.async {
            self.selectedWeekRange = range
        }
        // 周报时间范围改变时，重新获取数据
        Task {
            await loadData()
        }
    }

    /// 获取当前时间范围时间戳
    func getCurrentTimeRange() -> (start: Int64, end: Int64) {
        return (selectedTimeRange.getStartTimestamp(), selectedTimeRange.getEndTimestamp())
    }
    
    /// 加载数据（带缓存）
    @MainActor
    func loadData() async {

        // 显示加载状态
        currentData = []
        isLoading = true
        
        do {
            let data: [TDDataReviewModel]
            
            switch selectedStatType {
            case .yesterday:
                data = try await fetchYesterdaySummary()
            case .events:
                data = try await fetchEventStats()
            case .tomato:
                data = try await fetchTomatoStats()
            case .weekly:
                data = try await fetchWeekReport()
            }
            // 更新数据
            currentData = data
        } catch {
            print("❌ 加载数据失败: \(error.localizedDescription)")
            currentData = []
        }
        
        isLoading = false
    }

    
    // MARK: - API 调用方法
    
    /// 获取昨日小结数据
    func fetchYesterdaySummary() async throws -> [TDDataReviewModel] {
        return try await TDDataReviewAPI.shared.getReportYesterdaySummary()
    }
    
    /// 获取事件统计数据
    func fetchEventStats() async throws -> [TDDataReviewModel] {
        let timeRange = getCurrentTimeRange()
        let startTime = timeRange.start
        let endTime = timeRange.end
        
        return try await TDDataReviewAPI.shared.getReportTask(
            startTime: startTime,
            endTime: endTime
        )
    }
    
    /// 获取番茄统计数据
    func fetchTomatoStats() async throws -> [TDDataReviewModel] {
        let timeRange = getCurrentTimeRange()
        let startTime = timeRange.start
        let endTime = timeRange.end
        
        return try await TDDataReviewAPI.shared.getReportTomato(
            startTime: startTime,
            endTime: endTime
        )
    }
    
    /// 获取周报数据
    func fetchWeekReport() async throws -> [TDDataReviewModel] {
        let isFirstDayMonday = TDSettingManager.shared.isFirstDayMonday
        let weekStartSun = !isFirstDayMonday // 如果第一天是周一，则不是从周日开始
        
        // 使用选中的周报时间范围，只传递开始时间戳
        let diyEndTime = selectedWeekRange.getStartTimestamp()
        
        return try await TDDataReviewAPI.shared.getReportWeek(
            diyEndTime: diyEndTime,
            weekStartSun: weekStartSun
        )
    }
}
