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
    
    // MARK: - 文件夹路径
    
    /// 获取 TodoListFile 文件夹路径
    var todoListFileFolder: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let todoListFolder = documentsPath.appendingPathComponent("TodoListFile")
        
        // 确保文件夹存在
        if !FileManager.default.fileExists(atPath: todoListFolder.path) {
            try? FileManager.default.createDirectory(at: todoListFolder, withIntermediateDirectories: true)
        }
        
        return todoListFolder
    }
    
    // MARK: - 下载功能
    
    /// 下载文件
    /// - Parameters:
    ///   - urlString: 下载链接
    ///   - fileName: 文件名
    /// - Returns: 本地文件路径
    func downloadFile(from urlString: String, fileName: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw TDFileError.invalidURL
        }
        
        // 确保文件名包含后缀
        let finalFileName = ensureFileExtension(fileName: fileName, urlString: urlString)
        
        // 创建本地文件路径
        let localURL = todoListFileFolder.appendingPathComponent(finalFileName)
        
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
    
    /// 下载图片并生成缩略图
    /// - Parameters:
    ///   - urlString: 图片链接
    ///   - fileName: 文件名
    /// - Returns: 本地文件路径和缩略图路径
    func downloadImage(from urlString: String, fileName: String) async throws -> (originalPath: String, thumbnailPath: String?) {
        let originalPath = try await downloadFile(from: urlString, fileName: fileName)
        
        // 生成缩略图
        let thumbnailPath = try await generateThumbnail(for: originalPath, fileName: fileName)
        
        return (originalPath, thumbnailPath)
    }
    
    // MARK: - 缩略图生成
    
    /// 生成缩略图
    /// - Parameters:
    ///   - imagePath: 原图路径
    ///   - fileName: 文件名
    /// - Returns: 缩略图路径
    private func generateThumbnail(for imagePath: String, fileName: String) async throws -> String? {
        guard let image = NSImage(contentsOfFile: imagePath) else {
            return nil
        }
        
        // 计算缩略图尺寸
        let thumbnailSize = NSSize(width: 200, height: 200)
        
        // 生成缩略图
        let thumbnail = NSImage(size: thumbnailSize)
        thumbnail.lockFocus()
        
        let aspectRatio = image.size.width / image.size.height
        var drawRect = NSRect(origin: .zero, size: thumbnailSize)
        
        if aspectRatio > 1 {
            // 宽图
            drawRect.size.height = thumbnailSize.width / aspectRatio
            drawRect.origin.y = (thumbnailSize.height - drawRect.size.height) / 2
        } else {
            // 高图
            drawRect.size.width = thumbnailSize.height * aspectRatio
            drawRect.origin.x = (thumbnailSize.width - drawRect.size.width) / 2
        }
        
        image.draw(in: drawRect)
        thumbnail.unlockFocus()
        
        // 保存缩略图
        let thumbnailFileName = "thumb_\(fileName)"
        let thumbnailPath = todoListFileFolder.appendingPathComponent(thumbnailFileName)
        
        if let tiffData = thumbnail.tiffRepresentation,
           let bitmapRep = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            try pngData.write(to: thumbnailPath)
            return thumbnailPath.path
        }
        
        return nil
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
    
    /// 获取文件夹中的所有文件
    /// - Returns: 文件路径数组
    func getAllFiles() -> [String] {
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: todoListFileFolder.path)
            return files.map { todoListFileFolder.appendingPathComponent($0).path }
        } catch {
            return []
        }
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
    
    /// 检查附件是否已下载到本地
    /// - Parameters:
    ///   - name: 文件名
    ///   - suffix: 文件后缀
    /// - Returns: 是否已下载
    func isAttachmentDownloaded(name: String, suffix: String?) -> Bool {
        let fullFileName = getFullFileName(name: name, suffix: suffix)
        let localPath = todoListFileFolder.appendingPathComponent(fullFileName).path
        return fileExists(at: localPath)
    }

    /// 获取完整的文件名（name + suffix）
    /// - Parameters:
    ///   - name: 文件名
    ///   - suffix: 文件后缀
    /// - Returns: 完整的文件名
    func getFullFileName(name: String, suffix: String?) -> String {
        if let suffix = suffix, !suffix.isEmpty {
            return "\(name).\(suffix)"
        } else {
            return name
        }
    }
    
    /// 在 Finder 中显示文件
    func showInFinder(fullFileName:String) {
        let localPath = TDFileManager.shared.todoListFileFolder.appendingPathComponent(fullFileName)
        
        if TDFileManager.shared.fileExists(at: localPath.path) {
            NSWorkspace.shared.activateFileViewerSelecting([localPath])
        } else {
            print("❌ 文件不存在，无法在 Finder 中显示")
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
