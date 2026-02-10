////
////  TDFocusView.swift
////  TodoMacRepertorie
////
////  Created by 孬孬 on 2024/12/28.
////
//
//import SwiftUI
//
///// 专注界面
//struct TDFocusView: View {
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @EnvironmentObject private var tomatoManager: TDTomatoManager
//    @EnvironmentObject private var mainViewModel: TDMainViewModel
//    @EnvironmentObject private var settingManager: TDSettingManager
//
//    @State private var timeRemaining: Int = 0 // 剩余时间，以秒为单位
//    @State private var isRunning: Bool = false
//    @State private var isCompleted: Bool = false // 专注完成状态
//    @State private var timer: Timer?
//    @State private var selectedSound: TDSoundModel = TDSoundModel.defaultSound // 默认选择白噪音
//    @State private var showAbandonAlert: Bool = false // 显示放弃确认弹窗
//    @State private var showSoundPicker: Bool = false // 显示声音选择弹窗
//    @State private var showFocusRecord: Bool = false // 显示专注记录弹窗
//    @State private var showDurationPreset: Bool = false // 显示时长预设弹窗
//    @State private var showToast: Bool = false // 显示Toast提示
//    @State private var toastMessage: String = "" // Toast消息内容
//
//    // 记录相关状态
//    @State private var focusStartTime: Date = Date() // 专注开始时间
//    @State private var focusEndTime: Date = Date() // 专注结束时间
//    @State private var restStartTime: Date = Date() // 休息开始时间
//    @State private var focusSuccess: Bool = false // 专注是否成功
//    @State private var restSuccess: Bool = false // 休息是否成功
//
//    // 实际专注和休息时间
//    @State private var actualFocusTime: Int = 0 // 实际专注时间（秒）
//    @State private var actualRestTime: Int = 0 // 实际休息时间（秒）
//
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // 顶部分割线
//            Rectangle()
//                .fill(themeManager.separatorColor)
//                .frame(height: 1)
//            
//            // 主要内容
//            HStack(spacing: 20) {
//                // 左侧状态区域
//                leftStatusArea
//                
//                // 中间计时器区域
//                centerTimerArea
//                
//                // 右侧专注按钮
//                rightFocusButton
//            }
//            .padding(.horizontal, 20)
//            .padding(.vertical, 16)
//            .frame(height: 80)
//            .background(backgroundMaterial)
//        }
//        .alert(alertTitle, isPresented: $showAbandonAlert) {
//            Button("取消", role: .cancel) {
//                // 取消操作，不做任何处理
//            }
//            Button("确定", role: .destructive) {
//                abandonFocus()
//            }
//        }
//        .sheet(isPresented: $showSoundPicker) {
//            TDSoundPickerView(
//                selectedSound: $selectedSound,
//                isPresented: $showSoundPicker
//            )
//            .environmentObject(themeManager)
//        }
//        .onChange(of: selectedSound) { oldValue, newValue in
//            // 当音频选择改变时，如果正在专注或休息，重新播放新音频
//            if isRunning || isCompleted {
//                startAudioPlayback()
//            }
//        }
//        .sheet(isPresented: $showFocusRecord) {
//            TDFocusRecordView(isPresented: $showFocusRecord)
//                .environmentObject(themeManager)
//                .environmentObject(tomatoManager)
//        }
//        .sheet(isPresented: $showDurationPreset) {
//            TDFocusDurationPresetView(isPresented: $showDurationPreset)
//                .environmentObject(themeManager)
//        }
//        .onAppear {
//            // 初始化时设置专注时长
//            resetTimer()
//        }
//        .onChange(of: settingManager.focusDuration) { oldValue, newValue in
//            // 监听专注时长变化，只有在未开始状态才更新
//            if !isRunning && !isCompleted {
//                resetTimer()
//            }
//        }
//        .onChange(of: settingManager.restDuration) { oldValue, newValue in
//            // 监听休息时长变化，只有在未开始状态才更新
//            if !isRunning && !isCompleted {
//                resetTimer()
//            }
//        }
//        .tdToastBottom(
//            isPresenting: $showToast,
//            message: toastMessage,
//            type: .error
//        )
//
//    }
//    
//    // MARK: - 左侧状态区域
//    private var leftStatusArea: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(statusText)
//                .font(.system(size: 14, weight: .medium))
//                .foregroundColor(currentTextColor)
//            
//            Button(action: {
//                showFocusRecord = true
//            }) {
//                HStack(spacing: 6) {
//                    Image(systemName: "list.bullet")
//                        .font(.system(size: 12))
//                        .foregroundColor(currentTextColor)
//                    
//                    Text("今日番茄收获: \(tomatoManager.getTodayTomato()?.tomatoNum ?? 0)")
//                        .font(.system(size: 12))
//                        .foregroundColor(currentTextColor)
//                }
//            }
//            .pointingHandCursor()
//            .buttonStyle(PlainButtonStyle())
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//    }
//    
//    // MARK: - 中间计时器区域
//    private var centerTimerArea: some View {
//        VStack(spacing: 4) {
//            // 大计时器按钮
//            Button(action: {
//                handleTimerTap()
//            }) {
//                Text(timeString)
//                    .font(.system(size: 26, weight: .medium))
//                    .foregroundColor(currentTextColor)
//            }
//            .buttonStyle(PlainButtonStyle())
//            .help("点击修改专注时长")
//            .pointingHandCursor()
//
//            // 声音标签 - 一直显示
//            HStack(spacing: 4) {
//                Image(selectedSound.icon)
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 12, height: 12)
//
//                Text(displaySoundName)
//                    .font(.system(size: 12))
//                    .foregroundColor(selectedSound.name == "静音" ? themeManager.descriptionTextColor : themeManager.titleTextColor)
//
//                // 删除按钮 - 只在不是静音时显示
//                if selectedSound.name != "静音" {
//                    Button(action: {
//                        selectedSound = TDSoundModel.defaultSound // 恢复为静音
//                        // 如果正在专注或休息，立即停止音频播放
//                        if isRunning || isCompleted {
//                            stopAudioPlayback()
//                        }
//                    }) {
//                        Image(systemName: "xmark.circle.fill")
//                            .font(.system(size: 12))
//                            .foregroundColor(currentTextColor)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                    .pointingHandCursor()
//                }
//            }
//            .padding(.horizontal, 12)
//            .padding(.vertical, 6)
//            .background(
//                Capsule()
//                    .fill(themeManager.color(level: 5).opacity(0.1))
//                    .background(.ultraThinMaterial)
//            )
//            .onTapGesture {
//                showSoundPicker = true // 点击声音标签显示选择弹窗
//            }
//        }
//        .frame(maxWidth: .infinity)
//    }
//
//    // MARK: - 右侧专注按钮
//    private var rightFocusButton: some View {
//        Button(action: {
//            toggleTimer()
//        }) {
//            HStack(spacing: 8) {
//                Image(systemName: buttonIcon)
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(.white)
//                
//                Text(buttonText)
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(.white)
//            }
//            .padding(.horizontal, 20)
//            .padding(.vertical, 12)
//            .background(
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(currentButtonColor)
//            )
//        }
//        .buttonStyle(PlainButtonStyle())
//        .pointingHandCursor()
//        .frame(maxWidth: .infinity, alignment: .trailing)
//    }
//    
//    // MARK: - 计算属性
//    
//    /// 时间字符串显示
//    private var timeString: String {
//        let minutes = timeRemaining / 60
//        let seconds = timeRemaining % 60
//        return String(format: "%02d:%02d", minutes, seconds)
//    }
//    
//    /// 状态文字
//    private var statusText: String {
//        let baseStatus: String
//        if isCompleted {
//            baseStatus = "休息中"
//        } else if isRunning {
//            baseStatus = "专注中"
//        } else {
//            baseStatus = "待开始"
//        }
//        
//        // 如果有关联任务，显示任务标题
//        if let task = mainViewModel.focusTask {
//            return "\(baseStatus)：\(task.taskContent)"
//        } else {
//            return baseStatus
//        }
//
//    }
//    
//    /// 当前文字颜色
//    private var currentTextColor: Color {
//        if isCompleted {
//            return themeManager.fixedColor(themeId: "wish_orange", level: 5)
//        } else {
//            return themeManager.color(level: 5)
//        }
//    }
//    
//    /// 按钮图标
//    private var buttonIcon: String {
//        if isCompleted {
//            return "stop.fill"
//        } else if isRunning {
//            return "clock.fill"
//        } else {
//            return "play.fill"
//        }
//    }
//    
//    /// 按钮文字
//    private var buttonText: String {
//        if isCompleted {
//            return "button_give_up_rest".localized
//        } else if isRunning {
//            return "button_give_up_focus".localized
//        } else {
//            return "button_start_focus".localized
//        }
//    }
//    
//    /// 按钮颜色
//    private var currentButtonColor: Color {
//        if isCompleted {
//            return themeManager.fixedColor(themeId: "wish_orange", level: 5)
//        } else {
//            return themeManager.color(level: 5)
//        }
//    }
//    
//    /// 弹窗标题
//    private var alertTitle: String {
//        if isCompleted {
//            return "alert_confirm_give_up_rest".localized
//        } else if isRunning {
//            return "alert_confirm_give_up_focus".localized
//        } else {
//            return "alert_confirm_give_up_focus".localized
//        }
//    }
//    
//    /// 背景材质
//    private var backgroundMaterial: some View {
//        Group {
//            if isCompleted {
//                // 休息中：心想事橙毛玻璃效果
//                Rectangle()
//                    .fill(themeManager.fixedColor(themeId: "wish_orange", level: 5).opacity(0.1))
//                    .background(.ultraThinMaterial)
//            } else {
//                // 待开始/专注中：主题色毛玻璃效果
//                Rectangle()
//                    .fill(themeManager.color(level: 5).opacity(0.1))
//                    .background(.ultraThinMaterial)
//            }
//        }
//    }
//    
//    // MARK: - 私有方法
//    /// 显示的声音名称
//    private var displaySoundName: String {
//        if selectedSound.name == "静音" {
//            return "白噪音"
//        } else {
//            return selectedSound.name
//        }
//    }
//    // MARK: - 计时器点击处理
//    private func handleTimerTap() {
//        // 只有在未开始状态才能修改时长
//        if !isRunning && !isCompleted {
//            showDurationPreset = true
//        } else {
//            // 显示 Toast 提示
//            showToast(message: "toast_cannot_modify_duration".localized)
//        }
//    }
//    // MARK: - Toast 提示
//    private func showToast(message: String) {
//        toastMessage = message
//        showToast = true
//    }
//
//    /// 切换计时器状态
//    private func toggleTimer() {
//        if isCompleted {
//            // 如果正在休息，显示放弃确认弹窗
//            showAbandonAlert = true
//        } else if isRunning {
//            // 如果正在专注，显示放弃确认弹窗
//            showAbandonAlert = true
//        } else {
//            // 如果未开始，直接开始计时
//            startTimer()
//        }
//    }
//    
//    /// 开始计时器
//    private func startTimer() {
//        // 保存原始时间
//        // 从设置中获取专注时长
//        let focusMinutes = settingManager.focusDuration
//        timeRemaining = focusMinutes * 60
//        
//        // 记录专注开始时间
//        focusStartTime = Date()
//        focusSuccess = false
//        restSuccess = false
//        
//        isRunning = true
//        isCompleted = false
//
//        // 开始播放音频（循环播放）
//        startAudioPlayback()
//        
//        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
//            if timeRemaining > 0 {
//                timeRemaining -= 1
//            } else {
//                // 时间到，完成专注
//                completeFocus()
//            }
//        }
//    }
//    
//    /// 停止计时器
//    private func stopTimer() {
//        isRunning = false
//        timer?.invalidate()
//        timer = nil
//        
//        // 停止音频播放
//        stopAudioPlayback()
//    }
//    
//    /// 完成专注
//    private func completeFocus() {
//        isRunning = false
//        isCompleted = true
//        timer?.invalidate()
//        timer = nil
//        
//        // 记录专注结束时间
//        focusEndTime = Date()
//        
//        // 标记专注成功
//        focusSuccess = true
//
//        // 播放完成音效（不停止背景音频）
//        TDAudioManager.shared.playCompletionSound()
//        
//        // 开始休息计时器
//        startRestTimer()
//    }
//    
//    /// 开始休息计时器
//    private func startRestTimer() {
//        // 设置休息时间为5分钟
//        // 从设置中获取休息时长
//        let restMinutes = settingManager.restDuration
//        timeRemaining = restMinutes * 60
//        
//        // 记录休息开始时间
//        restStartTime = Date()
//        restSuccess = false
//
//        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
//            if timeRemaining > 0 {
//                timeRemaining -= 1
//            } else {
//                // 休息时间到，完成整个番茄钟
//                completeRest()
//            }
//        }
//    }
//    
//    /// 完成休息
//    private func completeRest() {
//        isRunning = false
//        isCompleted = false
//        timer?.invalidate()
//        timer = nil
//        
//        // 标记休息成功
//        restSuccess = true
//        
//        // 停止音频播放
//        stopAudioPlayback()
//        
//        // 创建番茄钟记录并保存
//        createTomatoRecord()
//        
//        // 自动同步数据到服务器
//        Task {
//            await tomatoManager.syncUnsyncedRecords()
//        }
//
//        // 重置时间
//        resetTimer()
//    }
//    
//    /// 放弃专注
//    private func abandonFocus() {
//        // 记录专注结束时间（如果正在专注中）
//        if isRunning {
//            focusEndTime = Date()
//        }
//        
//        // 停止计时器
//        isRunning = false
//        isCompleted = false
//        timer?.invalidate()
//        timer = nil
//        
//        // 停止音频播放
//        stopAudioPlayback()
//        // 判断专注时长是否超过120秒（2分钟）
//        let focusDuration = Int(focusEndTime.timeIntervalSince(focusStartTime))
//        if focusDuration >= 120 {
//            // 专注时长超过2分钟，创建番茄钟记录并保存
//            createTomatoRecord()
//            
//            // 自动同步数据到服务器
//            Task {
//                await tomatoManager.syncUnsyncedRecords()
//            }
//        }
//
//        // 创建番茄钟记录并保存（记录失败状态）
////        createTomatoRecord()
//        
//        // 重置时间
//        resetTimer()
//    }
//    
//    // MARK: - 音频播放方法
//    
//    /// 开始音频播放
//    private func startAudioPlayback() {
//        // 如果选择的是静音，停止播放
//        if selectedSound.name == "静音" {
//            stopAudioPlayback()
//            return
//        }
//        
//        // 直接使用声音名称作为文件名（添加.mp3扩展名）
//        let audioFileName = "\(selectedSound.name).mp3"
//        
//        // 循环播放音频
//        TDAudioManager.shared.playAudio(fileName: audioFileName, loop: true)
//    }
//    
//    /// 停止音频播放
//    private func stopAudioPlayback() {
//        TDAudioManager.shared.stopAudio()
//    }
//    
//
//    /// 重置计时器
//    private func resetTimer() {
//        // 重置时间显示
//        let focusMinutes = settingManager.focusDuration
//        timeRemaining = focusMinutes * 60
//        
//        // 重置状态
//        focusSuccess = false
//        restSuccess = false
//        
//        // 重置实际时间
//        actualFocusTime = 0
//        actualRestTime = 0
//        
//        // 重置时间记录
//        focusStartTime = Date()
//        restStartTime = Date()
//    }
//
//    // MARK: - 记录相关方法
//    
//    /// 创建番茄钟记录
//    private func createTomatoRecord() {
//        // 使用专注结束时间计算专注时长
//        let focusDuration = Int(focusEndTime.timeIntervalSince(focusStartTime))
//        let restDuration = actualRestTime
//        
//        // 获取用户ID（这里需要根据实际情况获取）
//        let userId = TDUserManager.shared.userId
//        
//        // 创建记录
//        let now = Date.currentTimestamp
//        let tomatoId = TDAppConfig.generateTaskId()
//        
//        let record = TDTomatoRecordModel(
//            userId: userId,
//            tomatoId: tomatoId,
//            taskContent: mainViewModel.focusTask?.taskContent ?? "null",  // 空值时传 "null"
//            taskId: mainViewModel.focusTask?.taskId ?? "null",          // 空值时传 "null"
//            startTime: focusStartTime.fullTimestamp,
//            endTime: focusEndTime.fullTimestamp,
//            focus: focusSuccess,
//            focusDuration: focusDuration,
//            rest: restSuccess,
//            restDuration: restDuration,
//            snowAdd: 0,
//            syncTime: now,
//            status: "add"
//        )
//        
//        // 保存到本地数据库
//        TDTomatoManager.shared.insertTomatoRecord(record)
//        
//        // 这里可以调用API保存到服务器
//        print("🍅 创建番茄钟记录:")
//        print("  - 专注成功: \(focusSuccess)")
//        print("  - 专注时长: \(focusDuration)秒")
//        print("  - 休息成功: \(restSuccess)")
//        print("  - 休息时长: \(restDuration)秒")
//        print("  - 番茄钟ID: \(record.tomatoId)")
//    }
//    
//
//}
//
//#Preview {
//    TDFocusView()
//        .environmentObject(TDThemeManager.shared)
//}


