//
//  String-Extension.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import CryptoKit

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
    
//    // MARK: - 字符串工具扩展
//    func localized(bundle: Bundle = .main, tableName: String = "Calendar") -> String {
//        return NSLocalizedString(self, tableName: tableName, bundle: bundle, value: "", comment: "")
//    }
}
