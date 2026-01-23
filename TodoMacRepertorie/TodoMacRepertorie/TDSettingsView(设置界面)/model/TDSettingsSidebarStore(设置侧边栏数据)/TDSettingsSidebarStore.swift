//
//  TDSettingsSidebarStore.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/12/5.
//

import Foundation
import SwiftUI

// MARK: - 设置侧边栏数据模型
enum TDSettingItemID: String, CaseIterable, Identifiable, Hashable {
    case accountSecurity
    case premium
    case general
    case featureModules
    case theme
    case appIcon
    case eventSettings
    case scheduleOverview
    case smartRecognition
    case pomodoroFocus
    case repeatManagement
    case assetManagement
    case shortcuts
    case universal
    case about
    
    var id: String { rawValue }
}

enum TDSettingGroupID: String, Identifiable, Hashable {
    case account
    case general
    case features
    case management
    case more
    
    var id: String { rawValue }
    
    var localizationKey: String {
        switch self {
        case .account:
            return "settings.group.account"
        case .general:
            return "settings.group.general"
        case .features:
            return "settings.group.features"
        case .management:
            return "settings.group.management"
        case .more:
            return "settings.group.others"
        }
    }
}

struct TDSettingSidebarItem: Identifiable, Hashable {
    let id: TDSettingItemID
    let titleKey: String
    let iconSystemName: String
}

struct TDSettingSidebarGroup: Identifiable, Hashable {
    let id: TDSettingGroupID
    let titleKey: String
    let items: [TDSettingSidebarItem]
}

struct TDSettingSidebarDataBuilder {
    static func buildDefaultGroups() -> [TDSettingSidebarGroup] {
        [
            TDSettingSidebarGroup(
                id: .account,
                titleKey: TDSettingGroupID.account.localizationKey,
                items: [
                    TDSettingSidebarItem(id: .accountSecurity, titleKey: "settings.section.account_security", iconSystemName: "lock.shield"),
                    TDSettingSidebarItem(id: .premium, titleKey: "settings.section.premium", iconSystemName: "crown.fill")
                ]
            ),
            TDSettingSidebarGroup(
                id: .general,
                titleKey: TDSettingGroupID.general.localizationKey,
                items: [
                    TDSettingSidebarItem(id: .general, titleKey: "settings.section.general", iconSystemName: "slider.horizontal.3"),
                    TDSettingSidebarItem(id: .featureModules, titleKey: "settings.section.feature_modules", iconSystemName: "square.grid.2x2"),
                    TDSettingSidebarItem(id: .theme, titleKey: "settings.section.theme", iconSystemName: "paintpalette.fill"),
                    TDSettingSidebarItem(id: .appIcon, titleKey: "settings.section.app_icon", iconSystemName: "app.badge")
                ]
            ),
            TDSettingSidebarGroup(
                id: .features,
                titleKey: TDSettingGroupID.features.localizationKey,
                items: [
                    TDSettingSidebarItem(id: .eventSettings, titleKey: "settings.section.event_settings", iconSystemName: "checkmark.circle"),
                    TDSettingSidebarItem(id: .scheduleOverview, titleKey: "settings.section.schedule_overview", iconSystemName: "calendar"),
//                    TDSettingSidebarItem(id: .smartRecognition, titleKey: "settings.section.smart_recognition", iconSystemName: "waveform"),
                    TDSettingSidebarItem(id: .pomodoroFocus, titleKey: "settings.section.pomodoro_focus", iconSystemName: "timer")
                ]
            ),
            TDSettingSidebarGroup(
                id: .management,
                titleKey: TDSettingGroupID.management.localizationKey,
                items: [
                    TDSettingSidebarItem(id: .repeatManagement, titleKey: "settings.section.repeat_event_management", iconSystemName: "repeat.circle"),
                    TDSettingSidebarItem(id: .assetManagement, titleKey: "settings.section.image_file_management", iconSystemName: "photo.on.rectangle")
                ]
            ),
            TDSettingSidebarGroup(
                id: .more,
                titleKey: TDSettingGroupID.more.localizationKey,
                items: [
//                    TDSettingSidebarItem(id: .shortcuts, titleKey: "settings.section.keyboard_shortcuts", iconSystemName: "command.square"),
                    TDSettingSidebarItem(id: .universal, titleKey: "settings.section.universal", iconSystemName: "gearshape.2"),
                    TDSettingSidebarItem(id: .about, titleKey: "settings.section.about", iconSystemName: "info.circle")
                ]
            )
        ]
    }
}

final class TDSettingsSidebarStore: ObservableObject {
    static let shared = TDSettingsSidebarStore()
    
    @Published private(set) var groups: [TDSettingSidebarGroup] = []
    @Published var selectedItemId: TDSettingItemID?
    
    private init() {
        TDPrepareSidebarDataIfNeeded()
    }
    
    func TDPrepareSidebarDataIfNeeded() {
        guard groups.isEmpty else { return }
        groups = TDSettingSidebarDataBuilder.buildDefaultGroups()
        if selectedItemId == nil {
            selectedItemId = groups.first?.items.first?.id
        }
    }
    
    func TDHandleSettingSelection(_ id: TDSettingItemID) {
        guard selectedItemId != id else { return }
        selectedItemId = id
    }
    
    func TDSettingItem(for id: TDSettingItemID) -> TDSettingSidebarItem? {
        for group in groups {
            if let match = group.items.first(where: { $0.id == id }) {
                return match
            }
        }
        return nil
    }
    
    var TDCurrentSelectedSidebarItem: TDSettingSidebarItem? {
        guard let id = selectedItemId else { return nil }
        return TDSettingItem(for: id)
    }
}
