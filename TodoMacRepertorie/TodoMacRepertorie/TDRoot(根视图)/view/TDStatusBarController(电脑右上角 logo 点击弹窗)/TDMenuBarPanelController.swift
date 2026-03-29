//
//  TDMenuBarPanelController.swift
//  TodoMacRepertorie
//
//  Created by Cursor AI on 2026/3/27.
//

import AppKit
import SwiftUI

/// 无箭头的状态栏弹窗容器（替代 NSPopover），并在点击外部时自动关闭
final class TDMenuBarPanelController {
    private let panel: NSPanel
    private var globalEventMonitor: Any?
    private var ignoreOutsideClicksUntil: Date = .distantPast
    private var statusButtonFrameOnScreen: NSRect?

    init(content: some View, size: CGSize) {
        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = NSRect(origin: .zero, size: size)

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.transient, .moveToActiveSpace]
        // 依赖“点外部关闭”逻辑；保持后台点击状态栏也能显示
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.contentView = hostingView

        self.panel = panel
    }

    func toggle(relativeTo statusBarButton: NSStatusBarButton) {
        if panel.isVisible {
            close()
        } else {
            show(relativeTo: statusBarButton)
        }
    }

    func close() {
        stopMonitoring()
        panel.orderOut(nil)
    }

    private func show(relativeTo statusBarButton: NSStatusBarButton) {
        guard let buttonWindow = statusBarButton.window else { return }

        // 计算按钮在屏幕坐标中的 frame
        let buttonFrameInWindow = statusBarButton.convert(statusBarButton.bounds, to: nil)
        let buttonFrameOnScreen = buttonWindow.convertToScreen(buttonFrameInWindow)
        statusButtonFrameOnScreen = buttonFrameOnScreen

        // 防止“打开弹窗那一下点击”被全局监听捕获导致立刻关闭
        ignoreOutsideClicksUntil = Date().addingTimeInterval(0.18)

        // 默认：居中对齐在按钮下方
        var originX = buttonFrameOnScreen.midX - panel.frame.width / 2
        var originY = buttonFrameOnScreen.minY - panel.frame.height - 6

        // 约束到当前屏幕可见区域内
        let screenFrame = buttonWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        originX = min(max(originX, screenFrame.minX + 6), screenFrame.maxX - panel.frame.width - 6)
        originY = min(max(originY, screenFrame.minY + 6), screenFrame.maxY - panel.frame.height - 6)

        panel.setFrameOrigin(NSPoint(x: originX, y: originY))
        panel.orderFrontRegardless()

        // 下一轮 RunLoop 再开始监听，避免吞掉打开点击
        DispatchQueue.main.async { [weak self] in
            self?.startMonitoring()
        }
    }

    private func startMonitoring() {
        stopMonitoring()
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            guard let self else { return }
            let point = NSEvent.mouseLocation // screen coords
            // 忽略刚打开弹窗时那一下点击
            if Date() < self.ignoreOutsideClicksUntil {
                return
            }
            // 忽略点在状态栏按钮上的点击（由按钮自身 action 负责 toggle）
            if let frame = self.statusButtonFrameOnScreen, frame.contains(point) {
                return
            }
            if self.panel.frame.contains(point) {
                return
            }
            self.close()
        }
    }

    private func stopMonitoring() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
    }

    deinit {
        stopMonitoring()
    }
}

