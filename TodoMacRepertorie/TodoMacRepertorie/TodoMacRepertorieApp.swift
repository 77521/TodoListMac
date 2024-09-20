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
struct TodoMacRepertorieApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    
    
    
    var body: some Scene {
        
        
        WindowGroup {
            
            if UserInfoDataModel.isLogin == false {
                LoginAndRegistrationView()
                    .frame(width: 932, height: 570)
            }else{
                ContentView()
                
            }
            
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(UserInfoDataModel.isLogin ? .automatic : .contentSize)
//        .modelContainer(sharedModelContainer)
//        // 这里是新增的代码
//        .commands {
//            CommandMenu("新菜单"){
//                Button("子菜单 1"){
//                    print("点击 子菜单 1")
//                }
//            }
//        }
        
//        Settings {
//            LoginAndRegistrationView()
//                }

        
    }
}
