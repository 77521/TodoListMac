//
//  TDDetailToobarView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/20.
//

import SwiftUI

struct TDDetailToobarDateView: View {
    @StateObject private var viewModel = DateNavigationViewModel()
    @StateObject private var settings = TDAppSettings.shared
    @State private var showCalendarPopover = false

    var body: some View {
        HStack(spacing: 8) {
            // 左箭头按钮
            Button(action: { viewModel.moveWeek(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.white)
            }
            .buttonStyle(.borderless)
            
            // 日期按钮组
            ForEach(viewModel.datesOfWeek(), id: \.date) { dateModel in
                TDDateButtonView(dateModel: dateModel) {
                    viewModel.selectedDate = dateModel.date
                }
            }
            
            // 右箭头按钮
            Button(action: { viewModel.moveWeek(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white)
            }
            .buttonStyle(.borderless)
            
            // 日期文本按钮
            Button(action: {
                showCalendarPopover.toggle()
            }) {
                Text(TDDetailDateModel(
                    date: viewModel.selectedDate,
                    isSelected: false
                ).fullDateString)
                .font(.system(size: 13))
                .foregroundStyle(.white)
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $showCalendarPopover) {
//                TDCalendarView(
//                    selectedDate: $viewModel.selectedDate,
//                    isPresented: $showCalendarPopover
//                )
//                .frame(width: 300, height: 320)
            }

            
            Spacer()
            
            // 设置按钮
            Button(action: {
                settings.weekStartsOnMonday.toggle()
            }) {
                Image(systemName: "gear")
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal)
        .frame(height: 40)
    }
}
// 日期按钮子视图
private struct TDDateButtonView: View {
    let dateModel: TDDetailDateModel
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(dateModel.displayText)  // 使用 displayText
                    .font(.system(size: 13))
            }
            .frame(width: 22, height: 22)
        }
        .buttonStyle(.borderless)
        .background(
            dateModel.isSelected ?
            Circle().fill(Color.marrsGreenColor5) :
            nil
        )
        .foregroundColor(
            dateModel.isSelected ? .white :
                dateModel.isToday ? .marrsGreenColor3 :
                    .greyColor3
        )
    }
}

#Preview {
    TDDetailToobarDateView()
}
