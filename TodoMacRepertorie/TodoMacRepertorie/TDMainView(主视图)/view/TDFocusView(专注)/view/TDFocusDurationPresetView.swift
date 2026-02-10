////
////  TDFocusDurationPresetView.swift
////  TodoMacRepertorie
////
////  Created by 赵浩 on 2025/1/29.
////
//
//import SwiftUI
//
///// 专注时长预设界面
//struct TDFocusDurationPresetView: View {
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @EnvironmentObject private var settingManager: TDSettingManager
//
//    @StateObject private var presetManager = TDFocusDurationPresetManager.shared
//    @Binding var isPresented: Bool
//    
//    @State private var newFocusDuration = "5"
//    @State private var newRestDuration = "1"
//    @State private var isEditingFocus = false
//    @State private var isEditingRest = false
//    @FocusState private var isFocusFieldFocused: Bool
//    @FocusState private var isRestFieldFocused: Bool
//    
//    // 本地 Toast 状态
//    @State private var showToast = false
//    @State private var toastMessage = ""
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // 标题栏
//            headerView
//                .padding(.horizontal,15)
//
//            // 内容区域
//            ScrollView {
//                VStack(spacing: 24) {
//                    // 专注时长预设
//                    focusDurationSection
//                        .padding(.horizontal,15)
//                    
//                    // 休息时长预设
//                    restDurationSection
//                        .padding(.horizontal,15)
//
//                }
//                .padding(.horizontal, 0)
//                .padding(.vertical, 16)
//                
//            }
//            .scrollIndicators(.hidden)
//            .padding(.horizontal,0)
//            // 底部按钮
//            bottomButtons
//                .padding(.horizontal,15)
//
//        }
//        .frame(width: 500, height: 400)
////        .padding(.horizontal, 10)
//        .background(themeManager.backgroundColor)
//        .cornerRadius(12)
//        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
//        .onTapGesture {
//            // 点击空白处时结束编辑
//            endEditing()
//        }
//        .onAppear {
//            // 刷新当前选中的时长
//            presetManager.objectWillChange.send()
//        }
//        // 本地 Toast 提示（顶部显示）
//        .tdToastTop(
//            isPresenting: $showToast,
//            message: toastMessage,
//            type: .error
//        )
//
//    }
//    
//    // MARK: - 标题栏
//    private var headerView: some View {
//        HStack {
//            Text("focus_duration_preset_title".localized)
//                .font(.system(size: 16, weight: .medium))
//                .foregroundColor(themeManager.color(level: 5))
//            
//            Spacer()
//            
//            Button(action: {
//                isPresented = false
//            }) {
//                Image(systemName: "xmark")
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(themeManager.titleTextColor)
//                    .frame(width: 24, height: 24)
//                    .background(
//                        Circle()
//                            .fill(themeManager.secondaryBackgroundColor)
//                    )
//            }
//            .pointingHandCursor()
//            .buttonStyle(PlainButtonStyle())
//        }
//        .padding(.horizontal, 0)
//        .padding(.vertical, 16)
//        .background(themeManager.backgroundColor)
//        .overlay(
//            Rectangle()
//                .fill(themeManager.separatorColor)
//                .frame(height: 1),
//            alignment: .bottom
//        )
//    }
//    
//    // MARK: - 专注时长预设区域
//    private var focusDurationSection: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("focus_duration_label".localized)
//                .font(.system(size: 14, weight: .medium))
//                .foregroundColor(themeManager.titleTextColor)
//            
//            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
//                ForEach(presetManager.focusPresets) { preset in
//                    PresetItemView(
//                        text: "\(preset.duration)",
//                        isSelected: preset.duration == settingManager.focusDuration,
//                        isCustom: preset.isCustom,
//                        onTap: {
//                            presetManager.setFocusDuration(preset.duration)
//                        },
//                        onDelete: (preset.isCustom && preset.duration != settingManager.focusDuration) ? {
//                            presetManager.removeFocusPreset(preset)
//                        } : nil
//                    )
//                }
//                
//                // 添加预设输入框
//                if isEditingFocus {
//                    addPresetInputField(
//                        text: $newFocusDuration,
//                        placeholder: "focus_duration_placeholder".localized,
//                        onCommit: {
//                            addFocusPreset()
//                        },
//                        focusState: $isFocusFieldFocused,
//                        isFocusDuration: true
//                    )
//                } else {
//                    addPresetButton {
//                        isEditingFocus = true
//                        newFocusDuration = "5"
//                    }
//                }
//            }
//        }
//    }
//    
//    // MARK: - 休息时长预设区域
//    private var restDurationSection: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("rest_duration_label".localized)
//                .font(.system(size: 14, weight: .medium))
//                .foregroundColor(themeManager.titleTextColor)
//            
//            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
//                ForEach(presetManager.restPresets) { preset in
//                    PresetItemView(
//                        text: "\(preset.duration)",
//                        isSelected: preset.duration == settingManager.restDuration,
//                        isCustom: preset.isCustom,
//                        onTap: {
//                            presetManager.setRestDuration(preset.duration)
//                        },
//                        onDelete: (preset.isCustom && preset.duration != settingManager.restDuration) ? {
//                            presetManager.removeRestPreset(preset)
//                        } : nil
//                    )
//                }
//                
//                // 添加预设输入框
//                if isEditingRest {
//                    addPresetInputField(
//                        text: $newRestDuration,
//                        placeholder: "rest_duration_placeholder".localized,
//                        onCommit: {
//                            addRestPreset()
//                        },
//                        focusState: $isRestFieldFocused,
//                        isFocusDuration: false
//                    )
//                } else {
//                    addPresetButton {
//                        isEditingRest = true
//                        newRestDuration = "1"
//                    }
//                }
//            }
//        }
//    }
//    
//    // MARK: - 添加预设按钮
//    private func addPresetButton(action: @escaping () -> Void) -> some View {
//        Button(action: action) {
//            Text("add_preset_button".localized)
//                .font(.system(size: 13, weight: .medium))
//                .foregroundColor(themeManager.descriptionTextColor)
//                .frame(maxWidth: .infinity, minHeight: 32)
//                .padding(.horizontal, 12)
//                .background(
//                    RoundedRectangle(cornerRadius: 6)
//                        .fill(themeManager.secondaryBackgroundColor)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 6)
//                                .stroke(themeManager.borderColor, style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
//                        )
//                )
//        }
//        .buttonStyle(PlainButtonStyle())
//        .pointingHandCursor()
//    }
//    
//    // MARK: - 添加预设输入框
//    private func addPresetInputField(
//        text: Binding<String>,
//        placeholder: String,
//        onCommit: @escaping () -> Void,
//        focusState: FocusState<Bool>.Binding,
//        isFocusDuration: Bool = true
//    ) -> some View {
//        TextField(placeholder, text: text)
//            .font(.system(size: 13))
//            .foregroundColor(themeManager.titleTextColor)
//            .frame(maxWidth: .infinity, minHeight: 32)
//            .padding(.horizontal, 12)
//            .background(
//                RoundedRectangle(cornerRadius: 6)
//                    .fill(themeManager.secondaryBackgroundColor)
//            )
//            .textFieldStyle(PlainTextFieldStyle())
//            .focused(focusState)
////            .onChange(of: text.wrappedValue) { _, newValue in
////                // 实时验证输入内容
////                validateInput(newValue)
////            }
//            .onSubmit {
//                // 提交时验证并执行操作
//                if isFocusDuration {
//                    validateAndCommit()
//                } else {
//                    validateAndCommitRest()
//                }
//            }
//            .onChange(of: focusState.wrappedValue) { _, isFocused in
//                // 当失去焦点时，执行验证和提交
//                if !isFocused {
//                    if isFocusDuration {
//                        validateAndCommit()
//                    } else {
//                        validateAndCommitRest()
//                    }
//                }
//            }
//            .onAppear {
//                // 输入框出现时自动激活焦点
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    focusState.wrappedValue = true
//                }
//            }
//    }
//    
//    // MARK: - 输入验证
//    private func validateInput(_ input: String) {
//        // 只允许输入数字
//        let filtered = input.filter { $0.isNumber }
//        if filtered != input {
//            newFocusDuration = filtered
//        }
//    }
//    // MARK: - 通用验证方法
//    private func validateDuration(_ input: String, defaultValue: String, minValue: Int = 5, maxValue: Int = 120) -> String {
//        guard let value = Int(input) else {
//            return defaultValue
//        }
//        
//        // 限制范围
//        let clampedValue = max(minValue, min(maxValue, value))
//        return String(clampedValue)
//    }
//
//    // MARK: - 验证并提交
//    private func validateAndCommit() {
//        let validatedValue = validateDuration(newFocusDuration, defaultValue: "25")
//        newFocusDuration = validatedValue
//        addFocusPreset()
//    }
//    
//    // MARK: - 验证并提交休息时长
//    private func validateAndCommitRest() {
//        let validatedValue = validateDuration(newRestDuration, defaultValue: "5")
//        newRestDuration = validatedValue
//        addRestPreset()
//    }
//    
//    // MARK: - 结束编辑
//    private func endEditing() {
//        // 如果当前有输入内容，先保存
//        if isFocusFieldFocused && !newFocusDuration.isEmpty {
//            validateAndCommit()
//        }
//        if isRestFieldFocused && !newRestDuration.isEmpty {
//            validateAndCommitRest()
//        }
//        
//        // 结束所有输入框的编辑状态
//        isFocusFieldFocused = false
//        isRestFieldFocused = false
//        isEditingFocus = false
//        isEditingRest = false
//    }
//
//    // MARK: - 添加预设方法
//    private func addFocusPreset() {
//        guard let duration = Int(newFocusDuration) else { return }
//        
//        // 检查是否重复
//        if presetManager.focusPresets.contains(where: { $0.duration == duration }) {
//            // TODO: 显示重复提示
//            print("专注时长 \(duration) 已存在，不能重复添加")
//            toastMessage = String(format: "focus_duration_exists".localized, duration)
//            showToast = true
//
//            return
//        }
//        
//        // 添加预设
//        presetManager.addFocusPreset(duration)
//        isEditingFocus = false
//        newFocusDuration = "5"
//    }
//    
//    private func addRestPreset() {
//        guard let duration = Int(newRestDuration) else { return }
//        
//        // 检查是否重复
//        if presetManager.restPresets.contains(where: { $0.duration == duration }) {
//            // TODO: 显示重复提示
//            print("休息时长 \(duration) 已存在，不能重复添加")
//            toastMessage = String(format: "rest_duration_exists".localized, duration)
//            showToast = true
//
//            return
//        }
//        
//        // 添加预设
//        presetManager.addRestPreset(duration)
//        isEditingRest = false
//        newRestDuration = "1"
//    }
//    
//    // MARK: - 底部按钮
//    private var bottomButtons: some View {
//        HStack {
//            Spacer()
//            
//            Button(action: {
//                presetManager.restoreDefaults()
//            }) {
//                Text("restore_default_button".localized)
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 16)
//                    .padding(.vertical, 8)
//                    .background(
//                        RoundedRectangle(cornerRadius: 6)
//                            .fill(themeManager.color(level: 5))
//                    )
//            }
//            .buttonStyle(PlainButtonStyle())
//            .pointingHandCursor()
//        }
//        .padding(.horizontal, 0)
//        .padding(.vertical, 16)
//        .background(themeManager.backgroundColor)
//        .overlay(
//            Rectangle()
//                .fill(themeManager.separatorColor)
//                .frame(height: 1),
//            alignment: .top
//        )
//    }
//}
//
//// MARK: - 子视图：单个预设项
//private struct PresetItemView: View {
//    @EnvironmentObject private var themeManager: TDThemeManager
//    let text: String
//    let isSelected: Bool
//    let isCustom: Bool
//    let onTap: () -> Void
//    let onDelete: (() -> Void)?
//    
//    @State private var isHovering: Bool = false
//    
//    var body: some View {
//        ZStack {
//            // 主按钮
//            Button(action: onTap) {
//                Text(text)
//                    .font(.system(size: 13, weight: .medium))
//                    .foregroundColor(isSelected ? .white : themeManager.titleTextColor)
//                    .frame(maxWidth: .infinity, minHeight: 32)
//                    .padding(.horizontal, 12)
//                    .background(
//                        RoundedRectangle(cornerRadius: 6)
//                            .fill(isSelected ? themeManager.color(level: 5) : themeManager.secondaryBackgroundColor)
//                    )
//            }
//            .buttonStyle(PlainButtonStyle())
//            .pointingHandCursor()
//            .zIndex(1)
//            
//            // 删除按钮（仅自定义 + 未选中 + 悬停）
//            if let onDelete,
//               isCustom,
//               !isSelected,
//               isHovering {
//                VStack {
//                    HStack {
//                        Spacer()
//                        Button(action: onDelete) {
//                            Image(systemName: "xmark")
//                                .font(.system(size: 9, weight: .medium))
//                                .foregroundColor(.white)
//                                .frame(width: 14, height: 14)
//                                .background(
//                                    Circle()
//                                        .fill(themeManager.descriptionTextColor)
//                                )
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                        .pointingHandCursor()
//                    }
//                    Spacer()
//                }
//                .zIndex(2)
//                .clipped()
//            }
//        }
//        .onHover { isHovering = $0 }
//        .clipped()
//    }
//}
//
//
//
//// MARK: - 预览
//#Preview {
//    TDFocusDurationPresetView(isPresented: .constant(true))
//        .environmentObject(TDThemeManager.shared)
//}


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
                .padding(.horizontal,15)

            // 内容区域
            ScrollView {
                VStack(spacing: 24) {
                    // 专注时长预设
                    focusDurationSection
                        .padding(.horizontal,15)
                    
                    // 休息时长预设
                    restDurationSection
                        .padding(.horizontal,15)

                }
                .padding(.horizontal, 0)
                .padding(.vertical, 16)
                
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal,0)
            // 底部按钮
            bottomButtons
                .padding(.horizontal,15)

        }
        .frame(width: 500, height: 400)
