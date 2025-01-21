////
////  TDMacTaskPredicateBuilder.swift
////  TodoMacRepertorie
////
////  Created by 孬孬 on 2024/12/28.
////
//
//import Foundation
//import SwiftData
//
///// 任务查询条件构建器
//class TDMacTaskPredicateBuilder {
//    
//    private let userId = TDUserManager.shared.userId ?? 0
//    
//    /// 构建基本查询条件（用户ID和删除状态）
//    func buildBasePredicate() -> Predicate<TDMacSwiftDataListModel> {
//        return #Predicate<TDMacSwiftDataListModel> { $0.userId == userId && $0.delete == false }
//    }
//    
//    /// 构建带分类ID的基本查询条件
//    func buildBasePredicateWithCategory(_ categoryId: Int) -> Predicate<TDMacSwiftDataListModel> {
//        return #Predicate<TDMacSwiftDataListModel> {
//            $0.userId == userId &&
//            !$0.delete &&
//            $0.standbyInt1 == categoryId
//        }
//    }
//    //
//    /// 构建指定日期的任务查询条件
//    func buildDatePredicate(timestamp: Int64, showFinishData: Bool) -> Predicate<TDMacSwiftDataListModel> {
//        if showFinishData {
//            return #Predicate<TDMacSwiftDataListModel> {
//                $0.userId == userId &&
//                !$0.delete &&
//                $0.todoTime == timestamp
//            }
//        } else {
//            return #Predicate<TDMacSwiftDataListModel> {
//                $0.userId == userId &&
//                !$0.delete &&
//                $0.todoTime == timestamp &&
//                !$0.complete
//            }
//        }
//    }
//    //
//    /// 构建已过期已完成任务的查询条件
//    func buildExpiredCompletedPredicate(startTimestamp: Int64, endTimestamp: Int64) -> Predicate<TDMacSwiftDataListModel> {
//        return #Predicate<TDMacSwiftDataListModel> {
//            $0.userId == userId &&
//            !$0.delete &&
//            $0.complete &&
//            ($0.todoTime ?? 0) < endTimestamp &&
//            ($0.todoTime ?? 0) >= startTimestamp
//        }
//    }
//    
//    /// 构建已过期未完成任务的查询条件
//    func buildExpiredUncompletedPredicate(startTimestamp: Int64, endTimestamp: Int64) -> Predicate<TDMacSwiftDataListModel> {
//        return #Predicate<TDMacSwiftDataListModel> {
//            $0.userId == userId &&
//            !$0.delete &&
//            !$0.complete &&
//            ($0.todoTime ?? 0) < endTimestamp &&
//            ($0.todoTime ?? 0) >= startTimestamp
//        }
//    }
//    
//    /// 构建未来任务的查询条件
//    func buildFuturePredicate(afterTimestamp: Int64, showFinishData: Bool) -> Predicate<TDMacSwiftDataListModel> {
//        if showFinishData {
//            return #Predicate<TDMacSwiftDataListModel> {
//                $0.userId == userId &&
//                !$0.delete &&
//                ($0.todoTime ?? 0) > afterTimestamp
//            }
//        } else {
//            return #Predicate<TDMacSwiftDataListModel> {
//                $0.userId == userId &&
//                !$0.delete &&
//                ($0.todoTime ?? 0) > afterTimestamp &&
//                !$0.complete
//            }
//        }
//    }
//    
//    /// 构建无日期任务的查询条件
//    func buildNoDatePredicate(showFinishData: Bool) -> Predicate<TDMacSwiftDataListModel> {
//        if showFinishData {
//            return #Predicate<TDMacSwiftDataListModel> {
//                $0.userId == userId &&
//                !$0.delete &&
//                $0.todoTime == 0
//            }
//        } else {
//            return #Predicate<TDMacSwiftDataListModel> {
//                $0.userId == userId &&
//                !$0.delete &&
//                $0.todoTime == 0 &&
//                !$0.complete
//            }
//        }
//    }
//    
//    /// 构建回收站任务的查询条件
//    func buildRecycleBinPredicate(startTimestamp: Int64) -> Predicate<TDMacSwiftDataListModel> {
//        return #Predicate<TDMacSwiftDataListModel> {
//            $0.userId == userId &&
//            $0.delete &&
//            ($0.syncTime ?? 0) >= startTimestamp
//        }
//
//    }
//    /// 构建最近已完成任务的查询条件
//    func buildRecentCompletedPredicate(startTimestamp: Int64) -> Predicate<TDMacSwiftDataListModel> {
//        return #Predicate<TDMacSwiftDataListModel> {
//            $0.userId == userId &&
//            !$0.delete &&
//            $0.complete &&
//            ($0.syncTime ?? 0) >= startTimestamp
//        }
//
//    }
//    
//    /// 构建已同步任务的查询条件
//    func buildSyncedTasksPredicate() -> Predicate<TDMacSwiftDataListModel> {
//        return #Predicate<TDMacSwiftDataListModel> {
//            $0.userId == userId &&
//            $0.status == "sync"
//        }
//    }
//    
//    /// 构建需要同步的任务查询条件
//    func buildNeedSyncPredicate() -> Predicate<TDMacSwiftDataListModel> {
//        return #Predicate<TDMacSwiftDataListModel> {
//            $0.userId == userId &&
//            $0.status != "sync"
//        }
//    }
//    
//    /// 构建根据任务ID查询的条件
//    func buildTaskByIdPredicate(taskId: String) -> Predicate<TDMacSwiftDataListModel> {
//        return #Predicate<TDMacSwiftDataListModel> {
//            $0.userId == userId &&
//            $0.taskId == taskId
//        }
//    }
//    
//    /// 构建无日期任务的查询条件（包含分类）
//    func buildNoDateTasksPredicate(categoryId: Int?) -> Predicate<TDMacSwiftDataListModel> {
//        if let categoryId = categoryId, categoryId > 0 {
//            return #Predicate<TDMacSwiftDataListModel> {
//                $0.userId == userId &&
//                !$0.delete &&
//                !$0.complete &&
//                $0.todoTime == 0 &&
//                $0.standbyInt1 == categoryId
//            }
//        } else {
//            return #Predicate<TDMacSwiftDataListModel> {
//                $0.userId == userId &&
//                !$0.delete &&
//                !$0.complete &&
//                $0.todoTime == 0
//            }
//        }
//    }
//    
//    /// 获取无日期任务的排序描述符
//    static func getNoDateSortDescriptors(sortState: Int, isReverse: Bool) -> [SortDescriptor<TDMacSwiftDataListModel>] {
//        switch sortState {
//        case 0:
//            return [SortDescriptor(\.createTime, order: isReverse ? .reverse : .forward)]
//        case 1:
//            return [SortDescriptor(\.taskSort, order: isReverse ? .reverse : .forward)]
//        case 2:
//            return [SortDescriptor(\.snowAssess, order: isReverse ? .reverse : .forward)]
//        default:
//            return [SortDescriptor(\.createTime, order: .forward)]
//        }
//    }
//    
//    /// 获取默认的排序描述符
//    static func getDefaultSortDescriptors(isTop: Bool) -> [SortDescriptor<TDMacSwiftDataListModel>] {
//        return [
//            SortDescriptor(\.taskSort, order: isTop ? .forward : .reverse)
//        ]
//    }
//    /// 获取基于时间的排序描述符
//    static func getTimeBasedSortDescriptors(isTop: Bool) -> [SortDescriptor<TDMacSwiftDataListModel>] {
//        return [
//            SortDescriptor(\.todoTime, order: .forward),
//            SortDescriptor(\.taskSort, order: isTop ? .forward : .reverse)
//        ]
//    }
//}
