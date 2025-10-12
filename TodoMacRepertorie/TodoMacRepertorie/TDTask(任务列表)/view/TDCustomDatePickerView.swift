//
//  TDCustomDatePickerView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/21.
//

import SwiftUI

// 自定义日期选择器视图
struct TDCustomDatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let onDateSelected: (Date) -> Void
    @StateObject private var themeManager = TDThemeManager.shared
    
    @State private var currentMonth: Date
    @State private var selectedMonth: Date
    
    private let calendar = Calendar.current
    private let daysInWeek = ["日", "一", "二", "三", "四", "五", "六"]
    
    init(selectedDate: Binding<Date>, isPresented: Binding<Bool>, onDateSelected: @escaping (Date) -> Void) {
        self._selectedDate = selectedDate
        self._isPresented = isPresented
        self.onDateSelected = onDateSelected
        self._currentMonth = State(initialValue: selectedDate.wrappedValue)
        self._selectedMonth = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 月份选择器
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(themeManager.titleTextColor)
                }
                .pointingHandCursor()

                Spacer()
                
                Text(monthYearString(from: currentMonth))
                    .foregroundColor(themeManager.titleTextColor)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(themeManager.titleTextColor)
                }
                .pointingHandCursor()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // 星期标题
            HStack(spacing: 0) {
                ForEach(daysInWeek, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(themeManager.descriptionTextColor)
                        .font(.system(size: 12))
                }
            }
            .padding(.vertical, 8)
            
            // 日期网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        Button(action: {
                            selectedDate = date
                            onDateSelected(date)
                            isPresented = false
                        }) {
                            Text("\(calendar.component(.day, from: date))")
                                .frame(width: 32, height: 32)
                                .background(
                                    calendar.isDate(date, inSameDayAs: selectedDate) ?
                                        themeManager.color(level: 5) :
                                        date.isToday ? themeManager.color(level: 3) : .clear
                                )
                                .foregroundColor(
                                    calendar.isDate(date, inSameDayAs: selectedDate) ? .white :
                                        date.isToday ? themeManager.color(level: 7) :
                                        calendar.isDate(date, inSameDayAs: currentMonth) ?
                                            themeManager.titleTextColor :
                                            themeManager.descriptionTextColor
                                )
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .pointingHandCursor()
                    } else {
                        Color.clear
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
        }
        .background(themeManager.backgroundColor)
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        return formatter.string(from: date)
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func daysInMonth() -> [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        let remainingDays = 42 - days.count
        days.append(contentsOf: Array(repeating: nil, count: remainingDays))
        
        return days
    }
}
//#Preview {
//    TDCustomDatePickerView(selectedDate: <#Binding<Date>#>, isPresented: <#Binding<Bool>#>, onDateSelected: <#(Date) -> Void#>)
//}
