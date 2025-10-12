//
//  TDCustomRepeatSettingView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/21.
//

import SwiftUI

/// 自定义重复设置弹窗视图
/// 用于设置任务的重复规则
struct TDCustomRepeatSettingView: View {
    
    // MARK: - 数据绑定
    @EnvironmentObject private var themeManager: TDThemeManager  // 主题管理器
    @Binding var isPresented: Bool  // 控制弹窗显示状态
    // MARK: - 参数
    let task: TDMacSwiftDataListModel  // 任务对象

    // MARK: - 回调闭包
    var onRepeatDatesCalculated: (([Date]) -> Void)?  // 重复日期计算完成回调

    // MARK: - 状态变量
    @State private var selectedUnit: RepeatUnit = .day  // 选中的重复单位
    @State private var repeatInterval: Int = 1  // 重复间隔（每几天）
    @State private var repeatCount: Int = 1  // 重复次数（最少1次）
    @State private var showHelpModal = false  // 控制帮助说明弹窗显示
    
    // 工作日相关选项
    @State private var isLegalWorkday = false  // 法定工作日
    @State private var skipHolidays = false  // 跳过法定节假日
    @State private var skipWeekends = false  // 跳过双休日
    
    @State private var selectedWeekdays: Set<Int> = []  // 选中的星期几（1-7，1=周日，7=周六）

    // 月选择相关
    @State private var selectedDays: Set<Int> = []  // 选中的日期（1-31）
    @State private var includeLastDay = false  // 是否包含最后一天

    // 年选择相关
    @State private var selectedCalendarType: TDDataOperationManager.CalendarType = .gregorian  // 日历类型
    @State private var selectedMonth: Int = 1  // 选中的月份
    @State private var selectedDay: Int = 1  // 选中的日期

    // MARK: - 初始化方法
    init(isPresented: Binding<Bool>, task: TDMacSwiftDataListModel, onRepeatDatesCalculated: (([Date]) -> Void)? = nil) {
        self._isPresented = isPresented
        self.task = task
        self.onRepeatDatesCalculated = onRepeatDatesCalculated
        
        // 根据任务的todoTime设置默认选中的星期
        let taskDate = Date.fromTimestamp(task.todoTime)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: taskDate)
        // Calendar.weekday: 1=周日, 2=周一, ..., 7=周六
        // 我们的格式: 1=周日, 2=周一, ..., 7=周六
        // 所以直接使用calendar的weekday值即可
        self._selectedWeekdays = State(initialValue: [weekday])
        
        // 根据任务的todoTime设置默认选中的日期
        let day = calendar.component(.day, from: taskDate)
        self._selectedDays = State(initialValue: [day])
        
