//
//  TDTomatoManager.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/7/29.
//

import Foundation
import OSLog

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
}
