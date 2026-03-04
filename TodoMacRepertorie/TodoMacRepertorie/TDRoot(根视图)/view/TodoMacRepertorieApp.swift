////
////  TodoMacRepertorieApp.swift
////  TodoMacRepertorie
////
////  Created by 孬孬 on 2024/12/27.
////
//
//import SwiftUI
//import SwiftData
//import AppKit
//
//// 禁用系统窗口恢复：即使上次退出前打开了设置窗口，冷启动也不会自动恢复
//final class TDAppDelegate: NSObject, NSApplicationDelegate {
//    func applicationShouldRestoreApplicationState(_ app: NSApplication) -> Bool { false }
//    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
//    
//    func applicationDidFinishLaunching(_ notification: Notification) {
//        // 启动时关闭所有窗口的系统恢复能力
//        NSApp.windows.forEach { $0.isRestorable = false }
//    }
//}
//
//@main
//struct TodoMacRepertorieApp: App {
//    @StateObject private var modelContainer = TDModelContainer.shared
//    @StateObject private var userManager = TDUserManager.shared
//    @StateObject private var themeManager = TDThemeManager.shared
//    @StateObject private var settingManager = TDSettingManager.shared
//    @StateObject private var mainViewModel = TDMainViewModel.shared
//    @StateObject private var appIconManager = TDAppIconManager.shared
//
//    @StateObject private var scheduleModel = TDScheduleOverviewViewModel.shared
//    @StateObject private var tomatoManager = TDTomatoManager.shared
//
//    @StateObject private var toastCenter = TDToastCenter.shared
//    @StateObject private var settingsSidebarStore = TDSettingsSidebarStore.shared
//
//    // 跟随系统时记录当前系统深色状态（固定模式不会受系统影响）
//    @State private var isSystemDark: Bool = false
//    
//    /// 期望的颜色模式：跟随设置（系统/白天/夜间）
//    private var preferredScheme: ColorScheme? {
//        switch settingManager.themeMode {
//        case .system:
//            // 跟随系统：根据当前记录的系统深浅色返回
//            return isSystemDark ? .dark : .light
//        case .light:
//            return .light
//        case .dark:
//            return .dark
//        }
//    }
//    /// 同步 App 外观到系统（跟随/强制明/暗）
//    private func applyAppearance() {
//        switch settingManager.themeMode {
//        case .system:
//            // 跟随系统：清空自定义外观，让 App 完全由系统控制
//            NSApp.appearance = nil
//            // 立即读取当前系统深浅色，确保切换时即时一致
//            isSystemDark = systemIsDark()
//            // 通知依赖主题的视图刷新
//            themeManager.objectWillChange.send()
//            settingManager.objectWillChange.send()
//
//        case .light:
//            // 强制白天：固定浅色，不受系统影响
//            NSApp.appearance = NSAppearance(named: .aqua)
//            isSystemDark = false
//        case .dark:
//            // 强制夜间：固定深色，不受系统影响
//            NSApp.appearance = NSAppearance(named: .darkAqua)
//            isSystemDark = true
//        }
//    }
//
//    
//    /// 获取当前系统深浅色（直接读取系统偏好，避免被 App 级 appearance 干扰）
//    private func systemIsDark() -> Bool {
//        if let style = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")?.lowercased() {
//            return style.contains("dark")
//        }
//        return false
//    }
//
//    
//    var body: some Scene {
//        WindowGroup {
//            Group {
//                if userManager.isLoggedIn {
//                    TDMainView()
//                        // 关键：避免点击小组件（openURL）时不断新建主窗口
//                        // 让 `todomac://...` 外部事件优先复用现有窗口（若已存在）
//                        .handlesExternalEvents(preferring: Set(arrayLiteral: "todomac"), allowing: Set(arrayLiteral: "todomac"))
//                        .environmentObject(themeManager)
//                        .environmentObject(settingManager)
//                        .environmentObject(mainViewModel)
//                        .environmentObject(scheduleModel)
//                        .environmentObject(tomatoManager)
//                        .environmentObject(toastCenter)
//                        .background(
//                            TDWindowAccessor { window in
//                                TDSettingsWindowTracker.shared.registerMainWindow(window)
//                            }
//                        )
//
//                } else {
//                    TDLoginView()
//                        .frame(width: 932, height: 621)
//                        .fixedSize()
//                }
//            }
//            .preferredColorScheme(preferredScheme)
//            .onOpenURL { url in
//                handleWidgetDeepLink(url)
//            }
////            .environment(\.locale, currentLocale)
//
////            .tdToastBottom(
////                isPresenting: Binding(
////                    get: { toastCenter.isPresenting && toastCenter.position == .bottom },
////                    set: { toastCenter.isPresenting = $0 }
////                ),
////                message: toastCenter.message,
////                type: toastCenter.type
////            )
////            .tdToastTop(
////                isPresenting: Binding(
////                    get: { toastCenter.isPresenting && toastCenter.position == .top },
////                    set: { toastCenter.isPresenting = $0 }
////                ),
////                message: toastCenter.message,
////                type: toastCenter.type
////            )
////            .tdToastCenter(
////                isPresenting: Binding(
////                    get: { toastCenter.isPresenting && toastCenter.position == .center },
////                    set: { toastCenter.isPresenting = $0 }
////                ),
////                message: toastCenter.message,
////                type: toastCenter.type
////            )
//            // 启动时同步一次外观与系统深浅色
//            .onAppear {
//                isSystemDark = systemIsDark()
//                applyAppearance()
//                // Toast 通过顶层透明 Panel 显示，避免被 sheet 遮罩盖住
//                TDToastOverlayWindowManager.shared.start()
//
//                // 启动时同步应用图标与 Dock 设置，保证默认就是上次选中的图标
//                appIconManager.syncFromSettings()
//
//            }
//            // 当 App 内部主题模式变更时，立即应用对应外观
//            // 当 App 内部主题模式变更时，立即应用对应外观
//            .onChange(of: settingManager.themeMode) { _, newValue in
//                if newValue == .system {
//                    // 切回跟随系统时先同步当前系统深浅色
//                    isSystemDark = systemIsDark()
//
//                } else {
//                    // 固定模式直接覆盖
//                    isSystemDark = (newValue == .dark)
//                }
//                applyAppearance()
//            }
//            // 跟随系统：监听系统外观变化，系统切换浅/深色时仅更新状态（避免循环）
//            .onReceive(NSApp.publisher(for: \.effectiveAppearance)) { _ in
//                // 仅在“跟随系统”模式下响应，避免固定模式循环触发
//                
//                guard settingManager.themeMode == .system else { return }
//                let nowDark = systemIsDark()
//                if nowDark != isSystemDark {
//                    isSystemDark = nowDark
//                    applyAppearance()
//
//                }
//            }
//
//        }
//        // 让主 WindowGroup 接管 `todomac://...` 外部事件（没有窗口时才创建新窗口）
//        .handlesExternalEvents(matching: Set(arrayLiteral: "todomac"))
//        .modelContainer(modelContainer.container)
//        .windowStyle(.hiddenTitleBar)
//        .windowResizability(.contentSize)
//        
//        
//        WindowGroup(id: "Settings") {
//            TDSettingsView()
//                .environmentObject(themeManager)
//                .environmentObject(settingManager)
//                .environmentObject(mainViewModel)
//                .environmentObject(scheduleModel)
//                .environmentObject(tomatoManager)
//                .environmentObject(userManager)
//                .environmentObject(settingsSidebarStore)
//                .background(
//                    TDWindowAccessor { window in
//                        TDSettingsWindowTracker.shared.attachSettingsWindow(window)
//                    }
//                )
//                .onDisappear {
//                    TDSettingsWindowTracker.shared.clearSettingsWindow()
//                }
//                .tdSettingToastBottom(
//                    isPresenting: Binding(
//                        get: { toastCenter.isSettingPresenting && toastCenter.position == .bottom },
//                        set: { toastCenter.isSettingPresenting = $0 }
//                    ),
//                    message: toastCenter.message,
//                    type: toastCenter.type
//                )
//                .preferredColorScheme(preferredScheme)
////                .environment(\.locale, currentLocale)
//            // 启动时同步一次外观与系统深浅色
//            .onAppear {
//                isSystemDark = systemIsDark()
//                applyAppearance()
//            }
//            // 当 App 内部主题模式变更时，立即应用对应外观
//            .onChange(of: settingManager.themeMode) { _, newValue in
//                if newValue == .system {
//                    // 切回跟随系统时先同步当前系统深浅色
//                    isSystemDark = systemIsDark()
//
//                } else {
//                    // 固定模式直接覆盖
//                    isSystemDark = (newValue == .dark)
//                }
//                applyAppearance()
//            }
//            // 跟随系统：监听系统外观变化，系统切换浅/深色时仅更新状态（避免循环）
//            .onReceive(NSApp.publisher(for: \.effectiveAppearance)) { _ in
//                // 仅在“跟随系统”模式下响应，避免固定模式循环触发
//                guard settingManager.themeMode == .system else { return }
//                let nowDark = systemIsDark()
//                if nowDark != isSystemDark {
//                    isSystemDark = nowDark
//                    applyAppearance()
//                }
//            }
//
//        }
//        .windowStyle(.hiddenTitleBar)
//        .windowResizability(.contentSize)
//        .defaultSize(width: 700, height: 660)
//        .defaultPosition(.center)
//        .handlesExternalEvents(matching: Set(arrayLiteral: "Settings"))
//        // 设置窗口也需要 SwiftData 容器，否则模型查询会缺上下文
//        .modelContainer(modelContainer.container)
//
////        TDToastCenter.shared.show("专注时长已存在，不能重复添加", type: .error, position: .top)   // 顶部
////        TDToastCenter.shared.show("保存成功")                                                   // 默认底部
////        TDToastCenter.shared.show("处理中…", type: .info, position: .center)                   // 中间
//    }
//
//    // MARK: - Widget / Deep Link
//    private func handleWidgetDeepLink(_ url: URL) {
//        // 仅处理我们自己的 scheme（避免误伤其他 openURL 场景）
//        guard url.scheme == "todomac" else { return }
//
//        // 激活到前台（你要“点击小组件主 App 立马切换”）
//        NSApp.activate(ignoringOtherApps: true)
//        TDSettingsWindowTracker.shared.mainWindow?.makeKeyAndOrderFront(nil)
//
//        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
//        let items = comps?.queryItems ?? []
//        func q(_ name: String) -> String? { items.first(where: { $0.name == name })?.value }
//
//        let action = q("action")?.lowercased()
//        let categoryId: Int? = {
//            if let s = q("categoryId"), let v = Int(s) { return v }
//            if let s = q("mode"), let v = Int(s) { return v } // 兼容旧参数名
//            return nil
//        }()
//        let taskId = q("taskId")?.trimmingCharacters(in: .whitespacesAndNewlines)
//
//        // 关键：深链必须“串行”，否则会出现竞态：
//        // - 切换第一栏分类的异步流程，可能在稍后把 selectedTask 清空
//        // - 导致你看到的：只有当主 App 已经在同模式下时，才会选中/出详情
//        Task { @MainActor in
//            let sliderVM = TDSliderBarViewModel.shared
//
//            // 如果点的是加号：切换模式 + 聚焦输入框（不打开详情）
//            if action == "add" {
//                if let cid = categoryId {
//                    if let model = findCategory(in: sliderVM.items, categoryId: cid) {
//                        sliderVM.selectedCategory = model
//                    } else if cid == 0 {
//                        sliderVM.selectedCategory = .uncategorized
//                    }
//                }
//                mainViewModel.selectedTask = nil
//                mainViewModel.pendingDeepLinkTaskId = nil
//                mainViewModel.pendingInputFocusRequestId = UUID()
//                return
//            }
//
//            // 点的是任务：必须保证“先切模式，再选中任务”
//            if let tid = taskId, !tid.isEmpty {
//                mainViewModel.pendingDeepLinkTaskId = tid
//            }
//
//            // 1) 第一栏：切换到对应模式/清单（直接赋值，避免额外 Task 再引入不确定顺序）
//            if let cid = categoryId {
//                if let model = findCategory(in: sliderVM.items, categoryId: cid) {
//                    sliderVM.selectedCategory = model
//                } else if cid == 0 {
//                    sliderVM.selectedCategory = .uncategorized
//                }
//            }
//
//            // 2) 等待主视图模型的 selectedCategory 确认切换完成（让异步清空逻辑在“保护标记”期间跑完）
//            if let cid = categoryId {
//                let deadline = Date().addingTimeInterval(0.8)
//                while Date() < deadline {
//                    if mainViewModel.selectedCategory?.categoryId == cid { break }
//                    await Task.yield()
//                }
//            } else {
//                // 没有 categoryId 时也让出一次执行权，保证 UI/状态先稳定
//                await Task.yield()
//            }
//
//            // 3) 打开任务详情（第二列选中 + 第三列显示）
//            if let tid = taskId, !tid.isEmpty {
//                do {
//                    let context = TDModelContainer.shared.mainContext
//                    if let task = try await TDQueryConditionManager.shared.getLocalTaskByTaskId(taskId: tid, context: context) {
//                        mainViewModel.selectedTask = task
//                    }
//                } catch {
//                    // 深链失败不弹 Toast，避免打扰
//                }
//
//                // 再让出 1-2 帧，避免极端情况下“切分类的异步 Task”延后执行把选中清掉
//                await Task.yield()
//                await Task.yield()
//                mainViewModel.pendingDeepLinkTaskId = nil
//            } else {
//                mainViewModel.pendingDeepLinkTaskId = nil
//            }
//        }
//    }
//
//    private func findCategory(in items: [TDSliderBarModel], categoryId: Int) -> TDSliderBarModel? {
//        for item in items {
//            if item.categoryId == categoryId { return item }
//            if let children = item.children, let found = findCategory(in: children, categoryId: categoryId) {
//                return found
//            }
//        }
//        return nil
//    }
//}
//
//
//// MARK: - 设置窗口追踪
//final class TDSettingsWindowTracker {
//    static let shared = TDSettingsWindowTracker()
//    
//    private var appTerminateObserver: Any?
//    private var mainWindowCloseObserver: Any?
//    private var settingsWindowCloseObserver: Any?
//
//    weak var mainWindow: NSWindow?
//    weak var settingsWindow: NSWindow?
//    
//    private init() {
//        appTerminateObserver = NotificationCenter.default.addObserver(
//            forName: NSApplication.willTerminateNotification,
//            object: nil,
//            queue: .main
//        ) { [weak self] _ in
//            self?.closeSettingsWindow()
//        }
//    }
//
//    
//    func registerMainWindow(_ window: NSWindow?) {
//        guard let window else { return }
//        guard window !== mainWindow else { return }
//        mainWindow = window
//        // 主窗口不参与系统窗口恢复，避免下次冷启动自动拉起设置窗口
//        window.isRestorable = false
//
//        if let observer = mainWindowCloseObserver {
//            NotificationCenter.default.removeObserver(observer)
//        }
//        mainWindowCloseObserver = NotificationCenter.default.addObserver(
//            forName: NSWindow.willCloseNotification,
//            object: window,
//            queue: .main
//        ) { [weak self] _ in
//            self?.closeSettingsWindow()
//        }
//    }
//    
//    func attachSettingsWindow(_ window: NSWindow?) {
//        guard let window else { return }
//        settingsWindow = window
//        window.isReleasedWhenClosed = false
//        window.isRestorable = false
//        window.titleVisibility = .hidden
//        window.titlebarAppearsTransparent = true
//        window.standardWindowButton(.zoomButton)?.isHidden = true
//        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
//        window.styleMask.insert(.fullSizeContentView)
//        // 让设置窗口保持常规级别，不随应用失焦而隐藏
//        window.level = .normal
//        window.hidesOnDeactivate = false
//        // 切换 Space / 切到其他 App 再回来时保持当前空间，避免“消失”
//        window.collectionBehavior.insert([.fullScreenNone, .moveToActiveSpace])
//        window.isMovableByWindowBackground = true
//        window.title = ""
//        
//        if let observer = settingsWindowCloseObserver {
//            NotificationCenter.default.removeObserver(observer)
//        }
//        settingsWindowCloseObserver = NotificationCenter.default.addObserver(
//            forName: NSWindow.willCloseNotification,
//            object: window,
//            queue: .main
//        ) { [weak self] _ in
//            self?.clearSettingsWindow()
//        }
//
//    }
//    
//    func clearSettingsWindow() {
//        settingsWindow = nil
//        if let observer = settingsWindowCloseObserver {
//            NotificationCenter.default.removeObserver(observer)
//            settingsWindowCloseObserver = nil
//        }
//
//    }
//    
//    func presentSettingsWindow(using openWindow: OpenWindowAction) {
//        if let window = settingsWindow {
//            window.makeKeyAndOrderFront(nil)
//            NSApp.activate(ignoringOtherApps: true)
//        } else {
//            openWindow(id: "Settings")
//        }
//    }
//    
//    func closeSettingsWindow() {
//        settingsWindow?.close()
//        settingsWindow = nil
//    }
//}
//
//// MARK: - Window Accessor
//struct TDWindowAccessor: NSViewRepresentable {
//    var onResolve: (NSWindow?) -> Void
//    
//    func makeNSView(context: Context) -> TDWindowAccessorView {
//        let view = TDWindowAccessorView()
//        view.onResolve = onResolve
//        return view
//    }
//    
//    func updateNSView(_ nsView: TDWindowAccessorView, context: Context) {}
//    
//    final class TDWindowAccessorView: NSView {
//        var onResolve: ((NSWindow?) -> Void)?
//        
//        override func viewDidMoveToWindow() {
//            super.viewDidMoveToWindow()
//            DispatchQueue.main.async { [weak self] in
//                self?.onResolve?(self?.window)
//            }
//        }
//    }
//}




