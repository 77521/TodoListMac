//
//  TDMacTaskGroup.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI

// MARK: - 任务分组模型

/// 任务分组标题颜色类型
enum TDTaskGroupTitleColorType {
    case descriptionColor      // 主题描述颜色
    case themeLevel6          // 主题6级颜色
    case fixedNewYearRed      // 固定新年红6级颜色
}

/// 任务分组类型枚举
enum TDTaskGroupType: Int, CaseIterable, Comparable {
    case overdueCompleted = 0      // 过期已达成
    case overdueUncompleted = 1    // 过期未达成
    case today = 2                 // 今天
    case tomorrow = 3              // 明天
    case dayAfterTomorrow = 4      // 后天
    case upcomingSchedule = 5      // 后续日程
    case noDate = 6                // 无日期
    
    /// 获取分组标题
    var title: String {
        switch self {
        case .overdueCompleted:
            return "过期已达成"
        case .overdueUncompleted:
            return "过期未达成"
        case .today:
            return "今天"
        case .tomorrow:
            return "明天"
        case .dayAfterTomorrow:
            return "后天"
        case .upcomingSchedule:
            return "后续日程"
        case .noDate:
            return "无日期"
        }
    }
    
    /// 获取分组标题（包含天数设置）
    func titleWithDays(_ days: Int) -> String {
        switch self {
        case .overdueCompleted:
            return "过期已达成(\(days)天内)"
        case .overdueUncompleted:
            return "过期未达成(\(days)天内)"
        default:
            return title
        }
    }
    
    /// 是否需要显示天数设置
    var needsDaysSetting: Bool {
        switch self {
        case .overdueCompleted, .overdueUncompleted:
            return true
        default:
            return false
        }
    }
    
    /// 是否需要显示设置图标
    var needsSettingsIcon: Bool {
        switch self {
        case .overdueCompleted, .overdueUncompleted, .upcomingSchedule, .noDate:
            return true
        default:
            return false
        }
    }
    
    /// 是否需要显示重新安排按钮
    var needsRescheduleButton: Bool {
        switch self {
        case .overdueUncompleted:
            return true
        default:
            return false
        }
    }
    
    /// 比较方法（用于排序）
    static func < (lhs: TDTaskGroupType, rhs: TDTaskGroupType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    /// 获取分组标题颜色类型（用于在 View 中获取实际颜色）
    var titleColorType: TDTaskGroupTitleColorType {
        switch self {
        case .overdueCompleted, .noDate:
            return .descriptionColor
        case .overdueUncompleted:
            return .fixedNewYearRed
        case .today, .tomorrow, .dayAfterTomorrow, .upcomingSchedule:
            return .themeLevel6
        }
    }
    
    /// 获取星期显示（仅今天、明天、后天需要）
    func getWeekdayDisplay() -> String? {
        switch self {
        case .today:
            return Date().weekdayDisplay()
        case .tomorrow:
            let tomorrow = Date().adding(days: 1)
            return tomorrow.weekdayDisplay()
        case .dayAfterTomorrow:
            let dayAfterTomorrow = Date().adding(days: 2)
            return dayAfterTomorrow.weekdayDisplay()
        default:
            return nil
        }
    }
}

/// 任务分组数据模型
struct TDTaskGroupModel: Identifiable {
    let type: TDTaskGroupType
    let title: String
    
    /// 使用枚举的rawValue作为ID
    var id: Int { type.rawValue }
    let weekdayDisplay: String?
    let taskCount: Int
    let completedCount: Int
    let totalCount: Int
    let isExpanded: Bool
    let isHovered: Bool
    let tasks: [TDMacSwiftDataListModel] // 添加任务数组属性，用于存储该分组的所有任务
    
    /// 计算完成率
    var completionRate: Double {
        guard totalCount > 0 else { return 0.0 }
        return Double(completedCount) / Double(totalCount)
    }
    
    /// 是否应该显示（根据任务数量和设置）
    var shouldShow: Bool {
        // 过期已达成分组特殊处理：即使没有数据也要显示（除非设置中设置为不显示）
        if type == .overdueCompleted {
            let settingManager = TDSettingManager.shared
            return settingManager.expiredRangeCompleted != .hide
        }
        
        // 其他分组：只有有数据才显示
        return totalCount > 0
    }
    
    /// 是否显示设置按钮（需要设置图标且鼠标悬停）
    var shouldShowSettingsButton: Bool {
        return type.needsSettingsIcon && isHovered
    }
    
    /// 是否显示重新安排按钮（需要重新安排按钮且鼠标悬停）
    var shouldShowRescheduleButton: Bool {
        return type.needsRescheduleButton && isHovered
    }
    
    /// 初始化方法
    init(
        type: TDTaskGroupType,
        taskCount: Int = 0,
        completedCount: Int = 0,
        totalCount: Int = 0,
        isExpanded: Bool = false,
        isHovered: Bool = false,
        tasks: [TDMacSwiftDataListModel] = [] // 添加任务数组参数
    ) {
        self.type = type
        self.taskCount = taskCount
        self.completedCount = completedCount
        self.totalCount = totalCount
        self.isExpanded = isExpanded
        self.isHovered = isHovered
        self.tasks = tasks // 设置任务数组
        
        // 设置标题和星期显示
        if type.needsDaysSetting {
            // 从设置管理器中获取天数配置
            let settingManager = TDSettingManager.shared
            let days: Int
            switch type {
            case .overdueCompleted:
                days = settingManager.expiredRangeCompleted.rawValue
            case .overdueUncompleted:
                days = settingManager.expiredRangeUncompleted.rawValue
            default:
                days = 7 // 默认值
            }
            self.title = type.titleWithDays(days)
        } else {
            // 使用枚举中的方法获取星期显示
            if let weekday = type.getWeekdayDisplay() {
                self.title = "\(type.title) \(weekday)"
            } else {
                self.title = type.title
            }
        }
        
        // 设置星期显示属性
        self.weekdayDisplay = type.getWeekdayDisplay()
    }
    
    /// 创建空分组（用于占位）
    static func emptyGroup(for type: TDTaskGroupType) -> TDTaskGroupModel {
        return TDTaskGroupModel(type: type, isExpanded: false, tasks: [])
    }
    
    /// 更新悬停状态
    func withHoverState(_ isHovered: Bool) -> TDTaskGroupModel {
        return TDTaskGroupModel(
            type: self.type,
            taskCount: self.taskCount,
            completedCount: self.completedCount,
            totalCount: self.totalCount,
            isExpanded: self.isExpanded,
            isHovered: isHovered,
            tasks: self.tasks // 保持原有任务数组
        )
    }
}



// MARK: - 使用示例
/*
 在视图中使用这些功能的示例：
 
 1. 监听鼠标悬停状态：
    .onHover { isHovered in
        taskGroupManager.updateGroupHoverState(for: group.id, isHovered: isHovered)
    }
 
 2. 显示设置按钮：
    if group.shouldShowSettingsButton {
        Button(action: { /* 设置操作 */ }) {
            Image(systemName: "gearshape")
        }
    }
 
 3. 显示重新安排按钮：
    if group.shouldShowRescheduleButton {
        Button(action: { /* 重新安排操作 */ }) {
            Image(systemName: "calendar.badge.plus")
        }
    }
 
 4. 在视图消失时清除悬停状态：
    .onDisappear {
        taskGroupManager.clearAllHoverStates()
    }
 */
