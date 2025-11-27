//
//  EnhancedItemCard.swift
//  ModaicsAppTemp
//
//  EnhancedUIComponents.swift
//  Premium UI components for Modaics that elevate the user experience
//
//  Created by Harvey Houlahan on 6/6/2025.
//


import SwiftUI
import Foundation

// MARK: - Enhanced Item Card
struct EnhancedItemCard: View {
    let item: FashionItem
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var isLiked = false
    @State private var imageLoaded = false
    @State private var sustainabilityVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced image container
            imageContainer
            
            // Content section
            contentSection
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.modaicsSpring.delay(0.2)) {
                sustainabilityVisible = true
            }
        }
    }
    
    private var placeholderView: some View {
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
                .font(.modaicsCaption(12))
                .foregroundColor(.modaicsCottonLight)
        }
    }
    
    private var imageContainer: some View {
        ZStack {
            // Main image with sophisticated loading
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [.modaicsSurface2, .modaicsSurface3],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .aspectRatio(3/4, contentMode: .fit)
                .overlay(
                    Group {
                        if let imageURLString = item.imageURLs.first, !imageURLString.isEmpty {
                            // Use premium cached image loader
                            PremiumCachedImage(url: imageURLString, contentMode: .fill)
                        } else {
                            placeholderView
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Floating action buttons
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        // Like button with animation
                        Button {
                            withAnimation(.modaicsElastic) {
                                isLiked.toggle()
                                viewModel.toggleLike(for: item)
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isLiked ? .red : .modaicsChrome1)
                                    .scaleEffect(isLiked ? 1.2 : 1.0)
                            }
                        }
                        
                        // Quick view button
                        Button {
                            // Quick view action
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "eye")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.modaicsChrome1)
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding(12)
            
            // Sustainability badge
            if sustainabilityVisible {
                VStack {
                    Spacer()
                    HStack {
                        SustainabilityBadge(score: item.sustainabilityScore)
                        Spacer()
                        
                        // Platform badge (if from external marketplace)
                        if let externalURL = item.externalURL, !externalURL.isEmpty {
                            PlatformBadge(url: externalURL)
                        }
                    }
                }
                .padding(12)
            }
            
            // Similarity badge (if AI search result)
            if let similarity = item.similarity, similarity > 0 {
                VStack {
                    HStack {
                        Spacer()
                        SimilarityBadge(similarity: similarity)
                    }
                    Spacer()
                }
                .padding(.top, 60)
                .padding(.trailing, 12)
            }
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Brand and category
            HStack {
                Text(item.brand)
                    .font(.modaicsCaption(12))
                    .foregroundColor(.modaicsChrome2)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
                
                CategoryPill(category: item.category)
            }
            
            // Item name
            Text(item.name)
                .font(.modaicsHeadline(16))
                .foregroundColor(.modaicsCotton)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Price section with enhanced styling
            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("$\(Int(max(0, item.listingPrice.isNaN ? 0 : item.listingPrice)))")
                        .font(.modaicsHeadline(20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.modaicsChrome1, .modaicsChrome2],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    if !item.originalPrice.isNaN && !item.listingPrice.isNaN && !item.priceReduction.isNaN && 
                       item.originalPrice > item.listingPrice && item.priceReduction > 0 && item.priceReduction.isFinite {
                        HStack(spacing: 4) {
                            Text("$\(Int(item.originalPrice))")
                                .font(.modaicsCaption(12))
                                .strikethrough()
                                .foregroundColor(.modaicsCottonLight)
                            
                            Text("\(Int(item.priceReduction))% off")
                                .font(.modaicsCaption(10))
                                .fontWeight(.medium)
                                .foregroundColor(.modaicsError)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.modaicsError.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
                
                // Quick action buttons
                HStack(spacing: 8) {
                    Button {
                        // Add to wardrobe
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.modaicsDenim1, .modaicsDenim2],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            
            // Location and time
            HStack {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundColor(.modaicsChrome2)
                
                Text(item.location)
                    .font(.modaicsCaption(11))
                    .foregroundColor(.modaicsCottonLight)
                
                Spacer()
                
                Text("2h ago")
                    .font(.modaicsCaption(11))
                    .foregroundColor(.modaicsCottonLight)
            }
        }
        .padding(16)
    }
}

// MARK: - Sustainability Badge
struct SustainabilityBadge: View {
    let score: SustainabilityScore
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 6) {
            // Animated sustainability icon
            ZStack {
                Circle()
                    .fill(score.sustainabilityColor.opacity(0.2))
                    .frame(width: 20, height: 20)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(score.sustainabilityColor)
                    .scaleEffect(1.0 + sin(animationProgress * .pi * 2) * 0.1)
            }
            
            Text("\(score.totalScore)")
                .font(.modaicsCaption(12))
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if score.fibreTraceVerified {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.modaicsAccent)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(score.sustainabilityColor.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationProgress = 1
            }
        }
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    let category: Category
    
    var body: some View {
        Text(category.rawValue)
            .font(.modaicsCaption(10))
            .fontWeight(.medium)
            .foregroundColor(.modaicsChrome1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.modaicsChrome1.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(Color.modaicsChrome1.opacity(0.3), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Enhanced Home Feed
struct EnhancedHomeFeed: View {
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var feedItems: [FeedItem] = []
    @State private var refreshOffset: CGFloat = 0
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Personalized header
                personalizedHeader
                
                // Mixed content feed
                ForEach(feedItems, id: \.id) { item in
                    feedItemView(item)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
        .refreshable {
            await refreshFeed()
        }
        .onAppear {
            generateFeedItems()
        }
    }
    
    private var personalizedHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good morning")
                        .font(.modaicsCaption(14))
                        .foregroundColor(.modaicsCottonLight)
                    
                    Text(viewModel.currentUser?.username ?? "Sustainable Style Lover")
                        .font(.modaicsDisplay(28))
                        .foregroundColor(.modaicsCotton)
                }
                
                Spacer()
                
                // Daily sustainability score
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color.modaicsAccent.opacity(0.3), lineWidth: 3)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.calculateUserSustainabilityScore()) / 100)
                            .stroke(Color.modaicsAccent, lineWidth: 3)
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(viewModel.calculateUserSustainabilityScore())")
                            .font(.modaicsHeadline(16))
                            .foregroundColor(.modaicsCotton)
                    }
                    
                    Text("Eco Score")
                        .font(.modaicsCaption(10))
                        .foregroundColor(.modaicsCottonLight)
                }
            }
            
            // Quick stats carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    QuickStatCard(
                        icon: "drop.fill",
                        value: "2.5K L",
                        label: "Water Saved",
                        color: .blue
                    )
                    
                    QuickStatCard(
                        icon: "leaf.fill",
                        value: "15 kg",
                        label: "CO₂ Reduced",
                        color: .modaicsAccent
                    )
                    
                    QuickStatCard(
                        icon: "heart.fill",
                        value: "\(viewModel.likedIDs.count)",
                        label: "Liked Items",
                        color: .red
                    )
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    @ViewBuilder
    private func feedItemView(_ item: FeedItem) -> some View {
        switch item {
        case .fashionItem(let fashionItem):
            EnhancedItemCard(item: fashionItem)
                .environmentObject(viewModel)
        case .communityPost(let post):
            CommunityPostCard(post: post)
        case .event(let event):
            EventHighlightCard(event: event)
        case .sustainabilityTip(let tip):
            SustainabilityTipCard(tip: tip)
        }
    }
    
    private func generateFeedItems() {
        var items: [FeedItem] = []
        
        // Add fashion items
        for item in viewModel.allItems.prefix(3) {
            items.append(.fashionItem(item))
        }
        
        // Add community content
        items.append(.communityPost(CommunityPost.sample))
        items.append(.sustainabilityTip(SustainabilityTip.sample))
        items.append(.event(Event.sample))
        
        // Add more fashion items
        for item in viewModel.allItems.dropFirst(3).prefix(2) {
            items.append(.fashionItem(item))
        }
        
        feedItems = items
    }
    
    private func refreshFeed() async {
        // Simulate refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        generateFeedItems()
    }
}

