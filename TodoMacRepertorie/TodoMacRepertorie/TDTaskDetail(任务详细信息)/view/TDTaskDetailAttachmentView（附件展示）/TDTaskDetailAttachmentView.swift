//
//  TDTaskDetailAttachmentView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import UniformTypeIdentifiers

/// 附件视图
struct TDTaskDetailAttachmentView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    
    @Bindable var task: TDMacSwiftDataListModel
    
    let onAttachmentDeleted: (() -> Void)?

    // 拖拽状态
    @State private var dragAttachment: TDMacSwiftDataListModel.Attachment?
    
    init(task: TDMacSwiftDataListModel, onAttachmentDeleted: (() -> Void)? = nil) {
        self.task = task
        self.onAttachmentDeleted = onAttachmentDeleted
    }
    
    var body: some View {
        ZStack {
            // 附件列表 - 自适应列数，带边框
            if !task.attachmentList.isEmpty {
                GeometryReader { geometry in
                    let containerWidth = geometry.size.width
                    let itemWidth: CGFloat = 95
                    let spacing: CGFloat = 15
                    let horizontalPadding: CGFloat = 30 // 左右各16pt
                    
                    // 计算能放多少个：容器宽度 - 左右padding - 间距
                    let availableWidth = containerWidth - horizontalPadding - spacing
                    let columnsCount = Int(availableWidth / (itemWidth + spacing))
                    let finalColumnsCount = max(1, columnsCount) // 至少1列
                    
                    let columns = Array(repeating: GridItem(.fixed(95), spacing: 15), count: finalColumnsCount)
                    
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 15) {
                        ForEach(Array(task.attachmentList.enumerated()), id: \.element.id) { index, attachment in
                            TDAttachmentItemView(attachment: attachment,task:task) {
                                // 删除附件的回调
                                deleteAttachment(at: index)
                            }
                                .frame(width: 95, height: 95)
                                .background(.clear)
                                .cornerRadius(8)
                            .onDrag {
                                createDragProvider(for: attachment)
                            }
                            .onDrop(of: [.text], delegate: AttachmentDropDelegate(
                                item: attachment,
                                listData: task.attachmentList,
                                current: $dragAttachment,
                                moveAction: { direction in
                                    print("moveAction 被调用: \(direction)")
                                    guard let draggedItem = dragAttachment else {
                                        print("draggedItem 为空")
                                        return
                                    }
                                    handleMoveAction(direction: direction, draggedItem: draggedItem, targetItem: attachment)
                                },
                                onDropCompleted: {
                                    // 拖拽完成后的同步回调
                                    onAttachmentDeleted?()
                                }
                            ))
                            .opacity(dragAttachment?.id == attachment.id ? 0.8 : 1.0)
                            .scaleEffect(dragAttachment?.id == attachment.id ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: dragAttachment?.id)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(themeManager.separatorColor, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .frame(height: calculateGridHeight(for: task.attachmentList.count, containerWidth: 300)) // 明确设置高度
            }
        }

        
    }
    
    /// 删除指定索引的附件
    private func deleteAttachment(at index: Int) {
        guard index < task.attachmentList.count else { return }
        
        // 从任务中移除附件
        task.attachmentList.remove(at: index)
        task.standbyStr4 = task.generateAttachmentListString()
        
        print("✅ 附件已从任务中移除，索引: \(index)")
        
        // 通知父视图进行同步
        onAttachmentDeleted?()
    }
    
    /// 创建拖拽提供者
    private func createDragProvider(for item: TDMacSwiftDataListModel.Attachment) -> NSItemProvider {
        print("开始拖拽: \(item.name)")
        let provider = NSItemProvider(object: NSString(string: item.id))
        provider.suggestedName = "attachments"
        dragAttachment = item
        print("设置拖拽状态: \(dragAttachment?.name ?? "nil")")
        return provider
    }
    
    /// 处理移动操作
    private func handleMoveAction(direction: AttachmentMoveEnum, draggedItem: TDMacSwiftDataListModel.Attachment, targetItem: TDMacSwiftDataListModel.Attachment) {
        print("处理移动操作: \(draggedItem.name) -> \(targetItem.name), 方向: \(direction == .left ? "左" : "右")")
        
        guard draggedItem != targetItem else {
            print("拖拽到自己，跳过")
            return
        }
        
        guard let draggedIndex = task.attachmentList.firstIndex(where: { $0.id == draggedItem.id }),
              let targetIndex = task.attachmentList.firstIndex(where: { $0.id == targetItem.id }) else {
            print("找不到索引，跳过")
            return
        }
        
        print("原始索引: 拖拽=\(draggedIndex), 目标=\(targetIndex)")
        
        withAnimation {
            // 先计算插入位置，考虑移除元素后的索引变化
            var insertIndex: Int
            if draggedIndex < targetIndex {
                // 如果拖拽元素在目标元素之前，移除后目标元素索引会减1
                insertIndex = direction == .left ? targetIndex - 1 : targetIndex
            } else {
                // 如果拖拽元素在目标元素之后，目标元素索引不变
                insertIndex = direction == .left ? targetIndex : targetIndex + 1
            }
            
            // 确保插入索引在有效范围内
            insertIndex = max(0, min(insertIndex, task.attachmentList.count - 1))
            
            print("计算插入索引: \(insertIndex)")
            
            task.attachmentList.remove(at: draggedIndex)
            task.attachmentList.insert(draggedItem, at: insertIndex)
            task.standbyStr4 = task.generateAttachmentListString()
            
            print("移动完成")
        }
        
    }
    
    /// 计算网格高度
    private func calculateGridHeight(for itemCount: Int, containerWidth: CGFloat) -> CGFloat {
        let itemWidth: CGFloat = 80
        let spacing: CGFloat = 15
        let horizontalPadding: CGFloat = 30
        
        // 计算列数
        let availableWidth = containerWidth - horizontalPadding - spacing
        let columnsCount = Int(availableWidth / (itemWidth + spacing))
        let finalColumnsCount = max(1, columnsCount)
        
        // 计算行数
        let rows = (itemCount + finalColumnsCount - 1) / finalColumnsCount
        let itemHeight: CGFloat = 100 // 80 + 20 for text
        let totalHeight = CGFloat(rows) * itemHeight + CGFloat(rows - 1) * spacing
        
        return max(100, totalHeight)
    }

}

/// 附件项视图
struct TDAttachmentItemView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    
    let attachment: TDMacSwiftDataListModel.Attachment
    let task : TDMacSwiftDataListModel
    let onDelete: (() -> Void)?

    // 下载状态管理
    @State private var isDownloading: Bool = false
    
    init(attachment: TDMacSwiftDataListModel.Attachment, task:TDMacSwiftDataListModel, onDelete: (() -> Void)? = nil) {
        self.attachment = attachment
        self.task = task
        self.onDelete = onDelete
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // 文件图标/预览 - 正方形显示
            Group {
                if attachment.isPhoto {
                    // 图片文件，不管是否下载都显示缩略图
                    AsyncImage(url: URL(string: attachment.url)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(themeManager.descriptionTextColor)
                    }
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeManager.separatorColor, lineWidth: 1)
                    )
                } else {
                    // 其他文件，根据下载状态显示不同内容
                    if TDFileManager.shared.isAttachmentDownloaded(fullName: attachment.getFullFileName(), taskId: task.taskId) {
                        // 已下载，显示文件图标
                        Image(systemName: TDFileManager.shared.getFileIcon(attachment.suffix ?? "unknown"))
                            .font(.system(size: 32))
                            .foregroundColor(themeManager.color(level: 5))
                            .frame(width: 80, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(themeManager.secondaryBackgroundColor)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(themeManager.separatorColor, lineWidth: 1)
                                    )
                            )
                    } else {
                        // 未下载，显示下载图标和文件大小
                        VStack(spacing: 2) {
                            Image(systemName: "arrowshape.down.fill")
                                .font(.system(size: 24))
                                .foregroundColor(themeManager.descriptionTextColor)
                            
                            // 文件大小
                            Text(TDFileManager.shared.formatFileSize(attachment.size))
                                .font(.system(size: 8))
                                .foregroundColor(themeManager.descriptionTextColor)
                                .lineLimit(1)
                        }
                        .frame(width: 80, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(themeManager.secondaryBackgroundColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(themeManager.separatorColor, lineWidth: 1)
                                )
                        )
                    }
                }
            }
            
            // 文件名（包含后缀）
            Text(attachment.getFullFileName())
                .font(.system(size: 10))
                .foregroundColor(themeManager.titleTextColor)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .truncationMode(.middle)  // 省略号显示在中间
                .frame(width: 80)
        }
        .onTapGesture {
            // 统一点击逻辑：下载或打开
            if TDFileManager.shared.isAttachmentDownloaded(fullName: attachment.getFullFileName(), taskId: task.taskId) {
                openAttachment()
            } else {
                downloadAttachment()
                openAttachment()
            }
        }
        .contextMenu {
            // 根据下载状态显示不同的右键菜单
            if TDFileManager.shared.isAttachmentDownloaded(fullName: attachment.getFullFileName(), taskId: task.taskId) {
                // 已下载文件的菜单
                Button("打开") {
                    openAttachment()
                }
                .pointingHandCursor()

                Button("查看文件夹") {
                    showInFinder()
                }
                .pointingHandCursor()

                Button("从浏览器打开") {
                    openInBrowser()
                }
                .pointingHandCursor()

                Divider()
                
                Button("删除") {
                    onDelete?()
                }
                .pointingHandCursor()
                .foregroundColor(.red)
            } else {
                // 未下载文件的菜单
                Button("从浏览器打开") {
                    openInBrowser()
                }
                .pointingHandCursor()

                Button("下载到本地") {
                    downloadAttachment()
                }
                .pointingHandCursor()

                Divider()
                
                Button("删除") {
                    onDelete?()
                }
                .pointingHandCursor()
                .foregroundColor(.red)
            }
        }
        .overlay(
            // 下载进度指示器
            Group {
                if isDownloading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 80, height: 80)
                }
            }
        )
    }
    
    /// 下载附件
    private func downloadAttachment() {
        isDownloading = true
        Task {
            do {
                let fullFileName = attachment.getFullFileName()
                _ = try await TDFileManager.shared.downloadFile(
                    from: attachment.url,
                    fileName: fullFileName,
                    taskId: task.taskId
                )
                print("✅ 附件下载成功: \(fullFileName)")
            } catch {
                print("❌ 附件下载失败: \(error)")
            }
            
            isDownloading = false
        }
    }
    
    /// 打开附件
    private func openAttachment() {
        Task {
            let fullFileName = attachment.getFullFileName()
            await TDFileManager.shared.openAttachment(
                url: attachment.url,
                fullFileName: fullFileName,
                taskId: task.taskId
            )
        }
    }
    
    /// 在 Finder 中显示文件
    private func showInFinder() {
        let fullFileName = attachment.getFullFileName()
        TDFileManager.shared.showInFinder(fullFileName: fullFileName, taskId: task.taskId)
    }
    
    /// 在浏览器中打开
    private func openInBrowser() {
        TDFileManager.shared.openInBrowser(url: attachment.url)
    }

}

