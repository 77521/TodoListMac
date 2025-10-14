//
//  TDDataReviewItem.swift
//  TodoMacRepertorie
//
//  Created by 赵浩 on 2025/10/14.
//

import Foundation

/// 数据复盘数据项模型
struct TDDataReviewModel: Codable {
    let modelType: Int          // 模型类型：1-图文卡片，2-双列统计，3-折线图，4-柱状图，5-圆饼图，6-雷达图，88-未开通VIP，-100-热力图
    let layoutId: Int?          // 布局ID：0-左边图标右边文字，1-居中大字和副标题
    let title: String?          // 标题
    let subTitle: String?       // 副标题
    let content: String?        // 内容文本
    let summary: String?        // 总结
    let imageUrl: String?       // 图片URL
    let jumpUrl: String?        // 跳转URL
    let backColor: String?      // 背景颜色
    let tomato: Bool?             // 番茄数量
    
    // 双数据卡片字段
    let leftTitle: String?      // 左侧标题
    let leftContent: String?    // 左侧内容
    let leftDataExplain: String? // 左侧数据说明
    let leftDataRate: String?   // 左侧数据比率
    let leftBackColor: String?  // 左侧背景颜色
    let rightTitle: String?     // 右侧标题
    let rightContent: String?   // 右侧内容
    let rightDataExplain: String? // 右侧数据说明
    let rightDataRate: String?  // 右侧数据比率
    let rightBackColor: String? // 右侧背景颜色
    
    // 图表数据字段
    let chartList: [TDChartData]? // 图表数据列表
    
    // MARK: - 计算属性
    
    /// 是否为图文卡片
    var isImageTextCard: Bool {
        return modelType == 1
    }
    
    /// 是否为双列统计
    var isDualColumnStats: Bool {
        return modelType == 2
    }
    
    /// 是否为折线图
    var isLineChart: Bool {
        return modelType == 3
    }
    
    /// 是否为柱状图
    var isBarChart: Bool {
        return modelType == 4
    }
    
    /// 是否为圆饼图
    var isPieChart: Bool {
        return modelType == 5
    }
    
    /// 是否为雷达图
    var isRadarChart: Bool {
        return modelType == 6
    }
    
    /// 是否为未开通VIP卡片
    var isNoVipCard: Bool {
        return modelType == 88
    }
    
    /// 是否为热力图
    var isHeatMap: Bool {
        return modelType == -100
    }
    
    /// 是否为图表类型
    var isChartType: Bool {
        return modelType >= 3 && modelType <= 6
    }
    
    /// 是否为图文卡片且左边图标右边文字布局
    var isImageTextCardWithIcon: Bool {
        return modelType == 1 && layoutId == 0
    }
    
    /// 是否为图文卡片且居中大字和副标题布局
    var isImageTextCardWithCenterTitle: Bool {
        return modelType == 1 && layoutId == 1
    }
    
    /// 是否为柱状图且普通样式
    var isBarChartNormal: Bool {
        return modelType == 4 && layoutId == 0
    }
    
    /// 是否为柱状图且密集型样式
    var isBarChartDense: Bool {
        return modelType == 4 && layoutId == 1
    }
}

/// 图表数据模型
struct TDChartData: Codable {
    let label: String    // 标签（日期或时间）
    let value: Double       // 数值
}



// MARK: - 数据复盘统计类型

/// 数据复盘统计类型
enum TDDataReviewStatType: String, CaseIterable {
    case yesterday = "昨日小结"    // 昨日小结
    case events = "事件统计"      // 事件统计
    case tomato = "番茄统计"      // 番茄统计
    case weekly = "周报"         // 周报
    
    /// 统计类型描述
    var description: String {
        return self.rawValue
    }
    
    /// 对应的API端点
    var apiEndpoint: String {
        switch self {
        case .yesterday:
            return "getReportYesterdaySummary"
        case .events:
            return "getReportTask"
        case .tomato:
            return "getReportTomato"
        case .weekly:
            return "getReportWeek"
        }
    }
}

// MARK: - 数据复盘时间范围

