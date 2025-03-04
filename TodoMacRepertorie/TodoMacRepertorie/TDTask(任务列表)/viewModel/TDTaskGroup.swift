//
//  TDMacTaskGroup.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation

//enum TDTaskGroup: Int, CaseIterable, Comparable {
//    case overdueCompleted = 0
//    case overdueIncomplete = 1
//    case today = 2
//    case tomorrow = 3
//    case dayAfterTomorrow = 4
//    case future = 5
//    case noDate = 6
//    
//    var title: String {
//        switch self {
//        case .overdueCompleted:
//            return "已完成的过期任务"
//        case .overdueIncomplete:
//            return "未完成的过期任务"
//        case .today:
//            return "今天"
//        case .tomorrow:
//            return "明天"
//        case .dayAfterTomorrow:
//            return "后天"
//        case .future:
//            return "后期日程"
//        case .noDate:
//            return "无日期"
//        }
//    }
//    
//    // 实现 Comparable 协议要求的 < 操作符
//    static func < (lhs: TDTaskGroup, rhs: TDTaskGroup) -> Bool {
//        lhs.rawValue < rhs.rawValue
//    }
//}
enum TDTaskGroup: Int, CaseIterable, Comparable {
    case overdueCompleted = 0   // 过期已完成
    case overdueIncomplete = 1  // 过期未完成
    case today = 2             // 今天
    case tomorrow = 3          // 明天
    case dayAfterTomorrow = 4  // 后天
    case future = 5            // 后续日程
    case noDate = 6            // 无日期
    case completed = 7         // 最近已完成
    case deleted = 8           // 回收站
    
    var title: String {
        switch self {
        case .overdueCompleted: return "已完成的过期任务"
        case .overdueIncomplete: return "未完成的过期任务"
        case .today: return "今天"
        case .tomorrow: return "明天"
        case .dayAfterTomorrow: return "后天"
        case .future: return "后续日程"
        case .noDate: return "无日期"
        case .completed: return "最近已完成"
        case .deleted: return "回收站"
        }
    }
    // 实现 Comparable 协议要求的 < 操作符
    static func < (lhs: TDTaskGroup, rhs: TDTaskGroup) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
