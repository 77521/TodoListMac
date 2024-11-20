//
//  TDDetailListView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/11/14.
//

import SwiftUI

struct TDDetailListView: View {
    let category: TDSliderBarModel
    var body: some View {
        List(1...20, id: \.self) { item in
            Text("项目 \(item)")
        }
        .listStyle(.sidebar)
    }
}

#Preview {
    TDDetailListView(category: TDSliderBarModel())
}
