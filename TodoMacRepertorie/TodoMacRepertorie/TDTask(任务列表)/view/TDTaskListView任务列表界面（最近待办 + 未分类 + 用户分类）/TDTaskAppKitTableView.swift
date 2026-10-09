import SwiftUI
import SwiftData
import AppKit

// MARK: - 扁平行（组头 + 任务）

/// 最近待办表格的一行。展开后任务行紧跟组头，收起则只有组头。
enum TDTaskTableItem: Identifiable {
    case header(TDTaskGroupType)
    case task(TDTaskListRenderItem, groupType: TDTaskGroupType, isFirst: Bool, isLast: Bool)
    case revealSpacer(TDTaskGroupType)

    var id: String {
        switch self {
        case .header(let type):
            return "header.\(type.rawValue)"
        case .task(let item, _, _, _):
            return item.id
        case .revealSpacer(let type):
            return "reveal.\(type.rawValue)"
        }
    }

    var isHeader: Bool {
        if case .header = self { return true }
        return false
    }

    var isRevealSpacer: Bool {
        if case .revealSpacer = self { return true }
        return false
    }
}

// MARK: - NSTableView 封装

/// 滴答清单同款：view-based NSTableView。展开/收起只插一行占位，用系统行高动画做整组延伸。
/// 行高预先算死，避免 NSHostingView 自动测高导致滑动卡、展开跳动。
struct TDTaskAppKitTable<RowContent: View>: NSViewRepresentable {
    let items: [TDTaskTableItem]
    let expandToken: Set<TDTaskGroupType>
    /// 选中 / 多选 / 拖拽占位变化时才刷新可见 cell，其它 SwiftUI 刷新一律跳过
    let updateToken: String
    @Binding var scrollToId: String?
    @ViewBuilder var rowContent: (TDTaskTableItem) -> RowContent

