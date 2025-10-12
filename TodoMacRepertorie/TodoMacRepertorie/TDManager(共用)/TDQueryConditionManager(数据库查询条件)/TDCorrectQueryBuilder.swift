//
//  TDCorrectQueryBuilder.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/29.
//

import Foundation
import SwiftData

/// 正确的查询构建器 - 按照实际业务逻辑
/// 这个文件负责构建所有的数据库查询条件，包括 Predicate 和 SortDescriptor
struct TDCorrectQueryBuilder {
    
    // MARK: - 查询本地最大 version 值的方法
    
    /// 获取本地最大 version 值（用于同步流程）
    /// 查询条件：userid = 本地登录用户 id，status = "sync"
    static func getLocalMaxVersionQuery() -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && task.status == "sync"
        }
        
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.version, order: .reverse)
        ]
        
        return (predicate, sortDescriptors)
    }
    
    /// 获取本地最大 version 值（用于本地增删改）
    /// 查询条件：userid = 本地登录用户 id
    static func getLocalMaxVersionForLocalQuery() -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId
        }
        
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.version, order: .reverse)
        ]
        
        return (predicate, sortDescriptors)
    }
    
    /// 根据 taskId 查询本地数据
    /// 查询条件：userid = 用户登录 id，taskid = 传入进来的taskId
    static func getLocalTaskByTaskIdQuery(_ taskId: String) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.taskId == taskId && task.userId == userId
        }
        
        // 根据 taskId 查询不需要排序，因为 taskId 是唯一的
        let sortDescriptors: [SortDescriptor<TDMacSwiftDataListModel>] = []
        
        return (predicate, sortDescriptors)
    }
    
    /// DayTodo 查询方法
    /// 查询条件：userid = 用户登录 id，todoTime = 传入的时间戳，delete = false
    /// 根据设置是否显示已完成事件，不显示的话添加 complete = false 条件
    static func getDayTodoQuery(selectedDate: Date) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let settingManager = TDSettingManager.shared
        let userId = TDUserManager.shared.userId
        let showCompleted = settingManager.showCompletedTasks
        let dateTimestamp = selectedDate.startOfDayTimestamp
