//
//  TDModelContainer.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftData
import SwiftUI

/// SwiftData 容器管理类
@MainActor
class TDModelContainer : ObservableObject {
    /// 单例
    static let shared = TDModelContainer()
    
    /// 主要的 ModelContainer
    let modelContainer: ModelContainer
    
    /// 主要的 ModelContext
    var mainContext: ModelContext {
        modelContainer.mainContext
    }
    
    private init() {
//        do {
//            // 删除旧的数据库文件
////            Self.clearOldDatabase()
//            // 配置 Schema
//            let schema = Schema([
//                TDMacSwiftDataListModel.self
//            ])
//            
//            // 配置 ModelConfiguration
//            let modelConfiguration = ModelConfiguration(
//                schema: schema,
//                isStoredInMemoryOnly: false,
//                allowsSave: true
//            )
//            
//            // 创建 ModelContainer
//            modelContainer = try ModelContainer(
//                for: schema,
//                configurations: modelConfiguration
//            )
//            
//        } catch {
//            print("创建 ModelContainer 失败: \(error)")
//            fatalError("Could not create ModelContainer: \(error)")
//        }
        
        // 1. 获取数据库路径（直接用 TDAppConfig.swiftDataDBURL）
        guard let dbURL = TDAppConfig.swiftDataDBURL else {
            fatalError("获取 App Group 数据库路径失败")
        }
        // 2. 配置 SwiftData 存储到 App Group
        let schema = Schema([TDMacSwiftDataListModel.self])
        let config = ModelConfiguration(schema: schema, url: dbURL)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
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

    
    
    /// 创建新的上下文
    func newContext() -> ModelContext {
        return mainContext
    }
    
    /// 保存所有更改
    func save() throws {
        try mainContext.save()
    }
    
    /// 在主线程上下文执行查询操作
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T: PersistentModel {
        return try mainContext.fetch(descriptor)
    }
    
    /// 在主线程上下文执行单个对象查询
    func fetchOne<T>(_ descriptor: FetchDescriptor<T>) throws -> T? where T: PersistentModel {
        var descriptor = descriptor
        descriptor.fetchLimit = 1
        return try mainContext.fetch(descriptor).first
    }
    
    /// 在主线程上下文执行删除操作
    func delete(_ object: any PersistentModel) {
        mainContext.delete(object)
    }
    
    /// 在主线程上下文执行插入操作
    func insert(_ object: any PersistentModel) {
        mainContext.insert(object)
    }
    
    /// 在主线程上下文执行批量操作
    func perform(_ changes: () throws -> Void) throws {
        try changes()
        try save()
    }
    
    /// 异步执行数据库操作，确保在主线程上执行
    @MainActor
    func perform<T>(_ operation: @escaping () throws -> T) async throws -> T {
        return try operation()
    }

}