    @EnvironmentObject private var themeManager: TDThemeManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let tableView = TDTaskPlainTableView()
        tableView.headerView = nil
        tableView.allowsColumnReordering = false
        tableView.allowsColumnResizing = false
        tableView.allowsMultipleSelection = false
        tableView.allowsEmptySelection = true
        tableView.allowsTypeSelect = false
        tableView.selectionHighlightStyle = .none
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.usesAutomaticRowHeights = false
        tableView.rowHeight = TDTaskTableRowMetrics.headerHeight
        tableView.intercellSpacing = .zero
        tableView.focusRingType = .none
        tableView.backgroundColor = .windowBackgroundColor
        tableView.style = .plain
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.wantsLayer = true

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("content"))
        column.resizingMask = .autoresizingMask
        column.minWidth = 80
        tableView.addTableColumn(column)

        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = .init()
        scrollView.wantsLayer = true

        context.coordinator.tableView = tableView
        context.coordinator.scrollView = scrollView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.makeAnyView = { [themeManager, modelContext, colorScheme] item in
            AnyView(
                rowContent(item)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .environmentObject(themeManager)
                    .environment(\.modelContext, modelContext)
                    .environment(\.colorScheme, colorScheme)
            )
        }

        let ids = items.map(\.id)
        let expandChanged = coordinator.didLoad && coordinator.lastExpandToken != expandToken
        let idsChanged = coordinator.lastIds != ids
        let tokenChanged = coordinator.lastUpdateToken != updateToken

        if coordinator.isAnimatingDiff {
            coordinator.lastExpandToken = expandToken
            coordinator.lastIds = ids
            coordinator.lastUpdateToken = updateToken
        } else if !coordinator.didLoad {
            coordinator.apply(items: items, animate: false)
            coordinator.didLoad = true
            coordinator.lastExpandToken = expandToken
            coordinator.lastIds = ids
            coordinator.lastUpdateToken = updateToken
        } else if expandChanged {
            coordinator.lastExpandToken = expandToken
            coordinator.lastIds = ids
            coordinator.apply(items: items, animate: true)
            coordinator.lastUpdateToken = updateToken
        } else if idsChanged {
            coordinator.apply(items: items, animate: false)
            coordinator.lastExpandToken = expandToken
            coordinator.lastIds = ids
            coordinator.lastUpdateToken = updateToken
        } else if tokenChanged {
            coordinator.items = items
            coordinator.refreshVisibleCells()
            coordinator.lastUpdateToken = updateToken
        } else {
            coordinator.lastExpandToken = expandToken
            coordinator.lastIds = ids
            coordinator.lastUpdateToken = updateToken
        }

        if let id = scrollToId {
            coordinator.scrollTo(id: id)
            DispatchQueue.main.async {
                if scrollToId == id {
                    scrollToId = nil
                }
            }
        }
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        weak var tableView: NSTableView?
        weak var scrollView: NSScrollView?

        var items: [TDTaskTableItem] = []
        var lastExpandToken: Set<TDTaskGroupType> = []
        var lastIds: [String] = []
        var lastUpdateToken = ""
        var didLoad = false
        var isAnimatingDiff = false
        var makeAnyView: ((TDTaskTableItem) -> AnyView)?
        private let metrics = TDTaskTableRowMetrics()
        private var revealHeight: CGFloat = 0
        private var revealFullHeight: CGFloat = 0
        private var revealImage: NSImage?
        private var revealImageOffset: CGFloat = 0
        private var pendingFinalItems: [TDTaskTableItem]?
        private var pendingInsertedRows = IndexSet()
        private var revealSpacerIndex: Int?

        func apply(items newItems: [TDTaskTableItem], animate: Bool) {
            guard let tableView else {
                items = newItems
                return
            }

            metrics.invalidateIfNeeded(tableWidth: tableView.bounds.width)

            if animate, !items.isEmpty {
                applyGroupReveal(from: items, to: newItems, in: tableView)
            } else {
                clearRevealState()
                items = newItems
                tableView.reloadData()
            }
        }

        func scrollTo(id: String) {
            guard let tableView, let row = items.firstIndex(where: { $0.id == id }) else { return }
            tableView.scrollRowToVisible(row)
        }

        /// 只插一行占位，用系统动画拉高度；内容固定高度被裁切，看起来是整组延伸/收缩。
        private func applyGroupReveal(from oldItems: [TDTaskTableItem], to newItems: [TDTaskTableItem], in tableView: NSTableView) {
            let oldIds = oldItems.map(\.id)
            let newIds = newItems.map(\.id)
            let oldSet = Set(oldIds)
            let newSet = Set(newIds)
            let deleted = IndexSet(oldIds.enumerated().compactMap { newSet.contains($0.element) ? nil : $0.offset })
            let inserted = IndexSet(newIds.enumerated().compactMap { oldSet.contains($0.element) ? nil : $0.offset })
            let isCollapse = !deleted.isEmpty && inserted.isEmpty
            let isExpand = !inserted.isEmpty && deleted.isEmpty

            guard isExpand || isCollapse else {
                items = newItems
                tableView.reloadData()
                return
            }

            let changedIndexSet = isExpand ? inserted : deleted
            guard Self.isContiguous(changedIndexSet),
                  let firstChanged = changedIndexSet.first,
                  let lastChanged = changedIndexSet.last else {
                items = newItems
                tableView.reloadData()
                return
            }

            let source = isExpand ? newItems : oldItems
            var groupType: TDTaskGroupType?
            var totalHeight: CGFloat = 0
            let width = tableView.bounds.width
            for index in firstChanged...lastChanged {
                let item = source[index]
                if case .task(_, let type, _, _) = item {
                    if let groupType, groupType != type {
                        items = newItems
                        tableView.reloadData()
                        return
                    }
                    groupType = type
                } else {
                    items = newItems
                    tableView.reloadData()
                    return
                }
                totalHeight += metrics.height(for: item, row: index, items: source, tableWidth: width)
            }
            guard let groupType else {
                items = newItems
                tableView.reloadData()
                return
            }

            revealFullHeight = totalHeight
            revealImage = nil
            revealImageOffset = 0
            pendingFinalItems = newItems
            pendingInsertedRows = inserted
            isAnimatingDiff = true

            if isExpand {
                let spacerIndex = firstChanged
                revealHeight = 0.01
                revealSpacerIndex = spacerIndex
                var mid = oldItems
                mid.insert(.revealSpacer(groupType), at: spacerIndex)
                items = mid
                tableView.insertRows(at: IndexSet(integer: spacerIndex), withAnimation: [])
                tableView.layoutSubtreeIfNeeded()
                DispatchQueue.main.async { [weak self] in
                    guard let self, self.revealSpacerIndex == spacerIndex else { return }
                    self.animateRevealHeight(to: self.revealFullHeight, in: tableView, spacerIndex: spacerIndex)
                }
            } else {
                if let snapshot = snapshotVisibleRows(deleted, in: tableView) {
                    revealImage = snapshot.image
                    revealImageOffset = snapshot.offset
                }
                revealHeight = max(revealFullHeight, 0.01)
                revealSpacerIndex = firstChanged
                var mid = oldItems
                mid.removeSubrange(firstChanged...lastChanged)
                mid.insert(.revealSpacer(groupType), at: firstChanged)
                items = mid
                tableView.beginUpdates()
                tableView.removeRows(at: deleted, withAnimation: [])
                tableView.insertRows(at: IndexSet(integer: firstChanged), withAnimation: [])
                tableView.endUpdates()
                tableView.layoutSubtreeIfNeeded()
                DispatchQueue.main.async { [weak self] in
                    guard let self, self.revealSpacerIndex == firstChanged else { return }
                    self.animateRevealHeight(to: 0.01, in: tableView, spacerIndex: firstChanged)
                }
            }
        }

        private static func isContiguous(_ set: IndexSet) -> Bool {
            guard let first = set.first, let last = set.last else { return false }
            return set.count == last - first + 1
        }

        private func animateRevealHeight(to height: CGFloat, in tableView: NSTableView, spacerIndex: Int) {
            guard items.indices.contains(spacerIndex), items[spacerIndex].isRevealSpacer else {
                finishReveal(in: tableView)
                return
            }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.32
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.10, 0.25, 1.00)
                context.allowsImplicitAnimation = true
                revealHeight = height
                tableView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: spacerIndex))
            }, completionHandler: { [weak self] in
                self?.finishReveal(in: tableView)
            })
        }

        private func finishReveal(in tableView: NSTableView) {
            let finalItems = pendingFinalItems ?? items
            let inserted = pendingInsertedRows
            let spacerIndex = revealSpacerIndex
            let spacerStillThere = spacerIndex.map { items.indices.contains($0) && items[$0].isRevealSpacer } ?? false
            items = finalItems
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            if spacerStillThere, let spacerIndex {
                if !inserted.isEmpty {
                    tableView.beginUpdates()
                    tableView.removeRows(at: IndexSet(integer: spacerIndex), withAnimation: [])
                    tableView.insertRows(at: inserted, withAnimation: [])
                    tableView.endUpdates()
                } else {
                    tableView.removeRows(at: IndexSet(integer: spacerIndex), withAnimation: [])
                }
            } else {
                tableView.reloadData()
            }
            CATransaction.commit()
            clearRevealState()
            isAnimatingDiff = false
            refreshHeaderCells()
        }

        /// 只拍当前屏幕里的分组，避免为整组任务建 SwiftUI。
        private func snapshotVisibleRows(_ rows: IndexSet, in tableView: NSTableView) -> (image: NSImage, offset: CGFloat)? {
            guard let first = rows.first, let last = rows.last else { return nil }
            let groupRect = tableView.rect(ofRow: first).union(tableView.rect(ofRow: last))
            let visible = groupRect.intersection(tableView.visibleRect).integral
            guard visible.width > 1, visible.height > 1 else { return nil }
            guard let rep = tableView.bitmapImageRepForCachingDisplay(in: visible) else { return nil }
            tableView.cacheDisplay(in: visible, to: rep)
            let image = NSImage(size: visible.size)
            image.addRepresentation(rep)
            return (image, max(visible.minY - groupRect.minY, 0))
        }

        private func clearRevealState() {
            revealHeight = 0
            revealFullHeight = 0
            revealImage = nil
            revealImageOffset = 0
            pendingFinalItems = nil
            pendingInsertedRows = []
            revealSpacerIndex = nil
        }

        func refreshVisibleCells() {
            guard let tableView else { return }
            let visible = tableView.rows(in: tableView.visibleRect)
            guard visible.length > 0 else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            let end = visible.location + visible.length
            for row in visible.location ..< end {
                configureExistingCell(row: row, in: tableView)
            }
            CATransaction.commit()
        }

        func refreshHeaderCells() {
            guard let tableView else { return }
            for row in items.indices where items[row].isHeader {
                configureExistingCell(row: row, in: tableView)
            }
        }

        private func configureExistingCell(row: Int, in tableView: NSTableView) {
            guard items.indices.contains(row), !items[row].isRevealSpacer else { return }
            guard let cell = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? TDTaskHostingCell else { return }
            cell.configure(with: view(for: row), token: token(for: row))
        }

        private func view(for row: Int) -> AnyView {
            guard items.indices.contains(row) else {
                return AnyView(EmptyView())
            }
            if items[row].isRevealSpacer {
                return AnyView(EmptyView())
            }
            guard let makeAnyView else {
                return AnyView(EmptyView())
            }
            return makeAnyView(items[row])
        }

        private func token(for row: Int) -> String {
            guard items.indices.contains(row) else { return "" }
            switch items[row] {
            case .header(let type):
                return "\(items[row].id)|\(lastUpdateToken)|\(lastExpandToken.contains(type) ? 1 : 0)"
            case .task:
                return "\(items[row].id)|\(lastUpdateToken)"
            case .revealSpacer:
                return items[row].id
            }
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            items.count
        }

        func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
            guard items.indices.contains(row) else { return TDTaskTableRowMetrics.headerHeight }
            if items[row].isRevealSpacer {
                return max(revealHeight, 0.01)
            }
            return metrics.height(for: items[row], row: row, items: items, tableWidth: tableView.bounds.width)
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            if items.indices.contains(row), items[row].isRevealSpacer {
                let identifier = NSUserInterfaceItemIdentifier("TDTaskRevealSpacerCell")
                let cell = (tableView.makeView(withIdentifier: identifier, owner: self) as? TDTaskRevealSpacerCell)
                    ?? TDTaskRevealSpacerCell()
                cell.identifier = identifier
                cell.configure(image: revealImage, imageOffset: revealImageOffset, fullHeight: revealFullHeight)
                return cell
            }

            let identifier = NSUserInterfaceItemIdentifier("TDTaskHostingCell")
            let cell = (tableView.makeView(withIdentifier: identifier, owner: self) as? TDTaskHostingCell)
                ?? TDTaskHostingCell()
            cell.identifier = identifier
            cell.configure(with: view(for: row), token: token(for: row))
            return cell
        }

        func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
            TDTaskPlainRowView()
        }

        func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
            false
        }

        func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
            false
        }

        func tableViewColumnDidResize(_ notification: Notification) {
            guard let tableView else { return }
            metrics.invalidateIfNeeded(tableWidth: tableView.bounds.width, force: true)
            let visible = tableView.rows(in: tableView.visibleRect)
            guard visible.length > 0 else { return }
            let end = visible.location + visible.length
            tableView.noteHeightOfRows(withIndexesChanged: IndexSet(integersIn: visible.location ..< end))
        }
    }
}

