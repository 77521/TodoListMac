//
//  TDModelContainer.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/27.
//

import Foundation
import SwiftData

/// SwiftData 容器管理类
@MainActor
class TDModelContainer {
    /// 单例
    static let shared = TDModelContainer()
    
    /// 主要的 ModelContainer
    private let container: ModelContainer
    
    /// 主要的 ModelContext
    let mainContext: ModelContext
    
    private init() {
        // 配置 Schema
        let schema = Schema([
            TDMacSwiftDataListModel.self,
            TDSubDataModel.self,
            TDUpLoadFieldModel.self
        ])
        
        // 配置选项
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            // 创建容器
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            // 获取主上下文
            mainContext = container.mainContext
        } catch {
            fatalError("无法创建 ModelContainer: \(error)")
        }
    }
    
    /// 创建新的上下文
    func newContext() -> ModelContext {
        return ModelContext(container)
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
