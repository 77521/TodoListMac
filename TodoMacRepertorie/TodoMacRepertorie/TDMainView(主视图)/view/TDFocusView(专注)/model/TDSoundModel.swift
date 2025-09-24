//
//  TDSoundModel.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/9/24.
//

import Foundation

/// 声音模型
struct TDSoundModel: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let icon: String
    
    init(name: String, icon: String) {
        self.id = UUID().uuidString
        self.name = name
        self.icon = icon
    }
}

// MARK: - 预设声音数据
extension TDSoundModel {
    /// 获取所有可用的声音选项
    static let allSounds: [TDSoundModel] = [
        TDSoundModel(name: "静音", icon: "icon_volume_mute"),
        TDSoundModel(name: "春雨", icon: "icon_big_rain"),
        TDSoundModel(name: "森林", icon: "icon_forest"),
        TDSoundModel(name: "海洋", icon: "icon_ocean"),
        TDSoundModel(name: "雨水敲打玻璃", icon: "icon_small_rain"),
        TDSoundModel(name: "火炉", icon: "icon_fire"),
        TDSoundModel(name: "小溪流水", icon: "icon_river"),
        TDSoundModel(name: "雷雨", icon: "icon_thunderstorm"),
        TDSoundModel(name: "篝火与雷雨", icon: "icon_thunderstorm-1"),
        TDSoundModel(name: "火车", icon: "icon_train"),
        TDSoundModel(name: "鸟鸣", icon: "icon_twitter"),
        TDSoundModel(name: "街道", icon: "icon_street"),
        TDSoundModel(name: "咖啡馆", icon: "icon_coffee"),
        TDSoundModel(name: "洞穴", icon: "icon_dongxue"),
        TDSoundModel(name: "自定义", icon: "icon_person.fill")
    ]
    
    /// 默认声音（静音）
    static let defaultSound = allSounds.first { $0.name == "静音" }!
}

