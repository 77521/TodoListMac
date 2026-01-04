//
//  TDHeaderImageView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI

struct TDHeaderImageView: View {
    let avatarURL: URL?
    let userId: Int
    
    var body: some View {
        Group {
            if let localURL = TDAvatarManager.shared.getLocalAvatarURL(for: userId) {
                // 优先使用本地缓存的头像
                AsyncImage(url: localURL) { phase in
                    handleImagePhase(phase)
                }
            } else if let remoteURL = avatarURL {
                // 有网络地址时再加载，避免空 URL 进入 loading
                AsyncImage(url: remoteURL) { phase in
                    handleImagePhase(phase)
                }
            } else {
                // 无头像地址时直接展示占位
                placeholderView
            }
        }
        .frame(width: 28, height: 28)
    }
    
    @ViewBuilder
    private func handleImagePhase(_ phase: AsyncImagePhase) -> some View {
        switch phase {
        case .empty:
            placeholderView
        case .success(let image):
            image
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        case .failure:
            placeholderView
        @unknown default:
            EmptyView()
        }
    }
    
    private var placeholderView: some View {
        Circle()
            .fill(Color(white: 0.9))
            .overlay(
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
                    .padding(6)
            )
    }

}

