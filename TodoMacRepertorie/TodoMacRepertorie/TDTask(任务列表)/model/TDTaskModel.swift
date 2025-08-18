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
        var isComplete: Bool?
        var content: String?
    }
    
    // MARK: - 附件结构体
    struct Attachment: Codable {
        // 服务器返回字段
        let size: String      // 附件大小，字符串类型
        let suffix: String?   // 文件后缀，可选
        let url: String       // 附件URL
        let name: String      // 附件名称
        
        // 本地字段
        var downloading: Bool = false
        
        /// 是否为图片类型
        var isPhoto: Bool {
            guard let suffix = suffix else { return true }
            return ["jpg", "jpeg", "png", "gif", "heic", "webp"].contains(suffix.lowercased())
        }
        
        enum CodingKeys: String, CodingKey {
            case size, suffix, url, name
        }

        /// 普通初始化方法
        init(size: String, suffix: String?, url: String, name: String) {
            self.size = size
            self.suffix = suffix
            self.url = url
            self.name = name
        }
        
        /// 自定义解码方法，兼容 size 字段为字符串或数字
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
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
            TDTaskModel.SubTask(isComplete: sub.isComplete, content: sub.content)
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
                content: subTask.content ?? ""
            )
        }
        model.attachmentList = processedModel.attachmentList.map { att in
            TDMacSwiftDataListModel.Attachment(
                downloading: att.downloading,
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
            let date = Date(timeIntervalSince1970: TimeInterval(reminderTime / 1000))
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            reminderTimeString = formatter.string(from: date)
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
            if parentComplete {
                return SubTask(isComplete: true, content: trimmed)
            }
            if trimmed.contains("- [x]") {
                let content = trimmed.replacingOccurrences(of: "- [x]", with: "")
                    .trimmingCharacters(in: .whitespaces)
                return SubTask(isComplete: true, content: content)
            } else if trimmed.contains("- [ ]") {
                let content = trimmed.replacingOccurrences(of: "- [ ]", with: "")
                    .trimmingCharacters(in: .whitespaces)
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
        case id, taskId, taskContent, taskDescribe, complete, createTime, delete
        case reminderTime, snowAdd, snowAssess, standbyInt1, standbyStr1
        case standbyStr2, standbyStr3, standbyStr4, syncTime, taskSort
        case todoTime, userId, version
        case status, number, isSubOpen, standbyIntColor, standbyIntName
        case reminderTimeString, subTaskList, attachmentList
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        taskId = try container.decode(String.self, forKey: .taskId)
        taskContent = try container.decodeIfPresent(String.self, forKey: .taskContent)
        taskDescribe = try container.decodeIfPresent(String.self, forKey: .taskDescribe)
        complete = try container.decode(Bool.self, forKey: .complete)
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