// MARK: - 行高（展开前就算死，插入时不再二次测高）

final class TDTaskTableRowMetrics {
    static let headerHeight: CGFloat = 36
    static let collapsedGroupGap: CGFloat = 1

    private var cache: [String: CGFloat] = [:]
    private var cachedWidth: CGFloat = 0
    private var settingsKey = ""

    func invalidateIfNeeded(tableWidth: CGFloat, force: Bool = false) {
        let sm = TDSettingManager.shared
        let nextSettings = "v2-\(sm.taskTitleLines)-\(sm.taskDescriptionLines)-\(sm.showTaskDescription)"
        let width = tableWidth > 1 ? tableWidth : cachedWidth
        if force || abs(width - cachedWidth) > 0.5 || nextSettings != settingsKey {
            cache.removeAll(keepingCapacity: true)
            cachedWidth = width
            settingsKey = nextSettings
        }
    }

    func height(for item: TDTaskTableItem, row: Int, items: [TDTaskTableItem], tableWidth: CGFloat) -> CGFloat {
        invalidateIfNeeded(tableWidth: tableWidth)
        switch item {
        case .header:
            let needsGap = row + 1 >= items.count || items[row + 1].isHeader
            return Self.headerHeight + (needsGap ? Self.collapsedGroupGap : 0)
        case .task(let render, _, _, _):
            let key = heightKey(render)
            if let cached = cache[key] { return cached }
            let value = measureTask(render, tableWidth: cachedWidth > 1 ? cachedWidth : 400)
            cache[key] = value
            return value
        case .revealSpacer:
            return 0.01
        }
    }

