//
//  TDMacWidgetBundle.swift
//  TDMacWidget
//
//  Created by 赵浩 on 2025/5/7.
//

import WidgetKit
import SwiftUI
import SwiftData

@main
struct TDMacWidgetBundle: WidgetBundle {
    var body: some Widget {
        // 列表格式
        TDMacWidgetListModeWidget()
//         //日程概览：周视图(中) / 月视图(大/超大)
        TDMacWidgetScheduleOverviewWidget()
        
        // 月历日清单：左月历点选，右侧 DayTodo
        TDMacWidgetMonthDayListWidget()

    }
}
