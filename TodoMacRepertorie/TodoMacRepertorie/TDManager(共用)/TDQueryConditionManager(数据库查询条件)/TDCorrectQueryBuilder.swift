//
//  TDCorrectQueryBuilder.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/29.
//

import Foundation
import SwiftData

/// 数据库查询条件构建器
/// 负责构建所有 SwiftData 查询的 Predicate 和 SortDescriptor
/// 注意：#Predicate 宏不支持运行时动态组合条件，必须在闭包内使用捕获变量进行短路求值
struct TDCorrectQueryBuilder {

    // MARK: - 版本号查询

    /// 获取本地最大 version（同步流程专用）
    /// 条件：userId = 当前用户 & status = "sync"，按 version 降序取首条
    static func getLocalMaxVersionQuery() -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && task.status == "sync"
        }
        return (predicate, [SortDescriptor(\.version, order: .reverse)])
    }

    /// 获取本地最大 version（本地增删改专用）
    /// 条件：userId = 当前用户，按 version 降序取首条
    static func getLocalMaxVersionForLocalQuery() -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId
        }
        return (predicate, [SortDescriptor(\.version, order: .reverse)])
    }

    // MARK: - 按 taskId 查询

    /// 根据 taskId 精确查询（taskId 唯一，无需排序）
    /// 条件：userId = 当前用户 & taskId = 传入值
    static func getLocalTaskByTaskIdQuery(_ taskId: String) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.taskId == taskId && task.userId == userId
        }
        return (predicate, [])
    }

    // MARK: - 日期任务列表查询

    /// 指定日期的任务列表查询
    /// 条件：userId + !delete + todoTime = 指定日期时间戳 + 按设置决定是否过滤已完成
    static func getDayTodoQuery(selectedDate: Date) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId
        let showCompleted = TDSettingManager.shared.showCompletedTasks
        let dateTimestamp = selectedDate.startOfDayTimestamp
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && !task.delete && task.todoTime == dateTimestamp &&
            (showCompleted || !task.complete)
        }
        let sortDescriptors = getTaskListSortDescriptors(sortType: TDSettingManager.shared.taskListSortType)
        return (predicate, sortDescriptors)
    }

    // MARK: - 未同步数据查询

    /// 查询本地所有未同步数据（status != "sync"）
    /// 用于上传本地修改到服务器
    static func getLocalUnsyncedDataQuery() -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && task.status != "sync"
        }
        return (predicate, [SortDescriptor(\.createTime, order: .reverse)])
    }

    // MARK: - taskSort 辅助查询

    /// 查询指定日期的最大 taskSort（用于"添加到底部"逻辑）
    static func getMaxTaskSortForDateQuery(_ todoTime: Int64) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && !task.delete && task.todoTime == todoTime
        }
        return (predicate, [SortDescriptor(\.taskSort, order: .reverse)])
    }

    /// 查询指定日期的最小 taskSort（用于"添加到顶部"逻辑）
    static func getMinTaskSortForDateQuery(_ todoTime: Int64) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && !task.delete && task.todoTime == todoTime
        }
        return (predicate, [SortDescriptor(\.taskSort, order: .forward)])
    }

    // MARK: - 排序描述符

    /// 根据排序类型返回任务列表排序规则
    /// - 所有模式下：已完成永远排在未完成下方，内部再按各自规则排序
    /// - Parameter sortType: 0=默认(taskSort) 1=提醒时间 2=添加时间↑ 3=添加时间↓ 4=工作量↑ 5=工作量↓
    static func getTaskListSortDescriptors(sortType: Int) -> [SortDescriptor<TDMacSwiftDataListModel>] {
        switch sortType {
        case 1: // 提醒时间升序
            return [
                SortDescriptor(\.complete, order: .forward),
                SortDescriptor(\.reminderTime, order: .forward),
                SortDescriptor(\.taskSort, order: .forward)
            ]
        case 2: // 添加时间升序
            return [
                SortDescriptor(\.complete, order: .forward),
                SortDescriptor(\.createTime, order: .forward)
            ]
        case 3: // 添加时间降序
            return [
                SortDescriptor(\.complete, order: .forward),
                SortDescriptor(\.createTime, order: .reverse)
            ]
        case 4: // 工作量升序
            return [
                SortDescriptor(\.complete, order: .forward),
                SortDescriptor(\.snowAssess, order: .forward),
                SortDescriptor(\.taskSort, order: .forward)
            ]
        case 5: // 工作量降序
            return [
                SortDescriptor(\.complete, order: .forward),
                SortDescriptor(\.snowAssess, order: .reverse),
                SortDescriptor(\.taskSort, order: .forward)
            ]
        default: // 0：自定义排序（taskSort升序）
            return [
                SortDescriptor(\.complete, order: .forward),
                SortDescriptor(\.taskSort, order: .forward)
            ]
        }
    }

    // MARK: - 应用层过滤辅助

    /// 标签筛选（应用层调用，不走 SwiftData 谓词）
    static func filterTasksByTag(_ tasks: [TDMacSwiftDataListModel], tagFilter: String) -> [TDMacSwiftDataListModel] {
        guard !tagFilter.isEmpty else { return tasks }
        return tasks.filter { $0.taskContent.contains(tagFilter) }
    }

    /// 全文搜索（应用层调用，搜索标题 / 备注 / 附件名）
    static func filterTasksBySearchText(_ tasks: [TDMacSwiftDataListModel], searchText: String) -> [TDMacSwiftDataListModel] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return tasks }
        return tasks.filter {
            $0.taskContent.localizedStandardContains(keyword) ||
            ($0.taskDescribe?.localizedStandardContains(keyword) ?? false) ||
            ($0.standbyStr2?.localizedStandardContains(keyword) ?? false)
        }
    }

    // MARK: - 任务列表超集查询（最近待办 / 未分类 / 用户分类）

    /// 任务列表页超集查询
    /// 保证"不会少数据"的范围超集，具体分组 / 显示规则由 UI 侧内存分组完成（业务逻辑不变）
    /// - Parameters:
    ///   - categoryId: -101=最近待办（不限分类）, -9999=标签模式（不限分类）, 0=未分类, >0=指定分类
    ///   - tagFilter: 标签关键词（含 #），为空则不过滤
    static func getTaskListSupersetQuery(
        categoryId: Int,
        tagFilter: String = ""
    ) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let settingManager = TDSettingManager.shared
        let userId = TDUserManager.shared.userId

        let showNoDate = settingManager.showNoDateEvents
        let completedDaysLimit = settingManager.expiredRangeCompleted.rawValue
        let uncompletedDaysLimit = settingManager.expiredRangeUncompleted.rawValue
        let futureScheduleDaysLimit = settingManager.futureDateRange.rawValue

        let today = Date()
        let todayTimestamp = today.startOfDayTimestamp

        // 过去时间下界：取已完成/未完成天数限制中的较大值
        let maxBackDays = max(completedDaysLimit, uncompletedDaysLimit)
        let startLowerBound: Int64 = maxBackDays <= 0
            ? todayTimestamp
            : today.adding(days: -maxBackDays).startOfDayTimestamp

        // 未来时间上界：0 表示不限制
        let futureUpperBound: Int64 = futureScheduleDaysLimit > 0
            ? today.adding(days: futureScheduleDaysLimit).endOfDayTimestamp
            : Int64.max

        // 分类过滤规则（与 iOS 保持一致）
        // -101 最近待办 / -9999 标签模式：不限分类
        // 0 未分类：standbyInt1 == 0
        // >0 用户分类：standbyInt1 == categoryId
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

        return (predicate, getTaskListSortDescriptors(sortType: settingManager.taskListSortType))
    }

    // MARK: - 搜索查询

    /// 搜索页查询（文字匹配由应用层处理，此处只做结构化条件过滤）
    /// - Parameters:
    ///   - dateFilter: 0=全部, 7=近7天, 30=近30天, 6=近半年, 1=近1年
    ///   - categoryId: 0=全部, >0=指定分类
    ///   - tagFilter: 标签关键词（含 #）
    ///   - completeFilter: 0=全部, 1=已完成, 2=未完成
    static func getSearchQuery(
        dateFilter: Int = 0,
        categoryId: Int = 0,
        tagFilter: String = "",
        completeFilter: Int = 0
    ) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId

        // 计算日期下界时间戳
        let startTimestamp: Int64 = {
            guard dateFilter > 0 else { return 0 }
            let daysMap: [Int: Int] = [7: 7, 30: 30, 6: 180, 1: 365]
            let days = daysMap[dateFilter] ?? 0
            return days > 0 ? Date().adding(days: -days).startOfDayTimestamp : 0
        }()

        let hasDateFilter     = startTimestamp > 0
        let hasCategoryFilter = categoryId > 0
        let hasTagFilter      = !tagFilter.isEmpty

        // 注意：#Predicate 宏要求闭包为单表达式，不能在闭包内部使用 if/else，
        // 但可以使用短路求值（||/&&）+ 捕获 Bool 变量实现"可选过滤"。
        // 三种完成状态使用三个独立 #Predicate，避免宏在同一闭包内分支报错。
        let predicate = makeSearchPredicate(
            userId: userId,
            hasDateFilter: hasDateFilter, startTimestamp: startTimestamp,
            hasCategoryFilter: hasCategoryFilter, categoryId: categoryId,
            hasTagFilter: hasTagFilter, tagFilter: tagFilter,
            completeFilter: completeFilter
        )

        let sortDescriptors: [SortDescriptor<TDMacSwiftDataListModel>] = [
            SortDescriptor(\.todoTime, order: .reverse),
            SortDescriptor(\.taskSort, order: .forward)
        ]
        return (predicate, sortDescriptors)
    }

    /// 搜索谓词内部构建（按完成状态分三路，复用捕获变量短路逻辑）
    private static func makeSearchPredicate(
        userId: Int,
        hasDateFilter: Bool, startTimestamp: Int64,
        hasCategoryFilter: Bool, categoryId: Int,
        hasTagFilter: Bool, tagFilter: String,
        completeFilter: Int
    ) -> Predicate<TDMacSwiftDataListModel> {
        switch completeFilter {
        case 1: // 已完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && task.complete
                && (!hasDateFilter     || task.todoTime >= startTimestamp)
                && (!hasCategoryFilter || task.standbyInt1 == categoryId)
                && (!hasTagFilter      || task.taskContent.localizedStandardContains(tagFilter))
            }
        case 2: // 未完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && !task.complete
                && (!hasDateFilter     || task.todoTime >= startTimestamp)
                && (!hasCategoryFilter || task.standbyInt1 == categoryId)
                && (!hasTagFilter      || task.taskContent.localizedStandardContains(tagFilter))
            }
        default: // 全部
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete
                && (!hasDateFilter     || task.todoTime >= startTimestamp)
                && (!hasCategoryFilter || task.standbyInt1 == categoryId)
                && (!hasTagFilter      || task.taskContent.localizedStandardContains(tagFilter))
            }
        }
    }

    // MARK: - 已删除 / 回收站

    /// 查询已删除任务（7天内，最多200条）
    static func getDeletedTasksFetchDescriptor() -> FetchDescriptor<TDMacSwiftDataListModel> {
        let userId = TDUserManager.shared.userId
        let startTimestamp = Int64(Date().adding(days: -7).startOfDayTimestamp)
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && task.delete && task.createTime >= startTimestamp
        }
        var descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.todoTime, order: .forward),
                SortDescriptor(\.taskSort, order: .forward)
            ]
        )
        descriptor.fetchLimit = 200
        return descriptor
    }

    // MARK: - 无日期事件

    /// 查询无日期未完成事件（待办箱 / 无日期列表入口）
    /// - Parameters:
    ///   - categoryId: >0 时按分类过滤，否则不限制
    ///   - sortField: 0=createTime  1=taskSort  2=snowAssess
    ///   - isAscending: 是否升序
    static func getNoDateUncompletedQuery(
        categoryId: Int = 0,
        sortField: Int = 0,
        isAscending: Bool = false
    ) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId
        let hasCategoryFilter = categoryId > 0
        // 修复：补充 !task.delete 过滤已删除数据
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && !task.delete && task.todoTime == 0 && !task.complete &&
            (!hasCategoryFilter || task.standbyInt1 == categoryId)
        }
        let order: SortOrder = isAscending ? .forward : .reverse
        let sortDescriptors: [SortDescriptor<TDMacSwiftDataListModel>] = {
            switch sortField {
            case 1: return [SortDescriptor(\.taskSort, order: .forward)]
            case 2: return [SortDescriptor(\.snowAssess, order: order)]
            default: return [SortDescriptor(\.createTime, order: order)]
            }
        }()
        return (predicate, sortDescriptors)
    }

    /// 待办箱完整查询（todoTime == 0，含已完成，界面自行决定展示规则）
    static func getInboxNoDateQuery() -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            (task.userId == userId) && (!task.delete) && (task.todoTime == 0)
        }
        // 待办箱有内部排序菜单，SwiftData 层不强制排序
        return (predicate, [])
    }

    // MARK: - 重复事件

    /// 根据重复 ID（standbyStr1）查询关联任务
    /// - Parameters:
    ///   - standbyStr1: 重复 ID
    ///   - onlyUncompleted: 是否只查询未完成
    static func getDuplicateTasksQuery(
        standbyStr1: String,
        onlyUncompleted: Bool = false
    ) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId
        let predicate: Predicate<TDMacSwiftDataListModel> = onlyUncompleted
            ? #Predicate { task in
                task.userId == userId && !task.delete && task.standbyStr1 == standbyStr1 && !task.complete
              }
            : #Predicate { task in
                task.userId == userId && !task.delete && task.standbyStr1 == standbyStr1
              }
        return (predicate, [SortDescriptor(\.todoTime, order: .forward)])
    }

    /// 查询所有含重复 ID 的任务（应用层去重，每个 standbyStr1 只保留一条）
    static func getUniqueDuplicateIdsQuery() -> FetchDescriptor<TDMacSwiftDataListModel> {
        let userId = TDUserManager.shared.userId
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && !task.delete &&
            task.standbyStr1 != nil && task.standbyStr1 != "" && task.standbyStr1 != "null"
        }
        return FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.todoTime, order: .forward)])
    }

    // MARK: - 附件查询

    /// 查询含附件的任务基础集合（standbyStr4 非空/非 null）
    /// 附件类型（图片/非图片）判断由应用层处理，避免在持久层访问复杂类型
    static func getTasksWithAttachmentsFetchDescriptor() -> FetchDescriptor<TDMacSwiftDataListModel> {
        let userId = TDUserManager.shared.userId
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && !task.delete &&
            task.standbyStr4 != nil && task.standbyStr4 != "" && task.standbyStr4 != "null"
        }
        return FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.createTime, order: .reverse)])
    }

    // MARK: - 标签管理

    /// 根据标签 key 查询所有包含该标签的任务（标签管理弹窗专用）
    /// 条件：userId + !delete + status != "delete" + taskContent 包含 tagKey
    static func getTasksByTagKeyQuery(_ tagKey: String) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId
        let key = tagKey
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && !task.delete && task.status != "delete" &&
            task.taskContent.localizedStandardContains(key)
        }
        return (predicate, [SortDescriptor(\.createTime, order: .reverse)])
    }

    // MARK: - 最近已完成 / 最近待办

    /// 最近已完成事件查询（第二栏「最近已完成」页面专用）
    /// 规则：有日期 + 已完成 + 未删除 + 当前用户，最近 N 天（含今天）
    static func getRecentCompletedQuery(days: Int = 30) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId
        let today = Date()
        // 例如 days=30：今天 + 前29天 = 30天
        let lowerBound = today.adding(days: -(max(days, 1) - 1)).startOfDayTimestamp
        let upperBound = today.endOfDayTimestamp
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            (task.userId == userId) && (!task.delete) && (task.complete) &&
            (task.todoTime > 0) && (task.todoTime >= lowerBound) && (task.todoTime <= upperBound)
        }
        return (predicate, [
            SortDescriptor(\.todoTime, order: .reverse),
            SortDescriptor(\.taskSort, order: .forward)
        ])
    }
}
