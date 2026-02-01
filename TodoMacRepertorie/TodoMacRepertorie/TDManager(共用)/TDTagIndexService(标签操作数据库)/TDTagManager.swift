//
//  TDTagManager.swift
//  TodoMacRepertorie
//
//  标签索引 CRUD 管理器（SwiftData）
//

import Foundation
import SwiftData
import OSLog

@MainActor
final class TDTagManager: ObservableObject {
    static let shared = TDTagManager()

    private let logger = Logger(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDTagManager")
    private init() {}

    // MARK: - Query

    func fetchAllTags(
        userId: Int = TDUserManager.shared.userId,
        context: ModelContext = TDModelContainer.shared.mainContext
    ) -> [TDTagModel] {
        do {
            let descriptor = FetchDescriptor<TDTagModel>(
                predicate: #Predicate { $0.userId == userId },
                sortBy: [SortDescriptor(\TDTagModel.createTime, order: .reverse)]
            )
            return try context.fetch(descriptor)
        } catch {
            logger.error("❌ fetchAllTags 失败: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func fetchTag(
        userId: Int = TDUserManager.shared.userId,
        key: String,
        context: ModelContext = TDModelContainer.shared.mainContext
    ) -> TDTagModel? {
        do {
            var descriptor = FetchDescriptor<TDTagModel>(
                predicate: #Predicate { $0.userId == userId && $0.key == key }
            )
            descriptor.fetchLimit = 1
            return try context.fetch(descriptor).first
        } catch {
            logger.error("❌ fetchTag 失败: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func fetchRelations(
        userId: Int = TDUserManager.shared.userId,
        tagKey: String,
        context: ModelContext = TDModelContainer.shared.mainContext
    ) -> [TDTaskTagModel] {
        do {
            let descriptor = FetchDescriptor<TDTaskTagModel>(
                predicate: #Predicate { $0.userId == userId && $0.tagKey == tagKey }
            )
            return try context.fetch(descriptor)
        } catch {
            logger.error("❌ fetchRelations 失败: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    // MARK: - Create / Update

    /// 手动创建/更新标签（不建议用于“从任务解析”的场景；解析应走 `TDTagIndexService`）
    func upsertTag(
        userId: Int = TDUserManager.shared.userId,
        key: String,
        display: String? = nil,
        time: Int64 = Date.currentTimestamp,
        taskCount: Int = 0,
        context: ModelContext = TDModelContainer.shared.mainContext
    ) throws {
        let k = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty else { return }

        if let tag = fetchTag(userId: userId, key: k, context: context) {
            if let d = display, !d.isEmpty { tag.display = d }
            tag.createTime = max(tag.createTime, time)
            tag.taskCount = max(0, max(tag.taskCount, taskCount))
        } else {
            let tag = TDTagModel(
                userId: userId,
                key: k,
                display: display?.isEmpty == false ? display! : k,
                createTime: time,
                taskCount: max(0, taskCount)
            )
            context.insert(tag)
        }

        try context.save()
    }

    /// 重命名标签 key（仅更新索引表：`TDTagModel.key` 与 `TDTaskTagModel.tagKey`）
    /// - 注意：不会自动改写任务标题里的 `#xxx` 文本（那属于任务内容的业务）
    /// - 如果 `newKey` 已存在，则会做“合并”：把旧 key 的关系迁移到新 key，并合并计数与时间。
    func renameTagKey(
        userId: Int = TDUserManager.shared.userId,
        from oldKey: String,
        to newKey: String,
        newDisplay: String? = nil,
        context: ModelContext = TDModelContainer.shared.mainContext
    ) throws {
        let fromKey = oldKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let toKey = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !fromKey.isEmpty, !toKey.isEmpty else { return }
        guard fromKey != toKey else {
            if let d = newDisplay, let tag = fetchTag(userId: userId, key: fromKey, context: context) {
                tag.display = d
                try context.save()
            }
            return
        }

        guard let fromTag = fetchTag(userId: userId, key: fromKey, context: context) else { return }

        if let toTag = fetchTag(userId: userId, key: toKey, context: context) {
            // 合并：迁移关系
            let relations = fetchRelations(userId: userId, tagKey: fromKey, context: context)
            for r in relations {
                r.tagKey = toKey
            }

            // 合并计数/时间/展示
            toTag.taskCount = max(0, toTag.taskCount + max(0, fromTag.taskCount))
            toTag.createTime = max(toTag.createTime, fromTag.createTime)
            if let d = newDisplay, !d.isEmpty {
                toTag.display = d
            } else if toTag.display.isEmpty {
                toTag.display = toKey
            }

            // 删除旧 tag
            context.delete(fromTag)
        } else {
            // 直接改 key：先改关系再改 tag（避免暂时查询不到）
            let relations = fetchRelations(userId: userId, tagKey: fromKey, context: context)
            for r in relations {
                r.tagKey = toKey
            }
            fromTag.key = toKey
            // 同步更新多账号唯一键，避免后续插入旧 key 时触发 unique 冲突
            fromTag.uniqueKey = "\(fromTag.userId)|\(toKey)"
            if let d = newDisplay, !d.isEmpty {
                fromTag.display = d
            } else if fromTag.display.isEmpty {
                fromTag.display = toKey
            }
        }

        try context.save()
    }

    // MARK: - Delete

    /// 删除标签（同时删除该标签的任务-标签关系）
    func deleteTag(
        userId: Int = TDUserManager.shared.userId,
        key: String,
        context: ModelContext = TDModelContainer.shared.mainContext
    ) throws {
        let k = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty else { return }

        let relations = fetchRelations(userId: userId, tagKey: k, context: context)
        for r in relations {
            context.delete(r)
        }
        if let tag = fetchTag(userId: userId, key: k, context: context) {
            context.delete(tag)
        }
        try context.save()
    }

    // MARK: - Helpers

    /// 给侧边栏生成稳定的负数 id（避免每次刷新都变动导致 UI 闪动）
    func stableSidebarId(for tagKey: String) -> Int {
        let v = fnv1a32(tagKey)
        // 不取模，避免不同 tagKey 发生碰撞导致 UI 丢项（ForEach id 重复会被合并）
        // 同时规避系统负数 id（-1000/-2000 等），用 -10_000 起
        return -10_000 - Int(v)
    }

    private func fnv1a32(_ s: String) -> UInt32 {
        var hash: UInt32 = 2166136261
        for b in s.utf8 {
            hash ^= UInt32(b)
            hash &*= 16777619
        }
        return hash
    }
}

