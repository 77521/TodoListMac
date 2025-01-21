//
//  NSAppearance-Extension.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import Foundation
import AppKit

// MARK: - NSAppearance 扩展
extension NSAppearance {
    var isDarkMode: Bool {
        name == .darkAqua
    }
}
