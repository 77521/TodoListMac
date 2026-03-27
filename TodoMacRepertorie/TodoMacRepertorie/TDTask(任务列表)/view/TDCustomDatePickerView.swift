//
//  TDCustomDatePickerView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/21.
//

import SwiftUI

/// 自定义日期选择器视图（弹窗）
/// - 目标：与“日程概览-月视图”的日期显示逻辑一致（周一开始 + 农历/节气 smartDisplay）
/// - 注意：这里只展示日期，不展示事件数据
struct TDCustomDatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let onDateSelected: (Date) -> Void
    
    @StateObject private var themeManager = TDThemeManager.shared
    @ObservedObject private var settingManager = TDSettingManager.shared
    @StateObject private var holidayManager = TDHolidayManager.shared
    
    @State private var displayMonth: Date
    
    // 预计算后的网格数据：避免在 SwiftUI 重绘里反复做“农历/节假日”重计算导致 CPU 飙升
    @State private var gridCells: [GridCell] = []
    @State private var gridWeekCount: Int = 6
    @State private var rebuildToken: Int = 0
    @State private var rebuildTask: Task<Void, Never>?
    
    // 农历信息缓存：key=当天 startOfDayTimestamp
    @State private var lunarCache: [Int64: LunarInfo] = [:]
    
    private let calendar: Calendar = Calendar(identifier: .gregorian)
    
    // 视觉间距：日期格子间距再缩小一半
    private var gridSpacing: CGFloat { 2 }
    private var contentHorizontalPadding: CGFloat { 2 }
    
    // 日期圆形的直径（阳历+农历一体放入圆形里）
    private var dateCircleDiameter: CGFloat { 36 }
    
    private var gridWidth: CGFloat {
        (dateCircleDiameter * 7) + (gridSpacing * 6)
    }
    
    private var calendarColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(dateCircleDiameter), spacing: gridSpacing, alignment: .center), count: 7)
    }
    
    init(selectedDate: Binding<Date>, isPresented: Binding<Bool>, onDateSelected: @escaping (Date) -> Void) {
        self._selectedDate = selectedDate
        self._isPresented = isPresented
        self.onDateSelected = onDateSelected
        self._displayMonth = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.top, 10)
                .padding(.bottom, 6)
            
            weekdayHeader
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.bottom, 6)
            
            monthGrid(cells: gridCells)
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.bottom, 10)
        }
        .frame(width: preferredWidth, height: preferredHeight(weekCount: gridWeekCount))
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onAppear {
            // 每次弹出时，让展示月份与当前选中日期保持一致
            if !calendar.isDate(selectedDate, equalTo: displayMonth, toGranularity: .month) {
                displayMonth = selectedDate
            }
            scheduleRebuildGrid()
        }
        .onChange(of: selectedDate) { _, newValue in
            // 外部改变选中日期时，自动跳转到对应月份（避免“标题月份不一致”）
            if !calendar.isDate(newValue, equalTo: displayMonth, toGranularity: .month) {
                displayMonth = newValue
            }
        }
        .onChange(of: displayMonth) { _, _ in
            scheduleRebuildGrid()
        }
        .onChange(of: settingManager.isFirstDayMonday) { _, _ in
            scheduleRebuildGrid()
        }
        .onChange(of: holidayManager.holidayList.count) { _, _ in
            // 节假日数据更新时，重建角标
            scheduleRebuildGrid()
        }
    }
    
    // MARK: - Top bar
    
    private var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Button(action: previousYear) {
                    Text("<<")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.titleTextColor)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                
                Button(action: previousMonth) {
                    Text("<")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.titleTextColor)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }
            
            Spacer(minLength: 0)
            
            Text(monthYearString(from: displayMonth))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.titleTextColor)
                .frame(minWidth: 96, alignment: .center)
            
            Spacer(minLength: 0)
            
            HStack(spacing: 6) {
                Button(action: nextMonth) {
                    Text(">")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.titleTextColor)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                
                Button(action: nextYear) {
                    Text(">>")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.titleTextColor)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }
        }
    }
    
    private var weekdayHeader: some View {
        let labels = settingManager.isFirstDayMonday
            ? ["一", "二", "三", "四", "五", "六", "日"]
            : ["日", "一", "二", "三", "四", "五", "六"]
        
        // 用与日期网格完全一致的 7 列布局，保证“周几”与下方日期严格中心对齐
        return LazyVGrid(columns: calendarColumns, spacing: gridSpacing) {
            ForEach(labels, id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeManager.descriptionTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    // MARK: - Grid
    
    private func monthGrid(cells: [GridCell]) -> some View {
        return LazyVGrid(columns: calendarColumns, spacing: gridSpacing) {
            ForEach(cells) { cell in
                dateCell(cell: cell)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func dateCell(cell: GridCell) -> some View {
        let date = cell.date
        let isCurrentMonth = cell.isCurrentMonth
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = date.isToday

        // 颜色规则（按你最新要求）：
        // - 非当月：阳历/农历都用 descriptionTextColor
        // - 当月未选中：阳历 titleTextColor，农历 descriptionTextColor
        // - 选中：都白色（背景主题 5）
        // - 今天（未选中）：都主题 6（背景主题 3）
        let solarColor: Color = {
            if isSelected { return .white }
            if isToday { return themeManager.color(level: 6) }
            if !isCurrentMonth { return themeManager.descriptionTextColor }
            return themeManager.titleTextColor
        }()
        let lunarColor: Color = {
            if isSelected { return .white }
            if isToday { return themeManager.color(level: 6) }
            if !isCurrentMonth { return themeManager.descriptionTextColor }
            return themeManager.descriptionTextColor
        }()
        let circleBackgroundColor: Color = {
            if isSelected { return themeManager.color(level: 5) }
            if isToday { return themeManager.color(level: 3) }
            return .clear
        }()
        
        let holidayBadge = cell.holidayBadge
        
        return Button {
            // 点击“上/下月补齐日期”时，也允许直接选中并回调
            selectedDate = date
            onDateSelected(date)
            isPresented = false
        } label: {
            VStack(spacing: 1) {
                // 阳历 + 农历一体化布局：
                // - 间距 1pt（你要 1~2pt）
                // - 选中/今天时：圆形背景包住两行
                // 这里“肯定显示农历”，不跟设置走
                VStack(spacing: 1) {
                    // 角标要挂在“阳历文字”的右上角（不是整个日期格子的右上角）
                    Text("\(cell.day)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(solarColor)
                        .overlay(alignment: .topTrailing) {
                            if let badge = holidayBadge {
                                ZStack {
                                    Circle()
                                        .fill(badge.isHoliday ? themeManager.color(level: 5) : themeManager.color(level: 2))
                                    Text(badge.text)
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(badge.isHoliday ? .white : themeManager.color(level: 7))
                                }
                                .frame(width: 14, height: 14)
                                .offset(x: 10, y: -10)
                                .allowsHitTesting(false)
                            }
                        }
                    
                    Text(cell.lunarText)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(lunarColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .frame(width: dateCircleDiameter, height: dateCircleDiameter, alignment: .center)
                .background(
                    Circle()
                        .fill(circleBackgroundColor)
                )
                .frame(maxWidth: .infinity)
            }
            .frame(height: cellHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
    }
    
    // MARK: - Layout metrics
    
    private var preferredWidth: CGFloat {
        // 用“固定列宽 + spacing + padding”决定实际宽度，spacing 才会肉眼可见地变化
        gridWidth + contentHorizontalPadding * 2
    }
    
    private var cellHeight: CGFloat {
        44
    }
    
    private func preferredHeight(weekCount: Int) -> CGFloat {
        // 顶部栏 + 星期栏 + 网格 + padding
        let top: CGFloat = 40
        let weekday: CGFloat = 22
        let grid = CGFloat(weekCount) * cellHeight + CGFloat(max(0, weekCount - 1)) * gridSpacing
        let paddingBottom: CGFloat = 10
        return top + weekday + grid + paddingBottom
    }
    
    private struct MonthMetrics {
        let dates: [Date]      // weekCount * 7
        let weekCount: Int     // 5 or 6（极少数月份可能 4）
    }
    
    private func metricsForCurrentMonth() -> MonthMetrics {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth)) ?? displayMonth
        let daysCount = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) // 1=Sun...7=Sat
        
        let offsetDays: Int = {
            if settingManager.isFirstDayMonday {
                return (firstWeekday + 5) % 7
            } else {
                return firstWeekday - 1
            }
        }()
        
        let totalCells = offsetDays + daysCount
        let weekCount = Int(ceil(Double(totalCells) / 7.0))
        let gridStart = calendar.date(byAdding: .day, value: -offsetDays, to: startOfMonth) ?? startOfMonth
        
        var result: [Date] = []
        result.reserveCapacity(weekCount * 7)
        for i in 0..<(weekCount * 7) {
            if let d = calendar.date(byAdding: .day, value: i, to: gridStart) {
                result.append(d)
            }
        }
        return MonthMetrics(dates: result, weekCount: weekCount)
    }
    
    // MARK: - Precompute grid (performance)
    
    private struct HolidayBadge: Equatable {
        let text: String
        let isHoliday: Bool
    }
    
    private struct LunarInfo: Equatable {
        let smart: String
        let lunarMonthDisplay: String
    }
    
    private struct GridCell: Identifiable, Equatable {
        let id: Int64
        let date: Date
        let day: Int
        let isCurrentMonth: Bool
        let lunarText: String
        let holidayBadge: HolidayBadge?
    }
    
    // 系统农历（轻量）用于“先出 UI，再慢慢补齐节气/节日 smartDisplay”
    // 说明：这里不依赖 LunarSwift，避免切月时一次性算 35~42 次导致 CPU 峰值过高。
    private static let lunarMonthNames = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
    private static let lunarDayNames = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]
    
    private static func systemLunarMonthDisplay(for date: Date) -> String {
        let chineseCalendar = Calendar(identifier: .chinese)
        let comps = chineseCalendar.dateComponents([.month, .day, .isLeapMonth], from: date)
        let month = comps.month ?? 1
        let day = comps.day ?? 1
        
        let isLeap = comps.isLeapMonth ?? false
        let monthName = Self.lunarMonthNames[max(0, min(11, month - 1))]
        
        if day == 1 {
            return (isLeap ? "闰" : "") + monthName + "月"
        }
        
        return Self.lunarDayNames[max(0, min(29, day - 1))]
    }
    
    private func scheduleRebuildGrid() {
        rebuildTask?.cancel()
        rebuildToken += 1
        let token = rebuildToken
        
        let month = displayMonth
        let firstDayMonday = settingManager.isFirstDayMonday
        let cached = lunarCache
        let holidays = holidayManager.getHolidayList()
        
        // 先用“系统农历”快速构建网格，避免切月时 CPU 瞬间拉满；
        // 然后再在后台用 LunarSwift 只补齐“当月日期”的节气/节日 smartDisplay（有缓存则不算）。
        rebuildTask = Task.detached(priority: .userInitiated) { [calendar] in
            if Task.isCancelled { return }
            
            // 1) 计算网格日期范围（5/6 行）
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
            let daysCount = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30
            let firstWeekday = calendar.component(.weekday, from: startOfMonth) // 1=Sun...7=Sat
            
            let offsetDays: Int = firstDayMonday ? ((firstWeekday + 5) % 7) : (firstWeekday - 1)
            let totalCells = offsetDays + daysCount
            let weekCount = Int(ceil(Double(totalCells) / 7.0))
            let gridStart = calendar.date(byAdding: .day, value: -offsetDays, to: startOfMonth) ?? startOfMonth
            
            // 2) 节假日 map（O(1) 查询）
            var holidayByDate: [Int64: Bool] = [:]
            holidayByDate.reserveCapacity(holidays.count)
            for h in holidays {
                holidayByDate[h.date] = h.holiday
            }
            
            // 3) 先构建 cells（农历用系统轻量显示；节气/节日后续再补）
            var cells: [GridCell] = []
            cells.reserveCapacity(weekCount * 7)
            
            for i in 0..<(weekCount * 7) {
                if Task.isCancelled { return }
                guard let date = calendar.date(byAdding: .day, value: i, to: gridStart) else { continue }
                let id = date.startOfDayTimestamp
                
                let isCurrentMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)
                let day = calendar.component(.day, from: date)
                let lunarText: String = Self.systemLunarMonthDisplay(for: date)
                
                let holidayBadge: HolidayBadge? = {
                    guard let isHoliday = holidayByDate[id] else { return nil }
                    return HolidayBadge(text: isHoliday ? "休" : "班", isHoliday: isHoliday)
                }()
                
                cells.append(
                    GridCell(
                        id: id,
                        date: date,
                        day: day,
                        isCurrentMonth: isCurrentMonth,
                        lunarText: lunarText,
                        holidayBadge: holidayBadge
                    )
                )
            }
            
            if Task.isCancelled { return }
            
            await MainActor.run {
                // 防止“快速连点切月/切年”时旧任务覆盖新结果
                guard self.rebuildToken == token else { return }
                
                self.gridWeekCount = weekCount
                self.gridCells = cells
            }
            
            // 4) 后台补齐：只对“当月日期”做 LunarSwift smartDisplay（有缓存则不再计算）
            var updated = cells
            var newCache: [Int64: LunarInfo] = [:]
            newCache.reserveCapacity(31)
            
            // 小节流：避免一次性把 CPU 打满（依然会算，但会更平滑）
            var computedCount = 0
            
            for idx in updated.indices {
                if Task.isCancelled { return }
                guard updated[idx].isCurrentMonth else { continue }
                
                let date = updated[idx].date
                let id = updated[idx].id
                
                let info: LunarInfo
                if let cachedInfo = cached[id] {
                    info = cachedInfo
                } else if let cachedInfo = newCache[id] {
                    info = cachedInfo
                } else {
                    let (smart, lunarMonthDisplay) = TDLunarCalendar.getSmartDisplayAndLunarMonthDisplay(for: date)
                    let computed = LunarInfo(smart: smart, lunarMonthDisplay: lunarMonthDisplay)
                    newCache[id] = computed
                    info = computed
                    
                    computedCount += 1
                    if computedCount % 6 == 0 {
                        // 每 6 个日期让出一下时间片，降低瞬时峰值
                        try? await Task.sleep(nanoseconds: 1_200_000) // 1.2ms
                    }
                }
                
                let smartText = info.smart.count > 4 ? info.lunarMonthDisplay : info.smart
                if smartText != updated[idx].lunarText {
                    updated[idx] = GridCell(
                        id: updated[idx].id,
                        date: updated[idx].date,
                        day: updated[idx].day,
                        isCurrentMonth: updated[idx].isCurrentMonth,
                        lunarText: smartText,
                        holidayBadge: updated[idx].holidayBadge
                    )
                }
            }
            
            if Task.isCancelled { return }
            
            await MainActor.run {
                guard self.rebuildToken == token else { return }
                
                if !newCache.isEmpty {
                    for (k, v) in newCache {
                        self.lunarCache[k] = v
                    }
                }
                
                self.gridCells = updated
            }
        }
    }
    
    // MARK: - Date formatting & navigation
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: displayMonth) {
            displayMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: displayMonth) {
            displayMonth = newDate
        }
    }
    
    private func previousYear() {
        if let newDate = calendar.date(byAdding: .year, value: -1, to: displayMonth) {
            displayMonth = newDate
        }
    }
    
    private func nextYear() {
        if let newDate = calendar.date(byAdding: .year, value: 1, to: displayMonth) {
            displayMonth = newDate
        }
    }
}
//#Preview {
//    TDCustomDatePickerView(selectedDate: <#Binding<Date>#>, isPresented: <#Binding<Bool>#>, onDateSelected: <#(Date) -> Void#>)
//}