    private func heightKey(_ render: TDTaskListRenderItem) -> String {
        let task = render.task
        return "\(task.taskId)|\(task.taskContent)|\(task.taskDescribe ?? "")|\(task.complete)|\(task.isSubOpen)|\(task.subTaskList.count)|\(task.hasReminder)|\(task.hasRepeat)|\(task.hasAttachment)|\(task.todoTime)"
    }

    private func measureTask(_ render: TDTaskListRenderItem, tableWidth: CGFloat) -> CGFloat {
        let sm = TDSettingManager.shared
        let task = render.task
        // 难度条 + checkbox + 左右 padding，跟 TDTaskRowView 对齐
        let contentWidth = max(tableWidth - 16 - 10 - 4 - 12 - 18, 80)

        // 上下 padding 12+12；内部 VStack spacing 6
        var height: CGFloat = 24
        let titleLimit = max(sm.taskTitleLines, 1)
        let titleLines = lineCount(task.taskContent, width: contentWidth, fontSize: 14, limit: titleLimit)
        height += CGFloat(titleLines) * 18

        if sm.showTaskDescription, let describe = task.taskDescribe, !describe.isEmpty {
            let descLimit = max(sm.taskDescriptionLines, 1)
            let descLines = lineCount(describe, width: contentWidth, fontSize: 13, limit: descLimit)
            height += 6 + CGFloat(descLines) * 16
        }

        if !task.taskDateConditionalString.isEmpty {
            height += 6 + 13
        }

        if task.hasReminder || task.hasRepeat || task.hasAttachment {
            height += 6 + 16
        }

        if !task.subTaskList.isEmpty {
            height += 6 + 20
            if task.isSubOpen {
                let count = task.subTaskList.count
                if count > 0 {
                    // 收起按钮和子任务列表之间还有一段 VStack spacing
                    height += 6
                    height += CGFloat(count) * 16 + CGFloat(max(count - 1, 0)) * 6
                }
            }
        }

        return max(ceil(height), 44)
    }

