//
//  LoginAndRegistrationView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/7/8.
//

import SwiftUI
import AppKit
import DynamicColor
import Alamofire

struct LoginAndRegistrationView: View {
    
    // 账号或者手机号
    @AppStorage("phoneAccountString") private var phoneAccountString = ""
    // 密码或者验证码
    @State private var passwordCodeString = ""
    // 当前登录方式 0：账号 1：手机号 2：扫一扫
    @State private var loginType = 0
    @State private var loginTypeString = "账号登录"
    // 是否点击了新用户注册
    @State private var isRegisterNewUser = false
    
    
    /// 是否点击了登录
    @State private var isClickLoginBtn = false
    
    /// 是否点击了阅读规则协议
    @State private var isClickReadRule = false
    // 登录方式内容
    var loginTypes : [String] {
        if isRegisterNewUser == true {
            return ["账号注册", "手机号注册"]
        } else {
            return ["账号登录", "手机号登录", "扫一扫登录"]
        }
    }
    // 账号手机号输入框占位文字
    var phoneAccountPlaceString : String {
        switch loginTypeString {
        case "账号注册", "账号登录":
            return "账号/邮箱"
        default:
            return "手机号"
        }
    }
    // 密码验证码输入框占位文字
    var passwordCodePlaceString : String {
        switch loginTypeString {
        case "账号注册", "账号登录":
            return "密码"
        default:
            return "验证码"
        }
    }
    
    /// 是否扫一扫登录
    var isPhoneScanCode : Bool {
        switch loginTypeString {
        case "扫一扫登录":
            return true
        default:
            return false
        }
    }
    /// 是否账号登录
    var isAccountLoginState : Bool {
        switch loginTypeString {
        case "手机号注册", "手机号登录":
            return false
        default:
            return true
        }
    }
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.themeBackGroundColor(i: 1).opacity(0.9))
                    .overlay(alignment: .center, content: {
                        VStack(alignment: .center, spacing: 20){
                            
                            VStack(alignment: .center, spacing: 20) {
                                HStack(alignment: .center) {
                                    Image(.loginLogo)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 28, height: 28)
                                    Text("Todo清单")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color.themeColor(i: 5))
                                }
                                Text("深受百万企业管理者与各界精英青睐\n强大的跨平台待办事项软件")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.themeLabelColor(i: 1))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(6.0)
                                    .fixedSize(horizontal: false, vertical: true)

                                Picker(selection: $loginTypeString) {
                                    ForEach(loginTypes, id: \.self){ loginSatae in
                                        Text(loginSatae)
                                            .tag(loginSatae)
                                            .foregroundStyle(.red)
                                    }
                                } label: {}
                                    .pickerStyle(.segmented)
                                    .padding(.top, 34.0)
                                    .labelsHidden()
                            }
                            .padding(.top, 40)

                            if isPhoneScanCode == false{
                                VStack(alignment: .leading, spacing: isClickLoginBtn ? 4 : 20) {
                                    VStack(alignment: .leading,spacing: 3) {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.white)
                                            .stroke(Color.greyColor1, lineWidth: 2)
                                            .frame(height: 40)
                                            .overlay {
                                                TextField(phoneAccountPlaceString, text: $phoneAccountString)
                                                    .textFieldStyle(.plain)
                                                    .padding(.horizontal, 18)
                                                    .onChange(of: phoneAccountString) { oldValue, newValue in
                                                        print("old== \(oldValue),,new== \(newValue)")
                                                        isClickLoginBtn = false
                                                    }
                                            }

                                        if isClickLoginBtn {
                                            Text("邮箱格式不正确")
                                                .font(.system(size: 10))
                                                .foregroundStyle(Color.redColor6)
                                                .animation(.bouncy(duration: 2))
                                        }
                                        
                                    }
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.white)
                                        .stroke(Color.greyColor1, lineWidth: 2)
                                        .frame(height: 40)
                                        .overlay {
                                            TDBridTextField(text: $passwordCodeString, titleKey: passwordCodePlaceString, isAccount: isAccountLoginState)
                                                .padding(.leading, 18)
                                                .padding(.trailing, 10)
                                        }
                                }

                                Button(action: {
                                    // 操作
                                    print("登录成功")
                                    if isAccountLoginState == true {// 账号登录
                                        if isRegisterNewUser == false {// 登录操作
                                            submitForm()
                                        } else {// 注册
                                            
                                        }
                                    }
//                                    isClickLoginBtn = true
                                }) {
                                    // 按钮样式
                                    Text(isRegisterNewUser ? "注册" : "登录")
                                        .font(.system(size: 14))
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .foregroundStyle(.white)
                                        .background(Color.marrsGreenColor6)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                                .buttonStyle(.plain)

                                Button(action: {
                                    // 操作
                                    isRegisterNewUser.toggle()
                                    loginTypeString = isRegisterNewUser ? "账号注册" : "账号登录"
                                }) {
                                    // 按钮样式
                                    Text(isRegisterNewUser ? "返回登录" : "新用户注册")
                                        .font(.system(size: 14))
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .foregroundStyle(.white)
                                        .background(Color.greyColor6)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                                .buttonStyle(.plain)
                            } else {
                                VStack(alignment:.center, spacing: 15.0) {
                                    Text("请使用Todo清单移动端\n扫描下方二维码")
                                        .font(.system(size: 11))
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(Color.themeLabelColor(i: 1))
                                        .fixedSize(horizontal: false, vertical: true)
                                    ZStack {
                                        Image(.loginBack)
                                            .resizable()
                                            .frame(width: 150,height: 150)
                                    }
                                    
                                }
                                .frame(minHeight: 150)
                                .padding(.top, 37)
                                Spacer()

                            }
                            
                            Spacer()
                            
                            LoginRuleView(isClickReadRule: $isClickReadRule)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 45)
                    })
                    .frame(width: 375)
                    .padding([.vertical, .trailing], 44)
                
            }
        }
        .ignoresSafeArea()
        .frame(width: 932, height: 570)
        .background(alignment: .center) {
            Image("login_backImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
    
    func submitForm() {
        let parameters: [String: String] = [
            "userAccount": phoneAccountString,
            "userPassword": passwordCodeString,
        ]
        
        HN.POST(url: TDAPI.Login.accountLogin.url, parameters: parameters).success { response in
            print("response -->", response)
        }.failed { error in
            print("error -->", error)
        }
    }
}
