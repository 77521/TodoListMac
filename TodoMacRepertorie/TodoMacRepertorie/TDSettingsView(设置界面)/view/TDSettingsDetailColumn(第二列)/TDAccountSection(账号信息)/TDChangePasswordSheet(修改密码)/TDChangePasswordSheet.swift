//
//  TDChangePasswordSheet.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/1.
//

import SwiftUI

/// 修改密码弹窗（根据模式展示不同表单）
struct TDChangePasswordSheet: View {
    /// 模式：旧密码 / 手机验证码 / 邮箱验证码
    enum Mode {
        case oldPassword
        case phone
        case email
    }
    
    // 当前模式
    let mode: Mode
    // 显示用手机号掩码（仅 phone 模式用）
    let maskedPhone: String?
    // 显示用邮箱账号（仅 email 模式用）
    let emailAccount: String?
       
    // 数据管理（直接在弹窗内调用接口）
    private let detailManager = TDSettingsDetailManager.shared

    
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.dismiss) private var dismiss
    
    // 输入状态
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var phoneCode: String = ""
    @State private var emailCode: String = ""
    
    // 错误文案
    @State private var currentPwdError: String?
    @State private var newPwdError: String?
    @State private var phoneCodeError: String?
    @State private var emailCodeError: String?
    
    // 抖动控制
    @State private var currentPwdShake = false
    @State private var newPwdShake = false
    @State private var phoneCodeShake = false
    @State private var emailCodeShake = false
    
    // 密码可见性切换
    @State private var currentPwdSecure = true
    @State private var newPwdSecure = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings.account.change_password.alert.title".localized)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(themeManager.titleTextColor)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Group {
                switch mode {
                case .oldPassword:
                    oldPasswordView
                case .phone:
                    phoneView
                case .email:
                    emailView
                }
            }
            
            HStack {
                Spacer()
                Button("common.cancel".localized) {
                    dismiss()
                }
                .font(.system(size: 12))
                .foregroundColor(themeManager.titleTextColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(themeManager.secondaryBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.plain)
                .pointingHandCursor()

                Button("common.confirm".localized) {
                    submit()
                }
                .font(.system(size: 12))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(themeManager.color(level: 5))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.plain)
                .pointingHandCursor()
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 460)
    }
    
    // MARK: - 旧密码模式视图
    private var oldPasswordView: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("settings.account.password.current".localized)
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 13))
                passwordField(
                    text: $currentPassword,
                    placeholder: "settings.account.password.current.placeholder".localized,
                    isSecure: $currentPwdSecure,
                    shake: currentPwdShake,
                    isError: currentPwdError != nil
                )
                Text(currentPwdError ?? " ")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("settings.account.password.new".localized)
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 13))
                passwordField(
                    text: $newPassword,
                    placeholder: "settings.account.password.new.placeholder".localized,
                    isSecure: $newPwdSecure,
                    shake: newPwdShake,
                    isError: newPwdError != nil
                )
                Text(newPwdError ?? " ")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - 手机模式视图
    private var phoneView: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("settings.account.phone.title".localized)
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 13))
                TDFormFieldContainer(shake: false, isError: false) {
                    HStack {
                        Text(maskedPhone ?? " ")
                            .foregroundColor(themeManager.titleTextColor)
                        Spacer()
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("settings.account.sms.code".localized)
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 13))
                TDFormTextFieldWithCountdown(
                    text: $phoneCode,
                    placeholder: "settings.account.phone.code.placeholder".localized,
                    onSend: {
                        // TODO: 接短信验证码接口（按需接入）；默认不启动倒计时
                        phoneCodeError = "settings.account.phone.code.placeholder".localized
                        $phoneCodeShake.triggerShake()
                        return false
                    },
                    themeManager: themeManager,
                    shake: phoneCodeShake,
                    isError: phoneCodeError != nil
                )
                Text(phoneCodeError ?? " ")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("settings.account.password.new".localized)
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 13))
                passwordField(
                    text: $newPassword,
                    placeholder: "settings.account.password.new.placeholder".localized,
                    isSecure: $newPwdSecure,
                    shake: newPwdShake,
                    isError: newPwdError != nil
                )
                Text(newPwdError ?? " ")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - 邮箱模式视图
    private var emailView: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("settings.account.bind.email.title".localized)
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 13))
                TDFormFieldContainer(shake: false, isError: false) {
                    HStack {
                        Text(emailAccount ?? " ")
                            .foregroundColor(themeManager.titleTextColor)
                        Spacer()
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("settings.account.email.new.code.title".localized)
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 13))
                TDFormTextFieldWithCountdown(
                    text: $emailCode,
                    placeholder: "settings.account.email.code.placeholder".localized,
                    onSend: {
                        // TODO: 接邮箱验证码接口（按需接入）；默认不启动倒计时
                        emailCodeError = "settings.account.email.code.placeholder".localized
                        $emailCodeShake.triggerShake()
                        return false
                    },
                    themeManager: themeManager,
                    shake: emailCodeShake,
                    isError: emailCodeError != nil
                )
                Text(emailCodeError ?? " ")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("settings.account.password.new".localized)
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 13))
                passwordField(
                    text: $newPassword,
                    placeholder: "settings.account.password.new.placeholder".localized,
                    isSecure: $newPwdSecure,
                    shake: newPwdShake,
                    isError: newPwdError != nil
                )
                Text(newPwdError ?? " ")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - 提交逻辑
    private func submit() {
        switch mode {
        case .oldPassword:
            guard validateOldPassword() else { return }
            Task {
                do {
                    try await detailManager.changePasswordByOld(current: currentPassword, newPassword: newPassword)
                    dismiss()
                } catch {
                    // 接口报错显示在最后一个输入框（新密码）下方
                    newPwdError = error.localizedDescription
                    $newPwdShake.triggerShake()
                }
            }
        case .phone:
            guard validatePhoneFlow() else { return }
            Task {
                do {
                    try await detailManager.changePasswordByPhone(code: phoneCode, newPassword: newPassword)
                    dismiss()
                } catch {
                    // 接口报错显示在最后一个输入框（新密码）下方
                    newPwdError = error.localizedDescription
                    $newPwdShake.triggerShake()
                }
            }
        case .email:
            guard validateEmailFlow() else { return }
            Task {
                do {
                    try await detailManager.changePasswordByEmail(code: emailCode, newPassword: newPassword)
                    dismiss()
                } catch {
                    // 接口报错显示在最后一个输入框（新密码）下方
                    newPwdError = error.localizedDescription
                    $newPwdShake.triggerShake()
                }
            }
        }
    }

    // MARK: - 校验
    private func validateOldPassword() -> Bool {
        let currentTrim = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let newTrim = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !currentTrim.isEmpty else {
            currentPwdError = "settings.account.password.current.placeholder".localized
            $currentPwdShake.triggerShake()
            return false
        }
        currentPwdError = nil
        guard !newTrim.isEmpty else {
            newPwdError = "settings.account.password.new.placeholder".localized
            $newPwdShake.triggerShake()
            return false
        }
        guard newTrim.count >= 6 else {
            newPwdError = "settings.account.password.short".localized
            $newPwdShake.triggerShake()
            return false
        }
        newPwdError = nil
        return true
    }
    
    private func validatePhoneFlow() -> Bool {
        let codeTrim = phoneCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let newTrim = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !codeTrim.isEmpty else {
            phoneCodeError = "settings.account.phone.code.placeholder".localized
            $phoneCodeShake.triggerShake()
            return false
        }
        phoneCodeError = nil
        guard !newTrim.isEmpty else {
            newPwdError = "settings.account.password.new.placeholder".localized
            $newPwdShake.triggerShake()
            return false
        }
        guard newTrim.count >= 6 else {
            newPwdError = "settings.account.password.short".localized
            $newPwdShake.triggerShake()
            return false
        }
        newPwdError = nil
        return true
    }
    
    private func validateEmailFlow() -> Bool {
        let codeTrim = emailCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let newTrim = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !codeTrim.isEmpty else {
            emailCodeError = "settings.account.email.code.placeholder".localized
            $emailCodeShake.triggerShake()
            return false
        }
        emailCodeError = nil
        guard !newTrim.isEmpty else {
            newPwdError = "settings.account.password.new.placeholder".localized
            $newPwdShake.triggerShake()
            return false
        }
        guard newTrim.count >= 6 else {
            newPwdError = "settings.account.password.short".localized
            $newPwdShake.triggerShake()
            return false
        }
        newPwdError = nil
        return true
    }
    
    // MARK: - 密码输入封装（带眼睛按钮）
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

