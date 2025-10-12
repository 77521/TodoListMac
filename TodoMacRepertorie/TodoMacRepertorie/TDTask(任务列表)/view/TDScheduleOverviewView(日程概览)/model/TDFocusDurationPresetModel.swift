//
//  TDFocusDurationPresetModel.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/9/25.
//

import Foundation
import OSLog

/// 专注时长预设模型
struct TDFocusDurationPresetModel: Codable, Identifiable, Equatable {
    let id: String
    let duration: Int // 时长（分钟）
    let isDefault: Bool // 是否为默认预设
    let isCustom: Bool // 是否为自定义预设
    
    init(duration: Int, isDefault: Bool = false, isCustom: Bool = false) {
        self.id = UUID().uuidString
        self.duration = duration
        self.isDefault = isDefault
        self.isCustom = isCustom
    }
    
    /// 默认专注时长预设
    static let defaultFocusPresets: [TDFocusDurationPresetModel] = [
        TDFocusDurationPresetModel(duration: 25, isDefault: true)
    ]
    
    /// 默认休息时长预设
    static let defaultRestPresets: [TDFocusDurationPresetModel] = [
        TDFocusDurationPresetModel(duration: 5, isDefault: true)
    ]
}

/// 专注时长预设管理器
@MainActor
class TDFocusDurationPresetManager: ObservableObject {
    static let shared = TDFocusDurationPresetManager()
    
    @Published var focusPresets: [TDFocusDurationPresetModel] = []
    @Published var restPresets: [TDFocusDurationPresetModel] = []
    
    private let logger = OSLog(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDFocusDurationPresetManager")
    
    /// 当前用户ID
    private var userId: Int {
        TDUserManager.shared.userId
    }
    
    /// 专注时长预设文件路径（App Group 目录下，按 userId 区分）
    private var focusPresetsFileURL: URL {
        // 1. 获取 App Group 目录（主程序和小组件都能访问）
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: TDAppConfig.appGroupId) else {
            fatalError("获取 App Group 目录失败")
        }
        // 2. 在 App Group 目录下创建 focus_presets 子目录
        let userDir = appGroupURL.appendingPathComponent("focus_presets", isDirectory: true)
        try? FileManager.default.createDirectory(at: userDir, withIntermediateDirectories: true)
        // 3. 每个用户一个 json 文件，文件名带 userId
        return userDir.appendingPathComponent("focus_presets_\(userId).json")
    }
    
    /// 休息时长预设文件路径（App Group 目录下，按 userId 区分）
    private var restPresetsFileURL: URL {
        // 1. 获取 App Group 目录（主程序和小组件都能访问）
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: TDAppConfig.appGroupId) else {
            fatalError("获取 App Group 目录失败")
        }
        // 2. 在 App Group 目录下创建 focus_presets 子目录
        let userDir = appGroupURL.appendingPathComponent("focus_presets", isDirectory: true)
        try? FileManager.default.createDirectory(at: userDir, withIntermediateDirectories: true)
        // 3. 每个用户一个 json 文件，文件名带 userId
        return userDir.appendingPathComponent("rest_presets_\(userId).json")
    }
    
    private init() {
        loadPresets()
    }
    
    /// 加载预设
    private func loadPresets() {
        // 加载专注时长预设
        do {
            let data = try Data(contentsOf: focusPresetsFileURL)
            let presets = try JSONDecoder().decode([TDFocusDurationPresetModel].self, from: data)
            self.focusPresets = presets
            os_log(.debug, log: logger, "📱 从本地加载专注时长预设成功")
        } catch {
            self.focusPresets = TDFocusDurationPresetModel.defaultFocusPresets
            os_log(.debug, log: logger, "📱 本地无专注时长预设，使用默认预设")
        }
        
        // 加载休息时长预设
        do {
            let data = try Data(contentsOf: restPresetsFileURL)
            let presets = try JSONDecoder().decode([TDFocusDurationPresetModel].self, from: data)
            self.restPresets = presets
            os_log(.debug, log: logger, "📱 从本地加载休息时长预设成功")
        } catch {
            self.restPresets = TDFocusDurationPresetModel.defaultRestPresets
            os_log(.debug, log: logger, "📱 本地无休息时长预设，使用默认预设")
        }
    }
    
    /// 保存专注时长预设
    private func saveFocusPresets() {
        Task.detached { [self] in
            do {
                let data = try await JSONEncoder().encode(focusPresets)
                try await data.write(to: focusPresetsFileURL)
                os_log(.debug, log: logger, "💾 专注时长预设保存到本地成功")
            } catch {
                os_log(.error, log: logger, "❌ 保存专注时长预设到本地失败: %@", error.localizedDescription)
            }
        }
    }
    
    /// 保存休息时长预设
    private func saveRestPresets() {
        Task.detached { [self] in
            do {
                let data = try await JSONEncoder().encode(restPresets)
                try await data.write(to: restPresetsFileURL)
                os_log(.debug, log: logger, "💾 休息时长预设保存到本地成功")
            } catch {
                os_log(.error, log: logger, "❌ 保存休息时长预设到本地失败: %@", error.localizedDescription)
            }
        }
    }
    
    /// 添加专注时长预设
    func addFocusPreset(_ duration: Int) {
        let preset = TDFocusDurationPresetModel(duration: duration, isCustom: true)
        focusPresets.append(preset)
        saveFocusPresets()
    }
    
    /// 添加休息时长预设
    func addRestPreset(_ duration: Int) {
        let preset = TDFocusDurationPresetModel(duration: duration, isCustom: true)
        restPresets.append(preset)
        saveRestPresets()
    }
    
    /// 删除专注时长预设
    func removeFocusPreset(_ preset: TDFocusDurationPresetModel) {
        guard preset.isCustom else { return } // 只能删除自定义预设
        focusPresets.removeAll { $0.id == preset.id }
        saveFocusPresets()
    }
    
    /// 删除休息时长预设
    func removeRestPreset(_ preset: TDFocusDurationPresetModel) {
        guard preset.isCustom else { return } // 只能删除自定义预设
        restPresets.removeAll { $0.id == preset.id }
        saveRestPresets()
    }
    
    /// 恢复默认预设
    func restoreDefaults() {
        // 使用数据模型中的默认预设
        let defaultFocusPreset = TDFocusDurationPresetModel.defaultFocusPresets.first!
        let defaultRestPreset = TDFocusDurationPresetModel.defaultRestPresets.first!
        
        // 选中默认的专注时长和休息时长
        setFocusDuration(defaultFocusPreset.duration)
        setRestDuration(defaultRestPreset.duration)
    }
    
    /// 获取当前选中的专注时长
    func getCurrentFocusDuration() -> Int {
        return TDSettingManager.shared.focusDuration
    }
    
    /// 获取当前选中的休息时长
    func getCurrentRestDuration() -> Int {
        return TDSettingManager.shared.restDuration
    }
    
    /// 设置专注时长
    func setFocusDuration(_ duration: Int) {
        TDSettingManager.shared.focusDuration = duration
    }
    
    /// 设置休息时长
    func setRestDuration(_ duration: Int) {
        TDSettingManager.shared.restDuration = duration
    }
}
