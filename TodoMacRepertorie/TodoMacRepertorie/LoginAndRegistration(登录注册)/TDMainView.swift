//
//  TDMainView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/5.
//

import SwiftUI

struct TDMainView: View {
    
    @StateObject private var categoryManager = TDCategoryManager.shared
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 第一列：分类列表
            TDSliderBarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } content: {
            // 第二列：待办列表
            Text("待办列表")
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            // 第三列：详情
            Text("详情")
                .navigationSplitViewColumnWidth(min: 300, ideal: 400)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

#Preview {
    TDMainView()
}
