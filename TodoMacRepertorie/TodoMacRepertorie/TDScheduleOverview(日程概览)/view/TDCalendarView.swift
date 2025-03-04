//
//  TDCalendarView.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/3/4.
//

import SwiftUI

struct TDCalendarView: View {
    @StateObject private var calendarManager = TDCalendarManager.shared
    @StateObject private var settingManager = TDSettingManager.shared
    
    private let weekDaySymbols = Calendar.current.veryShortWeekdaySymbols
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 顶部导航栏
            TDCalendarHeaderView()
            
            // 2. 日历主体
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // 周标题栏
                    weekdayHeader
                    
                    // 日历网格
                    calendarGrid(cellWidth: geometry.size.width / 7)
                }
                .onAppear {
                    calendarManager.updateViewHeight(geometry.size.height)
                    Task {
                        await calendarManager.updateCalendarData()
                    }
                }
                .onChange(of: geometry.size.height) { newHeight in
                    calendarManager.updateViewHeight(newHeight)
                    Task {
                        await calendarManager.updateCalendarData()
                    }
                }
            }
        }
    }
    
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(0..<7) { index in
                let weekdayIndex = settingManager.isFirstDayMonday ?
                (index + 1) % 7 : index
                Text(weekDaySymbols[weekdayIndex])
                    .frame(maxWidth: .infinity)
                    .foregroundColor(index > 4 ? .red : .primary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func calendarGrid(cellWidth: CGFloat) -> some View {
            GeometryReader { geometry in
                let cellHeight = geometry.size.height / CGFloat(calendarManager.calendarDates.count)
                
                VStack(spacing: 0) {
                    ForEach(calendarManager.calendarDates.indices, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(calendarManager.calendarDates[row]) { date in
                                TDCalendarDayCell(
                                    model: date,
                                    cellWidth: cellWidth,
                                    cellHeight: cellHeight
                                )
                            }
                        }
                    }
                }
            }
        }
}

struct TDCalendarDayCell: View {
    let model: TDCalendarDateModel
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    @StateObject private var settingManager = TDSettingManager.shared

    // 布局常量
    private struct Layout {
        static let headerHeight: CGFloat = 40        // 日期头部高度
        static let taskHeight: CGFloat = 14          // 每个任务的固定高度
        static let taskSpacing: CGFloat = 1          // 任务之间的间距
        static let horizontalPadding: CGFloat = 1    // 水平内边距
        static let topPadding: CGFloat = 1           // 顶部内边距
    }
    
