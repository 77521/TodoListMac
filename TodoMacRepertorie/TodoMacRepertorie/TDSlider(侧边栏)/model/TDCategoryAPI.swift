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
    
    // MARK: - 添加分类
    func addCategory(name: String, color: String) async throws {
        let parameters: [String: Any] = [
            "categoryName": name,
            "categoryColor": color
        ]
        
        _ = try await TDNetworkManager.shared.request(
            endpoint: "addCategoryList",
            parameters: parameters,
            responseType: TDEmptyResponse.self
        )
    }
    
    // MARK: - 更新分类信息（名字和颜色）
    func updateCategoryInfo(categoryId: Int, name: String, color: String) async throws {
        let parameters: [String: Any] = [
            "categoryId": categoryId,
            "categoryName": name,
            "categoryColor": color
        ]
        
        _ = try await TDNetworkManager.shared.request(
            endpoint: "updateCategoryList",
            parameters: parameters,
            responseType: TDEmptyResponse.self
        )
    }
    
    // MARK: - 更新分类排序
    func updateCategorySort(categoryId: Int, newSort: Int) async throws {
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
