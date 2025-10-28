//
//  TodoMacRepertorieApp.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/27.
//

import SwiftUI
import SwiftData

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
    init() {
            // 监听任意窗口关闭事件：如果关闭的不是设置窗口，则关闭设置窗口
            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: nil, queue: .main) { notification in
                guard let closingWindow = notification.object as? NSWindow else { return }
                // 如果关闭的不是设置窗口，则关闭设置窗口（跟随主窗口）
                if closingWindow != TDSettingsWindowTracker.shared.settingsWindow {
                    TDSettingsWindowTracker.shared.settingsWindow?.close()
                }
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
                } else {
                    TDLoginView()
                        .frame(width: 932, height: 621)
                        .fixedSize()
                }
            }
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
        
        // 设置窗口（默认隐藏，只有点击设置按钮时才打开）
        WindowGroup(id: "Settings") {
            TDSettingsView()
                .environmentObject(themeManager)
                .environmentObject(settingManager)
            // 设置窗口属性与跟踪
            .onAppear {
                DispatchQueue.main.async {
                    // 记录设置窗口引用
                    TDSettingsWindowTracker.shared.settingsWindow = NSApp.keyWindow
                    // 设置为浮动并在失活时隐藏（行为更贴近系统）
                    TDSettingsWindowTracker.shared.settingsWindow?.level = .floating
                    TDSettingsWindowTracker.shared.settingsWindow?.hidesOnDeactivate = true
                }
            }


        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .handlesExternalEvents(matching: Set(arrayLiteral: "Settings"))

//        TDToastCenter.shared.show("专注时长已存在，不能重复添加", type: .error, position: .top)   // 顶部
//        TDToastCenter.shared.show("保存成功")                                                   // 默认底部
//        TDToastCenter.shared.show("处理中…", type: .info, position: .center)                   // 中间
    }
}

// 跟踪设置窗口的简单管理器（弱引用避免循环持有）
final class TDSettingsWindowTracker {
    static let shared = TDSettingsWindowTracker()
    weak var settingsWindow: NSWindow?
    private init() {}
}

//
//  TodoMacRepertorieApp.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/27.
//

//import SwiftUI
//import SwiftData
//
//@main
//struct TodoMacRepertorieApp: App {
//    // 模型容器
//    @StateObject private var modelContainer = TDModelContainer.shared
//
//    // 用户管理器
//    @StateObject private var userManager = TDUserManager.shared
//    
//    // 用户管理器
//    @Environment(\.openWindow) private var openWindow
//    @Environment(\.dismissWindow) private var dismissWindow
//
//    
//    var body: some Scene {
//        // 登录窗口
//        WindowGroup(id: "Login") {
//            TDLoginView()
//                .frame(width: 932, height: 621)
//                .fixedSize()
//                .onAppear {
//                    if userManager.isLoggedIn {
//                        openWindow(id: "Main")
//                        dismissWindow(id: "Login")
//                    }
//                }
//                .onChange(of: userManager.isLoggedIn) { oldValue, newValue in
//                    if newValue {
//                        openWindow(id: "Main")
//                        dismissWindow(id: "Login")
//                    }
//                }
//        }
//        .windowStyle(.hiddenTitleBar)
//        .windowResizability(.contentSize)
//        .modelContainer(modelContainer.modelContainer)
//
//        // 主窗口
//        WindowGroup(id: "Main") {
//            TDMainView()
//                .frame(minWidth: 1100, minHeight: 700)
//                .environment(\.modelContext, modelContainer.mainContext)
//                .onAppear {
//                    if !userManager.isLoggedIn {
//                        openWindow(id: "Login")
//                        dismissWindow(id: "Main")
//                    }
//                }
//                .onChange(of: userManager.isLoggedIn) { oldValue, newValue in
//                    if !newValue {
//                        openWindow(id: "Login")
//                        dismissWindow(id: "Main")
//                    }
//                }
//
//        }
//        .windowStyle(.hiddenTitleBar)
//        .modelContainer(modelContainer.modelContainer)
//        
//    }
//
//}
