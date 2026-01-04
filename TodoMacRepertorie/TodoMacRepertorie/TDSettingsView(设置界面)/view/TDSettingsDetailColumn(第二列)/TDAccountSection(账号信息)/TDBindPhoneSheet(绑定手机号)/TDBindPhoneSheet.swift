//
//  TDBindPhoneSheet.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/12/19.
//

import SwiftUI

struct TDBindPhoneSheet: View {
    @Binding var phone: String
    @Binding var code: String
    let themeManager: TDThemeManager
    let detailManager: TDSettingsDetailManager
    let title: String

    var onSuccess: (() -> Void)?


    @State private var phoneError: String?
    @State private var codeError: String?
    @State private var phoneShake = false
    @State private var codeShake = false

    @State private var showForceBind = false
    @State private var forceMessage: String = "settings.account.phone.forcebind.message".localized
    @State private var pendingForcePhone: String = ""
    @State private var pendingForceCode: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Spacer()
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.titleTextColor)
                Spacer()
            }
            
            TDFormTextFieldWithCountdown(
                text: $phone,
                placeholder: "settings.account.phone.input.placeholder".localized,
                onSend: {
                    // sendCode 内部返回 Bool，倒计时由组件根据返回值控制
                    sendCode()
                },
                themeManager: themeManager,
                shake: phoneShake,
                isError: phoneError != nil,
                onSubmit: {
                    // 与获取验证码同逻辑
                    sendCode()
                }
            )
            .submitLabel(.go)

            Text(phoneError ?? " ")
                .font(.system(size: 10))
                .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                .opacity(phoneError == nil ? 0 : 1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 12)

            
            TDFormTextField(
                text: $code,
                placeholder: "settings.account.phone.code.placeholder".localized,
                shake: codeShake,
                isError: codeError != nil,
                onSubmit: {
                    submitBind()
                }
            )
            .submitLabel(.done)

            Text(codeError ?? " ")
                .font(.system(size: 10))
                .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
                .opacity(codeError == nil ? 0 : 1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 12)

            HStack {
                Spacer()
                Button("common.cancel".localized) {
                    code = ""
                    dismissSheet()
                }
                .font(.system(size: 12))
                .foregroundColor(themeManager.titleTextColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(themeManager.secondaryBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.plain)
                .pointingHandCursor()

                Button("common.confirm".localized) {
                    submitBind()

                }
                .font(.system(size: 12))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(themeManager.color(level: 5))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.plain)
                .pointingHandCursor()
            }
        }
        .padding(20)
        .frame(width: 380)
        .sheet(isPresented: $showForceBind) {
            TDForceBindPhoneSheet(
                message: forceMessage,
                phone: phone,
                code: Int(code) ?? 0,
                detailManager: detailManager,
                onCancel: { showForceBind = false },
                onSuccess: {
                    showForceBind = false
                    dismissSheet()
                    onSuccess?()
                    TDToastCenter.shared.show("settings.account.phone.bind.success".localized, type: .success)
                }
            )
            .environmentObject(themeManager)
        }
        .onDisappear {
            // 弹窗关闭时，如果未绑定成功（手机为空），清空输入
            phone = ""
            code = ""

        }

    }
    
    @Environment(\.dismiss) private var dismissSheet
    
    
    @discardableResult
    private func sendCode() -> Bool {
        guard validatePhone() else { return false }
        Task {
            do {
                try await detailManager.requestBindSmsCode(phone: phone)
                TDToastCenter.shared.show("settings.account.phone.code.success".localized, type: .success)
            } catch TDSettingsDetailManager.TDBindPhoneFlowError.message(let msg) {
                phoneError = msg
                triggerPhoneShake()
            } catch let err as TDNetworkError {
                if case .requestFailed(let msg) = err {
                    phoneError = msg
                } else {
                    phoneError = err.errorMessage
                }
                triggerPhoneShake()
            } catch {
                phoneError = error.localizedDescription
                triggerPhoneShake()
            }
        }
        return true
    }

    private func submitBind() {
        guard validatePhone(), validateCode(localOnly: true) else { return }
        guard let codeInt = Int(code) else {
            codeError = "settings.account.phone.code.invalid".localized
            triggerCodeShake()
            return
        }
        
        Task {
            do {
                try await detailManager.bindPhone(phone: phone, code: codeInt)
                dismissSheet()
                TDUserManager.shared.currentUser?.phoneNumber = Int(phone) ?? 0
                onSuccess?()
                TDToastCenter.shared.td_settingShow("settings.account.phone.bind.success".localized, type: .success)
            } catch TDSettingsDetailManager.TDBindPhoneFlowError.forceBindNeeded(let msg) {
                forceMessage = msg
                pendingForcePhone = phone
                pendingForceCode = codeInt
                showForceBind = true
            } catch TDSettingsDetailManager.TDBindPhoneFlowError.message(let msg) {
                codeError = msg
                triggerCodeShake()
            } catch let netErr as TDNetworkError {
                if case .requestFailed(let msg) = netErr {
                    codeError = msg   // 服务器原文
                } else {
                    codeError = netErr.errorMessage
                }
                triggerCodeShake()
            } catch {
                codeError = error.localizedDescription
                triggerCodeShake()
            }
        }
    }

    
    private func validatePhone() -> Bool {
        if !phone.isValidPhoneNumber {
            phoneError = "settings.account.phone.invalid".localized
            triggerPhoneShake()
            return false
        }
        phoneError = nil
        return true
    }

    private func validateCode(localOnly: Bool = false) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let ok = !trimmed.isEmpty && trimmed.allSatisfy(\.isNumber)
        if !ok {
            codeError = "settings.account.phone.code.invalid".localized
            triggerCodeShake()
        } else if localOnly {
            codeError = nil
        }
        return ok
    }
    
    private func triggerPhoneShake() {
        phoneShake.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            phoneShake.toggle()
        }
    }
    
    private func triggerCodeShake() {
        codeShake.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            codeShake.toggle()
        }
    }

}
