//
//  TDMacListViewModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/23.
//

import Foundation
import SwiftData

@MainActor // 将整个类标记为 MainActor
class TDMacListViewModel: ObservableObject {
    private let modelContext: ModelContext
    private let taskService: TDMacTaskService
    
    // MARK: - Published Properties
    @Published var selectedCategory: TDSliderBarModel?
    @Published var selectedDate: Date = Date()
    @Published var groupedTasks: [TDMacTaskGroup: [TDMacSwiftDataListModel]] = [:]
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var errorMessage: String?
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.taskService = TDMacTaskService.shared
    }
    // MARK: - Public Methods
    
    /// App启动、登录成功、手动同步时调用
    func syncAndRefresh() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            // 1. 同步数据
            try await taskService.syncTasks()
            
            // 2. 同步完成后刷新数据
            if let category = selectedCategory {
                await loadTasks(for: category)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error syncing tasks: \(error)")
        }
    }
    
    /// 更新选中的分类
    func updateCategory(_ category: TDSliderBarModel) {
        selectedCategory = category
        Task {
            await loadTasks(for: category)
        }
    }
    
    /// 更新选中的日期（仅当 categoryId == -100 时有效）
    func updateDate(_ date: Date) {
        selectedDate = date
        if let category = selectedCategory, category.categoryId == -100 {
            Task {
                await loadTasks(for: category)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 加载任务数据
    private func loadTasks(for category: TDSliderBarModel) async {
        isLoading = true
        defer { isLoading = false }
        do {
            groupedTasks = try await taskService.fetchTasks(categoryId: category.categoryId)
        } catch {
            errorMessage = error.localizedDescription
            print("Error loading tasks: \(error)")
        }
    }
}
