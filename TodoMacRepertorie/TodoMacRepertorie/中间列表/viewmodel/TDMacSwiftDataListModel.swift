//
//  TDMacSwiftDataListModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/19.
//

import Foundation
import SwiftUI
import SwiftData
import HandyJSON

@Model
final class TDMacSwiftDataListModel {
    /// 用户ID
    var userId: Int?
    
    /// 事件的唯一编号，由userID、时间戳、32位随机字符串组成。长度大概在100以内
    var taskId: String?
    
    /// 本地创建事件的时间，由客户端本地时间提供。时间戳（毫秒）
    var createTime: Int64?
    
    /// 事件状态：add(新增), delete(删除), update(更新), sync(同步)
    var status: String?
    
    /// 事件排序权重
    var taskSort: Double?
    
    /// 事件的服务器同步时间（毫秒）
    var createServerTime: Int64?
    
    /// 本地事件同步记录的相对整数型时间戳，当sync状态的数据被更改时需要+1
    var version: Int64?
    
    /// 最后一次同步成功的时间，由服务器提供（毫秒）
    var syncLocalTime: Int64?
    
    /// 本地修改时间，用于同步合并数据时解决冲突（毫秒）
    var syncTime: Int64?
    
    /// 事件的日期，精确到毫秒级别
    var todoTime: Int64?
    
    /// 事件是否完成
    var complete: Bool
    
    /// 事件内容，长度一般在200位以内
    var taskContent: String?
    
    /// 事件描述，长度一般在250位以内
    var taskDescribe: String?
    
    /// 事件工作量，值一般为0-10
    var snowAssess: Int?
    
    /// 事件提醒的时间（毫秒）
    var reminderTime: Int64?
    
    /// 重复事件组ID，重复事件组的唯一标识字符串，长度大概在100位以内
    var standbyStr1: String?
    
    /// 子任务数组
    @Relationship(deleteRule: .cascade) var standbyStr2Arr: [TDSubDataModel]?
    
    /// 子任务列表
    var standbyStr2: String?
    
    /// 事件图片
    var standbyStr3: String?
    
    /// 附件数据
    var standbyStr4: String?
    
    /// 附件数据数组
    @Relationship(deleteRule: .cascade) var standbyStr4Arr: [TDUpLoadFieldModel]?
    
    /// 自定义清单 categoryId
    var standbyInt1: Int?
    
    /// 所属清单颜色
    var standbyIntColor: String?
    
    /// 所属清单名字
    var standbyIntName: String?
    
    /// 是否是正在删除的任务
    var delete: Bool
    
    /// 子任务是否打开
    var subIsOpen: Bool
    
    /// 是否本地日历数据
    var isSystemCalendarData: Bool
    
    init(
        userId: Int = TDUserManager.shared.userId ?? 0,
        taskId: String = UUID().uuidString,
        createTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        status: String = "local",
        taskSort: Double = 0.0,
        createServerTime: Int64? = nil,
        version: Int64? = nil,
        syncLocalTime: Int64? = nil,
        syncTime: Int64? = nil,
        todoTime: Int64? = nil,
        complete: Bool = false,
        taskContent: String = "",
        taskDescribe: String? = nil,
        snowAssess: Int? = nil,
        reminderTime: Int64? = nil,
        standbyStr1: String? = nil,
        standbyStr2: String? = nil,
        standbyStr3: String? = nil,
        standbyStr4: String? = nil,
        standbyInt1: Int? = nil,
        standbyIntColor: String? = nil,
        standbyIntName: String? = nil,
        delete: Bool = false,
        subIsOpen: Bool = false,
        isSystemCalendarData: Bool = false
    ) {
        self.userId = userId
        self.taskId = taskId
        self.createTime = createTime
        self.status = status
        self.taskSort = taskSort
        self.createServerTime = createServerTime
        self.version = version
        self.syncLocalTime = syncLocalTime
        self.syncTime = syncTime
        self.todoTime = todoTime
        self.complete = complete
        self.taskContent = taskContent
        self.taskDescribe = taskDescribe
        self.snowAssess = snowAssess
        self.reminderTime = reminderTime
        self.standbyStr1 = standbyStr1
        self.standbyStr2 = standbyStr2
        self.standbyStr3 = standbyStr3
        self.standbyStr4 = standbyStr4
        self.standbyInt1 = standbyInt1
        self.standbyIntColor = standbyIntColor
        self.standbyIntName = standbyIntName
        self.delete = delete
        self.subIsOpen = subIsOpen
        self.isSystemCalendarData = isSystemCalendarData
        self.standbyStr2Arr = []
        self.standbyStr4Arr = []
        
        // 在 super.init() 之后解析子任务和附件
        if let subTasksString = standbyStr2 {
            self.standbyStr2Arr = parseSubTasks(subTasksString, parentComplete: complete)
        }
        
        if let attachmentsString = standbyStr4 {
            self.standbyStr4Arr = parseAttachments(attachmentsString)
        }
    }
    
