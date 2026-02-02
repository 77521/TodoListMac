//
//  TDScheduleTopToolbar.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import Foundation

/// 日程概览顶部工具栏
struct TDScheduleTopToolbar: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @EnvironmentObject private var viewModel: TDScheduleOverviewViewModel

    
    var body: some View {
        HStack(spacing: 12) {
            // 左侧：输入框区域 - 直接使用 TDScheduleTaskInputView
            TDScheduleTaskInputView(selectedDate: viewModel.currentDate)

            // 筛选菜单
            TDScheduleFilterMenu(
                onCategorySelected: { category in
                    viewModel.updateSelectedCategory(category)
                },
                onTagFiltered: { tag in
                    viewModel.updateTagFilter(tag)
                },
                onSortChanged: { sortType in
                    viewModel.updateSortType(sortType)
                },
                onClearFilter: {
                    viewModel.updateSelectedCategory(nil)
                    viewModel.updateTagFilter("")
                    viewModel.updateSortType(0)
                }
            )

            
            // 搜索筛选输入框 (带边框)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.descriptionTextColor)
                
                TextField("搜索筛选", text: .constant(""))
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.titleTextColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(themeManager.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(themeManager.borderColor, lineWidth: 1)
                    )
            )
            
            Spacer()
            
            // 日期导航区域
            HStack(spacing: 8) {
                // 日期导航容器 (带边框)
                HStack(spacing: 3) {
                    // 左箭头 - 增大点击区域
                    Button(action: {
                        viewModel.previousMonth()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.descriptionTextColor)
                            .frame(minWidth: 24, minHeight: 24) // 增大点击区域
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()

                    // 日期显示 - 宽度固定，中间对齐，只显示年月
                    Button(action: {
                        viewModel.showDatePickerView()
                    }) {
                        Text(viewModel.currentDate.formattedYearMonthString)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.color(level: 5))
                            .frame(width: 80, alignment: .center) // 固定宽度，中间对齐
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                    .popover(isPresented: $viewModel.showDatePicker) {
                        TDCustomDatePickerView(
                            selectedDate: $viewModel.currentDate,
                            isPresented: $viewModel.showDatePicker,
                            onDateSelected: { date in
                                // 日期选择完成后的回调函数 - 直接更新日期并重新计算日历数据
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.currentDate = date
                                }
                                // 手动触发日历数据重新计算
                                Task {
                                    try? await TDCalendarManager.shared.updateCalendarData()
                                }
                            }
                        )
                        .frame(width: 280, height: 320) // 设置弹窗尺寸
                    }
                    
                    // 右箭头 - 增大点击区域
                    Button(action: {
                        viewModel.nextMonth()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.descriptionTextColor)
                            .frame(minWidth: 24, minHeight: 24) // 增大点击区域
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(themeManager.backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(themeManager.borderColor, lineWidth: 1)
                        )
                )
                
                // 回到今天按钮 - 放在外面，按钮变大
                Button(action: {
                    viewModel.backToToday()
                }) {
                    Image(systemName: "sun.min.fill")
                        .font(.system(size: 16)) // 增大图标
                        .foregroundColor(themeManager.color(level: 5))
                        .frame(minWidth: 32, minHeight: 32) // 增大按钮区域
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(themeManager.backgroundColor)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)

    }
    
}



#Preview {
    TDScheduleTopToolbar()
}
