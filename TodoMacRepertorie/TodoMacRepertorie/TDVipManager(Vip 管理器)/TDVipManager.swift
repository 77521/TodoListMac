//
//  TDVipManager.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/7/29.
//

import Foundation
import OSLog

/// VIP数据管理器
@MainActor
final class TDVipManager: ObservableObject {
    
    // MARK: - 日志系统
    private let logger = OSLog(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDVipManager")
    
    /// 单例
    static let shared = TDVipManager()
    
    // MARK: - Published 属性
    
    /// VIP数据
    @Published private(set) var vipData: TDVipModel?
    
    // MARK: - 私有属性
    
    /// 当前用户ID（Int类型，-1 表示未登录）
    private var userId: Int {
        TDUserManager.shared.userId
    }
    
    /// VIP数据文件路径（App Group 目录下，按 userId 区分）
    private var vipFileURL: URL {
        // 1. 获取 App Group 目录（主程序和小组件都能访问）
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: TDAppConfig.appGroupId) else {
            fatalError("获取 App Group 目录失败")
        }
        // 2. 在 App Group 目录下创建 vip 子目录
        let userDir = appGroupURL.appendingPathComponent("vip", isDirectory: true)
        try? FileManager.default.createDirectory(at: userDir, withIntermediateDirectories: true)
        // 3. 每个用户一个 json 文件，文件名带 userId
        return userDir.appendingPathComponent("vip_\(userId).json")
    }
    
    // MARK: - 初始化方法
    
    private init() {
        loadVipFromLocal()
    }
    
    // MARK: - 公共方法
    
    /// 更新VIP数据
    func updateVipData(_ vipData: TDVipModel) {
        os_log(.info, log: logger, "🔄 更新VIP数据，商品数量: %d", vipData.goodsList.count)
        
        self.vipData = vipData
        saveVipToLocal(vipData)
    }
    
    /// 获取VIP数据
    func getVipData() -> TDVipModel? {
        return vipData
    }
    
    // MARK: - 私有方法
    
    /// 从本地加载VIP数据（按当前 userId，主程序和小组件都能用）
    private func loadVipFromLocal() {
        do {
            let data = try Data(contentsOf: vipFileURL)
            let vipData = try JSONDecoder().decode(TDVipModel.self, from: data)
            self.vipData = vipData
            os_log(.debug, log: logger, "📱 从本地加载VIP数据成功")
        } catch {
            os_log(.debug, log: logger, "📱 本地无VIP数据")
        }
    }
    
    /// 保存VIP数据到本地（按当前 userId，主程序和小组件都能用）
    private func saveVipToLocal(_ vipData: TDVipModel) {
        Task.detached { [self] in
            do {
                let data = try JSONEncoder().encode(vipData)
                try await data.write(to: self.vipFileURL)
                os_log(.debug, log: logger, "💾 VIP数据保存到本地成功")
            } catch {
                os_log(.error, log: logger, "❌ 保存VIP数据到本地失败: %@", error.localizedDescription)
            }
        }
    }
}


