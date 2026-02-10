////
////  TDTaskDetailBottomToolbar.swift
////  TodoMacRepertorie
////
////  Created by 孬孬 on 2024/12/28.
////
//
//import SwiftUI
//import SwiftData
//import AppKit
//
///// 任务详情底部工具栏组件
///// 包含：选择时间、重复、附件、标签、更多按钮
//struct TDTaskDetailBottomToolbar: View {
//    // MARK: - 数据绑定和依赖注入
//    @Bindable var task: TDMacSwiftDataListModel  // 当前任务数据（可绑定修改）
//    @EnvironmentObject private var themeManager: TDThemeManager  // 主题管理器
//    @Environment(\.modelContext) private var modelContext  // SwiftData 数据上下文
//    
//    // MARK: - 状态变量
//    @State private var showTagView = false  // 是否显示标签选择视图
//    @State private var showToast = false  // 是否显示Toast提示
//    @State private var toastMessage = ""  // Toast提示内容
//    
//    // MARK: - 主视图
//    var body: some View {
//        HStack(alignment: .center, spacing: 12) {
//            // MARK: - 时间选择按钮（第一个按钮）
//
//            TDTimeButtonView(task: task) {
//                syncTaskData(operation: "设置提醒时间")  // 同步数据到数据库
//            }
//            
//            // MARK: - 重复按钮（第二个按钮）
//            
//            TDRepeatSettingView(task: task) {
//                syncTaskData(operation: "设置重复任务")  // 同步数据到数据库
//
//            }
//            
//            // MARK: - 附件按钮（第三个按钮）
//            TDAttachmentButtonView(
//                task: task,
//                onAttachmentSet: {
//                    syncTaskData(operation: "设置附件")  // 同步数据到数据库
//                },
//                onShowToast: { message in
//                    showToastMessage(message)
//                }
//            )
//            
//            // MARK: - 标签按钮（第四个按钮）
//            //            Button(action: {
//            //                showTagView = true  // 显示标签选择弹窗
//            //            }) {
//            //                // 标签按钮始终显示灰色圆形图标（#号图标）
//            //                Image(systemName: "number")
//            //                    .font(.system(size: 16))
//            //                    .foregroundColor(themeManager.descriptionTextColor)
//            //                    .frame(width: 32, height: 32)
//            //                    .background(
//            //                        Circle()
//            //                            .fill(themeManager.secondaryBackgroundColor)
//            //                    )
//            //            }
//            //            .buttonStyle(PlainButtonStyle())
//            //            .help("标签")  // 鼠标悬停提示
//            
//            Spacer()  // 弹性空间，将更多按钮推到右边
//            
//            // MARK: - 更多选项按钮（右边按钮）
//            TDMoreOptionsButtonView(
//                task: task,
//                onMoreOptionsSet: {
//                    syncTaskData(operation: "更多选项操作")  // 同步数据到数据库
//                },
//                onShowToast: { message in
//                    showToastMessage(message)
//                }
//            )
//            
//        }
//        .padding(.horizontal, 12)  // 左右内边距
//        .padding(.vertical, 10)    // 上下内边距
//        .background(Color(.controlBackgroundColor))  // 工具栏背景色
//        .overlay(
//            // 顶部边框线
//            Rectangle()
//                .frame(height: 1)
//                .foregroundColor(themeManager.separatorColor),
//            alignment: .top
//        )
//        // MARK: - 弹窗组件
//        
//        // 标签选择弹窗
//        //        .popover(isPresented: $showTagView) {
//        //            VStack(spacing: 16) {
//        //                Text("选择标签")
//        //                    .font(.headline)
//        //
//        //                // 标签功能预留位置
//        //                Text("标签功能开发中...")
//        //                    .foregroundColor(themeManager.descriptionTextColor)
//        //
//        //                Button("确定") {
//        //                    showTagView = false
//        //                }
//        //                .buttonStyle(.borderedProminent)
//        //            }
//        //            .padding()
//        //            .frame(width: 250, height: 150)
//        //        }
//        // 通用Toast提示弹窗
//        .tdToastBottom(
//            isPresenting: $showToast,
//            message: toastMessage,
//            type: .info
//        )
//    }
//    
//    // MARK: - 私有方法
//    /// 同步任务数据到数据库和服务器
//    /// - Parameter operation: 操作描述，用于日志记录
//    private func syncTaskData(operation: String) {
//        Task {
//            await TDMainViewModel.shared.performSyncSeparately()
//            
//        }
//    }
//    
//    /// 显示Toast提示消息
//    /// - Parameter message: 提示消息内容
//    private func showToastMessage(_ message: String) {
//        toastMessage = message
//        showToast = true
//    }
//    
//}
//
//// MARK: - 预览组件
//#Preview {
//    TDTaskDetailBottomToolbar(task: TDMacSwiftDataListModel(
//        id: 1,
//        taskId: "preview_task",
//        taskContent: "预览任务",
//        taskDescribe: "这是一个预览任务",
//        complete: false,
//        createTime: Date().startOfDayTimestamp,
//        delete: false,
//        reminderTime: 0,
//        snowAdd: 0,
//        snowAssess: 0,
//        standbyInt1: 1, // 分类ID，在事件内使用standbyInt1
//        standbyStr1: nil,
//        standbyStr2: nil,
//        standbyStr3: nil,
//        standbyStr4: nil,
//        syncTime: Date().startOfDayTimestamp,
//        taskSort: Decimal(1),
//        todoTime: Date().startOfDayTimestamp,
//        userId: 1,
//        version: 1,
//        status: "sync",
//        isSubOpen: true,
//        standbyIntColor: "",
//        standbyIntName: "",
//        reminderTimeString: "",
//        subTaskList: [],
//        attachmentList: []
//    ))
//    .environmentObject(TDThemeManager.shared)
//}

