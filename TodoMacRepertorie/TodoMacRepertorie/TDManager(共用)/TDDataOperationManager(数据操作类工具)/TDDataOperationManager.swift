import Foundation
import AppKit
import SwiftData

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
    /// 日历类型枚举 - 定义公历和农历
    enum CalendarType: String, CaseIterable {
        case gregorian = "公历"
        case lunar = "农历"
        
        var localized: String {
            switch self {
            case .gregorian:
                return "calendar.gregorian".localized
            case .lunar:
                return "calendar.lunar".localized
            }
        }
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
    
    // MARK: - 任务创建相关方法
    
    /// 创建任务（异步方法）
    /// - Parameters:
    ///   - content: 任务内容（会自动清洗）
    ///   - category: 分类清单模型（nil表示未分类）
    ///   - todoTime: 任务日期的时间戳（默认为今天）
    ///   - modelContext: SwiftData 上下文
    ///   - onSuccess: 成功回调（在主线程执行）
    ///   - onError: 失败回调（在主线程执行）
    func createTask(
        content: String,
        category: TDSliderBarModel?,
        todoTime: Int64? = nil,
        modelContext: ModelContext,
        onSuccess: @escaping @MainActor () -> Void,
        onError: @escaping @MainActor () -> Void
    ) {
        // 1) 输入内容清洗（开头去空白；结尾按"标签空格"规则保留/去除）
        let sanitized = content.tdSanitizedTaskInputTitle()
        guard !sanitized.isEmpty else {
            Task { @MainActor in
                onError()
            }
            return
        }

        // 2) 构建最小任务模型（其他字段由 addLocalTask 自动赋值）
        let taskTodoTime = todoTime ?? Date().startOfDayTimestamp
        let newTask = makeNewLocalTask(content: sanitized, category: category, todoTime: taskTodoTime)

        Task {
            do {
                _ = try await TDQueryConditionManager.shared.addLocalTask(newTask, context: modelContext)
                // 3) 触发同步（保持与其它本地增删改一致）
                await TDMainViewModel.shared.performSyncSeparately()
                // 4) 成功回调
                await onSuccess()
            } catch {
                // 写入失败：触发错误回调
                await onError()
            }
        }
    }
    
    /// 构建"最小可用"的本地任务模型：
    /// - 只需要把 taskContent / todoTime / 分类相关字段填好
    /// - version/taskSort/taskId/createTime/syncTime/userId 等由 addLocalTask 统一赋值
    /// - Parameters:
    ///   - content: 任务内容
    ///   - category: 分类清单模型（nil表示未分类）
    ///   - todoTime: 任务日期的时间戳
    /// - Returns: 构建好的任务模型
    func makeNewLocalTask(content: String, category: TDSliderBarModel?, todoTime: Int64) -> TDMacSwiftDataListModel {
        let now = Date.currentTimestamp
        let userId = TDUserManager.shared.userId

        // 分类信息（用于：勾选框跟随清单颜色等 UI 展示）
        // 如果传入的是未分类（nil），使用默认值
        let standbyIntColor: String
        let standbyInt1: Int
        let standbyIntName: String
        
        if let category = category {
            standbyIntColor = category.categoryColor ?? ""
            standbyInt1 = max(0, category.categoryId)
            standbyIntName = category.categoryName
        } else {
            // 未分类的默认值
            standbyIntColor = "#c3c3c3"
            standbyInt1 = 0
            standbyIntName = "未分类"
        }

        return TDMacSwiftDataListModel(
            id: now,                    // 用时间戳保证唯一（服务器 id 之后会覆盖/同步）
            taskId: "",                 // addLocalTask 内会生成
            taskContent: content,
            taskDescribe: nil,
            complete: false,
            createTime: now,            // addLocalTask 内会覆盖
            delete: false,
            reminderTime: 0,
            snowAdd: 0,
            snowAssess: 0,
            standbyInt1: standbyInt1,
            standbyStr1: nil,
            standbyStr2: nil,
            standbyStr3: nil,
            standbyStr4: nil,
            syncTime: now,              // addLocalTask 内会覆盖
            taskSort: 0,                // addLocalTask 内会覆盖
            todoTime: todoTime,
            userId: userId,             // addLocalTask 内会覆盖，但这里先填上，便于 indexTask
            version: 0,
            status: "add",
            isSubOpen: true,
            standbyIntColor: standbyIntColor,
            standbyIntName: standbyIntName,
            reminderTimeString: "",
            subTaskList: [],
            attachmentList: []
        )
    }
    
    /// 根据"是否记忆上次分类选择"决定是否持久化
    /// - Parameter category: 分类模型（nil表示未分类）
    func persistSelectedCategoryIfNeeded(category: TDSliderBarModel?) {
        let userId = TDUserManager.shared.userId
        guard userId > 0 else { return }

        let settingManager = TDSettingManager.shared
        if settingManager.rememberLastCategory {
            settingManager.setLastSelectedCategory(category, for: userId)
        } else {
            // 不记忆：确保杀 App 后还是默认未分类
            settingManager.setLastSelectedCategory(nil, for: userId)
        }
    }

    /// 校验当前选择的分类是否仍然有效（被删除/不存在则回到未分类）
    /// - Parameter category: 要校验的分类模型
    /// - Returns: 有效的分类模型，如果无效则返回 nil
    func validateSelectedCategory(_ category: TDSliderBarModel?) -> TDSliderBarModel? {
        let userId = TDUserManager.shared.userId
        guard userId > 0 else { return nil }
        guard let category = category else { return nil }

        // 直接按 id 查找本地分类（避免每次全量遍历）
        guard let latest = TDCategoryManager.shared.getCategory(id: category.categoryId),
              (latest.delete == false || latest.delete == nil),
              latest.folderIs != true else {
            let settingManager = TDSettingManager.shared
            settingManager.setLastSelectedCategory(nil, for: userId)
            return nil
        }
        
        // 返回最新的分类数据（可能颜色等信息已更新）
        return latest
    }


}
