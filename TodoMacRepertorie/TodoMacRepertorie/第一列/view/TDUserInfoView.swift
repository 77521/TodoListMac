//
//  TDUserInfoView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/18.
//

import SwiftUI

struct TDUserInfoView: View {
    @StateObject private var userManager = TDUserManager.shared

    var body: some View {
        HStack(spacing: 8) {
            TDHeaderImageView(avatarURL: userManager.avatarURL, userId: userManager.userId ?? 0)

            VStack(alignment: .leading, spacing: 0) {
                Text(userManager.nickname)
                    .foregroundColor(.white)
                    .font(.system(size: 12))
                    .lineLimit(1)
                
                Text(userManager.account)
                    .foregroundColor(.greyColor4)
                    .font(.system(size: 12))
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 8)  // 添加垂直内边距
    }
}

#Preview {
    TDUserInfoView()
}
