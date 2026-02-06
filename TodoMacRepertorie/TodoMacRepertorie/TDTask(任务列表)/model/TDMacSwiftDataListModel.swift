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
    struct SubTask: Codable, Equatable {
        let id: String
        var isComplete: Bool
        var content: String
        
        init(isComplete: Bool, content: String, id: String? = nil) {
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
            
            self.isComplete = try container.decode(Bool.self, forKey: .isComplete)
            self.content = try container.decode(String.self, forKey: .content)
        }
        
        // 编码时总是包含 id
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(isComplete, forKey: .isComplete)
            try container.encode(content, forKey: .content)
        }
        
        private enum CodingKeys: String, CodingKey {
            case id, isComplete, content
        }
    }

    // MARK: - 附件结构体
       struct Attachment: Codable, Equatable {
           let id: String        // 添加唯一ID
           var name: String
           let size: String      // 改为 String 类型
           var suffix: String?
           var url: String

           var isPhoto: Bool {
               guard let suffix = suffix else { return true }
               return ["jpg", "jpeg", "png", "gif", "heic", "webp"].contains(suffix.lowercased())
           }
           /// 获取完整的文件名（name + suffix）
           /// - Parameters:
           ///   - name: 文件名
           ///   - suffix: 文件后缀
           /// - Returns: 完整的文件名
           func getFullFileName() -> String {
               if let suffix = suffix, !suffix.isEmpty {
                   return "\(name).\(suffix)"
               } else {
                   return name
               }
           }

           
           /// 普通初始化方法
           init(id: String = UUID().uuidString, name: String, size: String, suffix: String? = nil, url: String) {
               self.id = id
               self.name = name
               self.size = size
               self.suffix = suffix
               self.url = url
           }

           
           
           // MARK: - Codable
           private enum CodingKeys: String, CodingKey {
               case id, name, size, suffix, url
           }

           /// 自定义解码方法，兼容没有ID的旧数据
           init(from decoder: Decoder) throws {
               let container = try decoder.container(keyedBy: CodingKeys.self)
               
               // 处理 ID 字段，如果没有则生成一个
               if let idString = try? container.decode(String.self, forKey: .id) {
                   id = idString
               } else {
                   id = UUID().uuidString
               }
               
               name = try container.decode(String.self, forKey: .name)
               size = try container.decode(String.self, forKey: .size)
               suffix = try container.decodeIfPresent(String.self, forKey: .suffix)
               url = try container.decode(String.self, forKey: .url)
           }

           /// 编码方法
           func encode(to encoder: Encoder) throws {
               var container = encoder.container(keyedBy: CodingKeys.self)
               try container.encode(id, forKey: .id)
               try container.encode(name, forKey: .name)
               try container.encode(size, forKey: .size)
               try container.encodeIfPresent(suffix, forKey: .suffix)
               try container.encode(url, forKey: .url)
           }

       }
    
    // MARK: - 服务器字段
    // MARK: - 索引配置（提升查询和排序性能）
