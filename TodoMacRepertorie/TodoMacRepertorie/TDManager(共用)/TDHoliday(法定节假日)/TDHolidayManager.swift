//
//  TDHolidayManager.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/7/29.
//

import Foundation
import OSLog

final class TDHolidayManager: ObservableObject {
    
    // MARK: - 日志系统
    private let logger = OSLog(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDHolidayManager")
    
    /// 单例
    static let shared = TDHolidayManager()
    
    // MARK: - Published 属性
    
    /// 当前节假日列表
    @Published private(set) var holidayList: [TDHolidayItem] = []
    
    // MARK: - 私有属性
    
    /// 当前用户ID（Int类型，-1 表示未登录）
    private var userId: Int {
        TDUserManager.shared.userId
    }
    
    /// 节假日数据文件路径（App Group 目录下，按 userId 区分）
    private var holidayFileURL: URL {
        // 1. 获取 App Group 目录（主程序和小组件都能访问）
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: TDAppConfig.appGroupId) else {
            fatalError("获取 App Group 目录失败")
        }
        // 2. 在 App Group 目录下创建 holiday 子目录
        let userDir = appGroupURL.appendingPathComponent("holiday", isDirectory: true)
        try? FileManager.default.createDirectory(at: userDir, withIntermediateDirectories: true)
        // 3. 每个用户一个 json 文件，文件名带 userId
        return userDir.appendingPathComponent("holiday_\(userId).json")
    }
    
    // MARK: - 初始化方法
    
    private init() {
        loadHolidaysFromLocal()
    }
    
    // MARK: - 公共方法
    
    /// 更新节假日列表
    func updateHolidayList(_ holidays: [TDHolidayItem]) {
        os_log(.info, log: logger, "🔄 更新节假日列表，共 %d 个节假日", holidays.count)
        
        if Thread.isMainThread {
            self.holidayList = holidays
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.holidayList = holidays
            }
        }
        saveHolidaysToLocal(holidays)
    }
    
    /// 获取节假日列表
    func getHolidayList() -> [TDHolidayItem] {
        return holidayList
    }
    
    /// 从网络获取节假日列表
    func fetchHolidayListFromNetwork() async {
        do {
            let holidays = try await TDHolidayAPI.shared.getHolidayList()
            updateHolidayList(holidays)
            os_log(.info, log: logger, "✅ 从网络获取节假日列表成功，共 %d 个节假日", holidays.count)
        } catch {
            os_log(.error, log: logger, "❌ 从网络获取节假日列表失败: %@", error.localizedDescription)
        }
    }
    
    
    // MARK: - 私有方法
    
    /// 从本地加载节假日数据（按当前 userId，主程序和小组件都能用）
    private func loadHolidaysFromLocal() {
        do {
            let data = try Data(contentsOf: holidayFileURL)
            let holidays = try JSONDecoder().decode([TDHolidayItem].self, from: data)
            self.holidayList = holidays
            os_log(.debug, log: logger, "📱 从本地加载节假日数据成功，共 %d 个节假日", holidays.count)
        } catch {
            os_log(.debug, log: logger, "📱 本地无节假日数据")
        }
    }
    
    /// 保存节假日数据到本地（按当前 userId，主程序和小组件都能用）
    private func saveHolidaysToLocal(_ holidays: [TDHolidayItem]) {
        Task.detached { [self] in
            do {
                let data = try JSONEncoder().encode(holidays)
                try await data.write(to: self.holidayFileURL)
                os_log(.debug, log: logger, "💾 节假日数据保存到本地成功")
            } catch {
                os_log(.error, log: logger, "❌ 保存节假日数据到本地失败: %@", error.localizedDescription)
            }
        }
    }
}
