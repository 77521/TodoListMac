//
//  TDTomatoRecordModel.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/9/24.
//

import Foundation
import SwiftData

/// 番茄钟记录模型（服务器数据）
struct TDTomatoRecordModel: Codable {
    
    // MARK: - 自定义解码
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decodeIfPresent(Int64.self, forKey: .id)
        self.userId = try container.decode(Int.self, forKey: .userId)
        self.tomatoId = try container.decode(String.self, forKey: .tomatoId)
        self.taskContent = try container.decodeIfPresent(String.self, forKey: .taskContent)
        self.taskId = try container.decodeIfPresent(String.self, forKey: .taskId)
        self.startTime = try container.decode(Int64.self, forKey: .startTime)
        self.endTime = try container.decode(Int64.self, forKey: .endTime)
        self.focus = try container.decode(Bool.self, forKey: .focus)
        self.focusDuration = try container.decode(Int.self, forKey: .focusDuration)
        self.rest = try container.decode(Bool.self, forKey: .rest)
        self.restDuration = try container.decode(Int.self, forKey: .restDuration)
        self.snowAdd = try container.decode(Int.self, forKey: .snowAdd)
        self.syncTime = try container.decode(Int64.self, forKey: .syncTime)
        
        // status 字段如果服务器没有返回，使用默认值 "synced"
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? "sync"
    }
    /// 记录ID
    let id: Int64?
    /// 用户ID
    let userId: Int
    /// 番茄钟ID（唯一标识）
    let tomatoId: String
    /// 任务内容
    let taskContent: String?
    /// 任务ID
    let taskId: String?
    /// 开始时间（时间戳，毫秒）
    let startTime: Int64
    /// 结束时间（时间戳，毫秒）
    let endTime: Int64
    /// 是否专注成功
    let focus: Bool
    /// 专注时长（秒）
    let focusDuration: Int
    /// 是否休息成功
    let rest: Bool
    /// 休息时长（秒）
    let restDuration: Int
    /// 雪花值
    let snowAdd: Int
    /// 同步时间（时间戳，毫秒）
    let syncTime: Int64
    /// 记录状态（add: 新增，update: 更新，delete: 删除，synced: 已同步）
    let status: String
    
    /// 便利初始化方法（用于本地创建记录）
    init(
        id: Int64? = nil,
        userId: Int,
        tomatoId: String,
        taskContent: String? = nil,
        taskId: String? = nil,
        startTime: Int64,
        endTime: Int64,
        focus: Bool,
        focusDuration: Int,
        rest: Bool,
        restDuration: Int,
        snowAdd: Int = 0,
        syncTime: Int64,
        status: String = "sync"
    ) {
        self.id = id
        self.userId = userId
        self.tomatoId = tomatoId
        self.taskContent = taskContent
        self.taskId = taskId
        self.startTime = startTime
        self.endTime = endTime
        self.focus = focus
        self.focusDuration = focusDuration
        self.rest = rest
        self.restDuration = restDuration
        self.snowAdd = snowAdd
        self.syncTime = syncTime
        self.status = status
    }
}


// MARK: - SwiftData 本地数据库模型
@Model
class TDTomatoRecordLocalModel {
    /// 记录ID
    var id: Int64?
    /// 用户ID
    var userId: Int
    /// 番茄钟ID（唯一标识）
    var tomatoId: String
    /// 任务内容
    var taskContent: String?
    /// 任务ID
    var taskId: String?
    /// 开始时间（时间戳，毫秒）
    var startTime: Int64
    /// 结束时间（时间戳，毫秒）
    var endTime: Int64
    /// 是否专注成功
    var focus: Bool
    /// 专注时长（秒）
    var focusDuration: Int
    /// 是否休息成功
    var rest: Bool
    /// 休息时长（秒）
    var restDuration: Int
    /// 雪花值
    var snowAdd: Int
    /// 同步时间（时间戳，毫秒）
    var syncTime: Int64
    /// 记录状态（add: 新增，update: 更新，delete: 删除，synced: 已同步）
    var status: String
    
    init(
        id: Int64? = nil,
        userId: Int,
        tomatoId: String,
        taskContent: String? = nil,
        taskId: String? = nil,
        startTime: Int64,
        endTime: Int64,
        focus: Bool,
        focusDuration: Int,
        rest: Bool,
        restDuration: Int,
        snowAdd: Int = 0,
        syncTime: Int64,
        status: String = "add"
    ) {
        self.id = id
        self.userId = userId
        self.tomatoId = tomatoId
        self.taskContent = taskContent
        self.taskId = taskId
        self.startTime = startTime
        self.endTime = endTime
        self.focus = focus
        self.focusDuration = focusDuration
        self.rest = rest
        self.restDuration = restDuration
        self.snowAdd = snowAdd
        self.syncTime = syncTime
        self.status = status
    }
}

// MARK: - 数据转换方法
extension TDTomatoRecordModel {
    /// 转换为本地数据库模型
    func toLocalModel() -> TDTomatoRecordLocalModel {
        return TDTomatoRecordLocalModel(
            id: self.id,
            userId: self.userId,
            tomatoId: self.tomatoId,
            taskContent: self.taskContent,
            taskId: self.taskId,
            startTime: self.startTime,
            endTime: self.endTime,
            focus: self.focus,
            focusDuration: self.focusDuration,
            rest: self.rest,
            restDuration: self.restDuration,
            snowAdd: self.snowAdd,
            syncTime: self.syncTime,
            status: self.status
        )
    }
}

extension TDTomatoRecordLocalModel {
    /// 转换为服务器数据模型
    func toServerModel() -> TDTomatoRecordModel {
        return TDTomatoRecordModel(
            id: self.id,
            userId: self.userId,
            tomatoId: self.tomatoId,
            taskContent: self.taskContent,
            taskId: self.taskId,
            startTime: self.startTime,
            endTime: self.endTime,
            focus: self.focus,
            focusDuration: self.focusDuration,
            rest: self.rest,
            restDuration: self.restDuration,
            snowAdd: self.snowAdd,
            syncTime: self.syncTime,
            status: self.status
        )
    }
}
