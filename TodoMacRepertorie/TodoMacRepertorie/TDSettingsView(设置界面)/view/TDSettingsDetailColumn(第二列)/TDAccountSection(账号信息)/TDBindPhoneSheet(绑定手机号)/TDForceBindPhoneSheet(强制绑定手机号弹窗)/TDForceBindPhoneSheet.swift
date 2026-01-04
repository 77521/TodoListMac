//
//  TDForceBindPhoneSheet.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/12/22.
//

import SwiftUI

struct TDForceBindPhoneSheet: View {
    let message: String
    let phone: String
    let code: Int
    let detailManager: TDSettingsDetailManager
    var onCancel: () -> Void
    var onSuccess: () -> Void
    
    @State private var errorText: String?
    @State private var ackText: String = ""
    @State private var ackShake = false
    
    @EnvironmentObject private var themeManager: TDThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings.account.phone.forcebind.title".localized)
                .font(.system(size: 15))
                .foregroundColor(themeManager.titleTextColor)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(themeManager.titleTextColor)
                .lineSpacing(13)
            
            Text("settings.account.phone.forcebind.input_hint".localized)
                .font(.system(size: 12))
                .foregroundColor(themeManager.color(level: 5))
            
        TDFormTextField(
            text: $ackText,
            placeholder: "settings.account.phone.forcebind.placeholder".localized,
            shake: ackShake,
            isError: errorText != nil) {
                Task {
                    // 必须输入“已知晓”
                    if ackText.trimmingCharacters(in: .whitespacesAndNewlines) != "settings.account.phone.forcebind.placeholder".localized {
                        errorText = "settings.account.phone.forcebind.retry".localized
                        triggerAckShake()
                        return
                    }
                    
                    do {
                        try await detailManager.forceBindPhone(phone: phone, code: code)
                        onSuccess()
                    } catch TDSettingsDetailManager.TDBindPhoneFlowError.message(let msg) {
                        errorText = msg
                        triggerAckShake()
                    } catch let netErr as TDNetworkError {
                        if case .requestFailed(let msg) = netErr {
                            errorText = msg
                        } else {
                            errorText = netErr.errorMessage
                        }
                        triggerAckShake()
                    } catch {
                        errorText = error.localizedDescription
                        triggerAckShake()
                    }
                }
            }
        
        Text(errorText ?? " ")
            .font(.system(size: 10))
            .foregroundColor(themeManager.fixedColor(themeId: "new_year_red", level: 6))
            .opacity(errorText == nil ? 0 : 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 12)
            .padding(.top,-10)
        
        HStack {
            Spacer()
            Button("common.cancel".localized) { onCancel() }
                .font(.system(size: 12))
                .foregroundColor(themeManager.titleTextColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(themeManager.secondaryBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.plain)
                .pointingHandCursor()
            Button("settings.account.phone.forcebind.confirm".localized) {
                Task {
                    // 必须输入“已知晓”
                    if ackText.trimmingCharacters(in: .whitespacesAndNewlines) != "settings.account.phone.forcebind.placeholder".localized {
                        errorText = "settings.account.phone.forcebind.retry".localized
                        triggerAckShake()
                        return
                    }
                    
                    do {
                        try await detailManager.forceBindPhone(phone: phone, code: code)
                        TDUserManager.shared.currentUser?.phoneNumber = Int(phone) ?? 0

                        onSuccess()
                    } catch TDSettingsDetailManager.TDBindPhoneFlowError.message(let msg) {
                        errorText = msg
                        triggerAckShake()
                    } catch let netErr as TDNetworkError {
                        if case .requestFailed(let msg) = netErr {
                            errorText = msg
                        } else {
                            errorText = netErr.errorMessage
                        }
                        triggerAckShake()
                    } catch {
                        errorText = error.localizedDescription
                        triggerAckShake()
                    }
                }
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
    .frame(width: 420)
    }
    
    private func triggerAckShake() {
        ackShake.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            ackShake.toggle()
        }
    }
}