/// 数据复盘时间范围
enum TDDataReviewTimeRange: String, CaseIterable {
    case sevenDays = "最近 7 天"      // 最近7天
    case thirtyDays = "最近 30 天"    // 最近30天
    case threeMonths = "最近 3 月"   // 最近3个月
    case sixMonths = "最近半年"      // 最近半年
    case oneYear = "最近一年"        // 最近一年
    case custom = "自定义范围"        // 自定义范围
    
    /// 时间范围描述
    var description: String {
        return self.rawValue
    }
    
    /// 获取时间范围的开始日期时间戳
    func getStartTimestamp() -> Int64 {
        let today = Date()
        
        switch self {
        case .sevenDays:
            return today.subtracting(days: 7).startOfDayTimestamp
        case .thirtyDays:
            return today.subtracting(days: 30).startOfDayTimestamp
        case .threeMonths:
            return today.subtracting(months: 3).startOfDayTimestamp
        case .sixMonths:
            return today.subtracting(months: 6).startOfDayTimestamp
        case .oneYear:
            return today.subtracting(years: 1).startOfDayTimestamp
        case .custom:
            // 自定义范围，暂时返回30天前
            return today.subtracting(days: 30).startOfDayTimestamp
        }
    }
    
    /// 获取时间范围的结束日期时间戳
    func getEndTimestamp() -> Int64 {
        return Date().endOfDayTimestamp
    }
}

/// 周报时间范围
enum TDDataReviewWeekRange: String, CaseIterable {
    case lastWeek = "上周"           // 上周
    case twoWeeksAgo = "上上周"       // 上上周
    case threeWeeksAgo = "上上上周"   // 上上上周
    
    /// 时间范围描述
    var description: String {
        return self.rawValue
    }
    
    /// 获取周报时间范围的开始时间戳
    func getStartTimestamp() -> Int64 {
        let today = Date()
        let calendar = Calendar.current
        let isFirstDayMonday = TDSettingManager.shared.isFirstDayMonday
        
        var targetWeekStart: Date
        
        switch self {
        case .lastWeek:
            // 上周
            targetWeekStart = getWeekStart(for: today.adding(days: -7), isFirstDayMonday: isFirstDayMonday)
        case .twoWeeksAgo:
            // 上上周
            targetWeekStart = getWeekStart(for: today.adding(days: -14), isFirstDayMonday: isFirstDayMonday)
        case .threeWeeksAgo:
            // 上上上周
            targetWeekStart = getWeekStart(for: today.adding(days: -21), isFirstDayMonday: isFirstDayMonday)
        }
        
        return targetWeekStart.startOfDayTimestamp
    }
    
    
    /// 获取周报时间范围的结束时间戳
    func getEndTimestamp() -> Int64 {
        let startTimestamp = getStartTimestamp()
        let startDate = Date.fromTimestamp(startTimestamp)
        let endDate = startDate.adding(days: 6) // 一周7天
        return endDate.endOfDayTimestamp
    }
    
    /// 获取周报时间范围的开始日期
    func getStartDate() -> Date {
        let startTimestamp = getStartTimestamp()
        return Date.fromTimestamp(startTimestamp)
    }
    
    /// 获取周报时间范围的结束日期
    func getEndDate() -> Date {
        let endTimestamp = getEndTimestamp()
        return Date.fromTimestamp(endTimestamp)
    }
    
    /// 获取周报时间范围的显示文本（如：25.10.5-25.10.11）
    func getDisplayText() -> String {
        let startDate = getStartDate()
        let endDate = getEndDate()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yy.M.d"
        
        let startText = formatter.string(from: startDate)
        let endText = formatter.string(from: endDate)
        
        return "\(startText)-\(endText)"
    }
    
    /// 获取指定日期所在周的开始日期
    private func getWeekStart(for date: Date, isFirstDayMonday: Bool) -> Date {
        let calendar = Calendar.current
        var weekStart = date
        
        if isFirstDayMonday {
            // 周一开始
            let weekday = calendar.component(.weekday, from: date)
            let daysFromMonday = (weekday + 5) % 7 // 计算距离周一的天数
            weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: date) ?? date
        } else {
            // 周日开始
            let weekday = calendar.component(.weekday, from: date)
            let daysFromSunday = (weekday == 1) ? 0 : (weekday - 1) // 计算距离周日的天数
            weekStart = calendar.date(byAdding: .day, value: -daysFromSunday, to: date) ?? date
        }
        
        return weekStart
    }
}
