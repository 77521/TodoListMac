//
//  TDFocusDurationPresetView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/1/29.
//

import SwiftUI

/// 专注时长预设界面
struct TDFocusDurationPresetView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var settingManager: TDSettingManager
    @StateObject private var presetManager = TDFocusDurationPresetManager.shared
    @Binding var isPresented: Bool
    
    @State private var newFocusDuration = "5"
    @State private var newRestDuration = "1"
    @State private var isEditingFocus = false
    @State private var isEditingRest = false
    @FocusState private var isFocusFieldFocused: Bool
    @FocusState private var isRestFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView
            
            // 内容区域
            ScrollView {
                VStack(spacing: 24) {
                    // 专注时长预设
                    focusDurationSection
                    
                    // 休息时长预设
                    restDurationSection
                }
                .padding(.horizontal, 0)
                .padding(.vertical, 16)
            }
            
            // 底部按钮
            bottomButtons
        }
        .frame(width: 500, height: 400)
        .padding(.horizontal, 15)
        .background(themeManager.backgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onAppear {
            // 刷新当前选中的时长
            presetManager.objectWillChange.send()
        }
    }
    
    // MARK: - 标题栏
    private var headerView: some View {
        HStack {
            Text("修改番茄专注时长")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.color(level: 5))
            
            Spacer()
            
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.titleTextColor)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(themeManager.secondaryBackgroundColor)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 16)
        .background(themeManager.backgroundColor)
        .overlay(
            Rectangle()
                .fill(themeManager.separatorColor)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - 专注时长预设区域
    private var focusDurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("专注时长(分钟)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.titleTextColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(presetManager.focusPresets) { preset in
                    presetButton(
                        text: "\(preset.duration)",
                        isSelected: preset.duration == settingManager.focusDuration,
                        isCustom: preset.isCustom,
                        onTap: {
                            presetManager.setFocusDuration(preset.duration)
                        },
                        onDelete: preset.isCustom ? {
                            presetManager.removeFocusPreset(preset)
                        } : nil
                    )
                }
                
                // 添加预设输入框
                if isEditingFocus {
                    addPresetInputField(
                        text: $newFocusDuration,
                        placeholder: "输入专注时长",
                        onCommit: {
                            addFocusPreset()
                        },
                        focusState: $isFocusFieldFocused
                    )
                } else {
                    addPresetButton {
                        isEditingFocus = true
                        newFocusDuration = "5"
                    }
                }
            }
        }
    }
    
    // MARK: - 休息时长预设区域
    private var restDurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("休息时长(分钟)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.titleTextColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(presetManager.restPresets) { preset in
                    presetButton(
                        text: "\(preset.duration)",
                        isSelected: preset.duration == settingManager.restDuration,
                        isCustom: preset.isCustom,
                        onTap: {
                            presetManager.setRestDuration(preset.duration)
                        },
                        onDelete: preset.isCustom ? {
                            presetManager.removeRestPreset(preset)
                        } : nil
                    )
                }
                
                // 添加预设输入框
                if isEditingRest {
                    addPresetInputField(
                        text: $newRestDuration,
                        placeholder: "输入休息时长",
                        onCommit: {
                            addRestPreset()
                        },
                        focusState: $isRestFieldFocused
                    )
                } else {
                    addPresetButton {
                        isEditingRest = true
                        newRestDuration = "1"
                    }
                }
            }
        }
    }
    
    // MARK: - 预设按钮
    private func presetButton(
        text: String,
        isSelected: Bool,
        isCustom: Bool,
        onTap: @escaping () -> Void,
        onDelete: (() -> Void)?
    ) -> some View {
        ZStack {
            // 主按钮
            Button(action: onTap) {
                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : themeManager.titleTextColor)
                    .frame(maxWidth: .infinity, minHeight: 32)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? themeManager.color(level: 5) : themeManager.secondaryBackgroundColor)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .zIndex(1) // 确保主按钮在最上层
            
            // 删除按钮（仅自定义预设显示，放在右上角圆角处的中间）
            if let onDelete = onDelete, isCustom {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onDelete) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 16, height: 16)
                                .background(
                                    Circle()
                                        .fill(themeManager.descriptionTextColor)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .offset(x: 4, y: -4) // 向右上角偏移，放在圆角处的中间
                    }
                    Spacer()
                }
                .zIndex(2) // 删除按钮在最上层
            }
        }
    }
    
    // MARK: - 添加预设按钮
    private func addPresetButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("添加预设")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeManager.descriptionTextColor)
                .frame(maxWidth: .infinity, minHeight: 32)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(themeManager.secondaryBackgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(themeManager.borderColor, style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 添加预设输入框
    private func addPresetInputField(
        text: Binding<String>,
        placeholder: String,
        onCommit: @escaping () -> Void,
        focusState: FocusState<Bool>.Binding
    ) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(themeManager.titleTextColor)
            .frame(maxWidth: .infinity, minHeight: 32)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(themeManager.secondaryBackgroundColor)
            )
            .textFieldStyle(PlainTextFieldStyle())
            .focused(focusState)
            .onSubmit {
                // 在提交时验证和限制范围
                if let value = Int(text.wrappedValue) {
                    if value < 5 {
                        text.wrappedValue = "5"
                    } else if value > 120 {
                        text.wrappedValue = "120"
                    }
                }
                onCommit()
            }
            .onAppear {
                // 输入框出现时自动激活
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusState.wrappedValue = true
                }
            }
    }
    
    // MARK: - 添加预设方法
    private func addFocusPreset() {
        guard let duration = Int(newFocusDuration) else { return }
        
        // 检查是否重复
        if presetManager.focusPresets.contains(where: { $0.duration == duration }) {
            // TODO: 显示重复提示
            print("专注时长 \(duration) 已存在，不能重复添加")
            return
        }
        
        // 添加预设
        presetManager.addFocusPreset(duration)
        isEditingFocus = false
        newFocusDuration = "5"
    }
    
    private func addRestPreset() {
        guard let duration = Int(newRestDuration) else { return }
        
        // 检查是否重复
        if presetManager.restPresets.contains(where: { $0.duration == duration }) {
            // TODO: 显示重复提示
            print("休息时长 \(duration) 已存在，不能重复添加")
            return
        }
        
        // 添加预设
        presetManager.addRestPreset(duration)
        isEditingRest = false
        newRestDuration = "1"
    }
    
    // MARK: - 底部按钮
    private var bottomButtons: some View {
        HStack {
            Spacer()
            
            Button(action: {
                presetManager.restoreDefaults()
            }) {
                Text("恢复默认")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(themeManager.color(level: 5))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 16)
        .background(themeManager.backgroundColor)
        .overlay(
            Rectangle()
                .fill(themeManager.separatorColor)
                .frame(height: 1),
            alignment: .top
        )
    }
}


// MARK: - 预览
#Preview {
    TDFocusDurationPresetView(isPresented: .constant(true))
        .environmentObject(TDThemeManager.shared)
}
