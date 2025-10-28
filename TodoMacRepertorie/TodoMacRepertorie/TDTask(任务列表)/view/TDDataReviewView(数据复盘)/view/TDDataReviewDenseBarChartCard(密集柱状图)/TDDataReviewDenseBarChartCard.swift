//
//  TDDataReviewDenseBarChartCard.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/16.
//

import SwiftUI
import AAInfographics

/// 密集型柱状图卡片
struct TDDataReviewDenseBarChartCard: View {
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
            
            // 密集型柱状图
            ZStack {
                TDADenseBarChartView(
                    data: getChartData(),
                    xAxisLabels: getXAxisLabels()
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
    private func getChartData() -> [Double] {
        guard let chartList = item.chartList, !chartList.isEmpty else {
            return []
        }
        
        return chartList.map { $0.value }
    }
    
    /// 获取X轴标签
    private func getXAxisLabels() -> [String] {
        guard let chartList = item.chartList, !chartList.isEmpty else {
            return []
        }
        
        return chartList.map { $0.label }
    }
}

/// 使用 AAInfographics 库的密集型柱状图视图
struct TDADenseBarChartView: NSViewRepresentable {
    let data: [Double]
    let xAxisLabels: [String]
    @EnvironmentObject private var themeManager: TDThemeManager
    
    func makeNSView(context: Context) -> AAChartView {
        let chartView = AAChartView()
        chartView.isClearBackgroundColor = true
        chartView.shouldPrintOptionsJSON = false
        return chartView
    }
    
    func updateNSView(_ chartView: AAChartView, context: Context) {
        let aaOptions = createAAOptions()
        chartView.aa_drawChartWithChartOptions(aaOptions)
    }
    
    private func createAAOptions() -> AAOptions {
        // 获取最大值，如果为0则设为1
        var maxValue = data.max() ?? 0.0
        if maxValue == 0 {
            maxValue = 1.0
        }
        let yAxisMax = maxValue

        let blueStopsArr = [
            [0.0, AARgba(themeManager.color(level: 5).redComponent(), themeManager.color(level: 5).greenComponent(), themeManager.color(level: 5).blueComponent(), 0.6)],//颜色字符串设置支持十六进制类型和 rgba 类型
            [0.6, AARgba(themeManager.color(level: 5).redComponent(), themeManager.color(level: 5).greenComponent(), themeManager.color(level: 5).blueComponent(), 0.4)],
            [1.0, AARgba(themeManager.color(level: 5).redComponent(), themeManager.color(level: 5).greenComponent(), themeManager.color(level: 5).blueComponent(), 0.2)]
        ]
        let gradientBlueColorDic = AAGradientColor.linearGradient(
            direction: .toBottom,
            stops: blueStopsArr
        )

        
        let model = AAChartModel()
            .chartType(.column)
            .title("")
            .subtitle("")
            .borderRadius(8)
            .backgroundColor("transparent")
            .dataLabelsEnabled(false)
            .legendEnabled(false)
            .tooltipEnabled(true)
            .animationType(.easeInOutQuart)
            .animationDuration(1500)
            .xAxisLabelsEnabled(true)
            .yAxisLabelsEnabled(true)
            .xAxisGridLineWidth(0)
            .yAxisGridLineWidth(1)
            .yAxisLineWidth(0)
            .yAxisMin(0)
            .yAxisMax(yAxisMax)
            .categories(xAxisLabels)
            .xAxisTickInterval(1) // 强制显示所有X轴标签
            .dataLabelsEnabled(false)
            .series([
                AASeriesElement()
                    .data(data)
                    .color(gradientBlueColorDic)
                    .fillOpacity(0.3)
            ])

        let aaOptions = model.aa_toAAOptions()
        
        // 配置 X 轴虚线网格
        aaOptions.xAxis?
            .lineWidth(1.5)
            .lineColor(themeManager.separatorColor.toHexString())
            .gridLineDashStyle(.dash)
            .gridLineWidth(1)
            .gridLineColor(themeManager.borderColor.toHexString())
            .tickInterval(1) // 确保显示所有刻度
            .labels(
                AALabels()
                    .rotation(-50) // 旋转-45度，让文字倾斜显示
                    .style(AAStyle(color: themeManager.titleTextColor.toHexString()))
            )

        
        // 配置 Y 轴虚线网格
        aaOptions.yAxis?
            .opposite(false)
            .minRange(1)
            .gridLineDashStyle(.dash)
            .gridLineWidth(1)
            .gridLineColor(themeManager.borderColor.toHexString())
        
        // 配置自定义 Tooltip 样式
        let themeColor = themeManager.color(level: 5).opacity(0.8).toHexString()
        let headerFormat = "<span style=\"color:white;font-size:12px;padding:8px 12px;\">{point.x}&nbsp;&nbsp;&nbsp;&nbsp;{point.y}</span>"
        
        aaOptions.tooltip?
            .useHTML(true)
            .headerFormat(headerFormat.aa_toPureHTMLString())
            .style(AAStyle(color: AAColor.white, fontSize: 14))
            .backgroundColor(themeColor)
            .borderColor(themeColor)
            .pointFormat("")
            .footerFormat("")
            .valueDecimals(0) // 设置取值精确到小数点后几位
            .borderRadius(15)
            .borderWidth(0)
        
        return aaOptions
    }
}

/// 使用 AAInfographics 库的密集型柱状图视图
//struct TDADenseBarChartView: NSViewRepresentable {
//    let data: [Double]
//    let xAxisLabels: [String]
//    @EnvironmentObject private var themeManager: TDThemeManager
//    
//    func makeNSView(context: Context) -> AAChartView {
//        let chartView = AAChartView()
//        chartView.isClearBackgroundColor = true
//        return chartView
//    }
//    
//    func updateNSView(_ chartView: AAChartView, context: Context) {
//        let model = createAAChartModel()
//        chartView.aa_drawChartWithChartModel(model)
//    }
//    
//    private func createAAChartModel() -> AAChartModel {
//        return AAChartModel()
//            .chartType(.column)
//            .title("Colorful Gradient Chart")
//            .backgroundColor("#5E5E5E")
//            .categories(xAxisLabels)
//            .colorsTheme([
//                AAGradientColor.oceanBlue,
//                AAGradientColor.sanguine,
//                AAGradientColor.lusciousLime,
//                AAGradientColor.purpleLake,
//                AAGradientColor.freshPapaya,
//                AAGradientColor.ultramarine,
//                AAGradientColor.pinkSugar,
//                AAGradientColor.lemonDrizzle,
//                AAGradientColor.victoriaPurple,
//                AAGradientColor.springGreens,
//                AAGradientColor.mysticMauve,
//                AAGradientColor.reflexSilver,
//                AAGradientColor.newLeaf,
//                AAGradientColor.cottonCandy,
//                AAGradientColor.pixieDust,
//                AAGradientColor.fizzyPeach,
//                AAGradientColor.sweetDream,
//                AAGradientColor.firebrick,
//                AAGradientColor.wroughtIron,
//                AAGradientColor.deepSea,
//                AAGradientColor.coastalBreeze,
//                AAGradientColor.eveningDelight,
//            ] as [Any])
//            .stacking(.percent)
//            .xAxisLabelsStyle(AAStyle(color: AAColor.red))
//            .dataLabelsEnabled(false)
//            .series([
//                AASeriesElement()
//                    .name("")
//                    .data(data)
////                    .colorByPoint(true)
//            ])
//    }
//}


//#Preview {
//    TDDataReviewDenseBarChartCard(item: TDDataReviewModel(from: nil))
//}
