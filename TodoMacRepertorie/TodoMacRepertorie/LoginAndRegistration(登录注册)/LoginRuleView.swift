//
//  LoginRuleView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/7/23.
//

import SwiftUI

struct LoginRuleView: View {
    @ObservedObject var viewModel: TDLoginViewModel

    var body: some View {
        HStack(spacing:0) {
            Button {
                viewModel.agreedToTerms.toggle()
            } label: {
                Image(systemName: viewModel.agreedToTerms ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(Color.marrsGreenColor4)
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .frame(width: 20, height: 20)

            Text("已阅读并同意")
                .foregroundStyle(Color.labelColor2)
                .font(.system(size: 12))
            
            Button {
                
            } label: {
                Text("《用户注册协议》")
                    .foregroundStyle(Color.marrsGreenColor4)
                    .font(.system(size: 12))
                    .frame(minWidth: 0, maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            
            Text("与")
                .foregroundStyle(Color.labelColor2)
                .font(.system(size: 12))

            Button {
                
            } label: {
                Text("《隐私协议》")
                    .foregroundStyle(Color.marrsGreenColor4)
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
        }
    }

}

#Preview {
    LoginRuleView(viewModel: TDLoginViewModel())
}