    private func lineCount(_ text: String, width: CGFloat, fontSize: CGFloat, limit: Int) -> Int {
        guard !text.isEmpty, width > 0 else { return 1 }
        let font = NSFont.systemFont(ofSize: fontSize)
        let rect = (text as NSString).boundingRect(
            with: NSSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        )
        let lineHeight = max(font.ascender - font.descender + font.leading, fontSize)
        let lines = Int(ceil(rect.height / lineHeight))
        return min(max(lines, 1), limit)
    }
}

// MARK: - 表格 / 行 / Cell

private final class TDTaskPlainTableView: NSTableView {
    override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
        true
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        if abs(bounds.width - oldSize.width) > 0.5 {
            sizeLastColumnToFit()
        }
    }
}

private final class TDTaskPlainRowView: NSTableRowView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.masksToBounds = true
    }

    override func drawSelection(in dirtyRect: NSRect) {}
    override func drawSeparator(in dirtyRect: NSRect) {}
    override var isEmphasized: Bool {
        get { false }
        set {}
    }
}

/// 动画占位：只显示一张位图，行变矮时从底部裁切，动画过程不创建 SwiftUI。
private final class TDTaskRevealSpacerCell: NSView {
    private let imageView = NSImageView()
    private var fullHeight: CGFloat = 0
    private var imageOffset: CGFloat = 0

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
        imageView.imageScaling = .scaleNone
        imageView.imageAlignment = .alignTopLeft
        addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.masksToBounds = true
        imageView.imageScaling = .scaleNone
        imageView.imageAlignment = .alignTopLeft
        addSubview(imageView)
    }

    func configure(image: NSImage?, imageOffset: CGFloat, fullHeight: CGFloat) {
        self.fullHeight = max(fullHeight, 1)
        self.imageOffset = max(imageOffset, 0)
        imageView.image = image
        needsLayout = true
    }

    override func layout() {
        super.layout()
        let size = imageView.image?.size ?? .zero
        imageView.frame = NSRect(x: 0, y: imageOffset, width: max(bounds.width, size.width), height: size.height)
    }
}

private final class TDTaskHostingCell: NSView {
    private var hostingView: NSHostingView<AnyView>?
    private var lastToken: String?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.masksToBounds = true
    }

    func configure(with view: AnyView, token: String, force: Bool = false) {
        if !force, lastToken == token, hostingView != nil { return }
        lastToken = token
        if let hostingView {
            hostingView.rootView = view
        } else {
            let hosting = NSHostingView(rootView: view)
            hosting.sizingOptions = []
            addSubview(hosting)
            hostingView = hosting
        }
        hostingView?.frame = bounds
    }

    override func layout() {
        super.layout()
        hostingView?.frame = bounds
    }
}
