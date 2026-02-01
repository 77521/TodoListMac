//
//  TDTagFlowLayout.swift
//  TodoMacRepertorie
//
//  让标签“靠左紧凑排列”的流式布局：
//  - 每个标签之间固定水平间距 spacing
//  - 行与行之间固定垂直间距 lineSpacing
//  - 超出宽度自动换行
//

import SwiftUI

/// 适用于“标签云/胶囊”的流式布局（右侧剩余空间不参与分配）
struct TDTagFlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let proposedWidth = proposal.width
        let maxWidth = proposedWidth ?? .greatestFiniteMagnitude
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            // 计算：非首个元素需要加 spacing
            let nextWidth = (x > 0 ? x + spacing + size.width : size.width)
            if x > 0, nextWidth > maxWidth {
                // 换行
                maxLineWidth = max(maxLineWidth, x)
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x = (x > 0 ? x + spacing + size.width : size.width)
            lineHeight = max(lineHeight, size.height)
        }

        let totalHeight = y + lineHeight
        maxLineWidth = max(maxLineWidth, x)

        // 关键：如果父视图给了宽度，就返回该宽度，避免容器“缩水”导致一行只能放一个标签
        let width = proposedWidth ?? maxLineWidth
        return CGSize(width: width, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            // 计算：非首个元素需要加 spacing
            let nextWidth = (x > 0 ? x + spacing + size.width : size.width)
            if x > 0, nextWidth > maxWidth {
                // 换行
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }

            let placeX = (x > 0 ? x + spacing : 0)
            let origin = CGPoint(x: bounds.minX + placeX, y: bounds.minY + y)
            subview.place(at: origin, proposal: ProposedViewSize(size))

            x = placeX + size.width
            lineHeight = max(lineHeight, size.height)
        }
    }
}

