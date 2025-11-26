//
//  OptimizedItemCard.swift
//  ModaicsAppTemp
//
//  High-performance item card with cached images and reduced view hierarchy
//  Created by Harvey Houlahan on 11/26/2025.
//

import SwiftUI

// MARK: - Optimized Item Card
struct OptimizedItemCard: View {
    let item: FashionItem
    @EnvironmentObject var viewModel: FashionViewModel
    
    @State private var isLiked = false
    @State private var showQuickView = false
    
    var body: some View {
        Button {
            HapticManager.shared.cardTap()
            showQuickView = true
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showQuickView) {
            ItemDetailView(item: item)
                .environmentObject(viewModel)
        }
    }
    
    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Optimized image with caching
            imageSection
            
            // Streamlined content
            contentSection
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
        .clipped()
        .layoutPriority(1)
    }
    
    @ViewBuilder
    private var imageSection: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                // Cached async image
                if let imageURL = item.imageURLs.first {
                    CachedAsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } placeholder: {
                        SkeletonRectangle(height: geometry.size.height, cornerRadius: 16)
                    }
                } else {
                    placeholderImage
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                
                // Overlay badges and buttons
                overlayContent
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .frame(height: 240)
        .clipped()
    }
    
    @ViewBuilder
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [.modaicsSurface2, .modaicsSurface3],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 240)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "photo.artframe")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.modaicsChrome1.opacity(0.6), .modaicsChrome2.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Premium Fashion")
                        .font(.caption)
                        .foregroundColor(.modaicsCottonLight)
                }
            )
    }
    
    @ViewBuilder
    private var overlayContent: some View {
        VStack {
            // Top row: Like button
            HStack {
                Spacer()
                likeButton
            }
            
            Spacer()
            
            // Bottom row: Badges
            HStack {
                if item.sustainabilityScore.totalScore > 60 {
                    GlassBadge(
                        text: "🌱 \(item.sustainabilityScore.totalScore)",
                        color: .green,
                        size: .small
                    )
                }
                
                Spacer()
                
                if let similarity = item.similarity, similarity > 0 {
                    GlassBadge(
                        text: "\(Int(similarity * 100))% match",
                        color: .modaicsChrome1,
                        size: .small
                    )
                }
            }
        }
        .padding(12)
    }
    
    @ViewBuilder
    private var likeButton: some View {
        Button {
            HapticManager.shared.impact(.light)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isLiked.toggle()
            }
            viewModel.toggleLike(for: item)
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isLiked ? .red : .white)
                    .scaleEffect(isLiked ? 1.1 : 1.0)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Brand tag
            if !item.brand.isEmpty && item.brand != "Unknown" {
                Text(item.brand.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.modaicsChrome1)
                    .tracking(0.5)
            }
            
            // Title
            Text(item.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.modaicsCotton)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Price and category
            HStack {
                Text("$\(Int(item.listingPrice))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.modaicsChrome1, .modaicsChrome2],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
                
                if item.category != .other {
                    Text(item.category.rawValue)
                        .font(.caption2)
                        .foregroundColor(.modaicsCottonLight)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                }
            }
            
            // Condition indicator
            if item.condition != .new {
                HStack(spacing: 4) {
                    Circle()
                        .fill(conditionColor)
                        .frame(width: 6, height: 6)
                    
                    Text(item.condition.rawValue)
                        .font(.caption2)
                        .foregroundColor(.modaicsCottonLight)
                }
            }
        }
        .padding(12)
    }
    
    private var conditionColor: Color {
        switch item.condition {
        case .new: return .green
        case .likeNew: return .blue
        case .excellent: return .teal
        case .good: return .yellow
        case .fair: return .orange
        }
    }
}
