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

    @StateObject private var scheduleModel = TDScheduleOverviewViewModel.shared
    @StateObject private var tomatoManager = TDTomatoManager.shared

    @StateObject private var toastCenter = TDToastCenter.shared
    @StateObject private var settingsSidebarStore = TDSettingsSidebarStore.shared

    
    /// 当前语言对应的 Locale，系统以外仅中/英，系统且非中英时回落中文
    private var currentLocale: Locale {
        switch settingManager.language {
        case .system:
            let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
            if preferred.contains("en") {
                return Locale(identifier: "en")
            } else if preferred.contains("zh") {
                return Locale(identifier: "zh-Hans")
            } else {
                return Locale(identifier: "zh-Hans")
            }
        case .chinese:
            return Locale(identifier: "zh-Hans")
        case .english:
            return Locale(identifier: "en")
        }
    }
    
    /// 期望的颜色模式：跟随设置（系统/白天/夜间）
    private var preferredScheme: ColorScheme? {
        switch settingManager.themeMode {
        case .system:
            if NSApp.effectiveAppearance.isDarkMode {
                return .dark
            } else {
                return .light
            }
        case .light:
            return .light
        case .dark:
            return .dark
        }
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
            .environment(\.locale, currentLocale)

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
                .environment(\.locale, currentLocale)
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
