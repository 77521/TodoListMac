//
//  TDMacTaskGroup.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation

enum TDTaskGroup: Int, CaseIterable, Comparable {
    case overdueCompleted = 0
    case overdueIncomplete = 1
    case today = 2
    case tomorrow = 3
    case dayAfterTomorrow = 4
    case future = 5
    case noDate = 6
    
    var title: String {
        switch self {
        case .overdueCompleted:
            return "已完成的过期任务"
        case .overdueIncomplete:
            return "未完成的过期任务"
        case .today:
            return "今天"
        case .tomorrow:
            return "明天"
        case .dayAfterTomorrow:
            return "后天"
        case .future:
            return "未来"
        case .noDate:
            return "无日期"
        }
    }
    
    // 实现 Comparable 协议要求的 < 操作符
    static func < (lhs: TDTaskGroup, rhs: TDTaskGroup) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
