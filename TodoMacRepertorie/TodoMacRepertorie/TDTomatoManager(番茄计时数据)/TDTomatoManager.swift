//
//  TDTomatoManager.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/7/29.
//

import Foundation
import OSLog
import SwiftData

/// 番茄数据管理器
@MainActor
final class TDTomatoManager: ObservableObject {
    
    // MARK: - 日志系统
    private let logger = OSLog(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDTomatoManager")
    
    /// 单例
    static let shared = TDTomatoManager()
    
    // MARK: - Published 属性
    
    /// 今日番茄数据
    @Published private(set) var todayTomato: TDTomatoModel?
    
    // MARK: - 私有属性
    
    /// 当前用户ID（Int类型，-1 表示未登录）
    private var userId: Int {
        TDUserManager.shared.userId
    }
    
    /// 番茄数据文件路径（App Group 目录下，按 userId 区分）
    private var tomatoFileURL: URL {
        // 1. 获取 App Group 目录（主程序和小组件都能访问）
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: TDAppConfig.appGroupId) else {
            fatalError("获取 App Group 目录失败")
        }
        // 2. 在 App Group 目录下创建 tomato 子目录
        let userDir = appGroupURL.appendingPathComponent("tomato", isDirectory: true)
        try? FileManager.default.createDirectory(at: userDir, withIntermediateDirectories: true)
        // 3. 每个用户一个 json 文件，文件名带 userId
        return userDir.appendingPathComponent("tomato_\(userId).json")
    }
    
    // MARK: - 初始化方法
    
    private init() {
        loadTomatoFromLocal()
    }
    
    // MARK: - 公共方法
    
    /// 更新今日番茄数据
    func updateTodayTomato(_ tomato: TDTomatoModel) {
        os_log(.info, log: logger, "🔄 更新今日番茄数据: %d", tomato.tomatoNum)
        
        self.todayTomato = tomato
        saveTomatoToLocal(tomato)
    }
    
    /// 获取今日番茄数据
    func getTodayTomato() -> TDTomatoModel? {
        return todayTomato
    }
    
    // MARK: - 私有方法
    
    /// 从本地加载番茄数据（按当前 userId，主程序和小组件都能用）
    private func loadTomatoFromLocal() {
        do {
            let data = try Data(contentsOf: tomatoFileURL)
            let tomato = try JSONDecoder().decode(TDTomatoModel.self, from: data)
            self.todayTomato = tomato
            os_log(.debug, log: logger, "📱 从本地加载番茄数据成功")
        } catch {
            os_log(.debug, log: logger, "📱 本地无番茄数据")
        }
    }
    
    /// 保存番茄数据到本地（按当前 userId，主程序和小组件都能用）
    private func saveTomatoToLocal(_ tomato: TDTomatoModel) {
        Task.detached { [self] in
            do {
                let data = try JSONEncoder().encode(tomato)
                try await data.write(to: self.tomatoFileURL)
                os_log(.debug, log: logger, "💾 番茄数据保存到本地成功")
            } catch {
                os_log(.error, log: logger, "❌ 保存番茄数据到本地失败: %@", error.localizedDescription)
            }
        }
    }
    
    // MARK: - 插入专注记录
    
    /// 插入专注记录到本地数据库
    /// - Parameter record: 专注记录
    func insertTomatoRecord(_ record: TDTomatoRecordModel) {
        do {
            // 转换为本地模型
            let localRecord = record.toLocalModel()
            
            // 插入到数据库
            TDModelContainer.shared.insert(localRecord)
            try TDModelContainer.shared.save()
            
            print("✅ 专注记录已插入到本地数据库")
        } catch {
            print("❌ 插入专注记录失败: \(error)")
        }
    }
    
    // MARK: - 更新专注记录状态
    
    /// 更新专注记录状态为已同步
    /// - Parameter record: 要更新的记录
    func updateTomatoRecordToSynced(_ record: TDTomatoRecordLocalModel) {
        record.status = "sync"
        do {
            try TDModelContainer.shared.save()
            print("✅ 专注记录状态已更新为已同步")
        } catch {
            print("❌ 更新专注记录状态失败: \(error)")
        }
    }
    
    // MARK: - 查询专注记录
    
