//
//  TDMacHandyJsonListModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI

/// 任务模型（用于网络传输）
struct TDTaskModel: Codable {
    // MARK: - 子任务结构体
    struct SubTask: Codable {
        var isComplete: Bool?
        var content: String?
    }
    
    // MARK: - 附件结构体
    struct Attachment: Codable {
        // 服务器返回字段
        let size: String      // 改为 String 类型
        let suffix: String?  // 改为可选类型
        let url: String
        let name: String
        
        // 本地字段
        var downloading: Bool = false
        
        var isPhoto: Bool {
            guard let suffix = suffix else { return true }
            return ["jpg", "jpeg", "png", "gif", "heic", "webp"].contains(suffix.lowercased())
        }
        
        enum CodingKeys: String, CodingKey {
            case size, suffix, url, name
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // 处理 size 字段的两种可能类型
            if let sizeString = try? container.decode(String.self, forKey: .size) {
                size = sizeString
            } else if let sizeNumber = try? container.decode(Double.self, forKey: .size) {
                size = String(format: "%.8f", sizeNumber)
            } else {
                size = "0"
                print("无法解析 size 字段")
            }
            
            // suffix 字段可能不存在
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
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, taskId, taskContent, taskDescribe, complete, createTime, delete
        case reminderTime, snowAdd, snowAssess, standbyInt1, standbyStr1
        case standbyStr2, standbyStr3, standbyStr4, syncTime, taskSort
        case todoTime, userId, version
    }
    // MARK: - 数据处理方法
    
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
        // 从分类管理器获取分类信息
        if let category = TDCategoryManager.shared.getCategory(id: standbyInt1) {
            standbyIntColor = category.categoryColor ?? ""
            standbyIntName = category.categoryName
        }
        
        // 从分类管理器获取分类信息
                if let category = TDCategoryManager.shared.getCategory(id: standbyInt1) {
                    standbyIntColor = category.categoryColor ?? ""
                    standbyIntName = category.categoryName
                } else {
                    // 如果查不到分类信息，使用默认值
                    
                    standbyIntColor =  TDThemeManager.shared.borderColor.toHexString()
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
        
        // 解析子任务
        subTaskList = parseSubTasks(subTasksJson, parentComplete: complete)
    }
        
