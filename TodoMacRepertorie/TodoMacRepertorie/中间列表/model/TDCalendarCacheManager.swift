//
//  TDCalendarCacheManager.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/27.
//

import Foundation
import SwiftUI
import SwiftDate
import OSLog

// MARK: - 缓存管理器
class TDCalendarCacheManager {
    static let shared = TDCalendarCacheManager()
    private let cacheFileName = "TDCalendarCache.json"
    
    private init() {}
    
    func loadCache() throws -> [String: [TDCalendarDay]]? {
        let fileManager = FileManager.default
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw TDCalendarError.cacheLoadFailed
        }
        
        let cacheFileURL = cacheDirectory.appendingPathComponent(cacheFileName)
        
        if !fileManager.fileExists(atPath: cacheFileURL.path) {
            return nil
        }
        
        let data = try Data(contentsOf: cacheFileURL)
        return try JSONDecoder().decode([String: [TDCalendarDay]].self, from: data)
    }
    
    func saveCache(_ cache: [String: [TDCalendarDay]]) throws {
        let fileManager = FileManager.default
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw TDCalendarError.cacheSaveFailed
        }
        
        let cacheFileURL = cacheDirectory.appendingPathComponent(cacheFileName)
        let data = try JSONEncoder().encode(cache)
        try data.write(to: cacheFileURL)
    }
}
