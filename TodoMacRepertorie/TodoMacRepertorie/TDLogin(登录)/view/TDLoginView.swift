////
////  TDLoginView.swift
////  TodoMacRepertorie
////
////  Created by 孬孬 on 2024/12/28.
////
//
////
////  TDLoginView.swift
////  TodoMacRepertorie
////
////  Created by apple on 2024/11/5.
////
//
//import SwiftUI
////import AlertToast
//
//struct TDLoginView: View {
//    @StateObject private var viewModel = TDLoginViewModel()
//    @Environment(\.openWindow) private var openWindow
//    @Environment(\.dismissWindow) private var dismissWindow
//
//    var body: some View {
//        ZStack {
//            // 背景图
//            Image(.loginBack)
//                .resizable()
//                .aspectRatio(contentMode: .fill)
//                .ignoresSafeArea()
//            
//            HStack {
//                Spacer()
//                VStack(spacing: 0) {
//                    // Logo和标题
//                    VStack(spacing: 20) {
//                        HStack(spacing: 8) {
//                            Image(.loginLogo)
//                                .resizable()
//                                .frame(width: 28, height: 28)
//                            
//                            Text("Todo清单")
//                                .font(.title2)
//                                .fontWeight(.medium)
//                        }
//                        Text("深受百万企业管理者与各界精英青睐\n强大的跨平台待办事项软件")
//                            .font(.system(size: 12))
//                            .foregroundStyle(Color.greyColor6)
//                            .multilineTextAlignment(.center)
//                            .lineSpacing(6.0)
//                            .fixedSize(horizontal: false, vertical: true)
//
//                    }
//                    .padding(.top, 40)
//
//                    // 登录中
//                    if viewModel.isLoginLoading {// 登录中
//
//                        Spacer()
//                        ProgressView()
//                        Spacer()
//                    } else {// 未登录
//                        VStack(spacing: 20) {
//                            Picker("", selection: $viewModel.currentType) {
//                                if viewModel.loginState == .login {
//                                    Text("账号登录")
//                                        .tag(TDLoginViewModel.TDLoginType.account)
//                                    Text("手机号登录")
//                                        .tag(TDLoginViewModel.TDLoginType.phone)
//                                    Text("扫一扫登录")
//                                        .tag(TDLoginViewModel.TDLoginType.qrcode)
//                                } else {
//                                    Text("账号注册")
//                                        .tag(TDLoginViewModel.TDLoginType.account)
//                                    Text("手机号注册")
//                                        .tag(TDLoginViewModel.TDLoginType.phone)
//                                }
//                            }
//                            .pickerStyle(.segmented)
//                            .padding(.top, 54)
//                            
//                            // 登录表单
//                            Group {
//                                switch viewModel.currentType {
//                                case .account:
//                                    AccountLoginForm(viewModel: viewModel)
//                                case .phone:
//                                    PhoneLoginForm(viewModel: viewModel)
//                                case .qrcode:
//                                    QRCodeLoginForm(viewModel: viewModel)
//                                }
//                            }
//                            .frame(height: 220) // 固定表单区域高度
//                            
//                        }
//                        .padding(.horizontal, 47)
//
//                        Spacer()
//                        TDLoginRuleView(viewModel: viewModel)
//                            .padding([.horizontal], 44)
//                        Spacer()
//                        
//                    }
//                }
//                .frame(width: 375)
//                .background(
//                    BlurView(material: .popover, blendingMode: .withinWindow)
//                        .opacity(0.85)
//                )
//                .clipShape(RoundedRectangle(cornerRadius: 16))
//                .padding([.trailing, .vertical], 44)
////                .tdToastBottomRight(isPresenting: $viewModel.showErrorToast, title: viewModel.toastMessage)
//                .tdToastBottom(isPresenting: $viewModel.showErrorToast, message: viewModel.toastMessage)
////                .toast(isPresenting: $viewModel.showErrorToast) {
////                    AlertToast(type: .regular, title: viewModel.toastMessage)
////                }
//            }
//        }
////        .tdToastBottomRight(isPresenting: $viewModel.showErrorToast, title: viewModel.toastMessage)
//
//    }
//    
//    
////    var body: some View {
////        ZStack {
////            // 背景图片
////            Image("login_backImage")
////                .resizable()
////                .aspectRatio(contentMode: .fill)
////                .ignoresSafeArea()
////
////            // 毛玻璃登录卡片
////            HStack(spacing: 0) {
////                // 左侧背景图
////                Image("")
////                    .resizable()
////                    .aspectRatio(contentMode: .fill)
////                    .frame(width: 932 - 375 - 44)
////                    .clipped()
////
////                // 右侧登录表单
////                VStack (alignment: .center){
////                    // Logo和标题
////                    VStack(spacing: 20) {
////                        HStack {
////                            Image("login_logo")
////                                .resizable()
////                                .frame(width: 30, height: 30)
////                            Text("Todo清单")
////                                .font(.title2)
////                                .bold()
////                        }
////
////                        Text("深受百万企业管理者与各界精英青睐\n强大的跨平台待办事项软件")
////                            .font(.system(size: 12))
////                            .foregroundStyle(Color.themeLabelColor(i: 1))
////                            .multilineTextAlignment(.center)
////                            .lineSpacing(6.0)
////                    }
//////                    .padding(.top, 40)
//////                    .frame(height: 150)
////                    .background(.red)
////
////                    if !viewModel.isLoading {
////                        Picker("", selection: $viewModel.currentType) {
////                            if viewModel.loginState == .login {
////                                Text("账号登录")
////                                    .tag(TDLoginViewModel.TDLoginType.account)
////                                Text("手机号登录")
////                                    .tag(TDLoginViewModel.TDLoginType.phone)
////                                Text("扫一扫登录")
////                                    .tag(TDLoginViewModel.TDLoginType.qrcode)
////                            } else {
////                                Text("账号注册")
////                                    .tag(TDLoginViewModel.TDLoginType.account)
////                                Text("手机号注册")
////                                    .tag(TDLoginViewModel.TDLoginType.phone)
////                            }
////
////                        }
////                        .pickerStyle(.segmented)
////
////
////
////                        // 登录表单
////                        Group {
////                            switch viewModel.currentType {
////                            case .account:
////                                AccountLoginForm(viewModel: viewModel)
////                                    .frame(height: 75)
////                            case .phone:
////                                PhoneLoginForm(viewModel: viewModel)
////                                    .frame(height: 75)
////                            case .qrcode:
////                                QRCodeLoginForm(viewModel: viewModel)
////                            }
////                        }
////                        .transition(.opacity.combined(with: .move(edge: .trailing)))
////
////                        Button {
////
////
////                        } label: {
////                            // 按钮样式
////                            Text(viewModel.loginState == .register ? "注册" : "登录")
////                                .font(.system(size: 14))
////                                .frame(minWidth: 0, maxWidth: .infinity)
////                                .padding(.vertical, 10)
////                                .foregroundStyle(.white)
////                                .background(Color.marrsGreenColor6)
////                                .clipShape(RoundedRectangle(cornerRadius: 5))
////                        }
////                        .buttonStyle(.plain)
////
////                        Button(action: {
////                            // 操作
////                            viewModel.toggleLoginState()
////                            viewModel.currentType = .account
////                        }) {
////                            // 按钮样式
////                            Text(viewModel.loginState == .register ? "返回登录" : "新用户注册")
////                                .font(.system(size: 14))
////                                .frame(minWidth: 0, maxWidth: .infinity)
////                                .padding(.vertical, 10)
////                                .foregroundStyle(.white)
////                                .background(Color.greyColor6)
////                                .clipShape(RoundedRectangle(cornerRadius: 5))
////                        }
////                        .buttonStyle(.plain)
////
////
////                    } else {
////
////                    }
//////                    Spacer()
//////                     底部协议
////                    LoginRuleView(viewModel: viewModel)
//////                    Spacer()
////                }
////                .padding(.top,40)
////                .frame(width: 375,height: 533)
////                .background(
////                    BlurView(material: .popover, blendingMode: .withinWindow)
////                        .opacity(0.85)
////                )
////                .clipShape(RoundedRectangle(cornerRadius: 16))
////
////            }
//////            .padding(.trailing, 44)
////            .background(.yellow)
////        }
////    }
//}
//
//// Views/CustomSegmentedControl.swift
//struct CustomSegmentedControl<T: Hashable>: View {
//    @Binding var selection: T
//    let items: [(String, T)]
//    
//    var body: some View {
//        HStack(spacing: 0) {
//            ForEach(items, id: \.1) { item in
//                Button {
//                    withAnimation {
//                        selection = item.1
//                    }
//                } label: {
//                    Text(item.0)
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 8)
//                        .background(
//                            selection == item.1 ?
//                            Color.accentColor.opacity(0.1) : Color.clear
//                        )
//                        .foregroundColor(
//                            selection == item.1 ?
//                                .accentColor : .primary
//                        )
//                }
//                .buttonStyle(.plain)
//            }
//        }
//        .background(Color.gray.opacity(0.1))
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//    }
//}
//
//// Views/AccountLoginForm.swift
//struct AccountLoginForm: View {
//    @ObservedObject var viewModel: TDLoginViewModel
//    
//    @Environment(\.openWindow) private var openWindow
//    @Environment(\.dismissWindow) private var dismissWindow
//
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            TDTextFieldView(viewModel: viewModel, text: $viewModel.userAccount, placeString: "账号/邮箱")
//
//            if !viewModel.accountError.isEmpty {
//                Text(viewModel.accountError)
//                    .font(.system(size: 10))
//                    .foregroundStyle(Color.redColor6)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .frame(height: 20)
//            }
//            // 固定间距
//            
//            Spacer()
//                .frame(height: viewModel.accountError.isEmpty ? 20 : 0)
//
//            TDSecureTextField(viewModel: viewModel, text: $viewModel.password, placeString: "输入密码")
//            if !viewModel.passwordError.isEmpty {
//                Text(viewModel.passwordError)
//                    .font(.system(size: 10))
//                    .foregroundStyle(Color.redColor6)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .frame(height: 20)
//            }
//            // 固定间距
//            Spacer()
//                .frame(height: viewModel.passwordError.isEmpty ? 20 : 0)
//            
//            Button {
//                viewModel.loginWithAccount()
//            } label: {
//                // 按钮样式
//                Text(viewModel.loginState == .register ? "注册" : "登录")
//                    .font(.system(size: 14))
//                    .frame(minWidth: 0, maxWidth: .infinity)
//                    .padding(.vertical, 10)
//                    .foregroundStyle(.white)
//                    .background(Color.marrsGreenColor6)
//                    .clipShape(RoundedRectangle(cornerRadius: 5))
//            }
//            .buttonStyle(.plain)
//            .disabled(viewModel.isLoginLoading)
//            Spacer()
//                .frame(height: 20)
//
//            Button(action: {
//                // 操作
//                viewModel.loginState = viewModel.loginState == .login ? .register : .login
//                viewModel.currentType = .account
//            }) {
//                // 按钮样式
//                Text(viewModel.loginState == .register ? "返回登录" : "新用户注册")
//                    .font(.system(size: 14))
//                    .frame(minWidth: 0, maxWidth: .infinity)
//                    .padding(.vertical, 10)
//                    .foregroundStyle(.white)
//                    .background(Color.greyColor6)
//                    .clipShape(RoundedRectangle(cornerRadius: 5))
//            }
//            .buttonStyle(.plain)
//            .pointingHandCursor()
//            .disabled(viewModel.isLoginLoading)
//
//        }
//        .padding(.vertical, 20)
//
//    }
//}
//// Views/PhoneLoginForm.swift
//struct PhoneLoginForm: View {
//    @ObservedObject var viewModel: TDLoginViewModel
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            TDTextFieldView(viewModel: viewModel, text: $viewModel.phone, placeString: "手机号")
//
//            if !viewModel.phoneError.isEmpty {
//                Text(viewModel.phoneError)
//                    .font(.system(size: 10))
//                    .foregroundStyle(Color.redColor6)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .frame(height: 20)
//            }
//            // 固定间距
//            
//            Spacer()
//                .frame(height: viewModel.phoneError.isEmpty ? 20 : 0)
//
//            TDSecureTextField(viewModel: viewModel, text: $viewModel.smsCode, placeString: "验证码")
//            if !viewModel.smsCodeError.isEmpty {
//                Text(viewModel.smsCodeError)
//                    .font(.system(size: 10))
//                    .foregroundStyle(Color.redColor6)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .frame(height: 20)
//            }
//            // 固定间距
//            Spacer()
//                .frame(height: viewModel.smsCodeError.isEmpty ? 20 : 0)
//            
//            Button {
//                viewModel.loginWithPhone()
//            } label: {
//                // 按钮样式
//                Text(viewModel.loginState == .register ? "注册" : "登录")
//                    .font(.system(size: 14))
//                    .frame(minWidth: 0, maxWidth: .infinity)
//                    .padding(.vertical, 10)
//                    .foregroundStyle(.white)
//                    .background(Color.marrsGreenColor6)
//                    .clipShape(RoundedRectangle(cornerRadius: 5))
//            }
//            .buttonStyle(.plain)
//            .disabled(viewModel.isLoginLoading)
//
//            Spacer()
//                .frame(height: 20)
//
//            Button(action: {
//                // 操作
//                viewModel.loginState = viewModel.loginState == .login ? .register : .login
//                viewModel.currentType = .account
//            }) {
//                // 按钮样式
//                Text(viewModel.loginState == .register ? "返回登录" : "新用户注册")
//                    .font(.system(size: 14))
//                    .frame(minWidth: 0, maxWidth: .infinity)
//                    .padding(.vertical, 10)
//                    .foregroundStyle(.white)
//                    .background(Color.greyColor6)
//                    .clipShape(RoundedRectangle(cornerRadius: 5))
//            }
//            .buttonStyle(.plain)
//            .pointingHandCursor()
//            .disabled(viewModel.isLoginLoading)
//
//        }
//        .padding(.vertical, 20)
//        
//
//    }
//}
//
//
//// Views/QRCodeLoginForm.swift
//struct QRCodeLoginForm: View {
//    @ObservedObject var viewModel: TDLoginViewModel
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            // 二维码图片
////            if let qrCodeImage = viewModel.qrCodeImage {
////                Image(nsImage: qrCodeImage)
////                    .resizable()
////                    .interpolation(.none)
////                    .scaledToFit()
////                    .frame(width: 200, height: 160)
////            } else {
////                ProgressView()
////                    .frame(width: 200, height: 160)
////            }
//            
//            // 状态文本
////            Text(viewModel.qrCodeStatus.description)
////                .foregroundColor(.secondary)
////
////            // 刷新按钮
////            if viewModel.qrCodeStatus == .expired {
////                Button {
////                    Task {
////                        //                        await viewModel.refreshQRCode()
////                    }
////                } label: {
////                    Text("刷新二维码")
////                        .frame(maxWidth: .infinity)
////                }
////                .buttonStyle(.bordered)
////            }
////        }
////        .padding(.vertical, 20)
////        .task {
////            // 页面加载时获取二维码
////            //            await viewModel.startQRCodeLogin()
//        }
//    }
//}
//
////// Views/Login/PhoneLoginView.swift
////struct PhoneLoginView: View {
////    @ObservedObject var viewModel: TDLoginViewModel
////
////    var body: some View {
////        VStack(spacing: 20) {
////            // 手机号输入
////            TextField("请输入手机号", text: $viewModel.phoneNumber)
////                .textFieldStyle(.roundedBorder)
////
////            // 验证码输入和发送按钮
////            HStack {
////                TextField("请输入验证码", text: $viewModel.code)
////                    .textFieldStyle(.roundedBorder)
////
////                Button {
////                    Task {
////                        //                        await viewModel.sendCode()
////                    }
////                } label: {
////                    if viewModel.isSendingCode {
////                        ProgressView()
////                            .controlSize(.small)
////                    } else {
////                        Text(viewModel.countdownText)
////                            .frame(width: 100)
////                    }
////                }
////                .disabled(viewModel.isSendingCode || viewModel.countdown > 0)
////            }
////
////            // 登录按钮
////            Button {
////                Task {
////                    //                    await viewModel.loginWithCode()
////                }
////            } label: {
////                if viewModel.isLoading {
////                    ProgressView()
////                        .controlSize(.small)
////                } else {
////                    Text("登录")
////                        .frame(maxWidth: .infinity)
////                }
////            }
////            .buttonStyle(.borderedProminent)
////            .disabled(viewModel.isLoading || !viewModel.isPhoneLoginValid)
////        }
////        .padding(.horizontal)
////    }
////}
////
////// Views/Login/PasswordLoginView.swift
////struct PasswordLoginView: View {
////    @ObservedObject var viewModel: TDLoginViewModel
////
////    var body: some View {
////        VStack(spacing: 20) {
////            // 用户名输入
////            TextField("用户名/手机号", text: $viewModel.userAccount)
////                .textFieldStyle(.roundedBorder)
////
////            // 密码输入
////            SecureField("密码", text: $viewModel.userPassword)
////                .textFieldStyle(.roundedBorder)
////
////            // 登录按钮
////            Button {
////                Task {
////                    //                    await viewModel.loginWithPassword()
////                }
////            } label: {
////                if viewModel.isLoading {
////                    ProgressView()
////                        .controlSize(.small)
////                } else {
////                    Text("登录")
////                        .frame(maxWidth: .infinity)
////                }
////            }
////            .buttonStyle(.borderedProminent)
////            .disabled(viewModel.isLoading || !viewModel.isPasswordLoginValid)
////
////            // 忘记密码
////            Button("忘记密码？") {
////                viewModel.showForgotPassword = true
////            }
////            .font(.footnote)
////        }
////        .padding(.horizontal)
////    }
////}
////
////// Views/Login/QRCodeLoginView.swift
////struct QRCodeLoginView: View {
////    @ObservedObject var viewModel: TDLoginViewModel
////
////    var body: some View {
////        VStack(spacing: 20) {
////            if let qrCode = viewModel.qrCodeImage {
////                Image(nsImage: qrCode)
////                    .resizable()
////                    .interpolation(.none)
////                    .scaledToFit()
////                    .frame(width: 200, height: 200)
////            } else {
////                ProgressView()
////                    .frame(width: 200, height: 200)
////            }
////
////            Text("请使用手机APP扫码登录")
////                .font(.callout)
////                .foregroundColor(.secondary)
////
////            if viewModel.isCheckingQRCode {
////                Text("正在等待扫码...")
////                    .font(.callout)
////                    .foregroundColor(.secondary)
////            }
////        }
////        .padding()
////        .onAppear {
////            //            viewModel.startQRCodeLogin()
////        }
////        .onDisappear {
////            //            viewModel.stopQRCodeLogin()
////        }
////    }
////}
//
//
//#Preview {
//    TDLoginView()
//}
//


