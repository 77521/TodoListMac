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
            } else {
                // 本地没有缓存时加载网络图片
                AsyncImage(url: avatarURL) { phase in
                    handleImagePhase(phase)
                }
            }
        }
        .frame(width: 28, height: 28)
    }
    
    @ViewBuilder
    private func handleImagePhase(_ phase: AsyncImagePhase) -> some View {
        switch phase {
        case .empty:
            Circle()
                .fill(Color(white: 0.9))
                .overlay(
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)
                )
        case .success(let image):
            image
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        case .failure:
            Circle()
                .fill(Color(white: 0.9))
                .overlay(
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .padding(6)
                )
        @unknown default:
            EmptyView()
        }
    }
}

