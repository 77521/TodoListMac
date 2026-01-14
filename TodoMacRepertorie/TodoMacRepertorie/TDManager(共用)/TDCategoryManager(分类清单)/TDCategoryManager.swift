//
//  TDCategoryManager.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI

class TDCategoryManager: ObservableObject {
    static let shared = TDCategoryManager()
    // 使用 FileManager 存储在 Application Support 目录
    /// 当前用户ID（Int类型，-1 表示未登录）
    private var userId: Int {
        TDUserManager.shared.userId
    }

    /// 分类数据文件路径（App Group 目录下，按 userId 区分）
    private var categoriesFileURL: URL {
        // 1. 获取 App Group 目录（主程序和小组件都能访问）
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: TDAppConfig.appGroupId) else {
            fatalError("获取 App Group 目录失败")
        }
        // 2. 在 App Group 目录下创建 categories 子目录
        let userDir = appGroupURL.appendingPathComponent("categories", isDirectory: true)
        try? FileManager.default.createDirectory(at: userDir, withIntermediateDirectories: true)
        // 3. 每个用户一个 json 文件，文件名带 userId
        return userDir.appendingPathComponent("categories_\(userId).json")
    }

    /// 从文件加载分类数据（按当前 userId，主程序和小组件都能用）
    /// - Returns: 分类数组，如果失败则返回默认分类
    func loadLocalCategories() -> [TDSliderBarModel] {
        do {
            let data = try Data(contentsOf: categoriesFileURL)
            let categories = try JSONDecoder().decode([TDSliderBarModel].self, from: data)
            return categories
        } catch {
            print("加载本地分类数据失败：\(error)")
            return TDSliderBarModel.defaultItems(settingManager: TDSettingManager.shared)
        }
    }
    
    /// 保存分类数据到文件（按当前 userId，主程序和小组件都能用）
    /// - Parameter categories: 要保存的分类数组
    func saveCategories(_ categories: [TDSliderBarModel]) async {
        await withCheckedContinuation { continuation in
            Task.detached {
                do {
                    let data = try JSONEncoder().encode(categories)
                    try data.write(to: self.categoriesFileURL)
                } catch {
                    print("保存分类数据失败：\(error)")
                }
                continuation.resume()
            }
        }
    }
    
    /// 清除本地分类数据（只清除当前 userId 的数据，主程序和小组件都能用）
    func clearLocalCategories() {
        try? FileManager.default.removeItem(at: categoriesFileURL)
    }
    
    /// 根据分类ID获取分类信息（按当前 userId，主程序和小组件都能用）
    /// - Parameter id: 分类ID
    /// - Returns: 匹配的分类模型或 nil
    func getCategory(id: Int) -> TDSliderBarModel? {
        let categories = loadLocalCategories()
        return categories.first { $0.categoryId == id }
    }

}
