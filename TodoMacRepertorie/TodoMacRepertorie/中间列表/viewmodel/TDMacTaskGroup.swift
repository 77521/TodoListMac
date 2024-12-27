//
//  TDMacTaskGroup.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/24.
//

import Foundation

enum TDMacTaskGroup: Int, CaseIterable {
    case expiredCompleted    // 已过期已完成
    case expiredUncompleted  // 已过期未完成
    case today              // 今天
    case tomorrow           // 明天
    case afterTomorrow     // 后天
    case future            // 后续日程
    case noDate            // 无日期
    
    var title: String {
        switch self {
        case .expiredCompleted:
            return "已过期已完成"
        case .expiredUncompleted:
            return "已过期未完成"
        case .today:
            return "今天"
        case .tomorrow:
            return "明天"
        case .afterTomorrow:
            return "后天"
        case .future:
            return "后续日程"
        case .noDate:
            return "无日期"
        }
    }
}
