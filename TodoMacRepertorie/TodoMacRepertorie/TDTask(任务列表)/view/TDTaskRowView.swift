//
//  TDTaskRowView.swift
//  TodoMacRepertorie
//
//  Created by Assistant on 2025/1/20.
//

import SwiftUI
import SwiftData



/// 副本创建类型枚举
enum CopyType {
    case normal          // 创建副本（保持原日期）
    case toToday         // 创建副本到今天
    case toSpecificDate  // 创建副本到指定日期
}

/// 通用任务行视图组件
/// 右侧日期/角标颜色角色（避免直接传 Color，便于 Equatable 与主题统一）
enum TDTaskRowRightBadgeColorRole: Equatable {
    /// 主题色 5 级
    case themeLevel5
    /// 新年红 5 级（写死强调色）
    case newYearRedLevel5
    /// 标题字体颜色
    case titleText
}

struct TDTaskRowView: View , Equatable{
    let task: TDMacSwiftDataListModel
    let category: TDSliderBarModel?
    let orderNumber: Int?
    
    /// 是否在标题/描述下方显示“日期文字行”
    /// 说明：
    /// - 最近待办/分类清单里默认仍显示（保持原逻辑）
    /// - 最近已完成页面：右侧已经显示日期，所以这里要关闭
    let showInlineDate: Bool
    
    /// 右侧角标文本（用于「最近已完成」右侧日期）
    /// 说明：放在与“完成按钮”同一行（同一层级），不做分组头
    let rightBadgeText: String?
    /// 右侧角标颜色角色
    let rightBadgeColorRole: TDTaskRowRightBadgeColorRole?
    
    let isFirstRow: Bool
    let isLastRow: Bool
    // 计算属性：是否显示置顶按钮
    private var shouldShowPinToTop: Bool {
        return !isFirstRow
    }
    
    // 计算属性：是否显示置底按钮
    private var shouldShowPinToBottom: Bool {
        return !isLastRow
    }
    @State private var isHovered: Bool = false
    
    // 监听多选模式状态变化
    @ObservedObject private var mainViewModel = TDMainViewModel.shared
    
    /// 监听设置变化，确保列表样式能实时刷新（描述开关/行数/已完成删除线等）
    @ObservedObject private var settingManager = TDSettingManager.shared
    
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var showDatePickerForCopy: Bool = false  // 控制创建副本的日期选择器显示
    @State private var selectedCopyDate: Date = Date()  // 创建副本时选择的日期
    @State private var showCopySuccessToast: Bool = false  // 控制复制成功Toast的显示
    // 复制成功回调
    var onCopySuccess: (() -> Void)?
    // 进入多选模式回调
    var onEnterMultiSelect: (() -> Void)?
    
    // 判断是否显示顺序数字
    private var shouldShowOrderNumber: Bool {
        return category?.categoryId == -100 && task.shouldShowOrderNumber && orderNumber != nil
    }
    
    /// 自定义初始化方法
    /// 说明：
    /// - 之所以需要显式 init：因为 `showInlineDate` 需要可配置
    /// - 如果写成 `let xxx = 默认值`，Swift 会把它当作“常量”，不会出现在 init 参数里，导致调用处传参报错
    init(
        task: TDMacSwiftDataListModel,
        category: TDSliderBarModel?,
        orderNumber: Int?,
        isFirstRow: Bool,
        isLastRow: Bool,
        showInlineDate: Bool = true,
        rightBadgeText: String? = nil,
        rightBadgeColorRole: TDTaskRowRightBadgeColorRole? = nil,
        onCopySuccess: (() -> Void)? = nil,
        onEnterMultiSelect: (() -> Void)? = nil
    ) {
        self.task = task
        self.category = category
        self.orderNumber = orderNumber
        self.isFirstRow = isFirstRow
        self.isLastRow = isLastRow
        self.showInlineDate = showInlineDate
        self.rightBadgeText = rightBadgeText
        self.rightBadgeColorRole = rightBadgeColorRole
        self.onCopySuccess = onCopySuccess
        self.onEnterMultiSelect = onEnterMultiSelect
    }
    
