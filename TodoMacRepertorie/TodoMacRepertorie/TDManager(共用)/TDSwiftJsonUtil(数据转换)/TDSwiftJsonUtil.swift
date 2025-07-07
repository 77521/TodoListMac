//
//  TDSwiftJsonUtil.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/6/10.
//

import Foundation
/// JSON 工具类
class TDSwiftJsonUtil {

    /// 从共享文件读取并转换为对象
    /// - Parameters:
    ///   - fileName: 文件名
    ///   - type: 目标类型
    /// - Returns: 转换后的对象，失败返回默认值
    static func readSharedFileToModel<T: Codable>(_ fileName: String, _ type: T.Type, defaultValue: T) -> T {
        // 获取共享容器URL
        guard let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.eve.todolist4ios") else {
            return defaultValue
        }
        
        // 构建文件路径
        let fileUrl = groupUrl.appendingPathComponent("Library/Caches/\(fileName)")
        
        // 读取文件内容
        guard let contentData = FileManager.default.contents(atPath: fileUrl.path),
              let content = String(data: contentData, encoding: .utf8) else {
            return defaultValue
        }
        
        // 转换为对象
        return jsonToModel(content, type) ?? defaultValue
    }
    
    /// JSON字符串转对象
    /// - Parameters:
    ///   - jsonString: JSON字符串
    ///   - type: 目标类型
    /// - Returns: 转换后的对象，失败返回nil
    static func jsonToModel<T: Codable>(_ jsonString: String, _ type: T.Type) -> T? {
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: jsonData)
    }
    
    /// JSON字符串转数组
    /// - Parameters:
    ///   - jsonString: JSON字符串
    ///   - type: 数组元素类型
    /// - Returns: 转换后的数组，失败返回nil
    static func jsonToArray<T: Codable>(_ jsonString: String, _ type: T.Type) -> [T]? {
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([T].self, from: jsonData)
    }
    
    /// 字典转对象
    /// - Parameters:
    ///   - dict: 字典
    ///   - type: 目标类型
    /// - Returns: 转换后的对象，失败返回nil
    static func dictToModel<T: Codable>(_ dict: [String: Any], _ type: T.Type) -> T? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return try? JSONDecoder().decode(type, from: jsonData)
    }
    
    /// 对象转JSON字符串
    /// - Parameter model: 对象
    /// - Returns: JSON字符串，失败返回nil
    static func modelToJson<T: Codable>(_ model: T) -> String? {
        guard let jsonData = try? JSONEncoder().encode(model) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }
    
    /// 对象转字典
    /// - Parameter model: 对象
    /// - Returns: 字典，失败返回nil
    static func modelToDict<T: Codable>(_ model: T) -> [String: Any]? {
        guard let jsonData = try? JSONEncoder().encode(model),
              let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }
        return dict
    }
    
    /// 数组转JSON字符串
    /// - Parameter array: 数组
    /// - Returns: JSON字符串，失败返回nil
    static func arrayToJson<T: Codable>(_ array: [T]) -> String? {
        guard let jsonData = try? JSONEncoder().encode(array) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }
}
