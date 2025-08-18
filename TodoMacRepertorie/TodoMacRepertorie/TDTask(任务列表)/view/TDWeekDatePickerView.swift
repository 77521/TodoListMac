//
//  TDWeekDatePickerView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/21.
//

import SwiftUI

struct TDWeekDatePickerView: View {
    @StateObject private var dateManager = TDDateManager.shared
    @StateObject private var mainViewModel = TDMainViewModel.shared
    @StateObject private var themeManager = TDThemeManager.shared
    @State private var showDatePicker = false
    @State private var selectedPickerDate = Date()
    
    var body: some View {
        HStack {
            // 左边整体（切换按钮+日期显示）
            HStack(spacing: 0) {
                // 左切换按钮
                Button(action: {
                    dateManager.previousWeek()
                    if dateManager.currentWeek.contains(where: { $0.isToday }) {
                        dateManager.backToToday()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(themeManager.titleTextColor)
                        .frame(width: 30, height: 30)
//                        .background(Color.yellow.opacity(0.3))
                }
                .buttonStyle(.plain)
                
                // 日期显示
                HStack(spacing: 4) {
                    ForEach(dateManager.currentWeek, id: \.self) { date in
                        Button(action: {
                            Task {
                                await mainViewModel.selectDateAndRefreshTasks(date)
                            }
                        }) {
                            Text(date.dayNumberString)
                                .font(.system(size: 13))
                                .frame(width: 22, height: 22)
                                .background(
                                    dateManager.isSelectedDate(date) ? themeManager.color(level: 5) :
                                        date.isToday ? themeManager.color(level: 2) : Color.clear
                                )
                                .foregroundColor(
                                    dateManager.isSelectedDate(date) ? .white :
                                    date.isToday ? themeManager.color(level: 7) :
                                    themeManager.titleTextColor
                                )
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .frame(width: 24, height: 24)

                    }
                }
                
                // 右切换按钮
                Button(action: {
                    dateManager.nextWeek()
                    if dateManager.currentWeek.contains(where: { $0.isToday }) {
                        dateManager.backToToday()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(themeManager.titleTextColor)
                        .frame(width: 30, height: 30)
//                        .background(Color.yellow.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
//            .background(Color.green.opacity(0.1))
            
            Spacer(minLength: 0)
            
            // 日期详情
            Button(action: {
                selectedPickerDate = dateManager.selectedDate
                showDatePicker = true
            }) {
                Text(dateManager.selectedDate.dateAndWeekString)
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.titleTextColor)
                    .frame(height: 30)

            }
            .buttonStyle(.plain)
//            .background(Color.red.opacity(0.1))
            .popover(isPresented: $showDatePicker) {
                TDCustomDatePickerView(
                    selectedDate: $selectedPickerDate,
                    isPresented: $showDatePicker,
                    onDateSelected: { date in
                        Task {
                            await mainViewModel.selectDateAndRefreshTasks(date)
                        }
                    }
                )
                .frame(width: 280, height: 320)
            }
            
            // 回到今天按钮
            Button(action: {
                dateManager.backToToday()
            }) {
                Image(systemName: "sun.max")
                    .foregroundColor(themeManager.titleTextColor)
                    .frame(width: 30, height: 30)
//                    .background(Color.purple.opacity(0.3))
            }
            .buttonStyle(.plain)
        }
        .frame(height: 35)
        .padding(.horizontal, 12)
        .background(themeManager.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
    }
}

#Preview {
    TDWeekDatePickerView()
}
