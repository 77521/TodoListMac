//
//  TDLoginRuleView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//
import SwiftUI

struct TDLoginRuleView: View {

    // 协议勾选状态直接持有，不经过 ViewModel
    // 这样勾选时只有本视图重渲染，不会触发父视图 TDLoginView 的重渲染，
    // 避免 BlurView 背景在重渲染瞬间闪白
    @AppStorage("LoninViewAgreedToTerms") private var agreedToTerms = false

    /// 用户注册协议地址
    private let termsURL = URL(string: "https://www.evetech.top/?p=1039")!
    /// 隐私协议地址
    private let privacyURL = URL(string: "https://www.evetech.top/?p=828")!

    var body: some View {
        HStack(spacing: 0) {

            // 勾选圆圈 + "已阅读并同意"：纯 onTapGesture，无 Button，无系统级按压反馈
            HStack(spacing: 4) {
                Image(systemName: agreedToTerms ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(Color.marrsGreenColor4)
                    .font(.system(size: 12))

                Text("已阅读并同意")
                    .foregroundStyle(Color.labelColor2)
                    .font(.system(size: 12))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                agreedToTerms.toggle()
            }
            .pointingHandCursor()

            // 用户注册协议链接：Link 原生组件，无按压视觉反馈
            Link(destination: termsURL) {
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
            Link(destination: privacyURL) {
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
    TDLoginRuleView()
}
