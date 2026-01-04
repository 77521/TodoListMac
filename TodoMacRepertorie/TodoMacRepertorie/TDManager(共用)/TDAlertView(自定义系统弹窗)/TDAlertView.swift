//
//  TDAlertView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/1/1.
//

import SwiftUI

struct TDAlertView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    
    @Binding var isPresented: Bool
    var title: String = "common.alert.title".localized // 默认“提示”
    var message: String
    var primaryTitle: String = "common.cancel".localized // 默认“取消”
    var secondaryTitle: String = "common.confirm".localized // 默认“确定”
    var onPrimary: (() -> Void)? = nil
    var onSecondary: (() -> Void)? = nil

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                
                VStack(spacing: 14) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.titleTextColor)
                    
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.titleTextColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 12)
                    
                    HStack(spacing: 12) {
                        Button {
                            isPresented = false
                            onPrimary?()
                        } label: {
                            Text(primaryTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeManager.titleTextColor)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color.gray.opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .pointingHandCursor()
                        
                        Button {
                            isPresented = false
                            onSecondary?()
                        } label: {
                            Text(secondaryTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(themeManager.color(level: 6))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .pointingHandCursor()
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(width: 320)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.windowBackgroundColor))
                        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
                )
            }
            .transition(.opacity)
        }
    }
}