        // 根据任务的todoTime设置默认的年重复日期
        let month = calendar.component(.month, from: taskDate)
        self._selectedMonth = State(initialValue: month)
        self._selectedDay = State(initialValue: day)

    }
    

    
    // MARK: - 重复单位枚举
    enum RepeatUnit: String, CaseIterable {
        case day = "天"
        case week = "周"
        case month = "月"
        case year = "年"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    // MARK: - 主视图
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar
            
            // 分割线
            Divider()
                .background(themeManager.separatorColor)
            
            // 主要内容
            mainContent
            
            // 底部操作栏
            TDRepeatActionBar(
                onCancel: {
                    isPresented = false
                },
                onCreate: {
                    createRepeatRule()
                }
            )
            .environmentObject(themeManager)

        }
        .background(themeManager.backgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .animation(.easeInOut(duration: 0.3), value: isLegalWorkday)
        .overlay(
            // 帮助说明弹窗
            Group {
                if showHelpModal {
                    TDRepeatHelpModal(isPresented: $showHelpModal)
                        .environmentObject(themeManager)
                }
            }
        )
    }
    
    // MARK: - 子视图
    
    /// 标题栏
    private var titleBar: some View {
        HStack {
            // 标题和问号图标按钮
            Button(action: {
                showHelpModal = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "repeat.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.color(level: 5))
                    
                    Text("自定义重复设置")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.titleTextColor)
                    
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.descriptionTextColor)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
            .help("查看重复设置说明")
            
            Spacer()
            
            // 关闭按钮
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.descriptionTextColor)
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
            .help("关闭")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(themeManager.backgroundColor)
    }
    
    /// 主要内容
    private var mainContent: some View {
        VStack(spacing: 20) {
            // 重复间隔设置
            TDRepeatIntervalSection(
                repeatInterval: $repeatInterval,
                selectedUnit: selectedUnit,
                selectedWeekdays: selectedUnit == .week ? selectedWeekdays : nil,
                selectedDays: selectedUnit == .month ? selectedDays : nil,
                includeLastDay: selectedUnit == .month ? includeLastDay : false,
                repeatCount: repeatCount,
                selectedCalendarType: selectedUnit == .year ? selectedCalendarType : nil,
                selectedMonth: selectedUnit == .year ? selectedMonth : nil,
                selectedDay: selectedUnit == .year ? selectedDay : nil,
                taskTodoTime: task.todoTime,
                onPreviewTextChanged: {
                    // 预览文字变化时的处理
                }
            )
            .environmentObject(themeManager)

            
            // 重复单位选择
            repeatUnitSection
            
            // 特定选项（只在对应单位时显示）
            if selectedUnit == .week {
                weekSpecificOptions
            }
            else if selectedUnit == .month {
                monthSpecificOptions
            } else if selectedUnit == .year {
                yearSpecificOptions
            }
            
            // 共用选项（所有重复单位都显示）
            TDRepeatCommonOptions(
                isLegalWorkday: $isLegalWorkday,
                skipHolidays: $skipHolidays,
                skipWeekends: $skipWeekends,
                repeatCount: $repeatCount,
                onValidateRepeatCount: {
                    validateRepeatCount()
                }
            )
            .environmentObject(themeManager)

        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .animation(.easeInOut(duration: 0.3), value: isLegalWorkday)
    }
    
    /// 重复单位选择
    private var repeatUnitSection: some View {
        HStack(spacing: 8) {
            ForEach(RepeatUnit.allCases, id: \.self) { unit in
                Button(action: {
                    selectedUnit = unit
                }) {
                    Text(unit.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedUnit == unit ? .white : themeManager.titleTextColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedUnit == unit ? themeManager.color(level: 5) : themeManager.secondaryBackgroundColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedUnit == unit ? themeManager.color(level: 5) : themeManager.separatorColor, lineWidth: 1)
                        )
                }
                .pointingHandCursor()
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    /// 按周特定的选项
    private var weekSpecificOptions: some View {
        // 周选择器
        TDWeekdaySelectorView(selectedWeekdays: $selectedWeekdays, taskTodoTime: task.todoTime)
            .environmentObject(themeManager)
    }
    
    /// 按月特定的选项
    private var monthSpecificOptions: some View {
        // 月选择器
        TDMonthDaySelectorView(
            selectedDays: $selectedDays,
            includeLastDay: $includeLastDay,
            taskTodoTime: task.todoTime
        )
        .environmentObject(themeManager)
    }
    
    /// 按年特定的选项
    private var yearSpecificOptions: some View {
        TDYearDateSelectorView(
            selectedCalendarType: $selectedCalendarType,
            selectedMonth: $selectedMonth,
            selectedDay: $selectedDay,
            taskTodoTime: task.todoTime
        )
        .environmentObject(themeManager)
    }
    
    // MARK: - 私有方法
    
    /// 创建重复规则
    private func createRepeatRule() {
        print("✅ 创建重复规则: 每\(repeatInterval)\(selectedUnit.displayName)，重复\(repeatCount)次")
        
        // 打印当前设置
        print("📋 当前设置:")
        print("  - 重复间隔: \(repeatInterval)")
        print("  - 重复单位: \(selectedUnit.displayName)")
        print("  - 重复次数: \(repeatCount)")
        print("  - 法定工作日: \(isLegalWorkday)")
        print("  - 跳过法定节假日: \(skipHolidays)")
        print("  - 跳过双休日: \(skipWeekends)")
        
        // 检查节假日数据
        let holidayList = TDHolidayManager.shared.getHolidayList()
        print("📅 节假日数据状态:")
        print("  - 节假日数据总数: \(holidayList.count)")
        if holidayList.count > 0 {
            print("  - 前5个节假日:")
            for (index, holiday) in holidayList.prefix(5).enumerated() {
                let date = Date(timeIntervalSince1970: TimeInterval(holiday.date / 1000))
                print("    \(index + 1). \(holiday.name) - \(date.dateAndWeekString) (holiday: \(holiday.holiday))")
            }
        } else {
            print("  - ⚠️ 节假日数据为空，可能需要先获取节假日数据")
        }
        
        // 计算重复日期
        let repeatDates = calculateRepeatDates()
        print("📅 生成的重复日期: \(repeatDates.count)个")
        for (index, date) in repeatDates.enumerated() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd EEEE"
            let dateString = dateFormatter.string(from: date)
            let timestamp = date.startOfDayTimestamp
            print("  任务\(index + 1): \(dateString) (\(date.dateAndWeekString)) - 时间戳: \(timestamp)")
        }
//        // 通过回调将日期数组传递给上层界面
        onRepeatDatesCalculated?(repeatDates)

        // TODO: 实现创建重复规则的逻辑
        // 1. 创建重复任务
        // 2. 设置重复ID
        // 3. 保存到数据库
        
        isPresented = false
    }
    
    /// 计算重复日期
    private func calculateRepeatDates() -> [Date] {
        let baseDate = Date.fromTimestamp(task.todoTime) // 使用任务的todoTime
        var dates: [Date] = []
        
        if selectedUnit == .week {
            // 周重复：根据选择的星期计算日期
            dates = calculateWeekRepeatDates(baseDate: baseDate)
        } else if selectedUnit == .month {
            // 月重复：根据选择的日期计算日期
            dates = calculateMonthRepeatDates(baseDate: baseDate)
        } else if selectedUnit == .year {
            // 年重复：根据选择的月日计算日期
            dates = calculateYearRepeatDates(baseDate: baseDate)
        } else {
            // 其他重复单位：按原来的逻辑
            var currentDate = baseDate
            
            // 将当前事件的todoTime添加到数组的第一个位置
            dates.append(baseDate)
            
            // 计算重复的日期
            for _ in 1...repeatCount {
                // 从当前日期开始，每次增加间隔天数
                currentDate = currentDate.adding(days: repeatInterval)
                
                // 应用工作日过滤规则
                let validDate = applyWorkdayFilter(to: currentDate)
                dates.append(validDate)
                currentDate = validDate // 更新当前日期为找到的有效日期
            }
        }
        
        return dates
    }
    
    /// 计算周重复日期
    private func calculateWeekRepeatDates(baseDate: Date) -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        let baseWeekday = calendar.component(.weekday, from: baseDate)
        
        // 如果选择的星期包含当前事件的星期，则从当前事件开始
        if selectedWeekdays.contains(baseWeekday) {
            dates.append(baseDate)
        }
        
        // 计算重复的周数
        // repeatCount = 1: 需要2周（本周+下周）
        // repeatCount = 2: 需要3周（本周+下周+下下周）
        let totalWeeksNeeded = repeatCount + 1
        
        // 为每一周生成选中的星期日期
        for weekOffset in 1...totalWeeksNeeded {
            print("📅 处理第\(weekOffset)周:")
            for weekday in selectedWeekdays.sorted() {
                // 第1周：跳过当前事件的星期，因为已经包含在dates中了
                // 第2周及以后：包含所有选中的星期
                if weekOffset == 1 && weekday == baseWeekday {
                    print("  - 跳过当前事件的星期: \(weekday)")
                    continue
                }
                
                // 计算目标日期
                let targetDate = calculateWeekdayDate(
                    from: baseDate,
                    weekday: weekday,
                    weekOffset: weekOffset
                )
                
                // 检查目标日期是否符合工作日过滤规则
                if isDateValidForWorkdayFilter(targetDate) {
                    // 检查是否已经存在相同的日期，避免重复
                    if !dates.contains(where: { calendar.isDate($0, inSameDayAs: targetDate) }) {
                        dates.append(targetDate)
                        print("  - ✅ 添加日期: \(targetDate.dateAndWeekString)")
                    } else {
                        print("  - ⚠️ 跳过重复日期: \(targetDate.dateAndWeekString)")
                    }
                } else {
                    // 如果不符合过滤规则，跳过这个日期
                    print("  - ❌ 跳过无效日期: \(targetDate.dateAndWeekString)")
                    continue
                }
            }
        }
        
        // 按日期排序
        dates.sort { $0 < $1 }
        
        return dates
    }

    
    /// 计算月重复日期
    private func calculateMonthRepeatDates(baseDate: Date) -> [Date] {
        let calendar = Calendar.current
        
        // 第一步：根据每几个月和重复次数，计算所有月份的日期
        var allDates: [Date] = []
        
        // 计算重复的月数
        // repeatCount = 1: 需要2个月（本月+下月）
        // repeatCount = 2: 需要3个月（本月+下月+下下月）
        let totalMonthsNeeded = repeatCount + 1
        
        print("📅 第一步：计算所有月份的日期")
        print("  - 基准日期: \(baseDate.dateAndWeekString)")
        print("  - 重复次数: \(repeatCount)")
        print("  - 需要月份数: \(totalMonthsNeeded)")
        print("  - 每\(repeatInterval)月重复")
        print("  - 选中的日期: \(selectedDays.sorted())")
        
        for monthOffset in 0...totalMonthsNeeded {
            print("  - 处理第\(monthOffset)月:")
            
            // 计算目标月份
            let targetMonth = baseDate.adding(months: monthOffset * repeatInterval)
            let targetYear = targetMonth.year
            let targetMonthNum = targetMonth.month
            
            // 为选中的每个日期生成目标月份的日期
            for day in selectedDays.sorted() {
                // 使用Date扩展方法创建日期
                let targetDate = Date.createDate(year: targetYear, month: targetMonthNum, day: day)
                
                // 检查日期是否有效（处理2月30日、31日等不存在的情况）
                if targetDate.month == targetMonthNum && targetDate.day == day {
                    allDates.append(targetDate)
                    print("    - 📅 收集日期: \(targetDate.dateAndWeekString)")
                } else {
                    print("    - ❌ 跳过无效日期: \(targetYear)年\(targetMonthNum)月\(day)日 (该月不存在此日期)")
                }
            }
            
            // 如果选择了最后一天，计算该月的最后一天
            if includeLastDay {
                let lastDayOfMonth = getLastDayOfMonth(targetMonth)
                let lastDayDate = Date.createDate(year: targetYear, month: targetMonthNum, day: lastDayOfMonth)
                
                // 检查是否与已选择的日期重复
                let isDuplicate = selectedDays.contains { day in
                    let dayDate = Date.createDate(year: targetYear, month: targetMonthNum, day: day)
                    return calendar.isDate(dayDate, inSameDayAs: lastDayDate)
                }
                
                if !isDuplicate {
                    allDates.append(lastDayDate)
                    print("    - 📅 收集最后一天: \(lastDayDate.dateAndWeekString)")
                } else {
                    print("    - ⚠️ 跳过重复的最后一天: \(lastDayDate.dateAndWeekString)")
                }
            }
        }
        
        // 第二步：去除比当前事件todoTime小的日期
        print("📅 第二步：去除比基准日期小的日期")
        let filteredByTime = allDates.filter { date in
            let isAfterBaseDate = date.isGreaterThanOrEqual(to: baseDate)
            if !isAfterBaseDate {
                print("  - ❌ 去除过期日期: \(date.dateAndWeekString)")
            } else {
                print("  - ✅ 保留日期: \(date.dateAndWeekString)")
            }
            return isAfterBaseDate
        }
        
        // 第三步：根据条件筛选（跳过法定节假日、双休日、法定工作日）
        print("📅 第三步：应用过滤规则")
        var finalDates: [Date] = []
        for date in filteredByTime {
            let validDate = applyWorkdayFilter(to: date)
            
            // 检查是否已经存在相同的日期，避免重复
            if !finalDates.contains(where: { calendar.isDate($0, inSameDayAs: validDate) }) {
                finalDates.append(validDate)
                print("  - ✅ 最终日期: \(validDate.dateAndWeekString)")
            } else {
                print("  - ⚠️ 跳过重复日期: \(validDate.dateAndWeekString)")
            }
        }
        
        // 按日期排序
        finalDates.sort { $0 < $1 }
        
        return finalDates
    }

    
    /// 获取指定月份的最后一天
    private func getLastDayOfMonth(_ month: Date) -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: month)!
        return range.upperBound - 1
    }

    
    
    /// 计算指定星期的日期
    private func calculateWeekdayDate(from baseDate: Date, weekday: Int, weekOffset: Int) -> Date {
        let calendar = Calendar.current
        let baseWeekday = calendar.component(.weekday, from: baseDate)
        
        // weekOffset = 1: 当前周 (0天)
        // weekOffset = 2: 下周 (7天)
        // weekOffset = 3: 下下周 (14天)
        let daysToAdd = (weekday - baseWeekday + 7) % 7 + (weekOffset - 1) * 7

        let resultDate = baseDate.adding(days: daysToAdd)
                
        return resultDate
    }
    
    
    /// 计算年重复日期
    private func calculateYearRepeatDates(baseDate: Date) -> [Date] {
        let calendar = Calendar.current
        
        // 第一步：根据每几年和重复次数，计算所有年份的日期
        var allDates: [Date] = []
        
        // 计算重复的年数
        // repeatCount = 1: 需要2年（今年+明年）
        // repeatCount = 2: 需要3年（今年+明年+后年）
        let totalYearsNeeded = repeatCount + 1
        
        print("📅 第一步：计算所有年份的日期")
        print("  - 基准日期: \(baseDate.dateAndWeekString)")
        print("  - 重复次数: \(repeatCount)")
        print("  - 需要年数: \(totalYearsNeeded)")
        print("  - 每\(repeatInterval)年重复")
        print("  - 选中的月日: \(selectedMonth)月\(selectedDay)日")
        print("  - 日历类型: \(selectedCalendarType.rawValue)")
        
        for yearOffset in 0...totalYearsNeeded {
            print("  - 处理第\(yearOffset)年:")
            
            // 计算目标年份
            let targetYear = baseDate.adding(years: yearOffset * repeatInterval)
            let targetYearNum = targetYear.year
            
            if selectedCalendarType == .gregorian {
                // 公历日期计算
                let targetDate = Date.createDate(year: targetYearNum, month: selectedMonth, day: selectedDay)
                
                // 检查日期是否有效（处理2月30日、31日等不存在的情况）
                if targetDate.month == selectedMonth && targetDate.day == selectedDay {
                    allDates.append(targetDate)
                    print("    - 📅 收集公历日期: \(targetDate.dateAndWeekString)")
                } else {
                    print("    - ❌ 跳过无效公历日期: \(targetYearNum)年\(selectedMonth)月\(selectedDay)日 (该月不存在此日期)")
                }
                
            } else {
                // 农历日期计算（简化实现，实际应用中建议使用专业的农历库）
                print("    - 📅 农历日期计算（待实现）: \(targetYearNum)年\(selectedMonth)月\(selectedDay)日")
                // 第一步：根据事件的todoTime年份和选择的月日创建日期，转为农历
                let baseYear = baseDate.year
                let baseDateForLunar = Date.createDate(year: baseYear, month: selectedMonth, day: selectedDay)
                let baseLunar = baseDateForLunar.toLunar
                
                print("    - 📅 基准农历日期: \(baseLunar.yearInChinese)年\(baseLunar.monthInChinese)\(baseLunar.dayInChinese)")
                
                // 第二步：根据农历年月日，计算目标年份的农历日期
                let targetLunarYear = baseLunar.year + (yearOffset * repeatInterval)
                let targetLunarMonth = baseLunar.month
                let targetLunarDay = baseLunar.day
                
                print("    - 📅 目标农历日期: \(targetLunarYear)年\(targetLunarMonth)月\(targetLunarDay)日")
                
                // 第三步：将目标农历日期转换为阳历日期
                if let targetDate = Date.fromLunar(lunarYear: targetLunarYear, lunarMonth: targetLunarMonth, lunarDay: targetLunarDay) {
                    allDates.append(targetDate)
                    print("    - ✅ 农历转阳历成功: \(targetDate.dateAndWeekString)")
                    
                    // 验证转换结果：将阳历日期转回农历，检查是否匹配
                    let verifyLunar = targetDate.toLunar
                    if verifyLunar.month == targetLunarMonth && verifyLunar.day == targetLunarDay {
                        print("    - ✅ 农历验证通过: \(verifyLunar.monthInChinese)\(verifyLunar.dayInChinese)")
                    } else {
                        print("    - ⚠️ 农历验证失败: 期望\(targetLunarMonth)月\(targetLunarDay)日，实际\(verifyLunar.month)月\(verifyLunar.day)日")
                    }
                } else {
                    print("    - ❌ 农历转阳历失败: \(targetLunarYear)年\(targetLunarMonth)月\(targetLunarDay)日")
                }
            }
        }
        
        // 第二步：去除比当前事件todoTime小的日期
        print("📅 第二步：去除比基准日期小的日期")
        let filteredByTime = allDates.filter { date in
            let isAfterBaseDate = date.isGreaterThanOrEqual(to: baseDate)
            if !isAfterBaseDate {
                print("  - ❌ 去除过期日期: \(date.dateAndWeekString)")
            } else {
                print("  - ✅ 保留日期: \(date.dateAndWeekString)")
            }
            return isAfterBaseDate
        }
        
        // 第三步：根据条件筛选（跳过法定节假日、双休日、法定工作日）
        print("📅 第三步：应用过滤规则")
        var finalDates: [Date] = []
        for date in filteredByTime {
            let validDate = applyWorkdayFilter(to: date)
            
            // 检查是否已经存在相同的日期，避免重复
            if !finalDates.contains(where: { calendar.isDate($0, inSameDayAs: validDate) }) {
                finalDates.append(validDate)
                print("  - ✅ 最终日期: \(validDate.dateAndWeekString)")
            } else {
                print("  - ⚠️ 跳过重复日期: \(validDate.dateAndWeekString)")
            }
        }
        
        // 按日期排序
        finalDates.sort { $0 < $1 }
        
        return finalDates
    }

    
    /// 检查日期是否符合工作日过滤规则
    private func isDateValidForWorkdayFilter(_ date: Date) -> Bool {
        // 如果选择了法定工作日，检查是否为法定工作日
        if isLegalWorkday {
            return isLegalWorkday(date)
        } else {
            // 如果选择了跳过法定节假日或双休日，检查是否符合条件
            return isValidDate(date)
        }
    }
    
    /// 应用工作日过滤规则
    private func applyWorkdayFilter(to date: Date) -> Date {
        // 如果选择了法定工作日，需要过滤掉非工作日
        if isLegalWorkday {
            return findNextLegalWorkday(from: date)
        } else {
            // 如果选择了跳过法定节假日或双休日，也需要过滤
            return findValidDate(from: date)
        }
    }
    
    /// 查找下一个法定工作日（根据重复间隔）
    private func findNextLegalWorkday(from date: Date) -> Date {
        var currentDate = date
        
        // 循环查找，直到找到法定工作日
        while !isLegalWorkday(currentDate) {
            currentDate = addRepeatInterval(to: currentDate)
        }
        
        return currentDate
    }
    
    /// 根据设置查找有效日期（根据重复间隔）
    private func findValidDate(from date: Date) -> Date {
        var currentDate = date
        
        // 循环查找，直到找到符合条件的日期
        while !isValidDate(currentDate) {
            currentDate = addRepeatInterval(to: currentDate)
        }
        
        return currentDate
    }
    
    /// 根据重复间隔添加时间
    private func addRepeatInterval(to date: Date) -> Date {
        switch selectedUnit {
        case .day:
            return date.adding(days: repeatInterval)
        case .week:
            return date.adding(days: repeatInterval * 7)
        case .month:
            return date.adding(months: repeatInterval)
        case .year:
            return date.adding(years: repeatInterval)
        }
    }

    /// 判断日期是否有效（根据用户设置）
    private func isValidDate(_ date: Date) -> Bool {
        let isHolidayResult = isHoliday(date)
        let isWeekendResult = isWeekend(date)
        
        // 调试信息
        print("🔍 检查日期有效性: \(date.dateAndWeekString)")
        print("  - 是否为节假日: \(isHolidayResult)")
        print("  - 是否为周末: \(isWeekendResult)")
        print("  - 跳过法定节假日: \(skipHolidays)")
        print("  - 跳过双休日: \(skipWeekends)")
        
        // 如果选择了跳过法定节假日
        if skipHolidays && isHolidayResult {
            print("  - ❌ 跳过节假日")
            return false
        }
        
        // 如果选择了跳过双休日
        if skipWeekends && isWeekendResult {
            print("  - ❌ 跳过周末")
            return false
        }
        
        print("  - ✅ 日期有效")
        return true
    }

    /// 判断是否为法定节假日
    private func isHoliday(_ date: Date) -> Bool {
        let timestamp = date.startOfDayTimestamp
        let holidayList = TDHolidayManager.shared.getHolidayList()
        
        // 调试信息
        if date.description.contains("2025-10-01") {
            print("🔍 检查10月1日是否为节假日:")
            print("  - 时间戳: \(timestamp)")
            print("  - 节假日数据总数: \(holidayList.count)")
            print("  - 查找匹配的节假日:")
            for holiday in holidayList {
                if holiday.date == timestamp {
                    print("    - 找到匹配: \(holiday.name), holiday: \(holiday.holiday)")
                }
            }
        }
        
        return holidayList.contains { $0.date == timestamp && $0.holiday }
    }
    
    /// 判断是否为调休工作日
    private func isWorkday(_ date: Date) -> Bool {
        let timestamp = date.startOfDayTimestamp
        return TDHolidayManager.shared.getHolidayList().contains { $0.date == timestamp && !$0.holiday }
    }
    
    /// 判断是否为法定工作日（非周末，非节假日，但可能是调休工作日）
    private func isLegalWorkday(_ date: Date) -> Bool {
        // 如果是法定节假日，不是工作日
        if isHoliday(date) {
            return false
        }
        
        // 如果是调休工作日，是工作日
        if isWorkday(date) {
            return true
        }
        
        // 其他情况按正常工作日判断（周一到周五）
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday >= 2 && weekday <= 6 // 周一到周五
    }
    
    /// 判断是否为周末
    private func isWeekend(_ date: Date) -> Bool {
        // 如果是调休工作日，不是周末
        if isWorkday(date) {
            return false
        }
        
        // 其他情况按正常周末判断（周六周日）
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7 // 周日或周六
    }
    
    /// 验证重复次数范围
    private func validateRepeatCount() {
        if repeatCount < 1 {
            repeatCount = 1
        } else if repeatCount > 99 {
            repeatCount = 99
        }
    }
    
    
    
    
}

//// MARK: - 预览
//#Preview {
//    TDCustomRepeatSettingView(isPresented: .constant(true))
//        .environmentObject(TDThemeManager.shared)
//        .frame(width: 400)
//}
