import WidgetKit
import SwiftUI
import AppIntents

private struct TDWidgetFocusEntry: TimelineEntry {
    let date: Date
    let isLoggedIn: Bool
    let phase: TDFocusSessionStore.Phase
    /// 倒计时区间（idle 为 nil）
    let timerInterval: (start: Date, end: Date)?
    /// 今日收成（番茄数）
    let todayTomatoNum: Int
}

private struct TDWidgetFocusProvider: TimelineProvider {
    func placeholder(in context: Context) -> TDWidgetFocusEntry {
        TDWidgetFocusEntry(date: .now, isLoggedIn: false, phase: .idle, timerInterval: nil, todayTomatoNum: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (TDWidgetFocusEntry) -> Void) {
        completion(TDWidgetFocusEntry(date: .now, isLoggedIn: TDWidgetUserSession.currentUser() != nil, phase: .idle, timerInterval: nil, todayTomatoNum: 0))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TDWidgetFocusEntry>) -> Void) {
        Task { @MainActor in
            let now = Date()
            let user = TDWidgetUserSession.currentUser()
            if let user {
                // 让共享的 TDUserManager 在 Widget 进程里也有 token/userId（网络与 SwiftData 依赖它）
                TDUserManager.shared.currentUser = user
                TDUserManager.shared.currentUserId = user.userId
            }

            // 关键：无人值守时（仅 Widget 在跑）也要推进阶段并完成同步
            _ = await TDFocusSessionStore.shared.advanceIfNeeded(now: now)

            let store = TDFocusSessionStore.shared
            store.refreshFromDefaults()
            let phase = store.state.phase
            let interval = store.currentTimerInterval(now: now).map { ($0.start, $0.end) }
            let todayTomatoNum: Int = {
                guard user != nil else { return 0 }
                // 读取 AppGroup 本地缓存（主 App 已负责拉取并写入）
                return TDTomatoManager.shared.getTodayTomato()?.tomatoNum ?? 0
            }()

            let entry = TDWidgetFocusEntry(
                date: now,
                isLoggedIn: user != nil,
                phase: phase,
                timerInterval: interval.map { (start: $0.0, end: $0.1) },
                todayTomatoNum: todayTomatoNum
            )

            // 让系统在阶段结束时回调 provider，以便我们推进到下一阶段/完成并同步
            let nextRefresh: Date = {
                if let interval = interval {
                    // 防御：避免“过去时间”导致疯狂刷新
                    return max(interval.1, now.addingTimeInterval(3))
                }
                return Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(15 * 60)
            }()

            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }
}

private struct TDWidgetFocusView: View {
    let entry: TDWidgetFocusEntry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    private var isDark: Bool { colorScheme == .dark }
    private var adaptiveChipForeground: Color {
        TDWidgetAdaptiveStyle.chipForeground(renderingMode: widgetRenderingMode)
    }

    private var statusText: String {
        switch entry.phase {
        case .idle:
            return "番茄专注"
        case .focusing:
            return "专注中"
        case .resting:
            return "休息中"
        }
    }

    private var buttonTitle: String {
        switch entry.phase {
        case .idle:
            return "开始专注"
        case .focusing:
            return "放弃专注"
        case .resting:
            return "放弃休息"
        }
    }

    private var buttonIcon: String {
        switch entry.phase {
        case .idle:
            return "play.fill"
        case .focusing, .resting:
            return "stop.fill"
        }
    }

    private var buttonColor: Color {
        switch entry.phase {
        case .idle:
            return TDThemeManager.shared.primaryTintColor(isDark: isDark)
        case .focusing:
            return TDThemeManager.shared.fixedColor(themeId: "new_year_red", level: 5)
        case .resting:
            return TDThemeManager.shared.fixedColor(themeId: "wish_orange", level: 5)
        }
    }

    private var timeText: some View {
        Group {
            if let interval = entry.timerInterval {
                // 秒级动态倒计时：无需频繁刷新 timeline
                Text(timerInterval: interval.start...interval.end, countsDown: true)
                    .monospacedDigit()
            } else {
                let seconds = max(0, TDSettingManager.shared.focusDuration * 60)
                Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                    .monospacedDigit()
            }
        }
        .font(.system(size: 30, weight: .medium))
        .foregroundColor(TDThemeManager.shared.currentTheme.baseColors.titleText.color(isDark: isDark))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    private func openAppURL() -> URL {
        // 点击空白区：只打开 App（单窗口复用由主 App handlesExternalEvents 保证）
        URL(string: "todomac://widget?categoryId=-100")!
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(statusText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }

            timeText

            Button(intent: TDWidgetFocusToggleIntent()) {
                HStack(spacing: 8) {
                    Image(systemName: buttonIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tint)
                        .widgetAccentable()
                    Text(buttonTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tint)
                        .widgetAccentable()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                // 对齐 iOS：fullColor 用主题色；否则用 secondary 透明底
                .background(
                    TDWidgetAdaptiveStyle.chipBackground(base: buttonColor, renderingMode: widgetRenderingMode)
                )
            }
            // 关键：在非 fullColor 模式下，系统会改变渲染策略；用 tint 驱动文字颜色避免“变透明后看不见”
            .tint(TDWidgetAdaptiveStyle.chipTint(renderingMode: widgetRenderingMode))
            .buttonStyle(.plain)

            Text("今日收成：\(entry.todayTomatoNum)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(14)
        .widgetURL(openAppURL())
        .containerBackground(for: .widget) {
            isDark ? Color.black.opacity(0.25) : Color.white
        }
    }
}

struct TDMacWidgetFocusWidget: Widget {
    let kind: String = TDWidgetKind.focus

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TDWidgetFocusProvider()) { entry in
            TDWidgetFocusView(entry: entry)
        }
        .configurationDisplayName("番茄专注")
        .description("快速开始/结束番茄专注，进度与主 App 实时同步。")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

