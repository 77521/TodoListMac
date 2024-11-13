//
//  String-Extension.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/6.
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
}
