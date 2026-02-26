//
//  AppIntent.swift
//  TDMacWidget
//
//  Created by 赵浩 on 2025/5/7.
//
//
//import WidgetKit
//import AppIntents
//
//struct ConfigurationAppIntent: WidgetConfigurationIntent {
//    static var title: LocalizedStringResource { "Configuration" }
//    static var description: IntentDescription { "This is an example widget." }
//
//    // An example configurable parameter.
//    @Parameter(title: "Favorite Emoji", default: "😃")
//    var favoriteEmoji: String
//}


//
//  AppIntent.swift
//  TDMacWidget
//
//  列表类型小组件编辑配置：查看类型（Day Todo / 最近待办 / 分类清单）、分类选择、是否显示已过期
//  命名带 TD 前缀，后续其它小组件可单独定义自己的 Configuration Intent
//

import WidgetKit
import AppIntents

// MARK: - 列表类型 - 查看类型

enum TDWidgetListViewType: String, AppEnum {
    case dayTodo
    case recentTodos
    case categoryList

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "查看")
    }

    static var caseDisplayRepresentations: [TDWidgetListViewType: DisplayRepresentation] {
        [
            .dayTodo: DisplayRepresentation(title: "Day Todo"),
            .recentTodos: DisplayRepresentation(title: "最近待办"),
            .categoryList: DisplayRepresentation(title: "分类清单")
        ]
    }
}

// MARK: - 列表类型 - 分类实体（供配置里「分类清单」选择）

struct TDWidgetCategoryEntity: AppEntity {
    let categoryId: Int
    let categoryName: String

    var id: String { "\(categoryId)" }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "分类清单")
    }

    static var defaultQuery = TDWidgetCategoryQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(categoryName)")
    }
}

struct TDWidgetCategoryQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [TDWidgetCategoryEntity] {
        let userId = TDWidgetUserSession.currentUser()?.userId ?? -1
        let categories = TDCategoryManager.shared.loadLocalCategories(userId: userId)
        return identifiers.compactMap { id -> TDWidgetCategoryEntity? in
            guard let cid = Int(id) else { return nil }
            return categories.first { $0.categoryId == cid }.map {
                TDWidgetCategoryEntity(categoryId: $0.categoryId, categoryName: $0.categoryName)
            }
        }
    }

    func suggestedEntities() async throws -> [TDWidgetCategoryEntity] {
        let userId = TDWidgetUserSession.currentUser()?.userId ?? -1
        let categories = TDCategoryManager.shared.loadLocalCategories(userId: userId)
        return categories
            .filter { $0.categoryId > 0 && ($0.folderIs != true) }
            .map { TDWidgetCategoryEntity(categoryId: $0.categoryId, categoryName: $0.categoryName) }
    }
}

// MARK: - 列表类型编辑（仅用于列表模式小组件，其它小组件可另建 Intent）

struct TDListTypeConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "列表类型编辑" }
    static var description: IntentDescription { "选择小组件要显示的列表类型与选项（Day Todo / 最近待办 / 分类清单）" }

    /// 查看：Day Todo / 最近待办 / 分类清单
    @Parameter(title: "查看", default: .dayTodo)
    var viewType: TDWidgetListViewType

    /// 分类清单（仅当 viewType 为 分类清单 时显示）
    @Parameter(title: "分类清单")
    var category: TDWidgetCategoryEntity?

    /// 是否显示已过期（仅当 最近待办 或 分类清单 时显示）
    @Parameter(title: "显示已过期", default: true)
    var showExpired: Bool

    
    
    /// 根据「查看」类型决定展示的配置项：Day Todo 只显示查看；最近待办 多显示「显示已过期」；分类清单 多显示「分类清单」+「显示已过期」
    static var parameterSummary: some ParameterSummary {
        When(\.$viewType, .equalTo, TDWidgetListViewType.dayTodo) {
            Summary("查看 \(\.$viewType)")
        } otherwise: {
            When(\.$viewType, .equalTo, TDWidgetListViewType.recentTodos) {
                Summary("查看 \(\.$viewType)") {
                    \.$showExpired
                }
            } otherwise: {
                Summary("查看 \(\.$viewType)") {
                    \.$category
                    \.$showExpired
                }
            }
        }
    }
}
