//
//  TDCalendarPopView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/20.
//

import SwiftUI
import SwiftDate
import LunarSwift

// MARK: - 日历主视图
struct TDCalendarPopView: View {
    @StateObject private var viewModel = TDCalendarViewModel()
//    @Binding var selectedDate: DateInRegion
//    @Binding var isPresented: Bool
    
//    @StateObject private var viewModel: TDCalendarViewModel
    @Binding var selectedDate: DateInRegion
    @Binding var isPresented: Bool
    let configuration: TDCalendarConfiguration
    
    // 添加动画状态
    @State private var animationState = false

    
//    let configuration: Configuration
    init(selectedDate: Binding<DateInRegion>,
         isPresented: Binding<Bool>,
         initialDate: DateInRegion,  // 添加初始日期参数
         configuration: TDCalendarConfiguration) {
        _selectedDate = selectedDate
        _isPresented = isPresented
        self.configuration = configuration
        // 使用传入的初始日期初始化视图模型
        _viewModel = StateObject(wrappedValue: TDCalendarViewModel(initialDate: initialDate))
    }

    
    // MARK: - 配置结构
    struct TDCalendarConfiguration {
        var showLunar: Bool = true
        var showFestival: Bool = true
        var showWeekend: Bool = true
        var firstWeekday: Int = TDSettingManager.shared.firstWeekday  // 1 = 周日, 2 = 周一
        var monthDisplayFormat: String = "yyyy年MM月"  // 修改格式，确保年份显示4位
        var theme: TDCalendarTheme = .default
        
        var weekdaySymbols: [String] {
            let symbols = ["日", "一", "二", "三", "四", "五", "六"]
            if TDSettingManager.shared.weekStartsOnMonday {
                var adjusted = symbols
                let sunday = adjusted.removeFirst()
                adjusted.append(sunday)
                return adjusted
            }
            return symbols
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 所有内容放在一个 VStack 中，一次性加载
            VStack(spacing: 12) {
                // 导航栏
                navigationHeader
                
                if viewModel.showYearPicker {
                    yearPickerView
                } else {
                    // 星期和日期内容放在同一个 VStack 中
                    VStack(spacing: 8) {
                        weekdayHeader
                        monthGridView
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .background(configuration.theme.backgroundColor)
        .cornerRadius(10)
        .shadow(radius: 5)
        .frame(width: TDCalendarConstants.UI.calendarWidth)
        // 添加动画修饰符
        .offset(y: animationState ? 0 : 0)  // 移除位移动画
        .opacity(animationState ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) {
                animationState = true
            }
        }
        .onDisappear {
            animationState = false
        }

    }
    
    // MARK: - 导航头部
    private var navigationHeader: some View {
        HStack {
            Button(action: {
                Task {
                    await viewModel.changeYear(by: -1)
                }
            }) {
                Image(systemName: "chevron.left.2")
                    .foregroundColor(configuration.theme.controlColor)
            }
            
            Button(action: {
                Task {
                    await viewModel.changeMonth(by: -1)
                }
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(configuration.theme.controlColor)
            }
            
            Spacer()
            
            Button(action: { viewModel.showYearPicker.toggle() }) {
                Text(viewModel.currentDate.toFormat("yyyy年MM月"))  // 使用固定格式
                    .font(configuration.theme.titleFont)
                    .foregroundColor(configuration.theme.titleColor)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await viewModel.changeMonth(by: 1)
                }
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(configuration.theme.controlColor)
            }
            
            Button(action: {
                Task {
                    await viewModel.changeYear(by: 1)
                }
            }) {
                Image(systemName: "chevron.right.2")
                    .foregroundColor(configuration.theme.controlColor)
            }
        }
        .padding(.horizontal)
        .frame(height: TDCalendarConstants.UI.navigationHeight)
    }
    
    // MARK: - 星期头部
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(configuration.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(configuration.theme.weekdayFont)
                    .foregroundColor(configuration.theme.weekdayColor)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .frame(height: TDCalendarConstants.UI.weekdayHeight)
    }
    
    // MARK: - 月份网格
    private var monthGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
            ForEach(viewModel.calendarDays) { day in
                TDCalendarDayCell(
                    day: day,
                    isSelected: day.date.date.isSameDay(selectedDate.date),
                    configuration: configuration
                )
                .onTapGesture {
                    selectedDate = day.date
                    isPresented = false
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - 年份选择器
    private var yearPickerView: some View {
        let currentYear = viewModel.currentDate.year
        let years = Array(
            (TDCalendarConstants.minimumYear...TDCalendarConstants.maximumYear)
        )
        
        return ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 4),
                spacing: 12
            ) {
                ForEach(years, id: \.self) { year in
                    Button(action: {
                        Task {
                            await viewModel.changeYear(to: year)
                            viewModel.showYearPicker = false
                        }
                    }) {
                        Text("\(year)")
                            .font(configuration.theme.yearPickerFont)
                            .foregroundColor(
                                year == currentYear ?
                                configuration.theme.selectedTextColor :
                                configuration.theme.textColor
                            )
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                year == currentYear ?
                                configuration.theme.selectedBackgroundColor :
                                Color.clear
                            )
                            .cornerRadius(6)
                    }
                }
            }
            .padding()
        }
        .frame(height: 300)
    }

    
}
// MARK: - 日期单元格
struct TDCalendarDayCell: View {
    let day: TDCalendarDay
    let isSelected: Bool
    let configuration: TDCalendarPopView.TDCalendarConfiguration
    
