//
//  Button-Extension.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/9/25.
//

import SwiftUI

// MARK: - Button 扩展
extension Button {
    /// 鼠标悬停时显示手指光标的按钮样式
    /// - Returns: 带有手指光标效果的按钮
    func pointingHandCursor() -> some View {
        self.onHover { isHovering in
            if isHovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

