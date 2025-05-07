//
//  TDLoginViewModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI


@MainActor
class TDLoginViewModel: ObservableObject {
    // MARK: - 登录类型枚举
    enum TDLoginType: Int, CaseIterable {
        case account   // 账号密码登录
        case phone      // 手机验证码登录
        case qrcode     // 扫码登录
    }
    //  注册或者登录
    enum TDLoginState {
        case login
        case register
    }
    
    @Published var currentType: TDLoginType = .account
    // 视图状态
    @Published var loginState: TDLoginState = .login
    
    // 账号密码登录注册
    @AppStorage("LoninViewUserAccount") var userAccount = ""
    @Published var password = ""
    
    // 手机号登录
    @Published var phone = ""
    @Published var smsCode = ""
    @Published var countDown: Int = 0
    private var countDownTimer: Timer?
    private let countDownDuration = 60  // 固定60秒
    
//    // 二维码登录
//    @Published var qrCodeImage: NSImage?
//    @Published var qrStatus: TDQRCodeStatus = .waiting
//    
//    private var qrCode: String?
//    private var statusTimer: Timer?
//    private let pollingInterval: TimeInterval = 2.0

    
    @Published private var hasSentCode = false  // 添加一个标记，记录是否发送过验证码
    // 底部是否点击同意协议按钮
    @AppStorage("LoninViewAgreedToTerms") var agreedToTerms = false
    
    // 输入字段错误提示
    @Published var accountError = ""
    @Published var passwordError = ""
    @Published var phoneError = ""
    @Published var smsCodeError = ""
    @Published var qrCodeError = ""

    // 网络请求错误提示
    @Published var showErrorToast = false
    @Published var toastMessage = ""
    
    // 区分不同的 loading 状态
    @Published var isLoginLoading = false      // 登录loading
    @Published var isSendingSms = false        // 发送验证码loading
    @Published var isQRLoading = false         // 二维码loading

    // MARK: - 输入验证
    // 提取协议检查方法
    private func checkProtocol() -> Bool {
        guard agreedToTerms else {
            toastMessage = "请阅读并同意用户协议"
            showErrorToast = true
            return false
        }
        return true
    }
    // 验证账号
    private func validateAccount() -> Bool {
        if userAccount.isEmpty {
            accountError = "请输入账号"
            return false
        }
        if userAccount.count < 6 {
            accountError = "账号长度不能少于6位"
            return false
        }
        accountError = ""
        return true
    }
    
    // 验证密码
    private func validatePassword() -> Bool {
        if password.isEmpty {
            passwordError = "请输入密码"
            return false
        }
        if password.count < 6 {
            passwordError = "密码长度不能少于6位"
            return false
        }
        passwordError = ""
        return true
    }
    
