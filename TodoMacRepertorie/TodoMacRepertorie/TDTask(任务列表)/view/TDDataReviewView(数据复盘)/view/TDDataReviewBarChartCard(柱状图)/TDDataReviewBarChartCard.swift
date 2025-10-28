//
//  TDDataReviewBarChartCard.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/16.
//

import SwiftUI

import AAInfographics

struct TDDataReviewBarChartCard: View {
    @EnvironmentObject private var themeManager: TDThemeManager
    let item: TDDataReviewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题和副标题
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
            // 柱状图
            ZStack {
                TDAABarChartView(
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
                    .padding(.top,-10)
            }
//            else {
//                // 假的测试文案的
//                Text("这是测试文案，展示周几最勤奋分析结果。数据显示周三奋分析结果。数据显示周三奋分析结果。数据显示周三奋分析结果。数据显示周三奋分析结果。数据显示周三奋分析结果。数据显示周三奋分析结果。数据显示周三的工作量最高，周五的工作量最低。")
//                    .font(.system(size: 12))
//                    .foregroundColor(themeManager.descriptionTextColor)
//                    .multilineTextAlignment(.leading)
//                    .padding(.top,-10)
//            }
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
    
    private func getChartData() -> [Double] {
        guard let chartList = item.chartList, !chartList.isEmpty else { return [] }
        return chartList.map { $0.value }
    }
    
    private func getXAxisLabels() -> [String] {
        guard let chartList = item.chartList, !chartList.isEmpty else { return [] }
        return chartList.map { $0.label }
    }
}

struct TDAABarChartView: NSViewRepresentable {
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
            .borderRadius(15)
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
            .colorsTheme([themeManager.color(level: 5).opacity(0.5).toHexString()])
            .categories(xAxisLabels)
            .zoomType(.none) // 禁用缩放和滑动
            .series([
                AASeriesElement()
                    .data(data)
                    .color(gradientBlueColorDic)
                    .fillOpacity(0.3)

            ])
        
        let aaOptions = model.aa_toAAOptions()
        
        // 配置 Y 轴虚线网格
        aaOptions.yAxis?
            .opposite(false)
            .minRange(1)
            .gridLineDashStyle(.dash)
            .gridLineWidth(1)
            .gridLineColor(themeManager.borderColor.toHexString())
        // 配置 X 轴线
        aaOptions.xAxis?
            .lineWidth(1.5)
            .lineColor(themeManager.separatorColor.toHexString())
        
//        // 配置自定义 Tooltip 样式
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

//// MARK: - 预览
//#Preview {
//    TDDataReviewBarChartCard(
//        item: TDDataReviewModel(
//            id: "1",
//            title: "周几最勤奋",
//            subTitle: "展示了这段时间里,你在周一至周日的工作量分布",
//            modelType: 4,
//            layoutId: 0,
//            chartList: [
//                TDChartData(label: "周三", value: 34),
//                TDChartData(label: "周四", value: 19),
//                TDChartData(label: "周五", value: 9),
//                TDChartData(label: "周六", value: 13),
//                TDChartData(label: "周日", value: 10),
//                TDChartData(label: "周一", value: 20),
//                TDChartData(label: "周二", value: 20)
//            ],
//            summary: nil
//        )
//    )
//    .environmentObject(TDThemeManager.shared)
//    .frame(width: 400, height: 300)
//}
