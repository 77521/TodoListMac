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
    var id: Int64
    var taskId: String
    var taskContent: String
    var taskDescribe: String?
    var complete: Bool
    var createTime: Int64
    var delete: Bool
    var reminderTime: Int64
    var snowAdd: Int
    var snowAssess: Int
    var standbyInt1: Int
    var standbyStr1: String?
    var standbyStr2: String?
    var standbyStr3: String?
    var standbyStr4: String?
    var syncTime: Int64
    var taskSort: Double
    var todoTime: Int64
    var userId: Int
    var version: Int
    
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
        taskSort: Double,
        todoTime: Int64,
        userId: Int,
        version: Int,
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