//
//  TDFocusView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI

/// 专注界面
struct TDFocusView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var tomatoManager: TDTomatoManager
    @EnvironmentObject private var mainViewModel: TDMainViewModel
    @EnvironmentObject private var settingManager: TDSettingManager

    @State private var timeRemaining: Int = 0 // 剩余时间，以秒为单位
    @State private var isRunning: Bool = false
    @State private var isCompleted: Bool = false // 专注完成状态
    @State private var timer: Timer?
    @State private var selectedSound: TDSoundModel = TDSoundModel.defaultSound // 默认选择白噪音
    @State private var showAbandonAlert: Bool = false // 显示放弃确认弹窗
    @State private var showSoundPicker: Bool = false // 显示声音选择弹窗
    @State private var showFocusRecord: Bool = false // 显示专注记录弹窗
    @State private var showDurationPreset: Bool = false // 显示时长预设弹窗

    // 记录相关状态
    @State private var focusStartTime: Date = Date() // 专注开始时间
    @State private var focusEndTime: Date = Date() // 专注结束时间
    @State private var restStartTime: Date = Date() // 休息开始时间
    @State private var focusSuccess: Bool = false // 专注是否成功
    @State private var restSuccess: Bool = false // 休息是否成功

    // 实际专注和休息时间
    @State private var actualFocusTime: Int = 0 // 实际专注时间（秒）
    @State private var actualRestTime: Int = 0 // 实际休息时间（秒）


    var body: some View {
        VStack(spacing: 0) {
            // 顶部分割线
            Rectangle()
                .fill(themeManager.separatorColor)
                .frame(height: 1)
            
            // 主要内容
            HStack(spacing: 20) {
                // 左侧状态区域
                leftStatusArea
                
                // 中间计时器区域
                centerTimerArea
                
                // 右侧专注按钮
                rightFocusButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(height: 80)
            .background(backgroundMaterial)
        }
        .alert(alertTitle, isPresented: $showAbandonAlert) {
            Button("取消", role: .cancel) {
                // 取消操作，不做任何处理
            }
            Button("确定", role: .destructive) {
                abandonFocus()
            }
        }
        .sheet(isPresented: $showSoundPicker) {
            TDSoundPickerView(
                selectedSound: $selectedSound,
                isPresented: $showSoundPicker
            )
            .environmentObject(themeManager)
        }
        .onChange(of: selectedSound) { oldValue, newValue in
            // 当音频选择改变时，如果正在专注或休息，重新播放新音频
            if isRunning || isCompleted {
                startAudioPlayback()
            }
        }
        .sheet(isPresented: $showFocusRecord) {
            TDFocusRecordView(isPresented: $showFocusRecord)
                .environmentObject(themeManager)
                .environmentObject(tomatoManager)
        }
        .sheet(isPresented: $showDurationPreset) {
            TDFocusDurationPresetView(isPresented: $showDurationPreset)
                .environmentObject(themeManager)
        }
        .onAppear {
            // 初始化时设置专注时长
            resetTimer()
        }
        .onChange(of: settingManager.focusDuration) { oldValue, newValue in
            // 监听专注时长变化，只有在未开始状态才更新
            if !isRunning && !isCompleted {
                resetTimer()
            }
        }
        .onChange(of: settingManager.restDuration) { oldValue, newValue in
            // 监听休息时长变化，只有在未开始状态才更新
            if !isRunning && !isCompleted {
                resetTimer()
            }
        }

    }
    
    // MARK: - 左侧状态区域
    private var leftStatusArea: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(statusText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(currentTextColor)
            
            Button(action: {
                showFocusRecord = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12))
                        .foregroundColor(currentTextColor)
                    
                    Text("今日番茄收获: \(tomatoManager.getTodayTomato()?.tomatoNum ?? 0)")
                        .font(.system(size: 12))
                        .foregroundColor(currentTextColor)
                }
            }
            .pointingHandCursor()
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 中间计时器区域
    private var centerTimerArea: some View {
        VStack(spacing: 4) {
            // 大计时器按钮
            Button(action: {
                handleTimerTap()
            }) {
                Text(timeString)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(currentTextColor)
            }
            .buttonStyle(PlainButtonStyle())
            .help("点击修改专注时长")
            .pointingHandCursor()

            // 声音标签 - 一直显示
            HStack(spacing: 4) {
                Image(selectedSound.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)

                Text(displaySoundName)
                    .font(.system(size: 12))
                    .foregroundColor(selectedSound.name == "静音" ? themeManager.descriptionTextColor : themeManager.titleTextColor)

                // 删除按钮 - 只在不是静音时显示
                if selectedSound.name != "静音" {
                    Button(action: {
                        selectedSound = TDSoundModel.defaultSound // 恢复为静音
                        // 如果正在专注或休息，立即停止音频播放
                        if isRunning || isCompleted {
                            stopAudioPlayback()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(currentTextColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(themeManager.color(level: 5).opacity(0.1))
                    .background(.ultraThinMaterial)
            )
            .onTapGesture {
                showSoundPicker = true // 点击声音标签显示选择弹窗
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 右侧专注按钮
    private var rightFocusButton: some View {
        Button(action: {
            toggleTimer()
        }) {
            HStack(spacing: 8) {
                Image(systemName: buttonIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(buttonText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(currentButtonColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    // MARK: - 计算属性
    
    /// 时间字符串显示
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 状态文字
    private var statusText: String {
        let baseStatus: String
        if isCompleted {
            baseStatus = "休息中"
        } else if isRunning {
            baseStatus = "专注中"
        } else {
            baseStatus = "待开始"
        }
        
        // 如果有关联任务，显示任务标题
        if let task = mainViewModel.focusTask {
            return "\(baseStatus)：\(task.taskContent)"
        } else {
            return baseStatus
        }

    }
    
    /// 当前文字颜色
    private var currentTextColor: Color {
        if isCompleted {
            return themeManager.fixedColor(themeId: "wish_orange", level: 5)
        } else {
            return themeManager.color(level: 5)
        }
    }
    
    /// 按钮图标
    private var buttonIcon: String {
        if isCompleted {
            return "stop.fill"
        } else if isRunning {
            return "clock.fill"
        } else {
            return "play.fill"
        }
    }
    
    /// 按钮文字
    private var buttonText: String {
        if isCompleted {
            return "button_give_up_rest".localized
        } else if isRunning {
            return "button_give_up_focus".localized
        } else {
            return "button_start_focus".localized
        }
    }
    
    /// 按钮颜色
    private var currentButtonColor: Color {
        if isCompleted {
            return themeManager.fixedColor(themeId: "wish_orange", level: 5)
        } else {
            return themeManager.color(level: 5)
        }
    }
    
    /// 弹窗标题
    private var alertTitle: String {
        if isCompleted {
            return "alert_confirm_give_up_rest".localized
        } else if isRunning {
            return "alert_confirm_give_up_focus".localized
        } else {
            return "alert_confirm_give_up_focus".localized
        }
    }
    
    /// 背景材质
    private var backgroundMaterial: some View {
        Group {
            if isCompleted {
                // 休息中：心想事橙毛玻璃效果
                Rectangle()
                    .fill(themeManager.fixedColor(themeId: "wish_orange", level: 5).opacity(0.1))
                    .background(.ultraThinMaterial)
            } else {
                // 待开始/专注中：主题色毛玻璃效果
                Rectangle()
                    .fill(themeManager.color(level: 5).opacity(0.1))
                    .background(.ultraThinMaterial)
            }
        }
    }
    
    // MARK: - 私有方法
    /// 显示的声音名称
    private var displaySoundName: String {
        if selectedSound.name == "静音" {
            return "白噪音"
        } else {
            return selectedSound.name
        }
    }
    // MARK: - 计时器点击处理
    private func handleTimerTap() {
        // 只有在未开始状态才能修改时长
        if !isRunning && !isCompleted {
            showDurationPreset = true
        } else {
            // 显示 Toast 提示
            showToast(message: "toast_cannot_modify_duration".localized)
        }
    }
    // MARK: - Toast 提示
    private func showToast(message: String) {
        TDToastCenter.shared.show(message, type: .info, position: .bottom)
    }

    /// 切换计时器状态
    private func toggleTimer() {
        if isCompleted {
            // 如果正在休息，显示放弃确认弹窗
            showAbandonAlert = true
        } else if isRunning {
            // 如果正在专注，显示放弃确认弹窗
            showAbandonAlert = true
        } else {
            // 如果未开始，直接开始计时
            startTimer()
        }
    }
    
    /// 开始计时器
    private func startTimer() {
        // 保存原始时间
        // 从设置中获取专注时长
        let focusMinutes = settingManager.focusDuration
        timeRemaining = focusMinutes * 60
        
        // 记录专注开始时间
        focusStartTime = Date()
        focusSuccess = false
        restSuccess = false
        
        isRunning = true
        isCompleted = false

        // 开始播放音频（循环播放）
        startAudioPlayback()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // 时间到，完成专注
                completeFocus()
            }
        }
    }
    
    /// 停止计时器
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // 停止音频播放
        stopAudioPlayback()
    }
    
    /// 完成专注
    private func completeFocus() {
        isRunning = false
        isCompleted = true
        timer?.invalidate()
        timer = nil
        
        // 记录专注结束时间
        focusEndTime = Date()
        
        // 标记专注成功
        focusSuccess = true

        // 播放完成音效（不停止背景音频）
        TDAudioManager.shared.playCompletionSound()
        
        // 开始休息计时器
        startRestTimer()
    }
    
    /// 开始休息计时器
    private func startRestTimer() {
        // 设置休息时间为5分钟
        // 从设置中获取休息时长
        let restMinutes = settingManager.restDuration
        timeRemaining = restMinutes * 60
        
        // 记录休息开始时间
        restStartTime = Date()
        restSuccess = false

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // 休息时间到，完成整个番茄钟
                completeRest()
            }
        }
    }
    
    /// 完成休息
    private func completeRest() {
        isRunning = false
        isCompleted = false
        timer?.invalidate()
        timer = nil
        
        // 标记休息成功
        restSuccess = true
        
        // 停止音频播放
        stopAudioPlayback()
        
        // 创建番茄钟记录并保存
        createTomatoRecord()
        
        // 自动同步数据到服务器
        Task {
            await tomatoManager.syncUnsyncedRecords()
        }

        // 重置时间
        resetTimer()
    }
    
    /// 放弃专注
    private func abandonFocus() {
        // 记录专注结束时间（如果正在专注中）
        if isRunning {
            focusEndTime = Date()
        }
        
        // 停止计时器
        isRunning = false
        isCompleted = false
        timer?.invalidate()
        timer = nil
        
        // 停止音频播放
        stopAudioPlayback()
        // 判断专注时长是否超过120秒（2分钟）
        let focusDuration = Int(focusEndTime.timeIntervalSince(focusStartTime))
        if focusDuration >= 120 {
            // 专注时长超过2分钟，创建番茄钟记录并保存
            createTomatoRecord()
            
            // 自动同步数据到服务器
            Task {
                await tomatoManager.syncUnsyncedRecords()
            }
        }

        // 创建番茄钟记录并保存（记录失败状态）
//        createTomatoRecord()
        
        // 重置时间
        resetTimer()
    }
    
    // MARK: - 音频播放方法
    
    /// 开始音频播放
    private func startAudioPlayback() {
        // 如果选择的是静音，停止播放
        if selectedSound.name == "静音" {
            stopAudioPlayback()
            return
        }
        
        // 直接使用声音名称作为文件名（添加.mp3扩展名）
        let audioFileName = "\(selectedSound.name).mp3"
        
        // 循环播放音频
        TDAudioManager.shared.playAudio(fileName: audioFileName, loop: true)
    }
    
    /// 停止音频播放
    private func stopAudioPlayback() {
        TDAudioManager.shared.stopAudio()
    }
    

    /// 重置计时器
    private func resetTimer() {
        // 重置时间显示
        let focusMinutes = settingManager.focusDuration
        timeRemaining = focusMinutes * 60
        
        // 重置状态
        focusSuccess = false
        restSuccess = false
        
        // 重置实际时间
        actualFocusTime = 0
        actualRestTime = 0
        
        // 重置时间记录
        focusStartTime = Date()
        restStartTime = Date()
    }

    // MARK: - 记录相关方法
    
    /// 创建番茄钟记录
    private func createTomatoRecord() {
        // 使用专注结束时间计算专注时长
        let focusDuration = Int(focusEndTime.timeIntervalSince(focusStartTime))
        let restDuration = actualRestTime
        
        // 获取用户ID（这里需要根据实际情况获取）
        let userId = TDUserManager.shared.userId
        
        // 创建记录
        let now = Date.currentTimestamp
        let tomatoId = TDAppConfig.generateTaskId()
        
        let record = TDTomatoRecordModel(
            userId: userId,
            tomatoId: tomatoId,
            taskContent: mainViewModel.focusTask?.taskContent ?? "null",  // 空值时传 "null"
            taskId: mainViewModel.focusTask?.taskId ?? "null",          // 空值时传 "null"
            startTime: focusStartTime.fullTimestamp,
            endTime: focusEndTime.fullTimestamp,
            focus: focusSuccess,
            focusDuration: focusDuration,
            rest: restSuccess,
            restDuration: restDuration,
            snowAdd: 0,
            syncTime: now,
            status: "add"
        )
        
        // 保存到本地数据库
        TDTomatoManager.shared.insertTomatoRecord(record)
        
        // 这里可以调用API保存到服务器
        print("🍅 创建番茄钟记录:")
        print("  - 专注成功: \(focusSuccess)")
        print("  - 专注时长: \(focusDuration)秒")
        print("  - 休息成功: \(restSuccess)")
        print("  - 休息时长: \(restDuration)秒")
        print("  - 番茄钟ID: \(record.tomatoId)")
    }
    

}

#Preview {
    TDFocusView()
        .environmentObject(TDThemeManager.shared)
}
