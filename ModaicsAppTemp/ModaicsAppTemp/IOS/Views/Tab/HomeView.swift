//
//  HomeView.swift
//  ModaicsAppTemp
//
//  Premium curated homepage with AI/ML recommendations, events, and database items
//  Created by Harvey Houlahan on 6/6/2025.
//

import SwiftUI

struct HomeView: View {
    let userType: ContentView.UserType
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
                // Premium gradient background
                LinearGradient(
                    colors: [.modaicsDarkBlue, .modaicsMidBlue],
                    startPoint: .top,
                    endPoint: .bottom
                )
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
                        if userType == .user {
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
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.modaicsChrome1, .modaicsChrome2],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(greetingText)
                    .font(.system(size: 14))
                    .foregroundColor(.modaicsCottonLight)
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
                            .foregroundColor(.modaicsChrome1)
                        
                        // Notification badge
                        Circle()
                            .fill(Color.red)
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
                        .foregroundColor(.modaicsChrome1)
                }
            }
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(userType == .user ? "Your Wardrobe" : "Dashboard")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.modaicsCotton)
            
            HStack(spacing: 16) {
                // Stats cards
                StatCard(
                    icon: "square.grid.3x3.fill",
                    value: "\(viewModel.allItems.count)",
                    label: "Items",
                    color: .modaicsChrome1
                )
                
                StatCard(
                    icon: "heart.fill",
                    value: "\(viewModel.likedIDs.count)",
                    label: "Saved",
                    color: .red
                )
                
                StatCard(
                    icon: "leaf.fill",
                    value: "\(viewModel.calculateUserSustainabilityScore())%",
                    label: "Eco Score",
                    color: .green
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
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.modaicsCotton)
                    
                    Text("Events worth checking out")
                        .font(.system(size: 13))
                        .foregroundColor(.modaicsCottonLight)
                }
                
                Spacer()
                
                NavigationLink(destination: CommunityFeedView().environmentObject(viewModel)) {
                    Text("See All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.modaicsChrome1)
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
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.modaicsChrome1, .modaicsChrome2],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Picked for You")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.modaicsCotton)
                }
                
                Spacer()
                
                Text("AI-powered")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.modaicsChrome2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.modaicsChrome2.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(Color.modaicsChrome2.opacity(0.3), lineWidth: 1)
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
                        .foregroundColor(.orange)
                    
                    Text("Trending Now")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.modaicsCotton)
                }
                
                Spacer()
                
                NavigationLink(destination: DiscoverView().environmentObject(viewModel)) {
                    Text("Explore")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.modaicsChrome1)
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
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                
                Text("Impact This Month")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.modaicsCotton)
            }
            
            VStack(spacing: 12) {
                ImpactRow(
                    icon: "drop.fill",
                    label: "Water Saved",
                    value: "2,847 L",
                    color: .blue,
                    description: "compared to new"
                )
                
                ImpactRow(
                    icon: "cloud.fill",
                    label: "Carbon Offset",
                    value: "\(viewModel.calculateUserSustainabilityScore()) kg",
                    color: .green,
                    description: "emissions avoided"
                )
                
                ImpactRow(
                    icon: "arrow.3.trianglepath",
                    label: "Items Circulated",
                    value: "\(viewModel.userWardrobe.filter { $0.sustainabilityScore.isRecycled }.count)",
                    color: .orange,
                    description: "given new life"
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.modaicsDarkBlue.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.3), Color.blue.opacity(0.3)],
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
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.modaicsCotton)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                QuickActionCard(
                    icon: "plus.circle.fill",
                    title: "List Item",
                    subtitle: "Sell or swap",
                    gradient: [.modaicsChrome1, .modaicsChrome2]
                )
                
                QuickActionCard(
                    icon: "magnifyingglass.circle.fill",
                    title: "AI Search",
                    subtitle: "Find anything",
                    gradient: [.modaicsDenim1, .modaicsDenim2]
                )
                
                QuickActionCard(
                    icon: "arrow.triangle.swap",
                    title: "Swap Meet",
                    subtitle: "Join event",
                    gradient: [.green, Color(red: 0.2, green: 0.6, blue: 0.4)]
                )
                
                QuickActionCard(
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    title: "Analytics",
                    subtitle: "View stats",
                    gradient: [.purple, .pink]
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
        withAnimation(.easeOut(duration: 0.6)) {
            headerOffset = 0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
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
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.modaicsCotton)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.modaicsCottonLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.modaicsDarkBlue.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
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
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(event.type.color)
                .clipShape(Capsule())
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.modaicsCotton)
                        .lineLimit(2)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(event.date, style: .date)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.modaicsCottonLight)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(event.attendees) attending")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.modaicsCottonLight)
                }
            }
            .padding(16)
            .frame(width: 220, height: 200)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.modaicsDarkBlue.opacity(0.8),
                                event.type.color.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.modaicsSurface2)
                .aspectRatio(3/4, contentMode: .fit)
                .frame(width: 140)
                .overlay(
                    Group {
                        if let imageURL = item.imageURLs.first {
                            PremiumCachedImage(url: imageURL, contentMode: .fill)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.brand)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.modaicsChrome1)
                
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.modaicsCotton)
                    .lineLimit(2)
                
                if item.listingPrice > 0 {
                    Text("$\(Int(item.listingPrice))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.modaicsChrome2)
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
                    .font(.system(size: 14))
                    .foregroundColor(.modaicsCottonLight)
                
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.modaicsCotton)
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.modaicsCottonLight.opacity(0.7))
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
                .font(.title)
                .foregroundStyle(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modaicsCotton)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.modaicsCottonLight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.modaicsDarkBlue.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
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
