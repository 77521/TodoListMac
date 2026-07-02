////
////  TDLoginViewModel.swift
////  TodoMacRepertorie
////
////  Created by 孬孬 on 2024/12/28.
////
//
//import Foundation
//import SwiftUI
//
//
//@MainActor
//class TDLoginViewModel: ObservableObject {
//    // MARK: - 登录类型枚举
//    enum TDLoginType: Int, CaseIterable {
//        case account   // 账号密码登录
//        case phone      // 手机验证码登录
//        case qrcode     // 扫码登录
//    }
//    //  注册或者登录
//    enum TDLoginState {
//        case login
//        case register
//    }
//    
//    @Published var currentType: TDLoginType = .account
//    // 视图状态
//    @Published var loginState: TDLoginState = .login
//    
//    // 账号密码登录注册
//    @AppStorage("LoninViewUserAccount") var userAccount = ""
//    @Published var password = ""
//    
//    // 手机号登录
//    @Published var phone = ""
//    @Published var smsCode = ""
//    @Published var countDown: Int = 0
//    private var countDownTimer: Timer?
//    private let countDownDuration = 60  // 固定60秒
//    
////    // 二维码登录
////    @Published var qrCodeImage: NSImage?
////    @Published var qrStatus: TDQRCodeStatus = .waiting
////    
////    private var qrCode: String?
////    private var statusTimer: Timer?
////    private let pollingInterval: TimeInterval = 2.0
//
//    
//    @Published private var hasSentCode = false  // 添加一个标记，记录是否发送过验证码
//    // 底部是否点击同意协议按钮
//    @AppStorage("LoninViewAgreedToTerms") var agreedToTerms = false
//    
//    // 输入字段错误提示
//    @Published var accountError = ""
//    @Published var passwordError = ""
//    @Published var phoneError = ""
//    @Published var smsCodeError = ""
//    @Published var qrCodeError = ""
//
//    // 网络请求错误提示
//    @Published var showErrorToast = false
//    @Published var toastMessage = ""
//    
//    // 区分不同的 loading 状态
//    @Published var isLoginLoading = false      // 登录loading
//    @Published var isSendingSms = false        // 发送验证码loading
//    @Published var isQRLoading = false         // 二维码loading
//
//    // MARK: - 输入验证
//    // 提取协议检查方法
//    private func checkProtocol() -> Bool {
//        guard agreedToTerms else {
//            toastMessage = "请阅读并同意用户协议"
//            showErrorToast = true
//            return false
//        }
//        return true
//    }
//    // 验证账号
//    private func validateAccount() -> Bool {
//        if userAccount.isEmpty {
//            accountError = "请输入账号"
//            return false
//        }
//        if userAccount.count < 6 {
//            accountError = "账号长度不能少于6位"
//            return false
//        }
//        accountError = ""
//        return true
//    }
//    
//    // 验证密码
//    private func validatePassword() -> Bool {
//        if password.isEmpty {
//            passwordError = "请输入密码"
//            return false
//        }
//        if password.count < 6 {
//            passwordError = "密码长度不能少于6位"
//            return false
//        }
//        passwordError = ""
//        return true
//    }
//    
//    // 验证手机号
//    private func validatePhone() -> Bool {
//        if phone.isEmpty {
//            phoneError = "请输入手机号"
//            return false
//        }
//        if phone.count != 11 {
//            phoneError = "请输入11位手机号"
//            return false
//        }
//        // 可以添加更严格的手机号格式验证
//        let phoneRegex = "^1[3-9]\\d{9}$"
//        if !NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: phone) {
//            phoneError = "请输入正确的手机号"
//            return false
//        }
//        phoneError = ""
//        return true
//    }
//    
//    // 验证验证码
//    private func validateSmsCode() -> Bool {
//        if smsCode.isEmpty {
//            smsCodeError = "请输入验证码"
//            return false
//        }
//        if smsCode.count != 4 {
//            smsCodeError = "请输入4位验证码"
//            return false
//        }
//        smsCodeError = ""
//        return true
//    }
//    
//    // MARK: - 登录方法
//    
//    // 账号密码登录
//    func loginWithAccount() {
//        // 检查协议
//        guard checkProtocol() else { return }
//        // 验证输入
//        guard validateAccount() && validatePassword() else { return }
//        Task {
//            isLoginLoading = true
//            do {
//                let userModel = try await TDLoginAPI.shared.loginWithAccount(userAccount, password: password)
//
//                handleLoginSuccess(userModel)
//            } catch let error as TDNetworkError {
//                showErrorToast = true
//                toastMessage = error.errorMessage
//            } catch {
//                showErrorToast = true
//                toastMessage = "登录失败：\(error.localizedDescription)"
//            }
//            isLoginLoading = false
//        }
//    }
//    
//    // MARK: - 账号注册
//    func registerAccount(_ account: String, password: String) async {
//        // 检查协议
//        guard checkProtocol() else { return }
//        // 验证输入
//        guard validateAccount() && validatePassword() else { return }
//
//        Task {
//            isLoginLoading = true
//            do {
//                let userModel = try await TDLoginAPI.shared.registerAccount(userAccount, password: password)
//                handleLoginSuccess(userModel)
//            } catch {
//                showErrorToast = true
//                toastMessage = error.localizedDescription
//            }
//            isLoginLoading = false
//        }
//    }
//
//    // 手机号登录
//    func loginWithPhone() {
//        // 检查协议
//        guard checkProtocol() else { return }
//        // 验证输入
//        guard validatePhone() && validateSmsCode() else { return }
//        
//        Task {
//            isLoginLoading = true
//            do {
////                let user = try await TDLoginAPI.login(phone: phone, smsCode: smsCode)
//                let userModel = try await TDLoginAPI.shared.loginWithPhone(phone, smsCode: smsCode)
//
//                handleLoginSuccess(userModel)
//            } catch {
//                showErrorToast = true
//                toastMessage = error.localizedDescription
//            }
//            isLoginLoading = false
//        }
//    }
//    // 发送验证码
//    func sendSmsCode() {
//        // 先验证手机号
//        guard validatePhone() else { return }
//        Task {
//            isSendingSms = true
//            do {
//                try await TDLoginAPI.shared.getSmsCode(phone: phone)
//                startCountDown()  // 不再使用服务器返回的时间
//                // 发送成功提示
//                showErrorToast = true
//                hasSentCode = true  // 设置已发送标记
//                toastMessage = "验证码已发送"
//            } catch {
//                showErrorToast = true
//                toastMessage = error.localizedDescription
//            }
//            isSendingSms = false
//        }
//    }
//    
//    
//    
////    /// 获取二维码
////    func startQRCodeLogin() {
////        Task {
////            do {
////                // 1. 获取二维码
////                qrCode = try await TDLoginAPI.getQRCode()
////                await MainActor.run {
////                    // 生成二维码图片
////                    qrCodeImage = generateQRCode(from: qrCode ?? "")
////                    // 开始轮询状态
////                    startPollingStatus()
////                }
////            } catch {
////                await MainActor.run {
////                    qrCodeError = error.localizedDescription
////                }
////            }
////        }
////    }
////    
////    /// 开始检测二维码生效时间
////    @MainActor
////    private func startPollingStatus() {
////        stopPollingStatus()
////        statusTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
////            Task { @MainActor in
////                await self?.checkStatus()
////            }
////        }
////    }
////    
////    /// 检测二维码状态
////    @MainActor
////    private func checkStatus() async {
////        guard let qrCode = qrCode else { return }
////        
////        do {
////            let status = try await TDLoginAPI.checkQRCodeStatus(qrCode: qrCode)
////            self.qrStatus = status
////            
////            switch status {
////            case .confirmed:
////                // 登录成功，停止轮询
////                stopPollingStatus()
////                await qrPhoneSureBtnSucess()
////            case .invalid, .cancelled:
////                // 二维码失效或取消，停止轮询
////                stopPollingStatus()
////            default:
////                break
////            }
////        } catch {
////            qrCodeError = error.localizedDescription
////        }
////    }
////    
////    
////    /// 手机确认二维码登录成功
////    private func qrPhoneSureBtnSucess() async{
////        guard let qrCode = qrCode else { return }
////        Task {
////            isLoginLoading = true
////            do {
////                let user = try await TDLoginAPI.confirmQRCodeLogin(qrCode: qrCode)
////                handleLoginSuccess(user)
////            } catch {
////                showErrorToast = true
////                toastMessage = error.localizedDescription
////            }
////            isLoginLoading = true
////        }
////    }
//    
//    // MARK: - 退出登录
//    func logout() {
//        Task {
//            do {
//                clearInputs()
//                resetLoginState()
//                try await TDLoginAPI.shared.logout()
//                // 处理登出成功后的界面跳转等
//            } catch let error as TDNetworkError {
//                // 处理网络错误
//                switch error {
//                case .networkTimeout:
//                    // 处理超时
//                    showErrorToast = true
//                    toastMessage = error.localizedDescription
//                    break
//                default:
//                    // 处理其他错误
//                    showErrorToast = true
//                    toastMessage = error.localizedDescription
//                    break
//                }
//            } catch {
//                // 处理其他错误
//                showErrorToast = true
//                toastMessage = "退出失败"
//            }
//        }
//    }
//
////    func logout() async {
////        do {
////            isLoginLoading = true
////            
////            // 调用退出登录接口
////            try await TDLoginAPI.lo()
////            
////            // 清除用户信息
////            TDUserManager.shared.clearUser()
////            
////            
////            
////            // 重置输入和状态
////            clearInputs()
////            resetLoginState()
////            
////        } catch {
////            if let networkError = error as? TDNetworkManager.TDNetworkError {
////                showErrorToast = true
////                toastMessage = networkError.errorDescription ?? "退出失败"
////            } else {
////                showErrorToast = true
////                toastMessage = error.localizedDescription
////            }
////        }
////        
////        isLoginLoading = false
////    }
//
////    @MainActor
////    private func stopPollingStatus() {
////        statusTimer?.invalidate()
////        statusTimer = nil
////    }
//
//    
//    // MARK: - Private Methods
//    private func handleLoginSuccess(_ user: TDUserModel) {
//        // 保存用户信息
//        TDUserManager.shared.saveUser(user)
//        
//        // 清理状态
//        clearInputs()
//    }
//    
//    // 重置登录状态
//    private func resetLoginState() {
//        currentType = .account
//        loginState = .login
//        accountError = ""
//        passwordError = ""
//        phoneError = ""
//        smsCodeError = ""
//        qrCodeError = ""
//        showErrorToast = false
//        toastMessage = ""
////        stopPollingStatus()
//    }
//
//    private func clearInputs() {
//        password = ""
//        phone = ""
//        smsCode = ""
////        qrCode = nil
////        qrCodeImage = nil
////        qrStatus = .waiting
//        countDown = 0
//        hasSentCode = false
//        countDownTimer?.invalidate()
//        countDownTimer = nil
//    }
//    
//    
//    // 验证码按钮是否可点击
//    var canSendSms: Bool {
//        if countDown > 0 { return false }
//        if isSendingSms { return false }
//        return true
//    }
//    // 登录按钮是否可点击
//    var canLogin: Bool {
//        !isLoginLoading
//    }
//    // 验证码按钮文案
//    var smsButtonTitle: String {
//        if isSendingSms {
//            return ""  // loading 状态下不显示文字
//        }
//        if countDown > 0 {
//            return "\(countDown)s"
//        }
//        return hasSentCode ? "重新获取验证码" : "获取验证码"
//    }
//    private func startCountDown() {
//        // 先清除可能存在的计时器
//        countDownTimer?.invalidate()
//        countDown = countDownDuration  // 使用固定的60秒
//        
//        countDownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
//            Task { @MainActor [weak self] in
//                guard let self = self else { return }
//                if self.countDown > 0 {
//                    self.countDown -= 1
//                } else {
//                    self.countDownTimer?.invalidate()
//                }
//            }
//        }
//    }
//    
//    
//    /// 生成二维码图片
//    /// - Parameter string: 二维码链接
//    /// - Returns: 返回生成的二维码图片
////    private func generateQRCode(from string: String) -> NSImage? {
////        guard let data = string.data(using: .utf8) else { return nil }
////        
////        if let filter = CIFilter(name: "CIQRCodeGenerator") {
////            filter.setValue(data, forKey: "inputMessage")
////            filter.setValue("H", forKey: "inputCorrectionLevel")
////            
////            if let output = filter.outputImage {
////                let transform = CGAffineTransform(scaleX: 10, y: 10)
////                let scaledOutput = output.transformed(by: transform)
////                
////                let rep = NSCIImageRep(ciImage: scaledOutput)
////                let nsImage = NSImage(size: rep.size)
////                nsImage.addRepresentation(rep)
////                return nsImage
////            }
////        }
////        return nil
////    }
//    
//    deinit {
//        countDownTimer?.invalidate()
//        //二维码失效或取消，停止轮询
////        statusTimer?.invalidate()
////        statusTimer = nil
//    }
//    
//    
//}



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
    
    // MARK: - 二维码登录状态
    /// 当前二维码视图展示状态
    @Published var qrCodeViewStatus: TDQrCodeViewStatus = .loading
    /// 本地生成的二维码图片（由 qrCode 字符串渲染）
    @Published var qrCodeImage: NSImage? = nil
    /// 从接口获取到的二维码 ID，用于后续轮询
    private var qrCodeId: Int? = nil
    /// 从接口获取到的二维码代码串，用于后续轮询与生成图片
    private var qrCodeStr: String? = nil
    /// 二维码轮询任务句柄，切换 Tab 时取消
    private var qrPollingTask: Task<Void, Never>? = nil

    
    @Published private var hasSentCode = false  // 添加一个标记，记录是否发送过验证码
    
    // MARK: - 协议勾选（直接读 UserDefaults，不持有 @AppStorage）
    // 注意：agreedToTerms 改由 TDLoginRuleView 自持有 @AppStorage，
    // 避免勾选时触发 objectWillChange → TDLoginView 全量重渲染 → 背景闪白
    private var agreedToTerms: Bool {
        UserDefaults.standard.bool(forKey: "LoninViewAgreedToTerms")
    }
    
    // 输入字段错误提示
    @Published var accountError = ""
    @Published var passwordError = ""
    @Published var phoneError = ""
    @Published var smsCodeError = ""
    @Published var qrCodeError = ""

    // 区分不同的 loading 状态
    @Published var isLoginLoading = false      // 登录loading
    @Published var isSendingSms = false        // 发送验证码loading
    @Published var isQRLoading = false         // 二维码loading

    // MARK: - 输入验证
    // 提取协议检查方法
    private func checkProtocol() -> Bool {
        guard agreedToTerms else {
            TDToastCenter.shared.show("请阅读并同意用户协议", type: .info, position: .bottom)
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
        if smsCode.count != 4 {
            smsCodeError = "请输入4位验证码"
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
                TDToastCenter.shared.show(error.errorMessage, type: .error, position: .bottom)
            } catch {
                TDToastCenter.shared.show("登录失败：\(error.localizedDescription)", type: .error, position: .bottom)
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
                TDToastCenter.shared.show(error.localizedDescription, type: .error, position: .bottom)
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
                TDToastCenter.shared.show(error.localizedDescription, type: .error, position: .bottom)
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
                hasSentCode = true  // 设置已发送标记
                TDToastCenter.shared.show("验证码已发送", type: .success, position: .bottom)
            } catch {
                TDToastCenter.shared.show(error.localizedDescription, type: .error, position: .bottom)
            }
            isSendingSms = false
        }
    }
    
    
    
    // MARK: - 扫码登录：启动

    /// 切换到扫一扫 Tab 时调用，获取二维码并启动轮询
    func startQRCodeLogin() {
        // 取消已有轮询，重置状态
        stopQRCodeLogin()
        qrCodeViewStatus = .loading
        qrCodeImage = nil
        qrCodeId = nil
        qrCodeStr = nil

        qrPollingTask = Task {
            do {
                // 第一步：请求获取二维码
                let result = try await TDLoginAPI.shared.getTodoQrCode()
                guard !Task.isCancelled else { return }

                // 保存二维码标识，用于后续轮询
                qrCodeId  = result.id
                qrCodeStr = result.qrCode

                // 生成本地二维码图片
                if let codeStr = result.qrCode {
                    qrCodeImage = generateQRCodeImage(from: codeStr)
                }
                qrCodeViewStatus = .ready

                // 第二步：持续轮询二维码验证结果（获取结果后等待5秒再轮询）
                await pollQrVerifyResult()

            } catch {
                guard !Task.isCancelled else { return }
                qrCodeViewStatus = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - 扫码登录：停止轮询

    /// 离开扫一扫 Tab 或登录成功时调用，取消后台轮询任务
    func stopQRCodeLogin() {
        qrPollingTask?.cancel()
        qrPollingTask = nil
    }

    // MARK: - 扫码登录：刷新二维码

    /// 用户主动点击刷新按钮时调用，重新获取二维码
    func refreshQRCode() {
        startQRCodeLogin()
    }

    // MARK: - 私有：轮询验证结果

    /// 每隔5秒（接口返回后）查询一次二维码验证结果
    private func pollQrVerifyResult() async {
        guard let qrId = qrCodeId, let qrStr = qrCodeStr else { return }

        while !Task.isCancelled {
            // 等待5秒再轮询（避免过于频繁请求）
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }

            do {
                let result = try await TDLoginAPI.shared.getQrVerifyResult(
                    qrCodeId: qrId,
                    qrCodeStr: qrStr
                )
                guard !Task.isCancelled else { return }

                let verifyStatus = result.qrVerify ?? TDQrVerifyStatus.waiting.rawValue

                switch verifyStatus {
                case TDQrVerifyStatus.waiting.rawValue:
                    // 判断是否已扫码（scanUserId > 0 表示已被扫描，等待手机确认）
                    if let scanId = result.scanUserId, scanId > 0 {
                        qrCodeViewStatus = .scanned
                    }
                    // 继续轮询

                case TDQrVerifyStatus.success.rawValue:
                    // 登录成功
                    qrCodeViewStatus = .success
                    if let user = result.okUser {
                        handleLoginSuccess(user)
                    } else {
                        qrCodeViewStatus = .error(String(localized: "login.qrcode.error.no_user"))
                    }
                    return // 停止轮询

                case TDQrVerifyStatus.failed.rawValue:
                    // 验证失败，提示刷新
                    qrCodeViewStatus = .expired
                    return // 停止轮询

                default:
                    break
                }

            } catch {
                guard !Task.isCancelled else { return }
                // 网络错误时不立即停止，继续轮询（可能是临时网络波动）
                // 如果想要失败即停，将下面注释去掉
                // qrCodeViewStatus = .error(error.localizedDescription)
                // return
            }
        }
    }

    // MARK: - 私有：生成二维码图片

    /// 使用 CoreImage 将字符串渲染为 NSImage 二维码图片
    /// - Parameter string: 需要编码的二维码内容字符串
    /// - Returns: 生成的 NSImage，失败返回 nil
    private func generateQRCodeImage(from string: String) -> NSImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        // 设置二维码内容和纠错级别（H=最高，保证小尺寸下也可扫描）
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }

        // 放大倍数：避免二维码模糊（每个"格子"放大10倍）
        let scale: CGFloat = 10
        let scaledImage = outputImage.transformed(
            by: CGAffineTransform(scaleX: scale, y: scale)
        )

        let rep = NSCIImageRep(ciImage: scaledImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
    
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
                    TDToastCenter.shared.show(error.localizedDescription, type: .error, position: .bottom)
                    break
                default:
                    // 处理其他错误
                    TDToastCenter.shared.show(error.localizedDescription, type: .error, position: .bottom)
                    break
                }
            } catch {
                // 处理其他错误
                TDToastCenter.shared.show("退出失败", type: .error, position: .bottom)
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
        
        // 清理状态
        clearInputs()
    }
    
    // MARK: - 重置登录状态（退出登录/切换账号时使用）
    private func resetLoginState() {
        currentType = .account
        loginState = .login
        accountError = ""
        passwordError = ""
        phoneError = ""
        smsCodeError = ""
        qrCodeError = ""
        // 停止二维码轮询
        stopQRCodeLogin()
        qrCodeViewStatus = .loading
        qrCodeImage = nil
    }

    // MARK: - 清空输入字段（登录成功后清理）
    private func clearInputs() {
        password = ""
        phone = ""
        smsCode = ""
        countDown = 0
        hasSentCode = false
        countDownTimer?.invalidate()
        countDownTimer = nil
        // 停止二维码轮询并重置图片
        stopQRCodeLogin()
        qrCodeImage = nil
        qrCodeViewStatus = .loading
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
        // 释放短信验证码倒计时
        countDownTimer?.invalidate()
        // 释放二维码轮询任务
        qrPollingTask?.cancel()
    }
    
    
}
