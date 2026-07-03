//
//  TDHeaderImageView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import AppKit

/// 侧边栏用户头像视图
/// 加载优先级：本地缓存 → 远程 URL → 首字母占位（主题色背景）
struct TDHeaderImageView: View {
    /// 远程头像 URL
    let avatarURL: URL?
    /// 用户 ID（用于本地缓存 key）
    let userId: Int
    /// 用户昵称（取首字符作为占位文字）
    var nickname: String = ""

    @ObservedObject private var themeManager = TDThemeManager.shared

    var body: some View {
        Group {
            if let localURL = TDAvatarManager.shared.getLocalAvatarURL(for: userId) {
                // 优先使用本地缓存头像（已下载过）
                AsyncImage(url: localURL) { phase in
                    avatarPhase(phase)
                }
            } else if let remoteURL = avatarURL {
                // 有网络地址时再发起请求，避免空 URL 触发 loading
                AsyncImage(url: remoteURL) { phase in
                    avatarPhase(phase)
                }
            } else {
                // 无头像：显示首字母 + 主题色背景
                initialsView
            }
        }
        .frame(width: 32, height: 32)
    }

    // MARK: - 异步图片状态处理
    @ViewBuilder
    private func avatarPhase(_ phase: AsyncImagePhase) -> some View {
        switch phase {
        case .success(let image):
            image
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        case .empty, .failure:
            // 加载中或失败均降级到首字母占位
            initialsView
        @unknown default:
            initialsView
        }
    }

    // MARK: - 首字母占位视图
    private var initialsView: some View {
        Circle()
            .fill(themeManager.color(level: 5))
            .overlay(
                Text(initialsText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            )
    }

    /// 取昵称首字符大写，无昵称时显示 "U"
    private var initialsText: String {
        nickname.first.map { String($0).uppercased() } ?? "U"
    }
}
