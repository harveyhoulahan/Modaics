//
//  HomeView.swift
//  ModaicsAppTemp
//
//  Premium curated homepage with AI/ML recommendations, events, and database items
//  Dark Green Porsche Aesthetic - Luxury Sustainable Fashion
//  Created by Harvey Houlahan on 6/6/2025.
//

import SwiftUI

struct HomeView: View {
    let userType: UserType
    @EnvironmentObject var viewModel: FashionViewModel

    // UI state
    @State private var headerOffset: CGFloat = -50
    @State private var sectionsVisible = false
    @State private var hasAnimated = false
    @State private var selectedEvent: CommunityEvent?
    @State private var selectedItem: FashionItem?

    // sheets
    @State private var showNotifications = false
    @State private var showSettings = false

    // MARK: - body
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium dark green gradient background - Porsche aesthetic
                LinearGradient.forestBackground
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        // Header
                        header
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .offset(y: headerOffset)

                        // Hero Section
                        heroSection
                            .padding(.horizontal, 20)
                            .opacity(sectionsVisible ? 1 : 0)

                        // Curated Events Section
                        curatedEventsSection
                            .opacity(sectionsVisible ? 1 : 0)

                        // AI-Powered Recommendations
                        aiRecommendationsSection
                            .opacity(sectionsVisible ? 1 : 0)

                        // Trending Now (from database)
                        trendingItemsSection
                            .opacity(sectionsVisible ? 1 : 0)

                        // Sustainability Impact
                        if userType == .consumer {
                            sustainabilitySection
                                .padding(.horizontal, 20)
                                .opacity(sectionsVisible ? 1 : 0)
                        }

                        // Quick Actions
                        quickActionsSection
                            .padding(.horizontal, 20)
                            .opacity(sectionsVisible ? 1 : 0)

