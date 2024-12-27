//
//  TDMacHandleListModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/23.
//

import Foundation
import HandyJSON

/// 用于网络数据解析的待办事项模型
class TDMacHandyJsonListModel: HandyJSON {
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
    var complete: Bool?
    
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
    
    /// 子任务列表
    var standbyStr2: String?
    
    /// 事件图片
    var standbyStr3: String?
    
    /// 附件数据
    var standbyStr4: String?
    
    /// 自定义清单 categoryId
    var standbyInt1: Int?
    
    /// 所属清单颜色
    var standbyIntColor: String?
    
    /// 所属清单名字
    var standbyIntName: String?
    
    /// 是否是正在删除的任务
    var delete: Bool?
    
    /// 子任务是否打开
    var subIsOpen: Bool?
    
    /// 是否是系统日历事件
    var isSystemCalendarData: Bool?
    
    required init() {}
    
    func mapping(mapper: HelpingMapper) {
        // 处理 null 值的映射
        mapper <<<
            self.standbyStr1 <-- TransformOf<String, Any>(
                fromJSON: { (value) -> String? in
                    if let str = value as? String, str != "<null>" {
                        return str
                    }
                    return nil
                },
                toJSON: { $0 }
            )
        
        mapper <<<
            self.standbyStr2 <-- TransformOf<String, Any>(
                fromJSON: { (value) -> String? in
                    if let str = value as? String, str != "<null>" {
                        return str
                    }
                    return nil
                },
                toJSON: { $0 }
            )
        
        mapper <<<
            self.standbyStr3 <-- TransformOf<String, Any>(
                fromJSON: { (value) -> String? in
                    if let str = value as? String, str != "<null>" {
                        return str
                    }
                    return nil
                },
                toJSON: { $0 }
            )
        
        mapper <<<
            self.taskDescribe <-- TransformOf<String, Any>(
                fromJSON: { (value) -> String? in
                    if let str = value as? String, str != "<null>" {
                        return str
                    }
                    return nil
                },
                toJSON: { $0 }
            )
    }

    
    /// 将 HandyJSON 模型转换为 SwiftData 模型
    func toSwiftDataModel() -> TDMacSwiftDataListModel {
        let model = TDMacSwiftDataListModel(
            userId: (userId ?? TDUserManager.shared.userId) ?? 0,
            taskId: taskId ?? UUID().uuidString,
            createTime: createTime ?? Int64(Date().timeIntervalSince1970 * 1000),
            status: status ?? "add",
            taskSort: taskSort ?? 5000.0,
            createServerTime: createServerTime,
            version: version,
            syncLocalTime: syncLocalTime,
            syncTime: syncTime,
            todoTime: todoTime,
            complete: complete ?? false,
            taskContent: taskContent ?? "",
            taskDescribe: taskDescribe,
            snowAssess: snowAssess,
            reminderTime: reminderTime,
            standbyStr1: standbyStr1,
            standbyStr2: standbyStr2,
            standbyStr3: standbyStr3,
            standbyStr4: standbyStr4,
            standbyInt1: standbyInt1,
            standbyIntColor: standbyIntColor,
            standbyIntName: standbyIntName,
            delete: delete ?? false,
            subIsOpen: subIsOpen ?? false,
            isSystemCalendarData: isSystemCalendarData ?? false
        )
        return model
    }
}
