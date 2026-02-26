//
//  TDWidgetQueryBuilder.swift
//  TodoMacRepertorie
//
//  Widget / Extension / 外部调用的查询构建（不依赖 TDUserManager）
//

import Foundation
import SwiftData

// MARK: - Widget / 外部调用（不依赖 TDUserManager）

extension TDCorrectQueryBuilder {
    /// DayTodo 查询方法（外部注入 userId，用于 Widget 等无 TDUserManager 场景）
    /// 查询条件：userId = 传入 userId，todoTime = 传入的日期开始时间戳，delete = false
    /// 根据设置是否显示已完成事件，不显示的话添加 complete = false 条件
    static func getDayTodoQuery(
        selectedDate: Date,
        userId: Int
    ) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let settingManager = TDSettingManager.shared
        let showCompleted = settingManager.showCompletedTasks
        let dateTimestamp = selectedDate.startOfDayTimestamp

        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && !task.delete && task.todoTime == dateTimestamp &&
            (showCompleted || !task.complete)
        }

        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward), // 未完成在前，已完成在后
            SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
        ]

        return (predicate, sortDescriptors)
    }

    /// 任务列表页（最近待办/未分类/用户分类）超集查询（外部注入 userId）
    static func getTaskListSupersetQuery(
        categoryId: Int,
        tagFilter: String = "",
        userId: Int
    ) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let settingManager = TDSettingManager.shared

        let showNoDate = settingManager.showNoDateEvents
        let completedDaysLimit = settingManager.expiredRangeCompleted.rawValue
        let uncompletedDaysLimit = settingManager.expiredRangeUncompleted.rawValue
        let futureScheduleDaysLimit = settingManager.futureDateRange.rawValue

        let today = Date()
        let todayTimestamp = today.startOfDayTimestamp

        let maxBackDays = max(completedDaysLimit, uncompletedDaysLimit)
        let startLowerBound: Int64 = {
            if maxBackDays <= 0 { return todayTimestamp }
            return today.adding(days: -maxBackDays).startOfDayTimestamp
        }()

        let futureEndTimestamp: Int64? = {
            guard futureScheduleDaysLimit > 0 else { return nil }
            return today.adding(days: futureScheduleDaysLimit).endOfDayTimestamp
        }()
        let futureUpperBound: Int64 = futureEndTimestamp ?? Int64.max

        // 分类过滤（与原逻辑一致）
        // - 最近待办(-101)：不限制分类
        // - 未分类(0)：standbyInt1 == 0
        // - 标签模式(-9999)：不限制分类
        // - 其它：standbyInt1 == categoryId
        let shouldFilterByCategory = !(categoryId == -101 || categoryId == -9999)
        let standbyFilterValue = categoryId > 0 ? categoryId : 0
        let hasTagFilter = !tagFilter.isEmpty

        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            (task.userId == userId)
            && (!task.delete)
            && (!hasTagFilter || task.taskContent.localizedStandardContains(tagFilter))
            && (!shouldFilterByCategory || task.standbyInt1 == standbyFilterValue)
            && ((showNoDate && task.todoTime == 0) || (task.todoTime >= startLowerBound && task.todoTime <= futureUpperBound))
        }

        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward), // 未完成在前，已完成在后
            SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward),
            SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
        ]

        return (predicate, sortDescriptors)
    }
}

/// Widget/外部场景的 FetchDescriptor 工厂（统一 fetchLimit、排序与过滤）
enum TDWidgetTaskFetchDescriptorFactory {
    /// DayTodo：今天
    static func dayTodoToday(
        userId: Int,
        fetchLimit: Int
    ) -> FetchDescriptor<TDMacSwiftDataListModel> {
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getDayTodoQuery(selectedDate: Date(), userId: userId)
        var descriptor = FetchDescriptor<TDMacSwiftDataListModel>(predicate: predicate, sortBy: sortDescriptors)
        descriptor.fetchLimit = fetchLimit
        return descriptor
    }

    /// 列表页：最近待办 / 未分类 / 用户分类（超集查询）
    static func taskListSuperset(
        userId: Int,
        categoryId: Int,
        tagFilter: String = "",
        fetchLimit: Int
    ) -> FetchDescriptor<TDMacSwiftDataListModel> {
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getTaskListSupersetQuery(
            categoryId: categoryId,
            tagFilter: tagFilter,
            userId: userId
        )
        var descriptor = FetchDescriptor<TDMacSwiftDataListModel>(predicate: predicate, sortBy: sortDescriptors)
        descriptor.fetchLimit = fetchLimit
        return descriptor
    }
}

