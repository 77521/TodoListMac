//
//  TDTagIndexService.swift
//  TodoMacRepertorie
//
//  在同步/本地更新任务时增量维护标签索引
//

import Foundation
import SwiftData

final class TDTagIndexService {
    static let shared = TDTagIndexService()
    private init() {}

    // MARK: - Migration / Rebuild

    /// 兼容旧版本 SwiftData（未包含 userId/uniqueKey）导致的校验失败/数据不可见问题：
    /// - 新字段通过默认值/可选值完成轻量迁移后，需要把历史标签索引“按任务重建”一次。
    /// - 标签索引是派生数据（由任务 taskContent 解析），重建不会影响任务本身。
    func migrateLegacyTagIndexIfNeeded(context: ModelContext) {
        let flagKey = "td_tag_index_migrated_to_user_scoped_v2"
        if UserDefaults.standard.bool(forKey: flagKey) { return }

        do {
            // 1) 判断是否存在旧数据（userId 默认 -1，或 uniqueKey 为 nil）
            var legacyRelationDescriptor = FetchDescriptor<TDTaskTagModel>(
                predicate: #Predicate { $0.userId < 0 }
            )
            legacyRelationDescriptor.fetchLimit = 1
            let hasLegacyRelations = (try context.fetch(legacyRelationDescriptor).first != nil)

            var legacyTagDescriptor = FetchDescriptor<TDTagModel>(
                predicate: #Predicate { $0.userId < 0 || $0.uniqueKey == nil }
            )
            legacyTagDescriptor.fetchLimit = 1
            let hasLegacyTags = (try context.fetch(legacyTagDescriptor).first != nil)

            guard hasLegacyRelations || hasLegacyTags else {
                UserDefaults.standard.set(true, forKey: flagKey)
                return
            }

            print("🔁 检测到旧版标签索引，开始按任务重建（一次性）")

            // 2) 清空旧索引表（派生数据，允许重建）
            let oldTags = try context.fetch(FetchDescriptor<TDTagModel>())
            for t in oldTags { context.delete(t) }

            let oldRelations = try context.fetch(FetchDescriptor<TDTaskTagModel>())
            for r in oldRelations { context.delete(r) }

            try context.save()

            // 3) 扫描所有任务，重建 relations + tags 聚合
            let tasks = try context.fetch(FetchDescriptor<TDMacSwiftDataListModel>())

            struct Agg {
                var userId: Int
                var key: String
                var display: String
                var maxTime: Int64
                var count: Int
            }

            var aggByUnique: [String: Agg] = [:]
            aggByUnique.reserveCapacity(256)

            for task in tasks {
                if task.delete == true || task.status == "delete" { continue }

                let extracted = extractTags(from: task.taskContent)
                let keys = Set(extracted.filter { !$0.isEmpty })
                guard !keys.isEmpty else { continue }

                for key in keys {
                    // relation（用于后续增量 diff）
                    let relation = TDTaskTagModel(
                        userId: task.userId,
                        taskId: task.taskId,
                        tagKey: key,
                        taskCreateTime: task.createTime
                    )
                    context.insert(relation)

                    // 聚合 tag（用于侧边栏列表/排序）
                    let uk = "\(task.userId)|\(key)"
                    if var existing = aggByUnique[uk] {
                        existing.count += 1
                        if task.createTime > existing.maxTime { existing.maxTime = task.createTime }
                        aggByUnique[uk] = existing
                    } else {
                        let display = extracted.first(where: { $0 == key }) ?? key
                        aggByUnique[uk] = Agg(
                            userId: task.userId,
                            key: key,
                            display: display,
                            maxTime: task.createTime,
                            count: 1
                        )
                    }
                }
            }

            for agg in aggByUnique.values {
                let tag = TDTagModel(
                    userId: agg.userId,
                    key: agg.key,
                    display: agg.display,
                    createTime: agg.maxTime,
                    taskCount: agg.count
                )
                context.insert(tag)
            }

            try context.save()
            UserDefaults.standard.set(true, forKey: flagKey)
            print("✅ 标签索引重建完成：tags=\(aggByUnique.count)")
        } catch {
            // 不要阻塞启动；下次启动仍会再次尝试
            print("❌ 标签索引迁移/重建失败：\(error)")
        }
    }

    /// iOS 同款默认正则：末尾必须有空格（但不能是换行）
    /// - 例： "我#你好 " ✅；"我#你好" ❌；"#hi\\n" ❌
    private static let defaultPattern = #"#[^\s]{1,20}+(?!\n)\s"#

