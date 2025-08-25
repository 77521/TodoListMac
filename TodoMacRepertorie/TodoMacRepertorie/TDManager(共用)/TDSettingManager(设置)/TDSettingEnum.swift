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
    /// 跟随系统
    case system = 1
    /// 小号 (13pt)
    case small = 2
    /// 大号 (15pt)
    case large = 3
    
    var size: CGFloat {
        switch self {
        case .system:
            return 14 // 系统默认大小
        case .small:
            return 13
        case .large:
            return 15
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
enum TDExpiredRange: Int, Codable {
    case hide = 0      // 不显示
    case sevenDays = 7 // 7天内
    case thirtyDays = 30 // 30天内
    case hundredDays = 100 // 100天内
    
    var description: String {
        switch self {
        case .hide: return "不显示"
        case .sevenDays: return "7天内"
        case .thirtyDays: return "30天内"
        case .hundredDays: return "100天内"
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
            return "全部"
        case .one:
            return "1个"
        case .two:
            return "2个"
        case .five:
            return "5个"
        case .ten:
            return "10个"
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
        case .sevenDays: return "7天"
        case .thirtyDays: return "30天"
        case .threeMonths: return "三个月"
        case .oneYear: return "1年"
        case .all: return "全部"
        }
    }
}

/// 任务背景色显示模式
enum TDTaskBackgroundMode: Int, CaseIterable {
    case workload = 0      // 显示工作量背景色
    case category = 1      // 显示清单颜色
    
    var title: String {
        switch self {
        case .workload: return "事件工作量"
        case .category: return "清单颜色"
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
            return "叮声"
        case .todoFinishVoice:
            return "完成音效"
        }
    }
}
