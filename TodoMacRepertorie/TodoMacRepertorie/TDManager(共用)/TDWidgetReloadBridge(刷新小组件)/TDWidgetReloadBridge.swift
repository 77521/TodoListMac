//
//  TDWidgetReloadBridge.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2026/2/26.
//

import Foundation


#if canImport(WidgetKit)
import WidgetKit
#endif

enum TDWidgetReloadBridge {
    /// 当前小组件 kind（与 Widget Extension 里保持一致）
    static let listModeKind = "TDMacWidgetListMode"

    /// 刷新列表模式小组件（登录信息/后续任务数据都可以复用）
    static func reloadListMode() {
        reload(kind: listModeKind)
    }

    /// 刷新指定 kind
    static func reload(kind: String) {
#if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
//        WidgetCenter.shared.reloadAllTimelines()
#endif
    }

    /// 仅全量刷新（不指定 kind）
    static func reloadAll() {
#if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
#endif
    }
}
