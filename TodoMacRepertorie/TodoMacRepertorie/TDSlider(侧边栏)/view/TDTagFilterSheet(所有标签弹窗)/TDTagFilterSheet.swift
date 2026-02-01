//
//  TDTagFilterSheet.swift
//  TodoMacRepertorie
//
//  点击「所有标签」后弹出的标签管理 Sheet
//

import SwiftUI
import SwiftData

/// 标签管理弹窗（.sheet）
///
/// 设计目标（对照你给的图）：
/// - 顶部：标题「标签」+ `?` 说明（鼠标移入标题区域显示提示气泡），右侧关闭按钮
/// - 顶部第二行：搜索框
/// - 顶部第三行：排序 / 顺序 / 重置
/// - 下方：标签列表（名称 + 事件数量 + 右侧更多按钮）
struct TDTagFilterSheet: View {
    // MARK: - 外部控制

    /// 用于外部关闭 sheet（比如点击关闭按钮）
    @Binding var isPresented: Bool

    // MARK: - 依赖

    @ObservedObject private var themeManager = TDThemeManager.shared

    // MARK: - UI 状态

    /// 搜索关键字（只影响本地展示，不改数据库）
    @State private var searchText: String = ""

    /// 排序字段：按数量/按时间
    @State private var sortField: SortField = .count

    /// 排序方向：降序/升序
    @State private var sortOrder: SortOrder = .descending

    /// 「标题 + ?」hover 区域是否悬停（用于展示图2的提示气泡）
    @State private var isTitleHovered: Bool = false

    // MARK: - 数据

    /// 当前用户下的所有标签（来自 SwiftData：TDTagModel）
    @State private var allTags: [TDTagModel] = []

    /// 页面左右统一边距（标题、搜索、筛选、列表行 都用同一套）
    private let sidePadding: CGFloat = 16

    // MARK: - Enums

    enum SortField: String, CaseIterable, Identifiable {
        case count
        case time
        var id: String { rawValue }

        /// 国际化显示文本
        var title: String {
            switch self {
            case .count: return "tag.filter.sort.by_count".localized
            case .time: return "tag.filter.sort.by_time".localized
            }
        }
    }

    enum SortOrder: String, CaseIterable, Identifiable {
        case descending
        case ascending
        var id: String { rawValue }

        /// 国际化显示文本
        var title: String {
            switch self {
            case .descending: return "tag.filter.order.desc".localized
            case .ascending: return "tag.filter.order.asc".localized
            }
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        // 固定尺寸（贴近截图的弹窗比例）
        .frame(width: 420, height: 620)
        .background(themeManager.secondaryBackgroundColor)
        // 弹窗出现时加载一次标签数据
        .onAppear {
            loadTags()
        }
       
    }

    // MARK: - Header（标题 + 搜索 + 筛选）

    private var header: some View {
        // 说明：顶部三行（标题/搜索/筛选）间距统一为 15，便于后期统一调整
        VStack(spacing: 10) {
            // 1) 第一行：标题 + 帮助 + 关闭按钮
            HStack(alignment: .center, spacing: 10) {
                // 「标题 + ?」做成一个 hover 一体区域（你要求：鼠标放上去显示图2）
                HStack(spacing: 6) {
                    Text("tag.filter.sheet.title".localized)
                        .font(.system(size: 15))
                        .foregroundColor(themeManager.titleTextColor)

                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.descriptionTextColor)
                }
                // 关键：把 HStack 整体当成 hover 区域（标题和 ? 是一体的）
                .contentShape(Rectangle())
                .onHover { hovering in
                    // hover 时显示提示气泡，离开隐藏
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isTitleHovered = hovering
                    }
                }
                // 用 popover 实现「图2」那种提示气泡
                .popover(isPresented: $isTitleHovered, arrowEdge: .top) {
                    helpPopover
                }
                .pointingHandCursor()

                Spacer()

                // 关闭按钮（sheet 自带的关闭入口有时不明显，这里做一个显式按钮）
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.descriptionTextColor.opacity(0.8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("common.cancel".localized))
            }

