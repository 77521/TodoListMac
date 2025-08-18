//
//  TDMacSwiftDataListModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI
import SwiftData


/// 待办事项模型
@Model
final class TDMacSwiftDataListModel {
    // MARK: - 索引配置（提升查询和排序性能）
    @Attribute(.unique) var id: Int64
    @Attribute(.spotlight) var userId: Int
    @Attribute(.unique) var taskId: String
    @Attribute(.spotlight) var complete: Bool
    @Attribute(.spotlight) var delete: Bool
    @Attribute(.spotlight) var todoTime: Int64
    @Attribute(.spotlight) var taskSort: Decimal
    @Attribute(.spotlight) var standbyInt1: Int
    @Attribute(.spotlight) var createTime: Int64
    @Attribute(.spotlight) var syncTime: Int64
    @Attribute(.spotlight) var snowAssess: Int
    @Attribute(.spotlight) var standbyStr1: String?
    @Attribute(.spotlight) var version: Int64
    @Attribute(.spotlight) var taskContent: String
    @Attribute(.spotlight) var taskDescribe: String?
    @Attribute(.spotlight) var standbyStr2: String?
    // MARK: - 子任务结构体
    struct SubTask: Codable {
        var isComplete: Bool
        var content: String
    }
    
    // MARK: - 附件结构体
    struct Attachment: Codable {
        var downloading: Bool
        var name: String
        let size: String      // 改为 String 类型
        var suffix: String?
        var url: String
        
        var isPhoto: Bool {
            guard let suffix = suffix else { return true }
            return ["jpg", "jpeg", "png", "gif", "heic", "webp"].contains(suffix.lowercased())
        }
        
    }
    
    // MARK: - 服务器字段
    var reminderTime: Int64
    var snowAdd: Int
    var standbyStr3: String?
    var standbyStr4: String?
    
    // MARK: - 本地字段
    var status: String = "sync"
    var number: Int = 1
    var isSubOpen: Bool = true
    var standbyIntColor: String = ""
    var standbyIntName: String = ""
    var reminderTimeString: String = ""
    var subTaskList: [SubTask] = []
    var attachmentList: [Attachment] = []
    // 运行时属性，不保存到数据库
    @Transient var isSystemCalendarEvent: Bool = false

    // MARK: - 初始化方法
    init(
        id: Int64,
        taskId: String,
        taskContent: String,
        taskDescribe: String? = nil,
        complete: Bool = false,
        createTime: Int64,
        delete: Bool = false,
        reminderTime: Int64 = 0,
        snowAdd: Int = 0,
        snowAssess: Int = 0,
        standbyInt1: Int = 0,
        standbyStr1: String? = nil,
        standbyStr2: String? = nil,
        standbyStr3: String? = nil,
        standbyStr4: String? = nil,
        syncTime: Int64,
        taskSort: Decimal,
        todoTime: Int64,
        userId: Int,
        version: Int64,
        status: String = "sync",
        isSubOpen: Bool = true
    ) {
        self.id = id
        self.taskId = taskId
        self.taskContent = taskContent
        self.taskDescribe = taskDescribe
        self.complete = complete
        self.createTime = createTime
        self.delete = delete
        self.reminderTime = reminderTime
        self.snowAdd = snowAdd
        self.snowAssess = snowAssess
        self.standbyInt1 = standbyInt1
        self.standbyStr1 = standbyStr1
        self.standbyStr2 = standbyStr2
        self.standbyStr3 = standbyStr3
        self.standbyStr4 = standbyStr4
        self.syncTime = syncTime
        self.taskSort = taskSort
        self.todoTime = todoTime
        self.userId = userId
        self.version = version
        self.status = status
        self.isSubOpen = isSubOpen
    }
}
/// 子任务
@Model
final class TDSubDataModel {
    var content: String      // 子任务内容
    var complete: Bool       // 是否完成
    
    init(content: String, complete: Bool) {
        self.content = content
        self.complete = complete
    }
}