    /// 根据番茄钟ID查询专注记录
    /// - Parameter tomatoId: 番茄钟ID
    /// - Returns: 匹配的专注记录，如果没有找到则返回nil
    func getTomatoRecord(tomatoId: String) -> TDTomatoRecordLocalModel? {
        let userId = Int64(TDUserManager.shared.userId)
        
        do {
            let descriptor = FetchDescriptor<TDTomatoRecordLocalModel>(
                predicate: #Predicate { record in
                    record.tomatoId == tomatoId && record.userId == userId
                }
            )
            let records = try TDModelContainer.shared.mainContext.fetch(descriptor)
            return records.first
        } catch {
            os_log(.error, log: logger, "❌ 根据番茄钟ID查询记录失败: %@", error.localizedDescription)
            return nil
        }
    }

    
    /// 获取需要同步的专注记录（状态为 add 且用户ID匹配）
    /// - Returns: 需要同步的专注记录数组
    func getUnsyncedTomatoRecords() -> [TDTomatoRecordLocalModel] {
        let userId = Int64(TDUserManager.shared.userId)
        do {
            let descriptor = FetchDescriptor<TDTomatoRecordLocalModel>(
                predicate: #Predicate { record in
                    record.status == "add" && record.userId == userId
                }
            )
            return try TDModelContainer.shared.mainContext.fetch(descriptor)
        } catch {
            print("❌ 获取未同步专注记录失败: \(error)")
            return []
        }
    }
    
    /// 获取需要同步的专注记录并转换为服务器数据模型的JSON
    /// - Returns: 服务器数据模型的JSON字符串
    func getUnsyncedTomatoRecordsAsJson() -> String? {
        let localRecords = getUnsyncedTomatoRecords()
        
        // 转换为服务器数据模型
        let serverRecords = localRecords.map { $0.toServerModel() }
        
        // 转换为JSON
        return TDSwiftJsonUtil.arrayToJson(serverRecords)
    }

    // MARK: - 网络请求方法
    
    /// 获取今日番茄数据
    func fetchTodayTomato() async {
        do {
            let tomato = try await TDTomatoAPI.shared.getTodayTomato()
            updateTodayTomato(tomato)
            os_log(.info, log: logger, "✅ 获取今日番茄数据成功")
        } catch {
            os_log(.error, log: logger, "❌ 获取今日番茄数据失败: %@", error.localizedDescription)
        }
    }
    
    /// 获取番茄钟记录列表
    func fetchTomatoRecords() async -> [TDTomatoRecordModel] {
        do {
            let records = try await TDTomatoAPI.shared.getTomatoRecord()
            os_log(.info, log: logger, "✅ 获取番茄钟记录成功，共 %d 条", records.count)
            return records
        } catch {
            os_log(.error, log: logger, "❌ 获取番茄钟记录失败: %@", error.localizedDescription)
            return []
        }
    }

    /// 同步未同步的专注记录到服务器
    func syncUnsyncedRecords() async {
        do {
            // 获取未同步的记录JSON
            guard let recordsJson = getUnsyncedTomatoRecordsAsJson(),
                  !recordsJson.isEmpty else {
                os_log(.info, log: logger, "📝 没有需要同步的专注记录")
                return
            }
            
            // 调用API同步
            let results = try await TDTomatoAPI.shared.syncTomatoRecords(recordsJson)
            
            // 处理同步结果
            var successCount = 0
            var failedCount = 0
            
            for result in results {
                if result.succeed {
                    // 同步成功，通过 tomatoId 查询本地记录并更新状态
                    if let record = getTomatoRecord(tomatoId: result.tomatoId) {
                        updateTomatoRecordToSynced(record)
                        successCount += 1
                        os_log(.debug, log: logger, "✅ 同步成功，更新记录: %@", result.tomatoId)
                    } else {
                        os_log(.info, log: logger, "⚠️ 同步成功但未找到本地记录: %@", result.tomatoId)
                        failedCount += 1
                    }
                } else {
                    failedCount += 1
                    os_log(.error, log: logger, "❌ 同步失败: %@", result.tomatoId)
                }
            }

            os_log(.info, log: logger, "✅ 专注记录同步完成，成功: %d 条，失败: %d 条", successCount, failedCount)
            // 同步结束后，更新今日番茄数据
            await fetchTodayTomato()

        } catch {
            os_log(.error, log: logger, "❌ 专注记录同步失败: %@", error.localizedDescription)
        }
    }

    
}
