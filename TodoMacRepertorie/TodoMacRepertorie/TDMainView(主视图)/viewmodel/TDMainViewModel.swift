//
//  TDMainViewModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class TDMainViewModel: ObservableObject {
    /// 单例
    static let shared = TDMainViewModel()
    
    // MARK: - Published 属性
    
    /// 是否正在加载
    @Published var isLoading = false
    
    /// 错误信息
    @Published var error: Error?
    
    /// 搜索文本
    @Published var searchText = ""
    
    /// 选中的分类
    @Published var selectedCategory: TDSliderBarModel?
    
    /// 分类列表
    @Published var categories: [TDSliderBarModel] = []
    
    @Published private(set) var groupedTasks: [TDTaskGroup: [TDMacSwiftDataListModel]] = [:]

    // MARK: - 私有属性
    private let dateManager = TDDateManager.shared
    private let settingManager = TDSettingManager.shared
    private let queryManager = TDQueryConditionManager.shared

    // MARK: - 初始化方法
    
    private init() {
        // 初始化默认系统分类
        categories = TDSliderBarModel.defaultItems
        // 默认选中 DayTodo
        selectDefaultCategory()
        // 初始化当前周
//        updateCurrentWeek()
        
        

    }
    
    // MARK: - 公共方法
    
    /// 登录后同步数据
    func syncAfterLogin() async {
        await MainActor.run {
            isLoading = true
        }
        do {
            // 1. 在异步线程获取服务器分类清单数据
            let serverCategories = try await Task.detached {
                return try await TDCategoryAPI.shared.getCategoryList()
            }.value
            
            // 2. 在异步线程保存到本地
            await Task.detached {
                await TDCategoryManager.shared.saveCategories(serverCategories)
            }.value
            
            // 3. 在主线程更新界面数据
            await MainActor.run {
                updateCategories(serverCategories)
            }
            
            // 同步服务器数据到本地数据库
            await syncServerDataToLocal()
            
            await MainActor.run {
                isLoading = false
                // 确保同步完成后选中默认分类
                if selectedCategory == nil {
                    selectDefaultCategory()
                }
            }
        } catch {
            print("登录后同步失败: \(error)")
            await MainActor.run {
                isLoading = false
                // 确保同步完成后选中默认分类
                if selectedCategory == nil {
                    selectDefaultCategory()
                }
            }
        }
    }
    
    /// 启动后同步数据
    func syncAfterLaunch() async {
        // 1. 在异步线程加载本地数据
        let localCategories = await Task.detached {
            return TDCategoryManager.shared.loadLocalCategories()
        }.value
        
        // 2. 在主线程更新界面
        await MainActor.run {
            updateCategories(localCategories)
            isLoading = true
        }
        
        do {
            let serverCategories = try await Task.detached {
                return try await TDCategoryAPI.shared.getCategoryList()
            }.value
            
            await Task.detached {
                await TDCategoryManager.shared.saveCategories(serverCategories)
            }.value
            
            // 3. 在主线程更新界面数据
            await MainActor.run {
                updateCategories(serverCategories)
            }
            
            // 同步服务器数据到本地数据库
            await syncServerDataToLocal()
            
            await MainActor.run {
                isLoading = false
                // 确保同步完成后选中默认分类
                if selectedCategory == nil {
                    selectDefaultCategory()
                }
            }
        } catch {
            print("启动后同步失败: \(error)")
            await MainActor.run {
                isLoading = false
                // 确保同步完成后选中默认分类
                if selectedCategory == nil {
                    selectDefaultCategory()
                }
            }
        }
    }
    
    /// 手动同步数据
    func sync() async {
        await MainActor.run {
            isLoading = true
        }
        do {
            let serverCategories = try await Task.detached {
                return try await TDCategoryAPI.shared.getCategoryList()
            }.value
            
            await Task.detached {
                await TDCategoryManager.shared.saveCategories(serverCategories)
            }.value
            
            // 3. 在主线程更新界面数据
            await MainActor.run {
                updateCategories(serverCategories)
            }
            
            // 同步服务器数据到本地数据库
            await syncServerDataToLocal()
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            print("手动同步失败: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    /// 选择分类
    func selectCategory(_ category: TDSliderBarModel) {
        Task { @MainActor in
            print("选中分类: id=\(category.categoryId), name=\(category.categoryName), isSelect=\(category.isSelect)")

            selectedCategory = category
            await updateTasksForSelectedCategory()
        }
    }
    /// 更新选中分类的任务列表（公开方法）
    func refreshTasks() async {
        await updateTasksForSelectedCategory()
    }
    // MARK: - 私有方法
    
    /// 更新分类数据
    private func updateCategories(_ categories: [TDSliderBarModel]) {
        // 1. 将系统默认分类和用户创建的分类合并
        var newItems = TDSliderBarModel.defaultItems
        
        // 2. 找到分类清单的位置
        if let categoryListIndex = newItems.firstIndex(where: { $0.categoryId == -104 }) {
            // 3. 在分类清单后面插入用户创建的分类
            newItems.insert(contentsOf: categories, at: categoryListIndex + 1)
        }
        
        // 4. 更新界面数据
        self.categories = newItems
        
        // 5. 如果当前选中的分类在新数据中不存在,则选中 DayTodo
        if let selectedCategory = selectedCategory,
           !newItems.contains(where: { $0.categoryId == selectedCategory.categoryId }) {
            if let dayTodo = newItems.first(where: { $0.categoryId == -100 }) {
                selectCategory(dayTodo)
            }
        }
    }
    /// 选择默认分类（DayTodo）
    private func selectDefaultCategory() {
        if let dayTodo = categories.first(where: { $0.categoryId == -100 }) {
            selectCategory(dayTodo)
        }
    }
    private func fetchTasks(for category: TDSliderBarModel) async throws -> [TDMacSwiftDataListModel] {
        // TODO: 从数据库获取任务
        // 这里先返回一个空数组，后续实现真正的数据获取逻辑
        return try await queryManager.queryTasksByDate(timestamp: dateManager.selectedDate.startOfDayTimestamp)
    }

    /// 更新任务列表
    private func updateTasksForSelectedCategory() async {
        guard let category = selectedCategory else { return }
        
        do {
            let tasks = try await fetchTasks(for: category)
            await MainActor.run {
                if category.categoryId == -100 {
                    // DayTodo 模式：只显示选中日期的任务，不需要分组标题
                    self.groupedTasks = [.today: tasks]
                } else {
                    // 其他模式：按日期状态分组
//                    self.groupedTasks = groupTasks(tasks)
                }
            }
        } catch {
            print("Error fetching tasks: \(error)")
        }
    }
    /// 对任务进行分组
//    private func groupTasks(_ tasks: [TDMacSwiftDataListModel]) -> [TDTaskGroup: [TDMacSwiftDataListModel]] {
//        var grouped: [TDTaskGroup: [TDMacSwiftDataListModel]] = [:]
//        let calendar = Calendar.current
//        let now = Date()
//        
//        for task in tasks {
//            guard let dueDate = task.dueDate else {
//                // 无日期任务
//                grouped[.noDate, default: []].append(task)
//                continue
//            }
//            
//            if dueDate.isOverdue {
//                // 过期任务
//                if task.isCompleted {
//                    grouped[.overdueCompleted, default: []].append(task)
//                } else {
//                    grouped[.overdueIncomplete, default: []].append(task)
//                }
//            } else if dueDate.isToday {
//                // 今天的任务
//                grouped[.today, default: []].append(task)
//            } else if dueDate.isTomorrow {
//                // 明天的任务
//                grouped[.tomorrow, default: []].append(task)
//            } else if dueDate.isDayAfterTomorrow {
//                // 后天的任务
//                grouped[.dayAfterTomorrow, default: []].append(task)
//            } else {
//                // 后续日程
//                grouped[.future, default: []].append(task)
//            }
//        }
//        
//        return grouped
//    }
    /// 同步服务器数据到本地数据库
    private func syncServerDataToLocal() async {
        // TODO: 实现数据同步
        do {
            // 1. 获取本地最大同步时间戳（只考虑已同步的记录）
            let maxVersion = try await TDQueryConditionManager.shared.getMaxSyncVersion()
            print("本地最大同步值戳: \(maxVersion)")
            // 2. 获取服务器最大版本号
            let serverMaxVersion = try await TDTaskAPI.shared.getCurrentVersion()
            print("服务器最大版本号: \(serverMaxVersion)")
            // 3. 如果服务器版本号大于本地版本号，需要同步服务器数据
            if serverMaxVersion > maxVersion {
                print("从服务器获取更新的数据...")
                
                // 获取服务器数据
                let serverTasks = try await TDTaskAPI.shared.getTaskList(version: serverMaxVersion - maxVersion)
                
                // 如果服务器返回了数据，保存到本地
                if !serverTasks.isEmpty {
                    // 保存数据到本地
                    try await TDQueryConditionManager.shared.saveTasks(serverTasks)
                    
                    // 处理日历事件
                    for task in serverTasks {
                        do {
                            try await TDCalendarService.shared.handleReminderEvent(task: task)
                        } catch {
                            print("处理任务 \(task.taskId) 的日历事件失败: \(error.localizedDescription)")
                            // 继续处理下一个任务
                            continue
                        }
                    }
                    
                    // 在主线程更新界面
                    await MainActor.run {
                        // 更新当前选中分类的任务列表
                        if let category = selectedCategory {
                            Task {
                                await updateTasksForSelectedCategory()
                            }
                        }
                    }
                } else {
                    print("服务器没有新数据需要同步")
                }
            } else {
                print("本地数据已是最新")
            }

            
            // TODO: 根据同步时间戳从服务器获取更新的数据
            // 注意：version 是本地事件同步记录的相对整数型时间戳
            // 当 sync 状态的数据被更改时需要 +1
            
        } catch {
            print("同步服务器数据到本地失败: \(error)")
        }
    }
    
    /// 获取任务查询描述符
    private func getTasksDescriptor(for category: TDSliderBarModel) -> FetchDescriptor<TDMacSwiftDataListModel> {
        var descriptor = FetchDescriptor<TDMacSwiftDataListModel>()
        
//        // 1. 基础过滤：未删除的任务
//        var predicates: [Predicate<TDMacSwiftDataListModel>] = [
//            #Predicate<TDMacSwiftDataListModel> { task in
//                task.delete == 0
//            }
//        ]
//        
//        // 2. 分类过滤
//        switch category.categoryId {
//        case -100: // DayTodo
//            predicates.append(#Predicate<TDMacSwiftDataListModel> { task in
//                let calendar = Calendar.current
//                let today = calendar.startOfDay(for: Date())
//                let taskDate = Date(timeIntervalSince1970: TimeInterval(task.todoTime / 1000))
//                return calendar.isDate(taskDate, inSameDayAs: today)
//            })
//            
//        case -101: // 最近待办
//            predicates.append(#Predicate<TDMacSwiftDataListModel> { task in
//                task.complete == 0
//            })
//            
//        case -102: // 日程概览
//            predicates.append(#Predicate<TDMacSwiftDataListModel> { task in
//                task.complete == 0
//            })
//            
//        case -103: // 待办箱
//            predicates.append(#Predicate<TDMacSwiftDataListModel> { task in
//                task.complete == 0 && task.todoTime == 0
//            })
//            
//        case -107: // 最近已完成
//            predicates.append(#Predicate<TDMacSwiftDataListModel> { task in
//                task.complete == 1
//            })
//            
//        case -108: // 回收站
//            predicates.append(#Predicate<TDMacSwiftDataListModel> { task in
//                task.delete == 1
//            })
//            
//        default:
//            if category.categoryId >= -1 {
//                predicates.append(#Predicate<TDMacSwiftDataListModel> { task in
//                    task.standbyInt1 == category.categoryId
//                })
//            }
//        }
//        
//        // 3. 搜索过滤
//        if !searchText.isEmpty {
//            predicates.append(#Predicate<TDMacSwiftDataListModel> { task in
//                task.taskContent.localizedStandardContains(searchText)
//            })
//        }
//        
//        descriptor.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates.map { $0.toFoundation() })
//        descriptor.sortBy = [SortDescriptor(\TDMacSwiftDataListModel.taskSort, order: .forward)]
        
        return descriptor
    }
}
