//
//  TDScheduleOverviewView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData

/// 日程概览视图
struct TDScheduleOverviewView: View {
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            TDScheduleTopToolbar()
            
            // 内容区域
            Spacer()
        }
    }
}

#Preview {
    TDScheduleOverviewView()
        .environmentObject(TDThemeManager.shared)
} 
