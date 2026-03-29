//
//  TDStatusBarController.swift
//  TodoMacRepertorie
//
//  Created by Cursor AI on 2026/3/27.
//

import AppKit
import SwiftUI

final class TDStatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let contextMenu: NSMenu
    private let panelController: TDMenuBarPanelController
    
    override init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.contextMenu = NSMenu()
        self.panelController = TDMenuBarPanelController(
            content: TDMenuBarPopoverRootView(),
            size: CGSize(width: 320, height: 520)
        )
        super.init()
        
        setupContextMenu()
        
        if let button = statusItem.button {
            // 优先使用本地 Logo（用户指定：logomars_green），找不到则回退到 mars_green，再回退系统图标
            let baseImage =
                NSImage(named: "logomars_green")
                ?? NSImage(named: "mars_green")
                ?? NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "TodoMac")

            // 状态栏圆形图标（裁切成圆）
            let iconSize = NSSize(width: 18, height: 18)
            let image = baseImage.flatMap { Self.circularIcon(from: $0, size: iconSize, inset: 0.5) }
            image?.isTemplate = false
            button.image = image ?? baseImage
            button.target = self
            button.action = #selector(handleStatusItemAction(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private static func circularIcon(from image: NSImage, size: NSSize, inset: CGFloat) -> NSImage {
        let out = NSImage(size: size)
        out.lockFocus()
        defer { out.unlockFocus() }

        let rect = NSRect(origin: .zero, size: size)
        let clipRect = rect.insetBy(dx: inset, dy: inset)

        NSGraphicsContext.current?.imageInterpolation = .high
        NSBezierPath(ovalIn: clipRect).addClip()
        image.draw(in: clipRect, from: .zero, operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: nil)

        return out
    }
    
    @objc
    private func handleStatusItemAction(_ sender: Any?) {
        let eventType = NSApp.currentEvent?.type
        if eventType == .rightMouseUp {
            showContextMenu()
            return
        }
        
        togglePopover(sender)
    }
    
    private func setupContextMenu() {
        contextMenu.autoenablesItems = false
        
        let openMain = NSMenuItem(
            title: "打开主窗口",
            action: #selector(openMainWindow),
            keyEquivalent: ""
        )
        openMain.target = self
        openMain.image = NSImage(systemSymbolName: "rectangle.on.rectangle", accessibilityDescription: nil)
        
        let quit = NSMenuItem(
            title: "退出",
            action: #selector(quitApp),
            keyEquivalent: ""
        )
        quit.target = self
        quit.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        
        contextMenu.addItem(openMain)
        contextMenu.addItem(.separator())
        contextMenu.addItem(quit)
    }
    
    private func showContextMenu() {
        panelController.close()
        statusItem.menu = contextMenu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    @objc
    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        
        if let window = TDSettingsWindowTracker.shared.mainWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }
        
        if let anyWindow = NSApp.windows.first {
            anyWindow.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        panelController.toggle(relativeTo: button)
        _ = sender
    }
}
