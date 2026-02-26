//
//  TDWidgetUserSession.swift
//  TDMacWidgetExtension
//
//  Created by 赵浩 on 2026/2/26.
//

import Foundation

enum TDWidgetUserSession {
    private static let relativePath = "Shared/td_shared_user.json"

    /// 读取当前用户（纯同步读取 AppGroup 文件，供 Provider/Entry 同步调用）
    static func currentUser() -> TDUserModel? {
        // 优先读 AppGroup 文件（FileManager.containerURL）
        let json = TDAppGroupFileStore.readString(relativePath: relativePath)

        guard let json, !json.isEmpty,
              let user = TDSwiftJsonUtil.jsonToModel(json, TDUserModel.self),
              !user.token.isEmpty else { return nil }
        return user
    }
}

