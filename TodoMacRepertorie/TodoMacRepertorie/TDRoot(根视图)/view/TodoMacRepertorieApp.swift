//
//  TodoMacRepertorieApp.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/27.
//

import SwiftUI
import SwiftData
import AppKit

@main
struct TodoMacRepertorieApp: App {
    @StateObject private var modelContainer = TDModelContainer.shared
    @StateObject private var userManager = TDUserManager.shared
    @StateObject private var themeManager = TDThemeManager.shared
    @StateObject private var settingManager = TDSettingManager.shared
    @StateObject private var mainViewModel = TDMainViewModel.shared
    @StateObject private var appIconManager = TDAppIconManager.shared

    @StateObject private var scheduleModel = TDScheduleOverviewViewModel.shared
    @StateObject private var tomatoManager = TDTomatoManager.shared

    @StateObject private var toastCenter = TDToastCenter.shared
    @StateObject private var settingsSidebarStore = TDSettingsSidebarStore.shared

    // 跟随系统时记录当前系统深色状态（固定模式不会受系统影响）
    @State private var isSystemDark: Bool = false
    
    /// 期望的颜色模式：跟随设置（系统/白天/夜间）
    private var preferredScheme: ColorScheme? {
        switch settingManager.themeMode {
        case .system:
            // 跟随系统：根据当前记录的系统深浅色返回
            return isSystemDark ? .dark : .light
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    /// 同步 App 外观到系统（跟随/强制明/暗）
    private func applyAppearance() {
        switch settingManager.themeMode {
        case .system:
            // 跟随系统：清空自定义外观，让 App 完全由系统控制
            NSApp.appearance = nil
            // 立即读取当前系统深浅色，确保切换时即时一致
            isSystemDark = systemIsDark()
            // 通知依赖主题的视图刷新
            themeManager.objectWillChange.send()
            settingManager.objectWillChange.send()

        case .light:
            // 强制白天：固定浅色，不受系统影响
            NSApp.appearance = NSAppearance(named: .aqua)
            isSystemDark = false
        case .dark:
            // 强制夜间：固定深色，不受系统影响
            NSApp.appearance = NSAppearance(named: .darkAqua)
            isSystemDark = true
        }
    }

    
    /// 获取当前系统深浅色（直接读取系统偏好，避免被 App 级 appearance 干扰）
    private func systemIsDark() -> Bool {
        if let style = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")?.lowercased() {
            return style.contains("dark")
        }
        return false
    }

    
    var body: some Scene {
        WindowGroup {
            Group {
                if userManager.isLoggedIn {
                    TDMainView()
                        .environmentObject(themeManager)
                        .environmentObject(settingManager)
                        .environmentObject(mainViewModel)
                        .environmentObject(scheduleModel)
                        .environmentObject(tomatoManager)
                        .environmentObject(toastCenter)
                        .background(
                            TDWindowAccessor { window in
                                TDSettingsWindowTracker.shared.registerMainWindow(window)
                            }
                        )

                } else {
                    TDLoginView()
                        .frame(width: 932, height: 621)
                        .fixedSize()
                }
            }
            .preferredColorScheme(preferredScheme)
//            .environment(\.locale, currentLocale)

            .tdToastBottom(
                isPresenting: Binding(
                    get: { toastCenter.isPresenting && toastCenter.position == .bottom },
                    set: { toastCenter.isPresenting = $0 }
                ),
                message: toastCenter.message,
                type: toastCenter.type
            )
            .tdToastTop(
                isPresenting: Binding(
                    get: { toastCenter.isPresenting && toastCenter.position == .top },
                    set: { toastCenter.isPresenting = $0 }
                ),
                message: toastCenter.message,
                type: toastCenter.type
            )
            .tdToastCenter(
                isPresenting: Binding(
                    get: { toastCenter.isPresenting && toastCenter.position == .center },
                    set: { toastCenter.isPresenting = $0 }
                ),
                message: toastCenter.message,
                type: toastCenter.type
            )
            // 启动时同步一次外观与系统深浅色
            .onAppear {
                isSystemDark = systemIsDark()
                applyAppearance()
                // 启动时同步应用图标与 Dock 设置，保证默认就是上次选中的图标
                appIconManager.syncFromSettings()

            }
            // 当 App 内部主题模式变更时，立即应用对应外观
            // 当 App 内部主题模式变更时，立即应用对应外观
            .onChange(of: settingManager.themeMode) { _, newValue in
                if newValue == .system {
                    // 切回跟随系统时先同步当前系统深浅色
                    isSystemDark = systemIsDark()

                } else {
                    // 固定模式直接覆盖
                    isSystemDark = (newValue == .dark)
                }
                applyAppearance()
            }
            // 跟随系统：监听系统外观变化，系统切换浅/深色时仅更新状态（避免循环）
            .onReceive(NSApp.publisher(for: \.effectiveAppearance)) { _ in
                // 仅在“跟随系统”模式下响应，避免固定模式循环触发
                
                guard settingManager.themeMode == .system else { return }
                let nowDark = systemIsDark()
                if nowDark != isSystemDark {
                    isSystemDark = nowDark
                    applyAppearance()

                }
            }

        }
        .modelContainer(modelContainer.container)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        
        WindowGroup(id: "Settings") {
            TDSettingsView()
                .environmentObject(themeManager)
                .environmentObject(settingManager)
                .environmentObject(mainViewModel)
                .environmentObject(scheduleModel)
                .environmentObject(tomatoManager)
                .environmentObject(userManager)
                .environmentObject(settingsSidebarStore)
                .background(
                    TDWindowAccessor { window in
                        TDSettingsWindowTracker.shared.attachSettingsWindow(window)
                    }
                )
                .onDisappear {
                    TDSettingsWindowTracker.shared.clearSettingsWindow()
                }
                .tdSettingToastBottom(
                    isPresenting: Binding(
                        get: { toastCenter.isSettingPresenting && toastCenter.position == .bottom },
                        set: { toastCenter.isSettingPresenting = $0 }
                    ),
                    message: toastCenter.message,
                    type: toastCenter.type
                )
                .preferredColorScheme(preferredScheme)
//                .environment(\.locale, currentLocale)
            // 启动时同步一次外观与系统深浅色
            .onAppear {
                isSystemDark = systemIsDark()
                applyAppearance()
            }
            // 当 App 内部主题模式变更时，立即应用对应外观
            .onChange(of: settingManager.themeMode) { _, newValue in
                if newValue == .system {
                    // 切回跟随系统时先同步当前系统深浅色
                    isSystemDark = systemIsDark()

                } else {
                    // 固定模式直接覆盖
                    isSystemDark = (newValue == .dark)
                }
                applyAppearance()
            }
            // 跟随系统：监听系统外观变化，系统切换浅/深色时仅更新状态（避免循环）
            .onReceive(NSApp.publisher(for: \.effectiveAppearance)) { _ in
                // 仅在“跟随系统”模式下响应，避免固定模式循环触发
                guard settingManager.themeMode == .system else { return }
                let nowDark = systemIsDark()
                if nowDark != isSystemDark {
                    isSystemDark = nowDark
                    applyAppearance()
                }
            }

        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 700, height: 660)
        .defaultPosition(.center)
        .handlesExternalEvents(matching: Set(arrayLiteral: "Settings"))

//        TDToastCenter.shared.show("专注时长已存在，不能重复添加", type: .error, position: .top)   // 顶部
//        TDToastCenter.shared.show("保存成功")                                                   // 默认底部
//        TDToastCenter.shared.show("处理中…", type: .info, position: .center)                   // 中间
    }
}


// MARK: - 设置窗口追踪
final class TDSettingsWindowTracker {
    static let shared = TDSettingsWindowTracker()
    
