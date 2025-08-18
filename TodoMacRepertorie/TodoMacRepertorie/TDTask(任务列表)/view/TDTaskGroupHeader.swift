//
//  TDTaskGroupHeader.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/21.
//

import SwiftUI

struct TDTaskGroupHeader: View {
    let group: TDTaskGroupModel
    let taskCount: Int
    @StateObject private var themeManager = TDThemeManager.shared
    
    var body: some View {
        HStack {
            Text(group.title)
                .font(.system(size: 13))
                .foregroundColor(themeManager.descriptionTextColor)
            
            Spacer()
            
            Text("\(taskCount)")
                .font(.system(size: 12))
                .foregroundColor(themeManager.descriptionTextColor)
            
            Button(action: {
                // TODO: 组设置按钮点击事件
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(themeManager.descriptionTextColor)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
//    TDTaskGroupHeader(group: TDTaskGroupModel.today, taskCount: 1)
}
