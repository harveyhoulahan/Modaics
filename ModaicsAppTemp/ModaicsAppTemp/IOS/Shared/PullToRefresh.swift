//
//  PullToRefresh.swift
//  Modaics
//
//  Native pull-to-refresh implementation for ScrollView
//

import SwiftUI

struct RefreshableScrollView<Content: View>: View {
    let content: Content
    let onRefresh: () async -> Void
    
    @State private var isRefreshing = false
    @State private var offset: CGFloat = 0
    
    init(@ViewBuilder content: () -> Content, onRefresh: @escaping () async -> Void) {
        self.content = content()
        self.onRefresh = onRefresh
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Refresh indicator
                RefreshIndicator(isRefreshing: isRefreshing, offset: offset)
                    .frame(height: 60)
                    .offset(y: isRefreshing ? 0 : -60)
                
                content
            }
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minY
                    )
                }
            )
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            offset = value
            
            // Trigger refresh when pulled down enough and not already refreshing
            if value > 80 && !isRefreshing {
                triggerRefresh()
            }
        }
    }
    
    private func triggerRefresh() {
        isRefreshing = true
        HapticManager.shared.impact(.medium)
        
        Task {
            await onRefresh()
            await MainActor.run {
                withAnimation(.spring(response: 0.3)) {
                    isRefreshing = false
                }
            }
        }
    }
}

struct RefreshIndicator: View {
    let isRefreshing: Bool
    let offset: CGFloat
    
    private var rotationAngle: Double {
        if isRefreshing {
            return 360
        }
        return min(Double(offset) * 2, 180)
    }
    
    private var opacity: Double {
        if isRefreshing {
            return 1.0
        }
        return min(Double(offset) / 60, 1.0)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isRefreshing ? "arrow.clockwise" : "arrow.down")
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsChrome1)
                .rotationEffect(.degrees(rotationAngle))
                .animation(
                    isRefreshing ?
                    .linear(duration: 1).repeatForever(autoreverses: false) :
                    .spring(response: 0.3),
                    value: rotationAngle
                )
            
            if isRefreshing {
                Text("Refreshing...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsCotton)
            } else if offset > 60 {
                Text("Release to refresh")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsCotton)
            } else if offset > 20 {
                Text("Pull to refresh")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsCottonLight)
            }
        }
        .opacity(opacity)
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
#Preview {
    RefreshableScrollView {
        VStack(spacing: 20) {
            ForEach(0..<20, id: \.self) { index in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.modaicsChrome1, .modaicsChrome2],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 80)
                    .overlay(
                        Text("Item \(index + 1)")
                            .foregroundColor(.modaicsDarkBlue)
                            .font(.headline)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    } onRefresh: {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
    .background(
        LinearGradient(
            colors: [.modaicsDarkBlue, .modaicsMidBlue],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    )
}
