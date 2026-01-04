//
//  TDSettingRowTrailingContent.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/12/12.
//

import Foundation

/// 详情页行尾展示内容类型
enum TDSettingRowTrailingContent: Hashable {
    /// 文本信息（例如账号、状态）+ 可选图标或箭头
    case info(value: String?, iconSystemName: String? = nil, showsDisclosure: Bool = true)
    /// 开关按钮
    case toggle(isOn: Bool)
    /// 选择器
    case picker(selectedTitle: String?, options: [TDSettingPickerOption])
}

/// Picker option
struct TDSettingPickerOption: Identifiable, Hashable {
    let id: UUID
    let title: String
    
    init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
}

/// 详情页通用行模型
struct TDSettingDetailRowModel: Identifiable, Hashable {
    let id: UUID
    let title: String
    /// 副标题，可展示在主标题下方
    var subtitle: String?
    /// 顶部右侧信息/控件
    var trailingContent: TDSettingRowTrailingContent
    /// 可控制行的可用状态
    var isEnabled: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String? = nil,
        trailingContent: TDSettingRowTrailingContent,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.trailingContent = trailingContent
        self.isEnabled = isEnabled
    }
}
