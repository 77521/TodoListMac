//
//  TDFileManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import AppKit

/// 文件管理器
class TDFileManager {
    static let shared = TDFileManager()
    
    private init() {}
    
    /// 获取基础TodoListFile文件夹路径
    /// - Returns: TodoListFile文件夹URL (Documents/TodoListFile/)
    private var baseTodoListFileFolder: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let baseFolder = documentsPath.appendingPathComponent("TodoListFile")
        
        // 确保基础文件夹存在
        if !FileManager.default.fileExists(atPath: baseFolder.path) {
            try? FileManager.default.createDirectory(at: baseFolder, withIntermediateDirectories: true)
        }
        
        return baseFolder
    }
    
    /// 根据taskId获取任务附件文件夹路径
    /// - Parameter taskId: 任务ID
    /// - Returns: 任务附件文件夹URL (Documents/TodoListFile/taskId/)
    func getTaskAttachmentFolder(for taskId: String) -> URL {
        let taskFolder = baseTodoListFileFolder.appendingPathComponent(taskId)
        
        // 确保任务文件夹存在
        if !FileManager.default.fileExists(atPath: taskFolder.path) {
            try? FileManager.default.createDirectory(at: taskFolder, withIntermediateDirectories: true)
        }
        
        return taskFolder
    }
    
    // MARK: - 文件复制功能
    
    /// 复制本地文件到任务附件文件夹
    /// - Parameters:
    ///   - sourceURL: 源文件URL
    ///   - taskId: 任务ID
    ///   - fileName: 目标文件名
    /// - Returns: 复制后的文件路径
    func copyLocalFileToTaskFolder(sourceURL: URL, taskId: String, fileName: String) async throws -> String {
        print("📁 开始复制本地文件到任务文件夹")
        print("📁 源文件: \(sourceURL.path)")
        print("📁 任务ID: \(taskId)")
        print("📁 目标文件名: \(fileName)")
        
        // 获取任务附件文件夹
        let taskFolder = getTaskAttachmentFolder(for: taskId)
        let destinationURL = taskFolder.appendingPathComponent(fileName)
        
        print("📁 目标路径: \(destinationURL.path)")
        
        // 如果目标文件已存在，先删除
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
            print("📁 删除已存在的目标文件")
        }
        
        // 复制文件
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        print("✅ 文件复制成功: \(destinationURL.path)")
        
        return destinationURL.path
    }

    // MARK: - 下载功能
    
    /// 下载文件
    /// - Parameters:
    ///   - urlString: 下载链接
    ///   - fileName: 文件名
    ///   - taskId: 任务ID（用于确定下载路径）
    /// - Returns: 本地文件路径
    func downloadFile(from urlString: String, fileName: String, taskId: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw TDFileError.invalidURL
        }
        
        // 确保文件名包含后缀
        let finalFileName = ensureFileExtension(fileName: fileName, urlString: urlString)
        
        // 获取任务附件文件夹（自动创建如果不存在）
        let taskFolder = getTaskAttachmentFolder(for: taskId)
        let localURL = taskFolder.appendingPathComponent(finalFileName)
        
        // 如果文件已存在，直接返回路径
        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL.path
        }
        
        // 下载文件
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // 检查响应状态
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TDFileError.downloadFailed
        }
        
        // 保存文件
        try data.write(to: localURL)
        
        return localURL.path
    }

    
    // MARK: - 文件操作
    
    /// 检查文件是否存在
    /// - Parameter path: 文件路径
    /// - Returns: 是否存在
    func fileExists(at path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    /// 获取文件大小
    /// - Parameter path: 文件路径
    /// - Returns: 文件大小（字节）
    func fileSize(at path: String) -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
    
    /// 删除文件
    /// - Parameter path: 文件路径
    func deleteFile(at path: String) throws {
        try FileManager.default.removeItem(atPath: path)
    }
    
    
    
    // MARK: - 文件类型判断
    
    /// 判断是否为图片文件
    /// - Parameter fileName: 文件名
    /// - Returns: 是否为图片
    func isImageFile(_ fileName: String) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "webp", "svg"]
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        return imageExtensions.contains(fileExtension)
    }
    
    /// 获取文件类型
    /// - Parameter fileName: 文件名
    /// - Returns: 文件类型
    func getFileType(_ fileName: String) -> String {
        return (fileName as NSString).pathExtension.lowercased()
    }
    
    /// 确保文件名包含正确的后缀
    /// - Parameters:
    ///   - fileName: 原始文件名
    ///   - urlString: 文件URL
    /// - Returns: 包含后缀的文件名
    private func ensureFileExtension(fileName: String, urlString: String) -> String {
        // 如果文件名已经有后缀，直接返回
        if !getFileType(fileName).isEmpty {
            return fileName
        }
        
        // 尝试从URL中获取后缀
        if let url = URL(string: urlString) {
            let urlExtension = url.pathExtension.lowercased()
            if !urlExtension.isEmpty {
                return "\(fileName).\(urlExtension)"
            }
        }
        
        // 如果都没有后缀，返回原文件名
        return fileName
    }
    
    /// 获取文件图标
    /// - Parameter fileType: 文件类型
    /// - Returns: 系统图标名称
    func getFileIcon(_ fileType: String) -> String {
        switch fileType.lowercased() {
        case "pdf":
            return "p.square.fill"
        case "doc", "docx":
            return "w.square.fill"      // Word 使用方框带字母W的图标
        case "xls", "xlsx":
            return "tablecells.fill"
        case "ppt", "pptx":
            return "p.square.fill"
        case "txt":
            return "doc.text"
        case "zip", "rar", "7z":
            return "archivebox.fill"
        case "jpg", "jpeg", "png", "gif", "bmp", "webp", "svg":
            return "photo.fill"
        default:
            return "doc.fill"
        }
    }
    
    /// 格式化文件大小显示
    /// - Parameter sizeString: 文件大小字符串（单位：MB）
    /// - Returns: 格式化后的文件大小
    func formatFileSize(_ sizeString: String) -> String {
        guard let sizeInMB = Double(sizeString) else { return "0B" }
        
        // 将MB转换为字节
        let sizeInBytes = sizeInMB * 1024 * 1024
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(sizeInBytes))
    }
    
    /// 检查附件是否已下载到本地（使用完整文件名）
    /// - Parameters:
    ///   - fullName: 完整文件名
    ///   - taskId: 任务ID
    /// - Returns: 是否已下载
    func isAttachmentDownloaded(fullName: String, taskId: String) -> Bool {
        let taskFolder = getTaskAttachmentFolder(for: taskId)
        let localPath = taskFolder.appendingPathComponent(fullName).path
        
        print("🔍 检查文件是否存在:")
        print("🔍 - 完整文件名: \(fullName)")
        print("🔍 - 任务ID: \(taskId)")
        print("🔍 - 任务文件夹: \(taskFolder.path)")
        print("🔍 - 检查路径: \(localPath)")
        print("🔍 - 文件是否存在: \(fileExists(at: localPath))")
        
        // 总是列出文件夹中的所有文件，方便调试
        print("🔍 - 文件夹中的所有文件:")
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: taskFolder.path)
            if files.isEmpty {
                print("🔍   - 文件夹为空")
            } else {
                for file in files {
                    print("🔍   - \(file)")
                    // 检查文件名是否匹配
                    if file == fullName {
                        print("🔍     ✅ 找到匹配的文件!")
                    }
                }
            }
        } catch {
            print("🔍   - 无法读取文件夹: \(error)")
        }
        
        return fileExists(at: localPath)
    }


    
    /// 在 Finder 中显示文件
    /// - Parameters:
    ///   - fullFileName: 完整文件名
    ///   - taskId: 任务ID
    func showInFinder(fullFileName: String, taskId: String) {
        let taskFolder = getTaskAttachmentFolder(for: taskId)
        let localPath = taskFolder.appendingPathComponent(fullFileName)
        
        if fileExists(at: localPath.path) {
            NSWorkspace.shared.activateFileViewerSelecting([localPath])
        } else {
            print("❌ 文件不存在，无法在 Finder 中显示: \(localPath.path)")
        }
    }
    
    /// 在浏览器中打开
    func openInBrowser(url:String) {
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        } else {
            print("❌ 无效的 URL: \(url)")
        }
    }


    ///   - url: 远程URL
    ///   - fullFileName: 完整文件名
    ///   - taskId: 任务ID
    func openAttachment(url: String, fullFileName: String, taskId: String) async {
        let taskFolder = getTaskAttachmentFolder(for: taskId)
        let localPath = taskFolder.appendingPathComponent(fullFileName).path
        
        if fileExists(at: localPath) {
            // 文件已存在，直接打开
            let fileURL = URL(fileURLWithPath: localPath)
            NSWorkspace.shared.open(fileURL)
            print("✅ 直接打开本地文件: \(fullFileName)")
        } else {
            // 文件不存在，下载后打开
            do {
                let downloadedPath = try await downloadFile(
                    from: url,
                    fileName: fullFileName,
                    taskId: taskId
                )
                let fileURL = URL(fileURLWithPath: downloadedPath)
                NSWorkspace.shared.open(fileURL)
                print("✅ 下载并打开文件: \(fullFileName)")
            } catch {
                print("❌ 下载文件失败: \(error)")
            }
        }
    }

    
    
