//
//  TDForgetPasswordViewModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2026/7/1.
//

import SwiftUI

// MARK: - 找回密码上下文（用于跨窗口传值）
/// 通过 openWindow(id:value:) 传递给忘记密码窗口
struct TDForgetPasswordContext: Codable, Hashable {
    /// 登录账号（可能是邮箱格式）
    var accountStr: String
}

// MARK: - 找回密码步骤
enum TDForgetPasswordStep {
    /// 加载中：正在查询账号绑定的找回方式
    case loading
    /// 第一步：选择找回方式（手机 / 邮箱）
    case selectMethod
    /// 第二步：输入验证码 + 新密码
    case resetPassword
}

// MARK: - 找回方式
enum TDRecoveryMethod {
    /// 通过手机号找回
    case phone
    /// 通过邮箱账号找回
    case email
}

// MARK: - TDForgetPasswordViewModel
final class TDForgetPasswordViewModel: ObservableObject {

    // MARK: - 当前步骤
    /// 当前所处步骤
    @Published var currentStep: TDForgetPasswordStep = .loading

    // MARK: - 账号信息（从登录页传入）
    /// 用户在登录框输入的账号字符串
    var accountStr: String = ""

    // MARK: - 服务端返回的找回信息
    /// 脱敏手机号（如 "181****5257"），服务端返回，为空表示未绑定
    @Published var maskedPhone: String = ""
    /// 邮箱账号，服务端返回，为空表示未绑定或账号非邮箱格式
    @Published var maskedEmail: String = ""

    // MARK: - 第一步：选择方式
    /// 当前选中的找回方式
    @Published var selectedMethod: TDRecoveryMethod = .phone
    /// 手机号是否可用（服务端返回了有效的脱敏手机号）
    var isPhoneAvailable: Bool { !maskedPhone.isEmpty }
    /// 邮箱是否可用（服务端返回了有效的邮箱）
    var isEmailAvailable: Bool { !maskedEmail.isEmpty }

    // MARK: - 第二步：表单输入
    /// 手机号（用户自行输入完整号码以核验身份）
    @Published var phone: String = ""
    /// 验证码（SMS / 邮箱）
    @Published var code: String = ""
    /// 新密码
    @Published var newPassword: String = ""

    // MARK: - 验证码发送状态
    /// 是否正在请求发送验证码（避免重复请求）
    @Published var isSendingCode: Bool = false

    // MARK: - 加载 & 结果
    /// 是否正在提交重置请求
    @Published var isResetting: Bool = false
    /// 是否重置成功（成功后提示并关闭窗口）
    @Published var isSuccess: Bool = false

    // MARK: - 错误信息
    /// 手机号输入错误提示
    @Published var phoneError: String = ""
    /// 验证码错误提示
    @Published var codeError: String = ""
    /// 新密码错误提示
    @Published var passwordError: String = ""

    // MARK: - 初始化
    /// 使用传入的账号上下文初始化，并自动拉取找回密码信息
    init(context: TDForgetPasswordContext? = nil) {
        if let context = context {
            accountStr = context.accountStr
        }
        // 窗口出现后立即查询账号绑定的找回方式
        fetchRecoveryInfo()
    }

    // MARK: - 拉取账号找回信息
    /// 调用 todoList/queryAccountExist 接口，获取脱敏手机号和邮箱，用于展示可用的找回方式
    func fetchRecoveryInfo() {
        let trimmedAccount = accountStr.trimmingCharacters(in: .whitespaces)
        guard !trimmedAccount.isEmpty else {
            // 账号为空，直接展示空状态（两个方式均不可用）
            currentStep = .selectMethod
            return
        }
        currentStep = .loading
        Task { @MainActor in
            do {
                let info = try await TDLoginAPI.shared.queryAccountExist(account: trimmedAccount)

                // phoneNumber 为 "0" 或空表示未绑定手机（服务端约定 "0" = 无）
                let phone = info.phoneNumber ?? ""
                maskedPhone = (phone == "0" || phone.isEmpty) ? "" : phone

                // 邮箱是否可用只看用户输入的账号是否是邮箱格式（与 iOS 逻辑一致）
                // 不依赖服务端返回：只要用户输入的 accountStr 是邮箱，就直接展示
                maskedEmail = trimmedAccount.isValidEmail ? trimmedAccount : ""

                // 默认选优先有效方式：有手机选手机，否则选邮箱
                selectedMethod = isPhoneAvailable ? .phone : .email
            } catch {
                // 接口失败（含账号不存在）时展示选择页，两个方式均灰显
                maskedPhone = ""
                maskedEmail = ""
            }
            currentStep = .selectMethod
        }
    }

