//
//  TDAttachmentButtonView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import SwiftUI
import SwiftData
import AppKit

/// 附件按钮组件
/// 用于显示附件状态和上传进度
struct TDAttachmentButtonView: View {
    
    // MARK: - 数据绑定
    @Bindable var task: TDMacSwiftDataListModel  // 当前任务数据（可绑定修改）
    @EnvironmentObject private var themeManager: TDThemeManager  // 主题管理器
    @StateObject private var qiniuManager = TDQiniuManager.shared  // 七牛云管理器
    @Environment(\.modelContext) private var modelContext  // SwiftData 数据上下文
    
    // MARK: - 状态变量
    @State private var showDocumentPicker = false  // 控制文件选择器显示
    
    // MARK: - 回调
    let onAttachmentSet: () -> Void  // 附件设置完成回调（仅用于同步数据）
    let onShowToast: (String) -> Void  // 显示Toast回调
    
    // MARK: - 主视图
    var body: some View {
        Button(action: {
            handleAttachmentButtonClick()
        }) {
            HStack(spacing: 0) {
                // 文档图标
                Image(systemName: qiniuManager.isUploading ? "arrow.up.circle" : "text.document")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(qiniuManager.isUploading ? themeManager.color(level: 6) :
                                        (task.hasAttachment ? themeManager.color(level: 5) : themeManager.subtaskTextColor))
                    .padding(.all,8)
                    .background(
                        Circle()
                            .fill(themeManager.secondaryBackgroundColor)
                    )
                    .rotationEffect(.degrees(qiniuManager.isUploading ? 360 : 0))
                    .animation(qiniuManager.isUploading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: qiniuManager.isUploading)
                
                if qiniuManager.isUploading {
                    // 上传进度文字
                    Text("上传中 \(Int(qiniuManager.uploadProgress * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.color(level: 6))
                } else if task.hasAttachment {
                    // 附件数量文字（如：附件 1）
                    Text("附件 \(task.attachmentList.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.color(level: 5))
                }
            }
            .padding(.vertical,0)
            .padding(.leading,0)
            .padding(.trailing,(task.hasAttachment || qiniuManager.isUploading) ? 8 : 0)
            .background(
                RoundedRectangle(cornerRadius: 17)
                    .fill((task.hasAttachment || qiniuManager.isUploading) ? themeManager.secondaryBackgroundColor : Color.clear)
            )
            .transition(.asymmetric(
                insertion: .scale(scale: 0.1, anchor: .leading).combined(with: .opacity),
                removal: .scale(scale: 0.1, anchor: .leading).combined(with: .opacity)
            ))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(qiniuManager.isUploading)  // 上传时禁用按钮
        .help(qiniuManager.isUploading ? "正在上传文件..." : "选择附件")  // 鼠标悬停提示
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            handleDocumentSelection(result: result)
        }
    }
    
    // MARK: - 私有方法
    
    /// 处理附件按钮点击
    private func handleAttachmentButtonClick() {
        // 检查附件数量限制（最多4个）
        if task.attachmentList.count >= 4 {
            onShowToast("最多添加4个附件")
            
            return
        }
        
        // 显示文件选择器
        showDocumentPicker = true
    }
    
    /// 处理文档选择结果
    /// - Parameter result: 文件选择结果
    private func handleDocumentSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            // 成功选择文件
            if !urls.isEmpty {
                handleSelectedFiles(urls: urls)
            }
        case .failure(let error):
            // 选择文件失败
            onShowToast("选择文件失败")
            
        }
    }
    
    /// 处理选中的文件
    /// - Parameter urls: 选中的文件URL数组
    private func handleSelectedFiles(urls: [URL]) {
        // 检查附件数量限制（最多4个）
        let remainingSlots = 4 - task.attachmentList.count
        let filesToProcess = Array(urls.prefix(remainingSlots))
        
        
        if filesToProcess.count < urls.count {
            onShowToast("最多只能添加 \(remainingSlots) 个附件")
        }
        
        // 异步上传文件
        Task {
            await uploadFilesToQiniu(files: filesToProcess)
        }
    }
    
    /// 上传文件到七牛云
    /// - Parameter files: 要上传的文件URL数组
    @MainActor
    private func uploadFilesToQiniu(files: [URL]) async {
        
        for (index, fileURL) in files.enumerated() {
            do {
                
                // 再次检查文件是否存在和可读
                let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
                
                if !fileExists {
                    continue
                }
                
                // 对于通过fileImporter选择的文件，需要先获取安全作用域访问权限
                let hasAccess = fileURL.startAccessingSecurityScopedResource()
                
                defer {
                    // 确保在方法结束时释放访问权限
                    fileURL.stopAccessingSecurityScopedResource()
                }
                
                // 检查文件是否可读
                let isReadable = FileManager.default.isReadableFile(atPath: fileURL.path)
                
                if !isReadable {
                    
                    // 尝试获取更详细的权限信息
                    do {
                        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                        
                        // 检查文件权限
                        if let permissions = attributes[.posixPermissions] as? NSNumber {
                            let permissionString = String(permissions.intValue, radix: 8)
                        }
                        
                        // 尝试通过URL直接访问文件
                        let resourceValues = try fileURL.resourceValues(forKeys: [.isReadableKey, .fileSizeKey])
                        
                    } catch {
                    }
                    
                    // 尝试直接读取文件内容来测试权限
                    do {
                        let _ = try Data(contentsOf: fileURL)
                    } catch {
                        onShowToast("文件 \(fileURL.lastPathComponent) 不可读，请检查文件权限")
                        
                        continue
                    }
                }
                
                
                print("📤 调用七牛云上传方法...")
                
                // 1. 先复制文件到任务附件文件夹
                let fileName = fileURL.lastPathComponent
                let localFilePath = try await TDFileManager.shared.copyLocalFileToTaskFolder(
                    sourceURL: fileURL,
                    taskId: task.taskId,
                    fileName: fileName
                )
                print("📁 文件已复制到本地: \(localFilePath)")
                
                // 2. 上传附件到七牛云，带进度回调
                let uploadingAttachment = try await qiniuManager.uploadAttachment(fileURL: fileURL) { progress in
                    // 更新上传进度显示
                    _ = (Double(index) + progress) / Double(files.count)
                }
                
                // 3. 转换为本地附件对象，使用本地文件路径
                let attachment = uploadingAttachment.toLocalAttachment()
                
                // 4. 添加到任务附件列表
                task.attachmentList.append(attachment)
                task.standbyStr4 = task.generateAttachmentListString()
                
                
            } catch {
                onShowToast("文件 \(fileURL.lastPathComponent) 上传失败")
                
            }
        }
        if !files.isEmpty {
            onShowToast("附件上传完成")
            // 调用回调通知父组件同步数据
            onAttachmentSet()
        } else {
        }
    }
}

// MARK: - 预览
#Preview {
    // 创建一个示例任务用于预览
    let sampleTask = TDMacSwiftDataListModel(
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
    )
    
    TDAttachmentButtonView(
        task: sampleTask
    ) {
        print("附件设置完成，需要同步数据")
    }
    onShowToast: { message in
        print("显示Toast: \(message)")
    }
    .environmentObject(TDThemeManager.shared)
    .environmentObject(TDQiniuManager.shared)
}
