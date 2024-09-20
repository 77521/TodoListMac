//
//  TodoEventDetails.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/7/9.
//

import SwiftUI

struct TodoEventDetails: View {
    @Binding var isShowingInspector: Bool
    var body: some View {
        Text("你好 赵浩")
    }
}

#Preview {
    TodoEventDetails(isShowingInspector: .constant(false))
}
