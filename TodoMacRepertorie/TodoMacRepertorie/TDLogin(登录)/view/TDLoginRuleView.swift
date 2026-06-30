//
//  TDLoginRuleView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//
import SwiftUI

struct TDLoginRuleView: View {
    @ObservedObject var viewModel: TDLoginViewModel

    /// 用户注册协议地址
    private let termsURL = URL(string: "https://www.evetech.top/?p=1039")!
    /// 隐私协议地址
    private let privacyURL = URL(string: "https://www.evetech.top/?p=828")!

    var body: some View {
        HStack(spacing: 0) {
            // 勾选圆圈
            Button {
                viewModel.agreedToTerms.toggle()
            } label: {
                Image(systemName: viewModel.agreedToTerms ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(Color.marrsGreenColor4)
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .pointingHandCursor()

            // "已阅读并同意" 文字也可点击切换勾选状态
            Button {
                viewModel.agreedToTerms.toggle()
            } label: {
                Text("已阅读并同意")
                    .foregroundStyle(Color.labelColor2)
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .pointingHandCursor()

            // 用户注册协议链接
            Button {
                NSWorkspace.shared.open(termsURL)
            } label: {
                Text("《用户注册协议》")
                    .foregroundStyle(Color.marrsGreenColor4)
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .pointingHandCursor()

            Text("与")
                .foregroundStyle(Color.labelColor2)
                .font(.system(size: 12))

            // 隐私协议链接
            Button {
                NSWorkspace.shared.open(privacyURL)
            } label: {
                Text("《隐私协议》")
                    .foregroundStyle(Color.marrsGreenColor4)
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
        }
    }
}

#Preview {
    TDLoginRuleView(viewModel: TDLoginViewModel())
}
