//
//  View-Extension.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/6.
//

import Foundation
import SwiftUI

// Extensions/View+Window.swift
extension View {
    func customWindow(
        title: String = "",
        isResizable: Bool = true,
        showTitleBar: Bool = true
    ) -> some View {
        background(WindowAccessor { window in
            // 设置窗口标题
            window.title = title
            
            // 设置标题栏样式
            window.titlebarAppearsTransparent = !showTitleBar
            window.titleVisibility = showTitleBar ? .visible : .hidden
            
            // 设置窗口按钮
            if let closeButton = window.standardWindowButton(.closeButton) {
                closeButton.isHidden = false
            }
            
            if let minButton = window.standardWindowButton(.miniaturizeButton) {
                minButton.isHidden = !isResizable
            }
            
            if let zoomButton = window.standardWindowButton(.zoomButton) {
                zoomButton.isHidden = !isResizable
            }
            
            // 设置窗口样式掩码
            var styleMask = window.styleMask
            if isResizable {
                styleMask.insert(.resizable)
            } else {
                styleMask.remove(.resizable)
            }
            window.styleMask = styleMask
        })
    }
}


// Utilities/WindowAccessor.swift
struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
                
                // 设置窗口代理
                window.delegate = context.coordinator
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    // 创建协调器
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // 窗口代理协调器
    class Coordinator: NSObject, NSWindowDelegate {
        func windowDidResize(_ notification: Notification) {
            guard let window = notification.object as? NSWindow else { return }
            // 处理窗口大小变化
        }
    }
}


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

