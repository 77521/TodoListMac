import Foundation

@MainActor
final class TDTaskSearchViewModel: ObservableObject {
    struct Hit: Equatable, Identifiable {
        var id: String { taskId }
        let taskId: String
        let score: Int
        let todoTime: Int64

        let titleText: String
        let titleMatch: TDWeChatSearchMatcher.MatchResult?

        let subtitleText: String?
        let subtitleMatch: TDWeChatSearchMatcher.MatchResult?
    }

    struct Filters: Equatable {
        let dateRangeRaw: Int
        let categoryId: Int? // nil=全部
        let completeFilterRaw: Int // 0/1/2
    }

    /// 当前展示结果（已经防抖、后台计算完成）
    @Published private(set) var hits: [Hit] = []
    @Published private(set) var isSearching: Bool = false

    private var debounceTask: Task<Void, Never>?
    private var computeTask: Task<Void, Never>?
    private var lastToken: String?

    // MARK: - Snapshot

    struct TaskSnapshot: Sendable {
        let taskId: String
        let title: String
        let desc: String
        let subtasks: [String]
        let todoTime: Int64
        let standbyInt1: Int
        let complete: Bool
    }

    func update(keyword rawKeyword: String, snapshots: [TaskSnapshot], filters: Filters) {
        debounceTask?.cancel()
        computeTask?.cancel()

        let keyword = rawKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        if keyword.isEmpty {
            hits = []
            isSearching = false
            return
        }

        // 立刻搜索（视觉上“输入即出结果”）；每次输入会取消上一轮后台计算
        // 同时做一个轻量 token 去重，避免重复触发同一请求
        let token = "\(TDWeChatSearchMatcher.normalize(keyword))|\(filters.dateRangeRaw)|\(filters.categoryId ?? -999999)|\(filters.completeFilterRaw)|\(snapshots.count)"
        if token == lastToken { return }
        lastToken = token

        Task { [weak self] in
            await self?.recompute(token: token, keyword: keyword, snapshots: snapshots, filters: filters)
        }
    }

    private func recompute(token: String, keyword: String, snapshots: [TaskSnapshot], filters: Filters) async {
        computeTask?.cancel()

        // 把过滤尽量放在后台前做掉，减少计算量
        let filtered = applyFilters(snapshots: snapshots, filters: filters)
        let normalized = TDWeChatSearchMatcher.normalize(keyword)
        let queryIsAlphaNumeric = normalized.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) }

        // 进入搜索态：避免 UI 先闪“无数据”
        isSearching = true

        computeTask = Task.detached(priority: .userInitiated) { [filtered, normalized, queryIsAlphaNumeric, token] in
            if Task.isCancelled { return }
            let hits = Self.computeHits(filtered, normalizedQuery: normalized, queryIsAlphaNumeric: queryIsAlphaNumeric)
            if Task.isCancelled { return }
            await MainActor.run {
                // 避免旧结果覆盖新输入（token 不一致直接丢弃）
                guard self.lastToken == token else { return }
                self.hits = hits
                self.isSearching = false
            }
        }
    }

    private func applyFilters(snapshots: [TaskSnapshot], filters: Filters) -> [TaskSnapshot] {
        var base = snapshots

        // 1) 日期范围（todoTime==0 永远保留）
        if filters.dateRangeRaw != 0 {
            let startTimestamp: Int64 = {
                let today = Date()
                switch filters.dateRangeRaw {
                case 7:
                    return Int64(today.adding(days: -7).startOfDayTimestamp)
                case 30:
                    return Int64(today.adding(days: -30).startOfDayTimestamp)
                case 6:
                    return Int64(today.adding(days: -180).startOfDayTimestamp)
                case 1:
                    return Int64(today.adding(days: -365).startOfDayTimestamp)
                default:
                    return 0
                }
            }()
            if startTimestamp > 0 {
                base = base.filter { $0.todoTime == 0 || $0.todoTime >= startTimestamp }
            }
        }

        // 2) 分类
        if let cid = filters.categoryId {
            base = base.filter { $0.standbyInt1 == cid }
        }

        // 3) 达成状态
        switch filters.completeFilterRaw {
        case 1:
            base = base.filter { $0.complete }
        case 2:
            base = base.filter { !$0.complete }
        default:
            break
        }

        return base
    }

    nonisolated private static func computeHits(
        _ snapshots: [TaskSnapshot],
        normalizedQuery q: String,
        queryIsAlphaNumeric: Bool
    ) -> [Hit] {
        guard !q.isEmpty else { return [] }

        var hits: [Hit] = []
        hits.reserveCapacity(min(snapshots.count, 300))

        // 结果上限（避免一次渲染太多 AttributedString）
        let hardLimit = 500

        for snap in snapshots {
            // 标题/描述
            let titleMatch = TDWeChatSearchMatcher.bestMatch(in: snap.title, normalizedQuery: q, queryIsAlphaNumeric: queryIsAlphaNumeric)
            let descMatch = snap.desc.isEmpty ? nil : TDWeChatSearchMatcher.bestMatch(in: snap.desc, normalizedQuery: q, queryIsAlphaNumeric: queryIsAlphaNumeric)

            // 子任务：取最佳命中那条
            var bestSubText: String? = nil
            var bestSubMatch: TDWeChatSearchMatcher.MatchResult? = nil
            if !snap.subtasks.isEmpty {
                for st in snap.subtasks where !st.isEmpty {
                    if let m = TDWeChatSearchMatcher.bestMatch(in: st, normalizedQuery: q, queryIsAlphaNumeric: queryIsAlphaNumeric) {
                        if bestSubMatch == nil || m.score > bestSubMatch!.score {
                            bestSubMatch = m
                            bestSubText = st
                        }
                    }
                }
            }

            let allMatches: [TDWeChatSearchMatcher.MatchResult] = [titleMatch, descMatch, bestSubMatch].compactMap { $0 }
            guard let best = allMatches.max(by: { $0.score < $1.score }) else { continue }

            // subtitle：优先描述；否则子任务（加前缀）
            let subtitleText: String?
            let subtitleMatch: TDWeChatSearchMatcher.MatchResult?
            if let dm = descMatch {
                subtitleText = snap.desc
                subtitleMatch = dm
            } else if let st = bestSubText, let sm = bestSubMatch {
                let prefix = "子任务："
                subtitleText = prefix + st
                let prefixLen = (prefix as NSString).length
                let shifted = sm.highlightRanges.map { NSRange(location: $0.location + prefixLen, length: $0.length) }
                subtitleMatch = TDWeChatSearchMatcher.MatchResult(kind: sm.kind, highlightRanges: shifted, score: sm.score)
            } else {
                subtitleText = nil
                subtitleMatch = nil
            }

            hits.append(
                Hit(
                    taskId: snap.taskId,
                    score: best.score,
                    todoTime: snap.todoTime,
                    titleText: snap.title,
                    titleMatch: titleMatch,
                    subtitleText: subtitleText,
                    subtitleMatch: subtitleMatch
                )
            )

            if hits.count >= hardLimit { break }
        }

        // 排序：score 高在前；同分按 todoTime 新在前
        // 注意：这里快排只基于 score；todoTime 由外部按 tasks 字典补一次也行，但这一步已够稳定
        hits.sort { a, b in
            if a.score != b.score { return a.score > b.score }
            if a.todoTime != b.todoTime { return a.todoTime > b.todoTime }
            return a.taskId < b.taskId
        }

        return hits
    }
}

