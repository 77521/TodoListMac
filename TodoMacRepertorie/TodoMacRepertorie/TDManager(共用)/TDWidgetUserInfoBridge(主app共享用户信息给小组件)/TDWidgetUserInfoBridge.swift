//
//  TDWidgetUserInfoBridge.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/2/26.
//

import Foundation

enum TDWidgetUserInfoBridge {
    private static let relativePath = "Shared/td_shared_user.json"

    static func write(user: TDUserModel) {
        guard let json = TDSwiftJsonUtil.modelToJson(user) else { return }
        // 统一走 AppGroup 文件（FileManager.containerURL）
        _ = TDAppGroupFileStore.writeString(relativePath: relativePath, content: json)
        // 写入后立刻刷新小组件（调用方不需要再额外 reload）
        TDWidgetReloadBridge.reloadListMode()
    }

    static func clear() {
        TDAppGroupFileStore.remove(relativePath: relativePath)
        // 删除后立刻刷新小组件
        TDWidgetReloadBridge.reloadListMode()
    }
}
