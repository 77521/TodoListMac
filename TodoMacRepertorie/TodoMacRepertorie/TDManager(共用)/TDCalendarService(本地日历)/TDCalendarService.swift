//
//  TDCalendarService.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

//import Foundation
//import EventKit
//import Foundation
//import SwiftUI
//
//
//enum TDCalendarServiceError: LocalizedError {
//    case noCalendarAccess
//    case noCalendarSource
//    case cannotCreateCalendar
//    
//    var errorDescription: String? {
//        switch self {
//        case .noCalendarAccess:
//            return "未获得日历访问权限"
//        case .noCalendarSource:
//            return "无法获取本地日历源"
//        case .cannotCreateCalendar:
//            return "无法创建日历"
//        }
//    }
//}

//class TDCalendarService {
//    static let shared = TDCalendarService()
//    
//    private let eventStore = EKEventStore()
//    private var hasFullAccess = false
//    private let calendarIdentifier = "TodoSystemCalendarIdentifier"
//    private let calendarTitle = "TodoList"
//    
//    private init() {}
//    
//    /// 检查日历权限
//    func checkCalendarPermission() async -> Bool {
//        // 如果已经有完全访问权限，直接返回
//        if hasFullAccess {
//            return true
//        }
//        
//        // 检查权限状态
//        let status = EKEventStore.authorizationStatus(for: .event)
//        
//        switch status {
//        case .authorized:
//            hasFullAccess = true
//            return true
//            
//        case .notDetermined:
//            // 请求权限
//            do {
//                print("开始请求日历权限...")
//                hasFullAccess = try await eventStore.requestFullAccessToEvents()
//                print("日历权限请求结果: \(hasFullAccess)")
//                return hasFullAccess
//            } catch {
//                print("请求日历权限失败: \(error.localizedDescription)")
//                print("详细错误信息: \(error)")
//                return false
//            }
//            
//        case .restricted:
//            print("日历访问被限制")
//            return false
//            
//        case .denied:
//            print("日历访问被拒绝，请在系统设置中允许访问日历")
//            // 可以在这里添加打开系统设置的代码
//            if let settingsUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendar") {
//                NSWorkspace.shared.open(settingsUrl)
//            }
//            return false
//            
//        case .fullAccess:
//            hasFullAccess = true
//            return true
//            
//        case .writeOnly:
//            print("只有写入权限，需要完全访问权限")
//            return false
//            
//        @unknown default:
//            print("未知的权限状态")
//            return false
//        }
//    }
//    
//    /// 获取或创建待办事项日历
//    /// 获取或创建待办事项日历
//    func getTodoCalendar() throws -> EKCalendar {
//        // 获取所有日历
//        let calendars = eventStore.calendars(for: .event)
//        
//        // 首先在所有日历中查找标题为 "TodoList" 的日历
//        if let existingCalendar = calendars.first(where: { $0.title == calendarTitle }) {
//            print("找到现有的 TodoList 日历")
//            return existingCalendar
//        }
//        
//        print("未找到 TodoList 日历，准备创建新日历...")
//        
//        // 优先使用 iCloud 日历源
//        var calendarSource: EKSource
//        if let iCloudSource = eventStore.sources.first(where: { $0.sourceType == .calDAV && $0.title == "iCloud" }) {
//            print("使用 iCloud 日历源")
//            calendarSource = iCloudSource
//        } else if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
//            print("未找到 iCloud 日历源，使用本地日历源")
//            calendarSource = localSource
//        } else {
//            print("未找到可用的日历源")
//            throw TDCalendarServiceError.noCalendarSource
//        }
//        
//        // 创建新的日历
//        print("开始创建新日历...")
//        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
//        newCalendar.title = calendarTitle
//        newCalendar.source = calendarSource
//        
//        // 保存新日历
//        do {
//            try eventStore.saveCalendar(newCalendar, commit: true)
//            print("成功创建新日历")
//            return newCalendar
//        } catch {
//            print("创建日历失败: \(error)")
//            throw TDCalendarServiceError.cannotCreateCalendar
//        }
//    }
//    /// 处理任务的提醒事件
//    func handleReminderEvent(task: TDMacSwiftDataListModel) async throws {
//            // 检查权限
//            guard await checkCalendarPermission() else {
//                throw TDCalendarServiceError.noCalendarAccess
//            }
//            
//            // 获取当前时间戳（毫秒）
//            let currentTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
//            
//            // 如果任务已删除、已完成、没有提醒时间或提醒时间已过，删除对应的日历事件
//            if task.delete || task.complete || task.reminderTime <= 0 || task.reminderTime < currentTimestamp {
//                print("任务状态检查:")
//                print("- 是否删除: \(task.delete)")
//                print("- 是否完成: \(task.complete)")
//                print("- 提醒时间: \(task.reminderTime)")
//                print("- 当前时间: \(currentTimestamp)")
//                try deleteEvent(for: task)
//                return
//            }
//            
//            // 获取或创建 Todo 日历
//            let calendar = try getTodoCalendar()
//            
//            // 创建或更新事件
//            let event = try getOrCreateEvent(for: task, in: calendar)
//            
//            // 设置事件属性
//            event.title = task.taskContent
//            event.notes = "\(task.taskDescribe ?? "")\nTaskID: \(task.taskId)"
//            
//            // 设置提醒时间
//            let reminderDate = Date(timeIntervalSince1970: TimeInterval(task.reminderTime / 1000))
//            event.startDate = reminderDate
//            event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: reminderDate)
//            
//            // 添加提醒
//            event.addAlarm(EKAlarm(relativeOffset: 0))  // 在事件开始时提醒
//            
//            // 保存事件
//            try eventStore.save(event, span: .thisEvent, commit: true)
//            print("成功创建/更新事件，标题: \(event.title ?? "无标题"), 开始时间: \(event.startDate)")
//        }
//    /// 获取或创建事件
//    func getOrCreateEvent(for task: TDMacSwiftDataListModel, in calendar: EKCalendar) throws -> EKEvent {
//        // 尝试查找现有事件
//        let predicate = eventStore.predicateForEvents(
//            withStart: Date.distantPast,
//            end: Date.distantFuture,
//            calendars: [calendar]
//        )
//        
//        let existingEvents = eventStore.events(matching: predicate)
//        if let event = existingEvents.first(where: { $0.notes?.contains("TaskID: \(task.taskId)") == true }) {
//            return event
//        }
//        
//        // 如果没有找到，创建新事件
//        let event = EKEvent(eventStore: eventStore)
//        event.calendar = calendar
//        event.notes = "\(task.taskDescribe ?? "")\nTaskID: \(task.taskId)"  // 添加 TaskID 用于后续查找
//        return event
//    }
//    
//    /// 删除事件
//    /// 删除事件
//    func deleteEvent(for task: TDMacSwiftDataListModel) throws {
//        print("准备删除任务 \(task.taskId) 的日历事件")
//        
//        // 获取 TodoList 日历
//        let calendars = eventStore.calendars(for: .event)
//        guard let todoCalendar = calendars.first(where: { $0.title == calendarTitle }) else {
//            print("未找到 TodoList 日历，无需删除事件")
//            return
//        }
//        
//        // 查找事件
//        let predicate = eventStore.predicateForEvents(
//            withStart: Date.distantPast,
//            end: Date.distantFuture,
//            calendars: [todoCalendar]
//        )
//        
//        let existingEvents = eventStore.events(matching: predicate)
//        print("找到 \(existingEvents.count) 个事件")
//        
//        var deletedCount = 0
//        for event in existingEvents {
//            if event.notes?.contains("\(task.taskId)") == true {
//                print("找到匹配的事件，标题: \(event.title ?? "无标题")")
//                try eventStore.remove(event, span: .thisEvent, commit: true)
//                deletedCount += 1
//            }
//        }
//        
//        if deletedCount > 0 {
//            print("成功删除 \(deletedCount) 个事件")
//        } else {
//            print("未找到需要删除的事件")
//        }
//    }
//    // 处理提醒事件
//    //    func handleReminderEvent(task: TDMacSwiftDataListModel) async throws {
//    //        // 检查日历权限
//    //        guard await checkCalendarAuthorization() else {
//    //            print("未获得日历完全访问权限")
//    //            return
//    //        }
//    //
//    //        // 获取Todo日历
//    //        let calendar = try getOrCreateTodoCalendar()
//    //
//    //        // 获取当前时间戳（毫秒）
//    //        let currentTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
//    //
//    //        // 查找现有事件
//    //        let predicate = eventStore.predicateForEvents(
//    //            withStart: Date(timeIntervalSince1970: 0),
//    //            end: Date(timeIntervalSinceNow: 365 * 24 * 60 * 60),
//    //            calendars: [calendar]
//    //        )
//    //        let existingEvents = eventStore.events(matching: predicate)
//    //        let existingEvent = existingEvents.first { $0.notes == task.taskId }
//    //
//    //        // 如果任务已删除或已完成，删除对应的日历事件
//    //        if task.delete || task.complete {
//    //            if let event = existingEvent {
//    //                try eventStore.remove(event, span: .thisEvent, commit: true)
//    //            }
//    //            return
//    //        }
//    //
//    //        // 检查提醒时间
//    //        if task.reminderTime <= 0 {
//    //            // 如果没有提醒时间但存在事件，删除事件
//    //            if let event = existingEvent {
//    //                try eventStore.remove(event, span: .thisEvent, commit: true)
//    //            }
//    //            return
//    //        }
//    //
//    //        // 如果提醒时间已过，删除事件
//    //        if task.reminderTime < currentTimestamp {
//    //            if let event = existingEvent {
//    //                try eventStore.remove(event, span: .thisEvent, commit: true)
//    //            }
//    //            return
//    //        }
//    //
//    //        // 创建或更新事件
//    //        let event = existingEvent ?? EKEvent(eventStore: eventStore)
//    //        event.calendar = calendar
//    //        event.title = task.taskContent
//    //        event.notes = task.taskId  // 用于标识对应的任务
//    //        event.startDate = Date(
//    //            timeIntervalSince1970: TimeInterval(task.reminderTime / 1000))
//    //        event.endDate = event.startDate.addingTimeInterval(3600)  // 默认1小时
//    //        event.addAlarm(EKAlarm(absoluteDate: event.startDate))
//    //
//    //        if existingEvent == nil {
//    //            try eventStore.save(event, span: .thisEvent, commit: true)
//    //        } else {
//    //            try eventStore.save(event, span: .thisEvent, commit: true)
//    //        }
//    //    }
//    
//    // 获取本地日历事件
//    func fetchLocalEvents(
//        from startDate: Date, to endDate: Date,
//        excludingCalendarWithIdentifier identifier: String
//    ) async throws -> [EKEvent] {
//        // 获取所有日历，排除指定的日历
//        let calendars = eventStore.calendars(for: .event).filter {
//            $0.source.sourceIdentifier != identifier
//        }
//        
//        // 创建查询谓词
//        let predicate = eventStore.predicateForEvents(
//            withStart: startDate,
//            end: endDate,
//            calendars: calendars
//        )
//        
//        // 获取事件
//        return eventStore.events(matching: predicate)
//    }
//}





