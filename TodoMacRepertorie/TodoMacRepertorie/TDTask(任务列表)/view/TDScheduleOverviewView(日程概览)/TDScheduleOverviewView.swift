//
//  TDScheduleOverviewView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData

/// 日程概览界面
struct TDScheduleOverviewView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack {
            Text("日程概览界面")
                .font(.title2)
                .fontWeight(.semibold)
                .padding()
            
            Text("这里将显示日程概览")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

#Preview {
    TDScheduleOverviewView()
        .environmentObject(TDThemeManager.shared)
} 