                        Spacer(minLength: 100)
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    HapticManager.shared.impact(.light)
                    await refreshContent()
                    HapticManager.shared.success()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(event: event)
        }
        .sheet(isPresented: $showNotifications) { NotificationsView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true
            runAppearAnimations()
            loadCuratedContent()
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("modaics")
                    .font(.forestDisplay(28))
                    .foregroundStyle(.luxeGoldGradient)
                
                Text(greetingText)
                    .font(.forestCaption(14))
                    .foregroundColor(.sageMuted)
            }

            Spacer()

            HStack(spacing: 16) {
                Button {
                    HapticManager.shared.buttonTap()
                    showNotifications = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.title3)
                            .foregroundColor(.luxeGold)
                        
                        // Notification badge
                        Circle()
                            .fill(Color.emerald)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -4)
                    }
                }
                
                Button {
                    HapticManager.shared.buttonTap()
                    showSettings = true
                } label: {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.luxeGold)
                }
            }
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(userType == .consumer ? "Your Wardrobe" : "Dashboard")
                .font(.forestDisplay(32))
                .foregroundColor(.sageWhite)
            
            HStack(spacing: 16) {
                // Stats cards with gold accents
                StatCard(
                    icon: "square.grid.3x3.fill",
                    value: "\(viewModel.allItems.count)",
                    label: "Items",
                    color: .luxeGold
                )
                
                StatCard(
                    icon: "heart.fill",
                    value: "\(viewModel.likedIDs.count)",
                    label: "Saved",
                    color: .emerald
                )
                
                StatCard(
                    icon: "leaf.fill",
                    value: "\(viewModel.calculateUserSustainabilityScore())%",
                    label: "Eco Score",
                    color: .organicGreen
                )
            }
        }
    }

    // MARK: - Curated Events Section
    private var curatedEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Happening Near You")
                        .font(.forestHeadline(18))
                        .foregroundColor(.sageWhite)
                    
                    Text("Events worth checking out")
                        .font(.forestCaption(13))
                        .foregroundColor(.sageMuted)
                }
                
                Spacer()
                
                NavigationLink(destination: CommunityFeedView().environmentObject(viewModel)) {
                    Text("See All")
                        .font(.forestCaption(14))
                        .foregroundColor(.luxeGold)
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(upcomingEvents.prefix(5)) { event in
                        CuratedEventCard(event: event) {
                            selectedEvent = event
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - AI Recommendations Section
    private var aiRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundStyle(.luxeGoldGradient)
                    
                    Text("Picked for You")
                        .font(.forestHeadline(18))
                        .foregroundColor(.sageWhite)
                }
                
                Spacer()
                
                Text("AI-powered")
                    .font(.forestCaption(11))
                    .foregroundColor(.luxeGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(.luxeGold.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(.luxeGold.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(aiRecommendedItems.prefix(10)) { item in
                        HomeCompactItemCard(item: item)
                            .environmentObject(viewModel)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Trending Items Section
    private var trendingItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.earthAmber)
                    
                    Text("Trending Now")
                        .font(.forestHeadline(18))
                        .foregroundColor(.sageWhite)
                }
                
                Spacer()
                
                NavigationLink(destination: DiscoverView().environmentObject(viewModel)) {
                    Text("Explore")
                        .font(.forestCaption(14))
                        .foregroundColor(.luxeGold)
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(trendingItems.prefix(8)) { item in
                        EnhancedItemCard(item: item)
                            .frame(width: 180)
                            .environmentObject(viewModel)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Sustainability Section
    private var sustainabilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.emerald)
                
                Text("Impact This Month")
                    .font(.forestHeadline(18))
                    .foregroundColor(.sageWhite)
            }
            
            VStack(spacing: 12) {
                ImpactRow(
                    icon: "drop.fill",
                    label: "Water Saved",
                    value: "2,847 L",
                    color: .natureTeal,
                    description: "compared to new"
                )
                
                ImpactRow(
                    icon: "cloud.fill",
                    label: "Carbon Offset",
                    value: "\(viewModel.calculateUserSustainabilityScore()) kg",
                    color: .emerald,
                    description: "emissions avoided"
                )
                
                ImpactRow(
                    icon: "arrow.3.trianglepath",
                    label: "Items Circulated",
                    value: "\(viewModel.userWardrobe.filter { $0.sustainabilityScore.isRecycled }.count)",
                    color: .earthAmber,
                    description: "given new life"
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: ForestRadius.xlarge)
                    .fill(.forestMid.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: ForestRadius.xlarge)
                            .stroke(
                                LinearGradient(
                                    colors: [.emerald.opacity(0.3), .natureTeal.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
    }

    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.forestHeadline(18))
                .foregroundColor(.sageWhite)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                QuickActionCard(
                    icon: "plus.circle.fill",
                    title: "List Item",
                    subtitle: "Sell or swap",
                    gradient: [.luxeGold, .luxeGoldBright]
                )
                
                QuickActionCard(
                    icon: "magnifyingglass.circle.fill",
                    title: "AI Search",
                    subtitle: "Find anything",
                    gradient: [.emerald, .emeraldDeep]
                )
                
                QuickActionCard(
                    icon: "arrow.triangle.swap",
                    title: "Swap Meet",
                    subtitle: "Join event",
                    gradient: [.organicGreen, .emerald]
                )
                
                QuickActionCard(
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    title: "Analytics",
                    subtitle: "View stats",
                    gradient: [.natureTeal, .forestLight]
                )
            }
        }
    }

    // MARK: - Helpers & Computed Properties
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = viewModel.currentUser?.username ?? "there"
        
        switch hour {
        case 0..<12: return "Morning, \(name)"
        case 12..<17: return "Afternoon, \(name)"
        default: return "Evening, \(name)"
        }
    }
    
    private var upcomingEvents: [CommunityEvent] {
        CommunityEvent.mockEvents
            .filter { $0.date > Date() }
            .sorted { $0.date < $1.date }
    }
    
    private var aiRecommendedItems: [FashionItem] {
        // AI/ML powered recommendations based on user preferences
        let userLikedCategories = viewModel.allItems
            .filter { viewModel.isLiked($0) }
            .map { $0.category }
        
        let userLikedBrands = viewModel.allItems
            .filter { viewModel.isLiked($0) }
            .map { $0.brand }
        
        return viewModel.allItems
            .filter { item in
                userLikedCategories.contains(item.category) ||
                userLikedBrands.contains(item.brand) ||
                item.sustainabilityScore.totalScore >= 70
            }
            .shuffled()
    }
    
    private var trendingItems: [FashionItem] {
        // Most popular items from database
        viewModel.allItems
            .filter { $0.listingPrice > 0 }
            .sorted { $0.sustainabilityScore.totalScore > $1.sustainabilityScore.totalScore }
    }
    
    private func loadCuratedContent() {
        // Load initial recommendations if empty
        if viewModel.recommendedItems.isEmpty, let firstItem = viewModel.allItems.first {
            viewModel.loadRecommendations(for: firstItem)
        }
    }

    private func runAppearAnimations() {
        withAnimation(.forestElegant) {
            headerOffset = 0
        }
        
        withAnimation(.forestElegant.delay(0.2)) {
            sectionsVisible = true
        }
    }
    
    private func refreshContent() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        loadCuratedContent()
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.forestHeadline(20))
                .foregroundColor(.sageWhite)
            
            Text(label)
                .font(.forestCaption(12))
                .foregroundColor(.sageMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: ForestRadius.large)
                .fill(.forestMid.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: ForestRadius.large)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct CuratedEventCard: View {
    let event: CommunityEvent
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Event type badge
                HStack {
                    Image(systemName: event.type.icon)
                        .font(.system(size: 12))
                    Text(event.type.rawValue)
                        .font(.forestCaption(12))
                }
                .foregroundColor(.sageWhite)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(event.type.color)
                .clipShape(Capsule())
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.forestHeadline(16))
                        .foregroundColor(.sageWhite)
                        .lineLimit(2)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(event.date, style: .date)
                            .font(.forestCaption(12))
                    }
                    .foregroundColor(.sageMuted)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(event.attendees) attending")
                            .font(.forestCaption(12))
                    }
                    .foregroundColor(.sageMuted)
                }
            }
            .padding(16)
            .frame(width: 220, height: 200)
            .background(
                RoundedRectangle(cornerRadius: ForestRadius.xlarge)
                    .fill(
                        LinearGradient(
                            colors: [
                                .forestMid.opacity(0.8),
                                event.type.color.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: ForestRadius.xlarge)
                            .stroke(event.type.color.opacity(0.4), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

fileprivate struct HomeCompactItemCard: View {
    let item: FashionItem
    @EnvironmentObject var viewModel: FashionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            RoundedRectangle(cornerRadius: ForestRadius.medium)
                .fill(.surfaceElevated)
                .aspectRatio(3/4, contentMode: .fit)
                .frame(width: 140)
                .overlay(
                    Group {
                        if let imageURL = item.imageURLs.first {
                            PremiumCachedImage(url: imageURL, contentMode: .fill)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: ForestRadius.medium))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.brand)
                    .font(.forestCaption(12))
                    .foregroundColor(.luxeGold)
                
                Text(item.name)
                    .font(.forestBody(14))
                    .foregroundColor(.sageWhite)
                    .lineLimit(2)
                
                if item.listingPrice > 0 {
                    Text("$\(Int(item.listingPrice))")
                        .font(.forestCaption(13))
                        .foregroundColor(.luxeGoldBright)
                }
            }
        }
        .frame(width: 140)
    }
}

struct ImpactRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.forestCaption(14))
                    .foregroundColor(.sageMuted)
                
                Text(value)
                    .font(.forestHeadline(20))
                    .foregroundColor(.sageWhite)
                
                Text(description)
                    .font(.forestCaption(11))
                    .foregroundColor(.sageSubtle)
            }
            
            Spacer()
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.forestHeadline(16))
                    .foregroundColor(.sageWhite)
                
                Text(subtitle)
                    .font(.forestCaption(12))
                    .foregroundColor(.sageMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: ForestRadius.large)
                .fill(.forestMid.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: ForestRadius.large)
                        .stroke(
                            LinearGradient(
                                colors: gradient.map { $0.opacity(0.4) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

#Preview("Home View") {
    HomeView(userType: .consumer)
        .environmentObject(FashionViewModel())
}
