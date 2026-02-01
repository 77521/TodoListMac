//
//  TDTagModels.swift
//  TodoMacRepertorie
//
//  标签索引（从任务标题 taskContent 提取）：
//  - TDTagModel：唯一标签（用于列表/排序）
//  - TDTaskTagModel：任务-标签关系（用于计数与增量更新）
//

import Foundation
import SwiftData

/// 标签（唯一表）
@Model
final class TDTagModel {
    /// 当前用户 id（用于多账号隔离）
    /// - 注意：这是后加字段。为兼容旧库轻量迁移，需要提供默认值。
    var userId: Int = -1

    /// 归一化 key（用于去重）。默认不做大小写合并：`#Work` 与 `#work` 视为不同标签。
    var key: String

    /// 多账号唯一键：`userId|key`
    /// - 注意：旧库迁移时该字段会先为 nil；后续会在启动时补齐。
    /// - unique 约束允许多个 nil（类似 SQL 的多个 NULL），可避免迁移阶段因默认空串导致唯一冲突。
    @Attribute(.unique) var uniqueKey: String? = nil

    /// 展示文本（一般等于 key，但保留原始写法）
    var display: String

    /// 标签时间（毫秒）
    /// - 约定：使用“任务的 createTime”更新
    /// - 用途：按时间排序（新的在前）
    var createTime: Int64

    /// 关联任务数量（用于“按数量排序”）
    var taskCount: Int

    init(userId: Int, key: String, display: String, createTime: Int64, taskCount: Int) {
        self.userId = userId
        self.key = key
        self.uniqueKey = "\(userId)|\(key)"
        self.display = display
        self.createTime = createTime
        self.taskCount = taskCount
    }
}

/// 任务-标签关系（一条任务里同一个标签只存一条，用于计数/增量 diff）
@Model
final class TDTaskTagModel {
    /// 当前用户 id（用于多账号隔离）
    /// - 注意：这是后加字段。为兼容旧库轻量迁移，需要提供默认值。
    var userId: Int = -1
    var taskId: String
    var tagKey: String
    var taskCreateTime: Int64

    init(userId: Int, taskId: String, tagKey: String, taskCreateTime: Int64) {
        self.userId = userId
        self.taskId = taskId
        self.tagKey = tagKey
        self.taskCreateTime = taskCreateTime
    }
}

