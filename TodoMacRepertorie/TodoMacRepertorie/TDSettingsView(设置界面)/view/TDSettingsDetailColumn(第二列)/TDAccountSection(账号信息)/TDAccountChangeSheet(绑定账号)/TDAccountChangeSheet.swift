//
//  TDAccountChangeSheet.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/12/31.
//

import SwiftUI

/// 账号/密码设置与修改界面（sheet 弹出）
struct TDAccountChangeSheet: View {
    
    // 模式定义
    enum Mode {
        case bindAccount          // 没有账号，绑定账号+密码
        case changeNoPhone        // 有账号、无手机号，走邮箱验证
        case changeWithPhone      // 有账号、有手机号，走短信验证
        case locked               // 已修改过账号，显示限制提示
    }
    
    @EnvironmentObject private var themeManager: TDThemeManager
    private let detailManager = TDSettingsDetailManager.shared

    @Environment(\.dismiss) private var dismissSheet
    // Toast 提示
    @State private var showToast = false
    @State private var toastMessage: String = ""

    // 输入状态
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var smsCode: String = ""
    @State private var emailCode: String = ""
    @State private var newEmail: String = ""
    @State private var currentEmailCode: String = ""
    @State private var phoneCode: String = ""
    
    // 错误提示与抖动
    @State private var bindEmailError: String?
    @State private var bindEmailShake = false
    @State private var bindPasswordError: String?
    @State private var bindPasswordShake = false
    @State private var bindPasswordSecure = true
    
    @State private var changeEmailError: String?
    @State private var changeEmailShake = false
    @State private var changePasswordError: String?
    @State private var changePasswordShake = false
    @State private var changePasswordSecure = true
    @State private var changeEmailCodeError: String?
    @State private var changeEmailCodeShake = false
    
    @State private var changeNewEmailError: String?
    @State private var changeNewEmailShake = false
    @State private var changeNewEmailCodeError: String?
    @State private var changeNewEmailCodeShake = false
    
    @State private var changePhoneError: String?
    @State private var changePhoneShake = false
    @State private var changePhoneCodeError: String?
    @State private var changePhoneCodeShake = false
    
    // 修改账号确认弹窗
    @State private var showChangeAlert = false
    @State private var confirmAction: (() -> Void)?

    
    // 当前模式
    private let mode: Mode
    private let currentAccount: String
    private let maskedPhone: String
    private let rawPhone: String
    
    init(user: TDUserModel) {
        // 根据用户信息判断模式
        if user.accountChangeNum > 0 {
            self.mode = .locked
        } else if (user.userAccount).isEmpty {
            self.mode = .bindAccount
        } else if user.phoneNumber <= 0 {
            self.mode = .changeNoPhone
        } else {
            self.mode = .changeWithPhone
        }
        self.currentAccount = user.userAccount
        let phone = user.phoneNumber
        if phone > 0 {
            let s = String(phone)
            self.maskedPhone = s.count > 7 ? s.replacingCharacters(in: s.index(s.startIndex, offsetBy: 3)..<s.index(s.startIndex, offsetBy: min(7, s.count)), with: "****") : s
            self.rawPhone = s
        } else {
            self.maskedPhone = ""
            self.rawPhone = ""
        }
    }
    
    var body: some View {
        Group {
            switch mode {
            case .locked:
                lockedView
            case .bindAccount:
                bindView
            case .changeNoPhone:
                changeNoPhoneView
            case .changeWithPhone:
                changeWithPhoneView
            }
        }
        .frame(maxWidth: 520)
        .padding(20)
        .overlay(alignment: .topTrailing) {
            Button {
                dismissSheet()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 15)
            .padding(.top, 15)
        }
        .tdToastBottom(isPresenting: $showToast, message: toastMessage, type: .success)
        .alert("settings.account.change.alert.title".localized, isPresented: $showChangeAlert) {
            Button("common.cancel".localized, role: .cancel) {
                confirmAction = nil
            }
            Button("settings.account.change.alert.confirm".localized, role: .destructive) {
                let action = confirmAction
                confirmAction = nil
                action?()
            }
        } message: {
            Text("settings.account.change.alert.message".localized)
        }

    }
    