    var body: some View {
        HStack(spacing: 0) {
            
            // 1. 难度指示条（左边）
            RoundedRectangle(cornerRadius: 1.5)
                .fill(task.difficultyColor)
                .frame(width: 3)
                .padding(.vertical, 2)
                .padding(.leading, 1)
                .frame(maxHeight: .infinity)
            
            // 2. 主要内容区域
            VStack(alignment: .center, spacing: 8) {
                // 标题与右侧日期的间距：最多 10pt
                // - 右侧日期固定在最右
                // - 标题尽可能吃满日期左侧剩余空间，只有当间距要小于 10pt 才换行
                HStack(alignment: .top, spacing: 10) {
                    HStack(alignment: .top, spacing: 12) {
                        // 完成状态复选框/多选圆圈
                        Button(action: {
                            if mainViewModel.isMultiSelectMode {
                                toggleSelection()
                            } else {
                                toggleTaskCompletion()
                            }
                        }) {
                            ZStack {
                                if mainViewModel.isMultiSelectMode {
                                    // 多选模式：显示圆圈
                                    Circle()
                                        .stroke(themeManager.color(level: 5), lineWidth: 1.5)
                                        .frame(width: 18, height: 18)
                                    
                                    if mainViewModel.selectedTasks.contains(where: { $0.taskId == task.taskId }) {
                                        Circle()
                                            .fill(themeManager.color(level: 5))
                                            .frame(width: 18, height: 18)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    
                                    
                                } else {
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(task.checkboxColor, lineWidth: 1.5)
                                        .frame(width: 18, height: 18)
                                    
                                    if task.complete {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(task.checkboxColor)
                                            .frame(width: 18, height: 18)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    } else if shouldShowOrderNumber {
                                        // DayTodo 且设置显示顺序数字时，显示数字
                                        Text("\(orderNumber!)")
                                            .font(.system(size: 8, weight: .medium))
                                            .foregroundColor(task.checkboxColor)
                                    }
                                    
                                }
                            }
                            .contentShape(Rectangle())
                            
                        }
                        .buttonStyle(PlainButtonStyle())
                        .pointingHandCursor()
                        
                        // 任务内容
                        VStack(alignment: .leading, spacing: 6) {
                            // 任务标题
                            // 任务标题（第二栏富文本）：标签胶囊 + 链接千草蓝可点击
                            // 说明：这是你要求的“重要功能”——只要标题里包含 #标签 或 链接，都要按规则渲染
                            TDTaskTitleRichTextView(
                                rawTitle: task.taskContent,
                                baseTextColor: task.taskTitleColor,
                                fontSize: 14,
                                lineLimit: settingManager.taskTitleLines,
                                isStrikethrough: task.complete ? settingManager.showCompletedTaskStrikethrough : false,
                                opacity: task.complete ? 0.6 : 1.0,
                                onTapPlain: {
                                    // 点击标题普通区域时也要与“点击整行”一致：进入详情 / 多选切换
                                    if mainViewModel.isMultiSelectMode {
                                        toggleSelection()
                                    } else {
                                        mainViewModel.selectTask(task)
                                    }
                                }
                            )
                            
                            // 任务描述（根据设置和内容决定是否显示）
                            if settingManager.showTaskDescription && !(task.taskDescribe?.isEmpty ?? true) {
                                Text(task.taskDescribe ?? "")
                                    .font(.system(size: 13))
                                    .foregroundColor(themeManager.descriptionTextColor)
                                    .lineLimit(settingManager.taskDescriptionLines)
                            }
                            
                            // 任务日期（今天、明天、后天显示文字，其他显示日期）
                            // 在 DayTodo 分类下不显示日期
                            // 你要求：最近已完成右侧已显示日期 => 这里不再重复显示
                            if showInlineDate, category?.categoryId != -100 && !task.taskDateConditionalString.isEmpty {
                                Text(task.taskDateConditionalString)
                                    .font(.system(size: 10))
                                    .foregroundColor(task.taskDateColor)
                            }
                            
                            // 底部信息栏
                            if task.hasReminder || task.hasRepeat || !task.attachmentList.isEmpty {
                                HStack(spacing: 12) {
                                    // 5. 提醒时间
                                    if task.hasReminder {
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(themeManager.color(level: 4))
                                            Text(task.reminderTimeString)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(themeManager.color(level: 4))
                                        }
                                    }
                                    
                                    // 6. 重复事件
                                    if task.hasRepeat {
                                        Image(systemName: "repeat")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(themeManager.color(level: 4))
                                    }
                                    
                                    // 7. 附件
                                    if task.hasAttachment {
                                        Image(systemName: "paperclip")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(themeManager.color(level: 4))
                                    }
                                    
                                    Spacer()
                                }
                            }
                            
                            // 8&9. 子任务
                            if !task.subTaskList.isEmpty {
                                // 展开/收起按钮
                                Button(action: {
                                    task.isSubOpen.toggle()
                                    // 保存到数据库
                                    do {
                                        try modelContext.save()
                                    } catch {
                                        print("保存子任务展开状态失败: \(error)")
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 8))
                                            .foregroundColor(themeManager.descriptionTextColor)
                                            .rotationEffect(.degrees(task.isSubOpen ? 180 : 0))
                                        
                                        Text(task.isSubOpen ? "收起" : "展开")
                                            .font(.system(size: 10))
                                            .foregroundColor(themeManager.descriptionTextColor)
                                    }
                                    .frame(width: 55, height: 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(themeManager.secondaryBackgroundColor)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .pointingHandCursor()
                                .contentShape(Rectangle())
                                
                                // 子任务列表
                                if task.isSubOpen {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(Array(task.subTaskList.enumerated()), id: \.offset) { index, subTask in
                                            HStack(spacing: 6) {
                                                if task.complete {
                                                    // 当前任务完成时，所有子任务显示圆点（不可点击）
                                                    Circle()
                                                        .fill(themeManager.color(level: 5))
                                                        .frame(width: 8, height: 8)
                                                } else {
                                                    // 当前任务未完成时，根据子任务状态显示（可点击）
                                                    Button(action: {
                                                        toggleSubTaskCompletion(subTaskIndex: index)
                                                    }) {
                                                        ZStack {
                                                            // 边框
                                                            Circle()
                                                                .stroke(themeManager.color(level: 5), lineWidth: 1)
                                                                .frame(width: 12, height: 12)
                                                            
                                                            if subTask.isComplete {
                                                                // 已完成：显示实心圆圈加对号
                                                                Circle()
                                                                    .fill(themeManager.color(level: 5))
                                                                    .frame(width: 12, height: 12)
                                                                
                                                                Image(systemName: "checkmark")
                                                                    .font(.system(size: 8, weight: .medium))
                                                                    .foregroundColor(.white)
                                                            }
                                                        }
                                                        .contentShape(Rectangle())
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                    .pointingHandCursor()
                                                }
                                                
                                                Text(subTask.content)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(themeManager.subtaskTextColor)
                                                    .strikethrough(subTask.isComplete)
                                                    .opacity(subTask.isComplete ? 0.6 : 1.0)
                                            }
                                        }
                                    }
                                    .padding(.leading, 8)
                                }
                            }
                            
                        }
                        // 左侧内容占满日期左侧空间（否则会提前换行并留下大空白）
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 右侧日期/角标：固定宽度并贴右
                    if let rightBadgeText, let role = rightBadgeColorRole {
                        Text(rightBadgeText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(rightBadgeColor(role))
                            .frame(height: 18, alignment: .center)
                            .fixedSize(horizontal: true, vertical: false)
                            .allowsHitTesting(false)
                    }
                }
                    // 说明：专注按钮不放在 HStack 内，避免出现/消失导致整体布局抖动
                    // 你要求：
                    // 1) 只在“鼠标悬停到当前行”时显示（每行独立，不影响其它行）
                    // 2) 按钮与整行内容垂直居中对齐（不是右上角）
                    // 3) 如果设置里关闭“专注界面”，即使 hover 也不显示
                    // 4) 显示动画与“最近已完成”一致（淡入 + 轻微缩放）
                    
                    
                    //                    Button(action: startFocus) {
                    //                        Image(systemName: "timer")
                    //                            .font(.system(size: 14))
                    //                            .foregroundColor(themeManager.color(level: 5))
                    //                            .frame(width: 32, height: 32)
                    //                            .background(themeManager.color(level: 5).opacity(0.1))
                    //                            .clipShape(Circle())
                    //                    }
                    //                    .buttonStyle(PlainButtonStyle())
                }
            }
            // 你要求：标题/描述/子任务整体距离列表右边 10pt
            // - 这里把整体 trailing 从 16 收紧到 10
            .padding(.leading, 16)
            .padding(.trailing, 10)
            .padding(.vertical, 12)
        }
        //        .frame(maxWidth: .infinity) // 横向铺满
        .background(
            Group {
                
                if mainViewModel.selectedTask?.taskId == task.taskId {
                    // 单选模式选中态：背景不要太深，使用主题色 1 级（按你的反馈）
                    themeManager.color(level: 1).opacity(0.2)
                } else if isHovered {
                    // 悬停状态：主题颜色二级背景色
                    themeManager.secondaryBackgroundColor.opacity(0.3)
                } else {
                    // 默认状态：主题背景色
                    themeManager.backgroundColor
                }

                
//                if mainViewModel.selectedTask?.taskId == task.taskId || mainViewModel.selectedTasks.contains(where: { $0.taskId == task.taskId }) {
//                    // 选中状态（单选或多选）：毛玻璃背景
//                    Rectangle()
//                        .fill(.ultraThinMaterial)
//                        .background(themeManager.color(level: 4).opacity(0.1))
//                } else if isHovered {
//                    // 悬停状态：主题颜色二级背景色
//                    themeManager.secondaryBackgroundColor
//                } else {
//                    // 默认状态：主题背景色
//                    themeManager.backgroundColor
//                }
            }
        )
        .overlay(alignment: .trailing) {
            // 说明：按钮与整行“垂直居中”对齐（alignment:.trailing 默认是 centerY）
            // - 只在 hover + 非多选 + 开启专注界面时显示
            // - 距离右边 10pt（按你截图规范）
            if isHovered && !mainViewModel.isMultiSelectMode && settingManager.enableTomatoFocus {
                Button {
                    // 设置专注关联的任务
                    mainViewModel.setFocusTask(task)
                } label: {
                    Image(systemName: "timer")
                        .font(.system(size: 12, weight: .semibold))
                        // 你要求：图标颜色 = 主题颜色“字体颜色”
                        .foregroundColor(themeManager.titleTextColor)
                        // 你要求：专注按钮更小，28×28
                        .frame(width: 28, height: 28)
                        // 你要求：背景色 = 主题颜色的 1 级背景色（primaryBackground）
                        .background(themeManager.backgroundColor)
                        .clipShape(Circle())
                        // 你要求：加描边（border）
                        .overlay(
                            Circle()
                                .stroke(themeManager.borderColor, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                // 说明：与右侧日期对齐，右边距与左侧完成按钮的左边距一致
                .padding(.trailing, 10)
                // 你要求：专注按钮要在最上层，允许直接压住右侧日期文字
                .zIndex(999)
                // 你要求：显示动画更明显（从左推入，向右推出 / 或放大缩小）
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.92)),
                        removal: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.92))
                    )
                )
                // 兜底：确保 transition 一定会被动画驱动（避免你看到“生硬”）
                // 你要求：专注按钮动画稍微慢一点（更柔和）
                .animation(.easeInOut(duration: 0.28), value: isHovered)
            }
        }
        .overlay(
            Group {
                // 底部分割线：
                // - 每个分组的最后一行不显示（避免组尾多一条线）
                if !isLastRow {
                    Rectangle()
                        .fill(themeManager.separatorColor)
                        .frame(height: 1.0)
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        )
        // 说明：hover 绑定到“整行最外层”，确保鼠标在 cell 任意位置（包括按钮/右侧日期）都能触发
        .contentShape(Rectangle())
        .onHover { hovering in
            // 说明：每行独立 hover 状态（避免“悬停一行所有行都显示”）
            // 你要求：悬停时才显示专注按钮 + 背景轻高亮
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            if mainViewModel.isMultiSelectMode {
                // 多选模式下，点击整行也可以选中/取消选中
                toggleSelection()
            } else {
                // 单选模式下，选择任务并传递完整数据模型
                mainViewModel.selectTask(task)
                
            }
        }
        .contextMenu {
            if !mainViewModel.isMultiSelectMode {
                
                // 任务操作菜单
                Button("选择事件") {
                    // TODO: 实现选择事件功能
                    print("选择事件: \(task.taskContent)")
                    mainViewModel.enterMultiSelectMode()
                    mainViewModel.updateSelectedTask(task: task, isSelected: true)
                    // 调用进入多选模式回调，通知父视图更新任务列表
                    onEnterMultiSelect?()
                    
                }
                
                Divider()
                
                Button("复制内容") {
                    // 使用数据操作管理器复制单个任务内容
                    // 使用数据操作管理器复制单个任务内容
                    let singleTaskArray = [task]
                    let success = TDDataOperationManager.shared.copyTasksToClipboard(singleTaskArray)
                    
                    if success {
                        // 触发复制成功回调
                        onCopySuccess?()
                    }
                }
                
                Menu("创建副本") {
                    Button("创建副本") {
                        // TODO: 实现创建副本功能
                        // 创建副本 - 保持原日期
                        handleCreateCopy(copyType: .normal)
                    }
                    
                    // 根据当前任务的日期判断是否显示"创建到今天"
                    if !task.isToday {
                        Button("创建到今天") {
                            // TODO: 实现创建到今天功能
                            // 创建副本到今天
                            handleCreateCopy(copyType: .toToday)
                        }
                    }
                    
                    Button("创建到指定日期") {
                        // TODO: 实现创建到指定日期功能
                        // 创建副本到指定日期 - 显示日期选择器
                        showDatePickerForCopy = true
                    }
                }
                
                Button("移到最前") {
                    handleMoveTask(isToTop: true)
                }
                .disabled(category?.categoryId != -100 || isFirstRow)
                
                Button("移到最后") {
                    handleMoveTask(isToTop: false)
                }
                .disabled(category?.categoryId != -100 || isLastRow)
                
                Button("删除", role: .destructive) {
                    deleteTask()
                }
            }
        }
        // 左滑功能
        //        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
        //            if !mainViewModel.isMultiSelectMode {
        //                // 删除按钮 - 永远显示
        //                Button(role: .destructive, action: deleteTask) {
        //                    Image(systemName: "trash.fill")
        //                        .font(.system(size: 16, weight: .medium))
        //                        .foregroundColor(.white)
        //                }
        //                .tint(TDThemeManager.shared.fixedColor(themeId: "new_year_red", level: 5))
        //
        //                // 置底按钮 - 只在 DayTodo 且不是最后一行时显示
        //                if category?.categoryId == -100 && !isLastRow {
        //                    Button(action: moveToBottom) {
        //                        Image(systemName: "arrowshape.down.fill")
        //                            .font(.system(size: 16, weight: .medium))
        //                            .foregroundColor(.white)
        //                    }
        //                    .tint(TDThemeManager.shared.fixedColor(themeId: "wish_orange", level: 5))
        //                }
        //
        //                // 置顶按钮 - 只在 DayTodo 且不是第一行时显示
        //                if category?.categoryId == -100 && !isFirstRow {
        //                    Button(action: moveToTop) {
        //                        Image(systemName: "arrowshape.up.fill")
        //                            .font(.system(size: 16, weight: .medium))
        //                            .foregroundColor(.white)
        //                    }
        //                    .tint(Color.fromHex("#404040"))
        //                }
        //            }
        //
        //
        //        }
        
        // Performance optimizations
        //        .equatable()
        // 注意：这里不能用 drawingGroup()
        // 原因：我们在标题里嵌入了 NSTextView（NSViewRepresentable）实现“标签胶囊 + 链接 + 系统省略号”。
        // drawingGroup 会把整行栅格化，NSViewRepresentable 无法被正确绘制，结果就会出现你截图里的“黄色+禁止符号”占位。
        .animation(.none, value: task.complete)
        // 创建副本的日期选择器弹窗 - 使用自定义日期选择器（支持农历显示）
        .popover(isPresented: $showDatePickerForCopy) {
            TDCustomDatePickerView(
                selectedDate: $selectedCopyDate,
                isPresented: $showDatePickerForCopy,
                onDateSelected: { date in
                    // 日期选择完成后的回调函数
                    print("📅 选择创建副本的日期: \(date)")
                    // 创建副本到指定日期
                    handleCreateCopy(copyType: .toSpecificDate)
                }
            )
            .frame(width: 280, height: 320) // 设置弹窗尺寸，与多选模式保持一致
        }
        
    }
    
    // MARK: - Private Methods
    
    private func toggleTaskCompletion() {
        print("切换任务完成状态: \(task.taskContent)")
        Task {
            // 如果任务即将变为已完成状态，先播放完成音效
            if !task.complete {
                TDAudioManager.shared.playCompletionSound()
            }
            do {
                let updatedTask = task
                updatedTask.complete = !task.complete // 切换状态
                
                // 2. 调用通用更新方法
                let queryManager = TDQueryConditionManager()
                let result = try await queryManager.updateLocalTaskWithModel(
                    updatedTask: updatedTask,
                    context: modelContext
                )
                
                if result == .updated {
                    print("切换任务状态成功: \(task.taskContent)")
                    
                    // 3. 调用同步方法
                    await TDMainViewModel.shared.performSyncSeparately()
                } else {
                    print("切换任务状态失败: 更新结果异常")
                }
                
            } catch {
                print("切换任务状态失败: \(error)")
            }
        }
    }
    private func toggleSubTaskCompletion(subTaskIndex: Int) {
        print("切换子任务完成状态: \(task.subTaskList[subTaskIndex].content)")
        
        Task {
            do {
                
                // 1. 创建更新后的任务模型
                let updatedTask = task
                let newCompletionState = !task.subTaskList[subTaskIndex].isComplete
                
                // 2. 更新子任务状态
                updatedTask.subTaskList[subTaskIndex].isComplete = newCompletionState
                
                // 3. 重新生成 standbyStr2 字符串
                let newSubTasksString = updatedTask.generateSubTasksString()
                updatedTask.standbyStr2 = newSubTasksString.isEmpty ? nil : newSubTasksString
                
                // 4. 检查是否需要自动完成父任务
                if updatedTask.allSubTasksCompleted {
                    // 根据设置决定是否自动完成父任务
                    // TODO: 这里需要添加设置项，暂时默认自动完成
                    let shouldAutoCompleteParent = true // TDSettingManager.shared.autoCompleteParentWhenAllSubTasksDone
                    
                    if shouldAutoCompleteParent && !updatedTask.complete {
                        updatedTask.complete = true
                        print("🔍 所有子任务完成，自动完成父任务: \(updatedTask.taskContent)")
                    }
                }
                
                // 5. 调用通用更新方法
                let queryManager = TDQueryConditionManager()
                let result = try await queryManager.updateLocalTaskWithModel(
                    updatedTask: updatedTask,
                    context: modelContext
                )
                
                if result == .updated {
                    print("切换子任务状态成功: \(task.subTaskList[subTaskIndex].content)")
                    
                    // 6. 调用同步方法
                    await TDMainViewModel.shared.performSyncSeparately()
                } else {
                    print("切换子任务状态失败: 更新结果异常")
                }
                
            } catch {
                print("切换子任务状态失败: \(error)")
            }
        }
    }
    
    private func toggleSelection() {
        let isSelected = mainViewModel.selectedTasks.contains { $0.taskId == task.taskId }
        mainViewModel.updateSelectedTask(task: task, isSelected: !isSelected)
    }
    
    
    private func startFocus() {
        mainViewModel.exitMultiSelectMode()
        // TODO: 启动专注计时器
        print("启动专注计时器: \(task.taskContent)")
    }
    
    
    /// 置顶任务
    private func moveToTop() {
        print("置顶任务: \(task.taskContent)")
        // TODO: 实现置顶逻辑
        handleMoveTask(isToTop: true)
        
    }
    
    /// 置底任务
    private func moveToBottom() {
        print("置底任务: \(task.taskContent)")
        // TODO: 实现置底逻辑
        handleMoveTask(isToTop: false)
        
    }
    
    /// 删除任务
    private func deleteTask() {
        print("删除任务: \(task.taskContent)")
        
        Task {
            do {
                // 1. 创建更新后的任务模型
                let updatedTask = task
                updatedTask.delete = true
                updatedTask.status = "delete"
                
                // 2. 调用通用更新方法
                let queryManager = TDQueryConditionManager()
                let result = try await queryManager.updateLocalTaskWithModel(
                    updatedTask: updatedTask,
                    context: modelContext
                )
                
                print("删除任务成功，结果: \(result)")
                
                // 3. 调用同步方法
                await TDMainViewModel.shared.performSyncSeparately()
                
            } catch {
                print("删除任务失败: \(error)")
            }
        }
    }
    
    /// 处理任务移动（置顶或置底）
    /// - Parameter isToTop: true 表示置顶，false 表示置底
    private func handleMoveTask(isToTop: Bool) {
        // 检查是否为重复事件
        if let repeatId = task.standbyStr1, !repeatId.isEmpty {
            // 是重复事件，先获取重复事件数组，再显示弹窗
            Task {
                await showRepeatTaskAlertWithCount(isToTop: isToTop, repeatId: repeatId)
            }
        } else {
            // 不是重复事件，直接执行操作
            performMoveTask(isToTop: isToTop, isRepeatGroup: false)
        }
    }
    
    /// 显示重复事件操作弹窗（带数量）
    /// - Parameters:
    ///   - isToTop: true 表示置顶，false 表示置底
    ///   - repeatId: 重复事件ID
    @MainActor
    private func showRepeatTaskAlertWithCount(isToTop: Bool, repeatId: String) async {
        do {
            // 先获取重复事件数组
            let queryManager = TDQueryConditionManager()
            let duplicateTasks = try await queryManager.getDuplicateTasks(
                standbyStr1: repeatId,
                onlyUncompleted: false,
                context: modelContext
            )
            
            let action = isToTop ? "置顶" : "置底"
            let alert = NSAlert()
            alert.messageText = "重复事件操作"
            alert.informativeText = "是否对该重复组的\(duplicateTasks.count)个事件进行批量\(action)操作？"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "仅该事件")
            alert.addButton(withTitle: "确定")
            alert.addButton(withTitle: "取消")
            
            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn:
                // 仅该事件
                performMoveTask(isToTop: isToTop, isRepeatGroup: false)
            case .alertSecondButtonReturn:
                // 确定（批量操作）
                performMoveTask(isToTop: isToTop, isRepeatGroup: true, duplicateTasks: duplicateTasks)
            case .alertThirdButtonReturn:
                // 取消
                break
            default:
                break
            }
            
        } catch {
            print("获取重复事件失败: \(error)")
            // 如果获取失败，直接执行单个任务操作
            performMoveTask(isToTop: isToTop, isRepeatGroup: false)
        }
    }
    /// 执行任务移动操作
    /// - Parameters:
    ///   - isToTop: true 表示置顶，false 表示置底
    ///   - isRepeatGroup: 是否为重复组批量操作
    ///   - duplicateTasks: 重复事件数组（仅在批量操作时需要）
    private func performMoveTask(isToTop: Bool, isRepeatGroup: Bool, duplicateTasks: [TDMacSwiftDataListModel]? = nil) {
        let action = isToTop ? "置顶" : "置底"
        let scope = isRepeatGroup ? "重复组" : "单个"
        
        print("\(action)任务: \(task.taskContent) (\(scope))")
        
        Task {
            if isRepeatGroup, let duplicateTasks = duplicateTasks {
                // 批量操作重复组
                print("开始批量\(action) \(duplicateTasks.count) 个重复事件")
                await performBatchMove(duplicateTasks: duplicateTasks, isToTop: isToTop)
                
            } else {
                // 单个任务操作
                await performSingleMove(task: task, isToTop: isToTop)
            }
        }
    }
    
    // MARK: - 移动操作实现
    
    /// 执行批量移动操作
    /// - Parameters:
    ///   - duplicateTasks: 重复事件数组
    ///   - isToTop: true 表示置顶，false 表示置底
    private func performBatchMove(duplicateTasks: [TDMacSwiftDataListModel], isToTop: Bool) async {
        let action = isToTop ? "置顶" : "置底"
        
        do {
            // 遍历每个重复事件
            for task in duplicateTasks {
                await moveSingleTask(task: task, isToTop: isToTop)
            }
            
            // 保存所有更改
            try modelContext.save()
            print("批量\(action)完成，共处理 \(duplicateTasks.count) 个任务")
            
        } catch {
            print("批量\(action)失败: \(error)")
        }
    }
    
    /// 执行单个任务移动操作
    /// - Parameters:
    ///   - task: 要移动的任务
    ///   - isToTop: true 表示置顶，false 表示置底
    private func performSingleMove(task: TDMacSwiftDataListModel, isToTop: Bool) async {
        do {
            await moveSingleTask(task: task, isToTop: isToTop)
            // 保存更改
            try modelContext.save()
        } catch {
            print("移动任务失败: \(error)")
        }
    }
    
    /// 移动单个任务的核心逻辑
    /// - Parameters:
    ///   - task: 要移动的任务
    ///   - isToTop: true 表示置顶，false 表示置底
    private func moveSingleTask(task: TDMacSwiftDataListModel, isToTop: Bool) async {
        let queryManager = TDQueryConditionManager()
        let action = isToTop ? "置顶" : "置底"
        
        do {
            // 计算新的 taskSort 值
            let newTaskSort: Decimal
            let randomValue = TDAppConfig.randomTaskSort()
            
            if isToTop {
                // 置顶：获取最小值并计算
                let minTaskSort = try await queryManager.getMinTaskSortForDate(
                    todoTime: task.todoTime,
                    context: modelContext
                )
                
                if minTaskSort == 0 {
                    // 如果最小值为 0，使用默认值
                    newTaskSort = TDAppConfig.defaultTaskSort
                } else if minTaskSort > TDAppConfig.maxTaskSort * 2.0 {
                    // 最小值减去随机区间值
                    newTaskSort = minTaskSort - randomValue
                } else {
                    // 否则用最小值除以2.0
                    newTaskSort = minTaskSort / 2.0
                }
            } else {
                // 置底：获取最大值并计算
                let maxTaskSort = try await queryManager.getMaxTaskSortForDate(
                    todoTime: task.todoTime,
                    context: modelContext
                )
                // 用最大值加上随机区间值
                newTaskSort = maxTaskSort + randomValue
            }
            
            // 更新任务的 taskSort 值
            let updatedTask = task
            updatedTask.taskSort = newTaskSort
            
            let queryManager = TDQueryConditionManager()
            let result = try await queryManager.updateLocalTaskWithModel(
                updatedTask: updatedTask,
                context: modelContext
            )
            
            if result == .updated {
                print("\(action)任务成功: \(task.taskContent), 新 taskSort: \(newTaskSort)")
                
                // 调用同步方法
                await TDMainViewModel.shared.performSyncSeparately()
            } else {
                print("\(action)任务失败: 更新结果异常")
            }
            
        } catch {
            print("\(action)任务失败: \(error)")
        }
        
    }
    
    /// 处理创建副本的逻辑
    /// - Parameter copyType: 副本创建类型（普通副本、到今天、到指定日期）
    private func handleCreateCopy(copyType: CopyType) {
        print("📋 开始创建副本，类型: \(copyType)，任务: \(task.taskContent)")
        
        Task {
            do {
                // 1. 将当前任务转换为 TDTaskModel
                let taskModel = TDTaskModel(from: task)
                
                // 2. 将 TDTaskModel 转换回新的 TDMacSwiftDataListModel 对象
                let copiedTask = taskModel.toSwiftDataModel()
                
                // 2. 重置副本的基本信息
                copiedTask.standbyStr1 = ""  // 清空重复事件ID
                copiedTask.complete = false
                // 3. 根据副本类型设置日期
                switch copyType {
                case .normal:
                    // 保持原日期，不做修改
                    print("📅 创建副本 - 保持原日期: \(task.todoTime)")
                    
                case .toToday:
                    // 设置为今天开始时间
                    let todayStartTime = Date().startOfDayTimestamp
                    copiedTask.todoTime = todayStartTime
                    print("📅 创建副本到今天: \(todayStartTime)")
                    
                case .toSpecificDate:
                    // 设置为指定日期开始时间
                    let specificDateStartTime = selectedCopyDate.startOfDayTimestamp
                    copiedTask.todoTime = specificDateStartTime
                    print("📅 创建副本到指定日期: \(specificDateStartTime)")
                }
                
                // 4. 调用添加本地数据方法（会自动计算 taskSort）
                let queryManager = TDQueryConditionManager()
                let result = try await queryManager.addLocalTask(copiedTask, context: modelContext)
                
                if result == .added {
                    // 5. 执行数据同步
                    await TDMainViewModel.shared.performSyncSeparately()
                    
                    print("✅ 创建副本成功，新任务ID: \(copiedTask.taskId)")
                } else {
                    print("❌ 创建副本失败，结果: \(result)")
                }
                
            } catch {
                print("❌ 创建副本失败: \(error)")
            }
        }
    }
    
    // MARK: - Equatable 实现（性能优化关键）
    
    static func == (lhs: TDTaskRowView, rhs: TDTaskRowView) -> Bool {
        // 只比较关键属性，避免不必要的重新渲染
        let lhsIsSelected = lhs.mainViewModel.selectedTasks.contains(where: { $0.taskId == lhs.task.taskId })
        let rhsIsSelected = rhs.mainViewModel.selectedTasks.contains(where: { $0.taskId == rhs.task.taskId })
        
        // 只比较关键属性，避免不必要的重新渲染
        return lhs.task.taskId == rhs.task.taskId &&
        lhs.task.complete == rhs.task.complete &&
        lhs.task.taskContent == rhs.task.taskContent &&
        lhs.task.taskDescribe == rhs.task.taskDescribe &&
        lhs.task.isSubOpen == rhs.task.isSubOpen &&
        lhs.task.subTaskList == rhs.task.subTaskList &&
        lhs.isHovered == rhs.isHovered &&
        lhs.rightBadgeText == rhs.rightBadgeText &&
        lhs.rightBadgeColorRole == rhs.rightBadgeColorRole &&
        lhs.mainViewModel.isMultiSelectMode == rhs.mainViewModel.isMultiSelectMode &&
        lhs.mainViewModel.selectedTasks.contains(where: { $0.taskId == lhs.task.taskId }) ==
        rhs.mainViewModel.selectedTasks.contains(where: { $0.taskId == rhs.task.taskId })
    }
    
}

