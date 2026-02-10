//
//  TDTaskDragSortHelper.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/2/7.
//

import Foundation
/// 拖拽排序通用辅助（给 DayTodo / 最近待办分组 / 日程概览等复用）
enum TDTaskDragSortHelper {
    /// 纯内存移动数组顺序（不改数据库）
    static func move(
        tasks: [TDMacSwiftDataListModel],
        from sourceIndex: Int,
        to destinationIndex: Int
    ) -> [TDMacSwiftDataListModel] {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < tasks.count,
              destinationIndex >= 0, destinationIndex < tasks.count else {
            return tasks
        }
        var new = tasks
        let item = new.remove(at: sourceIndex)
        new.insert(item, at: destinationIndex)
        return new
    }

    /// 在移动后的数组中，找“满足过滤条件”的上一个/下一个 taskSort
    ///
    /// 重要：按 iOS 规则
    /// - **相邻数据不存在** 或 **相邻是系统订阅事件** 时，返回 nil（等价于 iOS 的 -1）
    static func findTopAndNextTaskSort(
        in movedTasks: [TDMacSwiftDataListModel],
        at index: Int,
        where predicate: (TDMacSwiftDataListModel) -> Bool
    ) -> (top: Decimal?, next: Decimal?) {
        // top：向上找
        var top: Decimal? = nil
        if index > 0 {
            for i in stride(from: index - 1, through: 0, by: -1) {
                let t = movedTasks[i]
                guard predicate(t) else { continue }
                if t.isSystemCalendarEvent { continue }
                top = t.taskSort
                break
            }
        }

        // next：向下找
        var next: Decimal? = nil
        if index < movedTasks.count - 1 {
            for i in (index + 1)..<movedTasks.count {
                let t = movedTasks[i]
                guard predicate(t) else { continue }
                if t.isSystemCalendarEvent { continue }
                next = t.taskSort
                break
            }
        }

        return (top, next)
    }
}

