//
//  TDCategoryAPI.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/13.
//

import Foundation

class TDCategoryAPI {
    /// 获取分类列表
    static func getCategories() async throws -> [TDSliderBarModel] {
        return try await withCheckedThrowingContinuation { continuation in
            TDNetworkManager.shared.requestList("getCategoryList") { (result: Result<[TDSliderBarModel], TDNetworkManager.TDNetworkError>) in
                switch result {
                case .success(let categories):
                    continuation.resume(returning: categories)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 更新分类排序
    static func updateCategorySort(_ categories: [TDSliderBarModel]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let params = categories.map { [
                "categoryId": $0.categoryId,
                "listSort": $0.listSort
            ] }
            
            TDNetworkManager.shared.request("category/sort",
                                          parameters: ["categories": params]) { (result: Result<TDBaseResponse<TDEmptyResponse>?, TDNetworkManager.TDNetworkError>) in
                switch result {
                case .success(let response):
                    if let response = response, response.code == 0 {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: TDNetworkManager.TDNetworkError.network("更新失败"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 修改分类
    static func updateCategory(_ category: TDSliderBarModel) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let params: [String: Any] = [
                "categoryId": category.categoryId,
                "categoryName": category.categoryName,
                "categoryColor": category.categoryColor,
                "headerIcon": category.headerIcon
            ]
            
            TDNetworkManager.shared.request("category/update",
                                          parameters: params) { (result: Result<TDBaseResponse<TDEmptyResponse>?, TDNetworkManager.TDNetworkError>) in
                switch result {
                case .success(let response):
                    if let response = response, response.code == 0 {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: TDNetworkManager.TDNetworkError.network("修改失败"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 删除分类
    static func deleteCategory(_ categoryId: Int) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            TDNetworkManager.shared.request("category/delete",
                                          parameters: ["categoryId": categoryId]) { (result: Result<TDBaseResponse<TDEmptyResponse>?, TDNetworkManager.TDNetworkError>) in
                switch result {
                case .success(let response):
                    if let response = response, response.code == 0 {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: TDNetworkManager.TDNetworkError.network("删除失败"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

}