//    /// 下载图片并生成缩略图
//    /// - Parameters:
//    ///   - urlString: 图片链接
//    ///   - fileName: 文件名
//    /// - Returns: 本地文件路径和缩略图路径
//    func downloadImage(from urlString: String, fileName: String) async throws -> (originalPath: String, thumbnailPath: String?) {
//        let originalPath = try await downloadFile(from: urlString, fileName: fileName)
//        
//        // 生成缩略图
//        let thumbnailPath = try await generateThumbnail(for: originalPath, fileName: fileName)
//        
//        return (originalPath, thumbnailPath)
//    }
//    
//    // MARK: - 缩略图生成
//    
//    /// 生成缩略图
//    /// - Parameters:
//    ///   - imagePath: 原图路径
//    ///   - fileName: 文件名
//    /// - Returns: 缩略图路径
//    private func generateThumbnail(for imagePath: String, fileName: String) async throws -> String? {
//        guard let image = NSImage(contentsOfFile: imagePath) else {
//            return nil
//        }
//        
//        // 计算缩略图尺寸
//        let thumbnailSize = NSSize(width: 200, height: 200)
//        
//        // 生成缩略图
//        let thumbnail = NSImage(size: thumbnailSize)
//        thumbnail.lockFocus()
//        
//        let aspectRatio = image.size.width / image.size.height
//        var drawRect = NSRect(origin: .zero, size: thumbnailSize)
//        
//        if aspectRatio > 1 {
//            // 宽图
//            drawRect.size.height = thumbnailSize.width / aspectRatio
//            drawRect.origin.y = (thumbnailSize.height - drawRect.size.height) / 2
//        } else {
//            // 高图
//            drawRect.size.width = thumbnailSize.height * aspectRatio
//            drawRect.origin.x = (thumbnailSize.width - drawRect.size.width) / 2
//        }
//        
//        image.draw(in: drawRect)
//        thumbnail.unlockFocus()
//        
//        // 保存缩略图
//        let thumbnailFileName = "thumb_\(fileName)"
//        let thumbnailPath = todoListFileFolder.appendingPathComponent(thumbnailFileName)
//        
//        if let tiffData = thumbnail.tiffRepresentation,
//           let bitmapRep = NSBitmapImageRep(data: tiffData),
//           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
//            try pngData.write(to: thumbnailPath)
//            return thumbnailPath.path
//        }
//        
//        return nil
//    }

}

// MARK: - 错误类型

enum TDFileError: Error, LocalizedError {
    case invalidURL
    case downloadFailed
    case fileNotFound
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .downloadFailed:
            return "下载失败"
        case .fileNotFound:
            return "文件不存在"
        case .invalidImage:
            return "无效的图片文件"
        }
    }
}
