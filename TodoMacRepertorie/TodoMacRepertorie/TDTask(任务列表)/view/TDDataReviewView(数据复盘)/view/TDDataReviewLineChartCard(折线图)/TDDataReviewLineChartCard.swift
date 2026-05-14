//
//  TDDataReviewLineChartCard.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/14.
//

import SwiftUI
import AAInfographics
import AppKit

/// 折线图卡片
struct TDDataReviewLineChartCard: View {
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
            // 折线图
            ZStack {
                TDAAChartView(
                    data: getChartData(),
                    xAxisLabels: getXAxisLabels()
                )
                .frame(height: 200)
                
                // 透明遮罩，阻止滚动但允许 tooltip 显示
                Color.clear
                    .frame(height: 200)
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
//                // 假的测试文案
//                Text("这是测试文案，展示工作量趋势分析结果。数据显示最近8天的工分析结果。数据显示最近8天的工分析结果。数据显示最近8天的工分析结果。数据显示最近8天的工分析结果。数据显示最近8天的工分析结果。数据显示最近8天的工分析结果。数据显示最近8天的工分析结果。数据显示最近8天的工作量变化情况，整体呈现稳定上升趋势。")
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

/// 使用 AAInfographics 库的折线图视图
struct TDAAChartView: NSViewRepresentable {
    let data: [Double]
    let xAxisLabels: [String]
    @EnvironmentObject private var themeManager: TDThemeManager
    
    func makeNSView(context: Context) -> AAChartView {
        let chartView = AAChartView()
        chartView.isClearBackgroundColor = true
//        chartView.shouldPrintOptionsJSON = false
        return chartView
    }
    
    func updateNSView(_ chartView: AAChartView, context: Context) {
        let aaOptions = createAAOptions()
        chartView.aa_drawChartWithChartOptions(aaOptions)
    }
    
    private func createAAOptions() -> AAOptions {
        // 获取最大值
        let maxValue = data.max() ?? 0.0
        
        // 计算 Y 轴最大值和最小值
        var yAxisMax: Double
        var yAxisMin: Double = 0
        
        if maxValue > 12 {
            yAxisMax = maxValue
        } else {
            if maxValue == 0 {
                yAxisMax = 1.0
            } else {
                yAxisMax = maxValue
            }
        }
        
        // 设置最小值
        if maxValue == 0 {
            yAxisMin = -1
        } else {
            yAxisMin = 0
        }
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
            .chartType(.areaspline)
            .title("")
            .subtitle("")
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
//            .yAxisLineWidth(0)
            .yAxisMax(yAxisMax)
            .yAxisMin(yAxisMin)
            .colorsTheme([themeManager.color(level: 5).opacity(0.5).toHexString()])
            .categories(xAxisLabels)
            .zoomType(.none) // 禁用缩放和滑动
            .series([
                AASeriesElement()
                    .data(data)
                    .lineWidth(2)
                    .color(themeManager.color(level: 5).opacity(0.2).toHexString())
                    .fillColor(gradientBlueColorDic)
                    .fillOpacity(0.3)
                    .marker(
                        AAMarker()
                            .radius(4)
                            .fillColor(themeManager.color(level: 5).toHexString())
                            .lineWidth(1)
                    )
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
// MARK: - 预览
//#Preview {
//    TDDataReviewLineChartCard(
//        item: TDDataReviewModel(
//            modelType: 3,
//            title: "番茄专注时长趋势 (每月)",
//            chartList: [
//                TDChartData(value: 0, label: "00:00:00"),
//                TDChartData(value: 0, label: "01:00:00"),
//                TDChartData(value: 0, label: "02:00:00"),
//                TDChartData(value: 0, label: "03:00:00"),
//                TDChartData(value: 0, label: "04:00:00"),
//                TDChartData(value: 0, label: "05:00:00"),
//                TDChartData(value: 0, label: "06:00:00"),
//                TDChartData(value: 0, label: "07:00:00"),
//                TDChartData(value: 0, label: "08:00:00"),
//                TDChartData(value: 0, label: "09:00:00"),
//                TDChartData(value: 1000, label: "10:00:00"),
//                TDChartData(value: 800, label: "11:00:00"),
//                TDChartData(value: 1000, label: "12:00:00"),
//                TDChartData(value: 1000, label: "13:00:00"),
//                TDChartData(value: 1000, label: "14:00:00"),
//                TDChartData(value: 1000, label: "15:00:00"),
//                TDChartData(value: 600, label: "16:00:00"),
//                TDChartData(value: 800, label: "17:00:00"),
//                TDChartData(value: 0, label: "18:00:00"),
//                TDChartData(value: 400, label: "19:00:00"),
//                TDChartData(value: 0, label: "20:00:00"),
//                TDChartData(value: 600, label: "21:00:00"),
//                TDChartData(value: 800, label: "22:00:00"),
//                TDChartData(value: 1000, label: "23:00:00")
//            ]
//        )
//    )
//    .environmentObject(TDThemeManager.shared)
//    .environmentObject(TDSettingManager.shared)
//    .padding()
//}
