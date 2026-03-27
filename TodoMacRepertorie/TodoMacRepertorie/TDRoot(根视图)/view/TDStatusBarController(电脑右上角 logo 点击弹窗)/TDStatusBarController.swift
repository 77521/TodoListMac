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
    private let popover: NSPopover
    private let contextMenu: NSMenu
    
    override init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.popover = NSPopover()
        self.contextMenu = NSMenu()
        super.init()
        
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 520)
        popover.contentViewController = NSHostingController(rootView: TDMenuBarPopoverView())
        
        setupContextMenu()
        
        if let button = statusItem.button {
            let image = NSImage(
                systemSymbolName: "checkmark.circle.fill",
                accessibilityDescription: "TodoMac"
            )
            image?.isTemplate = true
            button.image = image
            button.target = self
            button.action = #selector(handleStatusItemAction(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
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
        popover.performClose(nil)
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
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}

private struct TDMenuBarPopoverView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TodoMac 弹窗（占位）")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button("退出") { NSApp.terminate(nil) }
                    .buttonStyle(.borderless)
            }
            
            Divider()
            
            Text("这里先随便放一段文案，后续再替换成你图 1 的日历/任务内容。")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            Text("提示：左键点击右上角图标打开/关闭；右键/双指点按弹出菜单。")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(width: 360, height: 520)
    }
}