//
//  TDCalendarService.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import EventKit
import Foundation
import SwiftUI
import SwiftData

/// 日历服务错误类型
enum TDCalendarServiceError: LocalizedError {
    case noCalendarAccess
    case noCalendarSource
    case cannotCreateCalendar
    
    var errorDescription: String? {
        switch self {
        case .noCalendarAccess:
            return "未获得日历访问权限"
        case .noCalendarSource:
            return "无法获取本地日历源"
        case .cannotCreateCalendar:
            return "无法创建日历"
        }
    }
}

/// 日历服务类，用于管理待办事项的日历事件
@MainActor
final class TDCalendarService {
    /// 单例实例
    static let shared = TDCalendarService()
    
    /// 事件存储器
    private let eventStore = EKEventStore()
    
    /// 是否有完全访问权限
    private var hasFullAccess = false
    
    /// 日历标题
    private let calendarTitle = "TodoList"
    
    /// 用于本地存储日历标识符的键
    private let calendarIdKey = "TodoCalendarIdentifier"
    
    /// 用于本地存储事件标识符的前缀
    private let eventIdPrefix = ""
    
    /// 私有初始化方法
    private init() {}
    
    // MARK: - 本地存储方法
    
    /// 从本地存储获取日历标识符
    private func getSavedCalendarId() -> String? {
        return UserDefaults.standard.string(forKey: calendarIdKey)
    }
    
