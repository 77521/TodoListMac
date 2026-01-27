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
    
    /// 获取文件夹及其子分类的完整数据结构（按照 iOS 逻辑）
    /// - Parameter categories: 从服务器获取的原始分类数组
    /// - Returns: 返回处理后的分类数组，包含文件夹、顶级分类和子分类数据，类型为 [TDSliderBarModel]
    func getFolderWithSubCategories(from categories: [TDSliderBarModel]) -> [TDSliderBarModel] {
        // 1. 获取所有文件夹数据 (folderIs == true, delete == false, userId == 当前用户ID)，按listSort升序排序
        let folderDatas = categories
            .filter {
                $0.folderIs == true &&
                ($0.delete == false || $0.delete == nil) &&
                ($0.userId == userId || $0.userId == nil)
            }
            .sorted { (item1, item2) -> Bool in
                let sort1 = item1.listSort ?? 0
                let sort2 = item2.listSort ?? 0
                return sort1 < sort2
            }
        
        // 2. 获取所有分类数据 (folderIs == false, delete == false, userId == 当前用户ID)，按listSort升序排序
        let categoryDatas = categories
            .filter {
                $0.folderIs == false &&
                ($0.delete == false || $0.delete == nil) &&
                ($0.userId == userId || $0.userId == nil)
            }
            .sorted { (item1, item2) -> Bool in
                let sort1 = item1.listSort ?? 0
                let sort2 = item2.listSort ?? 0
                return sort1 < sort2
            }
        // 3. 处理文件夹，将分类添加到对应文件夹的 children 中
        // 注意：文件夹即使没有子分类也要显示，可以展开/关闭
        var processedFolders: [TDSliderBarModel] = []
        for var folder in folderDatas {
            // 初始化子分类数组
            var childModels: [TDSliderBarModel] = []
            
            // 查找属于当前文件夹的子分类（folderId > 0 且 folderId == 文件夹的 categoryId）
            for category in categoryDatas {
                if let folderId = category.folderId, folderId > 0, folderId == folder.categoryId {
                    childModels.append(category)
                }
            }
            
            // 将子分类添加到文件夹的 children 中（即使为空也要设置，因为文件夹本身需要显示）
            folder.children = childModels.isEmpty ? [] : childModels
            processedFolders.append(folder)
        }
        
        // 4. 获取所有顶级分类（folderIs == false 且 folderId == 0 或 folderId 不匹配任何文件夹）
        var topLevelCategories: [TDSliderBarModel] = []
        for category in categoryDatas {
            if let folderId = category.folderId {
                if folderId == 0 {
                    // folderId == 0 表示顶级分类
                    topLevelCategories.append(category)
                } else {
                    // 检查是否属于某个文件夹，如果不属于则也作为顶级分类显示
                    let belongsToFolder = folderDatas.contains { $0.categoryId == folderId }
                    if !belongsToFolder {
                        topLevelCategories.append(category)
                    }
                }
            } else {
                // folderId 为 nil，也作为顶级分类显示
                topLevelCategories.append(category)
            }
        }
        
        // 5. 合并文件夹和顶级分类，一起按 listSort 升序排序
        var resultArray = processedFolders
        resultArray.append(contentsOf: topLevelCategories)
        
        let sortedResult = resultArray.sorted { (item1, item2) -> Bool in
            let sort1 = item1.listSort ?? 0
            let sort2 = item2.listSort ?? 0
            return sort1 < sort2
        }
        
        return sortedResult
    }

    /// 获取所有文件夹数据（folderIs == true, delete == false, userId == 当前用户ID）
    /// - Parameter categories: 从服务器获取的原始分类数组
    /// - Returns: 返回所有文件夹数组，按listSort升序排序
    func getAllFolders(from categories: [TDSliderBarModel]) -> [TDSliderBarModel] {
        return categories
            .filter {
                $0.folderIs == true &&
                ($0.delete == false || $0.delete == nil) &&
                ($0.userId == userId || $0.userId == nil)
            }
            .sorted { (item1, item2) -> Bool in
                let sort1 = item1.listSort ?? 0
                let sort2 = item2.listSort ?? 0
                return sort1 < sort2
            }
    }

    /// 获取当前用户已创建的“分类清单”数量（不含文件夹、不含系统默认项）
    /// 用于非会员限制：最多 3 个分类清单。
    func userCreatedCategoryCount() -> Int {
        let categories = loadLocalCategories()
        return categories.filter { item in
            // 只统计服务器真实分类（通常为正数 id），忽略本地默认项（负数 id）
            guard item.categoryId > 0 else { return false }
            // 只统计当前用户数据
            guard item.userId == userId else { return false }
            // 只统计未删除（delete = false；兼容旧数据 delete 可能为 nil 的情况）
            guard item.delete == false || item.delete == nil else { return false }
            // folderIs == true 为文件夹；其余视作分类清单
            return item.folderIs != true
        }.count
    }

    
    /// 判断本地是否已经存在相同色值（忽略 alpha，忽略大小写）
    /// - Parameter colorHex: 颜色（十六进制字符串，如 `#RRGGBB` / `#RRGGBBAA`）
    func hasDuplicateColor(_ colorHex: String) -> Bool {
        let target = normalizeHexColor(colorHex)
        guard !target.isEmpty else { return false }
        
        let categories = loadLocalCategories()
        return categories.contains { item in
            // 仅比较当前用户数据
            guard item.userId == userId else { return false }
            // 仅比较未删除数据（delete = false；兼容旧数据 delete 可能为 nil 的情况）
            guard item.delete == false || item.delete == nil else { return false }
            guard let c = item.categoryColor else { return false }
            return normalizeHexColor(c) == target
        }
    }
    
    /// 统一 hex 表达：输出 `#RRGGBB`（忽略 alpha），并做大小写/空白清理
    private func normalizeHexColor(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        var hex = trimmed
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }
        hex = hex.uppercased()
        
        // 支持：RRGGBB / RRGGBBAA / RGB / RGBA（尽量宽容，但最终统一为 RRGGBB）
        if hex.count == 8 {
            hex = String(hex.prefix(6)) // 去掉 AA
        } else if hex.count == 4 {
            // RGBA -> RRGGBB（忽略 A）
            let chars = Array(hex)
            hex = "\(chars[0])\(chars[0])\(chars[1])\(chars[1])\(chars[2])\(chars[2])"
        } else if hex.count == 3 {
            // RGB -> RRGGBB
            let chars = Array(hex)
            hex = "\(chars[0])\(chars[0])\(chars[1])\(chars[1])\(chars[2])\(chars[2])"
        } else if hex.count != 6 {
            // 其他长度不处理
            return ""
        }
        
        return "#\(hex)"
    }


}
