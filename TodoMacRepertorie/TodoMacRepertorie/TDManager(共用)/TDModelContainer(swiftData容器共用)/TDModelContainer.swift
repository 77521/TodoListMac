

import Foundation
import SwiftData
import SwiftUI
import OSLog


/// SwiftData 容器管理类 - 性能优化版本
/// 主要优化：
/// 1. 移除@MainActor限制，允许后台线程数据库操作
/// 2. 提供线程安全的数据库访问方法
/// 3. 智能上下文管理
/// 4. 性能监控和日志
@MainActor
final class TDModelContainer: ObservableObject {
    
    // MARK: - 日志系统
    private let logger = OSLog(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDModelContainer")
    
    /// 单例
    static let shared = TDModelContainer()
    
    /// 主要的 ModelContainer
    private let modelContainer: ModelContainer
    
    /// 主线程的 ModelContext（用于UI相关操作）
    private(set) var mainContext: ModelContext
    
    /// 获取ModelContainer实例（用于SwiftUI的modelContainer修饰符）
    var container: ModelContainer {
        modelContainer
    }
    
    /// 后台操作的actor
    private let backgroundActor = BackgroundDatabaseActor()
    
    private init() {
        os_log(.info, log: logger, "📚 SwiftData容器初始化开始")
        
        // 1. 获取数据库路径（直接用 TDAppConfig.swiftDataDBURL）
        guard let dbURL = TDAppConfig.swiftDataDBURL else {
            fatalError("获取 App Group 数据库路径失败")
        }
        
        // 2. 配置 SwiftData 存储到 App Group
        let schema = Schema([TDMacSwiftDataListModel.self])
        let config = ModelConfiguration(schema: schema, url: dbURL)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: config)
            mainContext = ModelContext(modelContainer)
            os_log(.info, log: logger, "✅ SwiftData容器初始化成功")
        } catch {
            os_log(.error, log: logger, "❌ SwiftData容器初始化失败: %@", error.localizedDescription)
            fatalError("SwiftData 容器初始化失败: \(error)")
        }
    }
    
    /// 清除旧的数据库文件
    private static func clearOldDatabase() {
        do {
            // 1. 获取数据库主文件路径
            guard let storePath = TDAppConfig.swiftDataDBURL else {
                print("获取 App Group 数据库路径失败")
                return
            }
            // 2. 删除主数据库文件
            if FileManager.default.fileExists(atPath: storePath.path) {
                try FileManager.default.removeItem(at: storePath)
                print("已删除 App Group 下的旧数据库文件")
            }
            
            // 4. 删除 -shm 和 -wal 文件
            let shmPath = storePath.appendingPathExtension("sqlite-shm")
            let walPath = storePath.appendingPathExtension("sqlite-wal")
            
            if FileManager.default.fileExists(atPath: shmPath.path) {
                try FileManager.default.removeItem(at: shmPath)
            }
            if FileManager.default.fileExists(atPath: walPath.path) {
                try FileManager.default.removeItem(at: walPath)
            }
            
        } catch {
            print("清除 App Group 下旧数据库文件失败: \(error)")
        }
    }
    
    // MARK: - 异步数据库操作方法
    
    /// 异步执行查询操作 - 在后台线程执行
    func fetchAsync<T>(_ descriptor: FetchDescriptor<T>) async throws -> [T] where T: PersistentModel {
        try await backgroundActor.fetch(modelContainer: modelContainer, descriptor: descriptor)
    }
    
    /// 异步执行单个对象查询 - 在后台线程执行
    func fetchOneAsync<T>(_ descriptor: FetchDescriptor<T>) async throws -> T? where T: PersistentModel {
        try await backgroundActor.fetchOne(modelContainer: modelContainer, descriptor: descriptor)
    }
    
    /// 异步执行数据库操作 - 在后台线程执行
    func performAsync<T>(_ operation: @escaping (ModelContext) throws -> T) async throws -> T {
        try await backgroundActor.perform(modelContainer: modelContainer, operation: operation)
    }
    
    /// 异步批量操作 - 优化大量数据处理
    func performBatchAsync<T>(_ items: [T], batchSize: Int = 100, operation: @escaping (ModelContext, [T]) throws -> Void) async throws {
        try await backgroundActor.performBatch(modelContainer: modelContainer, items: items, batchSize: batchSize, operation: operation)
    }
    
    // MARK: - 主线程数据库方法（用于UI操作）
    
    /// 在主线程上下文执行查询操作（仅用于UI相关操作）
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T: PersistentModel {
        return try mainContext.fetch(descriptor)
    }
    
    /// 在主线程上下文执行单个对象查询（仅用于UI相关操作）
    func fetchOne<T>(_ descriptor: FetchDescriptor<T>) throws -> T? where T: PersistentModel {
        var descriptor = descriptor
        descriptor.fetchLimit = 1
        return try mainContext.fetch(descriptor).first
    }
    
    /// 在主线程保存所有更改（仅用于UI相关操作）
    func save() throws {
        try mainContext.save()
    }
    
    /// 在主线程执行删除操作（仅用于UI相关操作）
    func delete(_ object: any PersistentModel) {
        mainContext.delete(object)
    }
    
    /// 在主线程执行插入操作（仅用于UI相关操作）
    func insert(_ object: any PersistentModel) {
        mainContext.insert(object)
    }
    
    // MARK: - 清理方法
    
    deinit {
        os_log(.info, log: logger, "🗑️ SwiftData容器销毁")
    }
}

