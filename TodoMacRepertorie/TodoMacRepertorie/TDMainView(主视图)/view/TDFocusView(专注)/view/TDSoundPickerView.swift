//
//  TDSoundPickerView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/9/24.
//

import SwiftUI

/// 声音选择界面
struct TDSoundPickerView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Binding var selectedSound: TDSoundModel
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题栏
            HStack {
                Text("select_focus_sound".localized)
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.titleTextColor)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.descriptionTextColor)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(themeManager.secondaryBackgroundColor)
                        )

                }
                .pointingHandCursor()
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // 声音选项列表
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(TDSoundModel.allSounds) { sound in
                        soundOption(sound)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .frame(width: 300, height: 400)
        .background(themeManager.backgroundColor)
        .cornerRadius(16)
    }
    
    /// 声音选项
    private func soundOption(_ sound: TDSoundModel) -> some View {
        Button(action: {
            selectedSound = sound
            isPresented = false
        }) {
            HStack(spacing: 12) {
                Image(sound.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(themeManager.color(level: 5))
                
                Text(sound.name)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.titleTextColor)
                
                Spacer()
                
                if selectedSound.id == sound.id {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.color(level: 5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedSound.id == sound.id ? themeManager.color(level: 5).opacity(0.1) : themeManager.secondaryBackgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }
}

#Preview {
    TDSoundPickerView(
        selectedSound: .constant(TDSoundModel.defaultSound),
        isPresented: .constant(true)
    )
    .environmentObject(TDThemeManager.shared)
}
