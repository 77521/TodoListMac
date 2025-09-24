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
                } else {
                    TDLoginView()
                        .frame(width: 932, height: 621)
                        .fixedSize()
                }
            }
        }
        .modelContainer(modelContainer.container)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
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
