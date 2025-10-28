//
//  TDSettingsView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/21.
//

import SwiftUI

/// 设置界面
struct TDSettingsView: View {
    @ObservedObject private var themeManager = TDThemeManager.shared
    @ObservedObject private var settingsManager = TDSettingsSectionManager.shared
    @State private var selectedSection: TDSettingsSectionType? = nil
    
    var body: some View {
        HSplitView {
            // 第一列：设置分类导航栏
            firstColumn
            
            // 第二列：设置详情内容
            secondColumn
        }
        .frame(width: 800, height: 600)
        .background(themeManager.backgroundColor)
    }
    
    /// 第一列：设置分类导航栏
    @ViewBuilder
    private var firstColumn: some View {
        List {
            ForEach(settingsManager.getAllGroups(), id: \.self) { group in
                let sections = settingsManager.getSettingsSections(for: group)
                
                if !sections.isEmpty {
                    // 分组标题
                    Section(header: groupHeaderView(for: group)) {
                        ForEach(sections) { section in
                            settingsSectionRow(section: section)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(themeManager.secondaryBackgroundColor)
        .frame(width: 180)
    }
    
    /// 第二列：设置详情内容
    @ViewBuilder
    private var secondColumn: some View {
        if let selectedSection = selectedSection {
            settingsDetailView(for: selectedSection)
        } else {
            // 默认内容
            VStack(spacing: 20) {
                Image(systemName: "gearshape")
                    .font(.system(size: 48))
                    .foregroundColor(themeManager.descriptionTextColor)
                
                Text("选择设置项")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeManager.titleTextColor)
                
                Text("从左侧列表中选择一个设置项")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.descriptionTextColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    /// 分组标题视图
    @ViewBuilder
    private func groupHeaderView(for group: TDSettingsGroup) -> some View {
        HStack {
            Text(group.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.descriptionTextColor)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(themeManager.secondaryBackgroundColor.opacity(0.5))
    }
    
    /// 设置项行视图
    @ViewBuilder
    private func settingsSectionRow(section: TDSettingsSectionModel) -> some View {
        Button(action: {
            selectedSection = section.type
            print("🔧 点击了设置项: \(section.title) (类型: \(section.type.rawValue))")
        }) {
            HStack(spacing: 12) {
                // 图标
                Image(systemName: section.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.titleTextColor)
                    .frame(width: 20, height: 20)
                
                // 标题
                Text(section.title)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.titleTextColor)
                
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 3)
            .background(
                selectedSection == section.type ?
                themeManager.selectedBackgroundColor :
                Color.clear
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }
    
    /// 设置详情视图
    @ViewBuilder
    private func settingsDetailView(for sectionType: TDSettingsSectionType) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // 导航栏（重点部分）
            HStack {
                // 后退按钮
                Button(action: {
                    // 后退逻辑
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.titleTextColor)
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
                
                // 前进按钮
                Button(action: {
                    // 前进逻辑
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.titleTextColor)
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
                
                // 标题
                Text(sectionType.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.titleTextColor)
                    .padding(.leading, 8)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // 设置内容
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("设置项: \(sectionType.displayName)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.titleTextColor)
                    
                    Text("类型: \(sectionType.rawValue)")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.descriptionTextColor)
                    
                    Text("此设置项的具体配置内容待完善...")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.descriptionTextColor)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    TDSettingsView()
}
