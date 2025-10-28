//
//  TDDataReviewPieChartCard.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/16.
//

import SwiftUI
import AAInfographics

/// 饼状图卡片
struct TDDataReviewPieChartCard: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    let item: TDDataReviewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            if let title = item.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.titleTextColor)
            }
            
            // 副标题
            if let subTitle = item.subTitle, !subTitle.isEmpty {
                Text(subTitle)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.descriptionTextColor)
            }
            
            // 饼状图
            ZStack {
                TDAPieChartView(
                    data: getChartData()
                )
                .frame(height: 300)
                
                // 透明遮罩，阻止滚动但允许 tooltip 显示
                Color.clear
                    .frame(height: 300)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // 空的手势处理，阻止滚动
                    }
            }
            
            // 信息文案
            if let summary = item.summary, !summary.isEmpty {
                Text(summary)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.descriptionTextColor)
                    .multilineTextAlignment(.leading)
                    .padding(.top, -10)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.separatorColor, lineWidth: 1)
                )
        )
    }
    
    /// 获取图表数据
    private func getChartData() -> [[Any]] {
        print("🍰 开始获取饼状图数据")
        print("🍰 item.chartList: \(item.chartList ?? [])")
        
        guard let chartList = item.chartList, !chartList.isEmpty else {
            print("⚠️ 饼状图数据为空或不存在，使用测试数据")
            // 返回测试数据用于调试
            return getTestChartData()
        }
        
        print("🍰 原始数据: \(chartList)")
        
        // 将比例值转换为百分比
        let chartData = chartList.map { chartItem in
            let label = chartItem.label
            let value = (chartItem.value * 100 * 10).rounded() / 10
            print("🍰 转换数据: \(label) -> \(value)")
            return [label, value] as [Any]
        }
        
        print("🍰 最终饼状图数据: \(chartData)")
        return chartData
    }
    
    /// 获取测试图表数据
    private func getTestChartData() -> [[Any]] {
        return [
            ["已完成", 60.0],
            ["未完成", 25.0]
        ]
    }
}

/// 使用 AAInfographics 库的饼状图视图
struct TDAPieChartView: NSViewRepresentable {
    let data: [[Any]]
    @EnvironmentObject private var themeManager: TDThemeManager
    
    func makeNSView(context: Context) -> AAChartView {
        let chartView = AAChartView()
        chartView.isClearBackgroundColor = true
        return chartView
    }
    
    func updateNSView(_ chartView: AAChartView, context: Context) {
        print("🍰 饼状图数据: \(data)")
        let aaOptions = createAAOptionsWithCustomLegend()
        chartView.aa_drawChartWithChartOptions(aaOptions)
    }
    
    private func createAAOptionsWithCustomLegend() -> AAOptions {
        print("🍰 创建饼状图配置，数据: \(data)")
        
        // 先创建基础的 AAChartModel
        let model = AAChartModel()
            .chartType(.pie)
        
            .title("")
            .subtitle("")
            .backgroundColor("transparent")
            .dataLabelsEnabled(true)
            .legendEnabled(true)
            .tooltipEnabled(true)
            .animationType(.easeInOutQuart)
            .animationDuration(1500)
            .colorsTheme([
                themeManager.fixedColor(themeId: "mars_green", level: 5).toHexString(),
                themeManager.fixedColor(themeId: "wish_orange", level: 5).toHexString()
            ])
            .series([
                AASeriesElement()
                    .name("数据")
                    .data(data)
                    .size(200)
            ])
        
        // 转换为 AAOptions
        let aaOptions = model.aa_toAAOptions()
//        
//        // 配置图例样式为长方形并居中对齐
//        aaOptions.legend?
////            .itemWidth(100)
////            .symbolHeight(6)  // 减少高度，形成长方形
//            .symbolRadius(0)  // 设置为0使标记变成矩形
//            .itemStyle(AAStyle()
//                .width(100)
//                .fontSize(30)
//                .lineWidth(100)
//                .background(Color.red.toHexString())
//            )
        
//            .symbolPadding(8) // 符号和文字之间的间距
//            .itemMarginTop(2) // 调整顶部边距

        return aaOptions
    }
}

//#Preview {
//    TDDataReviewPieChartCard()
//}
