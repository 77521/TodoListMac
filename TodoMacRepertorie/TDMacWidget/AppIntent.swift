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

    /// 是否自动夜间模式（放在编辑项最后一行；关闭则永远按白天模式渲染）
    @Parameter(title: "自动夜间模式", default: true)
    var autoNightMode: Bool

    /// 根据「查看」类型决定展示的配置项：Day Todo 只显示查看；最近待办 多显示「显示已过期」；分类清单 多显示「分类清单」+「显示已过期」
    static var parameterSummary: some ParameterSummary {
        When(\.$viewType, .equalTo, TDWidgetListViewType.dayTodo) {
            Summary("查看 \(\.$viewType)") {
                \.$autoNightMode
            }
        } otherwise: {
            When(\.$viewType, .equalTo, TDWidgetListViewType.recentTodos) {
                Summary("查看 \(\.$viewType)") {
                    \.$showExpired
                    \.$autoNightMode
                }
            } otherwise: {
                Summary("查看 \(\.$viewType)") {
                    \.$category
                    \.$showExpired
                    \.$autoNightMode
                }
            }
        }
    }
}

// MARK: - 列表小组件：切换完成状态（点击左侧完成按钮）

struct TDWidgetListToggleCompleteIntent: AppIntent {
    static var title: LocalizedStringResource = "切换完成状态"

    @Parameter(title: "taskId")
    var taskId: String

    /// 让调用方可以直接用 String 创建 intent（否则会要求 IntentParameter<String>）
    init(taskId: String) {
        self.taskId = taskId
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        // 对齐主 App：先改本地数据（走 TDQueryConditionManager 的通用更新方法），再走同步推送流程
        guard let user = TDWidgetUserSession.currentUser() else { return .result() }

        // 让共享的 TDUserManager 在 Widget 进程里也有 token/userId（TDNetworkManager/QueryBuilder 依赖它）
        TDUserManager.shared.currentUser = user
        TDUserManager.shared.currentUserId = user.userId
        do {
            let context = try TDSharedSwiftDataStore.makeWidgetContext()

            // 1) 读取本地任务（复用主 App 方法，依赖 TDUserManager.userId）
            guard let task = try await TDQueryConditionManager.shared.getLocalTaskByTaskId(taskId: taskId, context: context) else {
                return .result()
            }

            // 2) 先改本地（复用主 App 通用更新方法：version/status/syncTime/索引等都在里面）
            let updatedTask = task
            updatedTask.complete = !task.complete
            _ = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(updatedTask: updatedTask, context: context)

            // 3) 再走同步推送（复用主 App 的数据组装与回写）
            if let tasksJson = try await TDQueryConditionManager.shared.getLocalUnsyncedDataAsJson(context: context),
               !tasksJson.isEmpty {
                let results = try await TDTaskAPI.shared.syncPushData(tasksJson: tasksJson)
                try await TDQueryConditionManager.shared.markTasksAsSynced(results: results, context: context)
            }
        } catch {
            // widget intent 里不抛 UI 错误，保持静默
        }
        return .result()
    }
}