    // 计算可显示的任务数量
    private var maxTasksToShow: Int {
        let availableHeight = cellHeight - Layout.headerHeight - Layout.topPadding
        return Int(availableHeight / (Layout.taskHeight + Layout.taskSpacing))
    }
    

//    // 计算每个单元格可以显示的任务数量
//    private var maxTasksToShow: Int {
//        // 假设每个任务行高为20，标题占用30，留出底部空间10
//        let availableHeight = cellHeight - 35
//        return Int(availableHeight / 13)
//    }
//    // 计算每行任务的最大字符数（假设每个中文字符宽度为15pt，英文字符为8pt）
//    private var maxCharsPerLine: Int {
//        // 减去左右padding和一些边距
//        let availableWidth = cellWidth - 2
//        // 假设平均字符宽度为12pt
//        return Int(availableWidth / 12)
//    }
//    
//    private func truncateText(_ text: String) -> String {
//        if text.count <= maxCharsPerLine {
//            return text
//        }
//        return String(text.prefix(maxCharsPerLine))
//    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 顶部日期信息
            HStack(alignment: .center, spacing: 4) {
                // 阳历日期
                Text("\(Calendar.current.component(.day, from: model.date))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(cellTextColor)
                
                // 农历日期
                Text(model.lunarDate)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 调休标记
                if model.isWorkday {
                    Text("班")
                        .font(.system(size: 10))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(2)
                }
            }
            .frame(height: Layout.headerHeight)
            .padding(.horizontal, Layout.horizontalPadding)
            
            // 2. 任务列表
            VStack(spacing: Layout.taskSpacing) {
                let tasksToShow = model.tasks.prefix(maxTasksToShow - 1)
                let remainingCount = model.tasks.count - (maxTasksToShow - 1)
                
                ForEach(Array(tasksToShow.enumerated()), id: \.element.id) { index, task in
                    TaskRowView(
                        task: task,
                        settingManager: settingManager,
                        width: cellWidth - (Layout.horizontalPadding * 2)
                    )
                    .frame(height: Layout.taskHeight)
                }
                
                // 显示剩余任务数量或最后一个任务
                if remainingCount > 0 {
                    if settingManager.calendarShowRemainingCount {
                        HStack {
                            Text("+\(remainingCount)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(height: Layout.taskHeight)
                        .padding(.horizontal, Layout.horizontalPadding)
                    } else if let lastTask = model.tasks[safe: maxTasksToShow - 1] {
                        TaskRowView(
                            task: lastTask,
                            settingManager: settingManager,
                            width: cellWidth - (Layout.horizontalPadding * 2)
                        )
                        .frame(height: Layout.taskHeight)
                    }
                }
                
                // 填充剩余空间
                Spacer()
            }
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .frame(width: cellWidth, height: cellHeight)
        .background(cellBackground)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
    
    
    private var cellTextColor: Color {
        if !model.isCurrentMonth {
            return .secondary
        }
        if model.isToday {
            return .white
        }
        if model.isHoliday {
            return .red
        }
        return .primary
    }
    
    private var cellBackground: Color {
        if model.isToday {
            return .blue.opacity(0.8)
        }
        if !model.isCurrentMonth {
            return Color(.windowBackgroundColor)
        }
        return .clear
    }
}

struct TDCalendarHeaderView: View {
    @State private var inputText = ""
    @StateObject private var calendarManager = TDCalendarManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // 1. 左侧输入框
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                
                TextField("在此编辑内容，按回车创建事件", text: $inputText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                Image(systemName: "plus")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
            }
            .padding(8)
            .background(Color(.textBackgroundColor))
            .cornerRadius(6)
            
            // 2. 排序按钮
            Button(action: {}) {
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundColor(.gray)
            }
            
            // 月份导航
            HStack(spacing: 16) {
                // 上个月按钮
                Button(action: {
                    previousMonth()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                }
                
                // 当前月份显示
                Text(monthYearString(from: calendarManager.selectedDate))
                    .font(.system(size: 14))
                
                // 下个月按钮
                Button(action: {
                    nextMonth()
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            
            // 4. 搜索框
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("搜索事件", text: .constant(""))
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(6)
            .frame(width: 150)
            .background(Color(.textBackgroundColor))
            .cornerRadius(6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    // 获取月份年份字符串
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: date)
    }
    
    // 上个月
    private func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: calendarManager.selectedDate) {
            Task {
                // 更新选中日期
                await MainActor.run {
                    calendarManager.selectedDate = newDate
                }
                // 重新加载日历数据
                await calendarManager.updateCalendarData()
            }
        }
    }
    
    // 下个月
    private func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: calendarManager.selectedDate) {
            Task {
                // 更新选中日期
                await MainActor.run {
                    calendarManager.selectedDate = newDate
                }
                // 重新加载日历数据
                await calendarManager.updateCalendarData()
            }
        }
    }

}

@MainActor

struct TaskRowView: View {
    let task: TDMacSwiftDataListModel
    let settingManager: TDSettingManager
    let width: CGFloat
    
    var body: some View {
        let style = settingManager.getTaskStyle(for: task)
        HStack {
            Text(truncateText(task.taskContent))
                .font(.system(size: 12))
                .lineLimit(1)
                .foregroundColor(style.textColor)
                .strikethrough(task.complete)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(style.backgroundColor)
    }
    
    // 计算每行任务的最大字符数（假设每个中文字符宽度为15pt，英文字符为8pt）
    private var maxCharsPerLine: Int {
        // 减去左右padding和一些边距
        let availableWidth = width - 4
        // 假设平均字符宽度为12pt
        return Int(availableWidth / 13)
    }
    
    private func truncateText(_ text: String) -> String {
        if text.count <= maxCharsPerLine {
            return text
        }
        return String(text.prefix(maxCharsPerLine))
    }
}

//struct TaskRowView: View {
//    let task: TDMacSwiftDataListModel
//    let settingManager: TDSettingManager
//    let cellWidth: CGFloat
//    
//    var body: some View {
//        let style = settingManager.getTaskStyle(for: task)
//        Text(truncateText(task.taskContent))
//            .font(.system(size: 12))
//            .lineLimit(1)
//            .foregroundColor(style.textColor)
//            .strikethrough(task.complete) // 已完成任务添加删除线
//            .padding(.horizontal, 1)
//            .background(style.backgroundColor)
//    }
//    
//    // 根据单元格宽度截取文字
////    private func truncateText(_ text: String) -> String {
////        let maxChars = Int(cellWidth / 10) - 2 // 假设每个字符平均12pt宽，减去padding
////        if text.count <= maxChars {
////            return text
////        }
////        return String(text.prefix(maxChars))
////    }
//    
//    // 计算每行任务的最大字符数（假设每个中文字符宽度为15pt，英文字符为8pt）
//    private var maxCharsPerLine: Int {
//        // 减去左右padding和一些边距
//        let availableWidth = cellWidth - 2
//        // 假设平均字符宽度为12pt
//        return Int(availableWidth / 11)
//    }
//    
//    private func truncateText(_ text: String) -> String {
//        if text.count <= maxCharsPerLine {
//            return text
//        }
//        return String(text.prefix(maxCharsPerLine))
//    }
//}

// 安全数组访问扩展
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
#Preview {
    TDCalendarView()
}
