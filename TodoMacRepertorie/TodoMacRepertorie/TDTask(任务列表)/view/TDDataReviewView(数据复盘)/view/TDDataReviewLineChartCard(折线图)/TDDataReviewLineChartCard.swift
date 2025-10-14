//
//  TDDataReviewLineChartCard.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/14.
//

import SwiftUI
import Charts

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
            
            // 折线图
            LineChartView(data: getChartData())
                .frame(height: 200)
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
    private func getChartData() -> [ChartDataPoint] {
        guard let chartList = item.chartList, !chartList.isEmpty else {
            return []
        }
        
        return chartList.enumerated().map { index, chartData in
            ChartDataPoint(
                x: index,
                y: chartData.value,
                label: chartData.label
            )
        }
    }
}

/// 图表数据点
struct ChartDataPoint: Identifiable, Equatable {
    let id = UUID()
    let x: Int
    let y: Double
    let label: String
    
    static func == (lhs: ChartDataPoint, rhs: ChartDataPoint) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.label == rhs.label
    }
}

/// 折线图视图
struct LineChartView: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        Chart(data) { point in
            // 填充区域
            AreaMark(
                x: .value("时间", point.x),
                y: .value("数值", point.y)
            )
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
            
            // 折线
            LineMark(
                x: .value("时间", point.x),
                y: .value("数值", point.y)
            )
            .foregroundStyle(Color.blue)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)
            
            // 数据点
            PointMark(
                x: .value("时间", point.x),
                y: .value("数值", point.y)
            )
            .foregroundStyle(Color.blue)
            .symbolSize(24)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                if let xValue = value.as(Int.self),
                   xValue < data.count {
                    AxisValueLabel {
                        Text(data[xValue].label)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .rotationEffect(.degrees(-45))
                    }
                }
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.2))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: getYAxisValues()) { value in
                AxisValueLabel {
                    if let yValue = value.as(Double.self) {
                        Text(String(format: "%.0f", yValue))
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.2))
            }
        }
        .chartYScale(domain: 0...getYAxisMax())
        .animation(.easeInOut(duration: 1.5), value: data)
    }
    
    /// 获取Y轴最大值
    private func getYAxisMax() -> Double {
        guard !data.isEmpty else { return 1.0 }
        
        let maxValue = data.map { $0.y }.max() ?? 0.0
        
        // 如果是整数，则 +1，否则向上取整
        if maxValue == floor(maxValue) {
            return maxValue + 1.0
        } else {
            return ceil(maxValue)
        }
    }
    
    /// 获取Y轴分界点值
    private func getYAxisValues() -> [Double] {
        let maxValue = getYAxisMax()
        let dataCount = data.count
        
        if maxValue <= 8 {
            // 如果最大值不超过8，显示8行（0-8）
            return Array(stride(from: 0, through: 8, by: 1))
        } else {
            // 如果最大值超过8，根据数组总数显示，最多8行
            let stepCount = min(dataCount, 8)
            let step = maxValue / Double(stepCount - 1)
            return (0..<stepCount).map { Double($0) * step }
        }
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
