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

struct TDSliderBarModel: HandyJSON, Codable, Identifiable, Equatable {
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
    var dayTodoNoFinishNumber: Int = 0  // DayTodo未完成数量
    
    // MARK: - UI状态
    var isSelect: Bool = false  // 是否选中
    var isHovering: Bool = false  // 鼠标是否悬停
    var categoryDatas: [TDSliderBarModel] = []  // 子分类数据
    
    // MARK: - 计算属性
    var type: TDGroupType {
        switch categoryId {
        case -100: return .fixed      // DayTodo
        case -101: return .fixed      // 最近待办
        case -102: return .fixed      // 日程概览
        case -103: return .fixed      // 待办箱
        case -104: return .category   // 分类清单
        case -105: return .tag        // 标签
        case -106: return .stats      // 数据统计
        case -107: return .stats      // 最近已完成
        case -108: return .stats      // 回收站
        default: return .category     // 默认为分类
        }
    }
    
    var displayIcon: String {
        if !headerIcon.isEmpty { return headerIcon }
        switch categoryId {
        case -100: return "calendar"
        case -101: return "clock"
        case -102: return "calendar.badge.clock"
        case -103: return "tray.full"
        case -104: return "folder"
        case -105: return "tag"
        case -106: return "chart.bar"
        case -107: return "checkmark.circle"
        case -108: return "trash"
        default: return "tray"
        }
    }
    
    var displayColor: Color {
        if !categoryColor.isEmpty {
            return Color(hexString: categoryColor)
        }
        switch categoryId {
        case -100: return Color(hexString: "#30B0C7")
        default: return .primary
        }
    }
}
/// 分组类型
enum TDGroupType: Int, Codable {
    case fixed      // 固定组（DayTodo等）
    case category   // 分类清单组
    case tag        // 标签组
    case stats      // 统计组
    
    var canCollapse: Bool {
        switch self {
        case .category, .tag: return true  // 只有分类和标签组可以折叠
        case .fixed, .stats: return false
        }
    }
    
    var showHeader: Bool {
        switch self {
        case .category, .tag: return true  // 只有分类和标签组显示组头
        case .fixed, .stats: return false
        }
    }
}
