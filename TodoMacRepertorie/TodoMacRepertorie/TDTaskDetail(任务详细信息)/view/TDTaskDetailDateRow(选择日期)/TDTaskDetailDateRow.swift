//
//  TDTaskDetailDateRow.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI

/// 任务详情日期选择行
struct TDTaskDetailDateRow: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    
    // 当前选中的日期
    let selectedDate: Date?
    
    // 日期选择回调
    let onDateSelected: (Date?) -> Void
    
    // 弹窗状态
    @State private var showDatePicker = false
    
    // 当前选中的日期（用于弹窗）
    @State private var currentSelectedDate: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // 按钮行
            HStack(spacing: 12) {
                // 今天按钮
                Button(action: {
                    onDateSelected(Date())
                }) {
                    Text("today".localized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isTodaySelected ? .white : themeManager.descriptionTextColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isTodaySelected ? themeManager.color(level: 5) : themeManager.secondaryBackgroundColor)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()

                // 明天按钮
                Button(action: {
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    onDateSelected(tomorrow)
                }) {
                    Text("tomorrow".localized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isTomorrowSelected ? .white : themeManager.descriptionTextColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isTomorrowSelected ? themeManager.color(level: 5) : themeManager.secondaryBackgroundColor)
                        )
                }
                .pointingHandCursor()
                .buttonStyle(PlainButtonStyle())
                
                // 选择日期按钮
                Button(action: {
                    currentSelectedDate = selectedDate ?? Date()
                    showDatePicker = true
                }) {
                    HStack(spacing: 4) {
                        Text(customDateButtonText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isCustomDateSelected ? .white : themeManager.descriptionTextColor)
                        
                        Image(systemName: "arrowtriangle.down.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(isCustomDateSelected ? .white : themeManager.descriptionTextColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isCustomDateSelected ? themeManager.color(level: 5) : themeManager.secondaryBackgroundColor)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
                .popover(isPresented: $showDatePicker) {
                    TDCustomDatePickerView(
                        selectedDate: $currentSelectedDate,
                        isPresented: $showDatePicker,
                        onDateSelected: { date in
                            onDateSelected(date)
                        }
                    )
                    .frame(width: 280, height: 320)
                }
                                
                // 待办箱/无日期按钮
                Button(action: {
                    onDateSelected(nil)
                }) {
                    Text(isNoDateSelected ? "inbox".localized : "no_date".localized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isNoDateSelected ? .white : themeManager.descriptionTextColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isNoDateSelected ? themeManager.color(level: 5) : themeManager.secondaryBackgroundColor)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            
            // 分割线
            Rectangle()
                .fill(themeManager.descriptionTextColor.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 0)
        }
//        .frame(height: 44)
    }
    
    // MARK: - 计算属性
    
    /// 判断今天是否被选中
    private var isTodaySelected: Bool {
        guard let selectedDate = selectedDate else { return false }
        return selectedDate.isToday
    }
    
    /// 判断明天是否被选中
    private var isTomorrowSelected: Bool {
        guard let selectedDate = selectedDate else { return false }
        return selectedDate.isTomorrow
    }
    
    /// 判断是否选择了"待办箱"（没有日期）
    private var isNoDateSelected: Bool {
        return selectedDate == nil
    }
    
    /// 判断选择日期按钮是否应该显示选中状态
    private var isCustomDateSelected: Bool {
        guard let selectedDate = selectedDate else { return false }
        // 如果不是今天、明天，且不是待办箱，则显示选中状态
        return !isTodaySelected && !isTomorrowSelected && !isNoDateSelected
    }
    
    /// 选择日期按钮的文字
    private var customDateButtonText: String {
        guard let selectedDate = selectedDate else { return "select_date".localized }
        
        // 如果是今天或明天，不显示选中状态，返回"选择日期"
        if isTodaySelected || isTomorrowSelected {
            return "select_date".localized
        }
        
        // 使用 Date-Extension 中的方法判断是否是今年
        if selectedDate.isThisYear {
            // 今年：显示月日 星期
            return selectedDate.dateAndWeekString
        } else {
            // 不是今年：显示年月日
            return selectedDate.formattedString
        }
    }
}

#Preview {
    TDTaskDetailDateRow(
        selectedDate: Date(),
        onDateSelected: { date in
            print("选择了日期: \(date?.description ?? "待办箱")")
        }
    )
    .environmentObject(TDThemeManager.shared)
}