    // 验证手机号
    private func validatePhone() -> Bool {
        if phone.isEmpty {
            phoneError = "请输入手机号"
            return false
        }
        if phone.count != 11 {
            phoneError = "请输入11位手机号"
            return false
        }
        // 可以添加更严格的手机号格式验证
        let phoneRegex = "^1[3-9]\\d{9}$"
        if !NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: phone) {
            phoneError = "请输入正确的手机号"
            return false
        }
        phoneError = ""
        return true
    }
    
    // 验证验证码
    private func validateSmsCode() -> Bool {
        if smsCode.isEmpty {
            smsCodeError = "请输入验证码"
            return false
        }
        if smsCode.count != 6 {
            smsCodeError = "请输入6位验证码"
            return false
        }
        smsCodeError = ""
        return true
    }
    
    // MARK: - 登录方法
    
    // 账号密码登录
    func loginWithAccount() {
        // 检查协议
        guard checkProtocol() else { return }
        // 验证输入
        guard validateAccount() && validatePassword() else { return }
        Task {
            isLoginLoading = true
            do {
                let userModel = try await TDLoginAPI.shared.loginWithAccount(userAccount, password: password)

                handleLoginSuccess(userModel)
            } catch let error as TDNetworkError {
                showErrorToast = true
                toastMessage = error.errorMessage
            } catch {
                showErrorToast = true
                toastMessage = "登录失败：\(error.localizedDescription)"
            }
            isLoginLoading = false
        }
    }
    
    // MARK: - 账号注册
    func registerAccount(_ account: String, password: String) async {
        // 检查协议
        guard checkProtocol() else { return }
        // 验证输入
        guard validateAccount() && validatePassword() else { return }

        Task {
            isLoginLoading = true
            do {
                let userModel = try await TDLoginAPI.shared.registerAccount(userAccount, password: password)
                handleLoginSuccess(userModel)
            } catch {
                showErrorToast = true
                toastMessage = error.localizedDescription
            }
            isLoginLoading = false
        }
    }

    // 手机号登录
    func loginWithPhone() {
        // 检查协议
        guard checkProtocol() else { return }
        // 验证输入
        guard validatePhone() && validateSmsCode() else { return }
        
        Task {
            isLoginLoading = true
            do {
//                let user = try await TDLoginAPI.login(phone: phone, smsCode: smsCode)
                let userModel = try await TDLoginAPI.shared.loginWithPhone(phone, smsCode: smsCode)

                handleLoginSuccess(userModel)
            } catch {
                showErrorToast = true
                toastMessage = error.localizedDescription
            }
            isLoginLoading = false
        }
    }
    // 发送验证码
    func sendSmsCode() {
        // 先验证手机号
        guard validatePhone() else { return }
        Task {
            isSendingSms = true
            do {
                try await TDLoginAPI.shared.getSmsCode(phone: phone)
                startCountDown()  // 不再使用服务器返回的时间
                // 发送成功提示
                showErrorToast = true
                hasSentCode = true  // 设置已发送标记
                toastMessage = "验证码已发送"
            } catch {
                showErrorToast = true
                toastMessage = error.localizedDescription
            }
            isSendingSms = false
        }
    }
    
    
    
//    /// 获取二维码
//    func startQRCodeLogin() {
//        Task {
//            do {
//                // 1. 获取二维码
//                qrCode = try await TDLoginAPI.getQRCode()
//                await MainActor.run {
//                    // 生成二维码图片
//                    qrCodeImage = generateQRCode(from: qrCode ?? "")
//                    // 开始轮询状态
//                    startPollingStatus()
//                }
//            } catch {
//                await MainActor.run {
//                    qrCodeError = error.localizedDescription
//                }
//            }
//        }
//    }
//    
//    /// 开始检测二维码生效时间
//    @MainActor
//    private func startPollingStatus() {
//        stopPollingStatus()
//        statusTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
//            Task { @MainActor in
//                await self?.checkStatus()
//            }
//        }
//    }
//    
//    /// 检测二维码状态
//    @MainActor
//    private func checkStatus() async {
//        guard let qrCode = qrCode else { return }
//        
//        do {
//            let status = try await TDLoginAPI.checkQRCodeStatus(qrCode: qrCode)
//            self.qrStatus = status
//            
//            switch status {
//            case .confirmed:
//                // 登录成功，停止轮询
//                stopPollingStatus()
//                await qrPhoneSureBtnSucess()
//            case .invalid, .cancelled:
//                // 二维码失效或取消，停止轮询
//                stopPollingStatus()
//            default:
//                break
//            }
//        } catch {
//            qrCodeError = error.localizedDescription
//        }
//    }
//    
//    
//    /// 手机确认二维码登录成功
//    private func qrPhoneSureBtnSucess() async{
//        guard let qrCode = qrCode else { return }
//        Task {
//            isLoginLoading = true
//            do {
//                let user = try await TDLoginAPI.confirmQRCodeLogin(qrCode: qrCode)
//                handleLoginSuccess(user)
//            } catch {
//                showErrorToast = true
//                toastMessage = error.localizedDescription
//            }
//            isLoginLoading = true
//        }
//    }
    
    // MARK: - 退出登录
    func logout() {
        Task {
            do {
                clearInputs()
                resetLoginState()
                try await TDLoginAPI.shared.logout()
                // 处理登出成功后的界面跳转等
            } catch let error as TDNetworkError {
                // 处理网络错误
                switch error {
                case .networkTimeout:
                    // 处理超时
                    showErrorToast = true
                    toastMessage = error.localizedDescription
                    break
                default:
                    // 处理其他错误
                    showErrorToast = true
                    toastMessage = error.localizedDescription
                    break
                }
            } catch {
                // 处理其他错误
                showErrorToast = true
                toastMessage = "退出失败"
            }
        }
    }

