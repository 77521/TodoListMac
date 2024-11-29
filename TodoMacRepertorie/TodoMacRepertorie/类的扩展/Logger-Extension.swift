//
//  Logger-Extension.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/27.
//

import Foundation
import OSLog

// MARK: - 日志系统
extension Logger {
    static let calendar = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Calendar")
    
    // MARK: - 错误日志
    func logError(_ error: TDCalendarError, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let errorInfo = """
            Error: \(error.localizedDescription)
            Code: \(error.errorCode)
            Reason: \(error.failureReason ?? "Unknown")
            Recovery: \(error.recoverySuggestion ?? "None")
            Location: \(fileName):\(line)
            Function: \(function)
            """
        
        self.error("\(errorInfo, privacy: .public)")
    }
    
    // MARK: - 警告日志
    func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        self.warning("""
            Warning: \(message, privacy: .public)
            Location: \(fileName):\(line)
            Function: \(function)
            """)
    }
    
    // MARK: - 信息日志
    func logInfo(_ message: String) {
        self.info("\(message, privacy: .public)")
    }
    
    // MARK: - 调试日志
    func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        self.debug("""
            Debug: \(message, privacy: .public)
            Location: \(fileName):\(line)
            Function: \(function)
            """)
        #endif
    }
    
    // MARK: - 性能日志
    func logPerformance(_ operation: String, duration: TimeInterval) {
        self.info("Performance: \(operation, privacy: .public) took \(duration, privacy: .public) seconds")
    }
}