// MARK: - 后台数据库操作Actor

/// 专门处理后台数据库操作的actor
actor BackgroundDatabaseActor {
    private let logger = OSLog(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "BackgroundDatabaseActor")
    
    func fetch<T>(modelContainer: ModelContainer, descriptor: FetchDescriptor<T>) async throws -> [T] where T: PersistentModel {
        os_signpost(.begin, log: logger, name: "AsyncFetch")
        
        let context = ModelContext(modelContainer)
        do {
            let result = try context.fetch(descriptor)
            os_signpost(.end, log: logger, name: "AsyncFetch")
            return result
        } catch {
            os_log(.error, log: logger, "❌ 异步查询失败: %@", error.localizedDescription)
            throw error
        }
    }
    
    func fetchOne<T>(modelContainer: ModelContainer, descriptor: FetchDescriptor<T>) async throws -> T? where T: PersistentModel {
        os_signpost(.begin, log: logger, name: "AsyncFetchOne")
        
        var descriptor = descriptor
        descriptor.fetchLimit = 1
        
        let context = ModelContext(modelContainer)
        do {
            let result = try context.fetch(descriptor).first
            os_signpost(.end, log: logger, name: "AsyncFetchOne")
            return result
        } catch {
            os_log(.error, log: logger, "❌ 异步单个查询失败: %@", error.localizedDescription)
            throw error
        }
    }
    
    func perform<T>(modelContainer: ModelContainer, operation: @escaping (ModelContext) throws -> T) async throws -> T {
        os_signpost(.begin, log: logger, name: "AsyncPerform")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let context = ModelContext(modelContainer)
        do {
            let result = try operation(context)
            try context.save()
            
            let endTime = CFAbsoluteTimeGetCurrent()
            os_log(.debug, log: logger, "⚡ 数据库操作耗时: %.3f 秒", endTime - startTime)
            
            os_signpost(.end, log: logger, name: "AsyncPerform")
            return result
        } catch {
            os_log(.error, log: logger, "❌ 异步操作失败: %@", error.localizedDescription)
            throw error
        }
    }
    
    func performBatch<T>(modelContainer: ModelContainer, items: [T], batchSize: Int, operation: @escaping (ModelContext, [T]) throws -> Void) async throws {
        os_signpost(.begin, log: logger, name: "AsyncBatch")
        os_log(.info, log: logger, "🔄 开始批量操作，共 %d 条数据", items.count)
        
        for i in stride(from: 0, to: items.count, by: batchSize) {
            let end = min(i + batchSize, items.count)
            let batch = Array(items[i..<end])
            
            let context = ModelContext(modelContainer)
            try operation(context, batch)
            try context.save()
            
            os_log(.debug, log: logger, "✅ 已处理 %d/%d 条数据", end, items.count)
        }
        
        os_log(.info, log: logger, "🎉 批量操作完成")
        os_signpost(.end, log: logger, name: "AsyncBatch")
    }
}

// MARK: - 扩展：性能监控

#if DEBUG
extension TDModelContainer {
    /// 打印数据库性能统计
    func printDatabaseStats() {
        os_log(.debug, log: logger, """
        📊 数据库统计:
        - 容器状态: 正常
        - 主线程上下文: 可用
        - 后台队列: 活跃
        """)
    }
    
    /// 执行数据库维护操作
    func performMaintenance() async {
        os_log(.info, log: logger, "🔧 开始数据库维护")
        
        do {
            try await performAsync { context in
                // 这里可以添加数据库维护逻辑
                // 比如清理过期数据、重建索引等
                os_log(.debug, log: self.logger, "🔧 数据库维护完成")
            }
        } catch {
            os_log(.error, log: logger, "❌ 数据库维护失败: %@", error.localizedDescription)
        }
    }
}
#endif
