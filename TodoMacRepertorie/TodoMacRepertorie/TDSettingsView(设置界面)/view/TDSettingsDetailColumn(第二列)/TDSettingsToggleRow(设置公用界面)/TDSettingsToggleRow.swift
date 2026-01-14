//
//  TDSettingsToggleRow.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/4.
//

import SwiftUI

/// 开关行（标题 + 主题色开关）
struct TDSettingsToggleRow: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(themeManager.titleTextColor)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(ThemedSwitchToggleStyle(onColor: themeManager.color(level: 5)))
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

/// 组尾文案（小号灰色文字，左对齐）
struct TDSettingsFooterText: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(themeManager.descriptionTextColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 10)
            .padding(.leading, 12)
    }
}

/// 卡片容器（统一圆角与背景）
struct TDSettingsCardContainer<Content: View>: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(themeManager.backgroundColor)
        )
    }
}

/// 分割线
struct TDSettingsDivider: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    var body: some View {
        Rectangle()
            .fill(themeManager.separatorColor)
            .frame(height: 1)
            .padding(.leading, 0)
    }
}

/// 信息行（标题 + 可选值 + 可选箭头）
struct TDSettingsInfoRow: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    let title: String
    let value: String?
    let showsDisclosure: Bool
    
    init(title: String, value: String?, showsDisclosure: Bool = true) {
        self.title = title
        self.value = value
        self.showsDisclosure = showsDisclosure
    }
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(themeManager.titleTextColor)
            Spacer()
            if let value {
                Text(value)
                    .foregroundColor(themeManager.descriptionTextColor)
            }
            if showsDisclosure {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeManager.descriptionTextColor)
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
/// 绑定行（绑定/未绑定 + 可选副标题 + 箭头）
struct TDSettingsBindingRow: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    let title: String
    let subtitle: String?
    let bound: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 4) {
                Text(title)
                    .foregroundColor(themeManager.titleTextColor)
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 10))
                        .foregroundColor(themeManager.descriptionTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Text(bound ? "settings.account.bound".localized : "settings.account.unbound".localized)
                .foregroundColor(bound ? themeManager.color(level: 5) : themeManager.descriptionTextColor)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.descriptionTextColor)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}


/// 选择行（标题 + Picker），支持根据内容自适应宽度
struct TDSettingsPickerRow<T: Hashable>: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    let title: String
    let options: [(String, T)]
    @Binding var selection: T
    /// 可选自定义宽度，默认根据最长文案计算
    var fixedWidth: CGFloat?
    
    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundColor(themeManager.titleTextColor)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.1) { item in
                    Text(item.0).tag(item.1)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: pillWidth(for: title))
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    
    /// 计算最长文案宽度 + padding，限制最小/最大
        private func pillWidth(for text: String) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 13, weight: .regular)
        let longest = options.map { ($0.0 as NSString).size(withAttributes: [.font: font]).width }.max() ?? 60
        let padding: CGFloat = 18 + 15// 左右总 padding
        let minW: CGFloat = 64
        let maxW: CGFloat = 200
        return min(max(longest + padding, minW), maxW)
    }
}