// MARK: - 移动方向枚举
enum AttachmentMoveEnum: Int {
    case left
    case right
}

// MARK: - 附件拖拽代理
struct AttachmentDropDelegate: DropDelegate {
    let item: TDMacSwiftDataListModel.Attachment
    var listData: [TDMacSwiftDataListModel.Attachment]
    @Binding var current: TDMacSwiftDataListModel.Attachment?
    var moveAction: (AttachmentMoveEnum) -> Void
    var onDropCompleted: (() -> Void)?

//    init(item: TDMacSwiftDataListModel.Attachment, listData: [TDMacSwiftDataListModel.Attachment], current: Binding<TDMacSwiftDataListModel.Attachment?>, moveAction: @escaping (AttachmentMoveEnum) -> Void) {
//        self.item = item
//        self.listData = listData
//        self._current = current
//        self.moveAction = moveAction
//        print("创建拖拽代理: \(item.name)")
//    }

    func dropEntered(info: DropInfo) {
        print("拖拽进入: \(item.name)")
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        print("拖拽更新: \(item.name), location.x = \(info.location.x), current = \(current?.name ?? "nil")")
        
        guard let current = current else {
            print("当前拖拽项目为空，跳过")
            return DropProposal(operation: .move)
        }
        
        if item.id != current.id {
            print("开始移动: 从 \(current.name) 到 \(item.name)")
            if info.location.x > 30 {
                print("向右移动")
                moveAction(.right)
            } else {
                print("向左移动")
                moveAction(.left)
            }
        } else {
            print("拖拽到自己，跳过")
        }
        
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        print("拖拽完成: \(item.name)")
        current = nil
        // 拖拽完成后进行同步
        onDropCompleted?()
        return true
    }
    
    func dropExited(info: DropInfo) {
        print("拖拽退出: \(item.name)")
        // 重置拖拽状态
        // 拖拽退出时重置状态
//        if current?.id == item.id {
//            current = nil
//        }

    }
}

#Preview {
    let sampleTask = TDMacSwiftDataListModel(
        id: 1,
        taskId: "test",
        taskContent: "测试任务",
        taskDescribe: nil,
        complete: false,
        createTime: 0,
        delete: false,
        reminderTime: 0,
        snowAdd: 0,
        snowAssess: 1,
        standbyInt1: 0,
        standbyStr1: nil,
        standbyStr2: nil,
        standbyStr3: nil,
        standbyStr4: nil,
        syncTime: 0,
        taskSort: 0,
        todoTime: 0,
        userId: 1,
        version: 1,
        status: "sync",
        isSubOpen: false,
        standbyIntColor: "",
        standbyIntName: "",
        reminderTimeString: "",
        subTaskList: [],
        attachmentList: []
    )
    
    TDTaskDetailAttachmentView(task: sampleTask, onAttachmentDeleted: {})
        .environmentObject(TDThemeManager.shared)
}
