//
//  TDFormTextField.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/12/19.
//

import SwiftUI

/// 外层容器，提供统一高度/圆角/背景，可选抖动和错误边框
struct TDFormFieldContainer<Content: View>: View {
    let shake: Bool
    let isError: Bool

    let content: () -> Content
    var body: some View {
        content()
            .padding(.horizontal, 12)
            .frame(height: 44)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isError ? Color.red.opacity(0.8) : Color.clear, lineWidth: 1)
            )
            .offset(x: shake ? 6 : 0)
            .animation(.easeInOut(duration: 0.08).repeatCount(shake ? 3 : 0, autoreverses: true), value: shake)
    }
}

/// 纯输入框（无边框，外层容器控制样式）
struct TDFormTextField: View {
    @Binding var text: String
    let placeholder: String
    var isSecure: Bool = false
    var shake: Bool = false
    var isError: Bool = false
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        TDFormFieldContainer(shake: shake, isError: isError) {
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .onSubmit { onSubmit?() }

                } else {
                    TextField(placeholder, text: $text)
                        .onSubmit { onSubmit?() }
                }
            }
            .textFieldStyle(.plain)
        }
    }
}

/// 右侧带按钮的输入框（无边框，外层容器控制样式）
struct TDFormTextFieldWithButton: View {
    @Binding var text: String
    let placeholder: String
    let buttonTitle: String
    var onButtonTap: () -> Void
    var themeManager: TDThemeManager
    var shake: Bool = false
    var isError: Bool = false
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        TDFormFieldContainer(shake: shake, isError: isError) {
            HStack(spacing: 8) {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .onSubmit { onSubmit?() }

                Button(buttonTitle) {
                    onButtonTap()
                }
                .font(.system(size: 12))
                .foregroundColor(.white)
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(themeManager.color(level: 5))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}

/// 右侧带倒计时按钮的输入框（无边框，外层容器控制样式）
struct TDFormTextFieldWithCountdown: View {
    @Binding var text: String
    let placeholder: String
    var countdownSeconds: Int = 60
    /// 返回 true 才启动倒计时，否则认为校验未通过
    var onSend: () -> Bool
    var themeManager: TDThemeManager
    
    @State private var remaining: Int = 0
    @State private var timer: Timer?
    var shake: Bool = false
    var isError: Bool = false
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        TDFormFieldContainer(shake: shake, isError: isError) {
            HStack(spacing: 8) {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        // 与按钮行为一致：仅当未在倒计时时触发
                        guard remaining <= 0 else { return }
                        if onSend() {
                            startCountdown()
                            onSubmit?()
                        }

                    }

                Button(buttonTitle) {
                    guard remaining <= 0 else { return }
                    if onSend() {
                        startCountdown()
                        onSubmit?()
                    }
                }
                .disabled(remaining > 0)
                .font(.system(size: 12))
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
                .foregroundColor(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(themeManager.color(level: 5))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private var buttonTitle: String {
        remaining > 0 ? "\(remaining)s" : "settings.account.phone.get_code".localized
    }
    
    private func startCountdown() {
        remaining = countdownSeconds
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            remaining -= 1
            if remaining <= 0 {
                t.invalidate()
                timer = nil
            }
        }
    }
}


//#Preview {
//    TDFormTextField(text: <#Binding<String>#>, placeholder: <#String#>)
//}
