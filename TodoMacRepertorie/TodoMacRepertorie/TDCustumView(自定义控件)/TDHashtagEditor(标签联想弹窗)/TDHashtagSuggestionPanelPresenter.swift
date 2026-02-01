//
//  TDHashtagSuggestionPanelPresenter.swift
//  TodoMacRepertorie
//
//  Window 级标签联想弹窗（NSPanel，不抢焦点、不被裁剪）
//
//  Created by 孬孬 on 2026/2/1.
//

import SwiftUI
import AppKit

/// 用 NSPanel 把联想弹窗挂到 window 最外层，避免被 ScrollView/容器裁剪
struct TDHashtagSuggestionPanelPresenter: NSViewRepresentable {
    @Binding var isPresented: Bool
    var anchorScreenRect: CGRect
    var tags: [String]
    @Binding var selectedIndex: Int
    var onSelectIndex: (Int) -> Void
    var width: CGFloat = 180
    var maxVisibleRows: Int = 10

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // 无数据就关闭
        if !isPresented || tags.isEmpty {
            context.coordinator.hide()
            return
        }

        // 没有合法锚点就不显示
        if anchorScreenRect == .zero {
            context.coordinator.hide()
            return
        }

        context.coordinator.showOrUpdate(
            parentWindow: nsView.window,
            anchorScreenRect: anchorScreenRect,
            tags: tags,
            selectedIndex: $selectedIndex,
            onSelectIndex: onSelectIndex,
            width: width,
            maxVisibleRows: maxVisibleRows
        )
    }

    final class Coordinator {
        private var panel: NSPanel?
        private var hostingView: NSHostingView<AnyView>?
        private weak var parentWindow: NSWindow?

        func hide() {
            panel?.orderOut(nil)
        }

        func showOrUpdate(
            parentWindow: NSWindow?,
            anchorScreenRect: CGRect,
            tags: [String],
            selectedIndex: Binding<Int>,
            onSelectIndex: @escaping (Int) -> Void,
            width: CGFloat,
            maxVisibleRows: Int
        ) {
            // 生成内容
            let content = AnyView(
                TDHashtagSuggestionPanelContent(
                    tags: tags,
                    selectedIndex: selectedIndex,
                    onSelectIndex: onSelectIndex,
                    width: width,
                    maxVisibleRows: maxVisibleRows
                )
            )

            if hostingView == nil {
                hostingView = NSHostingView(rootView: content)
            } else {
                hostingView?.rootView = content
            }

            if panel == nil {
                let p = NSPanel(
                    contentRect: .zero,
                    styleMask: [.borderless, .nonactivatingPanel],
                    backing: .buffered,
                    defer: false
                )
                p.isOpaque = false
                p.backgroundColor = .clear
                // 需求：不要阴影/不要描边（把系统面板阴影也关掉）
                p.hasShadow = false
                // 需求：主界面到后台时不应该还在最前端
                p.hidesOnDeactivate = true
                p.isReleasedWhenClosed = false
                // 跟随父窗口（不要跨 Space 漂移）
                p.collectionBehavior = [.fullScreenAuxiliary]
                p.ignoresMouseEvents = false
                p.becomesKeyOnlyIfNeeded = true
                p.contentView = hostingView
                panel = p
            } else {
                panel?.contentView = hostingView
            }

            // 让弹窗跟随父窗口（移动/最小化/失焦一起变化）
            if let parentWindow {
                if self.parentWindow !== parentWindow {
                    // 从旧 parent 上移除
                    if let old = self.parentWindow, let panel = panel {
                        old.removeChildWindow(panel)
                    }
                    self.parentWindow = parentWindow
                }
                if let panel, panel.parent != parentWindow {
                    parentWindow.addChildWindow(panel, ordered: .above)
                }
            }

            // 计算尺寸（按行数限制高度）
            let rowHeight: CGFloat = 32
            let visibleRows = min(maxVisibleRows, tags.count)
            let height = CGFloat(visibleRows) * rowHeight + CGFloat(max(0, visibleRows - 1)) * 1

            // 位置：按锚点的左侧对齐，放在光标 rect 下方
            // screen 坐标：原点在左下
            var origin = CGPoint(
                x: anchorScreenRect.minX,
                y: anchorScreenRect.minY - height - 6
            )

            // 防止超出屏幕
            if let screen = NSScreen.screens.first(where: { $0.visibleFrame.contains(anchorScreenRect.origin) }) ?? NSScreen.main {
                let frame = screen.visibleFrame
                origin.x = min(max(frame.minX, origin.x), frame.maxX - width)
                origin.y = min(max(frame.minY, origin.y), frame.maxY - height)
            }

            panel?.setFrame(CGRect(origin: origin, size: CGSize(width: width, height: height)), display: true)
            panel?.orderFront(nil)
        }
    }
}

private struct TDHashtagSuggestionPanelContent: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    let tags: [String]
    @Binding var selectedIndex: Int
    let onSelectIndex: (Int) -> Void
    let width: CGFloat
    let maxVisibleRows: Int

    var body: some View {
        let visible = Array(tags.prefix(maxVisibleRows))
        VStack(spacing: 0) {
            ForEach(Array(visible.enumerated()), id: \.offset) { idx, tag in
                Button {
                    onSelectIndex(idx)
                } label: {
                    HStack {
                        Text(tag)
                            .font(.system(size: 13))
                            // 文字颜色：主题色 5 级
                            .foregroundColor(themeManager.color(level: 5))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 32, alignment: .leading)
                    .frame(width: width, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            // 选中背景：主题色 5 级 + 0.1 透明度
                            .fill(idx == selectedIndex ? themeManager.color(level: 5).opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering { selectedIndex = idx }
                }

                if idx < visible.count - 1 {
                    Divider().background(themeManager.separatorColor.opacity(0.5))
                }
            }
        }
        // 需求：不要描边、不要阴影，仅保留纯背景
        .background(
            // 阴影：用“二级背景色”做投影色（更柔和，不会出现黑边）
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(themeManager.secondaryBackgroundColor)
                .shadow(color: themeManager.secondaryBackgroundColor, radius: 10, x: 0, y: 8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

