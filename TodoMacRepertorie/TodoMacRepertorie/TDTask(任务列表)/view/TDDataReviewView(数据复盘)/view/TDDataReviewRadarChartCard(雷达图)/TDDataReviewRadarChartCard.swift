//
//  TDDataReviewRadarChartCard.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/17.
//

import SwiftUI
import AAInfographics

/// 雷达图卡片
struct TDDataReviewRadarChartCard: View {
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
            
            // 雷达图
            ZStack {
                TDARadarChartView(
                    data: getChartData().data,
                    labels: getChartData().labels
                )
                .frame(height: 400)
                .contentShape(Rectangle())

                // 透明遮罩，阻止滚动但允许 tooltip 显示
                Color.clear
                    .frame(height: 400)
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
    private func getChartData() -> (data: [Double], labels: [String]) {
        print("📊 开始获取雷达图数据")
        print("📊 item.chartList: \(item.chartList ?? [])")
        
        guard let chartList = item.chartList, !chartList.isEmpty else {
            print("⚠️ 雷达图数据为空或不存在，使用测试数据")
            // 返回测试数据用于调试
            return getTestChartData()
        }
        
        print("📊 原始数据: \(chartList)")
        
        // 提取标签和数值
        let labels = chartList.map { $0.label }
        let data = chartList.map { $0.value } // 直接使用原始值，不转换
        
        print("📊 标签: \(labels)")
        print("📊 数值: \(data)")
        
        return (data: data, labels: labels)
    }
    
    /// 获取测试图表数据
    private func getTestChartData() -> (data: [Double], labels: [String]) {
        return (data: [17.0, 16.9, 12.5], labels: ["勤劳", "堕落", "一般"])
    }
}

/// 使用 AAInfographics 库的雷达图视图
struct TDARadarChartView: NSViewRepresentable {
    let data: [Double]
    let labels: [String]
    @EnvironmentObject private var themeManager: TDThemeManager
    
    func makeNSView(context: Context) -> AAChartView {
        let chartView = AAChartView()
        chartView.isClearBackgroundColor = true
        return chartView
    }
    
    func updateNSView(_ chartView: AAChartView, context: Context) {
        print("📊 雷达图数据: \(data)")
        print("📊 雷达图标签: \(labels)")
        let aaOptions = createAAOptionsWithCustomRadar()
        chartView.aa_drawChartWithChartOptions(aaOptions)
    }
    
    private func createAAOptionsWithCustomRadar() -> AAOptions {
        print("📊 创建雷达图配置，数据: \(data)")
        print("📊 创建雷达图配置，标签: \(labels)")
        
        // 计算最大值，用于设置Y轴范围
        let maxValue = max(data.max() ?? 0, 10.0)
        let yAxisMax = maxValue + 2 // 留一些余量
        
        // 先创建基础的 AAChartModel
        let model = AAChartModel()
            .chartType(.area)
            .backgroundColor("transparent")
            .markerRadius(4) // 显示数据点
            .yAxisMax(yAxisMax)
            .yAxisGridLineWidth(1)
            .polar(true)
            .legendEnabled(false)
            .tooltipEnabled(true)
            .xAxisGridLineWidth(1)
            .yAxisGridLineWidth(1)
            .dataLabelsEnabled(true)
            .categories(labels) // 设置X轴标签
            .series([
                AASeriesElement()
                    .name("数据")
                    .color(themeManager.fixedColor(themeId: "mars_green", level: 5).toHexString())
                    .fillOpacity(0.3)
                    .dataLabels(AADataLabels()
                        .enabled(true)
//                        .color(themeManager.fixedColor(themeId: "mars_green", level: 5).toHexString())
                    )
                    .data(data)
            ])
        
        // 转换为 AAOptions
        let aaOptions = model.aa_toAAOptions()
        
        // 配置 X 轴（雷达图的轴线）
        aaOptions.xAxis?
            .tickInterval(1)
            .lineWidth(0) // 避免多边形外环之外有额外套了一层无用的外环
            .gridLineWidth(0) // 隐藏轴线
            .gridLineColor(themeManager.fixedColor(themeId: "mars_green", level: 5).opacity(0.6).toHexString())
            .crosshair(AACrosshair()
                .width(1.5)
                .color(themeManager.fixedColor(themeId: "mars_green", level: 5).toHexString())
                .dashStyle(.longDashDotDot))
        
        // 配置 Y 轴（雷达图的网格）
        aaOptions.yAxis?
            .gridLineInterpolation("polygon")
            .lineWidth(0)
            .gridLineColor(themeManager.fixedColor(themeId: "mars_green", level: 5).toHexString())
            .crosshair(AACrosshair()
                .width(1.5)
                .color(themeManager.fixedColor(themeId: "mars_green", level: 5).toHexString())
                .dashStyle(.longDashDotDot))
            .tickPositions([0, yAxisMax/4, yAxisMax/2, yAxisMax*3/4, yAxisMax])
            .labels(AALabels()
                .enabled(false)) // 隐藏Y轴标签

        
        // 配置渐变背景色带
        let aaPlotBandsArr = [
            AAPlotBandsElement()
                .from(0)
                .to(yAxisMax/5)
                .color(themeManager.fixedColor(themeId: "mars_green", level: 5).toHexString()),
            AAPlotBandsElement()
                .from(yAxisMax/5)
                .to(yAxisMax*2/5)
                .color(themeManager.fixedColor(themeId: "mars_green", level: 5).opacity(0.8).toHexString()),
            AAPlotBandsElement()
                .from(yAxisMax*2/5)
                .to(yAxisMax*3/5)
                .color(themeManager.fixedColor(themeId: "mars_green", level: 5).opacity(0.6).toHexString()),
            AAPlotBandsElement()
                .from(yAxisMax*3/5)
                .to(yAxisMax*4/5)
                .color(themeManager.fixedColor(themeId: "mars_green", level: 5).opacity(0.4).toHexString()),
            AAPlotBandsElement()
                .from(yAxisMax*4/5)
                .to(yAxisMax)
                .color(themeManager.fixedColor(themeId: "mars_green", level: 5).opacity(0.2).toHexString()),
        ]
        
        let aaYAxis = aaOptions.yAxis
//        aaYAxis?.plotBands = aaPlotBandsArr
        
        return aaOptions
    }
}
