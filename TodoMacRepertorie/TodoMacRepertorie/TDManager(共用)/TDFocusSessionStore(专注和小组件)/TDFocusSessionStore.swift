import Foundation
import OSLog
import SwiftData

/// 主 App 与 Widget 共享的番茄专注会话（存储于 AppGroup UserDefaults）
///
/// 设计目标：
/// - App / Widget 任意一端开始或结束，都写同一份状态 -> 另一端必然同步
/// - Widget 没放出时，后续添加也能从状态“接上进度”
/// - 如果只靠 Widget 跑完流程：会创建记录并同步服务器
/// - 如果 App 与 Widget 同时存在：以 owner 规则保证只同步一次（owner=app 优先）
@MainActor
final class TDFocusSessionStore: ObservableObject {
    static let shared = TDFocusSessionStore()

    private let logger = Logger(subsystem: "com.Mac.Todolist.TodoMacRepertorie", category: "TDFocusSessionStore")

    enum Phase: String, Codable {
        case idle
        case focusing
        case resting
    }

    enum Owner: String, Codable {
        case app
        case widget
    }

    struct State: Codable, Equatable {
        var phase: Phase
        var owner: Owner

        /// 本次番茄记录的唯一 ID（用于去重插入/去重同步）
        var tomatoId: String?

        /// 关联任务（允许为空）
        var taskId: String?
        var taskContent: String?

        /// 专注阶段
        var focusStartMs: Int64?
        var focusEndMs: Int64?
        var focusDurationSec: Int
        var focusSuccess: Bool

        /// 休息阶段
        var restStartMs: Int64?
        var restEndMs: Int64?
        var restDurationSec: Int
        var restSuccess: Bool

        /// 记录最近一次写入时间（用于跨进程刷新）
        var updatedAtMs: Int64

        static func idle() -> State {
            State(
                phase: .idle,
                owner: .app,
                tomatoId: nil,
                taskId: nil,
                taskContent: nil,
                focusStartMs: nil,
                focusEndMs: nil,
                focusDurationSec: 25 * 60,
                focusSuccess: false,
                restStartMs: nil,
                restEndMs: nil,
                restDurationSec: 5 * 60,
                restSuccess: false,
                updatedAtMs: Date.currentTimestamp
            )
        }
    }

    // MARK: - AppGroup UserDefaults

