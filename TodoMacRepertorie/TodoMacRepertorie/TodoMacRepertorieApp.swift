//
//  TodoMacRepertorieApp.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/5/30.
//

import SwiftUI
import SwiftData
import AppKit

@main





//struct TodoMacRepertorieApp: App {
////    var sharedModelContainer: ModelContainer = {
////        let schema = Schema([
////            Item.self,
////        ])
////        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
////
////        do {
////            return try ModelContainer(for: schema, configurations: [modelConfiguration])
////        } catch {
////            fatalError("Could not create ModelContainer: \(error)")
////        }
////    }()
//    @StateObject private var themeManager = TDThemeManager.shared
//
//    var sharedModelContainer: ModelContainer = {
//        let schema = Schema([
//            TDMiddleSwiftDataModel.self,
//        ])
//        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//
//        do {
//            return try ModelContainer(for: schema, configurations: [modelConfiguration])
//        } catch {
//            fatalError("Could not create ModelContainer: \(error)")
//        }
//    }()
//
//
//    var model: () = UserInfoDataModel.sharedUserInfoDataModel.loadUserInfoData()
//
//    var body: some Scene {
//
//
//        WindowGroup(id:"TodoAPPLogin") {
//            LoginAndRegistrationView()
//                .environmentObject(themeManager)
//                .preferredColorScheme(themeManager.followSystem ? nil :
//                    themeManager.currentTheme.isDark ? .dark : .light)
//                .animation(.easeInOut, value: themeManager.currentTheme)
//                .frame(width: 932, height: 570)
//        }
//        .windowStyle(HiddenTitleBarWindowStyle())
//        .windowResizability(.contentSize)
//
//
//
//        WindowGroup(id: "TodoAPP") {
//            ContentView()
//                .environmentObject(themeManager)
//                .preferredColorScheme(themeManager.followSystem ? nil :
//                    themeManager.currentTheme.isDark ? .dark : .light)
//                .animation(.easeInOut, value: themeManager.currentTheme)
//                .onAppear {
//                    TDNetWorkManager().requestCategoryDatas()
//                }
//        }
//        .modelContainer(for: TDMiddleSwiftDataModel.self)
//        .windowResizability(.automatic)
//
//        .modelContainer(sharedModelContainer)
////        // 这里是新增的代码
////        .commands {
////            CommandMenu("新菜单"){
////                Button("子菜单 1"){
////                    print("点击 子菜单 1")
////                }
////            }
////        }
//
////        Settings {
////            LoginAndRegistrationView()
////                }
//
//
//    }
//}


struct TodoMacRepertorieApp: App {
    @StateObject private var userManager = TDUserManager.shared
    
    
    var body: some Scene {
        WindowGroup {
            Group {
                if userManager.isLoggedIn {
                    TDMainView()
                        .frame(minWidth: 800, minHeight: 600)
                        .customWindow(
                            title: "应用名称",
                            isResizable: true,
                            showTitleBar: true
                        )

                } else {
                    TDLoginView()
                        .frame(width: 932, height: 621)
                        .fixedSize()
                        .customWindow(
                            title: "登录",
                            isResizable: false,
                            showTitleBar: false
                        )

                }
            }
            .animation(.easeInOut, value: userManager.isLoggedIn)
        }
        .windowStyle(.hiddenTitleBar) // 默认隐藏标题栏
        .windowResizability(.contentSize) // 默认允许调整大小
    }
}
