//
//  TDSidebarSettingsColumn.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/12/5.
//

import SwiftUI

struct TDSidebarSettingsColumn: View {
    @EnvironmentObject private var settingManager: TDSettingManager
    @EnvironmentObject private var sidebarStore: TDSettingsSidebarStore
    @EnvironmentObject private var themeManager: TDThemeManager
    
    private var selectionColor: Color {
        themeManager.color(level: 4)
            .opacity(0.1)
    }
    
    private var iconColor: Color {
        themeManager.color(level: 5)
    }

    
    var body: some View {
        
        
//        VStack(spacing: 0) {
            // 顶部固定区域（不滚动）
//            Rectangle()
//                .fill(.red)
//                .frame(width: 280,height: 40)
            
            
            List {
                
                
                ForEach(sidebarStore.groups.indices, id: \.self) { index in
                    let group = sidebarStore.groups[index]
                    Section {
                        ForEach(group.items) { item in
                            sidebarRow(for: item)
                                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                                .listRowBackground(Color.clear)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .padding(.top, 40)
            .scrollIndicators(.hidden)
//            .padding(.bottom,50)
            .listRowSeparator(.hidden)
            .scrollContentBackground(.hidden)
            .background(
                TDVisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    .overlay(Color.black.opacity(settingManager.isDarkMode ? 0.2 : 0.05))
            )
//        }

       
    }
    
    @ViewBuilder
    private func sidebarRow(for item: TDSettingSidebarItem) -> some View {
        let isSelected = sidebarStore.selectedItemId == item.id
        
        Button {
            sidebarStore.TDHandleSettingSelection(item.id)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: item.iconSystemName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24, alignment: .center)

                Text(item.titleKey.localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.titleTextColor)
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? selectionColor : Color.clear)
            )
            .contentShape(Rectangle())

        }
        .buttonStyle(.plain)
//        .contentShape(Rectangle())
    }
    
//    private func iconColor(for id: TDSettingItemID) -> Color {
//        switch id {
//        case .accountSecurity, .premium:
//            return Color.red.opacity(0.9)
//        case .general, .featureModules, .theme, .appIcon:
//            return Color.blue.opacity(0.9)
//        case .eventSettings, .scheduleOverview, .smartRecognition, .pomodoroFocus:
//            return Color.orange.opacity(0.9)
//        case .repeatManagement, .assetManagement:
//            return Color.green.opacity(0.9)
//        case .shortcuts, .universal, .about:
//            return Color.purple.opacity(0.9)
//        }
//    }
}

#Preview {
    TDSidebarSettingsColumn()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
        .environmentObject(TDSettingsSidebarStore.shared)
        .frame(width: 280)
}