    var body: some View {
        VStack(spacing: 2) {
            // 阳历日期
            Text("\(day.solarDay)")
                .font(configuration.theme.dayFont)
                .foregroundColor(textColor)
            
            // 农历或节日信息
            if configuration.showLunar {
                Group {
                    if let festival = day.festival, configuration.showFestival {
                        // 优先显示节日
                        Text(festival.name)
                            .foregroundColor(festivalColor(for: festival))
                            .lineLimit(1)
                    } else if let solarTerm = day.solarTerm {
                        // 其次显示节气
                        Text(solarTerm)
                            .foregroundColor(configuration.theme.solarTermColor)
                    } else if day.isLunarFirstDay {
                        // 显示农历月份
                        Text(day.lunarMonth)
                            .foregroundColor(configuration.theme.lunarColor)
                    } else {
                        // 最后显示农历日期
                        Text(day.lunarDay)
                            .foregroundColor(configuration.theme.lunarColor)
                    }
                }
                .font(configuration.theme.lunarFont)
                .frame(height: 16)
            }
        }
        .frame(height: TDCalendarConstants.UI.dayCellHeight)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColorForDay)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected ? configuration.theme.selectedBackgroundColor : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - 辅助计算属性
    
    /// 背景颜色
    private var backgroundColorForDay: Color {
        if isSelected {
            return configuration.theme.selectedBackgroundColor.opacity(0.1)
        }
        if day.isToday {
            return configuration.theme.todayBackgroundColor
        }
        return Color.clear
    }
    
    /// 文本颜色
    private var textColor: Color {
        if !day.isCurrentMonth {
            return configuration.theme.inactiveTextColor
        }
        
        if day.workdayType == .holiday {
            return configuration.theme.holidayColor
        }
        
        if day.isWeekend && configuration.showWeekend {
            return configuration.theme.weekendColor
        }
        
        return configuration.theme.textColor
    }
    
    /// 节日文本颜色
    private func festivalColor(for festival: TDFestival) -> Color {
        switch festival.type {
        case .legal:
            return configuration.theme.holidayColor
        case .lunar:
            return configuration.theme.festivalColor
        case .solar:
            return configuration.theme.festivalColor
        case .foreign:
            return configuration.theme.festivalColor
        case .solarTerm:
            return configuration.theme.solarTermColor
        }
    }
}

//#Preview {
//    TDCalendarPopView(selectedDate: .constant(DateInRegion()), isPresented: .constant(true), configuration: TDCalendarPopView.TDCalendarConfiguration)
//        .frame(width: 300) // 只指定宽度，高度自适应
//}
