import Foundation
import SwiftUI
import AppKit

/// 图片扩展
extension Image {
    
    /// 从颜色创建指定尺寸的圆形图片
    /// - Parameters:
    ///   - color: 图片颜色
    ///   - width: 图片宽度，默认 12
    ///   - height: 图片高度，默认 12
    ///   - cornerRadius: 圆角半径，默认 6（圆形）
    /// - Returns: 生成的图片
    static func fromColor(_ color: Color, width: CGFloat = 12, height: CGFloat = 12, cornerRadius: CGFloat = 6) -> Image {
        let size = CGSize(width: width, height: height)
        let nsImage = NSImage(size: size)
        nsImage.lockFocus()
        
        // 创建圆角矩形路径
        let rect = NSRect(origin: .zero, size: size)
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        
        // 设置颜色并填充
        NSColor(color).setFill()
        path.fill()
        
        nsImage.unlockFocus()
        return Image(nsImage: nsImage)
    }
    
    /// 从十六进制颜色字符串创建指定尺寸的圆形图片
    /// - Parameters:
    ///   - hexString: 十六进制颜色字符串
    ///   - width: 图片宽度，默认 12
    ///   - height: 图片高度，默认 12
    ///   - cornerRadius: 圆角半径，默认 6（圆形）
    /// - Returns: 生成的图片
    static func fromHexColor(_ hexString: String, width: CGFloat = 12, height: CGFloat = 12, cornerRadius: CGFloat = 6) -> Image {
        let color = Color.fromHex(hexString)
        return Image.fromColor(color, width: width, height: height, cornerRadius: cornerRadius)
    }
  
    /// 从颜色创建指定尺寸的空心圆圈图片
    /// - Parameters:
    ///   - color: 圆圈颜色
    ///   - width: 图片宽度，默认 12
    ///   - height: 图片高度，默认 12
    ///   - lineWidth: 线条宽度，默认 1.5
    /// - Returns: 生成的图片
    static func fromCircleColor(_ color: Color, width: CGFloat = 12, height: CGFloat = 12, lineWidth: CGFloat = 1.5) -> Image {
        let size = CGSize(width: width, height: height)
        let nsImage = NSImage(size: size)
        nsImage.lockFocus()
        
        // 考虑线条宽度，调整绘制区域
        let inset = lineWidth / 2
        let rect = NSRect(x: inset, y: inset, width: size.width - lineWidth, height: size.height - lineWidth)
        let path = NSBezierPath(ovalIn: rect)
        
        // 设置线条颜色和宽度
        NSColor(color).setStroke()
        path.lineWidth = lineWidth
        
        // 绘制空心圆圈
        path.stroke()
        
        nsImage.unlockFocus()
        return Image(nsImage: nsImage)
    }

    /// 从十六进制颜色字符串创建指定尺寸的空心圆圈图片
    /// - Parameters:
    ///   - hexString: 十六进制颜色字符串
    ///   - width: 图片宽度，默认 12
    ///   - height: 图片高度，默认 12
    ///   - lineWidth: 线条宽度，默认 1.5
    ///   - cornerRadius: 圆角半径，默认 6（圆形）
    /// - Returns: 生成的图片
    static func fromCircleHexColor(_ hexString: String, width: CGFloat = 12, height: CGFloat = 12, lineWidth: CGFloat = 1.5, cornerRadius: CGFloat = 6) -> Image {
        let color = Color.fromHex(hexString)
        return Image.fromCircleColor(color, width: width, height: height, lineWidth: lineWidth)
    }

    
    
    /// 从系统图标名称创建指定颜色的图片
        /// - Parameters:
        ///   - systemName: 系统图标名称
        ///   - color: 图标颜色
        ///   - size: 图标尺寸，默认 12x12
        /// - Returns: 生成的图片
        static func fromSystemName(_ systemName: String, color: Color, size: CGFloat = 12) -> Image {
            // 获取系统图标
            guard let templateImage = NSImage(systemSymbolName: systemName, accessibilityDescription: nil) else {
                // 如果获取失败，返回一个空的图片
                return Image(nsImage: NSImage())
            }
            
            // 计算绘制区域（居中绘制，保持宽高比）
            let imageSize = templateImage.size
            let scale = min(size / imageSize.width, size / imageSize.height)
            let scaledWidth = imageSize.width * scale
            let scaledHeight = imageSize.height * scale
            let x = (size - scaledWidth) / 2
            let y = (size - scaledHeight) / 2
            let drawRect = NSRect(x: x, y: y, width: scaledWidth, height: scaledHeight)
            
            // 创建位图表示（使用正确的参数）
            guard let bitmapRep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(size),
                pixelsHigh: Int(size),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: Int(size) * 4,
                bitsPerPixel: 32
            ) else {
                return Image(nsImage: NSImage())
            }
            
