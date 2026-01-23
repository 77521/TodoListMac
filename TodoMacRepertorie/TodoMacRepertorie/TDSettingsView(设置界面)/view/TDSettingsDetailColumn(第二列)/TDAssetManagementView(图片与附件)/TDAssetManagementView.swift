//
//  TDAssetManagementView.swift
//  TodoMacRepertorie
//
//  Created by Cursor on 2026/1/19.
//

import SwiftUI
import SwiftData
import AppKit

/// 设置 - 图片与文件管理界面（segmented 切换 + 真实数据）
struct TDAssetManagementView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - 布局
    private let photoGridItem = GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 12, alignment: .top)
    
    // MARK: - 状态
    enum AssetTab: String, CaseIterable {
        case photos, files
    }
    @State private var currentTab: AssetTab = .photos                 // 当前分段
    @State private var photoTasks: [TDMacSwiftDataListModel] = []     // 含图片附件
    @State private var fileTasks: [TDMacSwiftDataListModel] = []      // 含非图片附件
    @State private var isLoading: Bool = false                        // 加载状态
    @State private var errorMessage: String? = nil                    // 错误信息
    @State private var filterDuplicates: Bool = false                 // 过滤重复项（默认未选中）
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部标题与描述
            headerSection
            
            // 分段控制 + 过滤按钮
            HStack(spacing: 12) {
                Picker("", selection: $currentTab) {
                    Text("settings.asset.tab.photos".localized).tag(AssetTab.photos)
                    Text("settings.asset.tab.files".localized).tag(AssetTab.files)
                }
                .pickerStyle(.segmented)
                .frame(minWidth: 100, maxWidth: 380, alignment: .leading)

                Spacer()
                
                Toggle(isOn: $filterDuplicates) {
                    Text("settings.asset.filter.duplicates".localized)
                        .foregroundColor(themeManager.titleTextColor)
                }
                .toggleStyle(ThemedSwitchToggleStyle(onColor: themeManager.color(level: 5)))
                .onChange(of: filterDuplicates) { _, _ in loadData() }
            }
            .padding(.top, 4)
            
            // 内容区域
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if currentTab == .photos {
                        photoContent
                    } else {
                        fileContent
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
            .background(themeManager.secondaryBackgroundColor.opacity(0.001))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
        .onAppear { loadData() }
    }
    
    // MARK: - 图片内容（九宫格）
    private var photoContent: some View {
        contentWrapper(tasks: photoTasks, emptyTextKey: "settings.asset.empty.photos") {
            LazyVGrid(columns: [photoGridItem], spacing: 12) {
                ForEach(photoTasks) { task in
                    if let att = firstPhotoAttachment(in: task) {
                        photoCell(task: task, attachment: att)
                    }
                }
            }
        }
    }
    
    private func photoCell(task: TDMacSwiftDataListModel, attachment: TDMacSwiftDataListModel.Attachment) -> some View {
        let fullName = attachment.getFullFileName()
        let isDownloaded = TDFileManager.shared.isAttachmentDownloaded(fullName: fullName, taskId: task.taskId)
        let localURL = localFileURL(fullName: fullName, taskId: task.taskId)
        let previewURL: URL? = {
            if isDownloaded, let url = localURL { return url }
            return URL(string: attachment.url)
        }()
        
       return VStack(alignment: .leading, spacing: 8) {
            // 预览（用 AsyncImage 显示远程/本地）
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(themeManager.color(level: 1))
                if let url = previewURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Image(systemName: "photo")
                                .font(.system(size: 28, weight: .light))
                                .foregroundColor(themeManager.color(level: 6))
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(themeManager.color(level: 6))
                }
            }
            .frame(height: 120)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            Text(attachment.getFullFileName())
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.titleTextColor)
                .lineLimit(2)
        }
        .padding(12)
        .background(themeManager.secondaryBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .contextMenu {
            if isDownloaded {
                Button("settings.asset.open.local".localized) {
                    openLocalFile(fullName: fullName, taskId: task.taskId, remoteURL: attachment.url)
                }
                Button("settings.asset.open.browser".localized) {
                    openInBrowser(attachment)
                }
                Button("settings.asset.show.finder".localized) {
                    TDFileManager.shared.showInFinder(fullFileName: fullName, taskId: task.taskId)
                }
                Button("settings.asset.view.url".localized) {
                    openInBrowser(attachment)
                }
            } else {
                Button("settings.asset.open.browser".localized) {
                    openInBrowser(attachment)
                }
                Button("settings.asset.download".localized) {
                    Task { await downloadAttachment(attachment, taskId: task.taskId) }
                }
            }
        }
    }
    
    // MARK: - 文件内容（列表）
    private var fileContent: some View {
        contentWrapper(tasks: fileTasks, emptyTextKey: "settings.asset.empty.files") {
            VStack(spacing: 10) {
                ForEach(fileTasks) { task in
                    if let att = firstFileAttachment(in: task) {
                        fileRow(task: task, attachment: att)
                            .padding(.horizontal, 4)
                    }
                }
            }
        }
    }
    
    private func fileRow(task: TDMacSwiftDataListModel, attachment: TDMacSwiftDataListModel.Attachment) -> some View {
        let fullName = attachment.getFullFileName()
        let fileType = TDFileManager.shared.getFileType(fullName)
        let icon = TDFileManager.shared.getFileIcon(fileType)
        let isDownloaded = TDFileManager.shared.isAttachmentDownloaded(fullName: fullName, taskId: task.taskId)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(themeManager.color(level: 6))
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(fullName)
                        .foregroundColor(themeManager.titleTextColor)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(2)
                    
                    HStack(spacing: 10) {
                        Text(TDFileManager.shared.formatFileSize(attachment.size))
                            .foregroundColor(themeManager.descriptionTextColor)
                            .font(.system(size: 12))
                        Text(formatDate(task.createTime))
                            .foregroundColor(themeManager.descriptionTextColor)
                            .font(.system(size: 12))
                    }
                }
                
                Spacer()
            }
            
        }
        .padding(12)
        .background(themeManager.secondaryBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        // 右键菜单：根据下载状态切换项
        .contextMenu {
            if isDownloaded {
                Button("settings.asset.open.file".localized) {
                    openLocalFile(fullName: fullName, taskId: task.taskId, remoteURL: attachment.url)
                }
                Button("settings.asset.open.browser".localized) {
                    openInBrowser(attachment)
                }
                Button("settings.asset.show.finder".localized) {
                    TDFileManager.shared.showInFinder(fullFileName: fullName, taskId: task.taskId)
                }
            } else {
                Button("settings.asset.open.browser".localized) {
                    openInBrowser(attachment)
                }
                Button("settings.asset.download".localized) {
                    Task { await downloadAttachment(attachment, taskId: task.taskId) }
                }
            }
        }
    }
    
    // MARK: - 包裹器（加载/错误/空态/内容）
    private func contentWrapper<T: View>(
        tasks: [TDMacSwiftDataListModel],
        emptyTextKey: String,
        @ViewBuilder content: @escaping () -> T
    ) -> some View {
        Group {
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("common.loading".localized)
                        .foregroundColor(themeManager.descriptionTextColor)
                        .font(.system(size: 13))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else if tasks.isEmpty {
                Text(emptyTextKey.localized)
                    .foregroundColor(themeManager.descriptionTextColor)
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                content()
            }
        }
    }
    /// 顶部说明区域：标题 + 描述
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("settings.asset_management.page.title".localized)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(themeManager.titleTextColor)
            
            Text("settings.asset_management.page.subtitle".localized)
                .font(.system(size: 13))
                .foregroundColor(themeManager.descriptionTextColor)
        }
    }

    // MARK: - 数据加载
    private func loadData() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let (photos, files) = try await TDQueryConditionManager.shared.getTasksWithAttachments(
                    filterDuplicates: filterDuplicates,
                    context: modelContext
                )
                await MainActor.run {
                    self.photoTasks = photos
                    self.fileTasks = files
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - 附件工具
    private func firstPhotoAttachment(in task: TDMacSwiftDataListModel) -> TDMacSwiftDataListModel.Attachment? {
        task.attachmentList.first { $0.isPhoto }
    }
    
    private func firstFileAttachment(in task: TDMacSwiftDataListModel) -> TDMacSwiftDataListModel.Attachment? {
        task.attachmentList.first { !$0.isPhoto }
    }
    
    /// 判断是否本地文件
    private func isLocalFile(_ urlString: String) -> Bool {
        if let url = URL(string: urlString), url.isFileURL {
            return FileManager.default.fileExists(atPath: url.path)
        }
        return false
    }
    
    /// 打开附件（系统处理）
    private func openAttachment(_ attachment: TDMacSwiftDataListModel.Attachment) {
        guard let url = URL(string: attachment.url) else { return }
        NSWorkspace.shared.open(url)
    }
    
    /// 浏览器打开
    private func openInBrowser(_ attachment: TDMacSwiftDataListModel.Attachment) {
        guard let url = URL(string: attachment.url) else { return }
        NSWorkspace.shared.open(url)
    }
    
    /// 打开本地文件（若不存在则回退到浏览器）
    private func openLocalFile(fullName: String, taskId: String, remoteURL: String) {
        let folder = TDFileManager.shared.getTaskAttachmentFolder(for: taskId)
        let localURL = folder.appendingPathComponent(fullName)
        if FileManager.default.fileExists(atPath: localURL.path) {
            NSWorkspace.shared.open(localURL)
        } else if let url = URL(string: remoteURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// 下载附件到本地
    private func downloadAttachment(_ attachment: TDMacSwiftDataListModel.Attachment, taskId: String) async {
        do {
            _ = try await TDFileManager.shared.downloadFile(
                from: attachment.url,
                fileName: attachment.getFullFileName(),
                taskId: taskId
            )
            // 下载后刷新状态
            await MainActor.run {
                loadData()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    /// 格式化日期（使用 createTime 毫秒）
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.M.d"
        return formatter.string(from: date)
    }
    
    /// 获取本地文件 URL
    private func localFileURL(fullName: String, taskId: String) -> URL? {
        let folder = TDFileManager.shared.getTaskAttachmentFolder(for: taskId)
        let local = folder.appendingPathComponent(fullName)
        return FileManager.default.fileExists(atPath: local.path) ? local : nil
    }
}

#Preview {
    TDAssetManagementView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
        .environmentObject(TDSettingsSidebarStore.shared)
        .modelContainer(for: [TDMacSwiftDataListModel.self], inMemory: true)
}