// MARK: - Feed Item Types
enum FeedItem {
    case fashionItem(FashionItem)
    case communityPost(CommunityPost)
    case event(Event)
    case sustainabilityTip(SustainabilityTip)
    
    var id: String {
        switch self {
        case .fashionItem(let item): return "fashion_\(item.id)"
        case .communityPost(let post): return "post_\(post.id)"
        case .event(let event): return "event_\(event.id)"
        case .sustainabilityTip(let tip): return "tip_\(tip.id)"
        }
    }
}


struct Event {
    let id = UUID()
    let title: String
    let location: String
    let date: Date
    let attendees: Int
    
    static let sample = Event(
        title: "Melbourne Sustainable Fashion Swap",
        location: "Federation Square",
        date: Date().addingTimeInterval(86400 * 7),
        attendees: 45
    )
}

struct SustainabilityTip {
    let id = UUID()
    let title: String
    let content: String
    let category: String
    
    static let sample = SustainabilityTip(
        title: "Care Tips for Longevity",
        content: "Washing your clothes in cold water can extend their lifespan by up to 3x while reducing energy consumption by 90%",
        category: "Care"
    )
}

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.modaicsHeadline(16))
                    .foregroundColor(.modaicsCotton)
                
                Text(label)
                    .font(.modaicsCaption(12))
                    .foregroundColor(.modaicsCottonLight)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Community Post Card