    /// 保存日历标识符到本地
    private func saveCalendarId(_ identifier: String) {
        UserDefaults.standard.set(identifier, forKey: calendarIdKey)
    }
    
    /// 获取事件标识符的存储键
    private func eventIdKey(for taskId: String) -> String {
        return eventIdPrefix + taskId
    }
    
    /// 保存事件标识符到本地
    private func saveEventId(_ eventId: String, for taskId: String) {
        UserDefaults.standard.set(eventId, forKey: eventIdKey(for: taskId))
    }
    
    /// 获取保存的事件标识符
    private func getSavedEventId(for taskId: String) -> String? {
        return UserDefaults.standard.string(forKey: eventIdKey(for: taskId))
    }
    
    /// 删除保存的事件标识符
    private func removeSavedEventId(for taskId: String) {
        UserDefaults.standard.removeObject(forKey: eventIdKey(for: taskId))
    }
    
    // MARK: - 权限管理
    
    /// 检查日历权限
    func checkCalendarPermission() async -> Bool {
        // 如果已经有完全访问权限，直接返回
        if hasFullAccess {
            return true
        }
        
        // 检查权限状态
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .authorized:
            hasFullAccess = true
            return true
            
        case .notDetermined:
            // 请求权限
            do {
                print("开始请求日历权限...")
                hasFullAccess = try await eventStore.requestFullAccessToEvents()
                print("日历权限请求结果: \(hasFullAccess)")
                return hasFullAccess
            } catch {
                print("请求日历权限失败: \(error.localizedDescription)")
                print("详细错误信息: \(error)")
                return false
            }
            
        case .restricted:
            print("日历访问被限制")
            return false
            
        case .denied:
            print("日历访问被拒绝，请在系统设置中允许访问日历")
            // 打开系统设置
            if let settingsUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendar") {
                NSWorkspace.shared.open(settingsUrl)
            }
            return false
            
