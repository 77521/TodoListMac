//
//  TDCalendarPopView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/20.
//

import SwiftUI
import SwiftDate

// 自定义日历视图
struct TDCalendarPopView: View {
    var body: some View {
        List(1...20, id: \.self) { item in
            Text("项目 \(item)")
        }
        .listStyle(.sidebar)
    }
}

#Preview {
    TDCalendarPopView()
}
