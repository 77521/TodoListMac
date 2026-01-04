//
//  View-Extension.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI

// Views/BlurView.swift
struct BlurView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
// MARK: - View 扩展 - 通用手指光标
extension View {
    /// 鼠标悬停时显示手指光标
    /// - Returns: 带有手指光标效果的视图
    func pointingHandCursor() -> some View {
        self.onHover { isHovering in
            if isHovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
    
    /// 鼠标悬停时显示手指光标（带条件）
    /// - Parameter condition: 是否启用手指光标效果
    /// - Returns: 带有条件手指光标效果的视图
    func pointingHandCursor(when condition: Bool) -> some View {
        self.onHover { isHovering in
            if condition && isHovering {
                NSCursor.pointingHand.push()
            } else if condition {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - 抖动辅助
extension Binding where Value == Bool {
    /// 触发一次抖动效果（用于错误提示）
    func triggerShake() {
        wrappedValue.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            wrappedValue.toggle()
        }
    }
}
