import SwiftUI

/// 重复设置底部操作栏
struct TDRepeatActionBar: View {
    
    // MARK: - 数据绑定
    @EnvironmentObject private var themeManager: TDThemeManager
    
    // MARK: - 回调闭包
    let onCancel: () -> Void
    let onCreate: () -> Void
    
    // MARK: - 主视图
    var body: some View {
        HStack(spacing: 12) {
            Spacer()
            
            // 取消按钮
            Button(action: onCancel) {
                Text("取消")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.titleTextColor)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.secondaryBackgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeManager.separatorColor, lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 创建按钮
            Button(action: onCreate) {
                Text("创建")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.color(level: 5))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(themeManager.backgroundColor)
    }
}

// MARK: - 预览
#Preview {
    TDRepeatActionBar(
        onCancel: { print("取消") },
        onCreate: { print("创建") }
    )
    .environmentObject(TDThemeManager.shared)
}
