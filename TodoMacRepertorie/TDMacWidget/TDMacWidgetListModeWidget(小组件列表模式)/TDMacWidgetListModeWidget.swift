//
//  TDMacWidgetListModeWidget.swift
//  TDMacWidget
//
//  极简版小组件：只读取 AppGroup 里的登录信息并展示
//

import WidgetKit
import SwiftUI
import Foundation
import SwiftData

private struct TDWidgetUserEntry: TimelineEntry {
    let date: Date
    let isLoggedIn: Bool
    let userId: Int
    let userName: String
    let pendingCount: Int
    let firstPendingTitle: String?
    let swiftDataError: String?
}

private struct TDWidgetUserProvider: TimelineProvider {
    func placeholder(in context: Context) -> TDWidgetUserEntry {
        TDWidgetUserEntry(
            date: .now,
            isLoggedIn: false,
            userId: -1,
            userName: "未登录",
            pendingCount: 0,
            firstPendingTitle: nil,
            swiftDataError: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TDWidgetUserEntry) -> Void) {
        completion(readEntry(family: context.family))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TDWidgetUserEntry>) -> Void) {
        let entry = readEntry(family: context.family)
        // 轻量：每 15 分钟刷新一次（后续接入列表后可再调）
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func readEntry(family: WidgetFamily) -> TDWidgetUserEntry {
        // Widget 最外层统一读取一次用户信息（AppGroup JSON -> TDUserModel）
        guard let user = TDWidgetUserSession.currentUser() else {
            return TDWidgetUserEntry(
                date: .now,
                isLoggedIn: false,
                userId: -1,
                userName: "未登录",
                pendingCount: 0,
                firstPendingTitle: nil,
                swiftDataError: nil
            )
        }

        let fetchLimit = TDWidgetTaskDisplayLimit.value(for: family)

        // 最小验证：Widget 读取 SwiftData（AppGroup store）里的“今天 DayTodo 数据”
        do {
            let context = try TDSharedSwiftDataStore.makeWidgetContext()
            let descriptor = TDWidgetTaskFetchDescriptorFactory.dayTodoToday(userId: user.userId, fetchLimit: fetchLimit)
            let tasks = try context.fetch(descriptor)

            let pendingCount = tasks.filter { !$0.complete }.count
            let firstPendingTitle = tasks.first { !$0.complete }?.taskContent
            return TDWidgetUserEntry(
                date: .now,
                isLoggedIn: true,
                userId: user.userId,
                userName: user.userName,
                pendingCount: pendingCount,
                firstPendingTitle: firstPendingTitle,
                swiftDataError: nil
            )
        } catch {
            return TDWidgetUserEntry(
                date: .now,
                isLoggedIn: true,
                userId: user.userId,
                userName: user.userName,
                pendingCount: 0,
                firstPendingTitle: nil,
                swiftDataError: "\(error)"
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
    let entry: TDWidgetUserProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DayTodo")
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

/// 列表模式（极简版，仅验证 AppGroup 登录信息共享）
struct TDMacWidgetListModeWidget: Widget {
    let kind: String = TDWidgetKind.listMode

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TDWidgetUserProvider()) { entry in
            TDWidgetUserView(entry: entry)
        }
        .configurationDisplayName("列表模式")
        .description("显示登录状态（AppGroup 共享）")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
