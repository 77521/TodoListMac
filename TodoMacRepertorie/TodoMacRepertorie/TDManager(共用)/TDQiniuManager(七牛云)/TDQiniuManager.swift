//
//  TDQiniuManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import Foundation
import AppKit
import QiniuSDK
import OSLog

/// 七牛云上传管理器
@MainActor
class TDQiniuManager: ObservableObject {
    
    // MARK: - 单例
    static let shared = TDQiniuManager()
    
    private init() {}
    
    // MARK: - 上传状态
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var uploadError: Error?
    
    // MARK: - 上传附件到七牛云
    /// 上传附件到七牛云（支持文件和图片）
    /// - Parameter fileURL: 本地文件URL
    /// - Returns: 上传成功后的附件信息
    func uploadAttachment(fileURL: URL, progressCallback: ((Double) -> Void)? = nil) async throws -> UploadingAttachment {
        // 重置状态
        isUploading = true
        uploadProgress = 0.0
        uploadError = nil
        
        defer {
            isUploading = false
        }
        
        do {
            // 1. 获取文件信息
            let fileName = fileURL.lastPathComponent
            let fileSize = getFileSizeString(from: fileURL)
            let fileSuffix = fileURL.pathExtension.isEmpty ? nil : fileURL.pathExtension
            
            // 分离文件名和扩展名，避免重复
            let nameWithoutExtension = (fileName as NSString).deletingPathExtension
            
            // 2. 获取七牛云上传token
            let tokenResponse = try await getQiniuUploadToken()
            
            // 3. 生成自定义key
            let fileNameKey = generateFileNameKey(fileName: fileName)
            
            // 4. 执行上传
            let uploadedURL = try await performFileUpload(
                fileURL: fileURL,
                fileNameKey: fileNameKey,
                tokenResponse: tokenResponse,
                progressCallback: progressCallback
            )
            
            // 5. 创建上传成功的附件信息
            let attachment = UploadingAttachment(
                name: nameWithoutExtension,
                size: fileSize,
                suffix: fileSuffix,
                url: uploadedURL
            )
            
            return attachment
            
        } catch {
            uploadError = error
            throw error
        }
    }
    
    // MARK: - 私有方法
    
    /// 获取七牛云上传token
    private func getQiniuUploadToken() async throws -> TDQiniuTokenModel {
        // 使用你的TDNetworkManager获取七牛云token
        return try await TDNetworkManager.shared.request(
            endpoint: "get7nyUpToken",
            parameters: [:],
            responseType: TDQiniuTokenModel.self
        )
    }
    
    /// 生成文件名key（仿照iOS的生成规则）
    /// - Parameter fileName: 原始文件名
    /// - Returns: 生成的文件名key
    private func generateFileNameKey(fileName: String) -> String {
        let fileNameArr = fileName.components(separatedBy: ".")
        let fileExtension = fileNameArr.last ?? ""
        let userId = TDUserManager.shared.userId
        let timestamp = Int(Date().timeIntervalSince1970)
        
        return "todo_\(userId)_\(timestamp).\(fileExtension)"
    }
    
    /// 获取文件大小字符串（MB格式）
    /// - Parameter fileURL: 文件URL
    /// - Returns: 文件大小字符串
    private func getFileSizeString(from fileURL: URL) -> String {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let fileSize = fileAttributes[.size] as? Int64 {
                let sizeInMB = Double(fileSize) / (1024 * 1024)
                return String(format: "%.1fMB", sizeInMB)
            }
        } catch {
            os_log(.error, log: logger, "获取文件大小失败: \(error.localizedDescription)")
        }
        return "0MB"
    }
    
    /// 执行文件上传
    private func performFileUpload(fileURL: URL, fileNameKey: String, tokenResponse: TDQiniuTokenModel, progressCallback: ((Double) -> Void)? = nil) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            // 直接使用七牛云SDK
            let config = QNConfiguration.buildV2 { builder in
                builder?.useHttps = true
            }
            
            let uploadManager = QNUploadManager(configuration: config)
            
            // 创建上传选项，使用专门的初始化方法设置进度回调
            let option = QNUploadOption(progressHandler: { (key: String?, percent: Float) in
                print("上传进度: \(Int(percent * 100))%")
                // 更新UI进度（由于类已标记为@MainActor，直接更新即可）
                self.uploadProgress = Double(percent)
                // 调用外部进度回调
                progressCallback?(Double(percent))
            })
            
            // 调用七牛云SDK上传文件，使用自定义的key
            uploadManager?.putFile(
                fileURL.path,
                key: fileNameKey,
                token: tokenResponse.token,
                complete: { info, key, resp in
                    if let info = info, info.isOK {
                        let uploadedURL = "\(tokenResponse.urlPrefix)\(key ?? "")"
                        continuation.resume(returning: uploadedURL)
                    } else {
                        let errorMessage = info?.error?.localizedDescription ?? "上传失败"
                        let error = QiniuError.uploadFailed(errorMessage)
                        continuation.resume(throwing: error)
                    }
                },
                option: option
            )
        }
    }
    
}

// MARK: - 错误定义
enum QiniuError: LocalizedError {
    case uploadFailed(String)
    case invalidToken
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .uploadFailed(let message):
            return "上传失败: \(message)"
        case .invalidToken:
            return "无效的上传token"
        case .networkError:
            return "网络错误"
        }
    }
}

// MARK: - 七牛云Token响应模型
struct TDQiniuTokenModel: Codable {
    let token: String
    let urlPrefix: String
}

// MARK: - 上传中的附件结构体
struct UploadingAttachment: Codable, Equatable {
    let id: String
    var name: String
    let size: String
    var suffix: String?
    var url: String
    var image: NSImage?        // 不保存在本地的图片字段
    var progress: Double       // 不保存在本地的进度字段
    
    var isPhoto: Bool {
        guard let suffix = suffix else { return true }
        return ["jpg", "jpeg", "png", "gif", "heic", "webp"].contains(suffix.lowercased())
    }
    
    /// 普通初始化方法
    init(id: String = UUID().uuidString, name: String, size: String, suffix: String? = nil, url: String, image: NSImage? = nil, progress: Double = 0.0) {
        self.id = id
        self.name = name
        self.size = size
        self.suffix = suffix
        self.url = url
        self.image = image
        self.progress = progress
    }
    
    // MARK: - Codable
    private enum CodingKeys: String, CodingKey {
        case id, name, size, suffix, url
        // image 和 progress 不参与编码，因为不保存在本地
    }
    
    /// 自定义解码方法，兼容没有ID的旧数据
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 处理 ID 字段，如果没有则生成一个
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else {
            id = UUID().uuidString
        }
        
        name = try container.decode(String.self, forKey: .name)
        size = try container.decode(String.self, forKey: .size)
        suffix = try container.decodeIfPresent(String.self, forKey: .suffix)
        url = try container.decode(String.self, forKey: .url)
        
        // image 和 progress 不参与解码，使用默认值
        image = nil
        progress = 0.0
    }
    
    /// 编码方法
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(size, forKey: .size)
        try container.encodeIfPresent(suffix, forKey: .suffix)
        try container.encode(url, forKey: .url)
        // image 和 progress 不参与编码
    }
    
    /// 转换为本地附件结构体
    func toLocalAttachment() -> TDMacSwiftDataListModel.Attachment {
        return TDMacSwiftDataListModel.Attachment(
            id: self.id,
            name: self.name,
            size: self.size,
            suffix: self.suffix,
            url: self.url
        )
    }
}

// MARK: - 日志
private let logger = OSLog(subsystem: "TodoMacRepertorie", category: "QiniuManager")