//
//  TodoMacRepertorieApp.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/27.
//

import SwiftUI
import SwiftData
import AppKit

// 禁用系统窗口恢复：即使上次退出前打开了设置窗口，冷启动也不会自动恢复
final class TDAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldRestoreApplicationState(_ app: NSApplication) -> Bool { false }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 启动时关闭所有窗口的系统恢复能力
        NSApp.windows.forEach { $0.isRestorable = false }
    }
}

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
            TDMainWindowRootView(
                preferredScheme: preferredScheme,
                onOpenURL: { url, openWindow in
                    handleWidgetDeepLink(url, openWindow: openWindow)
                }
            )
            .environmentObject(userManager)
            .environmentObject(themeManager)
            .environmentObject(settingManager)
            .environmentObject(mainViewModel)
            .environmentObject(scheduleModel)
            .environmentObject(tomatoManager)
            .environmentObject(toastCenter)
            .environmentObject(settingsSidebarStore)
//            .environment(\.locale, currentLocale)

//            .tdToastBottom(
//                isPresenting: Binding(
//                    get: { toastCenter.isPresenting && toastCenter.position == .bottom },
//                    set: { toastCenter.isPresenting = $0 }
//                ),
//                message: toastCenter.message,
//                type: toastCenter.type
//            )
//            .tdToastTop(
//                isPresenting: Binding(
//                    get: { toastCenter.isPresenting && toastCenter.position == .top },
//                    set: { toastCenter.isPresenting = $0 }
//                ),
//                message: toastCenter.message,
//                type: toastCenter.type
//            )
//            .tdToastCenter(
//                isPresenting: Binding(
//                    get: { toastCenter.isPresenting && toastCenter.position == .center },
//                    set: { toastCenter.isPresenting = $0 }
//                ),
//                message: toastCenter.message,
//                type: toastCenter.type
//            )
            // 启动时同步一次外观与系统深浅色
            .onAppear {
                isSystemDark = systemIsDark()
                applyAppearance()
                // Toast 通过顶层透明 Panel 显示，避免被 sheet 遮罩盖住
                TDToastOverlayWindowManager.shared.start()

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
        // 让主 WindowGroup 接管 `todomac://...` 外部事件（没有窗口时才创建新窗口）
        .handlesExternalEvents(matching: Set(arrayLiteral: "todomac"))
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
        // 设置窗口也需要 SwiftData 容器，否则模型查询会缺上下文
        .modelContainer(modelContainer.container)

//        TDToastCenter.shared.show("专注时长已存在，不能重复添加", type: .error, position: .top)   // 顶部
//        TDToastCenter.shared.show("保存成功")                                                   // 默认底部
//        TDToastCenter.shared.show("处理中…", type: .info, position: .center)                   // 中间
    }

    // MARK: - Widget / Deep Link
    private func handleWidgetDeepLink(_ url: URL, openWindow: OpenWindowAction) {
        // 仅处理我们自己的 scheme（避免误伤其他 openURL 场景）
        guard url.scheme == "todomac" else { return }

        // 激活到前台（你要“点击小组件主 App 立马切换”）
        NSApp.activate(ignoringOtherApps: true)
        TDSettingsWindowTracker.shared.mainWindow?.makeKeyAndOrderFront(nil)

        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = comps?.queryItems ?? []
        func q(_ name: String) -> String? { items.first(where: { $0.name == name })?.value }

        let action = q("action")?.lowercased()
        let scheduleMode = q("scheduleMode")?.lowercased()
        let dateMs: Int64? = {
            guard let s = q("date"), let v = Int64(s) else { return nil }
            return v
        }()
        let categoryId: Int? = {
            if let s = q("categoryId"), let v = Int(s) { return v }
            if let s = q("mode"), let v = Int(s) { return v } // 兼容旧参数名
            return nil
        }()
        let taskId = q("taskId")?.trimmingCharacters(in: .whitespacesAndNewlines)

        // 关键：深链必须“串行”，否则会出现竞态：
        // - 切换第一栏分类的异步流程，可能在稍后把 selectedTask 清空
        // - 导致你看到的：只有当主 App 已经在同模式下时，才会选中/出详情
        Task { @MainActor in
            let sliderVM = TDSliderBarViewModel.shared

            // VIP：打开设置并切到“高级会员”
            if action == "premium" {
                TDSettingsWindowTracker.shared.presentSettingsWindow(using: openWindow)
                settingsSidebarStore.TDHandleSettingSelection(.premium)
                return
            }

            // 如果点的是加号：切换模式 + 聚焦输入框（不打开详情）
            if action == "add" {
                if let cid = categoryId {
                    if let model = findCategory(in: sliderVM.items, categoryId: cid) {
                        sliderVM.selectedCategory = model
                    } else if cid == 0 {
                        sliderVM.selectedCategory = .uncategorized
                    }
                }

                // 日程概览：切到对应周/月，并同步月份/选中日期
                if categoryId == -102, let dateMs {
                    let date = Date(timeIntervalSince1970: TimeInterval(Double(dateMs) / 1000.0))
                    scheduleModel.setMonthAndSelectDate(date)
                    if scheduleMode == "week" {
                        scheduleModel.displayMode = .week
                    } else if scheduleMode == "month" {
                        scheduleModel.displayMode = .month
                    }
                }

                mainViewModel.selectedTask = nil
                mainViewModel.pendingDeepLinkTaskId = nil
                mainViewModel.pendingInputFocusRequestId = UUID()
                return
            }

            // 点的是任务：必须保证“先切模式，再选中任务”
            if let tid = taskId, !tid.isEmpty {
                mainViewModel.pendingDeepLinkTaskId = tid
            }

            // 1) 第一栏：切换到对应模式/清单（直接赋值，避免额外 Task 再引入不确定顺序）
            if let cid = categoryId {
                if let model = findCategory(in: sliderVM.items, categoryId: cid) {
                    sliderVM.selectedCategory = model
                } else if cid == 0 {
                    sliderVM.selectedCategory = .uncategorized
                }
            }

            // 日程概览：切到对应周/月，并同步月份/选中日期
            if categoryId == -102, let dateMs {
                let date = Date(timeIntervalSince1970: TimeInterval(Double(dateMs) / 1000.0))
                scheduleModel.setMonthAndSelectDate(date)
                if scheduleMode == "week" {
                    scheduleModel.displayMode = .week
                } else if scheduleMode == "month" {
                    scheduleModel.displayMode = .month
                }
            }

            // 2) 等待主视图模型的 selectedCategory 确认切换完成（让异步清空逻辑在“保护标记”期间跑完）
            if let cid = categoryId {
                let deadline = Date().addingTimeInterval(0.8)
                while Date() < deadline {
                    if mainViewModel.selectedCategory?.categoryId == cid { break }
                    await Task.yield()
                }
            } else {
                // 没有 categoryId 时也让出一次执行权，保证 UI/状态先稳定
                await Task.yield()
            }

            // 3) 打开任务详情（第二列选中 + 第三列显示）
            if let tid = taskId, !tid.isEmpty {
                do {
                    let context = TDModelContainer.shared.mainContext
                    if let task = try await TDQueryConditionManager.shared.getLocalTaskByTaskId(taskId: tid, context: context) {
                        mainViewModel.selectedTask = task
                    }
                } catch {
                    // 深链失败不弹 Toast，避免打扰
                }

                // 再让出 1-2 帧，避免极端情况下“切分类的异步 Task”延后执行把选中清掉
                await Task.yield()
                await Task.yield()
                mainViewModel.pendingDeepLinkTaskId = nil
            } else {
                mainViewModel.pendingDeepLinkTaskId = nil
            }
        }
    }

    private func findCategory(in items: [TDSliderBarModel], categoryId: Int) -> TDSliderBarModel? {
        for item in items {
            if item.categoryId == categoryId { return item }
            if let children = item.children, let found = findCategory(in: children, categoryId: categoryId) {
                return found
            }
        }
        return nil
    }
}

private struct TDMainWindowRootView: View {
    let preferredScheme: ColorScheme?
    let onOpenURL: (URL, OpenWindowAction) -> Void

    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var userManager: TDUserManager

    var body: some View {
        Group {
            if userManager.isLoggedIn {
                TDMainView()
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
        // 关键：避免点击小组件（openURL）时不断新建主窗口
        // 让 `todomac://...` 外部事件优先复用现有窗口（若已存在）
        .handlesExternalEvents(preferring: Set(arrayLiteral: "todomac"), allowing: Set(arrayLiteral: "todomac"))
        .preferredColorScheme(preferredScheme)
        .onOpenURL { url in
            onOpenURL(url, openWindow)
        }
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
        // 主窗口不参与系统窗口恢复，避免下次冷启动自动拉起设置窗口
        window.isRestorable = false

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
        window.isRestorable = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.styleMask.insert(.fullSizeContentView)
        // 让设置窗口保持常规级别，不随应用失焦而隐藏
        window.level = .normal
        window.hidesOnDeactivate = false
        // 切换 Space / 切到其他 App 再回来时保持当前空间，避免“消失”
        window.collectionBehavior.insert([.fullScreenNone, .moveToActiveSpace])
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