    // 解析子任务
    private func parseSubTasks(_ subTasksString: String, parentComplete: Bool) -> [TDSubDataModel] {
        let subTasks = subTasksString.components(separatedBy: "[end] -")
        return subTasks.compactMap { subTaskString in
            let trimmed = subTaskString.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            
            if parentComplete {
                return TDSubDataModel(content: trimmed, complete: true)
            }
            
            if trimmed.contains("-[x]") {
                let content = trimmed.replacingOccurrences(of: "-[x]", with: "").trimmingCharacters(in: .whitespaces)
                return TDSubDataModel(content: content, complete: true)
            } else if trimmed.contains("-[]") {
                let content = trimmed.replacingOccurrences(of: "-[]", with: "").trimmingCharacters(in: .whitespaces)
                return TDSubDataModel(content: content, complete: false)
            }
            
            return nil
        }
    }
    
    // 解析附件
    private func parseAttachments(_ attachmentsString: String) -> [TDUpLoadFieldModel] {
        guard let data = attachmentsString.data(using: .utf8),
              let attachments = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        
        return attachments.compactMap { attachment in
            guard let name = attachment["name"] as? String,
                  let size = attachment["size"] as? String,
                  let suffix = attachment["suffix"] as? String,
                  let url = attachment["url"] as? String else {
                return nil
            }
            
            return TDUpLoadFieldModel(
                name: name,
                size: size,
                suffix: suffix,
                url: url
            )
        }
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

/// 图片 文件
@Model
final class TDUpLoadFieldModel: HandyJSON {
    var name: String            // 文件名
    var size: String           // 文件大小
    var suffix: String         // 文件后缀
    var url: String            // 文件URL
    var isPhoto: Bool          // 是否是图片
    var downloading: Bool       // 是否已下载
    var filePath: String?      // 本地文件路径
    
    // HandyJSON 要求的初始化方法
    required init() {
        self.name = ""
        self.size = ""
        self.suffix = ""
        self.url = ""
        self.isPhoto = false
        self.downloading = false
    }
    
    init(name: String, size: String, suffix: String, url: String) {
        self.name = name
        self.size = size
        self.suffix = suffix
        self.url = url
        self.isPhoto = Self.checkIsPhoto(suffix: suffix)
        self.downloading = false
    }
    
    // 检查是否是图片文件
    private static func checkIsPhoto(suffix: String) -> Bool {
        let photoSuffixes = ["jpg", "jpeg", "png", "gif", "heic", "webp"]
        return photoSuffixes.contains(suffix.lowercased())
    }
}

extension TDMacSwiftDataListModel {
    
    
    /// 获取任务日期显示文本
    var dateDisplayText: String {
        guard let todoTime = todoTime else {
            return ""
        }
        
        return todoTime.toDate.formattedString
    }
}


// MARK: - SwiftData 模型转换扩展
extension TDMacSwiftDataListModel {
    /// 将 SwiftData 模型转换为 HandyJSON 模型
    func toHandyJSONModel() -> TDMacHandyJsonListModel {
        let model = TDMacHandyJsonListModel()
        model.userId = self.userId
        model.taskId = self.taskId
        model.createTime = self.createTime
        model.status = self.status
        model.taskSort = self.taskSort
        model.createServerTime = self.createServerTime
        model.version = self.version
        model.syncLocalTime = self.syncLocalTime
        model.syncTime = self.syncTime
        model.todoTime = self.todoTime
        model.complete = self.complete
        model.taskContent = self.taskContent
        model.taskDescribe = self.taskDescribe
        model.snowAssess = self.snowAssess
        model.reminderTime = self.reminderTime
        model.standbyStr1 = self.standbyStr1
        model.standbyStr2 = self.standbyStr2
        model.standbyStr3 = self.standbyStr3
        model.standbyStr4 = self.standbyStr4
        model.standbyInt1 = self.standbyInt1
        model.standbyIntColor = self.standbyIntColor
        model.standbyIntName = self.standbyIntName
        model.delete = self.delete
        model.subIsOpen = self.subIsOpen
        model.isSystemCalendarData = self.isSystemCalendarData
        return model
    }
}
