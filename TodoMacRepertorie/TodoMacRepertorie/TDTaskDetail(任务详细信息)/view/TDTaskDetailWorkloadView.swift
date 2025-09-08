//
//  TDTaskDetailWorkloadView.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2024/12/28.
//

import SwiftUI

/// 工作量选择视图
struct TDTaskDetailWorkloadView: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    
    @Bindable var task: TDMacSwiftDataListModel
    // 工作量变化回调
    let onWorkloadChanged: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 工作量图标
                Image(systemName: "exclamationmark.shield")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.titleTextColor)
                
                // 工作量标签
                Text("工作量")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.titleTextColor)
                
                Spacer()
                
                // 自定义分段控制器
                HStack(spacing: 2) {
                    ForEach(0..<3) { index in
                        Button(action: {
                            // 判断当前 snowAssess 是否已经在目标范围内
                            let currentValue = task.snowAssess
                            var newValue: Int?
                            
                            switch index {
                            case 0: // 一般：1-4 (不包含5)
                                if currentValue < 5 {
                                    // 已经在一般范围内，不需要修改
                                    return
                                }
                                newValue = Int.random(in: 1..<5)
                                
                            case 1: // 中等难度：5-8 (不包含9)
                                if currentValue >= 5 && currentValue < 9 {
                                    // 已经在中等难度范围内，不需要修改
                                    return
                                }
                                newValue = Int.random(in: 5..<9)
                                
                            case 2: // 较高难度：9-20
                                if currentValue >= 9 {
                                    // 已经在较高难度范围内，不需要修改
                                    return
                                }
                                newValue = Int.random(in: 9...20)
                                
                            default: break
                            }
                            
                            // 如果有新值，通过回调传递给父组件
                            if let newValue = newValue {
                                onWorkloadChanged(newValue)
                            }
                            
                        }) {
                            Text(["一般", "中等难度", "较高难度"][index])
                                .font(.system(size: 12))
                                .foregroundStyle(getTextColor(for: index))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(
                            // 根据位置设置不同的圆角
                            getRoundedRectangle(for: index)
                                .fill(getBackgroundColor(for: index))
                        )
                    }
                }
                .frame(width: 200)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.white)
            
            // 分割线
            Rectangle()
                .fill(themeManager.descriptionTextColor.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 私有方法
        
    /// 根据 snowAssess 值判断当前按钮是否被选中
    private func isSelected(for index: Int) -> Bool {
        switch index {
        case 0: // 一般
            return task.snowAssess < 5
        case 1: // 中等难度
            return task.snowAssess >= 5 && task.snowAssess < 9
        case 2: // 较高难度
            return task.snowAssess >= 9
        default:
            return false
        }
    }
    
    /// 获取文字颜色
    private func getTextColor(for index: Int) -> Color {
        if isSelected(for: index) {
            return .white // 选中时都是白色
        } else {
            return themeManager.titleTextColor // 未选中时使用主题标题颜色
        }
    }
    
    /// 获取背景颜色
    private func getBackgroundColor(for index: Int) -> Color {
        let selected = isSelected(for: index)
        
        switch index {
        case 0: // 一般
            if selected {
                return Color.adaptive(light: "#C3C3C3", dark: "#797979")
            } else {
                return themeManager.tertiaryBackgroundColor
            }
            
        case 1: // 中等难度
            if selected {
                return themeManager.fixedColor(themeId: "wish_orange", level: 5) // 心想事橙 5 级 - 写死的
            } else {
                return Color.adaptive(light: "#F6F1EB", dark: "#303030")
            }
            
        case 2: // 较高难度
            if selected {
                return themeManager.fixedColor(themeId: "new_year_red", level: 5) // 新年红 5 级 - 写死的
            } else {
                return Color.adaptive(light: "#F8E8E8", dark: "#303030")
            }
            
        default:
            return themeManager.backgroundColor
        }
    }
    
    /// 根据按钮位置获取圆角矩形
    private func getRoundedRectangle(for index: Int) -> UnevenRoundedRectangle {
        switch index {
        case 0: // 一般 - 只有左上左下圆角
            return UnevenRoundedRectangle(
                topLeadingRadius: 6,
                bottomLeadingRadius: 6,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
        case 1: // 中等难度 - 无圆角
            return UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
        case 2: // 较高难度 - 只有右上右下圆角
            return UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 6,
                topTrailingRadius: 6
            )
        default:
            return UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
        }
    }

}

#Preview {
    let sampleTask = TDMacSwiftDataListModel(
        id: 1,
        taskId: "test",
        taskContent: "测试任务",
        taskDescribe: nil,
        complete: false,
        createTime: 0,
        delete: false,
        reminderTime: 0,
        snowAdd: 0,
        snowAssess: 1, // 中等难度
        standbyInt1: 0,
        standbyStr1: nil,
        standbyStr2: nil,
        standbyStr3: nil,
        standbyStr4: nil,
        syncTime: 0,
        taskSort: 0,
        todoTime: 0,
        userId: 1,
        version: 1,
        status: "sync",
        isSubOpen: false,
        standbyIntColor: "",
        standbyIntName: "",
        reminderTimeString: "",
        subTaskList: [],
        attachmentList: []
    )
    
    TDTaskDetailWorkloadView(
        task: sampleTask,
        onWorkloadChanged: { newValue in
            print("工作量变化: \(newValue)")
        }
    )
        .environmentObject(TDThemeManager.shared)
}
