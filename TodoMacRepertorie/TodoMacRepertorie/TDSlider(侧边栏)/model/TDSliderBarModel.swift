//
//  TDSliderBarModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import Foundation
import SwiftUI
//import HandyJSON
//import DynamicColor

/// 侧边栏数据模型
struct TDSliderBarModel: Identifiable, Codable, Equatable {
//    var id = UUID().uuidString
    
    // MARK: - 服务器返回的字段
    var categoryId: Int          // 分类ID
    var categoryName: String     // 分类名称
    var categoryColor: String?   // 分类颜色(十六进制)
    var createTime: Int64?      // 创建时间
    var delete: Bool?            // 是否删除(0:未删除)
    var listSort: Double?          // 排序值
    var userId: Int?            // 用户ID
    
    // MARK: - 本地使用的字段
    var headerIcon: String?      // 系统图标名称
    var unfinishedCount: Int?  // 未完成数量
    var isSelect: Bool?   // 是否选中
    var children: [TDSliderBarModel]?

    var id: Int { categoryId }

    init(categoryId: Int,
         categoryName: String,
         headerIcon: String?,
         categoryColor: String? = nil,
         createTime: Int64? = nil,
         delete: Bool? = nil,
         listSort: Double? = nil,
         userId: Int? = nil,
         unfinishedCount: Int?,
         isSelect: Bool? = false,
         isExpanded: Bool? = false,
         children: [TDSliderBarModel]? = nil) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.headerIcon = headerIcon
        self.categoryColor = categoryColor
        self.createTime = createTime
        self.delete = delete
        self.listSort = listSort
        self.userId = userId
        self.unfinishedCount = unfinishedCount
        self.isSelect = isSelect
        self.children = children
    }

    
    // MARK: - 系统默认项目
    static let defaultItems: [TDSliderBarModel] = [
        // DayTodo
        TDSliderBarModel(categoryId: -100, categoryName: "DayTodo", headerIcon: "calendar"),
        // 最近待办
        TDSliderBarModel(categoryId: -101, categoryName: "最近待办", headerIcon: "clock"),
        // 日程概览
        TDSliderBarModel(categoryId: -102, categoryName: "日程概览", headerIcon: "calendar.day.timeline.left"),
        // 待办箱
        TDSliderBarModel(categoryId: -103, categoryName: "待办箱", headerIcon: "tray"),
        // 分类清单(分组)
        TDSliderBarModel(categoryId: -104, categoryName: "分类清单", headerIcon: "list.bullet"),
        // 标签(分组)
        TDSliderBarModel(categoryId: -105, categoryName: "标签", headerIcon: "tag"),
        // 数据统计
        TDSliderBarModel(categoryId: -106, categoryName: "数据统计", headerIcon: "chart.bar"),
        // 最近已完成
        TDSliderBarModel(categoryId: -107, categoryName: "最近已完成", headerIcon: "checkmark.circle"),
        // 回收站
        TDSliderBarModel(categoryId: -108, categoryName: "回收站", headerIcon: "trash")
    ]
    
    // MARK: - 初始化方法
    
    /// 创建系统默认项目
    init(categoryId: Int, categoryName: String, headerIcon: String) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.headerIcon = headerIcon
    }
    
    /// 创建未分类项目
    static var uncategorized: TDSliderBarModel {
        TDSliderBarModel(categoryId: 0, categoryName: "未分类", headerIcon: "circle")
    }
    
    /// 创建所有标签项目
    static var allTags: TDSliderBarModel {
        TDSliderBarModel(categoryId: -1000, categoryName: "所有标签", headerIcon: "tag")
    }
    
    // MARK: - 辅助方法
    
    /// 判断是否为分组类型
    var isGroup: Bool {
        categoryId == -104 || categoryId == -105
    }
    
    /// 判断是否为标签类型
    var isTag: Bool {
        categoryId == -1000
    }
}
