import SwiftUI

/// 重复设置共用选项
struct TDRepeatCommonOptions: View {
    
    // MARK: - 数据绑定
    @EnvironmentObject private var themeManager: TDThemeManager
    
    // MARK: - 状态绑定
    @Binding var isLegalWorkday: Bool
    @Binding var skipHolidays: Bool
    @Binding var skipWeekends: Bool
    @Binding var repeatCount: Int
    
    // MARK: - 回调闭包
    let onValidateRepeatCount: () -> Void
    
    // MARK: - 主视图
    var body: some View {
        VStack(spacing: 16) {
            // 法定工作日选项
            HStack {
                Text("法定工作日")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.titleTextColor)
                
                Spacer()
                
                Toggle("", isOn: $isLegalWorkday)
                    .toggleStyle(SwitchToggleStyle())
                    .tint(themeManager.color(level: 5))
            }
            
            // 只有在法定工作日关闭时才显示这两个选项
            if !isLegalWorkday {
                HStack {
                    Text("跳过法定节假日")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.titleTextColor)
                    
                    Spacer()
                    
                    Toggle("", isOn: $skipHolidays)
                        .toggleStyle(SwitchToggleStyle())
                        .tint(themeManager.color(level: 5))
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
                
                HStack {
                    Text("跳过双休日")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.titleTextColor)
                    
                    Spacer()
                    
                    Toggle("", isOn: $skipWeekends)
                        .toggleStyle(SwitchToggleStyle())
                        .tint(themeManager.color(level: 5))
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
            
            // 重复次数
            HStack {
                Text("重复次数")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.titleTextColor)
                
                Spacer()
                
                HStack(spacing: 0) {
                    Button(action: {
                        if repeatCount > 1 {
                            repeatCount -= 1
                        }
                    }) {
                        Text("-")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.titleTextColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                    .frame(width: 30, height: 30)
                    
                    TextField("1", value: $repeatCount, format: .number)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.titleTextColor)
                        .multilineTextAlignment(.center)
                        .frame(width: 40)
                        .onSubmit {
                            onValidateRepeatCount()
                        }
                        .onChange(of: repeatCount) { oldValue, newValue in
                            if newValue != oldValue {
                                onValidateRepeatCount()
                            }
                        }
                    
                    Button(action: {
                        if repeatCount < 99 {
                            repeatCount += 1
                        }
                    }) {
                        Text("+")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.titleTextColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                    .frame(width: 30, height: 30)
                }
                .background(themeManager.secondaryBackgroundColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeManager.separatorColor, lineWidth: 1)
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLegalWorkday)
    }
}

// MARK: - 预览
#Preview {
    TDRepeatCommonOptions(
        isLegalWorkday: .constant(false),
        skipHolidays: .constant(false),
        skipWeekends: .constant(false),
        repeatCount: .constant(1),
        onValidateRepeatCount: { print("验证重复次数") }
    )
    .environmentObject(TDThemeManager.shared)
}