//
//  TDLoginView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

//
//  TDLoginView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/5.
//

import SwiftUI
//import AlertToast

struct TDLoginView: View {
    @StateObject private var viewModel = TDLoginViewModel()
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        ZStack {
            // 背景图
            Image(.loginBack)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            HStack {
                Spacer()
                VStack(spacing: 0) {
                    // Logo和标题
                    VStack(spacing: 20) {
                        HStack(spacing: 8) {
                            Image(.loginLogo)
                                .resizable()
                                .frame(width: 28, height: 28)
                            
                            Text("Todo清单")
                                .font(.title2)
                                .fontWeight(.medium)
                        }
                        Text("深受百万企业管理者与各界精英青睐\n强大的跨平台待办事项软件")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.greyColor6)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6.0)
                            .fixedSize(horizontal: false, vertical: true)

                    }
                    .padding(.top, 40)

                    // 登录中
                    if viewModel.isLoginLoading {// 登录中

                        Spacer()
                        ProgressView()
                        Spacer()
                    } else {// 未登录
                        VStack(spacing: 20) {
                            Picker("", selection: $viewModel.currentType) {
                                if viewModel.loginState == .login {
                                    Text("账号登录")
                                        .tag(TDLoginViewModel.TDLoginType.account)
                                    Text("手机号登录")
                                        .tag(TDLoginViewModel.TDLoginType.phone)
                                    Text("扫一扫登录")
                                        .tag(TDLoginViewModel.TDLoginType.qrcode)
                                } else {
                                    Text("账号注册")
                                        .tag(TDLoginViewModel.TDLoginType.account)
                                    Text("手机号注册")
                                        .tag(TDLoginViewModel.TDLoginType.phone)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.top, 54)
                            
                            // 登录表单
                            Group {
                                switch viewModel.currentType {
                                case .account:
                                    AccountLoginForm(viewModel: viewModel)
                                case .phone:
                                    PhoneLoginForm(viewModel: viewModel)
                                case .qrcode:
                                    QRCodeLoginForm(viewModel: viewModel)
                                }
                            }
                            .frame(height: 220) // 固定表单区域高度
                            
                        }
                        .padding(.horizontal, 47)

                        Spacer()
                        TDLoginRuleView(viewModel: viewModel)
                            .padding([.horizontal], 44)
                        Spacer()
                        
                    }
                }
                .frame(width: 375)
                .background(
                    BlurView(material: .popover, blendingMode: .withinWindow)
                        .opacity(0.85)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding([.trailing, .vertical], 44)
//                .tdToastBottomRight(isPresenting: $viewModel.showErrorToast, title: viewModel.toastMessage)
                // Toast 统一走 TDToastCenter（ViewModel 内部触发）
//                .toast(isPresenting: $viewModel.showErrorToast) {
//                    AlertToast(type: .regular, title: viewModel.toastMessage)
//                }
            }
        }
//        .tdToastBottomRight(isPresenting: $viewModel.showErrorToast, title: viewModel.toastMessage)

    }
    
    
