//
//  TDCategoryAPI.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation

actor TDCategoryAPI {
    static let shared = TDCategoryAPI()
    private init() {}
    
    // MARK: - 获取分类列表
    func getCategoryList() async throws -> [TDSliderBarModel] {
        return try await TDNetworkManager.shared.fetchList(
            endpoint: "getCategoryList"
        )
    }
    
    // MARK: - 添加分类/文件夹
    /// - Parameters:
    ///   - name: 分类/文件夹名称
    ///   - color: 颜色（十六进制字符串）
    ///   - isFolder: 是否为文件夹
    ///   - parentFolderId: 归属文件夹ID（仅“分类清单”使用；nil/0 表示不归属任何文件夹，此时不传 folderId）
    func addCategory(name: String, color: String, isFolder: Bool, parentFolderId: Int?) async throws {
        // 按 iOS 端约定：
        // 1) 新建“文件夹”：只传 folderIs=true，不传 folderId（因为没有归属文件夹）
        // 2) 新建“分类清单”：只有选择了归属文件夹才传 folderId；选择“无”则不传
        var parameters: [String: Any] = [
            "categoryName": name,
            "categoryColor": color,
            "isFolder": isFolder
        ]

        if !isFolder, let parentFolderId, parentFolderId > 0 {
            parameters["folderId"] = parentFolderId
        }
        
        _ = try await TDNetworkManager.shared.request(
            endpoint: "addCategoryList",
            parameters: parameters,
            responseType: TDEmptyResponse.self
        )
    }

    // MARK: - 更新分类信息（名字和颜色）
    /// - Parameters:
    ///   - isFolder: 仅在“编辑文件夹”时需要传 true（按 iOS 端约定）；编辑分类清单无需传该参数
    ///   - folderId: 仅在更新“分类清单”所属文件夹时需要（传 0 表示不归属任何文件夹）
    func updateCategoryInfo(categoryId: Int, name: String, color: String, isFolder: Bool? = nil, folderId: Int? = nil) async throws {
        var parameters: [String: Any] = [
            "categoryId": categoryId,
            "categoryName": name,
            "categoryColor": color
        ]

        if let isFolder, isFolder == true {
            parameters["isFolder"] = true
        }

        if let folderId {
            parameters["folderId"] = folderId
        }
        
        _ = try await TDNetworkManager.shared.request(
            endpoint: "updateCategoryList",
            parameters: parameters,
            responseType: TDEmptyResponse.self
        )
    }


    // MARK: - 更新分类排序
    func updateCategorySort(categoryId: Int, newSort: Double) async throws {
        let parameters: [String: Any] = [
            "categoryId": categoryId,
            "newListSort": newSort
        ]
        
        _ = try await TDNetworkManager.shared.request(
            endpoint: "updateCategorySort",
            parameters: parameters,
            responseType: TDEmptyResponse.self
        )
    }
    
    // MARK: - 删除分类
    func deleteCategory(categoryId: Int) async throws {
        let parameters: [String: Any] = ["categoryId": categoryId]
        
        _ = try await TDNetworkManager.shared.request(
            endpoint: "deleteCategoryList",
            parameters: parameters,
            responseType: TDEmptyResponse.self
        )
    }
}
