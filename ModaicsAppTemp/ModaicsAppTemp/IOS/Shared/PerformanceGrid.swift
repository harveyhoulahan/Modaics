//
//  PerformanceGrid.swift
//  ModaicsAppTemp
//
//  Optimized grid view with lazy loading and adaptive layouts
//  Created by Harvey Houlahan on 11/26/2025.
//

import SwiftUI

// MARK: - Performance Grid
struct PerformanceGrid<Item: Identifiable, ItemView: View>: View {
    let items: [Item]
    let itemView: (Item) -> ItemView
    
    var columns: Int = 2
    var spacing: CGFloat = 16
    var horizontalPadding: CGFloat = 20
    var showsIndicators: Bool = false
    
    @State private var visibleRange: Range<Int> = 0..<20
    
    init(
        items: [Item],
        columns: Int = 2,
        spacing: CGFloat = 16,
        horizontalPadding: CGFloat = 20,
        showsIndicators: Bool = false,
        @ViewBuilder itemView: @escaping (Item) -> ItemView
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.showsIndicators = showsIndicators
        self.itemView = itemView
    }
    
    var body: some View {
        ScrollView(showsIndicators: showsIndicators) {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
                spacing: spacing
            ) {
                ForEach(items) { item in
                    itemView(item)
                        .id(item.id)
                }
            }
            .padding(.horizontal, horizontalPadding)
        }
    }
}

// MARK: - Adaptive Performance Grid
struct AdaptivePerformanceGrid<Item: Identifiable, ItemView: View>: View {
    let items: [Item]
    let itemView: (Item) -> ItemView
    let minItemWidth: CGFloat
    
    var spacing: CGFloat = 16
    var horizontalPadding: CGFloat = 20
    var showsIndicators: Bool = false
    
    init(
        items: [Item],
        minItemWidth: CGFloat = 150,
        spacing: CGFloat = 16,
        horizontalPadding: CGFloat = 20,
        showsIndicators: Bool = false,
        @ViewBuilder itemView: @escaping (Item) -> ItemView
    ) {
        self.items = items
        self.minItemWidth = minItemWidth
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.showsIndicators = showsIndicators
        self.itemView = itemView
    }
    
    var body: some View {
        ScrollView(showsIndicators: showsIndicators) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: minItemWidth), spacing: spacing)],
                spacing: spacing
            ) {
                ForEach(items) { item in
                    itemView(item)
                        .id(item.id)
                }
            }
            .padding(.horizontal, horizontalPadding)
        }
    }
}

// MARK: - Grid with Pull to Refresh
struct RefreshableGrid<Item: Identifiable, ItemView: View>: View {
    let items: [Item]
    let itemView: (Item) -> ItemView
    let onRefresh: () async -> Void
    
    var columns: Int = 2
    var spacing: CGFloat = 16
    var horizontalPadding: CGFloat = 20
    
    init(
        items: [Item],
        columns: Int = 2,
        spacing: CGFloat = 16,
        horizontalPadding: CGFloat = 20,
        onRefresh: @escaping () async -> Void,
        @ViewBuilder itemView: @escaping (Item) -> ItemView
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.onRefresh = onRefresh
        self.itemView = itemView
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
                spacing: spacing
            ) {
                ForEach(items) { item in
                    itemView(item)
                        .id(item.id)
                }
            }
            .padding(.horizontal, horizontalPadding)
        }
        .refreshable {
            HapticManager.shared.impact(.light)
            await onRefresh()
            HapticManager.shared.success()
        }
    }
}

// MARK: - Waterfall Grid (Pinterest-style)
struct WaterfallGrid<Item: Identifiable, ItemView: View>: View {
    let items: [Item]
    let itemView: (Item) -> ItemView
    let columns: Int
    
    @State private var columnHeights: [CGFloat]
    
    init(
        items: [Item],
        columns: Int = 2,
        @ViewBuilder itemView: @escaping (Item) -> ItemView
    ) {
        self.items = items
        self.columns = columns
        self.itemView = itemView
        self._columnHeights = State(initialValue: Array(repeating: 0, count: columns))
    }
    
    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 16) {
                ForEach(0..<columns, id: \.self) { columnIndex in
                    LazyVStack(spacing: 16) {
                        ForEach(itemsForColumn(columnIndex)) { item in
                            itemView(item)
                                .id(item.id)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func itemsForColumn(_ column: Int) -> [Item] {
        items.enumerated()
            .filter { $0.offset % columns == column }
            .map { $0.element }
    }
}

// MARK: - Grid State Management
enum GridState {
    case loading
    case loaded
    case empty
    case error(String)
}

struct StatefulGrid<Item: Identifiable, ItemView: View, EmptyView: View, ErrorView: View>: View {
    let state: GridState
    let items: [Item]
    let itemView: (Item) -> ItemView
    let emptyView: () -> EmptyView
    let errorView: (String) -> ErrorView
    
    var columns: Int = 2
    var spacing: CGFloat = 16
    
    init(
        state: GridState,
        items: [Item],
        columns: Int = 2,
        spacing: CGFloat = 16,
        @ViewBuilder itemView: @escaping (Item) -> ItemView,
        @ViewBuilder emptyView: @escaping () -> EmptyView,
        @ViewBuilder errorView: @escaping (String) -> ErrorView
    ) {
        self.state = state
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.itemView = itemView
        self.emptyView = emptyView
        self.errorView = errorView
    }
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                GridSkeleton(columns: columns, rows: 3)
                
            case .loaded:
                if items.isEmpty {
                    emptyView()
                } else {
                    PerformanceGrid(
                        items: items,
                        columns: columns,
                        spacing: spacing,
                        itemView: itemView
                    )
                }
                
            case .empty:
                emptyView()
                
            case .error(let message):
                errorView(message)
            }
        }
    }
}
