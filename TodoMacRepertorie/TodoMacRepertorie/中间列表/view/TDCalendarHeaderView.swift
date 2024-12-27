//
//  TDCalendarHeaderView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/2.
//

import SwiftUI
import SwiftDate



/// 日历头部视图（年月切换）
struct TDCalendarHeaderView: View {
    @ObservedObject var viewModel: TDCalendarState
    
    var body: some View {
        HStack {
            // 年月显示和选择器
            Button {
                viewModel.isYearPickerPresented = true
            } label: {
                HStack(spacing: 4) {
                    Text("\(viewModel.currentMonth.year)年\(viewModel.currentMonth.month)月")
                        .font(.system(size: 16, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                }
            }
            
            Spacer()
            
            // 月份切换按钮
            HStack(spacing: 16) {
                Button {
                    viewModel.previousMonth()
                } label: {
                    Image(systemName: "chevron.left")
                }
                
                Button {
                    viewModel.nextMonth()
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
        }
        .foregroundColor(.primary)
        .popover(isPresented: $viewModel.isYearPickerPresented) {
            TDCalendarYearPicker(viewModel: viewModel)
        }
    }
}

/// 星期栏视图
struct TDCalendarWeekView: View {
    let firstWeekday: Int
    
    private var weekdaySymbols: [String] {
        var symbols = ["日", "一", "二", "三", "四", "五", "六"]
        if firstWeekday == 1 {
            symbols.append(symbols.removeFirst())
        }
        return symbols
    }
    
    var body: some View {
        HStack {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// 日期网格视图
struct TDCalendarDatesView: View {
    @ObservedObject var viewModel: TDCalendarState
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
            ForEach(viewModel.dates) { date in
                TDCalendarDayCell(
                    date: date,
                    isSelected: date.date == viewModel.selectedDate,
                    theme: viewModel.config.calendarTheme
                )
                .onTapGesture {
                    viewModel.selectDate(date.date)
                }
            }
        }
    }
}

/// 年份选择器视图
private struct TDCalendarYearPicker: View {
    @ObservedObject var viewModel: TDCalendarState
    var body: some View {
        VStack {
            HStack {
                Button {
                    viewModel.previousYear()
                } label: {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Button {
                    viewModel.nextYear()
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(viewModel.availableYears(), id: \.self) { year in
                        Button {
                            viewModel.switchToYear(year)
                        } label: {
                            Text("\(year)")
                                .font(.system(size: 16))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(year == viewModel.currentMonth.year ? Color.accentColor.opacity(0.1) : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 200, height: 300)
    }
}


//#Preview {
//    TDCalendarHeaderView(currentMonth: <#Date#>, showWeekView: <#Bool#>, theme: <#TDCalendarTheme#>, onPreviousYear: <#() -> Void#>, onPreviousMonth: <#() -> Void#>, onNextMonth: <#() -> Void#>, onNextYear: <#() -> Void#>, onTodayTapped: <#() -> Void#>, onToggleViewMode: <#(Bool) -> Void#>)
//}