private extension TDTaskRowView {
    func rightBadgeColor(_ role: TDTaskRowRightBadgeColorRole) -> Color {
        switch role {
        case .themeLevel5:
            return themeManager.color(level: 5)
        case .newYearRedLevel5:
            return themeManager.fixedColor(themeId: "new_year_red", level: 5)
        case .titleText:
            return themeManager.titleTextColor
        }
    }
}

#Preview {
    let testTask = TDMacSwiftDataListModel(
        id: 1,
        taskId: "test",
        taskContent: "这是一个测试任务，内容比较长，用来测试多行显示效果",
        taskDescribe: "这是任务的详细描述，用来测试描述显示功能",
        complete: false,
        createTime: Date.currentTimestamp,
        delete: false,
        reminderTime: Date.currentTimestamp,
        snowAdd: 0,
        snowAssess: 7,
        standbyInt1: 0,
        standbyStr1: "每天",
        standbyStr2: "[{\"isComplete\":false,\"content\":\"子任务1\"},{\"isComplete\":true,\"content\":\"子任务2\"}]",
        standbyStr3: nil,
        standbyStr4: "[{\"downloading\":false,\"name\":\"附件1.pdf\",\"size\":\"1.2MB\",\"suffix\":\"pdf\",\"url\":\"http://example.com\"}]",
        syncTime: Date.currentTimestamp,
        taskSort: 1000,
        todoTime: Date.currentTimestamp,
        userId: 1,
        version: 1
    )
    
    // 设置子任务和附件列表
    testTask.subTaskList = [
        TDMacSwiftDataListModel.SubTask(isComplete: false, content: "子任务1"),
        TDMacSwiftDataListModel.SubTask(isComplete: true, content: "子任务2")
    ]
    
    testTask.attachmentList = [
        TDMacSwiftDataListModel.Attachment(
            name: "附件1.pdf",
            size: "1.2MB",
            suffix: "pdf",
            url: "http://example.com"
        )
    ]
    
    return TDTaskRowView(task: testTask, category: nil, orderNumber: nil, isFirstRow: true, isLastRow: true)
        .environmentObject(TDThemeManager.shared)
}