//    var body: some View {
//        ZStack {
//            // 背景图片
//            Image("login_backImage")
//                .resizable()
//                .aspectRatio(contentMode: .fill)
//                .ignoresSafeArea()
//
//            // 毛玻璃登录卡片
//            HStack(spacing: 0) {
//                // 左侧背景图
//                Image("")
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .frame(width: 932 - 375 - 44)
//                    .clipped()
//
//                // 右侧登录表单
//                VStack (alignment: .center){
//                    // Logo和标题
//                    VStack(spacing: 20) {
//                        HStack {
//                            Image("login_logo")
//                                .resizable()
//                                .frame(width: 30, height: 30)
//                            Text("Todo清单")
//                                .font(.title2)
//                                .bold()
//                        }
//
//                        Text("深受百万企业管理者与各界精英青睐\n强大的跨平台待办事项软件")
//                            .font(.system(size: 12))
//                            .foregroundStyle(Color.themeLabelColor(i: 1))
//                            .multilineTextAlignment(.center)
//                            .lineSpacing(6.0)
//                    }
////                    .padding(.top, 40)
////                    .frame(height: 150)
//                    .background(.red)
//
//                    if !viewModel.isLoading {
//                        Picker("", selection: $viewModel.currentType) {
//                            if viewModel.loginState == .login {
//                                Text("账号登录")
//                                    .tag(TDLoginViewModel.TDLoginType.account)
//                                Text("手机号登录")
//                                    .tag(TDLoginViewModel.TDLoginType.phone)
//                                Text("扫一扫登录")
//                                    .tag(TDLoginViewModel.TDLoginType.qrcode)
//                            } else {
//                                Text("账号注册")
//                                    .tag(TDLoginViewModel.TDLoginType.account)
//                                Text("手机号注册")
//                                    .tag(TDLoginViewModel.TDLoginType.phone)
//                            }
//
//                        }
//                        .pickerStyle(.segmented)
//
//
//
//                        // 登录表单
//                        Group {
//                            switch viewModel.currentType {
//                            case .account:
//                                AccountLoginForm(viewModel: viewModel)
//                                    .frame(height: 75)
//                            case .phone:
//                                PhoneLoginForm(viewModel: viewModel)
//                                    .frame(height: 75)
//                            case .qrcode:
//                                QRCodeLoginForm(viewModel: viewModel)
//                            }
//                        }
//                        .transition(.opacity.combined(with: .move(edge: .trailing)))
//
//                        Button {
//
//
//                        } label: {
//                            // 按钮样式
//                            Text(viewModel.loginState == .register ? "注册" : "登录")
//                                .font(.system(size: 14))
//                                .frame(minWidth: 0, maxWidth: .infinity)
//                                .padding(.vertical, 10)
//                                .foregroundStyle(.white)
//                                .background(Color.marrsGreenColor6)
//                                .clipShape(RoundedRectangle(cornerRadius: 5))
//                        }
//                        .buttonStyle(.plain)
//
//                        Button(action: {
//                            // 操作
//                            viewModel.toggleLoginState()
//                            viewModel.currentType = .account
//                        }) {
//                            // 按钮样式
//                            Text(viewModel.loginState == .register ? "返回登录" : "新用户注册")
//                                .font(.system(size: 14))
//                                .frame(minWidth: 0, maxWidth: .infinity)
//                                .padding(.vertical, 10)
//                                .foregroundStyle(.white)
//                                .background(Color.greyColor6)
//                                .clipShape(RoundedRectangle(cornerRadius: 5))
//                        }
//                        .buttonStyle(.plain)
//
//
//                    } else {
//
//                    }
////                    Spacer()
////                     底部协议
//                    LoginRuleView(viewModel: viewModel)
////                    Spacer()
//                }
//                .padding(.top,40)
//                .frame(width: 375,height: 533)
//                .background(
//                    BlurView(material: .popover, blendingMode: .withinWindow)
//                        .opacity(0.85)
//                )
//                .clipShape(RoundedRectangle(cornerRadius: 16))
//
//            }
////            .padding(.trailing, 44)
//            .background(.yellow)
//        }
//    }
}

