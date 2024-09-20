//
//  ContentView.swift
//  TodoMacRepertorie
//
//  Created by apple on 2024/5/30.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var isShowingInspector = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } content: {
            List {
                ForEach(0..<5) { i in
                    HStack {
                        Text("Select an item \(i)")
                            
                        if isShowingInspector {
                            Image(systemName: "plus")
                        }
                            
                    }
                    .onHover(perform: { hovering in
                        isShowingInspector = hovering
                    })
                    
                }
                
                
            }
            
            .navigationSplitViewColumnWidth(min: 700, ideal: 250)
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }

        } detail: {
            Text("Detail")
        }

    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
