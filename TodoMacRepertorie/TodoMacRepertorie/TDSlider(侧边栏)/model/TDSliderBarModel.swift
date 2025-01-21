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
struct TDSliderBarModel: Identifiable, Codable {
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

//struct TDSliderBarModel: Identifiable, Codable {
//    let categoryId: Int
//    let categoryName: String
//    let headerIcon: String?
//    let categoryColor: String?
//    let createTime: Int64?
//    let delete: Bool?
//    let listSort: Double?
//    let userId: Int?
//    var isSelect: Bool?
//    var isExpanded: Bool?
//    var children: [TDSliderBarModel]?
//    
//    var id: Int { categoryId }
//    
//    init(categoryId: Int,
//         categoryName: String,
//         headerIcon: String?,
//         categoryColor: String? = nil,
//         createTime: Int64? = nil,
//         delete: Bool? = nil,
//         listSort: Double? = nil,
//         userId: Int? = nil,
//         isSelect: Bool? = false,
//         isExpanded: Bool? = false,
//         children: [TDSliderBarModel]? = nil) {
//        self.categoryId = categoryId
//        self.categoryName = categoryName
//        self.headerIcon = headerIcon
//        self.categoryColor = categoryColor
//        self.createTime = createTime
//        self.delete = delete
//        self.listSort = listSort
//        self.userId = userId
//        self.isSelect = isSelect
//        self.isExpanded = isExpanded
//        self.children = children
//    }
//    
//    // 默认数据
//    static var defaultItems: [TDSliderBarModel] = [
//        // 固定组
//        TDSliderBarModel(categoryId: -100, categoryName: "DayTodo", headerIcon: "sun.min"),
//        TDSliderBarModel(categoryId: -101, categoryName: "最近待办", headerIcon: "note.text"),
//        TDSliderBarModel(categoryId: -102, categoryName: "日程概览", headerIcon: "calendar"),
//        TDSliderBarModel(categoryId: -103, categoryName: "待办箱", headerIcon: "tray.full.fill"),
//        
//        // 分类清单组
//        TDSliderBarModel(categoryId: -104, categoryName: "分类清单", headerIcon: "scroll", isSelect: true, isExpanded: true, children: [
//            TDSliderBarModel(categoryId: 0, categoryName: "未分类", headerIcon: "questionmark.circle")
//        ]),
//        
//        // 标签组
//        TDSliderBarModel(categoryId: -105, categoryName: "标签", headerIcon: "tag", isExpanded: false),
//        
//        // 统计组
//        TDSliderBarModel(categoryId: -106, categoryName: "数据统计", headerIcon: "chart.pie"),
//        TDSliderBarModel(categoryId: -107, categoryName: "最近已完成", headerIcon: "checkmark.square"),
//        TDSliderBarModel(categoryId: -108, categoryName: "回收站", headerIcon: "trash")
//    ]
//}

//struct TDSliderBarModel: HandyJSON, Codable, Identifiable, Hashable {
//    // MARK: - 数据库字段
//    var id: Int = -100  // 用于标识不同类型的菜单项
//    var categoryId: Int = -100  // 分类ID
//    var categoryName: String = "未分类"  // 分类名称
//    var categoryColor: String = ""  // 分类颜色（网络数据使用）
//    var createTime: Int64 = 0  // 创建时间
//    var listSort: Double = 0.0  // 排序值，从100开始，每次增加100
//    var anchor: Int = 0  // 最大更改值
//    var userId: Int = 0  // 用户ID
//    var headerIcon: String = ""  // 图标
//    var dayTodoNoFinishNumber: Int = 10  // DayTodo未完成数量
//    
//    // MARK: - UI状态
//    var isSelect: Bool = false  // 是否选中
//    var categoryDatas: [TDSliderBarModel] = []  // 子分类数据
//    
//    // MARK: - 计算属性
//    var type: TDGroupType {
//        switch categoryId {
//        case -100: return .fixed(.dayTodo)
//        case -101: return .fixed(.recentTodo)
//        case -102: return .fixed(.scheduleOverview)
//        case -103: return .fixed(.todoBox)
//        case -104: return .category
//        case -105: return .tag
//        case -106: return .stats(.dataStats)
//        case -107: return .stats(.recentCompleted)
//        case -108: return .stats(.trash)
//        default: return .category
//        }
//    }
//    // MARK: - Hashable
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(categoryId)  // 使用 categoryId 作为唯一标识
//    }
//    
//    // MARK: - Equatable
//    static func == (lhs: TDSliderBarModel, rhs: TDSliderBarModel) -> Bool {
//        return lhs.categoryId == rhs.categoryId
//    }
//}
//enum TDGroupType: Codable, Equatable {
//    case fixed(FixedType)
//    case category
//    case tag
//    case stats(StatsType)
//    
//    // 固定组类型
//    enum FixedType: Int, Codable {
//        case dayTodo
//        case recentTodo
//        case scheduleOverview
//        case todoBox
//    }
//    
//    // 统计组类型
//    enum StatsType: Int, Codable {
//        case dataStats
//        case recentCompleted
//        case trash
//    }
//    
//    var canCollapse: Bool {
//        switch self {
//        case .category, .tag: return true
//        case .fixed, .stats: return false
//        }
//    }
//    
//    var showHeader: Bool {
//        switch self {
//        case .category, .tag: return true
//        case .fixed, .stats: return false
//        }
//    }
//}