    private var appTerminateObserver: Any?
    private var mainWindowCloseObserver: Any?
    private var settingsWindowCloseObserver: Any?

    weak var mainWindow: NSWindow?
    weak var settingsWindow: NSWindow?
    
    private init() {
        appTerminateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.closeSettingsWindow()
        }
    }

    
    func registerMainWindow(_ window: NSWindow?) {
        guard let window else { return }
        guard window !== mainWindow else { return }
        mainWindow = window
        
        if let observer = mainWindowCloseObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        mainWindowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.closeSettingsWindow()
        }
    }
    
    func attachSettingsWindow(_ window: NSWindow?) {
        guard let window else { return }
        settingsWindow = window
        window.isReleasedWhenClosed = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.styleMask.insert(.fullSizeContentView)
        window.level = .floating
        window.hidesOnDeactivate = true
        window.isMovableByWindowBackground = true
        window.title = ""
        
        if let observer = settingsWindowCloseObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        settingsWindowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.clearSettingsWindow()
        }

    }
    
    func clearSettingsWindow() {
        settingsWindow = nil
        if let observer = settingsWindowCloseObserver {
            NotificationCenter.default.removeObserver(observer)
            settingsWindowCloseObserver = nil
        }

    }
    
    func presentSettingsWindow(using openWindow: OpenWindowAction) {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            openWindow(id: "Settings")
        }
    }
    
    func closeSettingsWindow() {
        settingsWindow?.close()
        settingsWindow = nil
    }
}

// MARK: - Window Accessor
struct TDWindowAccessor: NSViewRepresentable {
    var onResolve: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> TDWindowAccessorView {
        let view = TDWindowAccessorView()
        view.onResolve = onResolve
        return view
    }
    
    func updateNSView(_ nsView: TDWindowAccessorView, context: Context) {}
    
    final class TDWindowAccessorView: NSView {
        var onResolve: ((NSWindow?) -> Void)?
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            DispatchQueue.main.async { [weak self] in
                self?.onResolve?(self?.window)
            }
        }
    }
}