//        .padding(.horizontal, 10)
        .background(themeManager.backgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onTapGesture {
            // 点击空白处时结束编辑
            endEditing()
        }
        .onAppear {
            // 刷新当前选中的时长
            presetManager.objectWillChange.send()
        }

    }
    
    // MARK: - 标题栏
    private var headerView: some View {
        HStack {
            Text("focus_duration_preset_title".localized)
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
            .pointingHandCursor()
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
            Text("focus_duration_label".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.titleTextColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(presetManager.focusPresets) { preset in
                    PresetItemView(
                        text: "\(preset.duration)",
                        isSelected: preset.duration == settingManager.focusDuration,
                        isCustom: preset.isCustom,
                        onTap: {
                            presetManager.setFocusDuration(preset.duration)
                        },
                        onDelete: (preset.isCustom && preset.duration != settingManager.focusDuration) ? {
                            presetManager.removeFocusPreset(preset)
                        } : nil
                    )
                }
                
                // 添加预设输入框
                if isEditingFocus {
                    addPresetInputField(
                        text: $newFocusDuration,
                        placeholder: "focus_duration_placeholder".localized,
                        onCommit: {
                            addFocusPreset()
                        },
                        focusState: $isFocusFieldFocused,
                        isFocusDuration: true
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
            Text("rest_duration_label".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.titleTextColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(presetManager.restPresets) { preset in
                    PresetItemView(
                        text: "\(preset.duration)",
                        isSelected: preset.duration == settingManager.restDuration,
                        isCustom: preset.isCustom,
                        onTap: {
                            presetManager.setRestDuration(preset.duration)
                        },
                        onDelete: (preset.isCustom && preset.duration != settingManager.restDuration) ? {
                            presetManager.removeRestPreset(preset)
                        } : nil
                    )
                }
                
                // 添加预设输入框
                if isEditingRest {
                    addPresetInputField(
                        text: $newRestDuration,
                        placeholder: "rest_duration_placeholder".localized,
                        onCommit: {
                            addRestPreset()
                        },
                        focusState: $isRestFieldFocused,
                        isFocusDuration: false
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
    
    // MARK: - 添加预设按钮
    private func addPresetButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("add_preset_button".localized)
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
        .pointingHandCursor()
    }
    
    // MARK: - 添加预设输入框
    private func addPresetInputField(
        text: Binding<String>,
        placeholder: String,
        onCommit: @escaping () -> Void,
        focusState: FocusState<Bool>.Binding,
        isFocusDuration: Bool = true
    ) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 13))
            .foregroundColor(themeManager.titleTextColor)
            .frame(maxWidth: .infinity, minHeight: 32)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(themeManager.secondaryBackgroundColor)
            )
            .textFieldStyle(PlainTextFieldStyle())
            .focused(focusState)
//            .onChange(of: text.wrappedValue) { _, newValue in
//                // 实时验证输入内容
//                validateInput(newValue)
//            }
            .onSubmit {
                // 提交时验证并执行操作
                if isFocusDuration {
                    validateAndCommit()
                } else {
                    validateAndCommitRest()
                }
            }
            .onChange(of: focusState.wrappedValue) { _, isFocused in
                // 当失去焦点时，执行验证和提交
                if !isFocused {
                    if isFocusDuration {
                        validateAndCommit()
                    } else {
                        validateAndCommitRest()
                    }
                }
            }
            .onAppear {
                // 输入框出现时自动激活焦点
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusState.wrappedValue = true
                }
            }
    }
    
    // MARK: - 输入验证
    private func validateInput(_ input: String) {
        // 只允许输入数字
        let filtered = input.filter { $0.isNumber }
        if filtered != input {
            newFocusDuration = filtered
        }
    }
    // MARK: - 通用验证方法
    private func validateDuration(_ input: String, defaultValue: String, minValue: Int = 5, maxValue: Int = 120) -> String {
        guard let value = Int(input) else {
            return defaultValue
        }
        
        // 限制范围
        let clampedValue = max(minValue, min(maxValue, value))
        return String(clampedValue)
    }

    // MARK: - 验证并提交
    private func validateAndCommit() {
        let validatedValue = validateDuration(newFocusDuration, defaultValue: "25")
        newFocusDuration = validatedValue
        addFocusPreset()
    }
    
    // MARK: - 验证并提交休息时长
    private func validateAndCommitRest() {
        let validatedValue = validateDuration(newRestDuration, defaultValue: "5")
        newRestDuration = validatedValue
        addRestPreset()
    }
    
    // MARK: - 结束编辑
    private func endEditing() {
        // 如果当前有输入内容，先保存
        if isFocusFieldFocused && !newFocusDuration.isEmpty {
            validateAndCommit()
        }
        if isRestFieldFocused && !newRestDuration.isEmpty {
            validateAndCommitRest()
        }
        
        // 结束所有输入框的编辑状态
        isFocusFieldFocused = false
        isRestFieldFocused = false
        isEditingFocus = false
        isEditingRest = false
    }

    // MARK: - 添加预设方法
    private func addFocusPreset() {
        guard let duration = Int(newFocusDuration) else { return }
        
        // 检查是否重复
        if presetManager.focusPresets.contains(where: { $0.duration == duration }) {
            // TODO: 显示重复提示
            print("专注时长 \(duration) 已存在，不能重复添加")
            TDToastCenter.shared.show(
                String(format: "focus_duration_exists".localized, duration),
                type: .error,
                position: .top
            )

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
            TDToastCenter.shared.show(
                String(format: "rest_duration_exists".localized, duration),
                type: .error,
                position: .top
            )

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
                Text("restore_default_button".localized)
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
            .pointingHandCursor()
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

// MARK: - 子视图：单个预设项
private struct PresetItemView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    let text: String
    let isSelected: Bool
    let isCustom: Bool
    let onTap: () -> Void
    let onDelete: (() -> Void)?
    
    @State private var isHovering: Bool = false
    
    var body: some View {
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
            .pointingHandCursor()
            .zIndex(1)
            
            // 删除按钮（仅自定义 + 未选中 + 悬停）
            if let onDelete,
               isCustom,
               !isSelected,
               isHovering {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onDelete) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 14, height: 14)
                                .background(
                                    Circle()
                                        .fill(themeManager.descriptionTextColor)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .pointingHandCursor()
                    }
                    Spacer()
                }
                .zIndex(2)
                .clipped()
            }
        }
        .onHover { isHovering = $0 }
        .clipped()
    }
}



// MARK: - 预览
#Preview {
    TDFocusDurationPresetView(isPresented: .constant(true))
        .environmentObject(TDThemeManager.shared)
}
