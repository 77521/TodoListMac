//
//  TDRepeatManagementView.swift
//  TodoMacRepertorie
//
//  Created by Cursor on 2026/1/19.
//

import SwiftUI
import SwiftData

/// 设置 - 重复事件管理列表
/// 展示含重复ID（standbyStr1）的事件分组入口，点击后续处理
/// 设置页的“重复事件管理”列表视图（点击行弹出旧版 sheet 详情）
struct TDRepeatManagementSettingsView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    
    // 数据源：每个重复ID只保留一条事件作为入口
    @State private var repeatEntries: [TDMacSwiftDataListModel] = []
    @State private var sheetTask: TDMacSwiftDataListModel?
    // 加载态与错误信息
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                
                TDSettingsCardContainer {
                    if isLoading {
                        // 加载中提示
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("common.loading".localized)
                                .foregroundColor(themeManager.descriptionTextColor)
                                .font(.system(size: 13))
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else if let errorMessage {
                        // 错误提示
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 13))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 16)
                    } else if repeatEntries.isEmpty {
                        // 空态提示
                        Text("settings.repeat_management.empty".localized)
                            .foregroundColor(themeManager.descriptionTextColor)
                            .font(.system(size: 13))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 16)
                    } else {
                        // 列表展示
                        ForEach(repeatEntries.indices, id: \.self) { index in
                            let entry = repeatEntries[index]
                            Button {
                                handleRepeatTap(entry)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .foregroundColor(themeManager.color(level: 6))
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        // 事件标题
                                        Text(entry.taskContent)
                                            .foregroundColor(themeManager.titleTextColor)
                                            .font(.system(size: 15, weight: .medium))
                                            .lineLimit(1)
                                        
                                        // 重复ID 辅助信息
                                        if let repeatId = entry.standbyStr1, !repeatId.isEmpty {
                                            Text("ID: \(repeatId)")
                                                .foregroundColor(themeManager.descriptionTextColor)
                                                .font(.system(size: 12))
                                                .lineLimit(1)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(themeManager.descriptionTextColor)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            // 分割线（最后一行不显示）
                            if index < repeatEntries.count - 1 {
                                TDSettingsDivider()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 22)
        }
        .onAppear {
            // 首次进入时拉取数据
            loadRepeatEntriesIfNeeded()
        }
        .sheet(item: $sheetTask) { task in
            let presentedBinding = Binding<Bool>(
                get: { sheetTask != nil },
                set: { if !$0 { sheetTask = nil } }
            )
            
            TDRepeatManagementView(
                isPresented: presentedBinding,
                task: task
            )
            .environmentObject(themeManager)
            .environment(\.modelContext, modelContext)
            .presentationDragIndicator(.visible)
        }
    }
    
    /// 顶部说明区域：标题 + 描述
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("settings.repeat_management.page.title".localized)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(themeManager.titleTextColor)
            
            Text("settings.repeat_management.page.subtitle".localized)
                .font(.system(size: 13))
                .foregroundColor(themeManager.descriptionTextColor)
        }
    }
    
    /// 拉取含重复ID的入口数据，应用层去重
    private func loadRepeatEntriesIfNeeded() {
        guard repeatEntries.isEmpty, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let data = try await TDQueryConditionManager.shared.getUniqueDuplicateEntries(context: modelContext)
                await MainActor.run {
                    repeatEntries = data
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    /// 点击重复事件入口：弹出旧版 sheet
    private func handleRepeatTap(_ entry: TDMacSwiftDataListModel) {
        sheetTask = entry
    }
}

#Preview {
    TDRepeatManagementSettingsView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
        .environmentObject(TDSettingsSidebarStore.shared)
        .modelContainer(for: [TDMacSwiftDataListModel.self], inMemory: true)
}