struct CommunityPostCard: View {
    let post: CommunityPost
    @State private var isLiked = false
    @State private var likeCount: Int
    
    init(post: CommunityPost) {
        self.post = post
        self._likeCount = State(initialValue: post.likes)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User header
            HStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.modaicsDenim1, .modaicsDenim2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(post.user.prefix(1)).uppercased())
                            .font(.modaicsHeadline(16))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(post.user)")
                        .font(.modaicsHeadline(14))
                        .foregroundColor(.modaicsCotton)
                    
                    Text("2 hours ago")
                        .font(.modaicsCaption(12))
                        .foregroundColor(.modaicsCottonLight)
                }
                
                Spacer()
                
                Button {
                    // Follow action
                } label: {
                    Text("Follow")
                        .font(.modaicsCaption(12))
                        .fontWeight(.medium)
                        .foregroundColor(.modaicsDenim1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .stroke(Color.modaicsDenim1, lineWidth: 1)
                        )
                }
            }
            
            // Content
            Text(post.content)
                .font(.modaicsBody(15))
                .foregroundColor(.modaicsCotton)
                .lineSpacing(4)
            
            // Actions
            HStack(spacing: 20) {
                Button {
                    withAnimation(.modaicsElastic) {
                        isLiked.toggle()
                        likeCount += isLiked ? 1 : -1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .modaicsChrome2)
                            .scaleEffect(isLiked ? 1.1 : 1.0)
                        
                        Text("\(likeCount)")
                            .font(.modaicsCaption(14))
                            .foregroundColor(.modaicsChrome2)
                    }
                }
                
                Button {
                    // Comment action
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left")
                            .foregroundColor(.modaicsChrome2)
                        
                        Text("5")
                            .font(.modaicsCaption(14))
                            .foregroundColor(.modaicsChrome2)
                    }
                }
                
                Spacer()
                
                Button {
                    // Share action
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.modaicsChrome2)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.modaicsChrome1.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Event Highlight Card
struct EventHighlightCard: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 16) {
            // Event visual
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.modaicsAccent, Color(red: 0.15, green: 0.5, blue: 0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("SWAP")
                            .font(.modaicsCaption(10))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.modaicsHeadline(16))
                    .foregroundColor(.modaicsCotton)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.modaicsChrome2)
                    
                    Text(event.location)
                        .font(.modaicsCaption(13))
                        .foregroundColor(.modaicsCottonLight)
                }
                
                HStack {
                    Text("\(event.attendees) attending")
                        .font(.modaicsCaption(12))
                        .foregroundColor(.modaicsAccent)
                    
                    Spacer()
                    
                    Button("Join") {
                        // Join event action
                    }
                    .font(.modaicsCaption(12))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.modaicsAccent)
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.modaicsAccent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Sustainability Tip Card
struct SustainabilityTipCard: View {
    let tip: SustainabilityTip
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    SustainabilityIcon(size: 14)
                    
                    Text("Sustainability Tip")
                        .font(.modaicsCaption(12))
                        .fontWeight(.medium)
                        .foregroundColor(.modaicsAccent)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                
                Spacer()
                
                Text(tip.category)
                    .font(.modaicsCaption(10))
                    .foregroundColor(.modaicsAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.modaicsAccent.opacity(0.15))
                    )
            }
            
            Text(tip.title)
                .font(.modaicsHeadline(16))
                .foregroundColor(.modaicsCotton)
            
            Text(tip.content)
                .font(.modaicsBody(14))
                .foregroundColor(.modaicsCottonLight)
                .lineSpacing(3)
                .lineLimit(isExpanded ? nil : 3)
            
            if tip.content.count > 120 {
                Button(isExpanded ? "Show less" : "Read more") {
                    withAnimation(.modaicsSmoothSpring) {
                        isExpanded.toggle()
                    }
                }
                .font(.modaicsCaption(12))
                .foregroundColor(.modaicsAccent)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.modaicsAccent.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.modaicsAccent.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Platform Badge
struct PlatformBadge: View {
    let url: String
    
    var platformInfo: (name: String, color: Color) {
        if url.contains("depop") {
            return ("Depop", Color.red)
        } else if url.contains("grailed") {
            return ("Grailed", Color.gray)
        } else if url.contains("vinted") {
            return ("Vinted", Color.blue)
        } else {
            return ("Market", Color.modaicsChrome1)
        }
    }
    
    var body: some View {
        Text(platformInfo.name)
            .font(.modaicsCaption(10))
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(platformInfo.color)
            )
    }
}

// MARK: - Similarity Badge
struct SimilarityBadge: View {
    let similarity: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.modaicsAccent)
            
            Text("\(Int(similarity * 100))%")
                .font(.modaicsCaption(11))
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.modaicsAccent.opacity(0.5), lineWidth: 1)
                )
        )
    }
}
