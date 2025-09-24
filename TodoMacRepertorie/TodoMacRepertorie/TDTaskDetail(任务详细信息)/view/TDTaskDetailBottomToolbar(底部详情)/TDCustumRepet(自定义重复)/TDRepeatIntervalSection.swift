import SwiftUI

/// 重复间隔设置组件
struct TDRepeatIntervalSection: View {
    
    // MARK: - 数据绑定
    @EnvironmentObject private var themeManager: TDThemeManager
    
    // MARK: - 状态绑定
    @Binding var repeatInterval: Int
    
    // MARK: - 参数
    let selectedUnit: TDCustomRepeatSettingView.RepeatUnit
    let selectedWeekdays: Set<Int>?
    let selectedDays: Set<Int>?
    let includeLastDay: Bool
    let repeatCount: Int
    
    // 年重复参数
    let selectedCalendarType: TDDataOperationManager.CalendarType?
    let selectedMonth: Int?
    let selectedDay: Int?
    let taskTodoTime: Int64  // 任务的todoTime，用于获取年份

    // MARK: - 回调闭包
    let onPreviewTextChanged: () -> Void
    
    // MARK: - 主视图
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text("每")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.titleTextColor)
                
                // 数字输入框
                HStack(spacing: 0) {
                    TextField("1", value: $repeatInterval, format: .number)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.titleTextColor)
                        .multilineTextAlignment(.center)
                        .frame(width: 40)
                        .onChange(of: repeatInterval) { oldValue, newValue in
                            // 限制范围
                            if newValue < 1 {
                                repeatInterval = 1
                            } else if newValue > 99 {
                                repeatInterval = 99
                            }
                            onPreviewTextChanged()
                        }
                    
                    // 上下箭头按钮
                    VStack(spacing: 0) {
                        Button(action: {
                            if repeatInterval < 99 {
                                repeatInterval += 1
                                onPreviewTextChanged()
                            }
                        }) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 10))
                                .foregroundColor(themeManager.descriptionTextColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 20, height: 15)
                        
                        Button(action: {
                            if repeatInterval > 1 {
                                repeatInterval -= 1
                                onPreviewTextChanged()
                            }
                        }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                                .foregroundColor(themeManager.descriptionTextColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 20, height: 15)
                    }
                }
                .background(themeManager.secondaryBackgroundColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeManager.separatorColor, lineWidth: 1)
                )
            }
            
            // 预览文字
            HStack {
                Spacer()
                Text(getPreviewText())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.color(level: 5))
            }
        }
    }
    
    /// 获取预览文字
    private func getPreviewText() -> String {
        if selectedUnit == .week {
            // 周重复：显示选中的星期
            let weekText = getSelectedWeekdayText()
            return "每\(repeatInterval)周(\(weekText))，重复\(repeatCount)次"
        } else if selectedUnit == .month {
            // 月重复：显示选中的日期
            let dayText = getSelectedDayText()
            return "每\(repeatInterval)月(\(dayText))，重复\(repeatCount)次"
        } else if selectedUnit == .year {
            // 年重复：显示选中的月日
            let yearText = getSelectedYearText()
            return "每\(repeatInterval)年(\(yearText))，重复\(repeatCount)次"
        } else {
            // 其他重复单位：显示标准格式
            return "每\(repeatInterval)\(selectedUnit.displayName)，重复\(repeatCount)次"
        }
    }
    
    /// 获取选中的星期文字
    private func getSelectedWeekdayText() -> String {
        guard let weekdays = selectedWeekdays else { return "每天" }
        
        if weekdays.count == 7 {
            return "weekday.everyday".localized
        } else if weekdays.count == 1 {
            let weekday = weekdays.first!
            return getWeekdayName(weekday)
        } else {
            let sortedWeekdays = weekdays.sorted()
            let weekdayNames = sortedWeekdays.map { getWeekdayName($0) }
            return weekdayNames.joined(separator: "、")
        }
    }
    
    /// 获取星期名称
    private func getWeekdayName(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "weekday.sunday".localized
        case 2: return "weekday.monday".localized
        case 3: return "weekday.tuesday".localized
        case 4: return "weekday.wednesday".localized
        case 5: return "weekday.thursday".localized
        case 6: return "weekday.friday".localized
        case 7: return "weekday.saturday".localized
        default: return ""
        }
    }
    
    /// 获取选中的日期文字
    private func getSelectedDayText() -> String {
        guard let days = selectedDays else { return "1日" }
        
        // 如果选择了1-31天，显示"每月的每天"
        if days.count == 31 {
            return "每月的每天"
        }
        
        var dayTexts: [String] = []
        
        // 添加选中的日期
        let sortedDays = days.sorted()
        for day in sortedDays {
            dayTexts.append("\(day)日")
        }
        
        // 如果包含最后一天
        if includeLastDay {
            dayTexts.append("最后一天")
        }
        
        return dayTexts.joined(separator: "、")
    }
    
    /// 获取选中的年月日文字
    private func getSelectedYearText() -> String {
        guard let calendarType = selectedCalendarType,
              let month = selectedMonth,
              let day = selectedDay else {
            return "每年"
        }
        
        if calendarType == .gregorian {
            return "公历\(month)月\(day)日"
        } else {
            // 农历显示：将公历的月日转换为农历显示
            // 使用任务的todoTime年份进行转换
            let taskDate = Date.fromTimestamp(taskTodoTime)
            let taskYear = taskDate.year
            let solarDate = Date.createDate(year: taskYear, month: month, day: day)

            return "农历\(solarDate.lunarMonthDay)"
        }
    }
}

//// MARK: - 预览
//#Preview {
//    TDRepeatIntervalSection(
//        repeatInterval: .constant(1),
//        selectedUnit: .day,
//        selectedWeekdays: nil,
//        selectedDays: nil,
//        includeLastDay: false,
//        repeatCount: 1,
//        onPreviewTextChanged: { print("预览文字变化") }
//    )
//    .environmentObject(TDThemeManager.shared)
//}
