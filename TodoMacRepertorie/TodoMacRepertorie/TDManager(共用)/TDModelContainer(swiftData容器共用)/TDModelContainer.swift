

import Foundation
import SwiftData
import SwiftUI
import OSLog

enum TDSharedSwiftDataStore {
    /// 主 App 与 Widget 共享的 Schema（务必保持一致）
    static let schema = Schema([
        TDMacSwiftDataListModel.self,
        TDTomatoRecordLocalModel.self,
        TDTagModel.self,
        TDTaskTagModel.self
    ])

    /// Widget / Extension 使用：打开 AppGroup 下同一份 SwiftData store
    static func makeWidgetContext() throws -> ModelContext {
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(TDAppConfig.appGroupId)
        )
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        return ModelContext(container)
    }
}


/// SwiftData 容器管理类 - 简化版本
final class TDModelContainer: ObservableObject {
    
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
    
    private init() {
        print("📚 SwiftData容器初始化开始")
        
        // 配置 SwiftData 存储到 App Group
        let schema = TDSharedSwiftDataStore.schema
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(TDAppConfig.appGroupId),
            cloudKitDatabase: .automatic
        )
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            mainContext = ModelContext(modelContainer)
            // 标签索引是派生数据：如检测到旧库结构（新增字段导致），启动时重建一次以兼容多账号隔离
            TDTagIndexService.shared.migrateLegacyTagIndexIfNeeded(context: mainContext)
            print("✅ SwiftData容器初始化成功")
        } catch {
            print("❌ SwiftData容器初始化失败: \(error)")
            fatalError("SwiftData 容器初始化失败: \(error)")
        }
    }
    
    // MARK: - 基本数据库方法
    
    /// 保存所有更改
    func save() throws {
        try mainContext.save()
    }
    
    /// 删除对象
    func delete(_ object: any PersistentModel) {
        mainContext.delete(object)
    }
    
    /// 插入对象
    func insert(_ object: any PersistentModel) {
        mainContext.insert(object)
    }
    
    // MARK: - 清理方法
    
    deinit {
        print("🗑️ SwiftData容器销毁")
    }
}
