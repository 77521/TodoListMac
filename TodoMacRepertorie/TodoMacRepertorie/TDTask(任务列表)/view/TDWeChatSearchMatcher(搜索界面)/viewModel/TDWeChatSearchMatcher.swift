import Foundation
import SwiftUI

/// 微信式搜索匹配器
/// - 支持：中文包含、拼音全拼、拼音简写（首字母缩写）
/// - 输出：命中类型 + 需要高亮的文本 Range（用于 SwiftUI 的 AttributedString）
enum TDWeChatSearchMatcher {
    enum MatchKind: Int, Comparable {
        case direct = 3      // 原文直接包含（中文/英文/数字等）
        case initials = 2    // 拼音首字母（hh -> 好好）
        case pinyin = 1      // 拼音全拼/子串（nan -> 南）

        static func < (lhs: MatchKind, rhs: MatchKind) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    struct MatchResult: Equatable {
        let kind: MatchKind
        /// 需要高亮的原文范围（NSRange 基于 UTF-16；便于跨线程/缓存）
        /// - 可能是多个不连续范围：例如 initials 命中
        let highlightRanges: [NSRange]
        /// 辅助排序：越大越靠前
        let score: Int
    }

    static func bestMatch(in text: String, query: String) -> MatchResult? {
        let q = normalize(query)
        guard !q.isEmpty, !text.isEmpty else { return nil }
        return bestMatch(in: text, normalizedQuery: q, queryIsAlphaNumeric: isAlphaNumeric(q))
    }

    /// 供调用方复用：预先 normalize query，避免每条数据重复处理
    static func bestMatch(in text: String, normalizedQuery q: String, queryIsAlphaNumeric: Bool) -> MatchResult? {
        guard !q.isEmpty, !text.isEmpty else { return nil }

        // 1) 原文直接包含（优先级最高）
        if let ranges = findAllNSRanges(in: text, needle: q), !ranges.isEmpty {
            // 越靠前越高分
            let firstLoc = ranges[0].location
            let score = 3000 - min(firstLoc, 2000) // location 已是 UTF-16 offset
            return MatchResult(kind: .direct, highlightRanges: ranges, score: score)
        }

        // 2) 仅当 query 是“可用于拼音搜索”的字符（字母/数字）时，才走拼音
        guard queryIsAlphaNumeric else { return nil }

        let index = PinyinIndex(text)

        // 2.1) 拼音首字母缩写（次优先）
        if let initialsMatch = index.matchInitials(q) {
            return initialsMatch
        }

        // 2.2) 拼音全拼（再次）
        if let pinyinMatch = index.matchPinyin(q) {
            return pinyinMatch
        }

        return nil
    }

    // MARK: - Text -> AttributedString

    static func highlightedAttributedString(
        text: String,
        match: MatchResult?,
        normalColor: Color,
        highlightColor: Color
    ) -> AttributedString {
        var att = AttributedString(text)
        att.foregroundColor = normalColor

        guard let match else { return att }
        for nr in match.highlightRanges {
            guard let sr = Range(nr, in: text) else { continue }
            if let ar = Range(sr, in: att) { att[ar].foregroundColor = highlightColor }
        }
        return att
    }

    // MARK: - Internal

    static func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\t", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }

