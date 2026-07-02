//
//  TDForgetPasswordView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2026/7/1.
//

import SwiftUI

// MARK: - 忘记密码主窗口视图
struct TDForgetPasswordView: View {

    /// ViewModel（由 WindowGroup 通过 context 初始化传入）
    @StateObject var viewModel: TDForgetPasswordViewModel
    /// 主题管理器（用于封装组件的颜色）
    @EnvironmentObject private var themeManager: TDThemeManager
    /// 关闭当前窗口
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                // 顶部为交通灯按钮留出空间（.hiddenTitleBar 时按钮浮在内容上方）
                Spacer().frame(height: 28)

                // 根据步骤显示不同内容
                switch viewModel.currentStep {
                case .loading:
                    // 查询账号绑定信息中，显示加载占位
                    TDFPLoadingView()
                case .selectMethod:
                    TDFPSelectMethodView(viewModel: viewModel)
                case .resetPassword:
                    TDFPResetPasswordView(viewModel: viewModel, themeManager: themeManager) {
                        // 重置成功回调：关闭窗口
                        dismissWindow(id: "ForgetPassword")
                    }
                }
            }
        }
        // 宽度固定480，高度由内容撑开（选择方式步骤较矮，重置密码步骤较高）
        .frame(width: 480, alignment: .top)
        // 配置窗口：隐藏最小化和缩放按钮，只留关闭按钮
        .background(
            TDWindowAccessor { window in
                guard let win = window else { return }
                win.standardWindowButton(.miniaturizeButton)?.isHidden = true
                win.standardWindowButton(.zoomButton)?.isHidden = true
                // 允许通过拖拽背景移动窗口
                win.isMovableByWindowBackground = true
                // 禁止 macOS 在下次启动时自动恢复此窗口
                win.isRestorable = false
            }
        )
        .ignoresSafeArea()
    }
}

// MARK: - 加载中占位视图
private struct TDFPLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(NSLocalizedString("forget.loading", comment: ""))
                .font(.system(size: 13))
                .foregroundStyle(Color(NSColor.secondaryLabelColor))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - 第一步：选择找回方式
private struct TDFPSelectMethodView: View {