    // MARK: - 各模式 UI
    
    /// 无账号：设置账号与密码
    private var bindView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("settings.account.bind.title".localized)
                .font(.system(size: 16))
                .foregroundColor(themeManager.titleTextColor)
                .frame(maxWidth: .infinity, alignment: .center)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("settings.account.bind.email.title".localized)
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 13))
                TDFormTextField(
                    text: $email,
                    placeholder: "settings.account.bind.email.placeholder".localized,
                    shake: bindEmailShake,
                    isError: bindEmailError != nil
                )
                Text(bindEmailError ?? " ")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("settings.account.bind.password.title".localized)
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 13))
                passwordField(
                    text: $password,
                    placeholder: "settings.account.bind.password.placeholder".localized,
                    isSecure: $bindPasswordSecure,
                    shake: bindPasswordShake,
                    isError: bindPasswordError != nil
                )

                Text(bindPasswordError ?? " ")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            primaryButton(title: "settings.account.bind.button".localized) {
                guard email.isValidEmailFormat() else {
                    bindEmailError = "settings.account.email.invalid".tdPrefixed
                    $bindEmailShake.triggerShake()
                    return
                }
                bindEmailError = nil
                let trimmedPwd = password.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedPwd.isEmpty else {
                    bindPasswordError = "settings.account.password.placeholder".localized
                    $bindPasswordShake.triggerShake()
                    return
                }
                guard trimmedPwd.count >= 6 else {
                    bindPasswordError = "settings.account.password.short".localized
                    $bindPasswordShake.triggerShake()
                    return
                }
                bindPasswordError = nil
                // TODO: 触发绑定账号与密码的网络请求
                Task {
                    do {
                        try await detailManager.submitConfigAccount(setAccount: email, setPassword: trimmedPwd)
                        showSuccessToast()
                        dismissSheet()
                    } catch let flowErr as TDSettingsDetailManager.TDAccountChangeFlowError {
                        handleBindAccountError(flowErr)
                    } catch {
                        bindEmailError = error.localizedDescription
                        $bindEmailShake.triggerShake()
                    }
                }

            }
        }
    }
    // MARK: - 密码显示切换辅助
    private struct SecureToggleModifier: ViewModifier {
        let isSecure: Bool
        func body(content: Content) -> some View {
            content
                .environment(\.isEnabled, true) // 保持行为
                .overlay(
                    Group {} // 占位，实际 secure 由按钮控制文本显示
                )
        }
    }
    
    
    /// 有账号且无手机号：走邮箱验证修改
        private var changeNoPhoneView: some View {
            VStack(alignment: .leading, spacing: 15) {
                headerChangeTitle
                Text(String(format: "settings.account.change.current".localized, currentAccount))
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 14))
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("settings.account.password.title".localized)
                        .foregroundColor(themeManager.titleTextColor)
                        .font(.system(size: 13))
                    passwordField(
                        text: $password,
                        placeholder: "settings.account.password.placeholder".localized,
                        isSecure: $changePasswordSecure,
                        shake: changePasswordShake,
                        isError: changePasswordError != nil
                    )
                    Text(changePasswordError ?? " ")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(String(format: "settings.account.email.verify.current".localized, currentAccount))
                        .foregroundColor(themeManager.titleTextColor)
                        .font(.system(size: 13))
                    TDFormTextFieldWithCountdown(
                        text: $currentEmailCode,
                        placeholder: "settings.account.email.code.placeholder".localized,
                        onSend: {
                            let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
                            let trimmedCurrentCode = currentEmailCode.trimmingCharacters(in: .whitespacesAndNewlines)
                            let trimmedNewEmailCode = emailCode.trimmingCharacters(in: .whitespacesAndNewlines)

//                            // 校验当前邮箱格式
//                            if !currentAccount.isValidEmailFormat() {
//                                changeEmailError = "settings.account.email.invalid".tdPrefixed
//                                $changeEmailShake.triggerShake()
//                                return false
//                            }
//                            changeEmailError = nil
//                            guard !currentEmailCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
//                                changeEmailCodeError = "settings.account.email.code.placeholder".localized
//                                $changeEmailCodeShake.triggerShake()
//                                return false
//                            }
//                            changeEmailCodeError = nil
                            // TODO: 发送当前邮箱验证码
                            let passwordCopy = trimmedPassword
                            let newAccountCopy = newEmail
                            let newEmailCodeCopy = Int(trimmedNewEmailCode) ?? 0
                            let oldEmailCodeCopy = Int(trimmedCurrentCode)
                            
                            confirmAction = { [passwordCopy, newAccountCopy, newEmailCodeCopy, oldEmailCodeCopy] in
                                Task {
                                    do {
                                        try await detailManager.submitChangeAccount(
                                            password: passwordCopy,
                                            newAccount: newAccountCopy,
                                            newEmailCode: newEmailCodeCopy,
                                            smsCode: nil,
                                            oldEmailCode: oldEmailCodeCopy
                                        )
                                        showSuccessToast()
                                        dismissSheet()
                                    } catch let flowErr as TDSettingsDetailManager.TDAccountChangeFlowError {
                                        handleChangeNoPhoneError(flowErr)
                                    } catch {
                                        changeNewEmailError = error.localizedDescription
                                        $changeNewEmailShake.triggerShake()
                                    }
                                }
                            }
                            showChangeAlert = true

                            return true
                        },
                        themeManager: themeManager,
                        shake: changeEmailShake || changeEmailCodeShake,
                        isError: (changeEmailError != nil) || (changeEmailCodeError != nil)
                    )
                    Text(changeEmailError ?? changeEmailCodeError ?? " ")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("settings.account.email.new.title".localized)
                        .foregroundColor(themeManager.titleTextColor)
                        .font(.system(size: 13))
                    TDFormTextField(
                        text: $newEmail,
                        placeholder: "settings.account.email.new.placeholder".localized,
                        shake: changeNewEmailShake,
                        isError: changeNewEmailError != nil
                    )
                    Text(changeNewEmailError ?? " ")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("settings.account.email.new.code.title".localized)
                        .foregroundColor(themeManager.titleTextColor)
                        .font(.system(size: 13))
                    TDFormTextFieldWithCountdown(
                        text: $emailCode,
                        placeholder: "settings.account.email.code.placeholder".localized,
                        onSend: {
                            guard newEmail.isValidEmailFormat() else {
                                changeNewEmailError = "settings.account.email.invalid".tdPrefixed
                                $changeNewEmailShake.triggerShake()
                                return false
                            }
                            changeNewEmailError = nil
                            // TODO: 发送新邮箱验证码
                            Task {
                                do {
                                    try await detailManager.requestNewEmailCodeByChangeAccount(newAccount: newEmail)
                                    showSuccessToast()
                                } catch let flowErr as TDSettingsDetailManager.TDAccountChangeFlowError {
                                    handleChangeNoPhoneError(flowErr)
                                } catch {
                                    changeNewEmailCodeError = error.localizedDescription
                                    $changeNewEmailCodeShake.triggerShake()
                                }
                            }

                            return true

                        },
                        themeManager: themeManager,
                        shake: changeNewEmailCodeShake,
                        isError: changeNewEmailCodeError != nil
                    )
                    Text(changeNewEmailCodeError ?? " ")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                primaryButton(title: "settings.account.change.confirm".localized) {
                    // 先清空旧错误，避免残留
                    changePasswordError = nil
                    changeEmailError = nil
                    changeEmailCodeError = nil
                    changeNewEmailError = nil
                    changeNewEmailCodeError = nil
                    
                    // 顺序校验：遇到第一个错误即返回
                    let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedPassword.isEmpty else {
                        changePasswordError = "settings.account.password.placeholder".localized
                        $changePasswordShake.triggerShake()
                        return
                    }
                    guard trimmedPassword.count >= 6 else {
                        changePasswordError = "settings.account.password.short".localized
                        $changePasswordShake.triggerShake()
                        return
                    }

                    changePasswordError = nil
                    
                    guard newEmail.isValidEmailFormat() else {
                        changeNewEmailError = "settings.account.email.invalid".tdPrefixed
                        $changeNewEmailShake.triggerShake()
                        return
                    }
                    changeNewEmailError = nil
                    
                    let trimmedCurrentCode = currentEmailCode.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedCurrentCode.isEmpty else {
                        changeEmailCodeError = "settings.account.email.code.placeholder".localized
                        $changeEmailCodeShake.triggerShake()
                        return
                    }
                    changeEmailCodeError = nil
                    
                    let trimmedNewEmailCode = emailCode.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedNewEmailCode.isEmpty else {
                        changeNewEmailCodeError = "settings.account.email.code.placeholder".localized
                        $changeNewEmailCodeShake.triggerShake()
                        return
                    }
                    changeNewEmailCodeError = nil
                    // TODO: 触发修改账号流程（邮箱验证）
                    Task {
                        do {
                            let oldCodeInt = Int(trimmedCurrentCode)
                            let newCodeInt = Int(trimmedNewEmailCode) ?? 0
                            try await detailManager.submitChangeAccount(
                                password: trimmedPassword,
                                newAccount: newEmail,
                                newEmailCode: newCodeInt,
                                smsCode: nil,
                                oldEmailCode: oldCodeInt
                            )
                            showSuccessToast()
                            dismissSheet()
                        } catch let flowErr as TDSettingsDetailManager.TDAccountChangeFlowError {
                            handleChangeNoPhoneError(flowErr)
                        } catch {
                            changeNewEmailError = error.localizedDescription
                            $changeNewEmailShake.triggerShake()
                        }
                    }

                }
            }
        }
    
    /// 有账号且有手机号：短信+邮箱双验证
    private var changeWithPhoneView: some View {
        VStack(alignment: .leading, spacing: 15) {
            headerChangeTitle
            Text(String(format: "settings.account.change.current".localized, currentAccount))
                .foregroundColor(themeManager.titleTextColor)
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 5) {
                Text("settings.account.password.title".localized)
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 13))
                passwordField(
                    text: $password,
                    placeholder: "settings.account.password.placeholder".localized,
                    isSecure: $changePasswordSecure,
                    shake: changePasswordShake,
                    isError: changePasswordError != nil
                )
                Text(changePasswordError ?? " ")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("settings.account.phone.title".localized)
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 13))
                TDFormFieldContainer(shake: changePhoneShake, isError: changePhoneError != nil) {
                    HStack {
                        Text(maskedPhone.isEmpty ? "settings.account.phone.title".localized : maskedPhone)
                            .foregroundColor(themeManager.titleTextColor)
                        Spacer()
                    }
                }
                Text(changePhoneError ?? " ")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("settings.account.sms.code".localized)
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 13))
                TDFormTextFieldWithCountdown(
                    text: $phoneCode,
                    placeholder: "settings.account.phone.code.placeholder".localized,
                    onSend: {
                        if !rawPhone.isValidPhoneNumber {
                            changePhoneError = "settings.account.phone.invalid".tdPrefixed
                            $changePhoneShake.triggerShake()
                            return false
                        }
                        changePhoneError = nil
                        changePhoneCodeError = nil
                        // TODO: 发送短信验证码
                        Task {
                            do {
                                if let phoneInt = Int(rawPhone) {
                                    try await detailManager.requestChangeAccountSmsCode(phoneNumber: phoneInt)
                                    showSuccessToast()
                                }
                            } catch let flowErr as TDSettingsDetailManager.TDAccountChangeFlowError {
                                handleChangeWithPhoneError(flowErr)
                            } catch {
                                changePhoneCodeError = error.localizedDescription
                                $changePhoneCodeShake.triggerShake()
                            }
                        }

                        return true
                    },
                    themeManager: themeManager,
                    shake: changePhoneCodeShake,
                    isError: changePhoneCodeError != nil
                )
                Text(changePhoneCodeError ?? " ")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("settings.account.email.new.title".localized)
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 13))
                TDFormTextField(
                    text: $newEmail,
                    placeholder: "settings.account.email.new.placeholder".localized,
                    shake: changeNewEmailShake,
                    isError: changeNewEmailError != nil
                )
                Text(changeNewEmailError ?? " ")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("settings.account.email.new.code.title".localized)
                    .foregroundColor(themeManager.titleTextColor)
                    .font(.system(size: 13))
                TDFormTextFieldWithCountdown(
                    text: $emailCode,
                    placeholder: "settings.account.email.code.placeholder".localized,
                    onSend: {
                        guard newEmail.isValidEmailFormat() else {
                            changeNewEmailError = "settings.account.email.invalid".tdPrefixed
                            $changeNewEmailShake.triggerShake()
                            return false
                        }
                        changeNewEmailError = nil
                        // TODO: 发送邮箱验证码
                        Task {
                            do {
                                try await detailManager.requestNewEmailCodeByChangeAccount(newAccount: newEmail)
                                showSuccessToast()
                            } catch let flowErr as TDSettingsDetailManager.TDAccountChangeFlowError {
                                handleChangeWithPhoneError(flowErr)
                            } catch {
                                changeNewEmailCodeError = error.localizedDescription
                                $changeNewEmailCodeShake.triggerShake()
                            }
                        }

                        return true
                    },
                    themeManager: themeManager,
                    shake: changeNewEmailCodeShake,
                    isError: changeNewEmailCodeError != nil
                )
                Text(changeNewEmailCodeError ?? " ")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            primaryButton(title: "settings.account.change.confirm".localized) {
                
                // 顺序校验：遇到第一个错误即返回
                let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedPassword.isEmpty else {
                    changePasswordError = "settings.account.password.placeholder".localized
                    $changePasswordShake.triggerShake()
                    return
                }
                guard trimmedPassword.count >= 6 else {
                    changePasswordError = "settings.account.password.short".localized
                    $changePasswordShake.triggerShake()
                    return
                }

                changePasswordError = nil
                
                // 手机格式
                guard !rawPhone.isEmpty, rawPhone.isValidPhoneNumber else {
                    changePhoneError = "settings.account.phone.invalid".localized
                    $changePhoneShake.triggerShake()
                    return
                }
                changePhoneError = nil
                
                // 短信验证码
                let trimmedPhoneCode = phoneCode.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedPhoneCode.isEmpty else {
                    changePhoneCodeError = "settings.account.phone.code.placeholder".localized
                    $changePhoneCodeShake.triggerShake()
                    return
                }
                changePhoneCodeError = nil
                
                // 新邮箱格式
                guard newEmail.isValidEmailFormat() else {
                    changeNewEmailError = "settings.account.email.invalid".tdPrefixed
                    $changeNewEmailShake.triggerShake()
                    return
                }
                changeNewEmailError = nil
                
                // 邮箱验证码
                let trimmedEmailCode = emailCode.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedEmailCode.isEmpty else {
                    changeNewEmailCodeError = "settings.account.email.code.placeholder".localized
                    $changeNewEmailCodeShake.triggerShake()
                    return
                }
                changeNewEmailCodeError = nil

                let passwordCopy = trimmedPassword
                let newAccountCopy = newEmail
                let newEmailCodeCopy = Int(trimmedEmailCode) ?? 0
                let smsCodeCopy = Int(trimmedPhoneCode)
                
                confirmAction = { [passwordCopy, newAccountCopy, newEmailCodeCopy, smsCodeCopy] in
                    Task {
                        do {
                            try await detailManager.submitChangeAccount(
                                password: passwordCopy,
                                newAccount: newAccountCopy,
                                newEmailCode: newEmailCodeCopy,
                                smsCode: smsCodeCopy,
                                oldEmailCode: nil
                            )
                            showSuccessToast()
                            dismissSheet()
                        } catch let flowErr as TDSettingsDetailManager.TDAccountChangeFlowError {
                            handleChangeWithPhoneError(flowErr)
                        } catch {
                            changeNewEmailError = error.localizedDescription
                            $changeNewEmailShake.triggerShake()
                        }
                    }
                }
                showChangeAlert = true


            }
        }
    }

    /// 已经修改过账号：锁定界面
    private var lockedView: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("settings.account.change.title".localized)
                .font(.system(size: 16))
                .foregroundColor(themeManager.titleTextColor)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text("settings.account.change.locked.tip".localized)
                .foregroundColor(themeManager.titleTextColor)
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            Text("settings.account.change.locked.contact".localized)
                .foregroundColor(themeManager.descriptionTextColor)
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    // MARK: - 复用标题
    private var headerChangeTitle: some View {
        VStack(spacing: 8) {
            Text("settings.account.change.title".localized)
                .font(.system(size: 16))
                .foregroundColor(themeManager.titleTextColor)
            Text("settings.account.change.notice".localized)
                .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                .font(.system(size: 15))
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    // MARK: - 按钮封装
    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(themeManager.color(level: 6))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
        .padding(.top, 6)
    }
    
    // MARK: - 密码输入（可切换明/暗文，无额外背景）
    @ViewBuilder
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

    // MARK: - Toast 辅助
    private func showSuccessToast(_ message: String = "settings.account.phone.code.success".localized) {
        toastMessage = message
        showToast = true
    }
    
    // MARK: - 错误分发
    private func handleBindAccountError(_ error: TDSettingsDetailManager.TDAccountChangeFlowError) {
        switch error {
        case .password(let msg):
            bindPasswordError = msg; $bindPasswordShake.triggerShake()
        case .email(let msg), .general(let msg):
            bindEmailError = msg; $bindEmailShake.triggerShake()
        default:
            bindEmailError = (error as NSError).localizedDescription; $bindEmailShake.triggerShake()
        }
    }
    
    private func handleChangeNoPhoneError(_ error: TDSettingsDetailManager.TDAccountChangeFlowError) {
        switch error {
        case .password(let msg):
            changePasswordError = msg; $changePasswordShake.triggerShake()
        case .smsCode(let msg), .oldEmailCode(let msg):
            changeEmailCodeError = msg; $changeEmailCodeShake.triggerShake()
        case .newEmailCode(let msg):
            changeNewEmailCodeError = msg; $changeNewEmailCodeShake.triggerShake()
        case .email(let msg):
            changeNewEmailError = msg; $changeNewEmailShake.triggerShake()
        case .general(let msg):
            changeNewEmailError = msg; $changeNewEmailShake.triggerShake()
        }
    }
    
    private func handleChangeWithPhoneError(_ error: TDSettingsDetailManager.TDAccountChangeFlowError) {
        switch error {
        case .password(let msg):
            changePasswordError = msg; $changePasswordShake.triggerShake()
        case .smsCode(let msg):
            changePhoneCodeError = msg; $changePhoneCodeShake.triggerShake()
        case .newEmailCode(let msg):
            changeNewEmailCodeError = msg; $changeNewEmailCodeShake.triggerShake()
        case .email(let msg):
            changeNewEmailError = msg; $changeNewEmailShake.triggerShake()
        case .oldEmailCode(let msg):
            changeNewEmailError = msg; $changeNewEmailShake.triggerShake()
        case .general(let msg):
            changeNewEmailError = msg; $changeNewEmailShake.triggerShake()
        }
    }

}



