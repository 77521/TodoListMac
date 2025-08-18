//
//  TDInboxView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData

/// 待办箱界面
struct TDInboxView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack {
            Text("待办箱界面")
                .font(.title2)
                .fontWeight(.semibold)
                .padding()
            
            Text("这里将显示待办箱内容")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

#Preview {
    TDInboxView()
        .environmentObject(TDThemeManager.shared)
} 
