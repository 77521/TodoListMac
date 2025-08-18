//
//  TDCompletedDeletedView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI
import SwiftData

/// 已完成/已删除界面
struct TDCompletedDeletedView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    
    let category: TDSliderBarModel
    
    var body: some View {
        VStack {
            Text("\(category.categoryName) 界面")
                .font(.title2)
                .fontWeight(.semibold)
                .padding()
            
            Text("这里将显示 \(category.categoryName) 的内容")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

#Preview {
    TDCompletedDeletedView(category: TDSliderBarModel(
        categoryId: -107,
        categoryName: "最近已完成",
        headerIcon: "checkmark.circle",
        categoryColor: nil,
        unfinishedCount: 0,
        isSelect: false
    ))
    .environmentObject(TDThemeManager.shared)
} 
