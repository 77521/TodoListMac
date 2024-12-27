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
public struct TDCalendarPopView: View {
    @StateObject private var viewModel: TDCalendarState
    @Binding var isPresented: Bool
    
    /// 日期选择回调
    private let onDateSelected: (DateInRegion) -> Void
    
    public init(
        isPresented: Binding<Bool>,
        selectedDate: DateInRegion,
        config: TDCalendarConfig = TDCalendarConfig(),
        onDateSelected: @escaping (DateInRegion) -> Void
    ) {
        _isPresented = isPresented
        self.onDateSelected = onDateSelected
        _viewModel = StateObject(wrappedValue: TDCalendarState(
            date: selectedDate.date,
            config: config,
            onDateSelected: { date in
                onDateSelected(DateInRegion(date))  // 调用外部回调
                isPresented.wrappedValue = false
            }
        ))
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            TDCalendarHeaderView(viewModel: viewModel)
            TDCalendarWeekView(firstWeekday: TDSettingManager.shared.firstWeekday)
            TDCalendarDatesView(viewModel: viewModel)
        }
        .padding()
        .background(
            Color(NSColor.windowBackgroundColor)
                .cornerRadius(8)
                .shadow(radius: 8)
        )
//        .overlay(
//            Color.clear
//                .contentShape(Rectangle())
//                .onTapGesture {
//                    isPresented = false
//                }
//        )
    }
}

#Preview {
    TDCalendarPopView(
        isPresented: .constant(true),
        selectedDate: DateInRegion()
    ) { selectedDate in
        print("Selected date: \(selectedDate)")
    }
    .frame(width: 300)
    .padding()
}