    private static func isAlphaNumeric(_ s: String) -> Bool {
        guard !s.isEmpty else { return false }
        return s.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) }
    }

    private static func findAllNSRanges(in text: String, needle: String) -> [NSRange]? {
        guard !needle.isEmpty else { return nil }
        let ns = text as NSString
        let full = NSRange(location: 0, length: ns.length)
        var result: [NSRange] = []

        var searchRange = full
        while searchRange.length > 0 {
            let r = ns.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive], range: searchRange)
            if r.location == NSNotFound { break }
            result.append(r)
            let nextLoc = r.location + r.length
            if nextLoc >= ns.length { break }
            searchRange = NSRange(location: nextLoc, length: ns.length - nextLoc)
        }
        return result
    }

    // MARK: - Pinyin Index

    /// 把文本建立成“按字符可映射”的拼音索引，便于从拼音命中位置反推出需要高亮的中文字符
    private struct PinyinIndex {
        let text: String

        /// 每个字符对应的原文 range（按 Character 迭代，适配 emoji/组合字符）
        let charRanges: [Range<String.Index>]

        /// 每个字符的拼音分片（已去声调/小写/仅字母数字）
        let pinyinSegments: [String]

        /// 拼音串（所有 segment 直接拼接）
        let pinyinJoined: String

        /// 每个字符在 pinyinJoined 中的起始 offset
        let pinyinOffsets: [Int]

        /// 每个字符在 pinyinJoined 中的长度
        let pinyinLengths: [Int]

        /// 首字母串（每个字符取 pinyinSegments 的第一个字母数字）
        let initials: String

        /// initials 每个位置对应的 charIndex
        let initialsToCharIndex: [Int]

        init(_ text: String) {
            self.text = text

            var ranges: [Range<String.Index>] = []
            var segs: [String] = []

            var idx = text.startIndex
            while idx < text.endIndex {
                let next = text.index(after: idx)
                ranges.append(idx..<next)
                let ch = String(text[idx..<next])
                segs.append(Self.pinyinSegment(for: ch))
                idx = next
            }

            self.charRanges = ranges
            self.pinyinSegments = segs

            var joined = ""
            joined.reserveCapacity(segs.reduce(0) { $0 + $1.count })

            var offsets: [Int] = Array(repeating: 0, count: segs.count)
            var lengths: [Int] = Array(repeating: 0, count: segs.count)

            var cursor = 0
            for (i, s) in segs.enumerated() {
                offsets[i] = cursor
                lengths[i] = s.count
                joined.append(s)
                cursor += s.count
            }

            self.pinyinJoined = joined
            self.pinyinOffsets = offsets
            self.pinyinLengths = lengths

            var initialsStr = ""
            var map: [Int] = []
            for (i, s) in segs.enumerated() {
                guard let first = s.unicodeScalars.first else { continue }
                let c = Character(first)
                initialsStr.append(c)
                map.append(i)
            }
            self.initials = initialsStr
            self.initialsToCharIndex = map
        }

        func matchInitials(_ query: String) -> MatchResult? {
            guard !initials.isEmpty else { return nil }
            guard let r = initials.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) else { return nil }

            let startPos = initials.distance(from: initials.startIndex, to: r.lowerBound)
            let endPos = initials.distance(from: initials.startIndex, to: r.upperBound)
            guard startPos < endPos else { return nil }

            var highlight: [NSRange] = []
            highlight.reserveCapacity(endPos - startPos)
            for p in startPos..<endPos {
                let charIndex = initialsToCharIndex[p]
                if charIndex >= 0, charIndex < charRanges.count {
                    highlight.append(NSRange(charRanges[charIndex], in: text))
                }
            }

            let score = 2000 - min(startPos, 1500)
            return MatchResult(kind: .initials, highlightRanges: highlight, score: score)
        }

        func matchPinyin(_ query: String) -> MatchResult? {
            guard !pinyinJoined.isEmpty else { return nil }
            guard let r = pinyinJoined.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) else { return nil }

            let start = pinyinJoined.distance(from: pinyinJoined.startIndex, to: r.lowerBound)
            let end = pinyinJoined.distance(from: pinyinJoined.startIndex, to: r.upperBound)
            guard start < end else { return nil }

            // 把拼音命中区间映射到字符区间（连续）
            var firstChar: Int? = nil
            var lastChar: Int? = nil

            for i in 0..<pinyinSegments.count {
                let off = pinyinOffsets[i]
                let len = pinyinLengths[i]
                if len == 0 { continue }
                let segStart = off
                let segEnd = off + len

                if firstChar == nil, segEnd > start {
                    firstChar = i
                }
                if segStart < end {
                    lastChar = i
                } else {
                    break
                }
            }

            guard let a = firstChar, let b = lastChar, a <= b else { return nil }
            let highlight = [NSRange(charRanges[a].lowerBound..<charRanges[b].upperBound, in: text)]

            let score = 1500 - min(start, 1200)
            return MatchResult(kind: .pinyin, highlightRanges: highlight, score: score)
        }

        // MARK: - Pinyin Segment

        private static let cacheLock = NSLock()
        private static var segmentCache: [String: String] = [:]

        private static func pinyinSegment(for singleChar: String) -> String {
            cacheLock.lock()
            if let cached = segmentCache[singleChar] {
                cacheLock.unlock()
                return cached
            }
            cacheLock.unlock()

            // 默认：直接用小写（英数等）
            var out = singleChar.lowercased()

            // 尝试把中文转成拼音
            let mutable = NSMutableString(string: singleChar) as CFMutableString
            // “中文 -> 拉丁(拼音)”：会包含空格和声调
            if CFStringTransform(mutable, nil, kCFStringTransformToLatin, false) {
                // 去声调
                CFStringTransform(mutable, nil, kCFStringTransformStripCombiningMarks, false)
                out = (mutable as String).lowercased()
            }

            // 只保留字母数字（去空格/标点）
            out = out.unicodeScalars
                .filter { CharacterSet.alphanumerics.contains($0) }
                .map(String.init)
                .joined()

            cacheLock.lock()
            segmentCache[singleChar] = out
            cacheLock.unlock()
            return out
        }
    }
}

