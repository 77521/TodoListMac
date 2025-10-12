//
//  TDSubtaskRowView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI


/// 子任务行视图
struct TDSubtaskRowView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    
    // 任务数据
    @Bindable var task: TDMacSwiftDataListModel
    let index: Int
    let subTaskId: String
    
    // 回调
    let onToggleComplete: (Bool) -> Void
    let onDelete: () -> Void
    
    let onContentChanged: () -> Void  // 内容变化时的回调

    // 编辑状态
    @FocusState private var isInputFocused: Bool

    var body: some View {
        // 检查索引是否有效，如果无效则不渲染
        if index < task.subTaskList.count {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // 完成状态按钮
                    Button(action: {
                        onToggleComplete(!task.subTaskList[index].isComplete)
                    }) {
                        Image(systemName: task.subTaskList[index].isComplete ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16))
                            .foregroundColor(task.subTaskList[index].isComplete ? themeManager.color(level: 5) : themeManager.descriptionTextColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 实际的 TextField
                    TextField("", text: $task.subTaskList[index].content, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .focused($isInputFocused)
                        .foregroundColor(themeManager.subtaskTextColor)
                        .strikethrough(task.subTaskList[index].isComplete)
                        .opacity(task.subTaskList[index].isComplete ? 0.6 : 1.0)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onChange(of: task.subTaskList[index].content) { _, newValue in
                            // 使用 ID 查找当前子任务的索引
                            guard let currentIndex = task.subTaskList.firstIndex(where: { $0.id == subTaskId }) else { return }
                            
                            // 当内容被删除完时，自动触发删除
                            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onDelete()
                            } else if newValue.count > 80 {
                                // 限制80个字符
                                task.subTaskList[currentIndex].content = String(newValue.prefix(80))
                            }
                        }
                        .onChange(of: isInputFocused) { _, isFocused in
                            // 当输入框失去焦点时触发同步
                            if !isFocused {
                                onContentChanged()
                            }
                        }
                // 操作按钮（紧挨着输入框）
                HStack(spacing: 8) {
                    // 删除按钮
                    Button(action: {
                        onDelete()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.descriptionTextColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()

                    // 拖拽手柄
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.descriptionTextColor)
                    .help("拖拽排序")
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.white)
            
                // 分割线
                Rectangle()
                    .fill(themeManager.descriptionTextColor.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
            }

        } else {
            // 索引无效时，返回空视图
            EmptyView()
        }
    }
}
//
//#Preview {
//    let sampleTask = TDMacSwiftDataListModel(
//        id: 1,
//        userId: 1,
//        taskId: "test",
//        complete: false,
//        delete: false,
//        todoTime: Date().timeIntervalSince1970 * 1000,
//        taskSort: 0,
//        standbyInt1: 0,
//        createTime: Date().timeIntervalSince1970 * 1000,
//        syncTime: Date().timeIntervalSince1970 * 1000,
//        snowAssess: 0,
//        standbyStr1: nil,
//        version: 1,
//        taskContent: "测试任务",
//        taskDescribe: nil,
//        standbyStr2: nil,
//        standbyStr3: nil,
//        standbyStr4: nil,
//        reminderTime: nil,
//        snowAdd: 0,
//        isSubOpen: false,
//        standbyIntColor: nil,
//        standbyIntName: nil,
//        reminderTimeString: nil,
//        subTaskList: [
//            TDMacSwiftDataListModel.SubTask(isComplete: false, content: "单行子任务"),
//            TDMacSwiftDataListModel.SubTask(isComplete: true, content: "多行子任务已添加多行多行多行多行多行多行多行多行多行多行多行,氛围架构。发将诶我阿济格发将诶我阿。")
//        ],
//        attachmentList: []
//    )
//    
//    VStack(spacing: 8) {
//        TDSubtaskRowView(
//            task: sampleTask,
//            index: 0,
//            onToggleComplete: { _ in },
//            onDelete: { }
//        )
//        
//        TDSubtaskRowView(
//            task: sampleTask,
//            index: 1,
//            onToggleComplete: { _ in },
//            onDelete: { }
//        )
//    }
//    .padding()
//    .environmentObject(TDThemeManager())
//}
