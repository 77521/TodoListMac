//
//  TDCalendarGridView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/10.
//

import SwiftUI
import SwiftData

/// 日历网格视图 - 显示所有日期单元格
struct TDCalendarGridView: View {
    /// 主题管理器
    @EnvironmentObject private var themeManager: TDThemeManager
    
    /// 设置管理器
    @EnvironmentObject private var settingManager: TDSettingManager
    
    /// 日历管理器
    @StateObject private var calendarManager = TDCalendarManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            let cellHeight = geometry.size.height / CGFloat(calendarManager.calendarDates.count)
            
            VStack(spacing: 0) {
                ForEach(Array(calendarManager.calendarDates.enumerated()), id: \.offset) { weekIndex, week in
                    HStack(spacing: 0) {
                        ForEach(week) { dateModel in
                            TDCalendarDayCell(
                                dateModel: dateModel,
//                                cellWidth: 0, // 使用0让单元格自动填充宽度
                                cellWidth: geometry.size.width / 7,
                                cellHeight: cellHeight
                            )
                        }
                    }
                }
            }
            .onAppear {
                calendarManager.updateViewHeight(geometry.size.height)
            }
            .onChange(of: geometry.size.height) { oldValue, newValue in
                calendarManager.updateViewHeight(newValue)
            }
        }
    }
}

// MARK: - 日历日期单元格
/// 日历日期单元格 - 显示单个日期的所有信息
struct TDCalendarDayCell: View {
    /// 主题管理器
    @EnvironmentObject private var themeManager: TDThemeManager
    /// 设置管理器
    @EnvironmentObject private var settingManager: TDSettingManager

    /// 日历管理器
    @StateObject private var calendarManager = TDCalendarManager.shared
    /// 日程概览视图模型
    @EnvironmentObject private var viewModel: TDScheduleOverviewViewModel

    /// 使用 @Query 来实时监控任务数据
    @Query private var allTasks: [TDMacSwiftDataListModel]
    
    /// 当前日期的任务列表
    private var currentDateTasks: [TDMacSwiftDataListModel] {
        let tasks = allTasks
        
        // 应用标签筛选（仅当标签筛选值不为空时）
        if viewModel.tagFilter.isEmpty {
            // 没有标签筛选，直接返回原始任务列表
            print("📅 \(dateModel.date.formattedString) 任务数量: \(tasks.count) (无标签筛选)")
            return tasks
        } else {
            // 有标签筛选，进行筛选
            let filteredTasks = TDCorrectQueryBuilder.filterTasksByTag(tasks, tagFilter: viewModel.tagFilter)
            print("📅 \(dateModel.date.formattedString) 任务数量: \(filteredTasks.count) (标签筛选: \(viewModel.tagFilter))")
            return filteredTasks
        }
    }


    /// 日期模型
    let dateModel: TDCalendarDateModel
    
    /// 单元格宽度
    let cellWidth: CGFloat
    
