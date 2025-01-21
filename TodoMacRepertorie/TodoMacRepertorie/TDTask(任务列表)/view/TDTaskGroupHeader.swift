//
//  TDTaskGroupHeader.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/21.
//

import SwiftUI

struct TDTaskGroupHeader: View {
    let group: TDTaskGroup
    let taskCount: Int
    @StateObject private var themeManager = TDThemeManager.shared
    
    var body: some View {
        HStack {
            Text(group.title)
                .font(.system(size: 13))
                .foregroundColor(themeManager.secondaryTextColor)
            
            Spacer()
            
            Text("\(taskCount)")
                .font(.system(size: 12))
                .foregroundColor(themeManager.secondaryTextColor)
            
            Button(action: {
                // TODO: 组设置按钮点击事件
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    TDTaskGroupHeader(group: TDTaskGroup.today, taskCount: 1)
}
