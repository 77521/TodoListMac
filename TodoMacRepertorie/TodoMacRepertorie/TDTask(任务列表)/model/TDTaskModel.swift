//
//  TDMacHandyJsonListModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI


/// 任务模型（用于网络传输和业务处理）
struct TDTaskModel: Codable {
    // MARK: - 子任务结构体
    struct SubTask: Codable {
        let id: String
        var isComplete: Bool?
        var content: String?
        
        init(isComplete: Bool? = nil, content: String? = nil, id: String? = nil) {
            self.id = id ?? UUID().uuidString
            self.isComplete = isComplete
            self.content = content
        }
        
        // 自定义解码方法，兼容没有 id 字段的旧数据
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // 尝试解码 id，如果不存在则生成新的
            if let id = try? container.decode(String.self, forKey: .id) {
                self.id = id
            } else {
                self.id = UUID().uuidString
            }
            
            self.isComplete = try container.decodeIfPresent(Bool.self, forKey: .isComplete)
            self.content = try container.decodeIfPresent(String.self, forKey: .content)
        }
        
        // 编码时总是包含 id
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encodeIfPresent(isComplete, forKey: .isComplete)
            try container.encodeIfPresent(content, forKey: .content)
        }
        
        private enum CodingKeys: String, CodingKey {
            case id, isComplete, content
        }

    }
    
    // MARK: - 附件结构体
    struct Attachment: Codable {
        // 服务器返回字段
        let id: String        // 唯一ID
        let size: String      // 附件大小，字符串类型
        let suffix: String?   // 文件后缀，可选
        let url: String       // 附件URL
        let name: String      // 附件名称
        
        
        /// 是否为图片类型
        var isPhoto: Bool {
            guard let suffix = suffix else { return true }
            return ["jpg", "jpeg", "png", "gif", "heic", "webp"].contains(suffix.lowercased())
        }
        
        enum CodingKeys: String, CodingKey {
            case id, size, suffix, url, name
        }

        /// 普通初始化方法
        init(id: String = UUID().uuidString, size: String, suffix: String?, url: String, name: String) {
            self.id = id
            self.size = size
            self.suffix = suffix
            self.url = url
            self.name = name
        }
        
        /// 自定义解码方法，兼容 size 字段为字符串或数字
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // 处理 ID 字段，如果没有则生成一个
            if let idString = try? container.decode(String.self, forKey: .id) {
                id = idString
            } else {
                id = UUID().uuidString
            }
            
            if let sizeString = try? container.decode(String.self, forKey: .size) {
                size = sizeString
            } else if let sizeNumber = try? container.decode(Double.self, forKey: .size) {
                size = String(format: "%.8f", sizeNumber)
            } else {
                size = "0"
            }
            suffix = try? container.decode(String.self, forKey: .suffix)
            url = try container.decode(String.self, forKey: .url)
            name = try container.decode(String.self, forKey: .name)
        }
    }

    // MARK: - 服务器字段
    var id: Int64
    var taskId: String
    var taskContent: String?
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
    var taskSort: Decimal
    var todoTime: Int64
    var userId: Int
    var version: Int64
    
    // MARK: - 本地字段
    var status: String = "sync"
    var number: Int = 1
    var isSubOpen: Bool = true
    var standbyIntColor: String = ""
    var standbyIntName: String = ""
    var reminderTimeString: String = ""
    var subTaskList: [SubTask] = []
    var attachmentList: [Attachment] = []

    // MARK: - 通过本地模型初始化（本地转网络/业务模型）
    init(from model: TDMacSwiftDataListModel) {
        self.id = model.id
        self.taskId = model.taskId
        self.taskContent = model.taskContent
        self.taskDescribe = model.taskDescribe
        self.complete = model.complete
        self.createTime = model.createTime
        self.delete = model.delete
        self.reminderTime = model.reminderTime
        self.snowAdd = model.snowAdd
        self.snowAssess = model.snowAssess
        self.standbyInt1 = model.standbyInt1
        self.standbyStr1 = model.standbyStr1
        self.standbyStr2 = model.standbyStr2
        self.standbyStr3 = model.standbyStr3
        self.standbyStr4 = model.standbyStr4
        self.syncTime = model.syncTime
        self.taskSort = model.taskSort
        self.todoTime = model.todoTime
        self.userId = model.userId
        self.version = model.version
        self.status = model.status
        self.number = model.number
        self.isSubOpen = model.isSubOpen
        self.standbyIntColor = model.standbyIntColor
        self.standbyIntName = model.standbyIntName
        self.reminderTimeString = model.reminderTimeString
        self.subTaskList = model.subTaskList.map { sub in
            TDTaskModel.SubTask(isComplete: sub.isComplete, content: sub.content, id: sub.id)
        }
        self.attachmentList = model.attachmentList.map { att in
            TDTaskModel.Attachment(
                size: att.size,
                suffix: att.suffix,
                url: att.url,
                name: att.name
            )
        }
    }

    // MARK: - 网络模型转本地模型（含所有业务字段处理）
    @MainActor
    func toSwiftDataModel() -> TDMacSwiftDataListModel {
        var processedModel = self
        processedModel.processAllData()
        let model = TDMacSwiftDataListModel(
            id: processedModel.id,
            taskId: processedModel.taskId,
            taskContent: processedModel.taskContent ?? "",
            taskDescribe: processedModel.taskDescribe,
            complete: processedModel.complete,
            createTime: processedModel.createTime,
            delete: processedModel.delete,
            reminderTime: processedModel.reminderTime,
            snowAdd: processedModel.snowAdd,
            snowAssess: processedModel.snowAssess,
            standbyInt1: processedModel.standbyInt1,
            standbyStr1: processedModel.standbyStr1,
            standbyStr2: processedModel.standbyStr2,
            standbyStr3: processedModel.standbyStr3,
            standbyStr4: processedModel.standbyStr4,
            syncTime: processedModel.syncTime,
            taskSort: processedModel.taskSort,
            todoTime: processedModel.todoTime,
            userId: processedModel.userId,
            version: processedModel.version,
            status: processedModel.status,
            isSubOpen: processedModel.isSubOpen
        )
        model.number = processedModel.number
        model.standbyIntColor = processedModel.standbyIntColor
        model.standbyIntName = processedModel.standbyIntName
        model.reminderTimeString = processedModel.reminderTimeString
        model.subTaskList = processedModel.subTaskList.map { subTask in
            TDMacSwiftDataListModel.SubTask(
                isComplete: subTask.isComplete ?? false,
                content: subTask.content ?? "",
                id: subTask.id
            )
        }
        model.attachmentList = processedModel.attachmentList.map { att in
            TDMacSwiftDataListModel.Attachment(
                name: att.name,
                size: att.size,
                suffix: att.suffix,
                url: att.url
            )
        }
        return model
    }

    // MARK: - 解析和业务处理方法
    /// 处理所有业务字段（提醒时间、分类、子任务、附件）
    @MainActor
    mutating func processAllData() {
        processReminderTime()
        processCategoryInfo()
        processSubTasks()
        processAttachments()
    }
    /// 处理提醒时间字符串
    mutating func processReminderTime() {
        if reminderTime > 0 {
            let date = Date.fromTimestamp(reminderTime)
            reminderTimeString = date.toString(format: "time_format_hour_minute".localized)
        }
    }
    /// 处理分类信息
    @MainActor
    mutating func processCategoryInfo() {
        if let category = TDCategoryManager.shared.getCategory(id: standbyInt1) {
            standbyIntColor = category.categoryColor ?? ""
            standbyIntName = category.categoryName
        } else {
            standbyIntColor = TDThemeManager.shared.borderColor.toHexString()
            standbyIntName = "uncategorized".localized
        }
    }
    /// 处理子任务数据
    mutating func processSubTasks() {
        guard let subTasksJson = standbyStr2,
              !subTasksJson.isEmpty,
              subTasksJson != "null" else {
            subTaskList = []
            return
        }
        subTaskList = parseSubTasks(subTasksJson, parentComplete: complete)
    }
    /// 解析子任务字符串
    private func parseSubTasks(_ subTasksString: String, parentComplete: Bool) -> [SubTask] {
        let subTasks = subTasksString.components(separatedBy: "[end] -")
        return subTasks.compactMap { subTaskString in
            let trimmed = subTaskString.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            
            // 先处理复选框标识，无论父任务是否完成
            var content = trimmed
            if trimmed.contains("- [x]") {
                content = trimmed.replacingOccurrences(of: "- [x]", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if trimmed.contains("- [ ]") {
                content = trimmed.replacingOccurrences(of: "- [ ]", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
            
            if parentComplete {
                print("🔍 父任务完成，子任务content: '\(content)'")
                return SubTask(isComplete: true, content: content)
            }
            
            // 根据原始字符串判断完成状态
            if trimmed.contains("- [x]") {
                print("🔍 已完成子任务content: '\(content)'")
                return SubTask(isComplete: true, content: content)
            } else if trimmed.contains("- [ ]") {
                print("🔍 未完成子任务content: '\(content)'")
                return SubTask(isComplete: false, content: content)
            }
            return nil
        }
    }
    /// 处理附件数据
    mutating func processAttachments() {
        guard let attachmentsJson = standbyStr4,
              !attachmentsJson.isEmpty,
              attachmentsJson != "null" else {
            attachmentList = []
            return
        }
        var jsonString = attachmentsJson
        if jsonString.hasPrefix("\"") && jsonString.hasSuffix("\"") {
            jsonString = String(jsonString.dropFirst().dropLast())
        }
        jsonString = jsonString.replacingOccurrences(of: "\\\"", with: "\"")
        guard let data = jsonString.data(using: .utf8) else {
            print("附件数据转换失败")
            attachmentList = []
            return
        }
        do {
            attachmentList = try JSONDecoder().decode([Attachment].self, from: data)
        } catch {
            print("解析附件数据失败: \(error)")
            print("原始数据: \(jsonString)")
            attachmentList = []
        }
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, taskId, taskContent, taskDescribe, complete, isComplete, createTime, delete
        case reminderTime, snowAdd, snowAssess, standbyInt1, standbyStr1
        case standbyStr2, standbyStr3, standbyStr4, syncTime, taskSort
        case todoTime, userId, version
        case status, number, isSubOpen, standbyIntColor, standbyIntName
        case reminderTimeString, subTaskList, attachmentList
    }
    /// 编码给服务器：不包含 id，complete 以 isComplete 键输出
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(taskId, forKey: .taskId)
        try container.encodeIfPresent(taskContent, forKey: .taskContent)
        try container.encodeIfPresent(taskDescribe, forKey: .taskDescribe)
        try container.encode(complete, forKey: .isComplete)
        try container.encode(createTime, forKey: .createTime)
        try container.encode(delete, forKey: .delete)
        try container.encode(reminderTime, forKey: .reminderTime)
        try container.encode(snowAdd, forKey: .snowAdd)
        try container.encode(snowAssess, forKey: .snowAssess)
        try container.encode(standbyInt1, forKey: .standbyInt1)
        try container.encodeIfPresent(standbyStr1, forKey: .standbyStr1)
        try container.encodeIfPresent(standbyStr2, forKey: .standbyStr2)
        try container.encodeIfPresent(standbyStr3, forKey: .standbyStr3)
        try container.encodeIfPresent(standbyStr4, forKey: .standbyStr4)
        try container.encode(syncTime, forKey: .syncTime)
        try container.encode(taskSort, forKey: .taskSort)
        try container.encode(todoTime, forKey: .todoTime)
        try container.encode(userId, forKey: .userId)
        try container.encode(version, forKey: .version)
        try container.encode(status, forKey: .status)
        try container.encode(number, forKey: .number)
        try container.encode(isSubOpen, forKey: .isSubOpen)
        try container.encode(standbyIntColor, forKey: .standbyIntColor)
        try container.encode(standbyIntName, forKey: .standbyIntName)
        try container.encode(reminderTimeString, forKey: .reminderTimeString)
        try container.encode(subTaskList, forKey: .subTaskList)
        try container.encode(attachmentList, forKey: .attachmentList)
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
        taskId = try container.decode(String.self, forKey: .taskId)
        taskContent = try container.decodeIfPresent(String.self, forKey: .taskContent)
        taskDescribe = try container.decodeIfPresent(String.self, forKey: .taskDescribe)
        if let c = try? container.decode(Bool.self, forKey: .complete) {
            complete = c
        } else {
            complete = try container.decode(Bool.self, forKey: .isComplete)
        }
        createTime = try container.decode(Int64.self, forKey: .createTime)
        delete = try container.decode(Bool.self, forKey: .delete)
        reminderTime = try container.decode(Int64.self, forKey: .reminderTime)
        snowAdd = try container.decode(Int.self, forKey: .snowAdd)
        snowAssess = try container.decode(Int.self, forKey: .snowAssess)
        standbyInt1 = try container.decode(Int.self, forKey: .standbyInt1)
        standbyStr1 = try container.decodeIfPresent(String.self, forKey: .standbyStr1)
        standbyStr2 = try container.decodeIfPresent(String.self, forKey: .standbyStr2)
        standbyStr3 = try container.decodeIfPresent(String.self, forKey: .standbyStr3)
        standbyStr4 = try container.decodeIfPresent(String.self, forKey: .standbyStr4)
        syncTime = try container.decode(Int64.self, forKey: .syncTime)
        taskSort = try container.decode(Decimal.self, forKey: .taskSort)
        todoTime = try container.decode(Int64.self, forKey: .todoTime)
        userId = try container.decode(Int.self, forKey: .userId)
        version = try container.decode(Int64.self, forKey: .version)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "sync"
        number = try container.decodeIfPresent(Int.self, forKey: .number) ?? 1
        isSubOpen = try container.decodeIfPresent(Bool.self, forKey: .isSubOpen) ?? true
        standbyIntColor = try container.decodeIfPresent(String.self, forKey: .standbyIntColor) ?? ""
        standbyIntName = try container.decodeIfPresent(String.self, forKey: .standbyIntName) ?? ""
        reminderTimeString = try container.decodeIfPresent(String.self, forKey: .reminderTimeString) ?? ""
        subTaskList = try container.decodeIfPresent([SubTask].self, forKey: .subTaskList) ?? []
        attachmentList = try container.decodeIfPresent([Attachment].self, forKey: .attachmentList) ?? []
    }
}

// 推送数据后返回的数据
struct TDTaskSyncResultModel: Codable {
    var succeed: Bool
    var version: Int64
    var taskId: String
}
