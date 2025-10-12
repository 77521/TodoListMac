//
//  TDLoginRuleView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//
import SwiftUI

struct TDLoginRuleView: View {
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
            .pointingHandCursor()
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
            .pointingHandCursor()

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
            .pointingHandCursor()
        }
    }

}

#Preview {
    TDLoginRuleView(viewModel: TDLoginViewModel())
}

