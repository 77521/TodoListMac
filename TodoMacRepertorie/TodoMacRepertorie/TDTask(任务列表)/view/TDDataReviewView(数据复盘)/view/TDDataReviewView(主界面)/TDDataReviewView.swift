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
        VStack(spacing: 0) {
            // 顶部统计视图
            TDDataReviewTopView()
                .zIndex(1)
            
            // 数据内容展示区域
            TDDataReviewContentView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.backgroundColor)
    }
}

#Preview {
    TDDataReviewView()
        .environmentObject(TDThemeManager.shared)
} 
