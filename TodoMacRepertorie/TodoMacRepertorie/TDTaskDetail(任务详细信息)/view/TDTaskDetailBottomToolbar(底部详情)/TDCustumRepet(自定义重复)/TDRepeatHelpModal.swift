import SwiftUI

/// 重复设置帮助说明弹窗
struct TDRepeatHelpModal: View {
    
    // MARK: - 数据绑定
    @EnvironmentObject private var themeManager: TDThemeManager
    @Binding var isPresented: Bool
    
    // MARK: - 主视图
    var body: some View {
        ZStack {
            // 半透明背景遮罩
            Color.black.opacity(0.2)
                .ignoresSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                }
            
            // 帮助说明弹窗内容
            helpModalContent
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .opacity)
                ))
        }
        .zIndex(1000)
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
    
    /// 帮助说明弹窗内容
    private var helpModalContent: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.color(level: 5))
                
                Text("重复设置说明")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.titleTextColor)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.descriptionTextColor)
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()

            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // 分割线
            Divider()
                .background(themeManager.separatorColor)
            
            // 说明内容
            VStack(alignment: .leading, spacing: 16) {
                helpItem(
                    icon: "calendar",
                    title: "重复间隔",
                    description: "设置任务重复的间隔时间，如每1天、每2周等。"
                )
                
                helpItem(
                    icon: "clock",
                    title: "重复单位",
                    description: "选择重复的时间单位：天、周、月、年。"
                )
                
                helpItem(
                    icon: "calendar.badge.clock",
                    title: "特殊选项",
                    description: "可以设置跳过法定节假日、工作日等特殊规则。"
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(themeManager.backgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .frame(width: 300)
    }
    
    /// 帮助说明项
    private func helpItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(themeManager.color(level: 5))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.titleTextColor)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.descriptionTextColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - 预览
#Preview {
    TDRepeatHelpModal(isPresented: .constant(true))
        .environmentObject(TDThemeManager.shared)
        .frame(width: 400, height: 300)
}