            // 创建新的图片并添加位图表示
            let coloredImage = NSImage(size: CGSize(width: size, height: size))
            coloredImage.addRepresentation(bitmapRep)
            
            // 开始绘制
            coloredImage.lockFocus()
            defer { coloredImage.unlockFocus() }
            
            // 先绘制模板图片（黑色）
            templateImage.isTemplate = true
            templateImage.draw(in: drawRect, from: NSRect(origin: .zero, size: imageSize), operation: .sourceOver, fraction: 1.0)
            
            // 然后使用颜色填充，使用 sourceAtop 操作（只在已有内容的地方应用颜色）
            let nsColor = NSColor(color)
            nsColor.set()
            
            // 使用路径填充并应用混合模式
            let path = NSBezierPath(rect: drawRect)
            NSGraphicsContext.current?.compositingOperation = .sourceAtop
            path.fill()
            
            return Image(nsImage: coloredImage)
        }
        
    /// 从系统图标名称创建指定十六进制颜色的图片
    /// - Parameters:
    ///   - systemName: 系统图标名称
    ///   - hexString: 十六进制颜色字符串
    ///   - size: 图标尺寸，默认 12x12
    /// - Returns: 生成的图片
    static func fromSystemName(_ systemName: String, hexColor: String, size: CGFloat = 12) -> Image {
        let color = Color.fromHex(hexColor)
        return Image.fromSystemName(systemName, color: color, size: size)
    }
    
    
    /// 创建实心圆圈中间带加号的图片
    /// - Parameters:
    ///   - color: 圆圈颜色
    ///   - width: 图片宽度，默认 12
    ///   - height: 图片高度，默认 12
    ///   - plusSize: 加号大小，默认 6
    ///   - plusWidth: 加号线条宽度，默认 1.5
    /// - Returns: 生成的图片
    static func fromPlusCircleColor(_ color: Color, width: CGFloat = 12, height: CGFloat = 12, plusSize: CGFloat = 6, plusWidth: CGFloat = 1.5) -> Image {
        let size = CGSize(width: width, height: height)
        let nsImage = NSImage(size: size)
        nsImage.lockFocus()
        
        // 绘制实心圆圈
        let circleRect = NSRect(origin: .zero, size: size)
        let circlePath = NSBezierPath(ovalIn: circleRect)
        NSColor(color).setFill()
        circlePath.fill()
        
        // 绘制白色加号
        let centerX = size.width / 2
        let centerY = size.height / 2
        let halfPlusSize = plusSize / 2
        let halfPlusWidth = plusWidth / 2
        
        // 绘制横线
        let horizontalRect = NSRect(
            x: centerX - halfPlusSize,
            y: centerY - halfPlusWidth,
            width: plusSize,
            height: plusWidth
        )
        let horizontalPath = NSBezierPath(rect: horizontalRect)
        NSColor.white.setFill()
        horizontalPath.fill()
        
        // 绘制竖线
        let verticalRect = NSRect(
            x: centerX - halfPlusWidth,
            y: centerY - halfPlusSize,
            width: plusWidth,
            height: plusSize
        )
        let verticalPath = NSBezierPath(rect: verticalRect)
        NSColor.white.setFill()
        verticalPath.fill()
        
        nsImage.unlockFocus()
        return Image(nsImage: nsImage)
    }
    
    /// 创建实心圆圈中间带加号的图片（十六进制颜色版本）
    /// - Parameters:
    ///   - hexString: 十六进制颜色字符串
    ///   - width: 图片宽度，默认 12
    ///   - height: 图片高度，默认 12
    ///   - plusSize: 加号大小，默认 6
    ///   - plusWidth: 加号线条宽度，默认 1.5
    /// - Returns: 生成的图片
    static func fromPlusCircleHexColor(_ hexString: String, width: CGFloat = 12, height: CGFloat = 12, plusSize: CGFloat = 6, plusWidth: CGFloat = 1.5) -> Image {
        let color = Color.fromHex(hexString)
        return Image.fromPlusCircleColor(color, width: width, height: height, plusSize: plusSize, plusWidth: plusWidth)
    }

}
