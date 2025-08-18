//
//  TDGetCurrentVersionModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation

/// 服务器返回的最大版本号响应
struct TDGetCurrentVersionModel: Codable {
    let maxVersion: Int64
}
