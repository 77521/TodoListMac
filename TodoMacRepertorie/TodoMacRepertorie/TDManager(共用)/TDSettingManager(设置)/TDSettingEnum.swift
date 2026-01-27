//
//  TDSettingEnum.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import Foundation

/// 主题模式
enum TDThemeMode: Int, Codable {
    /// 跟随系统
    case system = 1
    /// 白天模式
    case light = 2
    /// 夜间模式
    case dark = 3
}
/// 文字大小
enum TDFontSize: Int, Codable {
    /// 9号字体
    case size9 = 1
    /// 10号字体
    case size10 = 2
    /// 11号字体
    case size11 = 3
    /// 12号字体
    case size12 = 4
    
    var size: CGFloat {
        switch self {
        case .size9:
            return 9
        case .size10:
            return 10
        case .size11:
            return 11
        case .size12:
            return 12
        }
    }
}

/// 日历任务颜色识别模式
enum TDCalendarTaskColorRecognition: Int, Codable {
    /// 自动识别
    case auto = 0
    /// 黑色
    case black = 1
    /// 白色
    case white = 2
}

/// 默认提醒时间（分钟偏移，0 表示发生时）
enum TDDefaultReminder: Int, CaseIterable {
    case atTime = 0
    case five = 5
    case ten = 10
    case fifteen = 15
    
    var title: String {
        switch self {
        case .atTime: return "settings.reminder.at_time".localized
        case .five: return "settings.reminder.five".localized
        case .ten: return "settings.reminder.ten".localized
        case .fifteen: return "settings.reminder.fifteen".localized
        }
    }
}

/// 语言设置
enum TDLanguage: Int, Codable {
    /// 跟随系统
    case system = 1
    /// 中文
    case chinese = 2
    /// 英文
    case english = 3
}

// MARK: - 过期任务显示范围枚举
enum TDExpiredRange: Int, Codable, CaseIterable {
    case hide = 0      // 不显示
    case sevenDays = 7 // 7天内
    case thirtyDays = 30 // 30天内
    case hundredDays = 100 // 100天内
    
    var description: String {
        switch self {
        case .hide: return "settings.expired_range.hide".localized
        case .sevenDays: return "settings.expired_range.7".localized
        case .thirtyDays: return "settings.expired_range.30".localized
        case .hundredDays: return "settings.expired_range.100".localized
        }
    }
    
}

// MARK: - 重复数据显示个数枚举
enum TDRepeatTasksLimit: Int, CaseIterable {
    case all = 0
    case one = 1
    case two = 2
    case five = 5
    case ten = 10
    
    var title: String {
        switch self {
        case .all:
            return "settings.repeat_limit.all".localized
        case .one:
            return "settings.repeat_limit.one".localized
        case .two:
            return "settings.repeat_limit.two".localized
        case .five:
            return "settings.repeat_limit.five".localized
        case .ten:
            return "settings.repeat_limit.ten".localized
        }
    }
}
// MARK: - 后续日程显示范围枚举
enum TDFutureDateRange: Int, CaseIterable {
    case sevenDays = 7
    case thirtyDays = 30
    case threeMonths = 90
    case oneYear = 365
    case all = 0
    
    var title: String {
        switch self {
        case .sevenDays: return "settings.future_range.7".localized
        case .thirtyDays: return "settings.future_range.30".localized
        case .threeMonths: return "settings.future_range.90".localized
        case .oneYear: return "settings.future_range.365".localized
        case .all: return "settings.future_range.all".localized
        }
    }
}

/// 任务背景色显示模式
enum TDTaskBackgroundMode: Int, CaseIterable {
    case workload = 0      // 显示工作量背景色
    case category = 1      // 显示清单颜色
    
    var title: String {
        switch self {
        case .workload: return "settings.task_background.workload".localized
        case .category: return "settings.task_background.category".localized
        }
    }
}


/// 音效类型枚举
enum TDSoundType: Int, CaseIterable {
    case okDing = 1
    case todoFinishVoice = 2
    
    /// 音效文件名
    var fileName: String {
        switch self {
        case .okDing:
            return "ok_ding.mp3"
        case .todoFinishVoice:
            return "todofinishvoice.mp3"
        }
    }
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .okDing:
            return "settings.sound.ok_ding".localized
        case .todoFinishVoice:
            return "settings.sound.default".localized
        
        }
    }
}