//
////
////  TDTaskRowView.swift
////  TodoMacRepertorie
////
////  Created by Assistant on 2025/1/20.
////
//
//import SwiftUI
//import SwiftData
//
///// 副本创建类型枚举
//enum CopyType {
//    case normal          // 创建副本（保持原日期）
//    case toToday         // 创建副本到今天
//    case toSpecificDate  // 创建副本到指定日期
//}
//
//struct CustomDisclosureGroupStyle: DisclosureGroupStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        VStack(alignment: .leading, spacing: 0) {
//            configuration.label
//            if configuration.isExpanded {
//                configuration.content
//                    .transition(.asymmetric(
//                        insertion: .opacity.combined(with: .move(edge: .top)).animation(.easeOut(duration: 0.3)),
//                        removal: .opacity.combined(with: .move(edge: .top)).animation(.easeIn(duration: 0.25))
//                    ))
//            }
//        }
//        .animation(.easeInOut(duration: 0.4), value: configuration.isExpanded)
//    }
//}
//
//// MARK: - 独立视图组件
//
///// 难度指示条组件
//struct DifficultyIndicatorView: View {
//    let difficultyColor: Color
//
//    var body: some View {
//        RoundedRectangle(cornerRadius: 2)
//            .fill(difficultyColor)
//            .frame(width: 4)
//            .padding(.vertical, 2)
//            .padding(.leading, 1)
//            .frame(maxHeight: .infinity)
//    }
//}
//
///// 复选框/多选圆圈组件
//struct TaskCheckboxView: View {
//    let task: TDMacSwiftDataListModel
//    let isMultiSelectMode: Bool
//    let isSelected: Bool
//    let shouldShowOrderNumber: Bool
//    let orderNumber: Int?
//    let onToggle: () -> Void
//
//    @EnvironmentObject private var themeManager: TDThemeManager
//
//    var body: some View {
//        Button(action: onToggle) {
//            ZStack {
//                if isMultiSelectMode {
//                    // 多选模式：显示圆圈
//                    Circle()
//                        .stroke(themeManager.color(level: 5), lineWidth: 1.5)
//                        .frame(width: 18, height: 18)
//
//                    if isSelected {
//                        Circle()
//                            .fill(themeManager.color(level: 5))
//                            .frame(width: 18, height: 18)
//
//                        Image(systemName: "checkmark")
//                            .font(.system(size: 10, weight: .medium))
//                            .foregroundColor(.white)
//                    }
//                } else {
//                    RoundedRectangle(cornerRadius: 3)
//                        .stroke(task.checkboxColor, lineWidth: 1.5)
//                        .frame(width: 18, height: 18)
//
//                    if task.complete {
//                        RoundedRectangle(cornerRadius: 3)
//                            .fill(task.checkboxColor)
//                            .frame(width: 18, height: 18)
//
//                        Image(systemName: "checkmark")
//                            .font(.system(size: 10, weight: .bold))
//                            .foregroundColor(.white)
//                    } else if shouldShowOrderNumber {
//                        Text("\(orderNumber!)")
//                            .font(.system(size: 8, weight: .medium))
//                            .foregroundColor(task.checkboxColor)
//                    }
//                }
//            }
//            .contentShape(Rectangle())
//        }
//        .buttonStyle(PlainButtonStyle())
//    }
//}
//
///// 任务内容组件
//struct TaskContentView: View {
//    let task: TDMacSwiftDataListModel
//    let category: TDSliderBarModel?
//
//    @EnvironmentObject private var themeManager: TDThemeManager
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            // 任务标题
//            Text(task.taskContent)
//                .font(.system(size: 14))
//                .foregroundColor(task.taskTitleColor)
//                .strikethrough(task.taskTitleStrikethrough)
//                .opacity(task.complete ? 0.6 : 1.0)
//                .lineLimit(TDSettingManager.shared.taskTitleLines)
//
//            // 任务描述
//            if task.shouldShowTaskDescription {
//                Text(task.taskDescribe ?? "")
//                    .font(.system(size: 13))
//                    .foregroundColor(themeManager.descriptionTextColor)
//                    .lineLimit(TDSettingManager.shared.taskDescriptionLines)
//            }
//
//            // 任务日期
//            if category?.categoryId != -100 && !task.taskDateConditionalString.isEmpty {
//                Text(task.taskDateConditionalString)
//                    .font(.system(size: 10))
//                    .foregroundColor(task.taskDateColor)
//            }
//
//            // 底部信息栏
//            TaskInfoBarView(task: task)
//
//            // 子任务
//            if !task.subTaskList.isEmpty {
//                SubTaskView(task: task)
//            }
//        }
//    }
//}
//
///// 任务信息栏组件
//struct TaskInfoBarView: View {
//    let task: TDMacSwiftDataListModel
//
//    @EnvironmentObject private var themeManager: TDThemeManager
//
//    var body: some View {
//        if task.hasReminder || task.hasRepeat || !task.attachmentList.isEmpty {
//            HStack(spacing: 12) {
//                // 提醒时间
//                if task.hasReminder {
//                    HStack(spacing: 4) {
//                        Image(systemName: "clock")
//                            .font(.system(size: 12, weight: .medium))
//                            .foregroundColor(themeManager.color(level: 4))
//                        Text(task.reminderTimeString)
//                            .font(.system(size: 12, weight: .medium))
//                            .foregroundColor(themeManager.color(level: 4))
//                    }
//                }
//
//                // 重复事件
//                if task.hasRepeat {
//                    Image(systemName: "repeat")
//                        .font(.system(size: 12, weight: .medium))
//                        .foregroundColor(themeManager.color(level: 4))
//                }
//
//                // 附件
//                if !task.attachmentList.isEmpty {
//                    Image(systemName: "paperclip")
//                        .font(.system(size: 12, weight: .medium))
//                        .foregroundColor(themeManager.color(level: 4))
//                }
//
//                Spacer()
//            }
//        }
//    }
//}
//
///// 子任务组件
//struct SubTaskView: View {
//    let task: TDMacSwiftDataListModel
//
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @Environment(\.modelContext) private var modelContext
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            // 展开/收起按钮
//            SubTaskToggleButton(task: task)
//
//            // 子任务列表
//            if task.isSubOpen {
//                SubTaskListView(task: task)
//            }
//        }
//    }
//}
//
///// 子任务切换按钮
//struct SubTaskToggleButton: View {
//    let task: TDMacSwiftDataListModel
//
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @Environment(\.modelContext) private var modelContext
//
//    var body: some View {
//        Button(action: {
//            task.isSubOpen.toggle()
//            do {
//                try modelContext.save()
//            } catch {
//                print("保存子任务展开状态失败: \(error)")
//            }
//        }) {
//            HStack(spacing: 4) {
//                Image(systemName: "chevron.down")
//                    .font(.system(size: 8))
//                    .foregroundColor(themeManager.descriptionTextColor)
//                    .rotationEffect(.degrees(task.isSubOpen ? 180 : 0))
//
//                Text(task.isSubOpen ? "收起" : "展开")
//                    .font(.system(size: 10))
//                    .foregroundColor(themeManager.descriptionTextColor)
//            }
//            .frame(width: 55, height: 20)
//            .background(
//                RoundedRectangle(cornerRadius: 6)
//                    .fill(themeManager.secondaryBackgroundColor)
//            )
//        }
//        .buttonStyle(PlainButtonStyle())
//        .contentShape(Rectangle())
//    }
//}
//
///// 子任务列表
//struct SubTaskListView: View {
//    let task: TDMacSwiftDataListModel
//
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @Environment(\.modelContext) private var modelContext
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            ForEach(Array(task.subTaskList.enumerated()), id: \.offset) { index, subTask in
//                SubTaskRowView(
//                    task: task,
//                    subTask: subTask,
//                    subTaskIndex: index
//                )
//            }
//        }
//        .padding(.leading, 8)
//    }
//}
//
///// 单个子任务行
//struct SubTaskRowView: View {
//    let task: TDMacSwiftDataListModel
//    let subTask: TDMacSwiftDataListModel.SubTask
//    let subTaskIndex: Int
//
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @Environment(\.modelContext) private var modelContext
//
//    var body: some View {
//        HStack(spacing: 6) {
//            if task.complete {
//                // 当前任务完成时，所有子任务显示圆点（不可点击）
//                Circle()
//                    .fill(themeManager.color(level: 5))
//                    .frame(width: 8, height: 8)
//            } else {
//                // 当前任务未完成时，根据子任务状态显示（可点击）
//                Button(action: {
//                    toggleSubTaskCompletion(subTaskIndex: subTaskIndex)
//                }) {
//                    ZStack {
//                        Circle()
//                            .stroke(themeManager.color(level: 5), lineWidth: 1)
//                            .frame(width: 12, height: 12)
//
//                        if subTask.isComplete {
//                            Circle()
//                                .fill(themeManager.color(level: 5))
//                                .frame(width: 12, height: 12)
//
//                            Image(systemName: "checkmark")
//                                .font(.system(size: 8, weight: .medium))
//                                .foregroundColor(.white)
//                        }
//                    }
//                    .contentShape(Rectangle())
//                }
//                .buttonStyle(PlainButtonStyle())
//            }
//
//            Text(subTask.content)
//                .font(.system(size: 11))
//                .foregroundColor(themeManager.subtaskTextColor)
//                .strikethrough(subTask.isComplete)
//                .opacity(subTask.isComplete ? 0.6 : 1.0)
//        }
//    }
//
//    private func toggleSubTaskCompletion(subTaskIndex: Int) {
//        Task {
//            do {
//                let updatedTask = task
//                let newCompletionState = !task.subTaskList[subTaskIndex].isComplete
//
//                updatedTask.subTaskList[subTaskIndex].isComplete = newCompletionState
//
//                let newSubTasksString = updatedTask.generateSubTasksString()
//                updatedTask.standbyStr2 = newSubTasksString.isEmpty ? nil : newSubTasksString
//
//                if updatedTask.allSubTasksCompleted {
//                    let shouldAutoCompleteParent = true
//
//                    if shouldAutoCompleteParent && !updatedTask.complete {
//                        updatedTask.complete = true
//                    }
//                }
//
//                let queryManager = TDQueryConditionManager()
//                let result = try await queryManager.updateLocalTaskWithModel(
//                    updatedTask: updatedTask,
//                    context: modelContext
//                )
//
//                if result == .updated {
//                    await TDMainViewModel.shared.performSyncSeparately()
//                }
//            } catch {
//                print("切换子任务状态失败: \(error)")
//            }
//        }
//    }
//}
//
///// 专注按钮组件
//struct FocusButtonView: View {
//    let onFocus: () -> Void
//
//    @EnvironmentObject private var themeManager: TDThemeManager
//
//    var body: some View {
//        Button(action: onFocus) {
//            Image(systemName: "timer")
//                .font(.system(size: 14))
//                .foregroundColor(themeManager.color(level: 5))
//                .frame(width: 32, height: 32)
//                .background(themeManager.color(level: 5).opacity(0.1))
//                .clipShape(Circle())
//        }
//        .buttonStyle(PlainButtonStyle())
//    }
//}
//
///// 任务行背景组件
//struct TaskRowBackgroundView: View {
//    let isSelected: Bool
//    let isHovered: Bool
//
//    @EnvironmentObject private var themeManager: TDThemeManager
//
//    var body: some View {
//        Group {
//            if isSelected {
//                Rectangle()
//                    .fill(.ultraThinMaterial)
//                    .background(themeManager.color(level: 4).opacity(0.1))
//            } else if isHovered {
//                themeManager.secondaryBackgroundColor
//            } else {
//                themeManager.backgroundColor
//            }
//        }
//    }
//}
//
//// MARK: - 主任务行视图
//
///// 通用任务行视图组件 - 深度性能优化版本
//struct TDTaskRowView: View, Equatable {
//    let task: TDMacSwiftDataListModel
//    let category: TDSliderBarModel?
//    let orderNumber: Int?
//
//    let isFirstRow: Bool
//    let isLastRow: Bool
//
//    // 状态管理优化：使用 @State 而不是 @ObservedObject 来减少重绘
//    @State private var isHovered: Bool = false
//    @State private var showDatePickerForCopy: Bool = false
//    @State private var selectedCopyDate: Date = Date()
//
//    // 回调函数
//    var onCopySuccess: (() -> Void)?
//    var onEnterMultiSelect: (() -> Void)?
//
//    // 环境对象
//    @EnvironmentObject private var themeManager: TDThemeManager
//    @Environment(\.modelContext) private var modelContext
//
//    // 计算属性
//    private var shouldShowOrderNumber: Bool {
//        category?.categoryId == -100 && task.shouldShowOrderNumber && orderNumber != nil
//    }
//
//    private var shouldShowPinToTop: Bool {
//        !isFirstRow
//    }
//
//    private var shouldShowPinToBottom: Bool {
//        !isLastRow
//    }
//
//    // 优化：缓存选中状态，避免重复计算
//    private var isSelected: Bool {
//        let mainViewModel = TDMainViewModel.shared
//        if let selectedTask = mainViewModel.selectedTask, selectedTask.taskId == task.taskId {
//            return true
//        }
//        return mainViewModel.selectedTasks.contains { $0.taskId == task.taskId }
//    }
//
//    // 优化：缓存多选模式状态
//    private var isMultiSelectMode: Bool {
//        TDMainViewModel.shared.isMultiSelectMode
//    }
//
//    var body: some View {
//        HStack(spacing: 0) {
//            // 1. 难度指示条
//            DifficultyIndicatorView(difficultyColor: task.difficultyColor)
//
//            // 2. 主要内容区域
//            VStack(alignment: .center, spacing: 8) {
//                HStack(alignment: .center, spacing: 12) {
//                    HStack(alignment: .top, spacing: 12) {
//                        // 复选框/多选圆圈
//                        TaskCheckboxView(
//                            task: task,
//                            isMultiSelectMode: isMultiSelectMode,
//                            isSelected: isSelected,
//                            shouldShowOrderNumber: shouldShowOrderNumber,
//                            orderNumber: orderNumber,
//                            onToggle: handleCheckboxToggle
//                        )
//
//                        // 任务内容
//                        TaskContentView(task: task, category: category)
//
//                        Spacer()
//                    }
//
//                    // 专注按钮
//                    FocusButtonView(onFocus: startFocus)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 12)
//        }
//        .background(TaskRowBackgroundView(isSelected: isSelected, isHovered: isHovered))
//        .onHover { hovering in
//            // 防抖处理
//            if hovering != isHovered {
//                isHovered = hovering
//            }
//        }
//        .overlay(
//            Rectangle()
//                .fill(themeManager.separatorColor)
//                .frame(height: 1.0)
//                .frame(maxWidth: .infinity)
//                .frame(maxHeight: .infinity, alignment: .bottom)
//        )
//        .onTapGesture {
//            handleRowTap()
//        }
//        .contextMenu {
//            if !isMultiSelectMode {
//                buildContextMenu()
//            }
//        }
//        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
//            if !isMultiSelectMode {
//                buildSwipeActions()
//            }
//        }
//        // 性能优化修饰符
//        .drawingGroup(opaque: true)
//        .fixedSize(horizontal: false, vertical: true)
//        .animation(.none, value: task.complete)
//        .popover(isPresented: $showDatePickerForCopy) {
//            TDCustomDatePickerView(
//                selectedDate: $selectedCopyDate,
//                isPresented: $showDatePickerForCopy,
//                onDateSelected: { date in
//                    handleCreateCopy(copyType: .toSpecificDate)
//                }
//            )
//            .frame(width: 280, height: 320)
//        }
//    }
//
//    // MARK: - 事件处理方法
//
//    private func handleCheckboxToggle() {
//        if isMultiSelectMode {
//            let mainViewModel = TDMainViewModel.shared
//            let isSelected = mainViewModel.selectedTasks.contains { $0.taskId == task.taskId }
//            mainViewModel.updateSelectedTask(task: task, isSelected: !isSelected)
//        } else {
//            toggleTaskCompletion()
//        }
//    }
//
//    private func handleRowTap() {
//        if isMultiSelectMode {
//            let mainViewModel = TDMainViewModel.shared
//            let isSelected = mainViewModel.selectedTasks.contains { $0.taskId == task.taskId }
//            mainViewModel.updateSelectedTask(task: task, isSelected: !isSelected)
//        } else {
//            TDMainViewModel.shared.selectTask(task)
//        }
//    }
//
//    private func startFocus() {
//        TDMainViewModel.shared.exitMultiSelectMode()
//    }
//
//    // MARK: - 上下文菜单构建
//
//    @ViewBuilder
//    private func buildContextMenu() -> some View {
//        Button("选择事件") {
//            let mainViewModel = TDMainViewModel.shared
//            mainViewModel.enterMultiSelectMode()
//            mainViewModel.updateSelectedTask(task: task, isSelected: true)
//            onEnterMultiSelect?()
//        }
//
//        Divider()
//
//        Button("复制内容") {
//            let singleTaskArray = [task]
//            let success = TDDataOperationManager.shared.copyTasksToClipboard(singleTaskArray)
//            if success {
//                onCopySuccess?()
//            }
//        }
//
//        Menu("创建副本") {
//            Button("创建副本") {
//                handleCreateCopy(copyType: .normal)
//            }
//
//            if !task.isToday {
//                Button("创建到今天") {
//                    handleCreateCopy(copyType: .toToday)
//                }
//            }
//
//            Button("创建到指定日期") {
//                showDatePickerForCopy = true
//            }
//        }
//
//        Button("移到最前") {
//            handleMoveTask(isToTop: true)
//        }
//        .disabled(category?.categoryId != -100 || isFirstRow)
//
//        Button("移到最后") {
//            handleMoveTask(isToTop: false)
//        }
//        .disabled(category?.categoryId != -100 || isLastRow)
//
//        Button("删除", role: .destructive) {
//            deleteTask()
//        }
//    }
//
//    // MARK: - 滑动操作构建
//
//    @ViewBuilder
//    private func buildSwipeActions() -> some View {
//        Button(role: .destructive, action: deleteTask) {
//            Image(systemName: "trash.fill")
//                .font(.system(size: 16, weight: .medium))
//                .foregroundColor(.white)
//        }
//        .tint(TDThemeManager.shared.fixedColor(themeId: "new_year_red", level: 5))
//
//        if category?.categoryId == -100 && !isLastRow {
//            Button(action: moveToBottom) {
//                Image(systemName: "arrowshape.down.fill")
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundColor(.white)
//            }
//            .tint(TDThemeManager.shared.fixedColor(themeId: "wish_orange", level: 5))
//        }
//
//        if category?.categoryId == -100 && !isFirstRow {
//            Button(action: moveToTop) {
//                Image(systemName: "arrowshape.up.fill")
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundColor(.white)
//            }
//            .tint(Color.fromHex("#404040"))
//        }
//    }
//
//    // MARK: - 任务操作方法
//
//    private func toggleTaskCompletion() {
//        print("切换任务完成状态: \(task.taskContent)")
//        Task {
//            if !task.complete {
//                TDAudioManager.shared.playCompletionSound()
//            }
//            do {
//                let updatedTask = task
//                updatedTask.complete = !task.complete
//
//                let queryManager = TDQueryConditionManager()
//                let result = try await queryManager.updateLocalTaskWithModel(
//                    updatedTask: updatedTask,
//                    context: modelContext
//                )
//
//                if result == .updated {
//                    print("切换任务状态成功: \(task.taskContent)")
//                    await TDMainViewModel.shared.performSyncSeparately()
//                } else {
//                    print("切换任务状态失败: 更新结果异常")
//                }
//            } catch {
//                print("切换任务状态失败: \(error)")
//            }
//        }
//    }
//
//    /// 置顶任务
//    private func moveToTop() {
//        print("置顶任务: \(task.taskContent)")
//        handleMoveTask(isToTop: true)
//    }
//
//    /// 置底任务
//    private func moveToBottom() {
//        print("置底任务: \(task.taskContent)")
//        handleMoveTask(isToTop: false)
//    }
//
//    /// 删除任务
//    private func deleteTask() {
//        print("删除任务: \(task.taskContent)")
//
//        Task {
//            do {
//                let updatedTask = task
//                updatedTask.delete = true
//
//                let queryManager = TDQueryConditionManager()
//                let result = try await queryManager.updateLocalTaskWithModel(
//                    updatedTask: updatedTask,
//                    context: modelContext
//                )
//
//                print("删除任务成功，结果: \(result)")
//                await TDMainViewModel.shared.performSyncSeparately()
//            } catch {
//                print("删除任务失败: \(error)")
//            }
//        }
//    }
//
//    /// 处理任务移动（置顶或置底）
//    private func handleMoveTask(isToTop: Bool) {
//        if let repeatId = task.standbyStr1, !repeatId.isEmpty {
//            Task {
//                await showRepeatTaskAlertWithCount(isToTop: isToTop, repeatId: repeatId)
//            }
//        } else {
//            performMoveTask(isToTop: isToTop, isRepeatGroup: false)
//        }
//    }
//
//    /// 显示重复事件操作弹窗（带数量）
//    @MainActor
//    private func showRepeatTaskAlertWithCount(isToTop: Bool, repeatId: String) async {
//        do {
//            let queryManager = TDQueryConditionManager()
//            let duplicateTasks = try await queryManager.getDuplicateTasks(
//                standbyStr1: repeatId,
//                onlyUncompleted: false,
//                context: modelContext
//            )
//
//            let action = isToTop ? "置顶" : "置底"
//            let alert = NSAlert()
//            alert.messageText = "重复事件操作"
//            alert.informativeText = "是否对该重复组的\(duplicateTasks.count)个事件进行批量\(action)操作？"
//            alert.alertStyle = .informational
//            alert.addButton(withTitle: "仅该事件")
//            alert.addButton(withTitle: "确定")
//            alert.addButton(withTitle: "取消")
//
//            let response = alert.runModal()
//            switch response {
//            case .alertFirstButtonReturn:
//                performMoveTask(isToTop: isToTop, isRepeatGroup: false)
//            case .alertSecondButtonReturn:
//                performMoveTask(isToTop: isToTop, isRepeatGroup: true, duplicateTasks: duplicateTasks)
//            case .alertThirdButtonReturn:
//                break
//            default:
//                break
//            }
//        } catch {
//            print("获取重复事件失败: \(error)")
//            performMoveTask(isToTop: isToTop, isRepeatGroup: false)
//        }
//    }
//
//    /// 执行任务移动操作
//    private func performMoveTask(isToTop: Bool, isRepeatGroup: Bool, duplicateTasks: [TDMacSwiftDataListModel]? = nil) {
//        let action = isToTop ? "置顶" : "置底"
//        let scope = isRepeatGroup ? "重复组" : "单个"
//
//        print("\(action)任务: \(task.taskContent) (\(scope))")
//
//        Task {
//            if isRepeatGroup, let duplicateTasks = duplicateTasks {
//                print("开始批量\(action) \(duplicateTasks.count) 个重复事件")
//                await performBatchMove(duplicateTasks: duplicateTasks, isToTop: isToTop)
//            } else {
//                await performSingleMove(task: task, isToTop: isToTop)
//            }
//        }
//    }
//
//    // MARK: - 移动操作实现
//
//    /// 执行批量移动操作
//    private func performBatchMove(duplicateTasks: [TDMacSwiftDataListModel], isToTop: Bool) async {
//        let action = isToTop ? "置顶" : "置底"
//
//        do {
//            for task in duplicateTasks {
//                await moveSingleTask(task: task, isToTop: isToTop)
//            }
//
//            try modelContext.save()
//            print("批量\(action)完成，共处理 \(duplicateTasks.count) 个任务")
//        } catch {
//            print("批量\(action)失败: \(error)")
//        }
//    }
//
//    /// 执行单个任务移动操作
//    private func performSingleMove(task: TDMacSwiftDataListModel, isToTop: Bool) async {
//        do {
//            await moveSingleTask(task: task, isToTop: isToTop)
//            try modelContext.save()
//        } catch {
//            print("移动任务失败: \(error)")
//        }
//    }
//
//    /// 移动单个任务的核心逻辑
//    private func moveSingleTask(task: TDMacSwiftDataListModel, isToTop: Bool) async {
//        let queryManager = TDQueryConditionManager()
//        let action = isToTop ? "置顶" : "置底"
//
//        do {
//            let newTaskSort: Decimal
//            let randomValue = TDAppConfig.randomTaskSort()
//
//            if isToTop {
//                let minTaskSort = try await queryManager.getMinTaskSortForDate(
//                    todoTime: task.todoTime,
//                    context: modelContext
//                )
//
//                if minTaskSort == 0 {
//                    newTaskSort = TDAppConfig.defaultTaskSort
//                } else if minTaskSort > TDAppConfig.maxTaskSort * 2.0 {
//                    newTaskSort = minTaskSort - randomValue
//                } else {
//                    newTaskSort = minTaskSort / 2.0
//                }
//            } else {
//                let maxTaskSort = try await queryManager.getMaxTaskSortForDate(
//                    todoTime: task.todoTime,
//                    context: modelContext
//                )
//                newTaskSort = maxTaskSort + randomValue
//            }
//
//            let updatedTask = task
//            updatedTask.taskSort = newTaskSort
//
//            let result = try await queryManager.updateLocalTaskWithModel(
//                updatedTask: updatedTask,
//                context: modelContext
//            )
//
//            if result == .updated {
//                print("\(action)任务成功: \(task.taskContent), 新 taskSort: \(newTaskSort)")
//                await TDMainViewModel.shared.performSyncSeparately()
//            } else {
//                print("\(action)任务失败: 更新结果异常")
//            }
//        } catch {
//            print("\(action)任务失败: \(error)")
//        }
//    }
//
//    /// 处理创建副本的逻辑
//    private func handleCreateCopy(copyType: CopyType) {
//        print("📋 开始创建副本，类型: \(copyType)，任务: \(task.taskContent)")
//
//        Task {
//            do {
//                let copiedTask = task
//                copiedTask.taskId = TDAppConfig.generateTaskId()
//                copiedTask.standbyStr1 = ""
//
//                switch copyType {
//                case .normal:
//                    print("📅 创建副本 - 保持原日期: \(task.todoTime)")
//                case .toToday:
//                    copiedTask.todoTime = Date().startOfDayTimestamp
//                case .toSpecificDate:
//                    copiedTask.todoTime = selectedCopyDate.startOfDayTimestamp
//                }
//
//                let queryManager = TDQueryConditionManager()
//                let result = try await queryManager.addLocalTask(copiedTask, context: modelContext)
//
//                if result == .added {
//                    await TDMainViewModel.shared.performSyncSeparately()
//                    print("✅ 创建副本成功，新任务ID: \(copiedTask.taskId)")
//                } else {
//                    print("❌ 创建副本失败，结果: \(result)")
//                }
//            } catch {
//                print("❌ 创建副本失败: \(error)")
//            }
//        }
//    }
//
//    // MARK: - Equatable 实现（深度优化）
//
//    static func == (lhs: TDTaskRowView, rhs: TDTaskRowView) -> Bool {
//        // 深度优化：只比较真正影响渲染的关键属性，按重要性排序
//        guard lhs.task.taskId == rhs.task.taskId else { return false }
//        guard lhs.task.complete == rhs.task.complete else { return false }
//        guard lhs.task.taskContent == rhs.task.taskContent else { return false }
//        guard lhs.task.isSubOpen == rhs.task.isSubOpen else { return false }
//        guard lhs.isHovered == rhs.isHovered else { return false }
//        guard lhs.isSelected == rhs.isSelected else { return false }
//        guard lhs.isMultiSelectMode == rhs.isMultiSelectMode else { return false }
//
//        // 只在必要时比较复杂属性
//        if lhs.task.taskDescribe != rhs.task.taskDescribe { return false }
//        if lhs.task.subTaskList != rhs.task.subTaskList { return false }
//
//        return true
//    }
//}
//
//#Preview {
//    let testTask = TDMacSwiftDataListModel(
//        id: 1,
//        taskId: "test",
//        taskContent: "这是一个测试任务，内容比较长，用来测试多行显示效果",
//        taskDescribe: "这是任务的详细描述，用来测试描述显示功能",
//        complete: false,
//        createTime: Date.currentTimestamp,
//        delete: false,
//        reminderTime: Date.currentTimestamp,
//        snowAdd: 0,
//        snowAssess: 7,
//        standbyInt1: 0,
//        standbyStr1: "每天",
//        standbyStr2: "[{\"isComplete\":false,\"content\":\"子任务1\"},{\"isComplete\":true,\"content\":\"子任务2\"}]",
//        standbyStr3: nil,
//        standbyStr4: "[{\"downloading\":false,\"name\":\"附件1.pdf\",\"size\":\"1.2MB\",\"suffix\":\"pdf\",\"url\":\"http://example.com\"}]",
//        syncTime: Date.currentTimestamp,
//        taskSort: 1000,
//        todoTime: Date.currentTimestamp,
//        userId: 1,
//        version: 1
//    )
//
//    // 设置子任务和附件列表
//    testTask.subTaskList = [
//        TDMacSwiftDataListModel.SubTask(isComplete: false, content: "子任务1"),
//        TDMacSwiftDataListModel.SubTask(isComplete: true, content: "子任务2")
//    ]
//
//    testTask.attachmentList = [
//        TDMacSwiftDataListModel.Attachment(
//            downloading: false,
//            name: "附件1.pdf",
//            size: "1.2MB",
//            suffix: "pdf",
//            url: "http://example.com"
//        )
//    ]
//
//    return TDTaskRowView(task: testTask, category: nil, orderNumber: nil, isFirstRow: true, isLastRow: true)
//        .environmentObject(TDThemeManager.shared)
//}