    // MARK: - 第一步：确定找回方式
    /// 点击"确定"按钮，进入第二步
    func confirmMethod() {
        currentStep = .resetPassword
    }

    // MARK: - 第二步：发送验证码
    /// 校验输入并触发发送，返回 true 表示校验通过（TDFormTextFieldWithCountdown 据此启动倒计时）
    func sendCode() -> Bool {
        // 手机方式额外校验手机号格式
        if selectedMethod == .phone {
            guard validatePhone() else { return false }
        }
        // 校验通过，异步发送（倒计时由组件自身管理）
        guard !isSendingCode else { return false }
        isSendingCode = true
        Task { @MainActor in
            do {
                if selectedMethod == .phone {
                    try await TDLoginAPI.shared.getForgetPasswordSmsCode(
                        phone: phone.trimmingCharacters(in: .whitespaces)
                    )
                } else {
                    try await TDLoginAPI.shared.getForgetPasswordEmailCode(email: accountStr)
                }
                TDToastCenter.shared.show(
                    NSLocalizedString("forget.code.sent", comment: ""),
                    type: .success,
                    position: .bottom
                )
            } catch {
                TDToastCenter.shared.show(error.localizedDescription, type: .error, position: .bottom)
            }
            isSendingCode = false
        }
        return true
    }

    // MARK: - 第二步：提交重置
    /// 提交新密码设置请求
    func submitReset(onSuccess: @escaping () -> Void) {
        guard validateForm() else { return }
        isResetting = true
        Task { @MainActor in
            do {
                if selectedMethod == .phone {
                    try await TDLoginAPI.shared.resetPasswordByPhone(
                        phone: phone.trimmingCharacters(in: .whitespaces),
                        code: code.trimmingCharacters(in: .whitespaces),
                        newPassword: newPassword
                    )
                } else {
                    try await TDLoginAPI.shared.resetPasswordByEmail(
                        email: accountStr.trimmingCharacters(in: .whitespaces),
                        code: code.trimmingCharacters(in: .whitespaces),
                        newPassword: newPassword
                    )
                }
                isSuccess = true
                TDToastCenter.shared.show(
                    NSLocalizedString("forget.reset.success", comment: ""),
                    type: .success,
                    position: .bottom
                )
                // 延迟关闭窗口，让用户看到成功提示
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onSuccess()
                }
            } catch {
                TDToastCenter.shared.show(error.localizedDescription, type: .error, position: .bottom)
            }
            isResetting = false
        }
    }

    // MARK: - 私有：手机号格式校验
    @discardableResult
    private func validatePhone() -> Bool {
        let trimmed = phone.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            phoneError = NSLocalizedString("forget.error.phone.empty", comment: "")
            return false
        }
        if trimmed.count != 11 {
            phoneError = NSLocalizedString("forget.error.phone.invalid", comment: "")
            return false
        }
        phoneError = ""
        return true
    }

    // MARK: - 私有：提交前整体校验
    @discardableResult
    private func validateForm() -> Bool {
        var valid = true
        if selectedMethod == .phone {
            if !validatePhone() { valid = false }
        }
        let codeVal = code.trimmingCharacters(in: .whitespaces)
        if codeVal.isEmpty {
            codeError = NSLocalizedString("forget.error.code.empty", comment: "")
            valid = false
        } else {
            codeError = ""
        }
        if newPassword.isEmpty {
            passwordError = NSLocalizedString("forget.error.password.empty", comment: "")
            valid = false
        } else {
            passwordError = ""
        }
        return valid
    }

    deinit { }
}

// MARK: - String 邮箱格式判断（扩展）
extension String {
    /// 是否符合邮箱格式
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }
}
