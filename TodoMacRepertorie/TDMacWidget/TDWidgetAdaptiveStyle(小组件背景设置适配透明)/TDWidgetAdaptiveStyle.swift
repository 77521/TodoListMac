import SwiftUI
import WidgetKit

/// 小组件通用：基于系统渲染模式（fullColor / accented / vibrant / monochrome）做颜色自适配
enum TDWidgetAdaptiveStyle {
    /// 对齐 iOS：fullColor 用真实主题色；否则使用 secondary 半透明
    @inline(__always)
    static func chipFill(base: Color, renderingMode: WidgetRenderingMode) -> Color {
        if renderingMode == .fullColor {
            return base
        } else {
            return Color.secondary.opacity(0.2)
        }
    }

    /// fullColor 下通常用白字；非 fullColor 用 primary，避免“白底白字看不见”
    @inline(__always)
    static func chipForeground(
        renderingMode: WidgetRenderingMode,
        fullColor: Color = .white,
        nonFullColor: Color = .primary
    ) -> Color {
        renderingMode == .fullColor ? fullColor : nonFullColor
    }

    /// 用作 `.foregroundStyle(.tint)` 的 tint 色（同 chipForeground）
    @inline(__always)
    static func chipTint(renderingMode: WidgetRenderingMode) -> Color {
        chipForeground(renderingMode: renderingMode)
    }

    /// 常用按钮风格：Capsule 背景（会自动适配渲染模式）
    @ViewBuilder
    static func chipBackground(base: Color, renderingMode: WidgetRenderingMode) -> some View {
        Capsule(style: .circular)
            .fill(chipFill(base: base, renderingMode: renderingMode))
    }
}