// Views/CustomSegmentedControl.swift
struct CustomSegmentedControl<T: Hashable>: View {
    @Binding var selection: T
    let items: [(String, T)]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.1) { item in
                Button {
                    withAnimation {
                        selection = item.1
                    }
                } label: {
                    Text(item.0)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selection == item.1 ?
                            Color.accentColor.opacity(0.1) : Color.clear
                        )
                        .foregroundColor(
                            selection == item.1 ?
                                .accentColor : .primary
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// Views/AccountLoginForm.swift
struct AccountLoginForm: View {
    @ObservedObject var viewModel: TDLoginViewModel
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    
    var body: some View {
        VStack(spacing: 0) {
            TDTextFieldView(viewModel: viewModel, text: $viewModel.userAccount, placeString: "账号/邮箱")

            if !viewModel.accountError.isEmpty {
                Text(viewModel.accountError)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.redColor6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 20)
            }
            // 固定间距
            
            Spacer()
                .frame(height: viewModel.accountError.isEmpty ? 20 : 0)

            TDSecureTextField(viewModel: viewModel, text: $viewModel.password, placeString: "输入密码")
            if !viewModel.passwordError.isEmpty {
                Text(viewModel.passwordError)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.redColor6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 20)
            }
            // 固定间距
            Spacer()
                .frame(height: viewModel.passwordError.isEmpty ? 20 : 0)
            
            Button {
                viewModel.loginWithAccount()
            } label: {
                // 按钮样式
                Text(viewModel.loginState == .register ? "注册" : "登录")
                    .font(.system(size: 14))
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(Color.marrsGreenColor6)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoginLoading)
            Spacer()
                .frame(height: 20)

            Button(action: {
                // 操作
                viewModel.loginState = viewModel.loginState == .login ? .register : .login
                viewModel.currentType = .account
            }) {
                // 按钮样式
                Text(viewModel.loginState == .register ? "返回登录" : "新用户注册")
                    .font(.system(size: 14))
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(Color.greyColor6)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .disabled(viewModel.isLoginLoading)

        }
        .padding(.vertical, 20)

    }
}
// Views/PhoneLoginForm.swift
struct PhoneLoginForm: View {
    @ObservedObject var viewModel: TDLoginViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            TDTextFieldView(viewModel: viewModel, text: $viewModel.phone, placeString: "手机号")

            if !viewModel.phoneError.isEmpty {
                Text(viewModel.phoneError)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.redColor6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 20)
            }
            // 固定间距
            
            Spacer()
                .frame(height: viewModel.phoneError.isEmpty ? 20 : 0)

            TDSecureTextField(viewModel: viewModel, text: $viewModel.smsCode, placeString: "验证码")
            if !viewModel.smsCodeError.isEmpty {
                Text(viewModel.smsCodeError)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.redColor6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 20)
            }
            // 固定间距
            Spacer()
                .frame(height: viewModel.smsCodeError.isEmpty ? 20 : 0)
            
            Button {
                viewModel.loginWithPhone()
            } label: {
                // 按钮样式
                Text(viewModel.loginState == .register ? "注册" : "登录")
                    .font(.system(size: 14))
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(Color.marrsGreenColor6)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoginLoading)

            Spacer()
                .frame(height: 20)

            Button(action: {
                // 操作
                viewModel.loginState = viewModel.loginState == .login ? .register : .login
                viewModel.currentType = .account
            }) {
                // 按钮样式
                Text(viewModel.loginState == .register ? "返回登录" : "新用户注册")
                    .font(.system(size: 14))
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(Color.greyColor6)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .disabled(viewModel.isLoginLoading)

        }
        .padding(.vertical, 20)
        

    }
}