    /// 解析子任务字符串
    private func parseSubTasks(_ subTasksString: String, parentComplete: Bool) -> [SubTask] {
        // 使用 [end] - 作为分隔符拆分子任务
        let subTasks = subTasksString.components(separatedBy: "[end] -")
        
        return subTasks.compactMap { subTaskString in
            // 去除首尾空白字符
            let trimmed = subTaskString.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            
            // 如果父任务已完成，所有子任务都标记为完成
            if parentComplete {
                return SubTask(isComplete: true, content: trimmed)
            }
            
            // 检查任务完成状态标记
            if trimmed.contains("- [x]") {
                // 已完成的任务
                let content = trimmed.replacingOccurrences(of: "- [x]", with: "")
                    .trimmingCharacters(in: .whitespaces)
                return SubTask(isComplete: true, content: content)
            } else if trimmed.contains("- [ ]") {
                // 未完成的任务
                let content = trimmed.replacingOccurrences(of: "- [ ]", with: "")
                    .trimmingCharacters(in: .whitespaces)
                return SubTask(isComplete: false, content: content)
            }
            
            // 如果没有有效的标记，返回 nil
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
        
        // 尝试修复 JSON 格式
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
    /// 处理所有数据
    @MainActor mutating func processAllData() {
        processReminderTime()
        processCategoryInfo()
        processSubTasks()
        processAttachments()
    }
    
    /// 转换为 SwiftData 模型
    @MainActor func toSwiftDataModel() -> TDMacSwiftDataListModel {
        // 处理所有数据
        var processedModel = self
        processedModel.processAllData()
        
        // 创建 SwiftData 模型
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
        
        // 直接赋值已处理好的字段
        model.number = processedModel.number
        model.standbyIntColor = processedModel.standbyIntColor
        model.standbyIntName = processedModel.standbyIntName
        model.reminderTimeString = processedModel.reminderTimeString
        // 转换子任务列表
        model.subTaskList = processedModel.subTaskList.map { subTask in
            TDMacSwiftDataListModel.SubTask(
                isComplete: subTask.isComplete ?? false,
                content: subTask.content ?? ""
            )
        }
        
        // 转换附件列表
        model.attachmentList = processedModel.attachmentList.map { attachment in
            TDMacSwiftDataListModel.Attachment(
                downloading: attachment.downloading,
                name: attachment.name ,
                size: attachment.size,
                suffix: attachment.suffix ?? "" ,
                url: attachment.url
            )
        }
        return model
    }
    
}
//
///// 用于网络数据解析的待办事项模型
//class TDMacHandyJsonListModel: HandyJSON {
//    /// 用户ID
//    var userId: Int?
//
//    /// 事件的唯一编号，由userID、时间戳、32位随机字符串组成。长度大概在100以内
//    var taskId: String?
//
//    /// 本地创建事件的时间，由客户端本地时间提供。时间戳（毫秒）
//    var createTime: Int64?
//
//    /// 事件状态：add(新增), delete(删除), update(更新), sync(同步)
//    var status: String?
//
//    /// 事件排序权重
//    var taskSort: Double?
//
//    /// 事件的服务器同步时间（毫秒）
//    var createServerTime: Int64?
//
//    /// 本地事件同步记录的相对整数型时间戳，当sync状态的数据被更改时需要+1
//    var version: Int64?
//
//    /// 最后一次同步成功的时间，由服务器提供（毫秒）
//    var syncLocalTime: Int64?
//
//    /// 本地修改时间，用于同步合并数据时解决冲突（毫秒）
//    var syncTime: Int64?
//
//    /// 事件的日期，精确到毫秒级别
//    var todoTime: Int64?
//
//    /// 事件是否完成
//    var complete: Bool?
//
//    /// 事件内容，长度一般在200位以内
//    var taskContent: String?
//
//    /// 事件描述，长度一般在250位以内
//    var taskDescribe: String?
//
//    /// 事件工作量，值一般为0-10
//    var snowAssess: Int?
//
//    /// 事件提醒的时间（毫秒）
//    var reminderTime: Int64?
//
//    /// 重复事件组ID，重复事件组的唯一标识字符串，长度大概在100位以内
//    var standbyStr1: String?
//
//    /// 子任务列表
//    var standbyStr2: String?
//
//    /// 事件图片
//    var standbyStr3: String?
//
//    /// 附件数据
//    var standbyStr4: String?
//
//    /// 自定义清单 categoryId
//    var standbyInt1: Int?
//
//    /// 所属清单颜色
//    var standbyIntColor: String?
//
//    /// 所属清单名字
//    var standbyIntName: String?
//
//    /// 是否是正在删除的任务
//    var delete: Bool?
//
//    /// 子任务是否打开
//    var subIsOpen: Bool?
//
//    /// 是否是系统日历事件
//    var isSystemCalendarData: Bool?
//
//    required init() {}
//
//    func mapping(mapper: HelpingMapper) {
//        // 处理 null 值的映射
//        mapper <<<
//            self.standbyStr1 <-- TransformOf<String, Any>(
//                fromJSON: { (value) -> String? in
//                    if let str = value as? String, str != "<null>" {
//                        return str
//                    }
//                    return nil
//                },
//                toJSON: { $0 }
//            )
//
//        mapper <<<
//            self.standbyStr2 <-- TransformOf<String, Any>(
//                fromJSON: { (value) -> String? in
//                    if let str = value as? String, str != "<null>" {
//                        return str
//                    }
//                    return nil
//                },
//                toJSON: { $0 }
//            )
//
//        mapper <<<
//            self.standbyStr3 <-- TransformOf<String, Any>(
//                fromJSON: { (value) -> String? in
//                    if let str = value as? String, str != "<null>" {
//                        return str
//                    }
//                    return nil
//                },
//                toJSON: { $0 }
//            )
//
//        mapper <<<
//            self.taskDescribe <-- TransformOf<String, Any>(
//                fromJSON: { (value) -> String? in
//                    if let str = value as? String, str != "<null>" {
//                        return str
//                    }
//                    return nil
//                },
//                toJSON: { $0 }
//            )
//    }
//
//
//    /// 将 HandyJSON 模型转换为 SwiftData 模型
//    func toSwiftDataModel() -> TDMacSwiftDataListModel {
//        let model = TDMacSwiftDataListModel(
//            userId: (userId ?? TDUserManager.shared.userId) ?? 0,
//            taskId: taskId ?? UUID().uuidString,
//            createTime: createTime ?? Int64(Date().timeIntervalSince1970 * 1000),
//            status: status ?? "add",
//            taskSort: taskSort ?? 5000.0,
//            createServerTime: createServerTime,
//            version: version,
//            syncLocalTime: syncLocalTime,
//            syncTime: syncTime,
//            todoTime: todoTime,
//            complete: complete ?? false,
//            taskContent: taskContent ?? "",
//            taskDescribe: taskDescribe,
//            snowAssess: snowAssess,
//            reminderTime: reminderTime,
//            standbyStr1: standbyStr1,
//            standbyStr2: standbyStr2,
//            standbyStr3: standbyStr3,
//            standbyStr4: standbyStr4,
//            standbyInt1: standbyInt1,
//            standbyIntColor: standbyIntColor,
//            standbyIntName: standbyIntName,
//            delete: delete ?? false,
//            subIsOpen: subIsOpen ?? false,
//            isSystemCalendarData: isSystemCalendarData ?? false
//        )
//        return model
//    }
//}
