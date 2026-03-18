//
//  TDMainViewModel.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/10.
//

import Foundation
import SwiftUI
import OSLog
import SwiftData

/// 主视图模型 - 重新设计版本
@MainActor
final class TDMainViewModel: ObservableObject {
    
    // MARK: - 日志系统
    private let logger = OSLog(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDMainViewModel")
    
    /// 单例
    static let shared = TDMainViewModel()
    
    // MARK: - Published 属性
        
    /// 错误信息
    @Published var error: Error?
        
    /// 当前选中的分类
    @Published var selectedCategory: TDSliderBarModel?
    
    /// 当前选中的标签（用于第二栏展示标签筛选后的本地数据）
    @Published var selectedTagKey: String?

    // MARK: - 搜索（侧边栏输入 -> 第二栏展示）
    /// 全局搜索关键字（微信式：支持中文/拼音/简写；结果在第二栏显示）
    @Published var searchText: String = ""

    // MARK: - 多选模式相关属性
    
    /// 是否处于多选模式
    @Published var isMultiSelectMode: Bool = false
    
    /// 选中的任务对象数组（包含完整的任务数据）
    @Published var selectedTasks: [TDMacSwiftDataListModel] = []
  
    
    // MARK: - 多选：日期选择器联动（用于“重新安排”一键流程）
    /// 多选操作栏的“选择日期”弹窗请求（一次性）
    /// - 说明：必须是“一次性请求”，否则当用户之后通过右键“选择事件”进入多选时，
    ///        多选操作栏重新挂载会重复响应旧请求，导致误弹窗（你反馈的问题）。
    @Published var pendingMultiSelectDatePickerRequestId: UUID? = nil
  

    // MARK: - 单选模式相关属性
    
    /// 当前选中的任务（单选模式）
    @Published var selectedTask: TDMacSwiftDataListModel?
    
    /// 深链：待打开的 taskId（用于避免“切换分类时异步清空 selectedTask”与深链选中发生竞态）
    /// - 只有在深链流程中短暂存在；完成后必须清空
    @Published var pendingDeepLinkTaskId: String? = nil


    /// 小组件/外部深链：请求把“添加任务输入框”聚焦（一次性）
    /// - 说明：用 UUID 作为 token，避免 bool 反复触发/丢触发
    @Published var pendingInputFocusRequestId: UUID? = nil

    /// 专注关联的任务（专门用于专注功能）
    @Published var focusTask: TDMacSwiftDataListModel?

    // MARK: - 私有属性
    
    /// 查询管理器
    private let queryManager = TDQueryConditionManager.shared
    
    /// 模型容器
    private let modelContainer: TDModelContainer
    
    /// 上次请求的日期（用于检测隔天）
    private var lastRequestDate: String = ""
    
    /// 定时器（用于检测日期变化）
    private var dateCheckTimer: Timer?
    
    /// 应用进入后台的时间
    private var backgroundTime: Date?

    
    private init() {
        // 确保在主线程初始化 modelContainer
        assert(Thread.isMainThread, "TDMainViewModel 必须在主线程初始化")
        self.modelContainer = TDModelContainer.shared
        // 监听应用生命周期
        setupAppLifecycleObserver()
    }

    /// 选择分类
    func selectCategory(_ category: TDSliderBarModel) {
        os_log(.info, log: logger, "🎯 主视图模型接收到分类选择: \(category.categoryName) (ID: \(category.categoryId))")
        // 使用 Task 来避免在 View 更新过程中修改 @Published 属性
        Task { @MainActor in
            // 选择分类时：退出“标签模式”
            selectedTagKey = nil
            selectedCategory = category
            // 切换分类时退出多选模式
            exitMultiSelectMode()
            // 深链打开任务时：不要在“切换分类”的异步里把选中任务又清空（否则会出现你说的：切到 DayTodo 但不选中/不出详情）
            if pendingDeepLinkTaskId == nil {
                selectedTask = nil
            }


        }
    }
    
    /// 选择标签（非“所有标签”）
    /// - 选择标签时：清空分类选中，第二栏改为展示标签筛选结果
    func selectTag(tagKey: String) {
        os_log(.info, log: logger, "🏷️ 主视图模型接收到标签选择: %@", tagKey)
        Task { @MainActor in
            selectedCategory = nil
            selectedTagKey = tagKey
            exitMultiSelectMode()
            if pendingDeepLinkTaskId == nil {
                selectedTask = nil
            }
        }
    }
    

    
    /// 是否首次登录
    private var isFirstLogin: Bool {
        TDUserSyncManager.shared.isFirstSync(userId: TDUserManager.shared.userId)
    }
    
    // MARK: - 初始化方法
    
//    private init() {
//        os_log(.info, log: logger, "🚀 主视图模型初始化")
//    }
    
    // MARK: - 登录成功后调用的四个服务器请求方法
    
    /// 登录成功后调用的四个服务器请求
    /// 这四个请求只在重新打开app或重新登录成功后调用
    /// 不会影响界面操作和同步流程
    func performInitialServerRequests() async {
        os_signpost(.begin, log: logger, name: "InitialServerRequests")
        
        os_log(.info, log: logger, "🚀 开始执行初始服务器请求")
        
        // 启动四个后台任务，不等待结果，立即继续执行
        Task {
            do {
                let config = try await TDConfigAPI.shared.getConfig()
                TDConfigManager.shared.updateConfig(config)
                os_log(.info, log: logger, "✅ 配置数据获取成功")
            } catch {
                os_log(.error, log: logger, "❌ 配置请求失败: %@", error.localizedDescription)
            }
        }
        
        Task {
            do {
                let countdownList = try await TDCountdownAPI.shared.getCountdownDayList()
                TDCountdownManager.shared.updateCountdownList(countdownList)
                os_log(.info, log: logger, "✅ 倒计时数据获取成功")
            } catch {
                os_log(.error, log: logger, "❌ 倒计时请求失败: %@", error.localizedDescription)
            }
        }
        
        Task {
            await TDTomatoManager.shared.fetchTodayTomato()
            os_log(.info, log: logger, "✅ 番茄数据获取成功")
        }
        
        Task {
            do {
                let vipData = try await TDVipAPI.shared.getVipGoodsWindow()
                TDVipManager.shared.updateVipData(vipData)
                os_log(.info, log: logger, "✅ VIP数据获取成功")
            } catch {
                os_log(.error, log: logger, "❌ VIP请求失败: %@", error.localizedDescription)
            }
        }
        
        Task {
            do {
                await TDHolidayManager.shared.fetchHolidayListFromNetwork()
                os_log(.info, log: logger, "✅ 节假日数据获取成功")
            } catch {
                os_log(.error, log: logger, "❌ 节假日请求失败: %@", error.localizedDescription)
            }
        }
        
        // 这里会立即执行，不需要等待五个请求完成
        os_log(.info, log: logger, "🚀 五个服务器请求已启动，继续执行后续逻辑")

        
        
        // 判断是否首次登录，如果是则执行同步逻辑
//        if isFirstLogin {
//            os_log(.info, log: logger, "🔄 首次登录，开始执行同步逻辑")
//            await Task.detached(priority: .userInitiated) {
//                await self.performSync(isFirstTime: true)
//            }.value
//        } else {
//            os_log(.info, log: logger, "🔄 非首次登录，开始执行同步逻辑")
//            await Task.detached(priority: .userInitiated) {
//                await self.performSync()
//            }.value
//        }
        // 执行同步逻辑
        await performSyncSeparately()

        os_signpost(.end, log: logger, name: "InitialServerRequests")
    }
    

    
    // MARK: - 首次登录同步逻辑
    /// 单独执行同步逻辑（与初始化请求分离）
    func performSyncSeparately() async {
        os_log(.info, log: logger, "🔄 开始单独执行同步逻辑")
        do {
            // 在单独的方法中获取本地最大 version 值
            let localMaxVersion = try await queryManager.getLocalMaxVersion(context: modelContainer.mainContext)
            os_log(.info, log: logger, "📊 本地最大版本号: %d", localMaxVersion)
            
            // 判断是否首次登录，如果是则执行同步逻辑
            if isFirstLogin {
                os_log(.info, log: logger, "🔄 首次登录，开始执行同步逻辑")
                await performSync(isFirstTime: true, localMaxVersion: localMaxVersion)
            } else {
                os_log(.info, log: logger, "🔄 非首次登录，开始执行同步逻辑")
                await performSync(isFirstTime: false, localMaxVersion: localMaxVersion)
            }
            
        } catch {
            os_log(.error, log: logger, "❌ 获取本地最大版本号失败: %@", error.localizedDescription)
            self.error = error
        }
        os_log(.info, log: logger, "✅ 同步逻辑执行完成")
    }
    /// 执行同步逻辑
    func performSync(isFirstTime: Bool = false, localMaxVersion: Int64) async {
        os_signpost(.begin, log: logger, name: "Sync")
        
        os_log(.info, log: logger, "🔄 开始执行同步逻辑")
        
        // 通知侧边栏开始同步
        TDSliderBarViewModel.shared.startSync(isFirstTime: isFirstTime)
        
        do {
            // 1. 先尝试从服务器获取分类清单数据
            do {
                let serverCategories = try await TDCategoryAPI.shared.getCategoryList()
                await TDCategoryManager.shared.saveCategories(serverCategories)
                
                // 更新侧边栏分类数据
                TDSliderBarViewModel.shared.updateCategories(serverCategories)
                
                os_log(.info, log: logger, "✅ 分类数据同步完成，共 %d 项", serverCategories.count)
            } catch {
                // 网络请求失败，使用本地数据
                os_log(.error, log: logger, "⚠️ 获取服务器分类数据失败，使用本地数据: %@", error.localizedDescription)
                
                // 从本地加载分类数据并更新侧边栏
                let localCategories = TDCategoryManager.shared.loadLocalCategories()
                if !localCategories.isEmpty {
                    TDSliderBarViewModel.shared.updateCategories(localCategories)
                    os_log(.info, log: logger, "✅ 使用本地分类数据，共 %d 项", localCategories.count)
                }
            }
            
            // 2. 获取本地最大 version 值
            // 让出执行权，避免线程优先级反转
//            await Task.yield()
//            let localMaxVersion = 44536
            os_log(.info, log: logger, "📊 本地最大版本号: %d", localMaxVersion)
            
            // 3. 获取服务器最大 version 值
            let serverMaxVersion = try await TDTaskAPI.shared.getCurrentVersion()
            os_log(.info, log: logger, "🌐 服务器最大版本号: %d", serverMaxVersion)
            
            // 4. 判断同步策略
//            var sss = localMaxVersion
//            sss = 0
            if localMaxVersion >= serverMaxVersion {
                // 本地为最新，不需要更新或插入本地
                os_log(.info, log: logger, "✅ 本地数据已是最新，开始上传本地数据到服务器")
                await uploadLocalDataToServer()
            } else {
                // 服务器为最新，需要从服务器获取数据
                os_log(.info, log: logger, "🔄 服务器数据更新，开始从服务器获取数据")
                await downloadDataFromServer(localMaxVersion: localMaxVersion, serverMaxVersion: serverMaxVersion, isFirstTime: isFirstTime)
                await uploadLocalDataToServer()
            }
            
        } catch {
            os_log(.error, log: logger, "❌ 同步失败: %@", error.localizedDescription)
            self.error = error
        }
        
        // 通知侧边栏完成同步
        TDSliderBarViewModel.shared.completeSync()
        // 同步完成后，根据当前选中的分类重新初始化界面
//        await refreshCurrentCategoryView()

        os_signpost(.end, log: logger, name: "Sync")
    }
    

    
    /// 上传本地数据到服务器
    private func uploadLocalDataToServer() async {
        os_log(.info, log: logger, "📤 开始上传本地数据到服务器")
        
        do {
            // 获取本地所有 status != "sync" 的数据转 JSON
            let unsyncedData = try await queryManager.getLocalUnsyncedDataAsJson(context: modelContainer.mainContext)
            
            guard let jsonData = unsyncedData, !jsonData.isEmpty && jsonData != "[]" else {
                os_log(.info, log: logger, "📝 没有需要同步的本地数据")
                return
            }
            
            // 上传到服务器
            let syncResults = try await TDTaskAPI.shared.syncPushData(tasksJson: jsonData)
            
            if !syncResults.isEmpty {
                // 根据服务器返回的数据，更新本地数据状态为已同步
                try await queryManager.markTasksAsSynced(results: syncResults, context: modelContainer.mainContext)
                os_log(.info, log: logger, "✅ 成功同步 %d 条本地数据到服务器", syncResults.count)
            }
            
        } catch {
            os_log(.error, log: logger, "❌ 上传本地数据到服务器失败: %@", error.localizedDescription)
        }
    }
    
    /// 从服务器下载数据
    private func downloadDataFromServer(localMaxVersion: Int64, serverMaxVersion: Int64, isFirstTime: Bool = false) async {
        os_log(.info, log: logger, "📥 开始从服务器下载数据")
        
        // 计算需要获取的数据量
        let dataCount = serverMaxVersion - localMaxVersion
        
        
        // 同步状态管理由 TDSliderBarViewModel 处理，这里不需要重复管理
        
        do {
            // 获取服务器数据
            let serverTasks = try await TDTaskAPI.shared.getTaskList(version: dataCount)
            
            // 同步到本地数据库
            let syncResult = try await queryManager.syncServerDataToLocal(
                serverTasks: serverTasks,
                context: modelContainer.mainContext
            ) { currentCount, totalCount in
                // 进度回调，通知侧边栏更新同步进度
                Task { @MainActor in
                    TDSliderBarViewModel.shared.updateSyncProgress(current: currentCount, total: totalCount, isFirstTime: isFirstTime)
                }
            }
            
            os_log(.info, log: logger, "✅ 服务器数据同步完成，插入: %d, 更新: %d, 跳过: %d",
                   syncResult.insertCount, syncResult.updateCount, syncResult.skipCount)
            
        } catch {
            os_log(.error, log: logger, "❌ 从服务器下载数据失败: %@", error.localizedDescription)
            self.error = error
        }
    }

    // MARK: - 日期相关方法
    
    /// 选择日期并刷新任务
    func selectDateAndRefreshTasks(_ date: Date) async {
        os_log(.info, log: logger, "📅 选择日期: %@", date.description)
        
        // 更新日期管理器的选中日期
        // @Query 会自动监听日期变化并更新数据
        TDDateManager.shared.selectDate(date)
    }
    // MARK: - 辅助方法
    
    // 注意：getLocalUnsyncedData 和 updateLocalTaskStatus 方法已移除
    // 现在使用 TDQueryConditionManager 中的统一方法

    
    /// 刷新当前分类的界面（同步完成后调用）
    private func refreshCurrentCategoryView() async {
        guard let selectedCategory = selectedCategory else { return }
        
        os_log(.info, log: logger, "🔄 同步完成，刷新当前分类界面: \(selectedCategory.categoryName)")
        
        // 如果是 DayTodo，强制刷新数据
        if selectedCategory.categoryId == -100 {
            // 强制刷新 DayTodo 的 @Query
            NotificationCenter.default.post(name: .dayTodoDataChanged, object: nil)
        }
        
        // 发送任务数据变化通知，触发对应界面重新初始化
        // 这会让 TDTaskListView 重新调用 init 方法，就像用户点击侧栏分类一样
        NotificationCenter.default.post(name: .taskDataChanged, object: nil)
    }
    
    // MARK: - 多选模式管理方法
    
    /// 进入多选模式
    func enterMultiSelectMode() {
        os_log(.info, log: logger, "🎯 进入多选模式")
        isMultiSelectMode = true
        selectedTask = nil
        selectedTasks.removeAll()
    }
    
    /// 退出多选模式
    func exitMultiSelectMode() {
        os_log(.info, log: logger, "🎯 退出多选模式")
        isMultiSelectMode = false
        selectedTasks.removeAll()
    }
    
    /// 更新选中任务状态
    func updateSelectedTask(task: TDMacSwiftDataListModel, isSelected: Bool) {
        if isSelected {
            selectedTasks.append(task)
        } else {
            selectedTasks.removeAll { $0.taskId == task.taskId }
        }
        os_log(.info, log: logger, "🎯 更新任务选中状态: \(task.taskId), 选中: \(isSelected), 当前选中数量: \(self.selectedTasks.count)")
    }

    /// 全选/取消全选
    func toggleSelectAll(allTasks: [TDMacSwiftDataListModel]) {
        if selectedTasks.count == allTasks.count {
            // 当前全选，则取消全选
            selectedTasks.removeAll()
        } else {
            // 当前未全选，则全选
            selectedTasks = allTasks
        }
        os_log(.info, log: logger, "🎯 切换全选状态，当前选中数量: \(self.selectedTasks.count)")
    }
    
    /// 请求打开“多选操作栏”的日期选择器弹窗（一次性）
    /// - 用于：过往未达成分组的“重新安排”按钮（自动进入多选 + 全选 + 弹出选日期）
    func requestShowMultiSelectDatePicker() {
        pendingMultiSelectDatePickerRequestId = UUID()
    }

    /// 消费（清空）一次性弹窗请求
    func consumeMultiSelectDatePickerRequest() {
        pendingMultiSelectDatePickerRequestId = nil
    }

    
    /// 选择任务（单选模式）
    func selectTask(_ task: TDMacSwiftDataListModel) {
        os_log(.info, log: logger, "🎯 选择任务: \(task.taskContent)")
        selectedTask = task

    }

    /// 设置专注关联的任务
    func setFocusTask(_ task: TDMacSwiftDataListModel?) {
        os_log(.info, log: logger, "🍅 设置专注任务: \(task?.taskContent ?? "无")")
        focusTask = task
    }

    
    /// 设置应用生命周期监听
      func setupAppLifecycleObserver() {
          // 监听应用进入后台
          NotificationCenter.default.addObserver(
              forName: NSApplication.didResignActiveNotification,
              object: nil,
              queue: .main
          ) { [weak self] _ in
              Task { @MainActor in
                  self?.handleAppDidEnterBackground()
              }
          }
          
          // 监听应用进入前台
          NotificationCenter.default.addObserver(
              forName: NSApplication.didBecomeActiveNotification,
              object: nil,
              queue: .main
          ) { [weak self] _ in
              Task { @MainActor in
                  self?.handleAppDidEnterForeground()
              }
          }
      }
      
      /// 应用进入后台处理
      private func handleAppDidEnterBackground() {
          backgroundTime = Date()
          os_log(.info, log: logger, "📱 应用进入后台，记录时间: \(self.backgroundTime?.toString(format: "HH:mm:ss") ?? "未知")")
      }
      
      /// 应用进入前台处理
      private func handleAppDidEnterForeground() {
          guard let backgroundTime = backgroundTime else {
              os_log(.debug, log: logger, "📱 应用进入前台，但没有后台时间记录")
              return
          }
          
          let foregroundTime = Date()
          let timeInterval = foregroundTime.timeIntervalSince(backgroundTime)
          let secondsAway = Int(timeInterval)
          
          os_log(.info, log: logger, "📱 应用进入前台，离开后台时长: \(secondsAway)秒")
          
          // 如果离开后台超过8秒，重新请求数据
          if secondsAway >= 1800 {
              os_log(.info, log: logger, "🔄 离开后台超过8秒，开始重新请求数据")
              Task {
                  await performInitialServerRequests()
              }
          } else {
              os_log(.debug, log: logger, "⏰ 离开后台时间不足8秒，跳过数据请求")
          }

          // 重置后台时间
          self.backgroundTime = nil
      }
      
}
