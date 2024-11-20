//
//  TDMainView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/5.
//

import SwiftUI

struct TDMainView: View {
    
    @State private var selectedCategory: TDSliderBarModel?

    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var leftWidth: CGFloat = 200
    @State private var centerWidth: CGFloat = 300

    var body: some View {
        
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 第一列：分类列表
            TDSliderBarView(selection: Binding(
                get: { selectedCategory },
                set: { selectedCategory = $0 }
            ))
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 220)
            .toolbarBackground(Color(hexString: "#282828").opacity(0.6))
        } content: {
            Text("哈哈")
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        TDDetailToobarDateView()
                            .frame(height: 32)
                    }
                }
        } detail: {
            
        }

        
//        NavigationSplitView(columnVisibility: $columnVisibility) {
//            // 第一列：分类列表
//            TDSliderBarView(selection: Binding(
//                get: { selectedCategory },
//                set: { selectedCategory = $0 }
//            ))
//            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 220)
//            .toolbarBackground(Color(hexString: "#282828").opacity(0.6))
//
//        } content: {
//            // 第二列
//            TDDetailListView(category: selectedCategory ?? TDSliderBarModel())
//                .navigationSplitViewColumnWidth(min: 400, ideal: 600)
//
//        } detail: {
//            // 第三列
//            ScrollView {
//                Text("详情内容")
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding()
//            }
//            .navigationSplitViewColumnWidth(min: 400, ideal: 600)
//
//        }
    }
}

#Preview {
    TDMainView()
}
