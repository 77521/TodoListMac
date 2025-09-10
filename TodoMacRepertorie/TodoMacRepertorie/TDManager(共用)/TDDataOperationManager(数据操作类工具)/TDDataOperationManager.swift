import Foundation
import AppKit

/// 数据操作管理类
/// 提供各种数据操作功能，如复制、导出等
class TDDataOperationManager {
    
    // MARK: - 单例
    static let shared = TDDataOperationManager()
    
    private init() {}
    
    // MARK: - 枚举定义
    
    /// 复制类型枚举 - 定义创建副本的不同方式
    enum CopyType {
        case normal        // 创建副本 - 保持原日期
        case toToday      // 创建副本到今天
        case toSpecificDate // 创建副本到指定日期
    }
    
    /// 删除类型枚举 - 定义不同的删除方式
    enum DeleteType {
        case single      // 仅删除该事件
        case all         // 删除该重复事件组的全部事件
        case incomplete  // 删除该重复事件组的全部未达成事件
    }
    

    /// 自定义重复类型枚举 - 定义各种重复模式
    enum CustomRepeatType: String, CaseIterable {
        case daily = "每天"                    // 每天重复
        case weekly = "每周"                  // 每周重复
        case workday = "每周工作日"            // 每周工作日重复
        case monthly = "每月"                 // 每月重复
        case monthlyLastDay = "每月最后一天"    // 每月最后一天重复
        case monthlyWeekday = "每月星期几"      // 每月第N个星期几重复
        case yearly = "每年"                  // 每年重复
        case lunarYearly = "每年农历"          // 每年农历重复
        case legalWorkday = "法定工作日"        // 法定工作日重复
        case ebbinghaus = "艾宾浩斯记忆法"      // 艾宾浩斯记忆法重复
    }
    
    /// 修改重复事件类型枚举 - 定义不同的修改方式
    enum ModifyType {
        case all         // 修改该重复事件组的全部事件
        case incomplete  // 修改该重复事件组的全部未达成事件
    }

    
    // MARK: - 复制功能
    
    /// 将选中的任务内容复制到剪贴板
    /// - Parameter tasks: 要复制的任务数组
    /// - Returns: 是否复制成功
    @discardableResult
    func copyTasksToClipboard(_ tasks: [TDMacSwiftDataListModel]) -> Bool {
        // 格式化选中的任务内容
        let formattedContent = formatTasksForClipboard(tasks)
        
        // 复制到剪贴板
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(formattedContent, forType: .string)
        
        print("✅ 已复制 \(tasks.count) 个任务到剪贴板")
        return true
    }
    
    /// 格式化任务内容用于剪贴板
    /// - Parameter tasks: 要格式化的任务数组
    /// - Returns: 格式化后的字符串
    private func formatTasksForClipboard(_ tasks: [TDMacSwiftDataListModel]) -> String {
        var formattedLines: [String] = []
        
        for task in tasks {
            // 添加任务标题
            formattedLines.append(task.taskContent)
            
            // 添加任务描述（如果有）
            if let description = task.taskDescribe, !description.isEmpty {
                formattedLines.append(description)
            }
            
            // 添加子任务（如果有）
            if !task.subTaskList.isEmpty {
                for subTask in task.subTaskList {
                    let subTaskPrefix = subTask.isComplete ? "√" : " "
                    formattedLines.append("[\(subTaskPrefix)] \(subTask.content)")
                }
            }
            
            // 每个任务之间添加一个空行（除了最后一个任务）
            if task != tasks.last {
                formattedLines.append("")
            }
        }
        
        return formattedLines.joined(separator: "\n")
    }
    
    // MARK: - 导出功能（预留）
    
    /// 导出任务为文本文件
    /// - Parameters:
    ///   - tasks: 要导出的任务数组
    ///   - fileURL: 保存的文件URL
    /// - Returns: 是否导出成功
    @discardableResult
    func exportTasksToTextFile(_ tasks: [TDMacSwiftDataListModel], to fileURL: URL) -> Bool {
        let content = formatTasksForClipboard(tasks)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ 已导出 \(tasks.count) 个任务到文件：\(fileURL.path)")
            return true
        } catch {
            print("❌ 导出任务失败：\(error)")
            return false
        }
    }
    
    // MARK: - 数据验证功能（预留）
    
}