//        
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && !task.delete && task.todoTime == dateTimestamp &&
            (showCompleted || !task.complete)
        }
        // 使用日期排序
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward), // 未完成在前，已完成在后
            SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
        ]
        
        return (predicate, sortDescriptors)
    }
    
    // MARK: - 优化的分组查询方法
    
    /// 查询过期已完成任务（优化版本）
    static func getExpiredCompletedQuery(categoryId: Int) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let settingManager = TDSettingManager.shared
        let userId = TDUserManager.shared.userId
        let showCompleted = settingManager.showCompletedTasks
        let completedDaysLimit = settingManager.expiredRangeCompleted.rawValue
        
        // 如果设置为不显示，返回空查询
        if completedDaysLimit <= 0 {
            let predicate = #Predicate<TDMacSwiftDataListModel> { task in
                false
            }
            return (predicate, [])
        }
        
        // 计算时间范围
        let today = Date()
        let completedStartDate = today.adding(days: -completedDaysLimit)
        let completedStartTimestamp = completedStartDate.startOfDayTimestamp
        let todayTimestamp = today.startOfDayTimestamp
        
        // 根据 categoryId 创建不同的 Predicate
        let predicate: Predicate<TDMacSwiftDataListModel>
        
        switch categoryId {
        case -101: // 最近待办
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && task.complete &&
                (showCompleted || !task.complete) &&
                task.todoTime >= completedStartTimestamp && task.todoTime < todayTimestamp
            }
        case 0: // 未分类
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && task.complete &&
                (showCompleted || !task.complete) &&
                task.todoTime >= completedStartTimestamp && task.todoTime < todayTimestamp &&
                task.standbyInt1 == 0
            }
        default: // 分类清单
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && task.complete &&
                (showCompleted || !task.complete) &&
                task.todoTime >= completedStartTimestamp && task.todoTime < todayTimestamp &&
                task.standbyInt1 == categoryId
            }
        }
        
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward), // 日期升序
            SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward) // taskSort 升序
        ]
        
        return (predicate, sortDescriptors)
    }
    
    /// 查询过期未完成任务（优化版本）
    static func getExpiredUncompletedQuery(categoryId: Int) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let settingManager = TDSettingManager.shared
        let userId = TDUserManager.shared.userId
        let showCompleted = settingManager.showCompletedTasks
        let uncompletedDaysLimit = settingManager.expiredRangeUncompleted.rawValue
        
        // 如果设置为不显示，返回空查询
        if uncompletedDaysLimit <= 0 {
            let predicate = #Predicate<TDMacSwiftDataListModel> { task in
                false
            }
            return (predicate, [])
        }
        
        // 计算时间范围
        let today = Date()
        let uncompletedStartDate = today.adding(days: -uncompletedDaysLimit)
        let uncompletedStartTimestamp = uncompletedStartDate.startOfDayTimestamp
        let todayTimestamp = today.startOfDayTimestamp
        
        // 根据 categoryId 创建不同的 Predicate
        let predicate: Predicate<TDMacSwiftDataListModel>
        
        switch categoryId {
        case -101: // 最近待办
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && !task.complete &&
                (showCompleted || !task.complete) &&
                task.todoTime >= uncompletedStartTimestamp && task.todoTime < todayTimestamp
            }
        case 0: // 未分类
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && !task.complete &&
                (showCompleted || !task.complete) &&
                task.todoTime >= uncompletedStartTimestamp && task.todoTime < todayTimestamp &&
                task.standbyInt1 == 0
            }
        default: // 分类清单
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && !task.complete &&
                (showCompleted || !task.complete) &&
                task.todoTime >= uncompletedStartTimestamp && task.todoTime < todayTimestamp &&
                task.standbyInt1 == categoryId
            }
        }
        
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward), // 日期升序
            SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward) // taskSort 升序
        ]
        
        return (predicate, sortDescriptors)
    }
    
    /// 查询今天任务（优化版本）
    static func getTodayQuery(categoryId: Int) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let settingManager = TDSettingManager.shared
        let userId = TDUserManager.shared.userId
        let showCompleted = settingManager.showCompletedTasks
        let todayTimestamp = Date().startOfDayTimestamp
        
        // 根据 categoryId 创建不同的 Predicate
        let predicate: Predicate<TDMacSwiftDataListModel>
        
        switch categoryId {
        case -101: // 最近待办
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                (showCompleted || !task.complete) &&
                task.todoTime == todayTimestamp
            }
        case 0: // 未分类
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                (showCompleted || !task.complete) &&
                task.todoTime == todayTimestamp &&
                task.standbyInt1 == 0
            }
        default: // 分类清单
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                (showCompleted || !task.complete) &&
                task.todoTime == todayTimestamp &&
                task.standbyInt1 == categoryId
            }
        }
        
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward), // 未完成在前，已完成在后
            SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward) // taskSort 升序
        ]
        
        return (predicate, sortDescriptors)
    }
    
    /// 查询明天任务（优化版本）
    static func getTomorrowQuery(categoryId: Int) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let settingManager = TDSettingManager.shared
        let userId = TDUserManager.shared.userId
        let showCompleted = settingManager.showCompletedTasks
        let tomorrowTimestamp = Date().adding(days: 1).startOfDayTimestamp
        
        // 根据 categoryId 创建不同的 Predicate
        let predicate: Predicate<TDMacSwiftDataListModel>
        
        switch categoryId {
        case -101: // 最近待办
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                (showCompleted || !task.complete) &&
                task.todoTime == tomorrowTimestamp
            }
        case 0: // 未分类
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                (showCompleted || !task.complete) &&
                task.todoTime == tomorrowTimestamp &&
                task.standbyInt1 == 0
            }
        default: // 分类清单
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                (showCompleted || !task.complete) &&
                task.todoTime == tomorrowTimestamp &&
                task.standbyInt1 == categoryId
            }
        }
        
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward), // 未完成在前，已完成在后
            SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward) // taskSort 升序
        ]
        
        return (predicate, sortDescriptors)
    }
    
    /// 查询后天任务（优化版本）
    static func getDayAfterTomorrowQuery(categoryId: Int) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let settingManager = TDSettingManager.shared
        let userId = TDUserManager.shared.userId
        let showCompleted = settingManager.showCompletedTasks
        let dayAfterTomorrowTimestamp = Date().adding(days: 2).startOfDayTimestamp
        
        // 根据 categoryId 创建不同的 Predicate
        let predicate: Predicate<TDMacSwiftDataListModel>
        
        switch categoryId {
        case -101: // 最近待办
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                (showCompleted || !task.complete) &&
                task.todoTime == dayAfterTomorrowTimestamp
            }
        case 0: // 未分类
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                (showCompleted || !task.complete) &&
                task.todoTime == dayAfterTomorrowTimestamp &&
                task.standbyInt1 == 0
            }
        default: // 分类清单
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                (showCompleted || !task.complete) &&
                task.todoTime == dayAfterTomorrowTimestamp &&
                task.standbyInt1 == categoryId
            }
        }
        
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward), // 未完成在前，已完成在后
            SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward) // taskSort 升序
        ]
        
        return (predicate, sortDescriptors)
    }
    
    /// 查询后续日程任务（优化版本）
    static func getFutureScheduleQuery(categoryId: Int) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let settingManager = TDSettingManager.shared
        let userId = TDUserManager.shared.userId
        let showCompleted = settingManager.showCompletedTasks
        let futureScheduleDaysLimit = settingManager.futureDateRange.rawValue
        
        // 计算时间范围
        let today = Date()
        let dayAfterTomorrowTimestamp = today.adding(days: 2).startOfDayTimestamp
        
        // 根据 categoryId 和设置创建不同的 Predicate
        let predicate: Predicate<TDMacSwiftDataListModel>
        
        if futureScheduleDaysLimit == 0 {
            // 全部显示，不限制天数
            switch categoryId {
            case -101: // 最近待办
                predicate = #Predicate<TDMacSwiftDataListModel> { task in
                    task.userId == userId && !task.delete &&
                    (showCompleted || !task.complete) &&
                    task.todoTime > dayAfterTomorrowTimestamp
                }
            case 0: // 未分类
                predicate = #Predicate<TDMacSwiftDataListModel> { task in
                    task.userId == userId && !task.delete &&
                    (showCompleted || !task.complete) &&
                    task.todoTime > dayAfterTomorrowTimestamp &&
                    task.standbyInt1 == 0
                }
            default: // 分类清单
                predicate = #Predicate<TDMacSwiftDataListModel> { task in
                    task.userId == userId && !task.delete &&
                    (showCompleted || !task.complete) &&
                    task.todoTime > dayAfterTomorrowTimestamp &&
                    task.standbyInt1 == categoryId
                }
            }
        } else {
            // 根据设置的天数限制
            let futureEndDate = today.adding(days: futureScheduleDaysLimit)
            let futureEndTimestamp = futureEndDate.endOfDayTimestamp
            
            switch categoryId {
            case -101: // 最近待办
                predicate = #Predicate<TDMacSwiftDataListModel> { task in
                    task.userId == userId && !task.delete &&
                    (showCompleted || !task.complete) &&
                    task.todoTime > dayAfterTomorrowTimestamp && task.todoTime <= futureEndTimestamp
                }
            case 0: // 未分类
                predicate = #Predicate<TDMacSwiftDataListModel> { task in
                    task.userId == userId && !task.delete &&
                    (showCompleted || !task.complete) &&
                    task.todoTime > dayAfterTomorrowTimestamp && task.todoTime <= futureEndTimestamp &&
                    task.standbyInt1 == 0
                }
            default: // 分类清单
                predicate = #Predicate<TDMacSwiftDataListModel> { task in
                    task.userId == userId && !task.delete &&
                    (showCompleted || !task.complete) &&
                    task.todoTime > dayAfterTomorrowTimestamp && task.todoTime <= futureEndTimestamp &&
                    task.standbyInt1 == categoryId
                }
            }
        }
        
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward), // 日期升序
            SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward), // 未完成在前，已完成在后
            SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward) // taskSort 升序
        ]
        
        return (predicate, sortDescriptors)
    }
    
    /// 查询无日期任务（优化版本）
    static func getNoDateQuery(categoryId: Int) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let settingManager = TDSettingManager.shared
        let userId = TDUserManager.shared.userId
        let showNoDate = settingManager.showNoDateEvents
        let showCompletedNoDate = settingManager.showCompletedNoDateEvents
        
        // 如果设置为不显示无日期事件，返回空查询
        if !showNoDate {
            let predicate = #Predicate<TDMacSwiftDataListModel> { task in
                false
            }
            return (predicate, [])
        }
        
        // 根据 categoryId 创建不同的 Predicate
        let predicate: Predicate<TDMacSwiftDataListModel>
        
        switch categoryId {
        case -101: // 最近待办
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                (showCompletedNoDate || !task.complete) &&
                task.todoTime == 0
            }
        case 0: // 未分类
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                (showCompletedNoDate || !task.complete) &&
                task.todoTime == 0 &&
                task.standbyInt1 == 0
            }
        default: // 分类清单
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                (showCompletedNoDate || !task.complete) &&
                task.todoTime == 0 &&
                task.standbyInt1 == categoryId
            }
        }
        
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward), // 未完成在前，已完成在后
            SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward) // taskSort 升序
        ]
        
        return (predicate, sortDescriptors)
    }
    
    /// 查询本地所有未同步数据
    /// 查询条件：status != "sync"，userid = 当前登录用户 Id
    static func getLocalUnsyncedDataQuery() -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        let userId = TDUserManager.shared.userId
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && task.status != "sync"
        }
        
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.createTime, order: .reverse)
        ]
        
        return (predicate, sortDescriptors)
    }
    
    /// 获取本地数据查询 - 支持日期、分类、完成状态筛选和多种排序方式
    /// 注意：标签筛选需要在应用层处理，这里只提供基础筛选
    /// - Parameters:
    ///   - dateTimestamp: 日期时间戳
    ///   - categoryId: 分类ID，>0时添加分类筛选条件
    ///   - sortType: 排序类型 0:默认 1:提醒时间 2:添加时间a-z 3:添加时间z-a 4:工作量a-z 5:工作量z-a
    /// - Returns: 查询条件和排序描述符
    static func getLocalDataQuery(
        dateTimestamp: Int64,
        categoryId: Int = 0,
        sortType: Int = 0
    ) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        
        let userId = TDUserManager.shared.userId
        let settingManager = TDSettingManager.shared
        let showCompleted = settingManager.showCompletedTasks
        
        // 构建基础查询条件
        let predicate: Predicate<TDMacSwiftDataListModel>
        
        if categoryId > 0 {
            // 有分类筛选
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                task.todoTime == dateTimestamp &&
                task.standbyInt1 == categoryId &&
                (showCompleted || !task.complete)
            }
        } else {
            // 基础查询条件
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                task.todoTime == dateTimestamp &&
                (showCompleted || !task.complete)
            }
        }
        
        // 根据排序类型创建排序描述符
        // 已完成永远在未完成下方，但已完成内部仍然按照相同的排序规则
        let sortDescriptors: [SortDescriptor<TDMacSwiftDataListModel>]
        
        switch sortType {
        case 1: // 提醒时间：order by reminderTime asc、taskSort asc
            sortDescriptors = [
                SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward), // 未完成在前，已完成在后
                SortDescriptor(\TDMacSwiftDataListModel.reminderTime, order: .forward),
                SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
            ]
        case 2: // 添加时间a-z：order by createTime asc
            sortDescriptors = [
                SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward), // 未完成在前，已完成在后
                SortDescriptor(\TDMacSwiftDataListModel.createTime, order: .forward)
            ]
        case 3: // 添加时间z-a：order by createTime desc
            sortDescriptors = [
                SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward), // 未完成在前，已完成在后
                SortDescriptor(\TDMacSwiftDataListModel.createTime, order: .reverse)
            ]
        case 4: // 工作量a-z：order by snowAssess asc, taskSort asc
            sortDescriptors = [
                SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward), // 未完成在前，已完成在后
                SortDescriptor(\TDMacSwiftDataListModel.snowAssess, order: .forward),
                SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
            ]
        case 5: // 工作量z-a：order by snowAssess desc, taskSort asc
            sortDescriptors = [
                SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward), // 未完成在前，已完成在后
                SortDescriptor(\TDMacSwiftDataListModel.snowAssess, order: .reverse),
                SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
            ]
        default: // 0: 默认根据 taskSort 值升序
            sortDescriptors = [
                SortDescriptor(\TDMacSwiftDataListModel.complete, order: .forward), // 未完成在前，已完成在后
                SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
            ]
        }
        
        return (predicate, sortDescriptors)
    }
       
    /// 标签筛选辅助方法 - 在应用层使用
    /// - Parameters:
    ///   - tasks: 需要筛选的任务数组
    ///   - tagFilter: 标签筛选条件，为空时不筛选
    /// - Returns: 筛选后的任务数组
    static func filterTasksByTag(_ tasks: [TDMacSwiftDataListModel], tagFilter: String) -> [TDMacSwiftDataListModel] {
        guard !tagFilter.isEmpty else { return tasks }
        
        return tasks.filter { task in
            return task.taskContent.contains(tagFilter)
        }
    }

       

    
    /// 搜索方法 - 根据筛选条件查询任务（搜索文字在应用层实现）
    /// 筛选条件：日期、分类、标签、完成状态
    /// 注意：搜索文字功能需要在应用层实现，这里只提供基础筛选
    /// 使用方法：
    /// 1. 先调用此方法获取基础筛选结果
    /// 2. 在应用层对结果进行文字搜索过滤
    /// 3. 示例：
    ///    let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getSearchQuery(dateFilter: 7, categoryId: 1, tagFilter: "#工作")
    ///    let tasks = try context.fetch(FetchDescriptor(predicate: predicate, sortBy: sortDescriptors))
    ///    let searchResults = tasks.filter { task in
    ///        task.taskContent.localizedStandardContains(searchText) ||
    ///        (task.taskDescribe?.localizedStandardContains(searchText) ?? false) ||
    ///        (task.standbyStr2?.localizedStandardContains(searchText) ?? false)
    ///    }
    static func getSearchQuery(
        dateFilter: Int = 0,      // 0:全部, 7:7天, 30:30天, 6:半年, 1:1年
        categoryId: Int = 0,      // 0:全部, >0:分类ID
        tagFilter: String = "",   // 标签筛选（带#的文字）
        completeFilter: Int = 0   // 0:全部, 1:已完成, 2:未完成
    ) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        
        let userId = TDUserManager.shared.userId
        
        // 计算日期范围
        let startTimestamp: Int64
        if dateFilter > 0 {
            let today = Date()
            switch dateFilter {
            case 7:
                startTimestamp = Int64(today.adding(days: -7).startOfDayTimestamp)
            case 30:
                startTimestamp = Int64(today.adding(days: -30).startOfDayTimestamp)
            case 6: // 半年
                startTimestamp = Int64(today.adding(days: -180).startOfDayTimestamp)
            case 1: // 1年
                startTimestamp = Int64(today.adding(days: -365).startOfDayTimestamp)
            default:
                startTimestamp = 0
            }
        } else {
            startTimestamp = 0
        }
        
        // 根据筛选条件创建不同的 Predicate
        let predicate: Predicate<TDMacSwiftDataListModel>
        
        // 根据完成状态创建不同的 Predicate
        switch completeFilter {
        case 1: // 已完成
            predicate = createCompletedFilterPredicate(
                userId: userId,
                tagFilter: tagFilter,
                dateFilter: dateFilter,
                categoryId: categoryId,
                startTimestamp: startTimestamp
            )
            
        case 2: // 未完成
            predicate = createIncompleteFilterPredicate(
                userId: userId,
                tagFilter: tagFilter,
                dateFilter: dateFilter,
                categoryId: categoryId,
                startTimestamp: startTimestamp
            )
            
        default: // 全部
            predicate = createAllFilterPredicate(
                userId: userId,
                tagFilter: tagFilter,
                dateFilter: dateFilter,
                categoryId: categoryId,
                startTimestamp: startTimestamp
            )
        }
        
        // 排序：先按日期降序，再按 taskSort 升序
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .reverse), // 日期降序
            SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward) // taskSort 升序
        ]
        
        return (predicate, sortDescriptors)
    }
    
    /// 创建已完成筛选 Predicate
    private static func createCompletedFilterPredicate(
        userId: Int,
        tagFilter: String,
        dateFilter: Int,
        categoryId: Int,
        startTimestamp: Int64
    ) -> Predicate<TDMacSwiftDataListModel> {
        
        // 根据筛选条件组合 Predicate
        if dateFilter > 0 && categoryId > 0 && !tagFilter.isEmpty {
            // 日期 + 分类 + 标签 + 已完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && task.complete &&
                task.todoTime >= startTimestamp &&
                task.standbyInt1 == categoryId &&
                task.taskContent.localizedStandardContains(tagFilter)
            }
        } else if dateFilter > 0 && categoryId > 0 {
            // 日期 + 分类 + 已完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && task.complete &&
                task.todoTime >= startTimestamp &&
                task.standbyInt1 == categoryId
            }
        } else if dateFilter > 0 && !tagFilter.isEmpty {
            // 日期 + 标签 + 已完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && task.complete &&
                task.todoTime >= startTimestamp &&
                task.taskContent.localizedStandardContains(tagFilter)
            }
        } else if categoryId > 0 && !tagFilter.isEmpty {
            // 分类 + 标签 + 已完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && task.complete &&
                task.standbyInt1 == categoryId &&
                task.taskContent.localizedStandardContains(tagFilter)
            }
        } else if dateFilter > 0 {
            // 日期 + 已完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && task.complete &&
                task.todoTime >= startTimestamp
            }
        } else if categoryId > 0 {
            // 分类 + 已完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && task.complete &&
                task.standbyInt1 == categoryId
            }
        } else if !tagFilter.isEmpty {
            // 标签 + 已完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && task.complete &&
                task.taskContent.localizedStandardContains(tagFilter)
            }
        } else {
            // 只有已完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && task.complete
            }
        }
    }
    
    
    
    /// 创建未完成筛选 Predicate
    private static func createIncompleteFilterPredicate(
        userId: Int,
        tagFilter: String,
        dateFilter: Int,
        categoryId: Int,
        startTimestamp: Int64
    ) -> Predicate<TDMacSwiftDataListModel> {
        
        // 根据筛选条件组合 Predicate
        if dateFilter > 0 && categoryId > 0 && !tagFilter.isEmpty {
            // 日期 + 分类 + 标签 + 未完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && !task.complete &&
                task.todoTime >= startTimestamp &&
                task.standbyInt1 == categoryId &&
                task.taskContent.localizedStandardContains(tagFilter)
            }
        } else if dateFilter > 0 && categoryId > 0 {
            // 日期 + 分类 + 未完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && !task.complete &&
                task.todoTime >= startTimestamp &&
                task.standbyInt1 == categoryId
            }
        } else if dateFilter > 0 && !tagFilter.isEmpty {
            // 日期 + 标签 + 未完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && !task.complete &&
                task.todoTime >= startTimestamp &&
                task.taskContent.localizedStandardContains(tagFilter)
            }
        } else if categoryId > 0 && !tagFilter.isEmpty {
            // 分类 + 标签 + 未完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && !task.complete &&
                task.standbyInt1 == categoryId &&
                task.taskContent.localizedStandardContains(tagFilter)
            }
        } else if dateFilter > 0 {
            // 日期 + 未完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && !task.complete &&
                task.todoTime >= startTimestamp
            }
        } else if categoryId > 0 {
            // 分类 + 未完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && !task.complete &&
                task.standbyInt1 == categoryId
            }
        } else if !tagFilter.isEmpty {
            // 标签 + 未完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && !task.complete &&
                task.taskContent.localizedStandardContains(tagFilter)
            }
        } else {
            // 只有未完成
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && !task.complete
            }
        }
    }
    
    /// 创建全部筛选 Predicate
    private static func createAllFilterPredicate(
        userId: Int,
        tagFilter: String,
        dateFilter: Int,
        categoryId: Int,
        startTimestamp: Int64
    ) -> Predicate<TDMacSwiftDataListModel> {
        
        // 根据筛选条件组合 Predicate
        if dateFilter > 0 && categoryId > 0 && !tagFilter.isEmpty {
            // 日期 + 分类 + 标签
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                task.todoTime >= startTimestamp &&
                task.standbyInt1 == categoryId &&
                task.taskContent.localizedStandardContains(tagFilter)
            }
        } else if dateFilter > 0 && categoryId > 0 {
            // 日期 + 分类
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                task.todoTime >= startTimestamp &&
                task.standbyInt1 == categoryId
            }
        } else if dateFilter > 0 && !tagFilter.isEmpty {
            // 日期 + 标签
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                task.todoTime >= startTimestamp &&
                task.taskContent.localizedStandardContains(tagFilter)
            }
        } else if categoryId > 0 && !tagFilter.isEmpty {
            // 分类 + 标签
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                task.standbyInt1 == categoryId &&
                task.taskContent.localizedStandardContains(tagFilter)
            }
        } else if dateFilter > 0 {
            // 只有日期
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                task.todoTime >= startTimestamp
            }
        } else if categoryId > 0 {
            // 只有分类
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                task.standbyInt1 == categoryId
            }
        } else if !tagFilter.isEmpty {
            // 只有标签
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete &&
                task.taskContent.localizedStandardContains(tagFilter)
            }
        } else {
            // 只有基础条件
            return #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete
            }
        }
    }
    
    
    
    /// 查询删除的数据（从7天前开始，最多200条）- 返回 FetchDescriptor
    /// 查询条件：userid = 登录用户 Id, delete = true
    /// 排序：按 todoTime 升序，相同 todoTime 按 taskSort 根据设置排序
    /// 数量限制：最多返回200条记录
    static func getDeletedTasksFetchDescriptor() -> FetchDescriptor<TDMacSwiftDataListModel> {
        
        let userId = TDUserManager.shared.userId
        
        // 计算7天前的时间戳
        let sevenDaysAgo = Date().adding(days: -7)
        let startTimestamp = Int64(sevenDaysAgo.startOfDayTimestamp)
        
        // 创建 Predicate：用户ID + 删除状态 + 时间范围
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && task.delete && task.createTime >= startTimestamp
        }
        
        // 排序：按 todoTime 升序，相同 todoTime 按 taskSort 升序
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward), // todoTime 升序
            SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward) // taskSort 升序
        ]
        
        // 创建 FetchDescriptor 并设置数量限制
        var fetchDescriptor = FetchDescriptor(predicate: predicate, sortBy: sortDescriptors)
        fetchDescriptor.fetchLimit = 200 // 最多返回200条记录
        
        return fetchDescriptor
    }
    
    /// 查询无日期未完成的数据
    /// 基础查询条件：userid = 登录用户 Id, todotime = 0, complete = false
    /// 可选查询条件：categoryId > 0 时添加 standbyInt1 = categoryId
    /// 排序逻辑：根据 sortField 和 isAscending 参数决定
    /// - sortField: 0=createTime, 1=taskSort, 2=snowAssess
    /// - isAscending: false=降序, true=升序
    static func getNoDateUncompletedQuery(
        categoryId: Int = 0,
        sortField: Int = 0,
        isAscending: Bool = false
    ) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        
        let userId = TDUserManager.shared.userId
        
        // 创建基础 Predicate
        let predicate: Predicate<TDMacSwiftDataListModel>
        
        if categoryId > 0 {
            // 基础条件 + 分类条件
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && task.todoTime == 0 && !task.complete && task.standbyInt1 == categoryId
            }
        } else {
            // 只有基础条件
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && task.todoTime == 0 && !task.complete
            }
        }
        
        // 根据排序字段和排序方向创建 SortDescriptor
        let sortDescriptors: [SortDescriptor<TDMacSwiftDataListModel>]
        
        switch sortField {
        case 0: // createTime
            sortDescriptors = [
                SortDescriptor(\TDMacSwiftDataListModel.createTime, order: isAscending ? .forward : .reverse)
            ]
        case 1: // taskSort
            sortDescriptors = [
                SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward) // taskSort 升序
            ]
        case 2: // snowAssess
            sortDescriptors = [
                SortDescriptor(\TDMacSwiftDataListModel.snowAssess, order: isAscending ? .forward : .reverse)
            ]
        default: // 默认使用 createTime 降序
            sortDescriptors = [
                SortDescriptor(\TDMacSwiftDataListModel.createTime, order: .reverse)
            ]
        }
        
        return (predicate, sortDescriptors)
    }
    
    /// 根据重复ID查询数据
    /// 基础查询条件：userid = 用户登录 Id, delete = false, standbyStr1 = 传入的重复ID
    /// 可选查询条件：只查询未完成时添加 complete = false
    /// 排序：按 todoTime 升序排序
    static func getDuplicateTasksQuery(
        standbyStr1: String,
        onlyUncompleted: Bool = false
    ) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        
        let userId = TDUserManager.shared.userId
        
        // 创建 Predicate
        let predicate: Predicate<TDMacSwiftDataListModel>
        
        if onlyUncompleted {
            // 基础条件 + 未完成条件
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && task.standbyStr1 == standbyStr1 && !task.complete
            }
        } else {
            // 只有基础条件
            predicate = #Predicate<TDMacSwiftDataListModel> { task in
                task.userId == userId && !task.delete && task.standbyStr1 == standbyStr1
            }
        }
        
        // 排序：按 todoTime 升序
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward)
        ]
        
        return (predicate, sortDescriptors)
    }
    
    /// 查询重复ID不为空且去重的数据
    /// 基础查询条件：userid = 登录用户 Id, delete = false, standbyStr1 不为空
    /// 去重逻辑：相同的 standbyStr1 只返回一个
    /// 排序：按 todoTime 升序排序
    /// 注意：去重需要在应用层处理，这里只提供基础查询
    static func getUniqueDuplicateIdsQuery() -> FetchDescriptor<TDMacSwiftDataListModel> {
        
        let userId = TDUserManager.shared.userId
        
        // 创建 Predicate：用户ID + 未删除 + standbyStr1 不为空
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && !task.delete && task.standbyStr1 != nil && task.standbyStr1 != ""
        }
        
        // 排序：按 todoTime 升序
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.todoTime, order: .forward)
        ]
        
        // 创建 FetchDescriptor
        let fetchDescriptor = FetchDescriptor(predicate: predicate, sortBy: sortDescriptors)
        
        return fetchDescriptor
    }
    
    /// 查询指定日期的最大 taskSort 值
    /// 基础查询条件：userid = 登录用户 Id, delete = false, todoTime = 传入的时间戳
    /// 排序：按 taskSort 降序，取第一个（最大值）
    /// - Parameter todoTime: 日期时间戳
    /// - Returns: 查询条件和排序描述符
    static func getMaxTaskSortForDateQuery(_ todoTime: Int64) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        
        let userId = TDUserManager.shared.userId
        
        // 创建 Predicate：用户ID + 未删除 + 指定日期
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && !task.delete && task.todoTime == todoTime
        }
        
        // 排序：按 taskSort 降序（最大值在前）
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .reverse)
        ]
        
        return (predicate, sortDescriptors)
    }
    
    /// 查询指定日期的最小 taskSort 值
    /// 基础查询条件：userid = 登录用户 Id, delete = false, todoTime = 传入的时间戳
    /// 排序：按 taskSort 升序，取第一个（最小值）
    /// - Parameter todoTime: 日期时间戳
    /// - Returns: 查询条件和排序描述符
    static func getMinTaskSortForDateQuery(_ todoTime: Int64) -> (Predicate<TDMacSwiftDataListModel>, [SortDescriptor<TDMacSwiftDataListModel>]) {
        
        let userId = TDUserManager.shared.userId
        
        // 创建 Predicate：用户ID + 未删除 + 指定日期
        let predicate = #Predicate<TDMacSwiftDataListModel> { task in
            task.userId == userId && !task.delete && task.todoTime == todoTime
        }
        
        // 排序：按 taskSort 升序（最小值在前）
        let sortDescriptors = [
            SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)
        ]
        
        return (predicate, sortDescriptors)
    }
    
    
    
}
