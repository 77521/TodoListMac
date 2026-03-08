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

    @StateObject private var focusSession = TDFocusSessionStore.shared
    /// 用于驱动 UI 秒级刷新（倒计时显示 + 跨进程状态同步）
    @State private var tickNow: Date = .now
    @State private var selectedSound: TDSoundModel = TDSoundModel.defaultSound // 默认选择白噪音
    @State private var showAbandonAlert: Bool = false // 显示放弃确认弹窗
    @State private var showSoundPicker: Bool = false // 显示声音选择弹窗
    @State private var showFocusRecord: Bool = false // 显示专注记录弹窗
    @State private var showDurationPreset: Bool = false // 显示时长预设弹窗

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
            if focusSession.state.phase != .idle {
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
            // App 在线时：优先由 App 负责结束同步
            focusSession.takeOwnershipIfPossible()
            tickNow = .now
        }
        .onChange(of: settingManager.focusDuration) { oldValue, newValue in
            // 监听专注时长变化，只有在未开始状态才更新显示
            if focusSession.state.phase == .idle { tickNow = .now }
        }
        .onChange(of: settingManager.restDuration) { oldValue, newValue in
            // 监听休息时长变化，只有在未开始状态才更新显示
            if focusSession.state.phase == .idle { tickNow = .now }
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { now in
            tickNow = now
            Task { @MainActor in
                // 跨进程同步：从 AppGroup 拉取最新会话状态（放在 tick 里，避免在 View 更新期间发布变更）
                focusSession.refreshFromDefaults()
                focusSession.takeOwnershipIfPossible()
                focusSession.updateAppHeartbeat()
                _ = await focusSession.advanceIfNeeded(now: now)
            }
        }
        .onChange(of: focusSession.state.phase) { oldValue, newValue in
            // 阶段变化：对齐旧逻辑的音频/提示音（UI 侧做，避免 Widget 进程触发音频）
            if oldValue == .focusing, newValue == .resting, settingManager.focusPlayFinishSound {
                TDAudioManager.shared.playCompletionSound()
            }

            if newValue == .idle {
                stopAudioPlayback()
            } else {
                startAudioPlayback()
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
                        if focusSession.state.phase != .idle {
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
        let remaining: Int = {
            if focusSession.state.phase == .idle {
                return max(0, settingManager.focusDuration * 60)
            }
            return focusSession.remainingSeconds(now: tickNow)
        }()
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 状态文字
    private var statusText: String {
        let baseStatus: String
        if focusSession.state.phase == .resting {
            baseStatus = "休息中"
        } else if focusSession.state.phase == .focusing {
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
        if focusSession.state.phase == .resting {
            return themeManager.fixedColor(themeId: "wish_orange", level: 5)
        } else {
            return themeManager.color(level: 5)
        }
    }
    
    /// 按钮图标
    private var buttonIcon: String {
        if focusSession.state.phase == .resting {
            return "stop.fill"
        } else if focusSession.state.phase == .focusing {
            return "clock.fill"
        } else {
            return "play.fill"
        }
    }
    
    /// 按钮文字
    private var buttonText: String {
        if focusSession.state.phase == .resting {
            return "button_give_up_rest".localized
        } else if focusSession.state.phase == .focusing {
            return "button_give_up_focus".localized
        } else {
            return "button_start_focus".localized
        }
    }
    
    /// 按钮颜色
       private var currentButtonColor: Color {
           switch focusSession.state.phase {
           case .idle:
               return themeManager.color(level: 5)
           case .focusing:
               return themeManager.fixedColor(themeId: "new_year_red", level: 5)
           case .resting:
               return themeManager.fixedColor(themeId: "wish_orange", level: 5)
           }
       }
       
       /// 弹窗标题
       private var alertTitle: String {
           if focusSession.state.phase == .resting {
               return "alert_confirm_give_up_rest".localized
           } else if focusSession.state.phase == .focusing {
               return "alert_confirm_give_up_focus".localized
           } else {
               return "alert_confirm_give_up_focus".localized
           }
       }
       
       /// 背景材质
       private var backgroundMaterial: some View {
           Group {
               switch focusSession.state.phase {
               case .idle:
                   // 待开始：主题色毛玻璃效果
                   Rectangle()
                       .fill(themeManager.color(level: 5).opacity(0.10))
                       .background(.ultraThinMaterial)
               case .focusing:
                   // 专注中：新年红毛玻璃效果
                   Rectangle()
                       .fill(themeManager.fixedColor(themeId: "new_year_red", level: 5).opacity(0.16))
                       .background(.ultraThinMaterial)
               case .resting:
                   // 休息中：心想事橙毛玻璃效果
                   Rectangle()
                       .fill(themeManager.fixedColor(themeId: "wish_orange", level: 5).opacity(0.16))
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
        if focusSession.state.phase == .idle {
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
        switch focusSession.state.phase {
        case .idle:
            startTimer()
        case .focusing, .resting:
            showAbandonAlert = true
        }
    }
    
    /// 开始计时器
    private func startTimer() {
        focusSession.start(
            focusMinutes: settingManager.focusDuration,
            restMinutes: settingManager.restDuration,
            taskId: mainViewModel.focusTask?.taskId,
            taskContent: mainViewModel.focusTask?.taskContent,
            owner: .app
        )
    }
    
    /// 放弃专注
    private func abandonFocus() {
        Task { @MainActor in
            await focusSession.abandon()
        }
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
    

}

#Preview {
    TDFocusView()
        .environmentObject(TDThemeManager.shared)
}
