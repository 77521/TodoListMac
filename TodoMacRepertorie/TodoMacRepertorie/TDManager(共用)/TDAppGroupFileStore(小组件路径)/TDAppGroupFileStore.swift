//
//  TDAppGroupFileStore.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/2/26.
//

import Foundation

enum TDAppGroupFileStore {
    static func containerURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: TDAppConfig.appGroupId)
    }

    /// relativePath 例：`td_shared_user.json` 或 `Shared/td_shared_user.json`
    static func fileURL(relativePath: String) -> URL? {
        guard let groupUrl = containerURL() else { return nil }
        return groupUrl.appendingPathComponent(relativePath)
    }

    private static func bestEffortSetProtectionNone(fileURL: URL) {
#if os(iOS) || os(tvOS) || os(watchOS) || os(macOS)
        // 避免某些系统环境下 Widget 读文件报 257（Operation not permitted）
        try? FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: fileURL.path)
#endif
    }

    @discardableResult
    static func writeString(relativePath: String, content: String) -> Bool {
        guard let url = fileURL(relativePath: relativePath) else { return false }
        let folder = url.deletingLastPathComponent()
        // 确保父目录存在（例如 Shared/）；否则写入会失败
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            bestEffortSetProtectionNone(fileURL: url)
            return true
        } catch {
            return false
        }
    }

    static func readString(relativePath: String) -> String? {
        guard let url = fileURL(relativePath: relativePath) else { return nil }
        guard let data = FileManager.default.contents(atPath: url.path) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func remove(relativePath: String) {
        guard let url = fileURL(relativePath: relativePath) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
