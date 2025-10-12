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
            // 左侧：输入框区域
            HStack(spacing: 8) {
                // 分类选择 Menu (缩小)
                Menu {
                    // MARK: - 不分类选项
                    Button(action: {
                        viewModel.updateSelectedCategory(nil)
                    }) {
                        HStack {
                            Image(systemName: "circle")
                                .foregroundColor(.red)
                                .font(.system(size: 12))
                            Text("未分类")
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()

                    // MARK: - 现有分类列表
                    if !viewModel.availableCategories.isEmpty {
                        Divider()
                        
                        ForEach(viewModel.availableCategories, id: \.categoryId) { category in
                            Button(action: {
                                viewModel.updateSelectedCategory(category)
                            }) {
                                HStack {
                                    Image.fromHexColor(category.categoryColor ?? "#c3c3c3", width: 14, height: 14, cornerRadius: 7.0)
                                        .resizable()
                                        .frame(width: 14.0, height: 14.0)

                                    Text(String(category.categoryName.prefix(8)))
                                        .font(.system(size: 12))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .pointingHandCursor()

                        }
                    }
                } label: {
                    // 显示当前选中的分类或默认圆圈 (缩小)
                    ZStack(alignment: .center) {
                        if let selectedCategory = viewModel.selectedCategory {
                            Circle()
                                .fill(Color.fromHex(selectedCategory.categoryColor ?? "#c3c3c3"))
                                .frame(width: 14, height: 14)

                        } else {
                            Circle()
                                .stroke(themeManager.color(level: 5), lineWidth: 2)
                                .frame(width: 14, height: 14)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .menuStyle(.button)
                .menuIndicator(.hidden)
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()

                // 输入框
                TextField("在此添加内容, 按回车创建事件", text: $viewModel.inputText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.titleTextColor)
                    .onSubmit {
                        viewModel.createTask()
                    }
                
                // 更多菜单按钮
                TDScheduleMoreMenu()

            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeManager.borderColor, lineWidth: 1)
                    )
            )
            
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
            
            // 日期导航 (带边框)
            HStack(spacing: 6) {
                // 左箭头
                Button(action: {
                    viewModel.previousMonth()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.descriptionTextColor)
                        .contentShape(Rectangle()) // 让整个单元格区域都可以点击
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()

                // 日历图标和日期
                Button(action: {
                    viewModel.showDatePickerView()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.color(level: 5))
                        
                        Text(viewModel.currentDate.formattedString)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.color(level: 5))
                    }
                    .contentShape(Rectangle()) // 让整个单元格区域都可以点击
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
                .popover(isPresented: $viewModel.showDatePicker) {
                    TDCustomDatePickerView(
                        selectedDate: $viewModel.currentDate,
                        isPresented: $viewModel.showDatePicker,
                        onDateSelected: { date in
                            // 日期选择完成后的回调函数
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
                // 右箭头
                Button(action: {
                    viewModel.nextMonth()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.descriptionTextColor)
                        .contentShape(Rectangle()) // 让整个单元格区域都可以点击
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
                // 回到今天按钮
                Button(action: {
                    viewModel.backToToday()
                }) {
                    Image(systemName: "sun.min.fill")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.color(level: 5))
                        .contentShape(Rectangle()) // 让整个单元格区域都可以点击
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