//    @Attribute(.unique) var id: Int64
//    @Attribute(.spotlight) var userId: Int
//    @Attribute(.unique) var taskId: String
//    @Attribute(.spotlight) var complete: Bool
//    @Attribute(.spotlight) var delete: Bool
//    @Attribute(.spotlight) var todoTime: Int64
//    @Attribute(.spotlight) var taskSort: Decimal
//    @Attribute(.spotlight) var standbyInt1: Int
//    @Attribute(.spotlight) var createTime: Int64
//    @Attribute(.spotlight) var syncTime: Int64
//    @Attribute(.spotlight) var snowAssess: Int
//    @Attribute(.spotlight) var standbyStr1: String?
//    @Attribute(.spotlight) var version: Int64
//    @Attribute(.spotlight) var taskContent: String
//    @Attribute(.spotlight) var taskDescribe: String?
//    @Attribute(.spotlight) var standbyStr2: String?

    // MARK: - 索引配置（提升查询和排序性能）
    var id: Int64
    var userId: Int
    var taskId: String
     var complete: Bool
     var delete: Bool
     var todoTime: Int64
     var taskSort: Decimal
     var standbyInt1: Int
     var createTime: Int64
     var syncTime: Int64
     var snowAssess: Int
     var standbyStr1: String?
     var version: Int64
     var taskContent: String
     var taskDescribe: String?
     var standbyStr2: String?

    
    var reminderTime: Int64
    var snowAdd: Int
    var standbyStr3: String?
    var standbyStr4: String?
    
    var status: String = "sync"
    var isSubOpen: Bool = true
    var standbyIntColor: String = ""
    var standbyIntName: String = ""
    var reminderTimeString: String = ""
    var subTaskList: [SubTask] = []
    var attachmentList: [Attachment] = []
    
    // MARK: - 本地字段
    // 运行时属性，不保存到数据库
    @Transient var isSystemCalendarEvent: Bool = false
    @Transient var number: Int = 1

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
        isSubOpen: Bool = true,
        // 本地字段
        standbyIntColor: String = "",
        standbyIntName: String = "",
        reminderTimeString: String = "",
        subTaskList: [SubTask] = [],
        attachmentList: [Attachment] = []
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
        // 初始化本地字段
        self.standbyIntColor = standbyIntColor
        self.standbyIntName = standbyIntName
        self.reminderTimeString = reminderTimeString
        self.subTaskList = subTaskList
        self.attachmentList = attachmentList

    }
    /// 难度等级颜色
    var difficultyColor: Color {
        if snowAssess < 5 {
            return .clear // 一般
        } else if snowAssess < 9 {
            return TDThemeManager.shared.fixedColor(themeId: "wish_orange", level: 6) // 心想事橙，6级
        } else {
            return TDThemeManager.shared.fixedColor(themeId: "new_year_red", level: 6) // 新年红，6级
        }
    }
    
    /// 是否有提醒时间
    var hasReminder: Bool {
        return reminderTime > 0
    }
    
    
    /// 是否有重复设置
    var hasRepeat: Bool {
        return !(standbyStr1?.isEmpty ?? true)
    }
    
    /// 是否有附件
    var hasAttachment: Bool {
        return !(standbyStr4?.isEmpty ?? true)
    }
    
    /// 是否有子任务
    var hasSubTasks: Bool {
        return !(standbyStr2?.isEmpty ?? true)
    }

    
    /// 根据 todotime 转换日期显示（今天、明天、后天返回空，否则判断是否今年）
    var taskDateConditionalString: String {
        // 无日期的情况
        if todoTime == 0 {
            return "no_date".localized
        }
        
        let taskDate = Date.fromTimestamp(todoTime)
        
        // 如果是今天、明天、后天，返回空字符串
        if taskDate.isToday || taskDate.isTomorrow || taskDate.isDayAfterTomorrow {
            return ""
        } else {
            // 否则返回根据年份的日期显示
            return taskDate.formattedString
        }
    }
        
    /// 根据 todotime 判断是否今年，显示月日或年月日（包含无日期判断）
    var taskDateByYearWithNoDateString: String {
        // 无日期的情况
        if todoTime == 0 {
            return "no_date".localized
        }
        
        let taskDate = Date.fromTimestamp(todoTime)
        return taskDate.formattedString
    }

    /// 根据 todotime 获取日期显示颜色
    var taskDateColor: Color {
        // 无日期的情况
        if todoTime == 0 {
            return TDThemeManager.shared.descriptionTextColor // 描述颜色
        }
        
        let taskDate = Date.fromTimestamp(todoTime)
        
        // 已过期
        if taskDate.isOverdue {
            return TDThemeManager.shared.fixedColor(themeId: "new_year_red", level: 6) // 新年红，6级
        }
        
        // 大于后天的情况
        if !taskDate.isToday && !taskDate.isTomorrow && !taskDate.isDayAfterTomorrow {
            return TDThemeManager.shared.descriptionTextColor // 描述颜色
        }
        
        // 今天、明天、后天
        return TDThemeManager.shared.color(level: 5) // 主题色
    }
    /// 获取任务标题显示颜色
    var taskTitleColor: Color {
        if complete {
            return TDThemeManager.shared.descriptionTextColor // 已完成显示描述颜色
        } else {
            return TDThemeManager.shared.titleTextColor // 未完成显示标题颜色
        }
    }
    /// 获取任务标题是否显示删除线
    var taskTitleStrikethrough: Bool {
        if !complete {
            return false // 未完成肯定不显示删除线
        } else {
            return TDSettingManager.shared.showCompletedTaskStrikethrough // 已完成根据设置决定
        }
    }
    /// 获取任务描述是否显示
    var shouldShowTaskDescription: Bool {
        // 如果设置内设置了不显示，就算描述有值，也不显示
//        guard TDSettingManager.shared.showTaskDescription else {
//            return false
//        }
        // 如果设置内设置显示，但是本身描述为空，也不显示
        return !(taskDescribe?.isEmpty ?? true)
    }
    /// 获取选中框颜色
    var checkboxColor: Color {
        if TDSettingManager.shared.checkboxFollowCategoryColor && standbyInt1 > 0 {
            // 如果设置跟随分类颜色且任务有分类，显示分类颜色
            return Color.fromHex(standbyIntColor)
        } else {
            // 否则显示主题颜色描述颜色
            return TDThemeManager.shared.descriptionTextColor
        }
    }
    /// 获取是否显示顺序数字
    var shouldShowOrderNumber: Bool {
        // 注意：该属性会在任务列表滚动时高频调用，禁止在这里打印日志（会导致 CPU 飙升）
        return TDSettingManager.shared.showDayTodoOrderNumber
    }
    
    /// 将子任务数组转换为字符串格式
    func generateSubTasksString() -> String {
        guard !subTaskList.isEmpty else { return "" }
        
        let subTaskStrings = subTaskList.map { subTask in
            let prefix = subTask.isComplete ? "- [x]" : "- [ ]"
            return "\(prefix) \(subTask.content)"
        }
        
        return subTaskStrings.joined(separator: "[end] -")
    }
    
    /// 将附件数组转换为 JSON 字符串
    func generateAttachmentListString() -> String {
        guard !attachmentList.isEmpty else { return "" }
        
        return TDSwiftJsonUtil.arrayToJson(attachmentList) ?? ""
    }
    
    /// 检查是否所有子任务都已完成
    var allSubTasksCompleted: Bool {
        return !subTaskList.isEmpty && subTaskList.allSatisfy { $0.isComplete }
    }

    /// 检查任务日期是否是今天
    var isToday: Bool {
        guard todoTime > 0 else { return false }
        let taskDate = Date.fromTimestamp(todoTime)
        return taskDate.isToday
    }
    /// 获取任务的日期
    var taskDate: Date {
        guard todoTime > 0 else { return Date() }
        return Date.fromTimestamp(todoTime)
    }

}