    /// 单元格高度
    let cellHeight: CGFloat
    
//    /// 计算每行任务的最大字符数（根据设置内的字体大小动态计算）
//        private func maxCharsPerLine(geometry: GeometryProxy) -> Int {
//            // 使用GeometryReader的实际宽度
//            let actualWidth = geometry.size.width
//            // 减去左右间距（各1pt）
//            let availableWidth = actualWidth - 2
//            // 根据字体大小计算字符宽度
//            let fontSize = settingManager.fontSize.size
//            // 中文字符宽度约为字体大小的1.0倍，英文字符约为字体大小的0.6倍，取平均值
//            let avgCharWidth = fontSize * 0.8 // 平均字符宽度
//            let maxChars = Int(availableWidth / avgCharWidth)
//            
//            // 打印调试信息
//            print("📏 字符长度计算:")
//            print("  - 实际宽度: \(actualWidth)")
//            print("  - 可用宽度: \(availableWidth)")
//            print("  - 字体大小: \(fontSize)")
//            print("  - 平均字符宽度: \(avgCharWidth)")
//            print("  - 最大字符数: \(maxChars)")
//            
//            return maxChars
//        }
//        
//        /// 截断文本 - 根据隐私保护模式处理
//        /// - Parameters:
//        ///   - text: 原始文本
//        ///   - geometry: 几何信息
//        /// - Returns: 处理后的文本
//        private func truncateText(_ text: String, geometry: GeometryProxy) -> String {
//            let maxChars = maxCharsPerLine(geometry: geometry)
//            if settingManager.isPrivacyModeEnabled {
//                // 隐私保护模式：显示第一个字符，其余用*号
//                if text.count <= 1 {
//                    return text
//                } else {
//                    let firstChar = String(text.prefix(1))
//                    // 确保至少显示一个字符，其余用*号填充到最大字符数
//                    let remainingChars = max(1, maxChars - 1) // 至少保留1个字符位置
//                    let asterisks = String(repeating: "*", count: min(text.count - 1, remainingChars))
//                    return firstChar + asterisks
//                }
//            } else {
//                // 正常模式：根据长度截断
//                if text.count <= maxChars {
//                    return text
//                }
//                return String(text.prefix(maxChars))
//            }
//        }
    /// 初始化方法 - 根据日期和筛选条件设置查询条件
    init(dateModel: TDCalendarDateModel, cellWidth: CGFloat, cellHeight: CGFloat) {
        self.dateModel = dateModel
        self.cellWidth = cellWidth
        self.cellHeight = cellHeight
        
        // 获取筛选条件
        let viewModel = TDScheduleOverviewViewModel.shared
        let dateTimestamp = dateModel.date.startOfDayTimestamp
        let categoryId = viewModel.selectedCategory?.categoryId ?? 0
        
        // 使用新的查询方法
        let (predicate, sortDescriptors) = TDCorrectQueryBuilder.getLocalDataQuery(
            dateTimestamp: dateTimestamp,
            categoryId: categoryId,
            sortType: viewModel.sortType
        )
        _allTasks = Query(filter: predicate, sort: sortDescriptors)
    }

    
    var body: some View {
        GeometryReader { geometry in
            
            ZStack {
                // 主要内容区域
                VStack(alignment: .leading, spacing: 2) {
                    // 日期和农历信息 - 水平居中对齐
                    HStack {
                        // 左侧：阳历和农历
                        HStack(alignment: .center,spacing: 4) {
                            // 阳历日期
                            Text("\(dateModel.date.day)")
                                .font(.system(size: 12))
                                .foregroundColor(dateModel.isCurrentMonth ? themeManager.titleTextColor : themeManager.descriptionTextColor)
                            
                            // 农历日期（根据设置决定是否显示）
                            if settingManager.showLunarCalendar {
                                Text(dateModel.smartDisplay)
                                    .font(.system(size: 10))
                                    .foregroundColor(themeManager.descriptionTextColor)
                            }
                        }
                        
                        Spacer()
                        
                        // 右侧：调休/上班状态
                        if dateModel.isInHolidayData {
                            Text(dateModel.isHoliday ? "休" : "班")
                                .font(.system(size: 9))
                                .foregroundColor(dateModel.isHoliday ? .white : themeManager.color(level: 7))
                                .padding(.all, 2)
                                .background(
                                    Circle()
                                        .fill(dateModel.isHoliday ? themeManager.color(level: 5) : themeManager.color(level: 2))
                                )
                        }
                    }
                    
                    // 任务列表 - 根据高度动态显示任务数量
                    if !currentDateTasks.isEmpty {
                        TDCalendarTaskList(
                            tasks: currentDateTasks,
                            cellWidth: geometry.size.width,
                            cellHeight: cellHeight,
                            maxTasks: calculateMaxTasks()
                        )

                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: cellHeight)
            .background(
                Rectangle()
                    .fill(dateModel.isToday ? themeManager.color(level: 1).opacity(0.3) : Color.clear)
            )
            
            .overlay(
                // 添加网格分割线
                Rectangle()
                    .stroke(themeManager.separatorColor, lineWidth: 1)
            )
            .overlay(
                Rectangle()
                    .stroke(dateModel.isSelected ? themeManager.color(level: 5) : Color.clear, lineWidth: 1)
                    .padding(.all,1)
            )
            .contentShape(Rectangle()) // 让整个单元格区域都可以点击
            .onTapGesture {
                // TODO: 处理日期点击事件
                // 选择当前日期
//                calendarManager.selectDate(dateModel.date)
                // 只更新选中状态，不重新查询数据，不切换月份
                viewModel.selectDateOnly(dateModel.date)

                print("点击日期为：\(dateModel.date.formattedString)")
            }
        }
    
        
        // MARK: - 任务列表
        /// 任务列表 - 根据单元格高度动态显示任务数量
//        private var taskList: some View {
//            VStack(alignment: .leading, spacing: 1) {
//                // 根据高度计算可显示的任务数量
//                let maxTasks = calculateMaxTasks(geometry: geometry)
//
//                // 根据设置决定显示逻辑
//                if settingManager.calendarShowRemainingCount && currentDateTasks.count > maxTasks {
//                    // 显示剩余数量：显示前(maxTasks-1)个任务 + 剩余数量提示
//                    let displayTasks = min(maxTasks - 1, currentDateTasks.count)
//                    let remainingCount = currentDateTasks.count - displayTasks - 1
//                    
//                    // 显示任务
//                    ForEach(Array(currentDateTasks.prefix(displayTasks).enumerated()), id: \.offset) { index, task in
//                        Text(truncateText(task.taskContent, geometry: geometry))
//                        //                    Text(task.taskContent)
//                            .font(.system(size: settingManager.fontSize.size))
//                            .foregroundColor(task.complete ? themeManager.descriptionTextColor : themeManager.titleTextColor)
//                            .strikethrough(task.complete)
//                            .lineLimit(1)
//                            .onTapGesture {
//                                print("点击了任务: \(task.taskContent)")
//                            }
//                    }
//                    
//                    // 显示剩余数量
//                    if remainingCount > 0 {
//                        Text("+\(remainingCount)")
//                            .font(.system(size: settingManager.fontSize.size))
//                            .foregroundColor(themeManager.color(level: 5))
//                    }
//                } else {
//                    // 不显示剩余数量：显示所有可显示的任务
//                    ForEach(Array(currentDateTasks.prefix(maxTasks).enumerated()), id: \.offset) { index, task in
//                        Text(truncateText(task.taskContent, geometry: geometry))
//                        //                    Text(task.taskContent)
//                            .font(.system(size: settingManager.fontSize.size))
//                            .foregroundColor(task.complete ? themeManager.descriptionTextColor : themeManager.titleTextColor)
//                            .strikethrough(task.complete)
//                            .lineLimit(1)
//                            .onTapGesture {
//                                print("点击了任务: \(task.taskContent)")
//                            }
//                    }
//                }
//            }
//        }
    }
    /// 根据单元格高度计算可显示的最大任务数量
    /// - Returns: 可显示的任务数量
    private func calculateMaxTasks() -> Int {
        // 基础高度：阳历文字高度(12) + VStack间距(2) + 水平内边距(4*2=8)
        let baseHeight: CGFloat = 14 + 2 + 8 // 22pt
        let availableHeight = cellHeight - baseHeight
        
        // 每个任务行的高度（根据字体大小动态计算，包括上下间距1pt）
        let fontSize = settingManager.fontSize.size
        let taskRowHeight = fontSize + 3 // 字体高度 + 上下间距
        
        // 计算可显示的任务数量（根据实际高度能显示多少就显示多少）
        let maxTasks = max(0, Int(availableHeight / taskRowHeight))
        
        return maxTasks
    }
    
}

// MARK: - 预览
#Preview {
    TDCalendarGridView()
        .environmentObject(TDThemeManager.shared)
        .environmentObject(TDSettingManager.shared)
}
