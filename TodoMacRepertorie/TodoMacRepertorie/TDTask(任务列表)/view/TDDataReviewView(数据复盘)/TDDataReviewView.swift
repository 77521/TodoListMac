//
//  TDDataReviewView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData

/// 数据复盘界面
struct TDDataReviewView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack {
            Text("数据复盘界面")
                .font(.title2)
                .fontWeight(.semibold)
                .padding()
            
            Text("这里将显示数据统计和复盘")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

#Preview {
    TDDataReviewView()
        .environmentObject(TDThemeManager.shared)
} 