        case .fullAccess:
            hasFullAccess = true
            return true
            
        case .writeOnly:
            print("只有写入权限，需要完全访问权限")
            return false
            
        @unknown default:
            print("未知的权限状态")
            return false
        }
    }
    
    /// 初始化时请求权限
    func requestInitialPermission() {
        Task {
            print("正在初始化日历权限...")
            let hasPermission = await checkCalendarPermission()
            print("日历权限状态: \(hasPermission)")
        }
    }
    
    // MARK: - 日历管理
    
    /// 获取或创建待办事项日历
    func getTodoCalendar() throws -> EKCalendar {
        // 首先尝试通过保存的标识符获取日历
        if let savedId = getSavedCalendarId(),
           let calendar = eventStore.calendar(withIdentifier: savedId) {
            print("通过保存的标识符找到日历")
            return calendar
        }
        
        // 如果没有保存的标识符或日历不存在，尝试通过标题查找
        let calendars = eventStore.calendars(for: .event)
        if let existingCalendar = calendars.first(where: { $0.title == calendarTitle }) {
            print("通过标题找到现有的 TodoList 日历")
            saveCalendarId(existingCalendar.calendarIdentifier)
            return existingCalendar
        }
        
        print("未找到 TodoList 日历，准备创建新日历...")
        
        // 优先使用 iCloud 日历源
        var calendarSource: EKSource
        if let iCloudSource = eventStore.sources.first(where: { $0.sourceType == .calDAV && $0.title == "iCloud" }) {
            print("使用 iCloud 日历源")
            calendarSource = iCloudSource
        } else if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            print("未找到 iCloud 日历源，使用本地日历源")
            calendarSource = localSource
        } else {
            print("未找到可用的日历源")
            throw TDCalendarServiceError.noCalendarSource
        }
        
        // 创建新的日历
        print("开始创建新日历...")
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = calendarTitle
        newCalendar.source = calendarSource
        
        // 保存新日历
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            print("成功创建新日历")
            saveCalendarId(newCalendar.calendarIdentifier)
            return newCalendar
        } catch {
            print("创建日历失败: \(error)")
            throw TDCalendarServiceError.cannotCreateCalendar
        }
    }
    
    // MARK: - 事件管理
    
    /// 处理任务的提醒事件
    func handleReminderEvent(task: TDMacSwiftDataListModel) async throws {
        // 检查权限
        guard await checkCalendarPermission() else {
            throw TDCalendarServiceError.noCalendarAccess
        }
        
        // 获取当前时间戳（毫秒）
        let currentTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
        
        // 如果任务已删除、已完成、没有提醒时间或提醒时间已过，删除对应的日历事件
        if task.delete || task.complete || task.reminderTime <= 0 || task.reminderTime < currentTimestamp {
            print("任务状态检查:")
            print("- 是否删除: \(task.delete)")
            print("- 是否完成: \(task.complete)")
            print("- 提醒时间: \(task.reminderTime)")
            print("- 当前时间: \(currentTimestamp)")
            try deleteEvent(for: task)
            return
        }
        
        // 获取或创建 Todo 日历
        let calendar = try getTodoCalendar()

        var event: EKEvent?
        
        // 1. 首先尝试通过保存的标识符获取事件
        if let savedEventId = getSavedEventId(for: task.taskId),
           let existingEvent = eventStore.event(withIdentifier: savedEventId) {
            print("通过保存的标识符找到事件")
            event = existingEvent
        }
        
        // 2. 如果没找到，尝试在同一个日历中搜索相似事件
        if event == nil {
            let reminderDate = Date(timeIntervalSince1970: TimeInterval(task.reminderTime / 1000))
            // 创建一个时间范围，前后5分钟
            let startSearch = Calendar.current.date(byAdding: .minute, value: -5, to: reminderDate) ?? reminderDate
            let endSearch = Calendar.current.date(byAdding: .minute, value: 5, to: reminderDate) ?? reminderDate
            
            let predicate = eventStore.predicateForEvents(
                withStart: startSearch,
                end: endSearch,
                calendars: [calendar]
            )
            
            let existingEvents = eventStore.events(matching: predicate)
            // 查找标题相同且时间接近的事件
            event = existingEvents.first { existingEvent in
                existingEvent.title == task.taskContent &&
                abs(existingEvent.startDate.timeIntervalSince1970 - reminderDate.timeIntervalSince1970) < 300 // 5分钟内
            }
            
            if event != nil {
                print("找到时间和标题匹配的现有事件")
                // 保存找到的事件ID以便后续使用
                if let eventId = event?.eventIdentifier {
                    saveEventId(eventId, for: task.taskId)
                }
            }
        }
        
        // 3. 如果仍然没找到，创建新事件
        if event == nil {
            print("未找到现有事件，创建新事件")
            event = EKEvent(eventStore: eventStore)
            event?.calendar = calendar
        } else {
            print("准备更新现有事件")
        }
        
        guard let event = event else {
            print("事件创建失败")
            return
        }
        // 先删除已存在的事件（如果有）
        try deleteEvent(for: task)

        // 设置事件属性
        event.title = task.taskContent
        event.notes = "\(task.taskDescribe ?? "")\nTaskID: \(task.taskId)"
        
        // 设置提醒时间
        let reminderDate = Date(timeIntervalSince1970: TimeInterval(task.reminderTime / 1000))
        event.startDate = reminderDate
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: reminderDate)
        
        // 添加提醒
        //                event.removeAllAlarms()  // 先移除所有现有的提醒
        event.addAlarm(EKAlarm(relativeOffset: 0))  // 在事件开始时提醒
        
        // 保存事件
        try eventStore.save(event, span: .thisEvent, commit: true)
        
        // 保存事件标识符（如果是新创建的事件）
        if let eventId = event.eventIdentifier {
            saveEventId(eventId, for: task.taskId)
        }
        
        print("成功\(event.eventIdentifier == nil ? "创建" : "更新")事件，标题: \(event.title ?? "无标题"), 开始时间: \(event.startDate)")
    }
    
    /// 获取或创建事件
    private func getOrCreateEvent(for task: TDMacSwiftDataListModel, in calendar: EKCalendar) throws -> EKEvent {
        // 首先尝试通过保存的标识符获取事件
        if let savedEventId = getSavedEventId(for: task.taskId),
           let event = eventStore.event(withIdentifier: savedEventId) {
            print("通过保存的标识符找到事件")
            return event
        }
        
        // 如果没有找到，创建新事件
        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        
        // 设置事件属性
        event.title = task.taskContent
        event.notes = "\(task.taskDescribe ?? "")\nTaskID: \(task.taskId)"
        
        // 设置提醒时间
        let reminderDate = Date(timeIntervalSince1970: TimeInterval(task.reminderTime / 1000))
        event.startDate = reminderDate
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: reminderDate)
        
        // 添加提醒
        event.addAlarm(EKAlarm(relativeOffset: 0))
        
        // 保存事件后记录其标识符
        try eventStore.save(event, span: .thisEvent, commit: true)
        if let eventId = event.eventIdentifier {
            saveEventId(eventId, for: task.taskId)
        }
        
        return event
    }
    
    /// 删除事件
    func deleteEvent(for task: TDMacSwiftDataListModel) throws {
        print("准备删除任务 \(task.taskId) 的日历事件")
        
        // 尝试通过保存的标识符删除事件
        if let event = eventStore.event(withIdentifier: task.taskId) {
            print("找到要删除的事件")
            try eventStore.remove(event, span: .thisEvent, commit: true)
            removeSavedEventId(for: task.taskId)
            print("成功删除事件")
            return
        }
        
        print("未找到保存的事件标识符，尝试通过搜索删除...")
        
        // 如果没有保存的标识符，回退到搜索方式
        guard let todoCalendar = try? getTodoCalendar() else {
            print("未找到 TodoList 日历")
            return
        }
        
        let predicate = eventStore.predicateForEvents(
            withStart: Date.distantPast,
            end: Date.distantFuture,
            calendars: [todoCalendar]
        )
        
        let existingEvents = eventStore.events(matching: predicate)
        for event in existingEvents {
            if event.notes?.contains("TaskID: \(task.taskId)") == true {
                try eventStore.remove(event, span: .thisEvent, commit: true)
                print("通过搜索找到并删除了事件")
                return
            }
        }
        
        print("未找到需要删除的事件")
    }
    
    // MARK: - 清理方法
    
    /// 清理所有日历数据（用于退出登录时）
    func cleanupCalendarData() async throws {
        print("开始清理日历数据...")
        
        // 检查权限
        guard await checkCalendarPermission() else {
            throw TDCalendarServiceError.noCalendarAccess
        }
        
        // 尝试获取保存的日历
        if let savedId = getSavedCalendarId(),
           let calendar = eventStore.calendar(withIdentifier: savedId) {
            print("找到保存的日历，准备删除所有事件...")
            
            // 获取该日历下的所有事件
            let predicate = eventStore.predicateForEvents(
                withStart: Date.distantPast,
                end: Date.distantFuture,
                calendars: [calendar]
            )
            
            let existingEvents = eventStore.events(matching: predicate)
            print("找到 \(existingEvents.count) 个事件")
            
            // 删除所有事件
            for event in existingEvents {
                try eventStore.remove(event, span: .thisEvent, commit: false)
            }
            
            // 删除日历本身
            try eventStore.removeCalendar(calendar, commit: true)
            print("成功删除日历及其所有事件")
            
            // 清理本地存储的标识符
            UserDefaults.standard.removeObject(forKey: calendarIdKey)
            
            // 清理所有事件标识符
            let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
            for key in allKeys where key.hasPrefix(eventIdPrefix) {
                UserDefaults.standard.removeObject(forKey: key)
            }
            
            print("已清理所有本地存储的标识符")
        } else {
            print("未找到保存的日历，无需清理")
        }
        
        // 重置权限状态
        hasFullAccess = false
        print("日历数据清理完成")
    }
    
    // MARK: - 本地日历查询
    
    /// 获取本地日历事件（排除 TodoList 日历）
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    ///   - includeDeclinedEvents: 是否包含已拒绝的事件，默认为 false
    /// - Returns: 转换后的任务模型数组
    func fetchLocalEvents(
        from startDate: Date,
        to endDate: Date,
        includeDeclinedEvents: Bool = false
    ) async throws -> [TDMacSwiftDataListModel] {
        print("开始获取本地日历事件...")
        print("时间范围: \(startDate) 到 \(endDate)")
        
        // 检查权限
        guard await checkCalendarPermission() else {
            throw TDCalendarServiceError.noCalendarAccess
        }
        
        // 获取 TodoList 日历的标识符
        let todoCalendarId = getSavedCalendarId()
        
        // 获取所有日历，排除 TodoList 日历
        let calendars = eventStore.calendars(for: .event).filter { calendar in
            // 如果有 TodoList 日历标识符，排除它
            if let todoId = todoCalendarId {
                return calendar.calendarIdentifier != todoId
            }
            // 如果没有标识符，通过标题排除
            return calendar.title != calendarTitle
        }
        
        print("找到 \(calendars.count) 个其他日历")
        
        // 创建查询谓词
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )
        
        // 获取事件
        let allEvents = eventStore.events(matching: predicate)
        
        // 转换事件为任务模型
        var tasks: [TDMacSwiftDataListModel] = []
        for event in allEvents {
            // 如果不包含已拒绝的事件且事件被取消，则跳过
            if !includeDeclinedEvents && event.status == .canceled {
                continue
            }
            
            // 创建任务模型
//            let tempContext = ModelContext(TDModelContainer.shared.modelContainer)
            let task = TDMacSwiftDataListModel(backingData: ModelContext(TDModelContainer.shared.modelContainer) as! any BackingData<TDMacSwiftDataListModel>)

            // 设置基本属性
            task.taskContent = event.title ?? ""
            task.taskDescribe = event.notes ?? ""
            task.standbyIntName = event.calendar.title
            
            // 将日历颜色转换为字符串保存
            if let calendarColor = event.calendar.cgColor {
                let color = Color(cgColor: calendarColor)
                task.standbyIntColor = color.toHexString()
            }
            
            // 设置时间相关属性
            task.createTime = Int64(event.startDate.timeIntervalSince1970 * 1000)
            task.reminderTime = Int64(event.startDate.timeIntervalSince1970 * 1000)
            
            // 设置其他必要属性
            task.taskId = event.eventIdentifier ?? UUID().uuidString
            task.complete = false
            task.delete = false
            
            // 设置是否为系统日历数据的标识（运行时属性，不保存到数据库）
            task.isSystemCalendarEvent = true
            
            tasks.append(task)
        }
        
        print("找到并转换了 \(tasks.count) 个系统日历事件")
        
        return tasks
    }

    /// 获取指定日期范围内的所有本地日历事件的统计信息
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 日历事件统计信息
//    func fetchLocalEventsStatistics(
//        from startDate: Date,
//        to endDate: Date
//    ) async throws -> [String: Any] {
//        let events = try await fetchLocalEvents(from: startDate, to: endDate)
//        
//        var statistics: [String: Any] = [:]
//        
//        // 按日历分组的事件数量
//        var eventsByCalendar: [String: Int] = [:]
//        // 按时间段分组的事件数量（上午/下午/晚上）
//        var eventsByTimeSlot: [String: Int] = [
//            "morning": 0,   // 5:00-12:00
//            "afternoon": 0, // 12:00-18:00
//            "evening": 0    // 18:00-次日5:00
//        ]
//        
//        for event in events {
//            // 统计每个日历的事件数量
//            let calendarTitle = event.calendar.title
//            eventsByCalendar[calendarTitle, default: 0] += 1
//            
//            // 统计不同时间段的事件数量
//            let hour = Calendar.current.component(.hour, from: event.startDate)
//            switch hour {
//            case 5..<12:
//                eventsByTimeSlot["morning"]! += 1
//            case 12..<18:
//                eventsByTimeSlot["afternoon"]! += 1
//            default:
//                eventsByTimeSlot["evening"]! += 1
//            }
//        }
//        
//        statistics["total_events"] = events.count
//        statistics["events_by_calendar"] = eventsByCalendar
//        statistics["events_by_time_slot"] = eventsByTimeSlot
//        
//        return statistics
//    }
    
}