            // 2) 第二行：搜索框
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.descriptionTextColor)
                    .font(.system(size: 14))

                TextField("tag.filter.search.placeholder".localized, text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.06))
            )

            // 3) 第三行：筛选/排序（保持你原来的横排布局：2 个 Picker + 重置按钮）
            // - 第一个控件的左边距与搜索框左边距一致（都由 header 的 sidePadding 控制）
            HStack(spacing: 10) {
                Picker("", selection: $sortField) {
                    ForEach(SortField.allCases) { opt in
                        Text(opt.title).tag(opt)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: pillWidth(for: currentSortFieldLabel))
                .fixedSize(horizontal: true, vertical: false)

                Picker("", selection: $sortOrder) {
                    ForEach(SortOrder.allCases) { opt in
                        Text(opt.title).tag(opt)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: pillWidth(for: currentSortOrderLabel))
                .fixedSize(horizontal: true, vertical: false)

                Button {
                    resetFilters()
                } label: {
                    Text("tag.filter.reset".localized)
                        .font(.system(size: 12, weight: .medium))
                        // 说明：重置按钮文字使用主题色 level 5（与标签高亮一致）
                        .foregroundColor(themeManager.color(level: 5))
                }
                .buttonStyle(.borderless)

                Spacer()
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, sidePadding)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .background(themeManager.secondaryBackgroundColor)
    }

    /// 「图2」的提示内容（国际化）
    private var helpPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("tag.filter.help.1".localized)
            Text("tag.filter.help.2".localized)
        }
        .font(.system(size: 12))
        .foregroundColor(themeManager.titleTextColor)
        .padding(12)
        // 这里不强行加背景色，交给系统 popover 样式（更贴近 macOS 体验）
    }

    // MARK: - Content（标签列表）

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredAndSortedTags, id: \.persistentModelID) { tag in
                    tagRow(tag)
                    Divider().opacity(0.35)
                }
            }
            .padding(.top, 2)
        }
        .background(Color.clear)
    }

    private func tagRow(_ tag: TDTagModel) -> some View {
        HStack(spacing: 12) {
            Text(tag.display)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeManager.color(level: 5))
                .lineLimit(1)

            Spacer()

            // 事件数量（国际化格式化）
            Text("tag.filter.event_count_format".localizedFormat(tag.taskCount))
                .font(.system(size: 12))
                .foregroundColor(themeManager.descriptionTextColor)
        }
        // 说明：让整行占满可用宽度，保证“右键菜单”在空白区域也能触发
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        // 说明：左右间距与标题一致（你截图里要求左对齐 + 右侧文案同样 inset）
        .padding(.horizontal, sidePadding)
        .padding(.vertical, 10)
        // 右键菜单：在标签行上操作（替代右侧更多按钮，保证右侧文案能贴齐右边距）
        .contextMenu {
            Button {
                // 右键操作1：从所有事件中移除该标签（会更新本地数据并进入同步流程）
                Task { await bulkEditAllTasks(for: tag, operation: .removeTag) }
            } label: {
                Text("tag.context.remove_tag".localized)
            }

            Button {
                // 右键操作2：从所有事件中移除该标签的 # 符号（会更新本地数据并进入同步流程）
                Task { await bulkEditAllTasks(for: tag, operation: .removeHashSymbol) }
            } label: {
                Text("tag.context.remove_hash".localized)
            }
        }
        // 点击标签：行为与侧滑栏点击普通标签一致，并且点击后弹窗关闭
        .onTapGesture {
            // 说明：弹窗里展示的都是具体标签（非“所有标签”），所以点击后直接进入“标签模式”
            TDSliderBarViewModel.shared.selectTagFromSheet(tagKey: tag.key)
            // 关闭 sheet
            isPresented = false
        }

    }

    // MARK: - 数据处理

    /// 读取当前用户的标签列表（SwiftData -> 内存）
    private func loadTags() {
        // 说明：标签是 SwiftData 索引表，按用户隔离；这里用主 context 同步读取即可
        let context = TDModelContainer.shared.mainContext
        let userId = TDUserManager.shared.userId
        allTags = TDTagManager.shared.fetchAllTags(userId: userId, context: context)
    }

    /// 重置筛选条件（不会改数据，只重置 UI 状态）
    private func resetFilters() {
        searchText = ""
        sortField = .count
        sortOrder = .descending
    }

    /// 搜索 + 排序后的展示数组
    private var filteredAndSortedTags: [TDTagModel] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1) 搜索过滤（名称和 key 都支持）
        let filtered: [TDTagModel]
        if keyword.isEmpty {
            filtered = allTags
        } else {
            filtered = allTags.filter { tag in
                tag.display.localizedCaseInsensitiveContains(keyword)
                || tag.key.localizedCaseInsensitiveContains(keyword)
            }
        }

        // 2) 排序
        let sorted = filtered.sorted { a, b in
            switch sortField {
            case .count:
                if sortOrder == .descending { return a.taskCount > b.taskCount }
                return a.taskCount < b.taskCount
            case .time:
                if sortOrder == .descending { return a.createTime > b.createTime }
                return a.createTime < b.createTime
            }
        }
        return sorted
    }

    // MARK: - Picker 文案与宽度（复用设置页同款计算方式）

    private var currentSortFieldLabel: String { sortField.title }
    private var currentSortOrderLabel: String { sortOrder.title }

    /// 计算文本宽度，保证胶囊长度与当前文案匹配（与设置页保持一致，便于统一视觉）
    private func pillWidth(for text: String) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 13, weight: .regular)
        let size = (text as NSString).size(withAttributes: [.font: font])
        let padding: CGFloat = 18 + 18 // 左右总 padding
        let minWidth: CGFloat = 64
        let maxWidth: CGFloat = 200
        return min(max(size.width + padding, minWidth), maxWidth)
    }

    // MARK: - 批量修改（走同步流程）

    /// 右键菜单的两种批量操作
    private enum BulkOperation {
        case removeTag
        case removeHashSymbol
    }

    /// 批量修改当前用户所有任务（更新 taskContent + version/status/syncTime，并更新标签索引）
    @MainActor
    private func bulkEditAllTasks(for tag: TDTagModel, operation: BulkOperation) async {
        let userId = TDUserManager.shared.userId
        let context = TDModelContainer.shared.mainContext

        // 2) 查询包含该标签的事件（按标签筛选，不做全量扫描）
        // 说明：查询条件在 TDCorrectQueryBuilder 里统一维护（userId + delete=false + taskContent 包含 tagKey）
        let tasks: [TDMacSwiftDataListModel]
        do {
            tasks = try await TDQueryConditionManager.shared.getTasksByTagKey(tagKey: tag.key, context: context)
        } catch {
            TDToastCenter.shared.show(error.localizedDescription, type: .error, position: .bottom)
            return
        }

        // 3) 批量修改 taskContent，并通过“你现有的本地更新通用方法”写回数据库（确保走同步流程）
        // 说明：
        // - 这里不直接手动改 version/status/syncTime（避免绕过你现有的同步约束）
        // - 改完 taskContent 后，调用 updateLocalTaskWithModel，它内部会：
        //   - version +1、status=update、syncTime 更新
        //   - 更新标签索引（TDTagIndexService.indexTask）
        //   - save
        var changedCount = 0

        for task in tasks {
            let oldContent = task.taskContent
            let newContent: String
            switch operation {
            case .removeTag:
                // 从所有事件中移除标签：删除 “#标签文本” 本体（以及紧随其后的空白）
                // 示例： "我啊你啊#爱你 哈哈哈" -> "我啊你啊哈哈哈"
                newContent = removeTagKey(tag.key, from: oldContent)
            case .removeHashSymbol:
                // 从所有事件中移除 # 号：仅移除该标签的 #（保留标签文本与空格）
                // 示例： "我啊你啊#爱你 哈哈哈" -> "我啊你啊爱你 哈哈哈"
                newContent = removeHashSymbol(for: tag.key, in: oldContent)
            }

            // 没变化就跳过，避免无意义的 version 增长
            if newContent == oldContent { continue }

            // 3.1) 先把改完后的内容回写到 taskContent（你要求：重新赋值给 taskContent）
            task.taskContent = newContent

            // 3.2) 再调用你现有的“通用更新方法”（内部会 save + 更新索引）
            do {
                let result = try await TDQueryConditionManager.shared.updateLocalTaskWithModel(
                    updatedTask: task,
                    context: context
                )
                if result == .updated {
                    changedCount += 1
                }
            } catch {
                // 不中断整体流程：记录错误并继续处理其他任务
                print("❌ 批量标签修改：本地更新失败 taskId=\(task.taskId)，error=\(error)")
            }
        }
         

        // 4) 更新完成后触发同步（只调用一次，避免每条任务都触发一次网络/同步）
        if changedCount > 0 {
            await TDMainViewModel.shared.performSyncSeparately()
        }

        // 4.1) 如果该标签已经在所有未删除事件中彻底不存在，则同步删除本地标签索引记录
        // 说明：
        // - 右键操作语义是“从所有事件移除”，所以当内容里已没有该 tagKey 时，本地标签也应消失
        // - 这里做一次兜底清理，避免因历史脏数据/残留关系导致标签仍显示
        // 4.1) 操作结束后再查一遍：如果没有任何事件还包含该 tagKey，则删除本地标签索引记录
        // 说明：不要复用上面的 tasks（它是“操作前”查出来的集合），这里用最新数据判断更准确
        let remaining: [TDMacSwiftDataListModel]
        do {
            remaining = try await TDQueryConditionManager.shared.getTasksByTagKey(tagKey: tag.key, context: context)
        } catch {
            remaining = []
        }
        if remaining.isEmpty {
            do {
                // 删除标签（同时删除关系表），按当前用户隔离
                try TDTagManager.shared.deleteTag(userId: userId, key: tag.key, context: context)
            } catch {
                // 不阻塞主流程：删索引失败只会导致列表暂时还在
                print("❌ 批量标签修改：删除本地标签索引失败 key=\(tag.key)，error=\(error)")
            }
        }

        loadTags()

        // 5) 提示：展示本次影响的任务数
        let toastKey: String = (operation == .removeTag)
            ? "tag.context.toast.removed_tag"
            : "tag.context.toast.removed_hash"
        TDToastCenter.shared.show(toastKey.localizedFormat(changedCount), type: .success, position: .bottom)
    }

    /// 从文本中移除某个 tagKey（tagKey 形如 "#xxx"）
    private func removeTagKey(_ tagKey: String, from content: String) -> String {
        // 说明：标签在任务标题里通常以「#xxx + 空格」结尾；这里移除：
        // - "#xxx" 本体
        // - 后续的空格/Tab（不吞换行）
        // 同时兼容：
        // - 标签在行末（没有额外空格）
        // - 标签后面紧跟标点（不吞标点，只移除标签本体）
        let escaped = NSRegularExpression.escapedPattern(for: tagKey)
        // 仅删除标签本体 + 紧随其后的空白（不吞掉换行）
        let pattern = "\(escaped)[ \\t]*"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return content }
        let range = NSRange(location: 0, length: (content as NSString).length)
        var result = regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: "")

        // 清理连续空格（避免 “移除标签后出现双空格”）
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        // 只清理首尾空格（不动换行，避免破坏多行内容）
        return result.trimmingCharacters(in: .whitespaces)
    }

    /// 从文本中移除该标签的 `#` 符号（"#xxx" -> "xxx"）
    private func removeHashSymbol(for tagKey: String, in content: String) -> String {
        guard tagKey.hasPrefix("#"), tagKey.count > 1 else { return content }
        let noHash = String(tagKey.dropFirst())
        let escaped = NSRegularExpression.escapedPattern(for: tagKey)
        guard let regex = try? NSRegularExpression(pattern: escaped, options: []) else { return content }
        let range = NSRange(location: 0, length: (content as NSString).length)
        return regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: noHash)
    }
}

