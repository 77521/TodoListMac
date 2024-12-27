//
//  TDGetCurrentVersionModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/25.
//

import Foundation
import HandyJSON

struct TDGetCurrentVersionModel : HandyJSON{
    
    var maxVersion : Int64?
    
    init() {
       
   }
}

// 服务器返回的上传结果模型
/// 任务上传结果
struct TDTaskUploadResult: HandyJSON {
    /// 是否成功
    var success: Bool = false
    /// 任务ID
    var taskId: String?
    /// 错误信息
    var message: String?
    
    init() {}
}
/// 任务同步响应
struct TDTaskSyncResponse: HandyJSON {
    /// 同步结果
    var success: Bool = false
    /// 任务列表
    var tasks: [TDMacHandyJsonListModel]?
    /// 错误信息
    var message: String?
    
    init() {}
}

class TDTaskListResponse: HandyJSON {
    var code: Int?
    var msg: String?
    var ret: Int?
    var data: TDTaskListData?
    
    required init() {}
}

class TDTaskListData: HandyJSON {
    var list: [TDMacHandyJsonListModel]?
    
    required init() {}
}