// Views/QRCodeLoginForm.swift
struct QRCodeLoginForm: View {
    @ObservedObject var viewModel: TDLoginViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // 二维码图片
//            if let qrCodeImage = viewModel.qrCodeImage {
//                Image(nsImage: qrCodeImage)
//                    .resizable()
//                    .interpolation(.none)
//                    .scaledToFit()
//                    .frame(width: 200, height: 160)
//            } else {
//                ProgressView()
//                    .frame(width: 200, height: 160)
//            }
            
            // 状态文本
//            Text(viewModel.qrCodeStatus.description)
//                .foregroundColor(.secondary)
//
//            // 刷新按钮
//            if viewModel.qrCodeStatus == .expired {
//                Button {
//                    Task {
//                        //                        await viewModel.refreshQRCode()
//                    }
//                } label: {
//                    Text("刷新二维码")
//                        .frame(maxWidth: .infinity)
//                }
//                .buttonStyle(.bordered)
//            }
//        }
//        .padding(.vertical, 20)
//        .task {
//            // 页面加载时获取二维码
//            //            await viewModel.startQRCodeLogin()
        }
    }
}

//// Views/Login/PhoneLoginView.swift
//struct PhoneLoginView: View {
//    @ObservedObject var viewModel: TDLoginViewModel
//
//    var body: some View {
//        VStack(spacing: 20) {
//            // 手机号输入
//            TextField("请输入手机号", text: $viewModel.phoneNumber)
//                .textFieldStyle(.roundedBorder)
//
//            // 验证码输入和发送按钮
//            HStack {
//                TextField("请输入验证码", text: $viewModel.code)
//                    .textFieldStyle(.roundedBorder)
//
//                Button {
//                    Task {
//                        //                        await viewModel.sendCode()
//                    }
//                } label: {
//                    if viewModel.isSendingCode {
//                        ProgressView()
//                            .controlSize(.small)
//                    } else {
//                        Text(viewModel.countdownText)
//                            .frame(width: 100)
//                    }
//                }
//                .disabled(viewModel.isSendingCode || viewModel.countdown > 0)
//            }
//
//            // 登录按钮
//            Button {
//                Task {
//                    //                    await viewModel.loginWithCode()
//                }
//            } label: {
//                if viewModel.isLoading {
//                    ProgressView()
//                        .controlSize(.small)
//                } else {
//                    Text("登录")
//                        .frame(maxWidth: .infinity)
//                }
//            }
//            .buttonStyle(.borderedProminent)
//            .disabled(viewModel.isLoading || !viewModel.isPhoneLoginValid)
//        }
//        .padding(.horizontal)
//    }
//}
//
//// Views/Login/PasswordLoginView.swift
//struct PasswordLoginView: View {
//    @ObservedObject var viewModel: TDLoginViewModel
//
//    var body: some View {
//        VStack(spacing: 20) {
//            // 用户名输入
//            TextField("用户名/手机号", text: $viewModel.userAccount)
//                .textFieldStyle(.roundedBorder)
//
//            // 密码输入
//            SecureField("密码", text: $viewModel.userPassword)
//                .textFieldStyle(.roundedBorder)
//
//            // 登录按钮
//            Button {
//                Task {
//                    //                    await viewModel.loginWithPassword()
//                }
//            } label: {
//                if viewModel.isLoading {
//                    ProgressView()
//                        .controlSize(.small)
//                } else {
//                    Text("登录")
//                        .frame(maxWidth: .infinity)
//                }
//            }
//            .buttonStyle(.borderedProminent)
//            .disabled(viewModel.isLoading || !viewModel.isPasswordLoginValid)
//
//            // 忘记密码
//            Button("忘记密码？") {
//                viewModel.showForgotPassword = true
//            }
//            .font(.footnote)
//        }
//        .padding(.horizontal)
//    }
//}
//
//// Views/Login/QRCodeLoginView.swift
//struct QRCodeLoginView: View {
//    @ObservedObject var viewModel: TDLoginViewModel
//
//    var body: some View {
//        VStack(spacing: 20) {
//            if let qrCode = viewModel.qrCodeImage {
//                Image(nsImage: qrCode)
//                    .resizable()
//                    .interpolation(.none)
//                    .scaledToFit()
//                    .frame(width: 200, height: 200)
//            } else {
//                ProgressView()
//                    .frame(width: 200, height: 200)
//            }
//
//            Text("请使用手机APP扫码登录")
//                .font(.callout)
//                .foregroundColor(.secondary)
//
//            if viewModel.isCheckingQRCode {
//                Text("正在等待扫码...")
//                    .font(.callout)
//                    .foregroundColor(.secondary)
//            }
//        }
//        .padding()
//        .onAppear {
//            //            viewModel.startQRCodeLogin()
//        }
//        .onDisappear {
//            //            viewModel.stopQRCodeLogin()
//        }
//    }
//}


#Preview {
    TDLoginView()
}