    /// 从标题提取标签（返回的字符串会去掉尾部空白）
    func extractTags(from taskContent: String, pattern: String? = nil) -> [String] {
        let p = (pattern?.isEmpty == false) ? pattern! : Self.defaultPattern
        guard let regex = try? NSRegularExpression(pattern: p, options: [.caseInsensitive]) else { return [] }

        let ns = taskContent as NSString
        let matches = regex.matches(in: taskContent, options: [], range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return [] }

        return matches.map { ns.substring(with: $0.range(at: 0)).trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    /// 增量索引一个任务：
    /// - 仅使用 taskContent
    /// - task.delete == true 或 status == "delete" 时：移除该任务的所有标签关系并扣减计数
    func indexTask(_ task: TDMacSwiftDataListModel, context: ModelContext) throws {
        let userId = task.userId
        // 删除任务：直接清关系
        if task.delete == true || task.status == "delete" {
            try removeAllTags(userId: userId, forTaskId: task.taskId, context: context)
            return
        }

        let extracted = extractTags(from: task.taskContent)
        let newKeys = Set(extracted.filter { !$0.isEmpty })

        // 读取旧关系
        let oldRelations = try fetchTaskTags(userId: userId, taskId: task.taskId, context: context)
        let oldKeys = Set(oldRelations.map(\.tagKey))

        let added = newKeys.subtracting(oldKeys)
        let removed = oldKeys.subtracting(newKeys)

        // 先处理移除（避免同一次更新里先加后减造成计数异常）
        for key in removed {
            try removeTagRelation(userId: userId, taskId: task.taskId, tagKey: key, removedTaskCreateTime: task.createTime, context: context)
        }

        // 再处理新增
        for key in added {
            // display：优先用本次提取到的原串
            let display = extracted.first(where: { $0 == key }) ?? key
            try addTagRelation(userId: userId, taskId: task.taskId, tagKey: key, display: display, taskCreateTime: task.createTime, context: context)
        }
    }

    // MARK: - Private

    private func fetchTaskTags(userId: Int, taskId: String, context: ModelContext) throws -> [TDTaskTagModel] {
        let descriptor = FetchDescriptor<TDTaskTagModel>(
            predicate: #Predicate { $0.userId == userId && $0.taskId == taskId }
        )
        return try context.fetch(descriptor)
    }

    private func fetchTaskTag(userId: Int, taskId: String, tagKey: String, context: ModelContext) throws -> TDTaskTagModel? {
        var descriptor = FetchDescriptor<TDTaskTagModel>(
            predicate: #Predicate { $0.userId == userId && $0.taskId == taskId && $0.tagKey == tagKey }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func fetchTag(userId: Int, key: String, context: ModelContext) throws -> TDTagModel? {
        var descriptor = FetchDescriptor<TDTagModel>(
            predicate: #Predicate { $0.userId == userId && $0.key == key }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func fetchMaxTaskCreateTime(userId: Int, forTagKey key: String, context: ModelContext) throws -> Int64 {
        // SwiftData 没有 group-by/max，退化为：按 taskCreateTime desc 取第一条
        var descriptor = FetchDescriptor<TDTaskTagModel>(
            predicate: #Predicate { $0.userId == userId && $0.tagKey == key },
            sortBy: [SortDescriptor(\TDTaskTagModel.taskCreateTime, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.taskCreateTime ?? 0
    }

    private func addTagRelation(
        userId: Int,
        taskId: String,
        tagKey: String,
        display: String,
        taskCreateTime: Int64,
        context: ModelContext
    ) throws {
        // 防御：避免重复插入（即使外层已做 diff）
        if let _ = try fetchTaskTag(userId: userId, taskId: taskId, tagKey: tagKey, context: context) {
            return
        }

        // upsert Tag
        let tag: TDTagModel
        if let existing = try fetchTag(userId: userId, key: tagKey, context: context) {
            tag = existing
            // 只保留一个时间字段：用任务 createTime 更新（用于按时间排序）
            if taskCreateTime > tag.createTime { tag.createTime = taskCreateTime }
            tag.taskCount = max(0, tag.taskCount + 1)
        } else {
            tag = TDTagModel(
                userId: userId,
                key: tagKey,
                display: display,
                createTime: taskCreateTime,
                taskCount: 1
            )
            context.insert(tag)
        }

        // insert relation
        let relation = TDTaskTagModel(userId: userId, taskId: taskId, tagKey: tagKey, taskCreateTime: taskCreateTime)
        context.insert(relation)
    }

    private func removeTagRelation(
        userId: Int,
        taskId: String,
        tagKey: String,
        removedTaskCreateTime: Int64,
        context: ModelContext
    ) throws {
        // 删除 relation
        if let relation = try fetchTaskTag(userId: userId, taskId: taskId, tagKey: tagKey, context: context) {
            context.delete(relation)
        } else {
            return
        }

        // 扣减 Tag 计数
        guard let tag = try fetchTag(userId: userId, key: tagKey, context: context) else { return }
        tag.taskCount = max(0, tag.taskCount - 1)

        if tag.taskCount <= 0 {
            // 没人用了：直接删标签
            context.delete(tag)
            return
        }

        // 如果移除的那条正好是“用于排序的时间”，则重算一次（只在这种情况下才查，避免常态开销）
        if removedTaskCreateTime == tag.createTime {
            tag.createTime = try fetchMaxTaskCreateTime(userId: userId, forTagKey: tagKey, context: context)
        }
    }

    private func removeAllTags(userId: Int, forTaskId taskId: String, context: ModelContext) throws {
        let relations = try fetchTaskTags(userId: userId, taskId: taskId, context: context)
        guard !relations.isEmpty else { return }

        // 逐条删除并扣减
        for r in relations {
            // 先删关系
            context.delete(r)
            // 扣减 tag
            if let tag = try fetchTag(userId: userId, key: r.tagKey, context: context) {
                tag.taskCount = max(0, tag.taskCount - 1)
                if tag.taskCount <= 0 {
                    context.delete(tag)
                } else if r.taskCreateTime == tag.createTime {
                    tag.createTime = try fetchMaxTaskCreateTime(userId: userId, forTagKey: r.tagKey, context: context)
                }
            }
        }
    }
}