    private enum Keys {
        static let sessionState = "td_focus_session_state_v1"
        static let appHeartbeatMs = "td_focus_session_app_heartbeat_ms"
    }

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: TDAppConfig.appGroupId)
    }

    @Published private(set) var state: State = .idle()

    private init() {
        refreshFromDefaults()
    }

    // MARK: - Public API

    func refreshFromDefaults() {
        guard let defaults else { return }
        guard let data = defaults.data(forKey: Keys.sessionState) else {
            if state.phase != .idle {
                state = .idle()
            }
            return
        }
        do {
            let decoded = try JSONDecoder().decode(State.self, from: data)
            if decoded != state {
                state = decoded
            }
        } catch {
            logger.error("decode session state failed: \(error.localizedDescription)")
            // 防御：坏数据直接清空，避免卡死在不可解析状态
            defaults.removeObject(forKey: Keys.sessionState)
            state = .idle()
        }
    }

    /// 让 App 进程“接管”本次会话的 owner（当 App 在线时，结束同步由 App 负责）
    func takeOwnershipIfPossible() {
        guard state.phase != .idle else { return }
        if state.owner != .app {
            var next = state
            next.owner = .app
            persist(next)
        }
    }

    /// 主 App 心跳：用于判断 App 是否在线（避免 App+Widget 同时存在时由 Widget 进程重复同步）
    func updateAppHeartbeat(nowMs: Int64 = Date.currentTimestamp) {
        defaults?.set(nowMs, forKey: Keys.appHeartbeatMs)
    }

    private func isAppHeartbeatFresh(nowMs: Int64) -> Bool {
        guard let ms = defaults?.object(forKey: Keys.appHeartbeatMs) as? Int64 else { return false }
        // 20 秒窗口：足够覆盖 App 前后台抖动/线程调度，且能让“App 已退出”快速被 Widget 接管
        return (nowMs - ms) <= 20_000
    }

    func start(focusMinutes: Int, restMinutes: Int, taskId: String?, taskContent: String?, owner: Owner) {
        let now = Date.currentTimestamp
        let focusSec = max(1, focusMinutes) * 60
        let restSec = max(1, restMinutes) * 60

        var next = State.idle()
        next.phase = .focusing
        next.owner = owner
        next.tomatoId = TDAppConfig.generateTaskId()
        next.taskId = taskId
        next.taskContent = taskContent
        next.focusStartMs = now
        next.focusEndMs = now + Int64(focusSec) * 1000
        next.focusDurationSec = focusSec
        next.focusSuccess = false
        next.restDurationSec = restSec
        next.restSuccess = false
        next.updatedAtMs = now

        persist(next)
        // 只刷新专注小组件即可（更及时且避免影响其它小组件）
        TDWidgetReloadBridge.reloadFocus()
    }

    /// 放弃：对齐旧逻辑
    /// - 专注中放弃：如果专注 >= 120s 才写记录 + 同步；否则只结束不写
    /// - 休息中放弃：如果专注 >= 120s 则写记录（focusSuccess 取决于是否已完成专注），再按 owner 同步
    func abandon(now: Date = Date()) async {
        refreshFromDefaults()
        guard state.phase != .idle else { return }

        let nowMs = Int64(now.timeIntervalSince1970 * 1000.0)
        let focusStart = state.focusStartMs ?? nowMs
        let focusEnd = state.focusEndMs ?? nowMs

        // 对齐旧逻辑：休息中放弃不会改 focusEnd（focusEnd = 专注完成时刻）
        let effectiveFocusEnd: Int64 = (state.phase == .focusing) ? nowMs : focusEnd
        let focusDurationSec = max(0, Int((effectiveFocusEnd - focusStart) / 1000))

        // 旧逻辑：只要专注时长 >= 120s 才写记录+同步
        if focusDurationSec >= 120 {
            await finalizeAndMaybeSync(
                focusEndMs: effectiveFocusEnd,
                focusSuccess: state.focusSuccess, // focusing 时通常为 false；resting 时可能为 true
                restSuccess: false,
                owner: state.owner,
                forceOwnerSync: false
            )
        }

        // 结束会话
        persist(.idle())
        TDWidgetReloadBridge.reloadFocus()
    }

    /// Tick：用于 App/Widget 在“显示时”推进阶段
    /// - 返回 true 表示发生了状态推进（phase 变化/会话结束）
    @discardableResult
    func advanceIfNeeded(now: Date = Date()) async -> Bool {
        refreshFromDefaults()
        guard state.phase != .idle else { return false }

        let nowMs = Int64(now.timeIntervalSince1970 * 1000.0)

        switch state.phase {
        case .focusing:
            guard let end = state.focusEndMs else { return false }
            if nowMs < end { return false }

            // 完成专注 -> 进入休息
            var next = state
            next.phase = .resting
            next.focusSuccess = true
            next.focusEndMs = end
            next.restStartMs = nowMs
            next.restEndMs = nowMs + Int64(next.restDurationSec) * 1000
            next.updatedAtMs = nowMs
            persist(next)
            TDWidgetReloadBridge.reloadFocus()
            return true

        case .resting:
            guard let restEnd = state.restEndMs else { return false }
            if nowMs < restEnd { return false }

            // 完成休息 -> 完成整个番茄：写记录 +（按 owner）同步 + 结束会话
            await finalizeAndMaybeSync(
                focusEndMs: state.focusEndMs ?? nowMs,
                focusSuccess: state.focusSuccess,
                restSuccess: true,
                owner: state.owner,
                forceOwnerSync: false
            )
            persist(.idle())
            TDWidgetReloadBridge.reloadFocus()
            return true

        case .idle:
            return false
        }
    }

    /// 当前阶段剩余秒数（<=0 表示已到期，需要 advanceIfNeeded 推进）
    func remainingSeconds(now: Date = Date()) -> Int {
        guard state.phase != .idle else { return max(0, state.focusDurationSec) }

        let nowMs = Int64(now.timeIntervalSince1970 * 1000.0)
        switch state.phase {
        case .focusing:
            let end = state.focusEndMs ?? nowMs
            return max(0, Int((end - nowMs) / 1000))
        case .resting:
            let end = state.restEndMs ?? nowMs
            return max(0, Int((end - nowMs) / 1000))
        case .idle:
            return state.focusDurationSec
        }
    }

    /// 用于 Widget 的倒计时：返回 [now...end] 的 interval（idle 返回 nil）
    func currentTimerInterval(now: Date = Date()) -> (start: Date, end: Date)? {
        guard state.phase != .idle else { return nil }

        let nowMs = Int64(now.timeIntervalSince1970 * 1000.0)
        let endMs: Int64
        switch state.phase {
        case .focusing:
            endMs = state.focusEndMs ?? nowMs
        case .resting:
            endMs = state.restEndMs ?? nowMs
        case .idle:
            return nil
        }
        let end = Date(timeIntervalSince1970: TimeInterval(Double(endMs) / 1000.0))
        return (start: now, end: end)
    }

    // MARK: - Internal

    private func persist(_ next: State) {
        guard let defaults else { return }
        do {
            let data = try JSONEncoder().encode(next)
            defaults.set(data, forKey: Keys.sessionState)
            state = next
        } catch {
            logger.error("encode session state failed: \(error.localizedDescription)")
        }
    }

    private func finalizeAndMaybeSync(
        focusEndMs: Int64,
        focusSuccess: Bool,
        restSuccess: Bool,
        owner: Owner,
        forceOwnerSync: Bool
    ) async {
        guard let tomatoId = state.tomatoId, !tomatoId.isEmpty else { return }

        let userId = TDUserManager.shared.userId
        guard userId > 0 else { return }

        let nowMs = Date.currentTimestamp

        let focusStartMs = state.focusStartMs ?? focusEndMs
        let focusDurationSec = max(0, Int((focusEndMs - focusStartMs) / 1000))

        // 对齐旧逻辑：restDuration 目前固定为 0（App 里 actualRestTime 未累计）
        let restDurationSec = 0

        // 防重复：同一个 tomatoId 只插入一次
        if TDTomatoManager.shared.getTomatoRecord(tomatoId: tomatoId) == nil {
            let record = TDTomatoRecordModel(
                userId: userId,
                tomatoId: tomatoId,
                taskContent: state.taskContent ?? "null",
                taskId: state.taskId ?? "null",
                startTime: focusStartMs,
                endTime: focusEndMs,
                focus: focusSuccess,
                focusDuration: focusDurationSec,
                rest: restSuccess,
                restDuration: restDurationSec,
                snowAdd: 0,
                syncTime: Date.currentTimestamp,
                status: "add"
            )
            TDTomatoManager.shared.insertTomatoRecord(record)
        }

        // 同步触发规则：
        // - owner=widget：仅在 Widget 进程触发
        // - owner=app：优先由 App 进程触发；若 App 心跳过期（App 不在线），允许 Widget 进程接管
        // - forceOwnerSync：测试/兜底用（目前默认 false）
        guard forceOwnerSync || owner == state.owner else { return }

        let isWidgetProcess: Bool = Bundle.main.bundleURL.pathExtension == "appex"

        let shouldSync: Bool = {
            if forceOwnerSync { return true }
            switch state.owner {
            case .widget:
                return isWidgetProcess
            case .app:
                if isWidgetProcess {
                    // App 在线 -> Widget 不同步；App 不在线 -> Widget 接管同步
                    return !isAppHeartbeatFresh(nowMs: nowMs)
                }
                return true
            }
        }()

        guard shouldSync else { return }
        await TDTomatoManager.shared.syncUnsyncedRecords()
    }
}

