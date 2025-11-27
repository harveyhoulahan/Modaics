//
//  SkeletonLoadingView.swift
//  Modaics
//
//  Skeleton loading states for smoother perceived performance
//

import SwiftUI

// MARK: - Skeleton Item Card
struct SkeletonItemCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(skeletonGradient)
                .aspectRatio(0.7, contentMode: .fit)
                .modifier(SkeletonAnimation(isAnimating: $isAnimating))
            
            // Title placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(skeletonGradient)
                .frame(height: 16)
                .frame(maxWidth: .infinity)
                .modifier(SkeletonAnimation(isAnimating: $isAnimating))
            
            // Price placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(skeletonGradient)
                .frame(width: 60, height: 14)
                .modifier(SkeletonAnimation(isAnimating: $isAnimating))
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private var skeletonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.modaicsDarkBlue.opacity(0.3),
                Color.modaicsMidBlue.opacity(0.3)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Skeleton Event Card
struct SkeletonEventCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Badge placeholder
                Capsule()
                    .fill(skeletonGradient)
                    .frame(width: 80, height: 28)
                    .modifier(SkeletonAnimation(isAnimating: $isAnimating))
                
                Spacer()
                
                // Price placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonGradient)
                    .frame(width: 50, height: 20)
                    .modifier(SkeletonAnimation(isAnimating: $isAnimating))
            }
            
            // Title placeholders
            RoundedRectangle(cornerRadius: 4)
                .fill(skeletonGradient)
                .frame(height: 20)
                .modifier(SkeletonAnimation(isAnimating: $isAnimating))
            
            RoundedRectangle(cornerRadius: 4)
                .fill(skeletonGradient)
                .frame(height: 20)
                .frame(width: 200)
                .modifier(SkeletonAnimation(isAnimating: $isAnimating))
            
            // Host placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(skeletonGradient)
                .frame(width: 120, height: 14)
                .modifier(SkeletonAnimation(isAnimating: $isAnimating))
            
            // Details placeholders
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(skeletonGradient)
                        .frame(height: 13)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .modifier(SkeletonAnimation(isAnimating: $isAnimating))
                }
            }
        }
        .padding(16)
        .background(Color.modaicsDarkBlue.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            isAnimating = true
        }
    }
    
    private var skeletonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.modaicsDarkBlue.opacity(0.3),
                Color.modaicsMidBlue.opacity(0.3)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Skeleton List Item
struct SkeletonListItem: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 12)
                .fill(skeletonGradient)
                .frame(width: 80, height: 80)
                .modifier(SkeletonAnimation(isAnimating: $isAnimating))
            
            VStack(alignment: .leading, spacing: 8) {
                // Title
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonGradient)
                    .frame(height: 16)
                    .modifier(SkeletonAnimation(isAnimating: $isAnimating))
                
                // Subtitle
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonGradient)
                    .frame(width: 120, height: 14)
                    .modifier(SkeletonAnimation(isAnimating: $isAnimating))
                
                // Price
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonGradient)
                    .frame(width: 60, height: 14)
                    .modifier(SkeletonAnimation(isAnimating: $isAnimating))
            }
            
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private var skeletonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.modaicsDarkBlue.opacity(0.3),
                Color.modaicsMidBlue.opacity(0.3)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Skeleton Animation Modifier
struct SkeletonAnimation: ViewModifier {
    @Binding var isAnimating: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .modaicsChrome1.opacity(0.4),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isAnimating ? 300 : -300)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Skeleton Grid
struct SkeletonItemGrid: View {
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(0..<6, id: \.self) { _ in
                SkeletonItemCard()
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Skeleton Event List
struct SkeletonEventList: View {
    var body: some View {
        VStack(spacing: 20) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonEventCard()
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        LinearGradient(
            colors: [.modaicsDarkBlue, .modaicsMidBlue],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 40) {
                Text("Item Grid Skeleton")
                    .font(.headline)
                    .foregroundColor(.modaicsCotton)
                
                SkeletonItemGrid()
                
                Text("Event Card Skeleton")
                    .font(.headline)
                    .foregroundColor(.modaicsCotton)
                
                SkeletonEventList()
                
                Text("List Item Skeleton")
                    .font(.headline)
                    .foregroundColor(.modaicsCotton)
                
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonListItem()
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 40)
        }
    }
}
