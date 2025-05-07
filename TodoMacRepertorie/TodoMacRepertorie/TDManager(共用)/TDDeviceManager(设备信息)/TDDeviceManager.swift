//
//  TDDeviceManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import IOKit
import IOKit.network
import CryptoKit

class TDDeviceManager {
    static let shared = TDDeviceManager()
    

    // 安全密钥
    private let securityKey = TDAppConfig.securityKey
    
    // 设备ID（优先使用存储的，没有则生成新的）
    var deviceId: String {
        if let savedId = UserDefaults.standard.string(forKey: "device_id") {
            return savedId
        }
        
        let newId = generateDeviceId()
        UserDefaults.standard.set(newId, forKey: "device_id")
        return newId
    }
    
    private func generateDeviceId() -> String {
        // 组合多个唯一标识符
        let components = [
            UUID().uuidString,                    // 随机UUID
            getModelIdentifier(),                 // 设备型号
            ProcessInfo.processInfo.hostName,     // 主机名
            String(Date().timeIntervalSince1970)  // 时间戳
        ]
        
        // 组合并加密
        let combined = components.joined(separator: "_")
        return combined.hmacSHA256(key: securityKey)
    }
    
    // 获取设备型号标识符
    private func getModelIdentifier() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }
    
    // 获取系统信息
    func getSystemInfo() -> [String: String] {
        return [
            "model": getModelIdentifier(),
            "name": deviceName,
            "system_version": systemVersion,
            "app_version": appVersion,
            "build_version": buildVersion,
            "hostname": ProcessInfo.processInfo.hostName
        ]
    }
    
    // 设备名称
    var deviceName: String {
        return Host.current().localizedName ?? "Unknown Device"
    }
    
    // 系统版本
    var systemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    // 应用版本
    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    // 应用构建版本
    var buildVersion: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // 获取设备型号
    private func getModelName() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }
}
