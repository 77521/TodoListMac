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
    // 模型容器
    @StateObject private var modelContainer = TDModelContainer.shared

    // 用户管理器
    @StateObject private var userManager = TDUserManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if userManager.isLoggedIn {
                    TDMainView()
                        .frame(minWidth: 1050, minHeight: 700)
                        .environment(\.modelContext, modelContainer.mainContext)
                } else {
                    TDLoginView()
                        .frame(width: 932, height: 621)
                        .fixedSize()
                }
            }
        }
        .modelContainer(modelContainer.modelContainer)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }

}
