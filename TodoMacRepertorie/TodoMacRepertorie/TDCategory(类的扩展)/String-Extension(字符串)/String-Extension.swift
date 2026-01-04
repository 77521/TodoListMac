//
//  String-Extension.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import CryptoKit
import Darwin

extension String {
    // SHA256加密
    func sha256() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        return SHA256.hash(data: data)
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
    
    // HMAC-SHA256加密（带密钥）
    func hmacSHA256(key: String) -> String {
        guard let keyData = key.data(using: .utf8),
              let messageData = self.data(using: .utf8) else { return self }
        
        let key = SymmetricKey(data: keyData)
        let signature = HMAC<SHA256>.authenticationCode(
            for: messageData,
            using: key
        )
        
        return Data(signature)
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
    
    /// 国际化处理
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func localizedFormat(_ arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }
    
    /// 将数值手机号转换为带掩码的字符串
    /// - Parameter number: 原始手机号（整型）
    /// - Returns: 掩码后的手机号，如 137****1234
    static func maskedPhoneNumber(from number: Int?) -> String? {
        guard let number, number > 0 else { return nil }
        let digits = String(number)
        guard digits.count >= 7 else { return digits }
        let prefix = digits.prefix(3)
        let suffix = digits.suffix(4)
        return "\(prefix)****\(suffix)"
    }

    /// 校验邮箱格式是否有效
    /// - Returns: 邮箱格式是否匹配
    func isValidEmailFormat() -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return range(of: pattern, options: .regularExpression) != nil
    }
    
    /// 是否为 1 开头的 11 位手机号
    var isValidPhoneNumber: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        let regex = "^1\\d{10}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: trimmed)
    }

    /// 前缀 “Todo清单：” 的国际化文案
    var tdPrefixed: String {
        "\("app_name".localized)：\(self.localized)"
    }
    /// 获取当前 mac 型号标识（用于接口 deviceType 参数），失败时返回 "Mac"
    static func currentDeviceIdentifier() -> String {
        var size: Int = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        guard size > 0 else { return "Mac" }
        var buf = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &buf, &size, nil, 0)
        if let model = String(validatingUTF8: buf) {
            return model
        }
        return "Mac"
    }

//    // MARK: - 字符串工具扩展
//    func localized(bundle: Bundle = .main, tableName: String = "Calendar") -> String {
//        return NSLocalizedString(self, tableName: tableName, bundle: bundle, value: "", comment: "")
//    }
}

// 用于 SwiftData，让布尔值可排序
extension Bool: @retroactive Comparable {
    public static func <(lhs: Self, rhs: Self) -> Bool {
        // the only true inequality is false < true
        !lhs && rhs
    }
}
