//
//  TDCalendarDayData.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/21.
//

import Foundation
import SwiftUI
import SwiftDate
import LunarSwift
import OSLog

@MainActor
final class TDCalendarManager: ObservableObject {
    static let shared = TDCalendarManager()
    
    @Published private(set) var currentDate: DateInRegion
    @Published private(set) var calendarDays: [TDCalendarDay] = []
    @Published private(set) var isLoading: Bool = false
    
    private let dataManager = TDCalendarDataManager.shared
    private let cacheManager = TDCalendarCacheManager.shared
    private let memoryMonitor = TDMemoryMonitor.shared
    
    private init() {
        SwiftDate.defaultRegion = Region.current
        self.currentDate = DateInRegion()
        setupMonitoring()
    }
    
    private func setupMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.memoryMonitor.checkMemoryUsage()
        }
    }
    
    // MARK: - Public Methods
    func initialize() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await dataManager.initialize()
            await updateMonth(currentDate)
        } catch {
            Logger.calendar.logError(error as? TDCalendarError ?? .initializationFailed)
        }
    }
    
    func updateMonth(_ date: DateInRegion) async {
        do {
            let days = try await dataManager.getDaysForMonth(year: date.year, month: date.month)
            await MainActor.run {
                self.currentDate = date
                self.calendarDays = days
            }
            // 预加载相邻月份
            await preloadAdjacentMonths(date)
        } catch {
            Logger.calendar.logError(error as? TDCalendarError ?? .dataGenerationFailed)
        }
    }
    
    func changeMonth(by value: Int) async {
        let newDate = currentDate + value.months
        await updateMonth(newDate)
    }
    
    func changeYear(to year: Int) async {
        let newDate = currentDate + year.years
        await updateMonth(newDate)
    }
    
    func goToToday() async {
        await updateMonth(DateInRegion())
    }
    
    // MARK: - Private Methods
    private func preloadAdjacentMonths(_ date: DateInRegion) async {
        let adjacentMonths = [-1, 1].map { date + $0.months }
        
        await withTaskGroup(of: Void.self) { group in
            for month in adjacentMonths {
                group.addTask {
                    _ = try? await self.dataManager.getDaysForMonth(
                        year: month.year,
                        month: month.month
                    )
                }
            }
        }
    }
}
