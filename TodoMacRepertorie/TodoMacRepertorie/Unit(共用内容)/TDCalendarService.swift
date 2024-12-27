//
//  TDCalendarService.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/26.
//

import AppKit
import EventKit
import Foundation

class TDCalendarService {
    static let shared = TDCalendarService()
    private let eventStore = EKEventStore()
    private let calendarIdentifier = "TodoSystemCalendarIdentifier"

    private init() {}

    // 检查日历权限
    func checkCalendarAuthorization() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .authorized:
            return true
        case .notDetermined:
            do {
                // 请求日历权限
                return try await eventStore.requestFullAccessToEvents()
            } catch {
                print("请求日历权限失败: \(error)")
                return false
            }
        default:
            return false
        }
    }

    // 获取或创建Todo日历源
    private func getOrCreateTodoCalendar() throws -> EKCalendar {
        // 查找现有的Todo日历
        if let existingCalendar = eventStore.calendars(for: .event).first(
            where: { $0.source.sourceIdentifier == calendarIdentifier })
        {
            return existingCalendar
        }

        // 创建新的日历
        guard
            let localSource = eventStore.sources.first(where: {
                $0.sourceType == .local
            })
        else {
            throw NSError(
                domain: "TDCalendarService", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "无法获取本地日历源"])
        }

        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.source = localSource
        calendar.title = "TodoList"
        calendar.cgColor = NSColor.systemBlue.cgColor

        try eventStore.saveCalendar(calendar, commit: true)
        return calendar
    }

    // 处理提醒事件
    func handleReminderEvent(task: TDMacSwiftDataListModel) async throws {
        // 检查日历权限
        guard await checkCalendarAuthorization() else {
            print("未获得日历完全访问权限")
            return
        }

        // 获取Todo日历
        let calendar = try getOrCreateTodoCalendar()

        // 获取当前时间戳（毫秒）
        let currentTimestamp = Int64(Date().timeIntervalSince1970 * 1000)

        // 查找现有事件
        let predicate = eventStore.predicateForEvents(
            withStart: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSinceNow: 365 * 24 * 60 * 60),
            calendars: [calendar]
        )
        let existingEvents = eventStore.events(matching: predicate)
        let existingEvent = existingEvents.first { $0.notes == task.taskId }

        // 如果任务已删除或已完成，删除对应的日历事件
        if task.delete || task.complete {
            if let event = existingEvent {
                try eventStore.remove(event, span: .thisEvent, commit: true)
            }
            return
        }

        // 检查提醒时间
        guard let reminderTime = task.reminderTime, reminderTime > 0 else {
            // 如果没有提醒时间但存在事件，删除事件
            if let event = existingEvent {
                try eventStore.remove(event, span: .thisEvent, commit: true)
            }
            return
        }

        // 如果提醒时间已过，删除事件
        if reminderTime < currentTimestamp {
            if let event = existingEvent {
                try eventStore.remove(event, span: .thisEvent, commit: true)
            }
            return
        }

        // 创建或更新事件
        let event = existingEvent ?? EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = task.taskContent
        event.notes = task.taskId  // 用于标识对应的任务
        event.startDate = Date(
            timeIntervalSince1970: TimeInterval(reminderTime / 1000))
        event.endDate = event.startDate.addingTimeInterval(3600)  // 默认1小时
        event.addAlarm(EKAlarm(absoluteDate: event.startDate))

        if existingEvent == nil {
            try eventStore.save(event, span: .thisEvent, commit: true)
        } else {
            try eventStore.save(event, span: .thisEvent, commit: true)
        }
    }

    // 获取本地日历事件
    func fetchLocalEvents(
        from startDate: Date, to endDate: Date,
        excludingCalendarWithIdentifier identifier: String
    ) throws -> [EKEvent] {
        // 获取所有日历，排除指定的日历
        let calendars = eventStore.calendars(for: .event).filter {
            $0.source.sourceIdentifier != identifier
        }
        
        // 创建查询谓词
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )
        
        // 获取事件
        return eventStore.events(matching: predicate)
    }
}
