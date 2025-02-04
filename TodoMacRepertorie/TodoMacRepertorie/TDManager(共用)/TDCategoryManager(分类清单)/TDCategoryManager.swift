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
    private var categoriesFileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appSupportURL = documentsDirectory.appendingPathComponent("TodoList", isDirectory: true)
        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        return appSupportURL.appendingPathComponent("categories.json")
    }
    
    // 从文件加载分类数据
    func loadLocalCategories() -> [TDSliderBarModel] {
        do {
            let data = try Data(contentsOf: categoriesFileURL)
            let categories = try JSONDecoder().decode([TDSliderBarModel].self, from: data)
            return categories
        } catch {
            print("加载本地分类数据失败：\(error)")
            return TDSliderBarModel.defaultItems
        }
    }
    
    // 保存分类数据到文件
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
    
    // 清除本地分类数据
    func clearLocalCategories() {
        try? FileManager.default.removeItem(at: categoriesFileURL)
    }
    
    /// 根据分类ID获取分类信息
    func getCategory(id: Int) -> TDSliderBarModel? {
        // 从本地文件加载所有分类
        let categories = loadLocalCategories()
        
        // 查找匹配的分类
        return categories.first { $0.categoryId == id }
    }
    
}
