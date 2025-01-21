////
////  TDMacTaskService.swift
////  TodoMacRepertorie
////
////  Created by 孬孬 on 2024/12/28.
////
//
//import Foundation
//import SwiftData
//import HandyJSON
//import SwiftUI
//import EventKit
//
//@MainActor
//class TDMacTaskService {
//    static let shared = TDMacTaskService(modelContainer: TDModelContainer.shared)
//    private let modelContext: ModelContext
//    private let calendarService: TDCalendarService
//    private var isLoading = false
//    private let userId = TDUserManager.shared.userId ?? 0
//    private let predicateBuilder: TDMacTaskPredicateBuilder
//    private let modelContainer: TDModelContainer
//
//    init(modelContainer: TDModelContainer) {
//        self.modelContainer = modelContainer
//        self.modelContext = TDModelContainer.shared.mainContext
//        self.calendarService = TDCalendarService.shared
//        self.predicateBuilder = TDMacTaskPredicateBuilder()
//    }
//       
//    // MARK: - 同步相关方法
//    
//    /// 同步任务数据
//    func syncTasks() async throws {
//        let userId = userId
//        let isFirst = TDUserSyncManager.shared.isFirstSync(userId: userId)
//        
//        // 检查日历权限（首次同步时）
//        if !isLoading {
//            isLoading = true
//            _ = await TDCalendarService.shared.checkCalendarAuthorization()
//        }
//        
//        // 1. 先获取最新的清单数据
//        let categories = try await TDCategoryAPI.getCategories()
//        
//        // 2. 获取服务器最大版本号
//        let serverMaxVersion = try await TDTaskAPI.fetchServerMaxVersion()
//        
//        // 3. 获取本地最大版本号
//        let localMaxVersion = try getLocalMaxVersion()
//        
//        // 4. 比较版本号
//        if serverMaxVersion > localMaxVersion {
//            // 5. 从服务器获取新数据
////            let jsonTasks = try await TDTaskAPI.getTasks(isFirst: isFirst, syncNum: Int(serverMaxVersion - localMaxVersion))
//            let jsonTasks = [TDMacHandyJsonListModel]()
//            // 6. 更新本地数据
//            for jsonTask in jsonTasks {
//                // 转换为 SwiftData 模型
//                let task = jsonTask.toSwiftDataModel()
//                
//                // 检查本地是否存在此任务
//                if let existingTask = try findLocalTask(by: task.taskId ?? "") {
//                    // 比较 syncTime
//                    let existingSyncTime = existingTask.syncTime ?? 0
//                    let newSyncTime = task.syncTime ?? 0
//                    
//                    if newSyncTime > existingSyncTime {
//                        // 从最新获取的清单数据中查找对应的清单信息
//                        if let categoryId = task.standbyInt1,
//                           let category = categories.first(where: { $0.categoryId == categoryId }) {
//                            task.standbyIntColor = category.categoryColor
//                            task.standbyIntName = category.categoryName
//                        }
//                        
//                        // 更新本地数据
//                        updateLocalTask(existingTask, with: task)
//                        
//                        // 处理日历提醒事件
//                        try await TDCalendarService.shared.handleReminderEvent(task: existingTask)
//                    }
//                } else {
//                    // 从最新获取的清单数据中查找对应的清单信息
//                    if let categoryId = task.standbyInt1,
//                       let category = categories.first(where: { $0.categoryId == categoryId }) {
//                        task.standbyIntColor = category.categoryColor
//                        task.standbyIntName = category.categoryName
//                    }
//                    
//                    // 插入新任务
//                    modelContext.insert(task)
//                    
//                    // 处理日历提醒事件
//                    try await TDCalendarService.shared.handleReminderEvent(task: task)
//                }
//            }
//            
//            // 7. 保存更改
//            try TDModelContainer.shared.save()
//            
//            // 8. 如果是首次同步，标记为已完成
//            if isFirst {
//                TDUserSyncManager.shared.markSyncCompleted(userId: userId)
//            }
//        }
//        
//        // 9. 获取所有未同步的本地数据
//        let unsyncedTasks = try await fetchLocalTasksNeedSync()
//        
//        // 10. 如果有未同步的数据，转换为 HandyJSON 模型并上传到服务器
//        if !unsyncedTasks.isEmpty {
//            // 转换为 HandyJSON 模型
//            let jsonTasks = unsyncedTasks.map { $0.toHandyJSONModel() }
//            
//            // 11. 上传到服务器并获取更新后的数据
//            let updatedTasks = try await TDTaskAPI.syncTasks(tasks: jsonTasks)
//            
//            // 12. 更新本地数据
//            for jsonTask in updatedTasks {
//                let task = jsonTask.toSwiftDataModel()
//                if let existingTask = try findLocalTask(by: task.taskId ?? "") {
//                    updateLocalTask(existingTask, with: task)
//                } else {
//                    modelContext.insert(task)
//                }
//            }
//            
//            // 13. 保存更改
//            try TDModelContainer.shared.save()
//            
//            // 14. 更新日历事件
//            await updateCalendarEvents(for: try modelContext.fetch(FetchDescriptor<TDMacSwiftDataListModel>()))
//        }
//        
//        isLoading = false
//    }
//
//    // MARK: - 查询方法
//    
//    /// 根据侧边栏类型获取任务列表
//    func fetchTasks(categoryId: Int) async throws -> [TDMacTaskGroup: [TDMacSwiftDataListModel]] {
//        switch categoryId {
//        case -100: // DayTodo
//            // 今日待办不需要分组，直接返回今天的任务
//            let tasks = try await fetchTasksForDate(Date())
//            return [.today: tasks]
//
//        case -101: // 最近待办或自定义清单
//            // 这两种情况需要完整的分组逻辑
//            return try await fetchRecentTasks(categoryId: categoryId)
//        case let id where id >= 0:
//            // 自定义清单
//            return try await fetchRecentTasks(categoryId: categoryId)
//
//        case -103: // 无日期任务
//            // 无日期任务单独处理，不需要分组
//            return try await fetchNoDateTasks()
//            
//        case -107: // 最近已完成
//            // 最近已完成任务不需要分组
//            return try await fetchRecentCompletedTasks()
//            
//        case -108: // 回收站
//            // 回收站任务不需要分组
//            return try await fetchRecycleBinTasks()
//
//        default:
//            return [:]
//        }
//    }
//    
//    /// 获取指定日期的任务列表
//    private func fetchTasksForDate(_ date: Date) async throws -> [TDMacSwiftDataListModel] {
//        // 将日期转换为时间戳（毫秒）
//        let timestamp = Int64(date.timeIntervalSince1970 * 1000)
//        
//        // 构建查询条件
//        let predicate = predicateBuilder.buildDatePredicate(
//            timestamp: timestamp,
//            showFinishData: TDSettingManager.shared.isShowFinishData
//        )
//        
//        // 获取任务数据
//        let descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
//            predicate: predicate,
//            sortBy: TDMacTaskPredicateBuilder.getDefaultSortDescriptors(isTop: TDSettingManager.shared.isTop)
//        )
//        
//        var tasks = try modelContext.fetch(descriptor)
//        
//        // 如果需要显示本地日历事件
//        if TDSettingManager.shared.isSubscription {
//            if await TDCalendarService.shared.checkCalendarAuthorization() {
//                // 获取本地日历事件
//                let calendarEvents = try await fetchLocalCalendarEvents(for: date)
//                
//                // 将日历事件转换为任务模型并插入到适当位置
//                let calendarTasks = calendarEvents.map { event in
//                    convertEventToTask(event, userId: userId, date: date)
//                }
//                
//                // 根据完成状态分组任务
//                let uncompletedTasks = tasks.filter { !$0.complete }
//                let completedTasks = tasks.filter { $0.complete }
//                
//                // 重新组合任务列表：未完成任务 -> 日历事件 -> 已完成任务
//                tasks = uncompletedTasks + calendarTasks + completedTasks
//            }
//        }
//
//        return tasks
//    }
//    
//    /// 获取本地日历事件
//    private func fetchLocalCalendarEvents(for date: Date) async throws -> [EKEvent] {
//        let calendar = Calendar.current
//        let startOfDay = calendar.startOfDay(for: date)
//        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
//        
//        return try await TDCalendarService.shared.fetchLocalEvents(
//            from: startOfDay,
//            to: endOfDay,
//            excludingCalendarWithIdentifier: TDCalendarService.shared.calendarIdentifier
//        )
//    }
//    
//    /// 将日历事件转换为任务模型
//    private func convertEventToTask(_ event: EKEvent, userId: Int, date: Date) -> TDMacSwiftDataListModel {
//        let task = TDMacSwiftDataListModel(
//            userId: userId,
//            taskId: "calendar_\(event.eventIdentifier ?? UUID().uuidString)",
//            createTime: Int64(event.creationDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970) * 1000,
//            status: "local",
//            taskSort: 0.0,
//            todoTime: Int64(date.timeIntervalSince1970 * 1000),
//            complete: false,
//            taskContent: event.title ?? "",
//            taskDescribe: event.notes
//        )
//        
//        // 标记为系统日历事件
//        task.isSystemCalendarData = true
//        
//        return task
//    }
//    
//    /// 获取最近待办或自定义清单任务
//    private func fetchRecentTasks(categoryId: Int) async throws -> [TDMacTaskGroup: [TDMacSwiftDataListModel]] {
//        var result: [TDMacTaskGroup: [TDMacSwiftDataListModel]] = [:]
//        let calendar = Calendar.current
//        let today = calendar.startOfDay(for: Date())
//        
//        // 1. 获取已过期已完成任务
//        let expiredRangeCompleted = TDSettingManager.shared.expiredRangeCompleted
//        if expiredRangeCompleted > 0 {
//            let expiredStart = calendar.date(byAdding: .day, value: -expiredRangeCompleted, to: today)!
//            let expiredStartTimestamp = Int64(expiredStart.timeIntervalSince1970 * 1000)
//            let todayTimestamp = Int64(today.timeIntervalSince1970 * 1000)
//            
//            let predicate = predicateBuilder.buildExpiredCompletedPredicate(
//                startTimestamp: expiredStartTimestamp,
//                endTimestamp: todayTimestamp
//            )
//            
//            let descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
//                predicate: predicate,
//                sortBy: TDMacTaskPredicateBuilder.getTimeBasedSortDescriptors(isTop: TDSettingManager.shared.isTop)
//            )
//            let expiredCompletedTasks = try modelContext.fetch(descriptor)
//            if !expiredCompletedTasks.isEmpty {
//                result[.expiredCompleted] = expiredCompletedTasks
//            }
//        }
//        
//        
//        // 2. 获取已过期未完成任务
//        let expiredRangeUncompleted = TDSettingManager.shared.expiredRangeUncompleted
//        if expiredRangeUncompleted > 0 {
//            let expiredStart = calendar.date(byAdding: .day, value: -expiredRangeUncompleted, to: today)!
//            let expiredStartTimestamp = Int64(expiredStart.timeIntervalSince1970 * 1000)
//            let todayTimestamp = Int64(today.timeIntervalSince1970 * 1000)
//            
//            let predicate = predicateBuilder.buildExpiredUncompletedPredicate(
//                startTimestamp: expiredStartTimestamp,
//                endTimestamp: todayTimestamp
//            )
//            
//            let descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
//                predicate: predicate,
//                sortBy: TDMacTaskPredicateBuilder.getTimeBasedSortDescriptors(isTop: TDSettingManager.shared.isTop)
//            )
//            let expiredUncompletedTasks = try modelContext.fetch(descriptor)
//            if !expiredUncompletedTasks.isEmpty {
//                result[.expiredUncompleted] = expiredUncompletedTasks
//            }
//        }
//
//        // 3. 获取今天、明天、后天的任务
//        for daysOffset in 0...2 {
//            let targetDate = calendar.date(byAdding: .day, value: daysOffset, to: today)!
//            let targetTimestamp = Int64(targetDate.timeIntervalSince1970 * 1000)
//            
//            let predicate = predicateBuilder.buildDatePredicate(
//                timestamp: targetTimestamp,
//                showFinishData: TDSettingManager.shared.isShowFinishData
//            )
//            
//            let descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
//                predicate: predicate,
//                sortBy: TDMacTaskPredicateBuilder.getDefaultSortDescriptors(isTop: TDSettingManager.shared.isTop)
//            )
//            var tasks = try modelContext.fetch(descriptor)
//            
//            // 根据完成状态分组任务
//            let uncompletedTasks = tasks.filter { !$0.complete }
//            let completedTasks = tasks.filter { $0.complete }
//            
//            // 重新组合任务列表：未完成任务 -> 已完成任务
//            tasks = uncompletedTasks + completedTasks
//            
//            if !tasks.isEmpty {
//                let group: TDMacTaskGroup = daysOffset == 0 ? .today :
//                daysOffset == 1 ? .tomorrow : .afterTomorrow
//                result[group] = tasks
//            }
//        }
//        
//        // 4. 获取后续日程
//        let afterTomorrowDate = calendar.date(byAdding: .day, value: 3, to: today)!
//        let afterTomorrowTimestamp = Int64(afterTomorrowDate.timeIntervalSince1970 * 1000)
//        
//        let futurePredicate = predicateBuilder.buildFuturePredicate(
//            afterTimestamp: afterTomorrowTimestamp,
//            showFinishData: TDSettingManager.shared.isShowFinishData
//        )
//        
//        let futureTasks = try modelContext.fetch(FetchDescriptor<TDMacSwiftDataListModel>(
//            predicate: futurePredicate,
//            sortBy: TDMacTaskPredicateBuilder.getTimeBasedSortDescriptors(isTop: TDSettingManager.shared.isTop)
//        ))
//        
//        if !futureTasks.isEmpty {
//            var processedTasks = futureTasks
//            let repeatNum = TDSettingManager.shared.repeatNum
//
//            if repeatNum  > 0 {
//                // 按 standbyStr1 分组
//                var groupedTasks: [String: [TDMacSwiftDataListModel]] = [:]
//                for task in futureTasks {
//                    if let repeatId = task.standbyStr1 {
//                        groupedTasks[repeatId, default: []].append(task)
//                    }
//                }
//                
//                // 限制每组的数量
//                processedTasks = futureTasks.filter { task in
//                    if let repeatId = task.standbyStr1,
//                       let group = groupedTasks[repeatId] {
//                        return group.firstIndex(where: { $0.taskId == task.taskId })! < repeatNum
//                    }
//                    return true
//                }
//            }
//            
//            // 根据完成状态分组任务
//            let uncompletedTasks = processedTasks.filter { !$0.complete }
//            let completedTasks = processedTasks.filter { $0.complete }
//            
//            // 重新组合任务列表：未完成任务 -> 已完成任务
//            result[.future] = uncompletedTasks + completedTasks
//        }
//        
//        // 5. 获取无日期任务（只在最近待办和自定义清单时显示）
//        if (categoryId == -101 || categoryId >= 0) && TDSettingManager.shared.isShowNoDateData {
//            let noDatePredicate = predicateBuilder.buildNoDatePredicate(
//                showFinishData: TDSettingManager.shared.isShowNoDateFinishData
//            )
//            
//            let noDateTasks = try modelContext.fetch(FetchDescriptor<TDMacSwiftDataListModel>(
//                predicate: noDatePredicate,
//                sortBy: TDMacTaskPredicateBuilder.getDefaultSortDescriptors(isTop: TDSettingManager.shared.isTop)
//            ))
//            
//            if !noDateTasks.isEmpty {
//                // 根据完成状态分组任务
//                let uncompletedTasks = noDateTasks.filter { !$0.complete }
//                let completedTasks = noDateTasks.filter { $0.complete }
//                
//                // 重新组合任务列表：未完成任务 -> 已完成任务
//                result[.noDate] = uncompletedTasks + completedTasks
//            }
//        }
//
//        return result
//    }
//    
//    /// 获取无日期任务
//    private func fetchNoDateTasks() async throws -> [TDMacTaskGroup: [TDMacSwiftDataListModel]] {
//        let predicate = predicateBuilder.buildNoDateTasksPredicate(
//            categoryId: TDSettingManager.shared.noDateCategoryId
//        )
//        
//        let sortDescriptors = TDMacTaskPredicateBuilder.getNoDateSortDescriptors(
//            sortState: TDSettingManager.shared.noDateSortState,
//            isReverse: TDSettingManager.shared.noDateSort
//        )
//        
//        let descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
//            predicate: predicate,
//            sortBy: sortDescriptors
//        )
//        
//        let tasks = try modelContext.fetch(descriptor)
//        return [.noDate: tasks]
//    }
//    
//    /// 获取最近已完成任务
//    private func fetchRecentCompletedTasks() async throws -> [TDMacTaskGroup: [TDMacSwiftDataListModel]] {
//        let calendar = Calendar.current
//        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: Date()))!
//        let thirtyDaysAgoTimestamp = Int64(thirtyDaysAgo.timeIntervalSince1970 * 1000)
//        
//        let predicate = predicateBuilder.buildRecentCompletedPredicate(
//            startTimestamp: thirtyDaysAgoTimestamp
//        )
//        
//        var descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
//            predicate: predicate,
//            sortBy: TDMacTaskPredicateBuilder.getTimeBasedSortDescriptors(isTop: false)
//        )
//        descriptor.fetchLimit = 300
//        
//        let tasks = try modelContext.fetch(descriptor)
//        return [.today: tasks]
//    }
//    /// 获取回收站任务
//    private func fetchRecycleBinTasks() async throws -> [TDMacTaskGroup: [TDMacSwiftDataListModel]] {
//        let calendar = Calendar.current
//        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: Date()))!
//        let thirtyDaysAgoTimestamp = Int64(thirtyDaysAgo.timeIntervalSince1970 * 1000)
//        
//        let predicate = predicateBuilder.buildRecycleBinPredicate(
//            startTimestamp: thirtyDaysAgoTimestamp
//        )
//        
//        var descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
//            predicate: predicate,
//            sortBy: TDMacTaskPredicateBuilder.getTimeBasedSortDescriptors(isTop: false)
//        )
//        descriptor.fetchLimit = 300
//        
//        let tasks = try modelContext.fetch(descriptor)
//        return [.today: tasks]
//    }
//
//    /// 获取本地已同步的最大版本号
//    private func getLocalMaxVersion() throws -> Int64 {
//        var descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
//            predicate: predicateBuilder.buildSyncedTasksPredicate(),
//            sortBy: [SortDescriptor(\.version, order: .reverse)]
//        )
//        descriptor.fetchLimit = 1
//        let tasks = try modelContext.fetch(descriptor)
//        return tasks.first?.version ?? 0
//    }
//
//    // MARK: - 辅助方法
//    
//    /// 获取本地需要同步的任务
//    private func fetchLocalTasksNeedSync() async throws -> [TDMacSwiftDataListModel] {
////        let descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
////            predicate: predicateBuilder.buildNeedSyncPredicate()
////        )
////        return try modelContext.fetch(descriptor)
//        
//        
//        return try await Task.detached {
//            let descriptor = await FetchDescriptor<TDMacSwiftDataListModel>(
//                predicate: self.predicateBuilder.buildNeedSyncPredicate()
//            )
//            
//            // 创建新的上下文用于后台查询
//            let backgroundContext = await self.modelContainer.newContext()
//            return try backgroundContext.fetch(descriptor)
//        }.value
//
//    }
//    
//    /// 查找本地任务
//    private func findLocalTask(by taskId: String) throws -> TDMacSwiftDataListModel? {
//        let descriptor = FetchDescriptor<TDMacSwiftDataListModel>(
//            predicate: predicateBuilder.buildTaskByIdPredicate(taskId: taskId)
//        )
//        return try modelContext.fetch(descriptor).first
//    }
//
//        // 更新任务的所有字段
//    private func updateLocalTask(_ existingTask: TDMacSwiftDataListModel, with newTask: TDMacSwiftDataListModel) {
//        // 更新所有字段
//        existingTask.userId = newTask.userId
//        existingTask.status = newTask.status ?? ""
//        existingTask.taskSort = newTask.taskSort ?? 0.0
//        existingTask.createServerTime = newTask.createServerTime
//        existingTask.version = newTask.version
//        existingTask.syncLocalTime = newTask.syncLocalTime
//        existingTask.syncTime = newTask.syncTime
//        existingTask.todoTime = newTask.todoTime
//        existingTask.complete = newTask.complete
//        existingTask.taskContent = newTask.taskContent ?? ""
//        existingTask.taskDescribe = newTask.taskDescribe
//        existingTask.snowAssess = newTask.snowAssess
//        existingTask.reminderTime = newTask.reminderTime
//        existingTask.standbyStr1 = newTask.standbyStr1
//        existingTask.standbyStr2 = newTask.standbyStr2
//        existingTask.standbyStr3 = newTask.standbyStr3
//        existingTask.standbyStr4 = newTask.standbyStr4
//        existingTask.standbyInt1 = newTask.standbyInt1
//        existingTask.standbyIntColor = newTask.standbyIntColor
//        existingTask.standbyIntName = newTask.standbyIntName
//        existingTask.delete = newTask.delete
//        existingTask.subIsOpen = newTask.subIsOpen
//        
//        existingTask.standbyStr2Arr = newTask.standbyStr2Arr
//        existingTask.standbyStr4Arr = newTask.standbyStr4Arr
//
//    }
//
//    /// 更新日历事件
//    private func updateCalendarEvents(for tasks: [TDMacSwiftDataListModel]) async {
//        for task in tasks {
//            try? await calendarService.handleReminderEvent(task: task)
//        }
//    }
////    
////    // 下载文件
////    func downloadFile(attachment: TDUpLoadFieldModel) async throws {
////        // 如果已经下载过，直接返回
////        if attachment.downloading, let filePath = attachment.filePath {
////            let fileExists = FileManager.default.fileExists(atPath: filePath)
////            if fileExists {
////                return
////            }
////        }
////        
////        // 获取下载目录
////        guard let downloadDir = getDownloadDirectory() else {
////            throw NSError(domain: "TDMacTaskService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法获取下载目录"])
////        }
////        
////        // 创建文件名
////        let fileName = "\(attachment.name).\(attachment.suffix)"
////        let filePath = (downloadDir as NSString).appendingPathComponent(fileName)
////        
////        // 下载文件
////        guard let url = URL(string: attachment.url) else {
////            throw NSError(domain: "TDMacTaskService", code: -2, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])
////        }
////        
////        let (tempURL, _) = try await URLSession.shared.download(from: url)
////        
////        // 移动文件到目标位置
////        try FileManager.default.moveItem(at: tempURL, to: URL(fileURLWithPath: filePath))
////        
////        // 更新附件信息
////        attachment.downloading = true
////        attachment.filePath = filePath
////        
////        // 保存更改
////        try modelContext.save()
////    }
////    
////    // 获取下载目录
////    private func getDownloadDirectory() -> String? {
////        let fileManager = FileManager.default
////        
////        // 获取应用支持目录
////        guard let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
////            return nil
////        }
////        
////        // 创建下载目录
////        let downloadDir = appSupportDir.appendingPathComponent("Downloads")
////        
////        // 如果目录不存在，创建它
////        if !fileManager.fileExists(atPath: downloadDir.path) {
////            do {
////                try fileManager.createDirectory(at: downloadDir, withIntermediateDirectories: true)
////            } catch {
////                return nil
////            }
////        }
////        
////        return downloadDir.path
////    }
////    
////    // 检查文件是否存在
////    func checkFileExists(attachment: TDUpLoadFieldModel) -> Bool {
////        guard let filePath = attachment.filePath else {
////            return false
////        }
////        return FileManager.default.fileExists(atPath: filePath)
////    }
////    
////    // 获取文件URL
////    func getFileURL(attachment: TDUpLoadFieldModel) -> URL? {
////        guard let filePath = attachment.filePath else {
////            return nil
////        }
////        return URL(fileURLWithPath: filePath)
////    }
//
//
//}
