//
//  ShimmerView.swift
//  ModaicsAppTemp
//
//  Elegant shimmer loading effect for skeleton states
//  Created by Harvey Houlahan on 11/26/2025.
//

import SwiftUI

// MARK: - Shimmer Effect Modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    var duration: Double = 1.5
    var bounce: Bool = true
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.6),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(30))
                        .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: bounce)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer(duration: Double = 1.5, bounce: Bool = false) -> some View {
        modifier(ShimmerModifier(duration: duration, bounce: bounce))
    }
}

// MARK: - Skeleton Views
struct SkeletonRectangle: View {
    var width: CGFloat?
    var height: CGFloat
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.2))
            .frame(width: width, height: height)
            .shimmer()
    }
}

struct SkeletonCircle: View {
    var diameter: CGFloat
    
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: diameter, height: diameter)
            .shimmer()
    }
}

struct SkeletonText: View {
    var lines: Int = 1
    var lineHeight: CGFloat = 14
    var lastLineWidth: CGFloat = 0.7
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<lines, id: \.self) { index in
                SkeletonRectangle(
                    width: index == lines - 1 ? nil : nil,
                    height: lineHeight,
                    cornerRadius: 4
                )
                .frame(maxWidth: index == lines - 1 ? .infinity : .infinity)
                .frame(width: index == lines - 1 ? nil : nil)
                .scaleEffect(x: index == lines - 1 ? lastLineWidth : 1.0, anchor: .leading)
            }
        }
    }
}

// MARK: - Item Card Skeleton
struct ItemCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            SkeletonRectangle(height: 200, cornerRadius: 16)
            
            // Title
            SkeletonText(lines: 2, lineHeight: 16, lastLineWidth: 0.6)
            
            // Price and details
            HStack {
                SkeletonRectangle(width: 80, height: 24, cornerRadius: 12)
                Spacer()
                SkeletonCircle(diameter: 32)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Grid Skeleton
struct GridSkeleton: View {
    var columns: Int = 2
    var rows: Int = 3
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: columns),
            spacing: 16
        ) {
            ForEach(0..<(columns * rows), id: \.self) { _ in
                ItemCardSkeleton()
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - List Skeleton
struct ListSkeleton: View {
    var count: Int = 5
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<count, id: \.self) { _ in
                HStack(spacing: 12) {
                    SkeletonRectangle(width: 80, height: 80, cornerRadius: 12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonText(lines: 2, lineHeight: 14)
                        SkeletonRectangle(width: 100, height: 20, cornerRadius: 10)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
            }
        }
        .padding(.horizontal, 20)
    }
}
