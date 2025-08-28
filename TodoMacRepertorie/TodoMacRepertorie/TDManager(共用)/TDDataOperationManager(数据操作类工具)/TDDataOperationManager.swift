import Foundation
import AppKit

/// 数据操作管理类
/// 提供各种数据操作功能，如复制、导出等
class TDDataOperationManager {
    
    // MARK: - 单例
    static let shared = TDDataOperationManager()
    
    private init() {}
    
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