//    func logout() async {
//        do {
//            isLoginLoading = true
//            
//            // 调用退出登录接口
//            try await TDLoginAPI.lo()
//            
//            // 清除用户信息
//            TDUserManager.shared.clearUser()
//            
//            
//            
//            // 重置输入和状态
//            clearInputs()
//            resetLoginState()
//            
//        } catch {
//            if let networkError = error as? TDNetworkManager.TDNetworkError {
//                showErrorToast = true
//                toastMessage = networkError.errorDescription ?? "退出失败"
//            } else {
//                showErrorToast = true
//                toastMessage = error.localizedDescription
//            }
//        }
//        
//        isLoginLoading = false
//    }

//    @MainActor
//    private func stopPollingStatus() {
//        statusTimer?.invalidate()
//        statusTimer = nil
//    }

    
    // MARK: - Private Methods
    private func handleLoginSuccess(_ user: TDUserModel) {
        // 保存用户信息
        TDUserManager.shared.saveUser(user)
        // 登录成 功后获取分类数据
        Task {
//            await TDCategoryManager.shared.fetchCategories()
        }
        // 清理状态
        clearInputs()
    }
    
    // 重置登录状态
    private func resetLoginState() {
        currentType = .account
        loginState = .login
        accountError = ""
        passwordError = ""
        phoneError = ""
        smsCodeError = ""
        qrCodeError = ""
        showErrorToast = false
        toastMessage = ""
//        stopPollingStatus()
    }

    private func clearInputs() {
        password = ""
        phone = ""
        smsCode = ""
//        qrCode = nil
//        qrCodeImage = nil
//        qrStatus = .waiting
        countDown = 0
        hasSentCode = false
        countDownTimer?.invalidate()
        countDownTimer = nil
    }
    
    
    // 验证码按钮是否可点击
    var canSendSms: Bool {
        if countDown > 0 { return false }
        if isSendingSms { return false }
        return true
    }
    // 登录按钮是否可点击
    var canLogin: Bool {
        !isLoginLoading
    }
    // 验证码按钮文案
    var smsButtonTitle: String {
        if isSendingSms {
            return ""  // loading 状态下不显示文字
        }
        if countDown > 0 {
            return "\(countDown)s"
        }
        return hasSentCode ? "重新获取验证码" : "获取验证码"
    }
    private func startCountDown() {
        // 先清除可能存在的计时器
        countDownTimer?.invalidate()
        countDown = countDownDuration  // 使用固定的60秒
        
        countDownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.countDown > 0 {
                    self.countDown -= 1
                } else {
                    self.countDownTimer?.invalidate()
                }
            }
        }
    }
    
    
    /// 生成二维码图片
    /// - Parameter string: 二维码链接
    /// - Returns: 返回生成的二维码图片
//    private func generateQRCode(from string: String) -> NSImage? {
//        guard let data = string.data(using: .utf8) else { return nil }
//        
//        if let filter = CIFilter(name: "CIQRCodeGenerator") {
//            filter.setValue(data, forKey: "inputMessage")
//            filter.setValue("H", forKey: "inputCorrectionLevel")
//            
//            if let output = filter.outputImage {
//                let transform = CGAffineTransform(scaleX: 10, y: 10)
//                let scaledOutput = output.transformed(by: transform)
//                
//                let rep = NSCIImageRep(ciImage: scaledOutput)
//                let nsImage = NSImage(size: rep.size)
//                nsImage.addRepresentation(rep)
//                return nsImage
//            }
//        }
//        return nil
//    }
    
    deinit {
        countDownTimer?.invalidate()
        //二维码失效或取消，停止轮询
//        statusTimer?.invalidate()
//        statusTimer = nil
    }
    
    
    // MARK: - 数据同步
    private func syncUserData() async {
        // 同步分类数据
        let sliderBarViewModel = TDMainViewModel.shared
        
        // 登录场景：直接从服务器获取数据并同步
        await sliderBarViewModel.syncAfterLogin()
    }
}
