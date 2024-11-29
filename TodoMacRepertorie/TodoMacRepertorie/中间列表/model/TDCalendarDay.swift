//
//  TDCalendarDay.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/27.
//

import Foundation
import SwiftDate
import SwiftUI
import Darwin
import os.log

// MARK: - 日历日期模型
struct TDCalendarDay: Identifiable, Codable {
    let id: UUID
    let date: DateInRegion
    let solarDay: Int
    let lunarDay: String
    let lunarMonth: String
    let isLunarFirstDay: Bool  // 是否农历初一
    let solarTerm: String?     // 24节气
    let festival: TDFestival?  // 节日信息
    let workdayType: TDWorkdayType
    let isToday: Bool
    let isCurrentMonth: Bool
    let isWeekend: Bool
}

// MARK: - 节日模型
struct TDFestival: Codable {
    let name: String
    let type: TDFestivalType
    let isHoliday: Bool
    let duration: Int
    let remark: String?
}

// MARK: - 节日类型
enum TDFestivalType: String, Codable {
    case lunar      // 农历节日
    case solar      // 阳历节日
    case foreign    // 国外节日
    case legal      // 法定节假日
    case solarTerm  // 24节气
}

// MARK: - 工作日类型
enum TDWorkdayType: String, Codable {
    case normal     // 普通工作日
    case weekend    // 周末
    case holiday    // 节假日
    case workday    // 调休工作日
}

// MARK: - 日历错误类型
enum TDCalendarError: LocalizedError {
    case invalidDate
    case dataGenerationFailed
    case cacheLoadFailed
    case cacheSaveFailed
    case initializationFailed
    
    var errorCode: Int {
        switch self {
        case .invalidDate:
            return 1001
        case .dataGenerationFailed:
            return 1002
        case .cacheLoadFailed:
            return 1003
        case .cacheSaveFailed:
            return 1004
        case .initializationFailed:
            return 1005
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .invalidDate:
            return "无效的日期"
        case .dataGenerationFailed:
            return "日历数据生成失败"
        case .cacheLoadFailed:
            return "缓存加载失败"
        case .cacheSaveFailed:
            return "缓存保存失败"
        case .initializationFailed:
            return "日历初始化失败"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidDate:
            return "输入的日期格式不正确或超出有效范围"
        case .dataGenerationFailed:
            return "生成日历数据时发生错误"
        case .cacheLoadFailed:
            return "无法从缓存中读取数据"
        case .cacheSaveFailed:
            return "无法将数据保存到缓存"
        case .initializationFailed:
            return "日历系统初始化过程中发生错误"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidDate:
            return "请检查日期输入是否在有效范围内（1900-2200年）"
        case .dataGenerationFailed:
            return "请尝试重新加载日历数据"
        case .cacheLoadFailed:
            return "请检查应用权限或清除缓存后重试"
        case .cacheSaveFailed:
            return "请检查设备存储空间是否充足"
        case .initializationFailed:
            return "请重启应用或清除缓存后重试"
        }
    }
}

// MARK: - 日历常量
enum TDCalendarConstants {
    static let minimumYear = 1900
    static let maximumYear = 2200
    
    enum UI {
        static let calendarWidth: CGFloat = 300
        static let navigationHeight: CGFloat = 44
        static let weekdayHeight: CGFloat = 30
        static let dayCellHeight: CGFloat = 50
    }
    
    enum Cache {
        static let fileName = "TDCalendarCache"
        static let expirationDays = 30
    }
}

// MARK: - 日历主题
struct TDCalendarTheme {
    let backgroundColor: Color
    let titleColor: Color
    let controlColor: Color
    let weekdayColor: Color
    let textColor: Color
    let lunarColor: Color
    let festivalColor: Color
    let solarTermColor: Color
    let holidayColor: Color
    let weekendColor: Color
    let inactiveTextColor: Color
    let selectedTextColor: Color
    let selectedBackgroundColor: Color
    let todayBackgroundColor: Color
    
    let titleFont: Font
    let weekdayFont: Font
    let dayFont: Font
    let lunarFont: Font
    let yearPickerFont: Font
    
    static let `default` = TDCalendarTheme(
        backgroundColor: .white,
        titleColor: .primary,
        controlColor: .blue,
        weekdayColor: .secondary,
        textColor: .primary,
        lunarColor: .secondary,
        festivalColor: .red,
        solarTermColor: .green,
        holidayColor: .red,
        weekendColor: .blue,
        inactiveTextColor: .gray,
        selectedTextColor: .white,
        selectedBackgroundColor: .blue,
        todayBackgroundColor: .blue.opacity(0.1),
        titleFont: .headline,
        weekdayFont: .subheadline,
        dayFont: .body,
        lunarFont: .caption2,
        yearPickerFont: .body
    )
}


// MARK: - 内存监控器
@globalActor actor TDMemoryMonitor {
    static let shared = TDMemoryMonitor()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TDCalendar", category: "MemoryMonitor")
    
    private init() {}
    
    /// 检查内存使用情况
    nonisolated func checkMemoryUsage() {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMB = Float(taskInfo.phys_footprint) / 1048576.0
            Task { @MainActor in
                logger.info("当前内存使用: \(String(format: "%.2f", usedMB))MB")
                
                // 如果内存使用超过阈值，发出警告
                if usedMB > 500 {  // 500MB 作为示例阈值
                    logger.warning("内存使用超过阈值！")
                }
            }
        }
    }
    
    /// 获取当前内存使用量（MB）
    nonisolated func currentMemoryUsage() -> Float {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return Float(taskInfo.phys_footprint) / 1048576.0
        }
        return 0
    }
}