    @ObservedObject var viewModel: TDForgetPasswordViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── 选项列表 ──
            VStack(spacing: 0) {
                // 手机号选项（显示服务端返回的脱敏手机号）
                TDFPMethodRow(
                    title: viewModel.isPhoneAvailable
                        ? String(format: NSLocalizedString("forget.method.phone.with", comment: ""), viewModel.maskedPhone)
                        : NSLocalizedString("forget.method.phone.unavailable", comment: ""),
                    isAvailable: viewModel.isPhoneAvailable,
                    isSelected: viewModel.selectedMethod == .phone
                ) {
                    if viewModel.isPhoneAvailable {
                        viewModel.selectedMethod = .phone
                    }
                }

                Divider().padding(.leading, 48)

                // 邮箱账号选项（显示服务端返回的邮箱）
                TDFPMethodRow(
                    title: viewModel.isEmailAvailable
                        ? String(format: NSLocalizedString("forget.method.email.with", comment: ""), viewModel.maskedEmail)
                        : NSLocalizedString("forget.method.email.unavailable", comment: ""),
                    isAvailable: viewModel.isEmailAvailable,
                    isSelected: viewModel.selectedMethod == .email
                ) {
                    if viewModel.isEmailAvailable {
                        viewModel.selectedMethod = .email
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // ── 无法找回时的提示文字 ──
            if !viewModel.isPhoneAvailable && !viewModel.isEmailAvailable {
                VStack(alignment: .leading, spacing: 10) {
                    Text(String(format: NSLocalizedString("forget.no_recovery.desc", comment: ""), viewModel.accountStr))
                        .font(.system(size: 12))
                        .foregroundStyle(Color(NSColor.secondaryLabelColor))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(NSLocalizedString("forget.no_recovery.contact_label", comment: ""))
                        .font(.system(size: 12))
                        .foregroundStyle(Color(NSColor.secondaryLabelColor))

                    // 可点击的客服邮箱（点击复制）
                    Text("contact@evestudio.cn")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.marrsGreenColor6)
                        .onTapGesture {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString("contact@evestudio.cn", forType: .string)
                            TDToastCenter.shared.show(
                                NSLocalizedString("forget.email.copied", comment: ""),
                                type: .success,
                                position: .bottom
                            )
                        }
                        .pointingHandCursor()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }

            // ── 确定按钮（有可用方式时才显示）──
            if viewModel.isPhoneAvailable || viewModel.isEmailAvailable {
                Button {
                    viewModel.confirmMethod()
                } label: {
                    Text(NSLocalizedString("forget.btn.confirm", comment: ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.marrsGreenColor6)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            } else {
                // 无可用方式时底部留白
                Spacer().frame(height: 32)
            }
        }
        // 不设固定高度，让内容自然撑开窗口
    }
}

// MARK: - 找回方式选项行
private struct TDFPMethodRow: View {

    /// 显示文本
    let title: String
    /// 是否可用（不可用则置灰）
    let isAvailable: Bool
    /// 是否已选中
    let isSelected: Bool
    /// 点击回调
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // 左侧选中状态图标
            Image(systemName: isSelected && isAvailable ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundStyle(isSelected && isAvailable ? Color.marrsGreenColor6 : Color(NSColor.tertiaryLabelColor))

            // 右侧标题文字
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(isAvailable ? Color(NSColor.labelColor) : Color(NSColor.tertiaryLabelColor))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

// MARK: - 第二步：输入验证码 + 新密码
private struct TDFPResetPasswordView: View {

    @ObservedObject var viewModel: TDForgetPasswordViewModel
    /// 主题管理器（传给封装组件）
    let themeManager: TDThemeManager
    /// 成功后关闭窗口的回调
    let onSuccess: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // ── 第一字段：手机号 / 邮箱账号 ──
            if viewModel.selectedMethod == .phone {
                // 手机方式：用户输入完整手机号以核验身份，placeholder 带脱敏号提示
                let phonePlaceholder: String = viewModel.maskedPhone.isEmpty
                    ? NSLocalizedString("forget.placeholder.phone", comment: "")
                    : String(format: NSLocalizedString("forget.placeholder.phone.masked", comment: ""), viewModel.maskedPhone)
                fieldSection(label: NSLocalizedString("forget.field.phone", comment: "")) {
                    TDFormTextField(
                        text: $viewModel.phone,
                        placeholder: phonePlaceholder,
                        isError: !viewModel.phoneError.isEmpty
                    )
                } errorText: { viewModel.phoneError }
            } else {
                // 邮箱方式：只读展示邮箱账号
                fieldSection(label: NSLocalizedString("forget.field.email_account", comment: "")) {
                    TDFormTextField(
                        text: .constant(viewModel.accountStr),
                        placeholder: viewModel.accountStr
                    )
                } errorText: { "" }
            }

            // ── 验证码字段（封装的带倒计时输入框）──
            fieldSection(
                label: viewModel.selectedMethod == .phone
                    ? NSLocalizedString("forget.field.sms_code", comment: "")
                    : NSLocalizedString("forget.field.email_code", comment: "")
            ) {
                TDFormTextFieldWithCountdown(
                    text: $viewModel.code,
                    placeholder: NSLocalizedString("forget.placeholder.code", comment: ""),
                    countdownSeconds: 60,
                    onSend: { viewModel.sendCode() },
                    themeManager: themeManager,
                    isError: !viewModel.codeError.isEmpty
                )
            } errorText: { viewModel.codeError }

            // ── 新密码字段 ──
            fieldSection(label: NSLocalizedString("forget.field.new_password", comment: "")) {
                TDFormTextField(
                    text: $viewModel.newPassword,
                    placeholder: NSLocalizedString("forget.placeholder.new_password", comment: ""),
                    isSecure: true,
                    isError: !viewModel.passwordError.isEmpty
                )
            } errorText: { viewModel.passwordError }

            // ── 提交按钮 ──
            Button {
                viewModel.submitReset(onSuccess: onSuccess)
            } label: {
                ZStack {
                    if viewModel.isResetting {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(NSLocalizedString("forget.btn.set_password", comment: ""))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(viewModel.isResetting ? Color.marrsGreenColor6.opacity(0.6) : Color.marrsGreenColor6)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .disabled(viewModel.isResetting || viewModel.isSuccess)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 32)
    }

    // MARK: - 字段布局辅助（标签 + 输入框 + 错误提示）
    @ViewBuilder
    private func fieldSection<F: View>(
        label: String,
        @ViewBuilder field: () -> F,
        errorText: () -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color(NSColor.secondaryLabelColor))

            field()

            let err = errorText()
            if !err.isEmpty {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            }
        }
    }
}
