//
//  TDTaskRowComponents.swift
//  TodoMacRepertorie
//
//  Created by 孬孬 on 2025/1/22.
//

import SwiftUI
import SwiftData
import AppKit

/// 任务行视图的子组件
enum TDTaskRowComponents {
    struct CheckButton: View {
            let task: TDMacSwiftDataListModel
            let isDayTodo: Bool
            @StateObject private var themeManager = TDThemeManager.shared
            
            var body: some View {
                Button(action: {
                    Task {
                        task.complete.toggle()
                        try? await TDModelContainer.shared.perform {
                            try TDModelContainer.shared.save()
                        }
                        await TDMainViewModel.shared.refreshTasks()
                    }
                }) {
                    if isDayTodo {
                        // DayTodo 模式下显示数字
                        Text("\(task.number)")
                            .font(.system(size: 8))
                            .foregroundColor(task.complete ? .white : themeManager.titleTextColor)
                            .frame(width: 20, height: 20)
                            .background(
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(task.complete ?
                                        (task.standbyInt1 > 0 ? Color.fromHex(task.standbyIntColor) : themeManager.color(level: 5)) :
                                        Color.clear
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 2)
                                            .strokeBorder(task.standbyInt1 > 0 ? Color.fromHex(task.standbyIntColor) : themeManager.color(level: 5), lineWidth: 2)
                                    )
                            )
                    } else {
                        // 其他模式显示勾选框
                        Image(systemName: task.complete ? "checkmark.square.fill" : "square")
                            .font(.system(size: 20))
                            .foregroundColor(task.complete ?
                                (task.standbyInt1 > 0 ? Color.fromHex(task.standbyIntColor) : themeManager.color(level: 5)) :
                                                themeManager.descriptionTextColor
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
    /// 任务行视图的子组件
//    struct CategoryView: View {
//        let categoryId: Int
//        let categoryColor: String
//        let categoryName: String
//        @Binding var selectedCategoryId: Int
//        @StateObject private var categoryManager = TDCategoryManager.shared
//        @StateObject private var themeManager = TDThemeManager.shared
//        var body: some View {
//                    Menu {
//                        ForEach(categoryManager.loadLocalCategories()) { category in
//                            Button(action: {
//                                selectedCategoryId = category.categoryId
//                            }) {
//                                HStack(spacing: 8) {
//                                    if selectedCategoryId == category.categoryId {
//                                        Image(systemName: "checkmark")
//                                            .foregroundColor(.white)
//                                            .frame(width: 16)
//                                    } else {
//                                        Spacer()
//                                            .frame(width: 16)
//                                    }
//                                    Image(systemName: "square.fill")
//                                        .resizable()
//                                        .frame(width: 28, height: 16)
//                                        .foregroundStyle(Color.fromHex(category.categoryColor ?? "#c3c3c3"))
//                                    Text(category.categoryName)
//                                        .foregroundColor(selectedCategoryId == category.categoryId ? .white : .primary)
//                                    Spacer()
//                                }
//                                .padding(.vertical, 2)
//                                .padding(.horizontal, 12)
//                                .background(selectedCategoryId == category.categoryId ? Color.accentColor : Color.clear)
//                                .contentShape(Rectangle())
//                            }
//                            .buttonStyle(.plain)
//                        }
//                    } label: {
//                        HStack(spacing: 6) {
//                            Image(systemName: "square.fill")
//                                .resizable()
//                                .frame(width: 28, height: 16)
//                                .foregroundStyle(.linearGradient(colors: [.pink, .orange], startPoint: .leading, endPoint: .trailing))
//                            
//                            Text("强调色")
//                                .foregroundColor(.primary)
//                            
//                            Image(systemName: "chevron.down")
//                                .font(.system(size: 10))
//                                .foregroundColor(.secondary)
//                        }
//                        .padding(.horizontal, 8)
//                        .padding(.vertical, 4)
//                        .background(Color(nsColor: .windowBackgroundColor))
//                        .cornerRadius(6)
//                    }
//                    .menuStyle(.borderlessButton)
//                    .fixedSize()
//                }
////        var body: some View {
//////            HStack{
//////                Circle()
//////                    .fill(Color.fromHex(categoryColor))
//////                    .frame(width: 12,height: 12)
//////                Text(categoryName)
//////                    .font(.system(size: 12))
//////                    .foregroundStyle(themeManager.titleTextColor)
//////            }
////            Picker("", selection: $selectedCategoryId) {
////                            ForEach(categoryManager.loadLocalCategories()) { category in
////                                HStack(spacing: 8) {
////                                    Image(systemName: "circle.fill")
////                                        .frame(width: 12, height: 12)
////                                        
////                                    Text(category.categoryName)
////                                        .foregroundColor(Color.fromHex(category.categoryColor ?? ""))
////                                }
////                                .tag(category.categoryId)
////                                
////                            }
////                        }
////                        .pickerStyle(.menu)
////                        .menuIndicator(.visible)
////                        .background(themeManager.backgroundColor)
////                        .frame(maxWidth: 100)
////                        .modifier(ImageColorModifier(color: .red)) // 应用颜色修改器
////
////
////            .labelsHidden()
////
//////            
//////            Picker("", selection: $selectedCategoryId) {
//////                ForEach(categoryManager.loadLocalCategories()) { category in
//////                    Text(category.categoryName)
//////                        .tag(category.categoryId)
//////                }
//////            }
//////            .pickerStyle(.menu)
//////            .labelsHidden()
////        }
//    }

    /// 分类显示组件
//    struct CategoryView: View {
//           let categoryId: Int
//           let categoryColor: String
//           let categoryName: String
//           @Binding var selectedCategoryId: Int
//           @StateObject private var categoryManager = TDCategoryManager.shared
//           
//           var body: some View {
//               HStack {
//                   Circle()
//                       .fill(Color.fromHex(categoryColor))
//                       .frame(width: 12, height: 12)
//                   Text(categoryName)
//                       .font(.system(size: 12))
//               }
//           }
//       }
    struct CategoryView: View {
            let categoryId: Int
            let categoryColor: String
            let categoryName: String
            @Binding var selectedCategoryId: Int
            @StateObject private var categoryManager = TDCategoryManager.shared
            
            var body: some View {
                Menu {
                    ForEach(categoryManager.loadLocalCategories()) { category in
                        Button(action: {
                            selectedCategoryId = category.categoryId
                        }) {
                            HStack {
                                Image(systemName: "share")
                                Text(category.categoryName)
                                    .foregroundStyle(Color.fromHex(category.categoryColor ?? ""))
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "share")
                        Text(categoryName)
                            .foregroundStyle(Color.fromHex(categoryColor))
                    }
                }
                .menuStyle(.borderlessButton)
            }
        }
    /// 日期显示组件
    struct DateView: View {
        let timestamp: Int64
        @StateObject private var themeManager = TDThemeManager.shared
        @StateObject private var mainViewModel = TDMainViewModel.shared // 添加 mainViewModel

        var body: some View {
            // 只在非 DayTodo 模式下显示日期
            if mainViewModel.selectedCategory?.categoryId != -100 && timestamp > 0 {
                let date = Date.fromTimestamp(timestamp)
                if !date.isToday && !date.isTomorrow && !date.isDayAfterTomorrow {
                    Text(date.formattedString)
                        .font(.system(size: 12))
                        .foregroundColor(date.isOverdue ? .red : themeManager.descriptionTextColor)
                }
            } else if mainViewModel.selectedCategory?.categoryId != -100 {
                // 非 DayTodo 模式下且没有日期时显示"无日期"
                Text("no_date".localized)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.descriptionTextColor)
            }
        }
    }
    
    /// 提醒时间组件
    struct ReminderView: View {
        let timestamp: Int64
        @StateObject private var themeManager = TDThemeManager.shared
        
        var body: some View {
            if timestamp > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text(Date.timestampToString(timestamp: timestamp, format: "HH:mm"))
                }
                .font(.system(size: 14,weight: .medium))
                .foregroundColor(themeManager.color(level: 5))
            }
        }
    }
    
    /// 子任务列表组件
    struct SubTaskListView: View {
        let task: TDMacSwiftDataListModel
        @StateObject private var themeManager = TDThemeManager.shared
        
        var body: some View {
            if !task.subTaskList.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    // 展开/收起按钮
                    Button(action: {
                        // 更新本地数据库
                        withAnimation(.easeInOut(duration: 0.2)) {
                            task.isSubOpen.toggle()
                            Task {
                                try? await TDModelContainer.shared.perform {
                                    try TDModelContainer.shared.save()
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 0) {
                            HStack(spacing: 5) {
                                Image(systemName: task.isSubOpen ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12))
                                Text(task.isSubOpen ? "收起" : "\(task.subTaskList.filter(\.isComplete).count)/\(task.subTaskList.count)")
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(themeManager.secondaryBackgroundColor)
                            )
                        }
                        .foregroundColor(themeManager.descriptionTextColor)
                    }
                    .buttonStyle(.plain)
                    
                    // 子任务列表
                    if task.isSubOpen {
                        ForEach(task.subTaskList.indices, id: \.self) { index in
                            SubTaskRow(task: task, index: index)
                        }
                    }
                }
                .padding(.leading, 37)
            }
        }
    }
    
    /// 单个子任务行组件
    struct SubTaskRow: View {
        let task: TDMacSwiftDataListModel
        let index: Int
        @StateObject private var themeManager = TDThemeManager.shared
        
        var body: some View {
            HStack(spacing: 8) {
                Button(action: {
                    task.subTaskList[index].isComplete.toggle()
                    Task {
                        try? await TDModelContainer.shared.perform {
                            try TDModelContainer.shared.save()
                        }
                    }
                }) {
                    Image(systemName: task.subTaskList[index].isComplete ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14))
                        .foregroundColor(task.subTaskList[index].isComplete ? themeManager.color(level: 5) : themeManager.subtaskTextColor)
                }
                .buttonStyle(.plain)
                
                Text(task.subTaskList[index].content)
                    .font(.system(size: 12))
                    .foregroundColor(task.subTaskList[index].isComplete ? themeManager.subtaskFinishTextColor : themeManager.subtaskTextColor)
                    .strikethrough(task.subTaskList[index].isComplete)
            }
        }
    }
}

/// NSPopUpButton 包装器
struct PopUpButtonView: NSViewRepresentable {
    @Binding var selectedCategoryId: Int
    let categories: [TDSliderBarModel]
    let currentColor: String
    let currentName: String
    
