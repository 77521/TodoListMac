//
//  TDSettingsSectionModel.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/21.
//

import Foundation

/// 设置分组类型枚举
enum TDSettingsSectionType: String, CaseIterable, Codable {
    // 账户与安全
    case accountSecurity = "account_security"
    
    // 常规
    case general = "general"
    
    // 功能模块
    case featureModules = "feature_modules"
    
    // 外观
    case appearance = "appearance"
    
    // 事件
    case events = "events"
    
    // 语音添加与智能识别
    case voiceInput = "voice_input"
    
    // 微信消息提醒
    case wechatReminder = "wechat_reminder"
    
    // 番茄专注
    case pomodoroFocus = "pomodoro_focus"
    
    // 日程概览
    case scheduleOverview = "schedule_overview"
    
    // 图片与文件管理
    case imageFileManagement = "image_file_management"
    
    // 重复事件管理
    case repeatEventManagement = "repeat_event_management"
    
    // 系统日历订阅管理
    case systemCalendarSubscription = "system_calendar_subscription"
    
    // 日历提醒校正
    case calendarReminderCorrection = "calendar_reminder_correction"
    
    // 用户注册协议
    case userRegistrationAgreement = "user_registration_agreement"
    
    // 隐私政策
    case privacyPolicy = "privacy_policy"
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .accountSecurity:
            return "账户与安全"
        case .general:
            return "常规"
        case .featureModules:
            return "功能模块"
        case .appearance:
            return "外观"
        case .events:
            return "事件"
        case .voiceInput:
            return "语音添加与智能识别"
        case .wechatReminder:
            return "微信消息提醒"
        case .pomodoroFocus:
            return "番茄专注"
        case .scheduleOverview:
            return "日程概览"
        case .imageFileManagement:
            return "图片与文件管理"
        case .repeatEventManagement:
            return "重复事件管理"
        case .systemCalendarSubscription:
            return "系统日历订阅管理"
        case .calendarReminderCorrection:
            return "日历提醒校正"
        case .userRegistrationAgreement:
            return "用户注册协议"
        case .privacyPolicy:
            return "隐私政策"
        }
    }
    
    /// 图标名称
    var iconName: String {
        switch self {
        case .accountSecurity:
            return "person.badge.shield.checkmark"
        case .general:
            return "gearshape"
        case .featureModules:
            return "calendar"
        case .appearance:
            return "eye"
        case .events:
            return "checkmark.square"
        case .voiceInput:
            return "mic"
        case .wechatReminder:
            return "bubble.left.and.bubble.right"
        case .pomodoroFocus:
            return "timer"
        case .scheduleOverview:
            return "calendar"
        case .imageFileManagement:
            return "doc.badge.image"
        case .repeatEventManagement:
            return "arrow.clockwise"
        case .systemCalendarSubscription:
            return "calendar"
        case .calendarReminderCorrection:
            return "wrench"
        case .userRegistrationAgreement:
            return "doc.text"
        case .privacyPolicy:
            return "doc.text"
        }
    }
}

/// 设置项分组枚举
enum TDSettingsGroup: String, CaseIterable, Codable {
    case account = "account"
    case general = "general"
    case features = "features"
    case management = "management"
    case legal = "legal"
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .account:
            return "账户与安全"
        case .general:
            return "常规设置"
        case .features:
            return "功能模块"
        case .management:
            return "管理工具"
        case .legal:
            return "法律条款"
        }
    }
}

/// 设置分组数据模型
struct TDSettingsSectionModel: Identifiable, Codable, Hashable {
    /// 唯一标识符
    let id: String
    
    /// 图标名称
    let iconName: String
    
    /// 标题
    let title: String
    
    /// 类型
    let type: TDSettingsSectionType
    
    /// 分组
    let group: TDSettingsGroup
    
    /// 是否启用
    var isEnabled: Bool
    
    /// 排序权重（用于排序）
    var sortWeight: Int
    
    /// 初始化方法
    init(
        iconName: String,
        title: String,
        type: TDSettingsSectionType,
        group: TDSettingsGroup,
        isEnabled: Bool = true,
        sortWeight: Int = 0
    ) {
        self.id = UUID().uuidString
        self.iconName = iconName
        self.title = title
        self.type = type
        self.group = group
        self.isEnabled = isEnabled
        self.sortWeight = sortWeight
    }
    
    /// 从类型创建设置分组
    static func fromType(_ type: TDSettingsSectionType, group: TDSettingsGroup) -> TDSettingsSectionModel {
        return TDSettingsSectionModel(
            iconName: type.iconName,
            title: type.displayName,
            type: type,
            group: group
        )
    }
}

/// 设置分组管理器
class TDSettingsSectionManager: ObservableObject {
    static let shared = TDSettingsSectionManager()
    
    @Published var settingsSections: [TDSettingsSectionModel] = []
    
    private init() {
        loadDefaultSettings()
    }
    
    /// 加载默认设置分组
    private func loadDefaultSettings() {
        settingsSections = [
            // 账户与安全
            TDSettingsSectionModel.fromType(.accountSecurity, group: .account),
            
            // 常规设置
            TDSettingsSectionModel.fromType(.general, group: .general),
            TDSettingsSectionModel.fromType(.appearance, group: .general),
            
            // 功能模块
            TDSettingsSectionModel.fromType(.featureModules, group: .features),
            TDSettingsSectionModel.fromType(.events, group: .features),
            TDSettingsSectionModel.fromType(.voiceInput, group: .features),
            TDSettingsSectionModel.fromType(.wechatReminder, group: .features),
            TDSettingsSectionModel.fromType(.pomodoroFocus, group: .features),
            TDSettingsSectionModel.fromType(.scheduleOverview, group: .features),
            
            // 管理工具
            TDSettingsSectionModel.fromType(.imageFileManagement, group: .management),
            TDSettingsSectionModel.fromType(.repeatEventManagement, group: .management),
            TDSettingsSectionModel.fromType(.systemCalendarSubscription, group: .management),
            TDSettingsSectionModel.fromType(.calendarReminderCorrection, group: .management),
            
            // 法律条款
            TDSettingsSectionModel.fromType(.userRegistrationAgreement, group: .legal),
            TDSettingsSectionModel.fromType(.privacyPolicy, group: .legal)
        ]
    }
    
    /// 根据分组获取设置分组
    func getSettingsSections(for group: TDSettingsGroup) -> [TDSettingsSectionModel] {
        return settingsSections
            .filter { $0.group == group }
            .sorted { $0.sortWeight < $1.sortWeight }
    }
    
    /// 获取所有分组
    func getAllGroups() -> [TDSettingsGroup] {
        return TDSettingsGroup.allCases
    }
    
    /// 根据类型查找设置分组
    func getSettingsSection(for type: TDSettingsSectionType) -> TDSettingsSectionModel? {
        return settingsSections.first { $0.type == type }
    }
}