//
//  TDTaskDetailBottomToolbar.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData
import AppKit

/// 任务详情底部工具栏组件
/// 包含：选择时间、重复、附件、标签、更多按钮
struct TDTaskDetailBottomToolbar: View {
    // MARK: - 数据绑定和依赖注入
    @Bindable var task: TDMacSwiftDataListModel  // 当前任务数据（可绑定修改）
    @EnvironmentObject private var themeManager: TDThemeManager  // 主题管理器
    @Environment(\.modelContext) private var modelContext  // SwiftData 数据上下文
    
    // MARK: - 状态变量
    @State private var showTagView = false  // 是否显示标签选择视图
    
    // MARK: - 主视图
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // MARK: - 时间选择按钮（第一个按钮）

            TDTimeButtonView(task: task) {
                syncTaskData(operation: "设置提醒时间")  // 同步数据到数据库
            }
            
            // MARK: - 重复按钮（第二个按钮）
            
            TDRepeatSettingView(task: task) {
                syncTaskData(operation: "设置重复任务")  // 同步数据到数据库

            }
            
            // MARK: - 附件按钮（第三个按钮）
            TDAttachmentButtonView(
                task: task,
                onAttachmentSet: {
                    syncTaskData(operation: "设置附件")  // 同步数据到数据库
                },
                onShowToast: { message in
                    TDToastCenter.shared.show(message, type: .info, position: .bottom)
                }
            )
            
            // MARK: - 标签按钮（第四个按钮）
            //            Button(action: {
            //                showTagView = true  // 显示标签选择弹窗
            //            }) {
            //                // 标签按钮始终显示灰色圆形图标（#号图标）
            //                Image(systemName: "number")
            //                    .font(.system(size: 16))
            //                    .foregroundColor(themeManager.descriptionTextColor)
            //                    .frame(width: 32, height: 32)
            //                    .background(
            //                        Circle()
            //                            .fill(themeManager.secondaryBackgroundColor)
            //                    )
            //            }
            //            .buttonStyle(PlainButtonStyle())
            //            .help("标签")  // 鼠标悬停提示
            
            Spacer()  // 弹性空间，将更多按钮推到右边
            
            // MARK: - 更多选项按钮（右边按钮）
            TDMoreOptionsButtonView(
                task: task,
                onMoreOptionsSet: {
                    syncTaskData(operation: "更多选项操作")  // 同步数据到数据库
                },
                onShowToast: { message in
                    TDToastCenter.shared.show(message, type: .info, position: .bottom)
                }
            )
            
        }
        .padding(.horizontal, 12)  // 左右内边距
        .padding(.vertical, 10)    // 上下内边距
        .background(Color(.controlBackgroundColor))  // 工具栏背景色
        .overlay(
            // 顶部边框线
            Rectangle()
                .frame(height: 1)
                .foregroundColor(themeManager.separatorColor),
            alignment: .top
        )
        // MARK: - 弹窗组件
        
        // 标签选择弹窗
        //        .popover(isPresented: $showTagView) {
        //            VStack(spacing: 16) {
        //                Text("选择标签")
        //                    .font(.headline)
        //
        //                // 标签功能预留位置
        //                Text("标签功能开发中...")
        //                    .foregroundColor(themeManager.descriptionTextColor)
        //
        //                Button("确定") {
        //                    showTagView = false
        //                }
        //                .buttonStyle(.borderedProminent)
        //            }
        //            .padding()
        //            .frame(width: 250, height: 150)
        //        }
    }
    
    // MARK: - 私有方法
    /// 同步任务数据到数据库和服务器
    /// - Parameter operation: 操作描述，用于日志记录
    private func syncTaskData(operation: String) {
        Task {
            await TDMainViewModel.shared.performSyncSeparately()
            
        }
    }
    
}

// MARK: - 预览组件
#Preview {
    TDTaskDetailBottomToolbar(task: TDMacSwiftDataListModel(
        id: 1,
        taskId: "preview_task",
        taskContent: "预览任务",
        taskDescribe: "这是一个预览任务",
        complete: false,
        createTime: Date().startOfDayTimestamp,
        delete: false,
        reminderTime: 0,
        snowAdd: 0,
        snowAssess: 0,
        standbyInt1: 1, // 分类ID，在事件内使用standbyInt1
        standbyStr1: nil,
        standbyStr2: nil,
        standbyStr3: nil,
        standbyStr4: nil,
        syncTime: Date().startOfDayTimestamp,
        taskSort: Decimal(1),
        todoTime: Date().startOfDayTimestamp,
        userId: 1,
        version: 1,
        status: "sync",
        isSubOpen: true,
        standbyIntColor: "",
        standbyIntName: "",
        reminderTimeString: "",
        subTaskList: [],
        attachmentList: []
    ))
    .environmentObject(TDThemeManager.shared)
}
