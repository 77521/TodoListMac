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
    
    /// 国际化处理（跟随设置内语言选择，而不是系统语言）
    var localized: String {
        // 从设置管理器获取当前选择的语言
        let lang = TDSettingManager.shared.language
        let code: String?
        switch lang {
        case .system:
            // 仅支持中/英，系统若非中/英则回落中文
            let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
            if preferred.contains("en") {
                code = "en"
            } else if preferred.contains("zh") {
                code = "zh-Hans"
            } else {
                code = "zh-Hans"
            }
        case .chinese:
            code = "zh-Hans"
        case .english:
            code = "en"
        }
        // 如果有指定语言码，则加载对应 lproj bundle
        if let code,
           let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: self, value: nil, table: nil)
        }
        // 默认走系统语言
        return NSLocalizedString(self, comment: "")
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
    
    
    // MARK: - 输入框文本清洗（通用）
    
    /// 任务输入框标题清洗（用于“回车创建事件”等场景）
    ///
    /// 规则（按你的描述）：
    /// - **开头**：无论是空格还是换行，全部去掉
    /// - **结尾**：
    ///   - 如果结尾是「标签 token」（以 `#` 开头，且后面紧跟 1+ 个非空白字符），并且用户在其后输入了空格/换行：
    ///     - 保留 **一个** 空格（表示标签结束，符合标签提取规则）
    ///     - 多余空格/换行全部去掉
    ///   - 如果结尾不是标签 token：结尾所有空格/换行全部去掉
    ///
    /// 备注：
    /// - 标签识别只看最后一个 token（按空白分割），满足 `#` + 非空白 即视为标签
    func tdSanitizedTaskInputTitle() -> String {
        // 1) 去掉开头空白（空格/制表/换行等）
        let leadingTrimmed = tdTrimmingLeadingWhitespacesAndNewlines()
        guard !leadingTrimmed.isEmpty else { return "" }

        // 2) 记录“用户是否在末尾输入过空白”
        let hasTrailingWhitespace = leadingTrimmed.unicodeScalars.last.map { CharacterSet.whitespacesAndNewlines.contains($0) } ?? false

        // 3) 去掉结尾空白（先全部去掉，后面再按规则补回 1 个空格）
        let core = leadingTrimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !core.isEmpty else { return "" }

        // 4) 如果末尾是标签 token 且用户确实输入过末尾空白：补回 1 个空格
        if hasTrailingWhitespace && core.tdLastTokenIsHashtagToken() {
            return core + " "
        }
        return core
    }

    /// 去掉字符串开头的空白与换行（只处理开头，不动结尾）
    private func tdTrimmingLeadingWhitespacesAndNewlines() -> String {
        var s = self
        while let first = s.unicodeScalars.first, CharacterSet.whitespacesAndNewlines.contains(first) {
            s.removeFirst()
        }
        return s
    }

    /// 判断当前字符串的“最后一个 token”是否是标签 token（#xxx）
    /// - token：按空白分割后的最后一段
    /// - 标签：以 `#` 开头，且长度 > 1
    private func tdLastTokenIsHashtagToken() -> Bool {
        // split(whereSeparator:) 会自动忽略连续空白
        let parts = self.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        guard let last = parts.last else { return false }
        guard let first = last.first, first == "#" else { return false }
        return last.count > 1
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
