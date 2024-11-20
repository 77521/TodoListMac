//
//  TDSliderBarModel.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/13.
//

import Foundation
import SwiftUI
import HandyJSON
import DynamicColor

struct TDSliderBarModel: HandyJSON, Codable, Identifiable, Hashable {
    // MARK: - 数据库字段
    var id: Int = -100  // 用于标识不同类型的菜单项
    var categoryId: Int = -100  // 分类ID
    var categoryName: String = "未分类"  // 分类名称
    var categoryColor: String = ""  // 分类颜色（网络数据使用）
    var createTime: Int64 = 0  // 创建时间
    var listSort: Double = 0.0  // 排序值，从100开始，每次增加100
    var anchor: Int = 0  // 最大更改值
    var userId: Int = 0  // 用户ID
    var headerIcon: String = ""  // 图标
    var dayTodoNoFinishNumber: Int = 10  // DayTodo未完成数量
    
    // MARK: - UI状态
    var isSelect: Bool = false  // 是否选中
    var categoryDatas: [TDSliderBarModel] = []  // 子分类数据
    
    // MARK: - 计算属性
    var type: TDGroupType {
        switch categoryId {
        case -100: return .fixed(.dayTodo)
        case -101: return .fixed(.recentTodo)
        case -102: return .fixed(.scheduleOverview)
        case -103: return .fixed(.todoBox)
        case -104: return .category
        case -105: return .tag
        case -106: return .stats(.dataStats)
        case -107: return .stats(.recentCompleted)
        case -108: return .stats(.trash)
        default: return .category
        }
    }
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(categoryId)  // 使用 categoryId 作为唯一标识
    }
    
    // MARK: - Equatable
    static func == (lhs: TDSliderBarModel, rhs: TDSliderBarModel) -> Bool {
        return lhs.categoryId == rhs.categoryId
    }
}
enum TDGroupType: Codable, Equatable {
    case fixed(FixedType)
    case category
    case tag
    case stats(StatsType)
    
    // 固定组类型
    enum FixedType: Int, Codable {
        case dayTodo
        case recentTodo
        case scheduleOverview
        case todoBox
    }
    
    // 统计组类型
    enum StatsType: Int, Codable {
        case dataStats
        case recentCompleted
        case trash
    }
    
    var canCollapse: Bool {
        switch self {
        case .category, .tag: return true
        case .fixed, .stats: return false
        }
    }
    
    var showHeader: Bool {
        switch self {
        case .category, .tag: return true
        case .fixed, .stats: return false
        }
    }
}
