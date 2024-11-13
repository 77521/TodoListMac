////
////  ContentView.swift
////  TodoMacRepertorie
////
////  Created by apple on 2024/5/30.
////
//
//import SwiftUI
//import SwiftData
//
//struct ContentView: View {
//    
//
//    @Environment(\.openWindow) private var openWindow
//    @Environment(\.presentationMode) var presentationMode
//    @Environment(\.modelContext) private var modelContext
//    @Query private var items: [Item]
//    @State private var columnVisibility = NavigationSplitViewVisibility.all
//    @State private var isShowingInspector = false
//
//    @StateObject var leftDataManager = TDNetWorkManager()
//    // 选中第一列的数据
//    @State var categorySelectModel : TDLeftDataModel = TDLeftDataModel()
//
//    
//    var body: some View {
//        
//        
//        NavigationSplitView(columnVisibility: $columnVisibility) {
//            TDLeftListView(categoryModel: $categorySelectModel)
//            .navigationSplitViewColumnWidth(min: 260, ideal: 280, max: 280)
//            .toolbar {
//                ToolbarItem {
//                    TDLeftToobarView()
//                        .frame(height: 50)
//                }
//
//            }
////            .toolbar(removing: .sidebarToggle)// 隐藏打开关闭侧边栏开关按钮
//            .toolbarBackground(.red)
//            .onAppear {
//                if !UserInfoDataModel.sharedUserInfoDataModel.isLogin {
//                    openWindow(id: "TodoAPPLogin")
//                    presentationMode.wrappedValue.dismiss()
//
//                }
//            }
////            .onAppear {
////                            // 隐藏最小化按钮
////                            NSApp.windows.first?.standardWindowButton(.miniaturizeButton)?.isHidden = true
////                            // 隐藏关闭按钮
////                            NSApp.windows.first?.standardWindowButton(.closeButton)?.isHidden = true
////                            // 隐藏退出按钮
////                            NSApp.windows.first?.standardWindowButton(.zoomButton)?.isHidden = true
////                        }
//        } content: {
//            List {
//                TDMiddleView(categoryModel: categorySelectModel)
//                
//            }
//            .navigationSplitViewColumnWidth(min: 400, ideal: 250)
//            .toolbar {
//                ToolbarItem(placement: .navigation) {// 第二列 顶部 toobar 放在左边
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
//            }
//            .navigationTitle("")
//
//        } detail: {
//            Text("Detail")
//        }
//        .navigationSplitViewStyle(.automatic)
//        .environmentObject(leftDataManager)
//        .environmentObject(categorySelectModel)
//    }
//
//    private func addItem() {
//        withAnimation {
//            UserInfoDataModel.sharedUserInfoDataModel.removeUserInfo()
//            openWindow(id: "TodoAPPLogin")
//            presentationMode.wrappedValue.dismiss()
//
//            let newItem = Item(timestamp: Date())
//            modelContext.insert(newItem)
//        }
//    }
//
//    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            for index in offsets {
//                modelContext.delete(items[index])
//            }
//        }
//    }
//}
//
//#Preview {
////    ContentView(categorySelectModel: <#TDLeftDataModel#>)
////        .modelContainer(for: Item.self, inMemory: true)
//}
