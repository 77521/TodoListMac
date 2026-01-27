//
//  TDToastOverlayWindowManager.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/26.
//

import Foundation
import AppKit
import Combine
import SwiftUI

/// 通过独立的最上层透明 Window/Panel 承载 Toast，
/// 避免被 `.sheet` 的遮罩/背景盖住。
final class TDToastOverlayWindowManager {
    static let shared = TDToastOverlayWindowManager()

    private var cancellables = Set<AnyCancellable>()
    private var started = false

    private weak var currentTargetWindow: NSWindow?
    private var panel: NSPanel?

    private init() {}

    func start() {
        guard !started else { return }
        started = true

        setupPanelIfNeeded()
        bindCenter()
        bindWindowMoveResize()
    }

    // MARK: - Private

    private func setupPanelIfNeeded() {
        guard panel == nil else { return }

        let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient,
            .ignoresCycle
        ]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true

        let hostingView = NSHostingView(rootView: TDToastOverlayHostView())
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView

        self.panel = panel
    }

    private func bindCenter() {
        let center = TDToastCenter.shared

        Publishers.CombineLatest(center.$isPresenting, center.$isSettingPresenting)
            .receive(on: RunLoop.main)
            .sink { [weak self] isPresenting, isSettingPresenting in
                self?.updateVisibility(isPresenting: isPresenting, isSettingPresenting: isSettingPresenting)
            }
            .store(in: &cancellables)

        center.$position
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFrame()
            }
            .store(in: &cancellables)
    }

    private func bindWindowMoveResize() {
        let nc = NotificationCenter.default

        nc.publisher(for: NSWindow.didMoveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self, let window = notification.object as? NSWindow else { return }
                guard window === self.currentTargetWindow else { return }
                self.updateFrame()
            }
            .store(in: &cancellables)

        nc.publisher(for: NSWindow.didResizeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self, let window = notification.object as? NSWindow else { return }
                guard window === self.currentTargetWindow else { return }
                self.updateFrame()
            }
            .store(in: &cancellables)
    }

    private func updateVisibility(isPresenting: Bool, isSettingPresenting: Bool) {
        let shouldShow = isSettingPresenting || isPresenting
        guard shouldShow else {
            hidePanel()
            return
        }

        guard let target = resolveTargetWindow(isSettingPreferred: isSettingPresenting) ?? NSApp.keyWindow ?? NSApp.mainWindow else {
            hidePanel()
            return
        }
        if currentTargetWindow !== target {
            currentTargetWindow = target
        }

        showPanel()
        updateFrame()
    }

    private func resolveTargetWindow(isSettingPreferred: Bool) -> NSWindow? {
        if isSettingPreferred, let settings = TDSettingsWindowTracker.shared.settingsWindow {
            return settings
        }
        if let main = TDSettingsWindowTracker.shared.mainWindow {
            return main
        }
        return nil
    }

    private func showPanel() {
        guard let panel else { return }
        if !panel.isVisible {
            panel.orderFrontRegardless()
        } else {
            panel.orderFront(nil)
        }
    }

    private func hidePanel() {
        panel?.orderOut(nil)
    }

    private func updateFrame() {
        guard let panel, let target = currentTargetWindow else { return }
        let frame = target.frame

        // 跟随目标窗口位置/尺寸，确保 Toast 永远覆盖在该窗口最上层（包括 sheet）。
        panel.setFrame(frame, display: true)
    }
}

private struct TDToastOverlayHostView: View {
    @ObservedObject private var toastCenter = TDToastCenter.shared

    private enum ActiveTarget {
        case settings
        case main
    }

    private var activeTarget: ActiveTarget {
        toastCenter.isSettingPresenting ? .settings : .main
    }

    private var activeIsPresenting: Binding<Bool> {
        Binding(
            get: {
                switch activeTarget {
                case .settings: return toastCenter.isSettingPresenting
                case .main: return toastCenter.isPresenting
                }
            },
            set: { newValue in
                switch activeTarget {
                case .settings: toastCenter.isSettingPresenting = newValue
                case .main: toastCenter.isPresenting = newValue
                }
            }
        )
    }

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .tdToastBottom(
                isPresenting: Binding(
                    get: { activeIsPresenting.wrappedValue && toastCenter.position == .bottom },
                    set: { activeIsPresenting.wrappedValue = $0 }
                ),
                message: toastCenter.message,
                type: toastCenter.type
            )
            .tdToastTop(
                isPresenting: Binding(
                    get: { activeIsPresenting.wrappedValue && toastCenter.position == .top },
                    set: { activeIsPresenting.wrappedValue = $0 }
                ),
                message: toastCenter.message,
                type: toastCenter.type
            )
            .tdToastCenter(
                isPresenting: Binding(
                    get: { activeIsPresenting.wrappedValue && toastCenter.position == .center },
                    set: { activeIsPresenting.wrappedValue = $0 }
                ),
                message: toastCenter.message,
                type: toastCenter.type
            )
    }
}
