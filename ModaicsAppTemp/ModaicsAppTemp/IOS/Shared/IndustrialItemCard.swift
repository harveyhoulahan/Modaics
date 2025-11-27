//
//  IndustrialItemCard.swift
//  ModaicsAppTemp
//
//  Unified industrial-themed item card for all platforms (Depop, Grailed, Vinted)
//  Created by Harvey Houlahan on 11/27/2025.
//

import SwiftUI

// MARK: - Industrial Item Card (Universal)
struct IndustrialItemCard: View {
    let item: FashionItem
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var isLiked = false
    @State private var showDetail = false
    
    var body: some View {
        Button {
            HapticManager.shared.impact(.light)
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Image Section
                imageContainer
                
                // Content Section
                contentSection
            }
            .background(Color.appSurface)
            .overlay(
                Rectangle()
                    .stroke(Color.appBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            ItemDetailView(item: item)
                .environmentObject(viewModel)
        }
    }
    
    private var imageContainer: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                // Main image
                if let imageURL = item.imageURLs.first, !imageURL.isEmpty {
                    PremiumCachedImage(url: imageURL, contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.appBg)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 32, weight: .medium, design: .monospaced))
                                    .foregroundColor(.appTextMuted.opacity(0.3))
                                
                                Text("NO IMAGE")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .tracking(1)
                                    .foregroundColor(.appTextMuted.opacity(0.5))
                            }
                        )
                }
                
                // Overlay badges and actions
                overlayContent
            }
        }
        .frame(height: 280)
    }
    
    private var overlayContent: some View {
        VStack(spacing: 0) {
            // Top row: Platform badge + Like button
            HStack(alignment: .top) {
                // Platform badge
                if let externalURL = item.externalURL, !externalURL.isEmpty {
                    platformBadge(url: externalURL)
                }
                
                Spacer()
                
                // Like button
                likeButton
            }
            .padding(12)
            
            Spacer()
            
            // Bottom row: Sustainability + Similarity
            HStack(alignment: .bottom) {
                // Sustainability badge
                if item.sustainabilityScore.totalScore > 0 {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(sustainabilityColor)
                            .frame(width: 3, height: 16)
                        
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("\(item.sustainabilityScore.totalScore)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.75))
                }
                
                Spacer()
                
                // AI Similarity badge
                if let similarity = item.similarity, similarity > 0 {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.appRed)
                            .frame(width: 3, height: 16)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.appRed)
                        
                        Text("\(Int(similarity * 100))%")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("MATCH")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .tracking(0.5)
                            .foregroundColor(.appTextMuted)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.75))
                }
            }
            .padding(12)
        }
    }
    
    private var likeButton: some View {
        Button {
            HapticManager.shared.impact(.light)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isLiked.toggle()
            }
            viewModel.toggleLike(for: item)
        } label: {
            Rectangle()
                .fill(Color.black.opacity(0.75))
                .frame(width: 36, height: 36)
                .overlay(
                    Rectangle()
                        .stroke(isLiked ? Color.appRed : Color.appBorder, lineWidth: 1)
                )
                .overlay(
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isLiked ? .appRed : .white)
                        .scaleEffect(isLiked ? 1.1 : 1.0)
                )
        }
        .buttonStyle(.plain)
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Brand + Category row
            HStack {
                if !item.brand.isEmpty && item.brand != "Unknown" {
                    Text(item.brand.uppercased())
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .tracking(1)
                        .foregroundColor(.appTextMuted)
                        .lineLimit(1)
                } else {
                    Text("MARKETPLACE")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .tracking(1)
                        .foregroundColor(.appTextMuted)
                }
                
                Spacer()
                
                // Category badge
                if item.category != .other {
                    Rectangle()
                        .fill(Color.appSurface)
                        .frame(height: 16)
                        .overlay(
                            Text(item.category.rawValue.uppercased())
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .tracking(0.5)
                                .foregroundColor(.appTextMuted)
                                .padding(.horizontal, 6)
                        )
                        .overlay(
                            Rectangle()
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                }
            }
            
            // Item name
            Text(item.name)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.appTextMain)
                .lineLimit(2)
                .frame(height: 32, alignment: .top)
                .multilineTextAlignment(.leading)
            
            // Price row with condition
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("$\(Int(max(0, item.listingPrice.isNaN ? 0 : item.listingPrice)))")
                        .font(.system(size: 17, weight: .medium, design: .monospaced))
                        .foregroundColor(.appRed)
                    
                    // Original price if discounted
                    if !item.originalPrice.isNaN && !item.listingPrice.isNaN && 
                       item.originalPrice > item.listingPrice && !item.priceReduction.isNaN && item.priceReduction > 0 {
                        HStack(spacing: 4) {
                            Text("$\(Int(item.originalPrice))")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .strikethrough()
                                .foregroundColor(.appTextMuted)
                            
                            Rectangle()
                                .fill(Color.appRed)
                                .frame(width: 2, height: 12)
                            
                            Text("\(Int(item.priceReduction))% OFF")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .tracking(0.5)
                                .foregroundColor(.appRed)
                        }
                    }
                }
                
                Spacer()
                
                // Condition indicator
                if item.condition != .new {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(conditionColor)
                            .frame(width: 3, height: 14)
                        
                        Text(item.condition.rawValue.uppercased())
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .tracking(0.5)
                            .foregroundColor(.appTextMuted)
                    }
                }
            }
            
            // Location if available
            if !item.location.isEmpty && item.location != "Unknown" {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.appTextMuted)
                    
                    Text(item.location.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(0.5)
                        .foregroundColor(.appTextMuted)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .frame(height: 110)
    }
    
    // MARK: - Helper Functions
    
    private func platformBadge(url: String) -> some View {
        let info = platformInfo(url)
        return HStack(spacing: 4) {
            Rectangle()
                .fill(info.color)
                .frame(width: 3, height: 14)
            
            Text(info.name)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(1)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.75))
    }
    
    private func platformInfo(_ url: String) -> (name: String, color: Color) {
        if url.contains("depop") {
            return ("DEPOP", Color(red: 1.0, green: 0.25, blue: 0.25))
        } else if url.contains("grailed") {
            return ("GRAILED", Color(red: 0.5, green: 0.5, blue: 0.5))
        } else if url.contains("vinted") {
            return ("VINTED", Color(red: 0.2, green: 0.6, blue: 0.9))
        } else {
            return ("MARKET", Color.appRed)
        }
    }
    
    private var sustainabilityColor: Color {
        let score = item.sustainabilityScore.totalScore
        if score >= 75 { return Color.green }
        else if score >= 50 { return Color.yellow }
        else if score >= 25 { return Color.orange }
        else { return Color.red }
    }
    
    private var conditionColor: Color {
        switch item.condition {
        case .new: return .green
        case .likeNew: return Color(red: 0.4, green: 0.8, blue: 0.4)
        case .excellent: return .yellow
        case .good: return .orange
        case .fair: return .red
        }
    }
}

// Type alias for backward compatibility
typealias EnhancedItemCard = IndustrialItemCard
typealias OptimizedItemCard = IndustrialItemCard
