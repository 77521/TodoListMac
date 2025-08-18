//
//  TDCountdownManager.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/7/29.
//

import Foundation
import OSLog

/// 倒计时管理器
@MainActor
final class TDCountdownManager: ObservableObject {
    
    // MARK: - 日志系统
    private let logger = OSLog(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDCountdownManager")
    
    /// 单例
    static let shared = TDCountdownManager()
    
    // MARK: - Published 属性
    
    /// 倒计时列表
    @Published private(set) var countdownList: [TDCountdownModel] = []
    
    // MARK: - 私有属性
    
    /// 当前用户ID（Int类型，-1 表示未登录）
    private var userId: Int {
        TDUserManager.shared.userId
    }
    
    /// 倒计时数据文件路径（App Group 目录下，按 userId 区分）
    private var countdownFileURL: URL {
        // 1. 获取 App Group 目录（主程序和小组件都能访问）
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: TDAppConfig.appGroupId) else {
            fatalError("获取 App Group 目录失败")
        }
        // 2. 在 App Group 目录下创建 countdown 子目录
        let userDir = appGroupURL.appendingPathComponent("countdown", isDirectory: true)
        try? FileManager.default.createDirectory(at: userDir, withIntermediateDirectories: true)
        // 3. 每个用户一个 json 文件，文件名带 userId
        return userDir.appendingPathComponent("countdown_\(userId).json")
    }
    
    // MARK: - 初始化方法
    
    private init() {
        loadCountdownFromLocal()
    }
    
    // MARK: - 公共方法
    
    /// 更新倒计时列表
    func updateCountdownList(_ countdownList: [TDCountdownModel]) {
        os_log(.info, log: logger, "🔄 更新倒计时列表，共 %d 项", countdownList.count)
        
        self.countdownList = countdownList
        saveCountdownToLocal(countdownList)
    }
    
    /// 获取倒计时列表
    func getCountdownList() -> [TDCountdownModel] {
        return countdownList
    }
    
    // MARK: - 私有方法
    
    /// 从本地加载倒计时数据（按当前 userId，主程序和小组件都能用）
    private func loadCountdownFromLocal() {
        do {
            let data = try Data(contentsOf: countdownFileURL)
            let countdownList = try JSONDecoder().decode([TDCountdownModel].self, from: data)
            self.countdownList = countdownList
            os_log(.debug, log: logger, "📱 从本地加载倒计时数据成功，共 %d 项", countdownList.count)
        } catch {
            os_log(.debug, log: logger, "📱 本地无倒计时数据")
        }
    }
    
    /// 保存倒计时数据到本地（按当前 userId，主程序和小组件都能用）
    private func saveCountdownToLocal(_ countdownList: [TDCountdownModel]) {
        Task.detached { [self] in
            do {
                let data = try JSONEncoder().encode(countdownList)
                try await data.write(to: self.countdownFileURL)
                os_log(.debug, log: logger, "💾 倒计时数据保存到本地成功")
            } catch {
                os_log(.error, log: logger, "❌ 保存倒计时数据到本地失败: %@", error.localizedDescription)
            }
        }
    }
}

