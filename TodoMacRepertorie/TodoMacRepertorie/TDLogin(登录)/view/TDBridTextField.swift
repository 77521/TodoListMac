//
//  TDBridTextField.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI

/// 手机号 邮箱账号
struct TDTextFieldView: View {
    @ObservedObject var viewModel: TDLoginViewModel
    @Binding var text : String
    var placeString : String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading,spacing: 3) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white)
                    .stroke(Color.greyColor1, lineWidth: 2)
                    .frame(height: 40)
                    .overlay {
                        TextField(placeString, text: $text)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 15)
                            .onChange(of: viewModel.currentType == .account  ? viewModel.userAccount : viewModel.phone) { oldValue, newValue in
                                viewModel.phoneError = ""
                                viewModel.accountError = ""
                            }
                    }
            }
        }
    }
}

struct TDSecureTextField: View {
    @ObservedObject var viewModel: TDLoginViewModel
    @Binding var text: String
    var placeString : String
    @State private var isSecureTextEntry : Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading,spacing: 3) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white)
                    .stroke(Color.greyColor1, lineWidth: 2)
                    .frame(height: 40)
                    .overlay {
                        HStack(alignment:.center){
                            Group{
                                if isSecureTextEntry && viewModel.currentType == .account{
                                    SecureField(placeString, text: $text)
                                }else{
                                    TextField(placeString, text: $text)
                                }
                            }
                            .textFieldStyle(.plain)
                            .animation(.easeInOut(duration: 0.2), value: isSecureTextEntry)
                            .onChange(of: viewModel.currentType == .account  ? viewModel.password : viewModel.smsCode) { oldValue, newValue in
                                viewModel.passwordError = ""
                                viewModel.smsCodeError = ""
                            }
                            if viewModel.currentType == .account {
                                Button(action: {
                                    isSecureTextEntry.toggle()
                                }, label: {
                                    Image(systemName: isSecureTextEntry ? "eye.slash.fill" : "eye.fill" )
                                        .foregroundStyle(Color.greyColor4)
                                })
                                .frame(width: 20, height: 20)
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    
                                }, label: {
                                    Image(systemName: "questionmark.circle.fill" )
                                        .foregroundStyle(Color.greyColor2)
                                        .frame(width: 15, height: 15)
                                })
                                .buttonStyle(.plain)
                            } else {
                                
                                Button(action: { viewModel.sendSmsCode() }) {
                                    if viewModel.isSendingSms {
                                        ProgressView()  // loading 状态显示转圈圈
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.7)  // 缩小转圈圈的大小
                                    } else {
                                        Text(viewModel.smsButtonTitle)
                                            .foregroundStyle(.white)
                                            .font(.system(size: 10))  // 设置字体大小为10
                                    }
                                }
                                .frame(height: 30)  // 固定高度
                                .padding(.horizontal, 10)  // 左右内边距10
                                .background(Color.marrsGreenColor6)// 设置背景色
                                .foregroundColor(.white) // 文字颜色为白色
                                .cornerRadius(6)         // 圆角
                                .buttonStyle(.plain)
                                .disabled(!viewModel.canSendSms)
                            }
                            
                        }
                        .padding(.horizontal, 15)
                    }
            }
        }
        //Add any modifiers shared by the Button and the Fields here
    }
    

}

#Preview {
    TDTextFieldView(viewModel: TDLoginViewModel(), text: .constant("asdad"), placeString: "你好")
}

