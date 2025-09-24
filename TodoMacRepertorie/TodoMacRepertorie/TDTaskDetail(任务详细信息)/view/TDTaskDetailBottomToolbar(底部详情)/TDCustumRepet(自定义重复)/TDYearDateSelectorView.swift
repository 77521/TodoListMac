import SwiftUI

/// 年日期选择器视图
struct TDYearDateSelectorView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Binding var selectedCalendarType: TDDataOperationManager.CalendarType
    @Binding var selectedMonth: Int
    @Binding var selectedDay: Int
    let taskTodoTime: Int64
    
    
    // 月份选项
    private let months = Array(1...12)
    
    // 日期选项
    private let days = Array(1...31)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 日历类型、月份、日期选择（同一行）
            HStack(spacing: 12) {
                // 日历类型选择
                Picker("类型", selection: $selectedCalendarType) {
                    ForEach(TDDataOperationManager.CalendarType.allCases, id: \.self) { type in
                        Text(type.localized)
                            .tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(themeManager.secondaryBackgroundColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeManager.separatorColor, lineWidth: 1)
                )
                
                // 月份选择
                Picker("月份", selection: $selectedMonth) {
                    ForEach(months, id: \.self) { month in
                        Text("\(month)月")
                            .tag(month)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(themeManager.secondaryBackgroundColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeManager.separatorColor, lineWidth: 1)
                )
                
                // 日期选择
                Picker("日期", selection: $selectedDay) {
                    ForEach(availableDays, id: \.self) { day in
                        Text("\(day)日")
                            .tag(day)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(themeManager.secondaryBackgroundColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeManager.separatorColor, lineWidth: 1)
                )
            }
        }
        .onAppear {
            setupDefaultValues()
        }
        .onChange(of: selectedMonth) { oldValue, newValue in
            // 当月份改变时，调整日期选择
            adjustDaySelection()
        }
    }
    
    // 计算可用的日期（统一按公历计算）
    private var availableDays: [Int] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let daysInMonth = calendar.range(of: .day, in: .month, for: Date.createDate(year: currentYear, month: selectedMonth, day: 1))?.count ?? 31
        return Array(1...daysInMonth)
    }

    // 设置默认值
    private func setupDefaultValues() {
        let taskDate = Date.fromTimestamp(taskTodoTime)
        let calendar = Calendar.current
        
        // 根据任务日期设置默认值
        selectedMonth = taskDate.month
        selectedDay = taskDate.day
        
        // 默认使用公历
        selectedCalendarType = .gregorian
    }
    
    // 调整日期选择
    private func adjustDaySelection() {
        let maxDay = availableDays.max() ?? 31
        if selectedDay > maxDay {
            selectedDay = maxDay
        }
    }
    
}

// MARK: - 预览
#Preview {
    TDYearDateSelectorView(
        selectedCalendarType: .constant(.gregorian),
        selectedMonth: .constant(3),
        selectedDay: .constant(1),
        taskTodoTime: Date().fullTimestamp
    )
    .environmentObject(TDThemeManager.shared)
    .padding()
}