    func makeNSView(context: Context) -> NSPopUpButton {
        let popUp = NSPopUpButton(frame: .zero, pullsDown: false)
        popUp.target = context.coordinator
        popUp.action = #selector(Coordinator.selectionChanged(_:))
        return popUp
    }
    
    func updateNSView(_ nsView: NSPopUpButton, context: Context) {
        // 清除现有项
        nsView.menu?.removeAllItems()
        
        // 添加菜单项
        for category in categories {
            let item = NSMenuItem()
            
            // 创建自定义视图
            let itemView = NSStackView()
            itemView.orientation = .horizontal
            itemView.spacing = 8
            
            // 添加选中标记
            if category.categoryId == selectedCategoryId {
                let checkmark = NSImageView(image: NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)!)
                checkmark.contentTintColor = .white
                itemView.addArrangedSubview(checkmark)
            }
            
            // 添加颜色方块
            let colorView = NSView()
            colorView.wantsLayer = true
            colorView.layer?.backgroundColor = NSColor(Color.fromHex(category.categoryColor ?? "")).cgColor
            colorView.frame = NSRect(x: 0, y: 0, width: 28, height: 16)
            itemView.addArrangedSubview(colorView)
            
            // 添加文字标签
            let label = NSTextField(labelWithString: category.categoryName)
            label.textColor = category.categoryId == selectedCategoryId ? .white : .labelColor
            itemView.addArrangedSubview(label)
            
            // 设置菜单项
            item.view = itemView
            item.tag = category.categoryId
            
            nsView.menu?.addItem(item)
        }
        
        // 更新当前显示
        let titleView = NSStackView()
        titleView.orientation = .horizontal
        titleView.spacing = 4
        
        let colorView = NSView()
        colorView.wantsLayer = true
        colorView.layer?.backgroundColor = NSColor(Color.fromHex(currentColor)).cgColor
        colorView.layer?.cornerRadius = 6
        colorView.frame = NSRect(x: 0, y: 0, width: 12, height: 12)
        titleView.addArrangedSubview(colorView)
        
        let label = NSTextField(labelWithString: currentName)
        label.font = .systemFont(ofSize: 12)
        titleView.addArrangedSubview(label)
        
        nsView.menu?.items.first?.view = titleView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: PopUpButtonView
        
        init(_ parent: PopUpButtonView) {
            self.parent = parent
        }
        
        @objc func selectionChanged(_ sender: NSPopUpButton) {
            if let selectedItem = sender.selectedItem {
                parent.selectedCategoryId = selectedItem.tag
            }
        }
    }
}

