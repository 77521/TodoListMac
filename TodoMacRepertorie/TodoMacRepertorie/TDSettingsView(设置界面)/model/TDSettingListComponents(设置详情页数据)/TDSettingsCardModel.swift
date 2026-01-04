//
//  TDSettingsCardModel.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/12/18.
//

import Foundation

struct TDSettingsCardModel: Identifiable {
    let id = UUID()
    let rows: [TDSettingsRow]
}

enum TDSettingsRow: Hashable {
    case info(title: String, value: String?, disclosure: Bool = true)
    case gender
    case binding(title: String, bound: Bool)
    case footer(String)
}
