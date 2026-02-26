//
//  TDMacWidgetListModeWidget.swift
//  TDMacWidget
//
//  列表模式小组件：支持 Day Todo / 最近待办 / 分类清单，可配置是否显示已过期
//

import WidgetKit
import SwiftUI
import Foundation
import SwiftData
import AppIntents

private struct TDWidgetUserEntry: TimelineEntry {
    let date: Date
    /// 与 Demo 一致：Entry 必须持有 configuration，系统据此识别为可编辑小组件并弹出编辑界面
    let configuration: TDListTypeConfigurationIntent
    let isLoggedIn: Bool
    let userId: Int
    let userName: String
    /// 当前查看类型标题（Day Todo / 最近待办 / 分类名）
    let viewTitle: String
    let pendingCount: Int
    let firstPendingTitle: String?
    let swiftDataError: String?
}

private struct TDWidgetIntentProvider: AppIntentTimelineProvider {
    typealias Intent = TDListTypeConfigurationIntent

    func placeholder(in context: Context) -> TDWidgetUserEntry {
        TDWidgetUserEntry(
            date: .now,
            configuration: TDListTypeConfigurationIntent(),
            isLoggedIn: false,
            userId: -1,
            userName: "未登录",
            viewTitle: "Day Todo",
            pendingCount: 0,
            firstPendingTitle: nil,
            swiftDataError: nil
        )
    }

    func snapshot(for configuration: TDListTypeConfigurationIntent, in context: Context) async -> TDWidgetUserEntry {
        await entry(for: configuration, family: context.family)
    }

    func timeline(for configuration: TDListTypeConfigurationIntent, in context: Context) async -> Timeline<TDWidgetUserEntry> {
        let entry = await entry(for: configuration, family: context.family)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(15 * 60)
        return Timeline(entries: [entry], policy: .after(next))
    }

    private func entry(for configuration: TDListTypeConfigurationIntent, family: WidgetFamily) async -> TDWidgetUserEntry {
        let viewTitle = viewTitle(for: configuration)
        guard let user = TDWidgetUserSession.currentUser() else {
            return TDWidgetUserEntry(
                date: .now,
                configuration: configuration,
                isLoggedIn: false,
                userId: -1,
                userName: "未登录",
                viewTitle: viewTitle,
                pendingCount: 0,
                firstPendingTitle: nil,
                swiftDataError: nil
            )
        }

        let fetchLimit = TDWidgetTaskDisplayLimit.value(for: family)

        do {
            let context = try TDSharedSwiftDataStore.makeWidgetContext()
            let descriptor = descriptor(for: configuration, userId: user.userId, fetchLimit: fetchLimit)
            let tasks = try context.fetch(descriptor)

            let pendingCount = tasks.filter { !$0.complete }.count
            let firstPendingTitle = tasks.first { !$0.complete }?.taskContent
            return TDWidgetUserEntry(
                date: .now,
                configuration: configuration,
                isLoggedIn: true,
                userId: user.userId,
                userName: user.userName,
                viewTitle: viewTitle,
                pendingCount: pendingCount,
                firstPendingTitle: firstPendingTitle,
                swiftDataError: nil
            )
        } catch {
            return TDWidgetUserEntry(
                date: .now,
                configuration: configuration,
                isLoggedIn: true,
                userId: user.userId,
                userName: user.userName,
                viewTitle: viewTitle,
                pendingCount: 0,
                firstPendingTitle: nil,
                swiftDataError: "\(error)"
            )
        }
    }

    private func viewTitle(for configuration: TDListTypeConfigurationIntent) -> String {
        switch configuration.viewType {
        case .dayTodo:
            return "Day Todo"
        case .recentTodos:
            return "最近待办"
        case .categoryList:
            return configuration.category?.categoryName ?? "分类清单"
        }
    }

    private func descriptor(
        for configuration: TDListTypeConfigurationIntent,
        userId: Int,
        fetchLimit: Int
    ) -> FetchDescriptor<TDMacSwiftDataListModel> {
        switch configuration.viewType {
        case .dayTodo:
            return TDWidgetTaskFetchDescriptorFactory.dayTodoToday(userId: userId, fetchLimit: fetchLimit)
        case .recentTodos:
            return TDWidgetTaskFetchDescriptorFactory.taskListSuperset(
                userId: userId,
                categoryId: -101,
                tagFilter: "",
                fetchLimit: fetchLimit,
                showExpired: configuration.showExpired
            )
        case .categoryList:
            let categoryId = configuration.category?.categoryId ?? 0
            return TDWidgetTaskFetchDescriptorFactory.taskListSuperset(
                userId: userId,
                categoryId: categoryId > 0 ? categoryId : -101,
                tagFilter: "",
                fetchLimit: fetchLimit,
                showExpired: configuration.showExpired
            )
        }
    }
}

private enum TDWidgetTaskDisplayLimit {
    static func value(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall:
            return 5
        case .systemMedium:
            return 7
        case .systemLarge:
            return 15
        default:
            return 7
        }
    }
}

private struct TDWidgetUserView: View {
    let entry: TDWidgetIntentProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.viewTitle)
                .font(.system(size: 14, weight: .regular))

            if entry.isLoggedIn {
                Text("已登录：\(entry.userName)")
                    .font(.system(size: 12))
                Text("userId: \(entry.userId)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Text("未完成：\(entry.pendingCount)")
                    .font(.system(size: 12, weight: .medium))

                if let title = entry.firstPendingTitle, !title.isEmpty {
                    Text(title)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let err = entry.swiftDataError, !err.isEmpty {
                    Text("SwiftData读取失败")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.red)
                    Text(err)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            } else {
                Text("未登录")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(8)
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
}

/// 列表模式小组件：可配置 Day Todo / 最近待办 / 分类清单，及是否显示已过期
struct TDMacWidgetListModeWidget: Widget {
    let kind: String = TDWidgetKind.listMode

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: TDListTypeConfigurationIntent.self,
            provider: TDWidgetIntentProvider()
        ) { entry in
            TDWidgetUserView(entry: entry)
        }
        .configurationDisplayName("列表模式")
        .description("快速查看任务。添加后右键点击小组件选「编辑」可配置：查看（Day Todo / 最近待办 / 分类清单）、显示已过期等。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
