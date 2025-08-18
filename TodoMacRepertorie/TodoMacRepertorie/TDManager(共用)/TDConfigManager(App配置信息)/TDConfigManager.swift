//
//  TDConfigManager.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/7/29.
//

import Foundation
import OSLog

@MainActor
final class TDConfigManager: ObservableObject {
    
    // MARK: - 日志系统
    private let logger = OSLog(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDConfigManager")
    
    /// 单例
    static let shared = TDConfigManager()
    
    // MARK: - Published 属性
    
    /// 当前配置
    @Published private(set) var currentConfig: TDConfigModel?
    
    // MARK: - 私有属性
    
    /// 当前用户ID（Int类型，-1 表示未登录）
    private var userId: Int {
        TDUserManager.shared.userId
    }
    
    /// 配置数据文件路径（App Group 目录下，按 userId 区分）
    private var configFileURL: URL {
        // 1. 获取 App Group 目录（主程序和小组件都能访问）
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: TDAppConfig.appGroupId) else {
            fatalError("获取 App Group 目录失败")
        }
        // 2. 在 App Group 目录下创建 config 子目录
        let userDir = appGroupURL.appendingPathComponent("config", isDirectory: true)
        try? FileManager.default.createDirectory(at: userDir, withIntermediateDirectories: true)
        // 3. 每个用户一个 json 文件，文件名带 userId
        return userDir.appendingPathComponent("config_\(userId).json")
    }
    
    // MARK: - 初始化方法
    
    private init() {
        loadConfigFromLocal()
    }
    
    // MARK: - 公共方法
    
    /// 更新配置
    func updateConfig(_ config: TDConfigModel) {
        os_log(.info, log: logger, "🔄 更新应用配置")
        
        self.currentConfig = config
        saveConfigToLocal(config)
    }
    
    /// 获取配置
    func getConfig() -> TDConfigModel? {
        return currentConfig
    }
    
    // MARK: - 私有方法
    
    /// 从本地加载配置（按当前 userId，主程序和小组件都能用）
    private func loadConfigFromLocal() {
        do {
            let data = try Data(contentsOf: configFileURL)
            let config = try JSONDecoder().decode(TDConfigModel.self, from: data)
            self.currentConfig = config
            os_log(.debug, log: logger, "📱 从本地加载配置成功")
        } catch {
            os_log(.debug, log: logger, "📱 本地无配置数据")
        }
    }
    
    /// 保存配置到本地（按当前 userId，主程序和小组件都能用）
    private func saveConfigToLocal(_ config: TDConfigModel) {
        Task.detached { [self] in
            do {
                let data = try JSONEncoder().encode(config)
                try await data.write(to: self.configFileURL)
                os_log(.debug, log: logger, "💾 配置保存到本地成功")
            } catch {
                os_log(.error, log: logger, "❌ 保存配置到本地失败: %@", error.localizedDescription)
            }
        }
    }
}
