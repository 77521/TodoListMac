//
//  TDDeleteAccountSheet.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/2.
//

import SwiftUI

/// 注销账号弹窗，根据用户信息展示不同验证方式
struct TDDeleteAccountSheet: View {
    /// 模式：仅手机号、仅邮箱、手机号+密码
    enum Mode {
        case phone
        case email
        case phoneAndPassword
    }
    
    // 当前用户（用于展示手机号/邮箱）
    let user: TDUserModel
    // 关闭回调
    var onDismiss: (() -> Void)?
    
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.dismiss) private var dismiss
    private let detailManager = TDSettingsDetailManager.shared
    
    // 输入状态
    @State private var code: String = ""
    @State private var password: String = ""
    
    // 错误状态
    @State private var codeError: String?
    @State private var pwdError: String?
    
    // 抖动控制
    @State private var codeShake = false
    @State private var pwdShake = false
    
    // 密码可见性
    @State private var pwdSecure = true

    // 提交确认弹窗
    @State private var showConfirmAlert = false
    
    // 计算当前模式
    private var mode: Mode {
        let hasPhone = user.phoneNumber > 0
        let isEmailAcc = user.userAccount.isValidEmailFormat()
        if hasPhone && !isEmailAcc {
            return .phone
        } else if !hasPhone && isEmailAcc {
            return .email
        } else if hasPhone {
            return .phoneAndPassword
        } else {
            return .email
        }
    }
    
    // 掩码手机号
    private var maskedPhone: String? {
        String.maskedPhoneNumber(from: user.phoneNumber)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // 警示图标与标题
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                Text("settings.account.delete.title".localized)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeManager.titleTextColor)
            }
            .frame(maxWidth: .infinity)
            
            // 警示文案
            Text("settings.account.delete.notice".localized)
                .font(.system(size: 14))
                .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                .lineSpacing(4)
            
            // 手机号展示 + 获取验证码（phone / phone+password）
            if mode == .phone || mode == .phoneAndPassword {
                VStack(alignment: .leading, spacing: 5) {
                    Text("settings.account.phone.title".localized)
                        .foregroundColor(themeManager.titleTextColor)
                        .font(.system(size: 13))
                    TDFormTextFieldWithCountdown(
                        text: $code,
                        placeholder: "settings.account.phone.code.placeholder".localized,
                        onSend: {
                            guard let phoneText = maskedPhone, !phoneText.isEmpty else {
                                codeError = "settings.account.phone.invalid".localized
                                $codeShake.triggerShake()
                                return false
                            }
                            codeError = nil
                            Task {
                                do {
                                    try await detailManager.requestBindSmsCode(phone: String(user.phoneNumber))
                                } catch {
                                    codeError = error.localizedDescription
                                    $codeShake.triggerShake()
                                }
                            }
                            return true
                        },
                        themeManager: themeManager,
                        shake: codeShake,
                        isError: codeError != nil
                    )
                    Text(codeError ?? " ")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // 邮箱展示（email 模式）
            if mode == .email {
                VStack(alignment: .leading, spacing: 5) {
                    Text("settings.account.bind.email.title".localized)
                        .foregroundColor(themeManager.titleTextColor)
                        .font(.system(size: 13))
                    TDFormFieldContainer(shake: false, isError: false) {
                        HStack {
                            Text(user.userAccount)
                                .foregroundColor(themeManager.titleTextColor)
                            Spacer()
                        }
                    }
                }
            }
            
            // 密码输入（email 模式必填 / phoneAndPassword 模式必填）
            if mode == .email || mode == .phoneAndPassword {
                VStack(alignment: .leading, spacing: 5) {
                    Text("settings.account.password.title".localized)
                        .foregroundColor(themeManager.titleTextColor)
                        .font(.system(size: 13))
                    passwordField(
                        text: $password,
                        placeholder: "settings.account.password.placeholder".localized,
                        isSecure: $pwdSecure,
                        shake: pwdShake,
                        isError: pwdError != nil
                    )
                    Text(pwdError ?? " ")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // 确认按钮
            Button {
                guard validateInputs() else { return }
                showConfirmAlert = true
            } label: {
                Text("settings.account.delete.confirm".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            colors: [
                                themeManager.fixedColor(themeId: "new_year_red", level: 7),
                                themeManager.fixedColor(themeId: "new_year_red", level: 4)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
        }
        .padding(20)
        .frame(width: 500)
        .alert("settings.account.delete.confirm_alert.title".localized, isPresented: $showConfirmAlert) {
            Button("common.cancel".localized, role: .cancel) {
                showConfirmAlert = false
            }
            Button("settings.account.delete.confirm".localized, role: .destructive) {
                submitDelete()
            }
        } message: {
            Text("settings.account.delete.confirm_alert.message".localized)
        }
    }
    
    // MARK: - 校验输入
    private func validateInputs() -> Bool {
        var ok = true
        // 校验验证码（需要时）
        if mode == .phone || mode == .phoneAndPassword {
            let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                codeError = "settings.account.phone.code.placeholder".localized
                $codeShake.triggerShake()
                ok = false
            } else {
                codeError = nil
            }
        }
        // 校验密码（需要时）
        if mode == .email || mode == .phoneAndPassword {
            let pwdTrim = password.trimmingCharacters(in: .whitespacesAndNewlines)
            if pwdTrim.isEmpty {
                pwdError = "settings.account.password.placeholder".localized
                $pwdShake.triggerShake()
                ok = false
            } else {
                pwdError = nil
            }
        }
        return ok
    }
    
    // MARK: - 提交注销
    private func submitDelete() {
        Task {
            do {
                let phoneParam: Int? = user.phoneNumber > 0 ? user.phoneNumber : nil
                let codeParam: String? = (mode == .phone || mode == .phoneAndPassword) ? code.trimmingCharacters(in: .whitespacesAndNewlines) : nil
                let pwdParam: String? = (mode == .email || mode == .phoneAndPassword) ? password.trimmingCharacters(in: .whitespacesAndNewlines) : nil
                
                try await detailManager.deleteAccount(
                    phoneNumber: phoneParam,
                    code: codeParam,
                    nowPassword: pwdParam
                )
                dismiss()
                onDismiss?()
            } catch {
                // 失败优先显示在密码栏（如无密码栏则显示在验证码栏），不关闭弹窗
                let message: String = {
                    if let netErr = error as? TDNetworkError {
                        if case .requestFailed(let msg) = netErr {
                            return msg
                        }
                        return netErr.errorMessage
                    }
                    return error.localizedDescription
                }()
                if mode == .email || mode == .phoneAndPassword {
                    pwdError = message
                    $pwdShake.triggerShake()
                } else {
                    codeError = message
                    $codeShake.triggerShake()
                }
            }
        }
    }
    
    // MARK: - 密码输入（带眼睛）
    private func passwordField(text: Binding<String>,
                               placeholder: String,
                               isSecure: Binding<Bool>,
                               shake: Bool,
                               isError: Bool) -> some View {
        TDFormFieldContainer(shake: shake, isError: isError) {
            HStack(spacing: 8) {
                if isSecure.wrappedValue {
                    SecureField(placeholder, text: text)
                        .textFieldStyle(.plain)
                } else {
                    TextField(placeholder, text: text)
                        .textFieldStyle(.plain)
                }
                Button {
                    isSecure.wrappedValue.toggle()
                } label: {
                    Image(systemName: isSecure.wrappedValue ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

}
