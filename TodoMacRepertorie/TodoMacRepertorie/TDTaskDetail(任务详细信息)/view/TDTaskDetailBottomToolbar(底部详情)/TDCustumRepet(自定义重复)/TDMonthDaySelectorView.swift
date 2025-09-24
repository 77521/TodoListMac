import SwiftUI

/// 月日期选择器视图
/// 用于选择每月的哪几天重复
struct TDMonthDaySelectorView: View {
    
    // MARK: - 数据绑定
    @EnvironmentObject private var themeManager: TDThemeManager  // 主题管理器
    @Binding var selectedDays: Set<Int>  // 选中的日期（1-31）
    @Binding var includeLastDay: Bool  // 是否包含最后一天
    
    // MARK: - 参数
    let taskTodoTime: Int64  // 任务的todoTime（时间戳）
    
    // MARK: - 初始化方法
    init(selectedDays: Binding<Set<Int>>, includeLastDay: Binding<Bool>, taskTodoTime: Int64) {
        self._selectedDays = selectedDays
        self._includeLastDay = includeLastDay
        self.taskTodoTime = taskTodoTime
    }
    
    // MARK: - 私有属性
    private let maxDaysInMonth = 31
    
    // MARK: - 主视图
    var body: some View {
        VStack(spacing: 16) {
            // 日期选择网格
            daySelectionGrid
            
            // 最后一天选项
            lastDayOption
        }
        .onAppear {
            // 如果selectedDays为空，则设置默认值
            if selectedDays.isEmpty {
                let taskDate = Date.fromTimestamp(taskTodoTime)
                let calendar = Calendar.current
                let day = calendar.component(.day, from: taskDate)
                selectedDays = [day]
            }
        }
    }
    
    /// 日期选择网格
    private var daySelectionGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(1...maxDaysInMonth, id: \.self) { day in
                Button(action: {
                    toggleDay(day)
                }) {
                    Text("\(day)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedDays.contains(day) ? .white : themeManager.color(level: 5))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(selectedDays.contains(day) ? themeManager.color(level: 5) : themeManager.secondaryBackgroundColor)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    /// 最后一天选项
    private var lastDayOption: some View {
        HStack {
            Text("最后一天")
                .font(.system(size: 14))
                .foregroundColor(themeManager.titleTextColor)
            
            Spacer()
            
            Toggle("", isOn: $includeLastDay)
                .toggleStyle(SwitchToggleStyle())
                .tint(themeManager.color(level: 5))
        }
    }
    
    // MARK: - 私有方法
    
    /// 切换日期选择
    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            // 如果只剩一个选择，不能取消
            if selectedDays.count > 1 {
                selectedDays.remove(day)
            }
        } else {
            selectedDays.insert(day)
        }
    }
}

// MARK: - 预览
#Preview {
    TDMonthDaySelectorView(
        selectedDays: .constant([1, 15, 31]),
        includeLastDay: .constant(true),
        taskTodoTime: Date().startOfDayTimestamp
    )
    .environmentObject(TDThemeManager.shared)
}
