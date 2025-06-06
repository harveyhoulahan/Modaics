//
//  EnhancedDiscoverView.swift
//  ModaicsAppTemp
//
//  Created by Harvey Houlahan on 6/6/2025.
//


//
//  EnhancedDiscoverySystem.swift
//  Intelligent, community-driven discovery for Modaics
//

import SwiftUI

// MARK: - Enhanced Discover View
struct EnhancedDiscoverView: View {
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var searchText = ""
    @State private var selectedDiscoveryMode: DiscoveryMode = .trending
    @State private var showAdvancedFilters = false
    @State private var showAIStyleAssistant = false
    @State private var selectedItem: FashionItem?
    @State private var searchSuggestions: [String] = []
    @State private var isSearching = false
    
    enum DiscoveryMode: String, CaseIterable {
        case trending = "Trending"
        case sustainable = "Most Sustainable"
        case local = "Near You"
        case community = "Community Picks"
        case aiRecommended = "For You"
        
        var icon: String {
            switch self {
            case .trending: return "flame.fill"
            case .sustainable: return "leaf.fill"
            case .local: return "location.fill"
            case .community: return "heart.fill"
            case .aiRecommended: return "sparkles"
            }
        }
        
        var gradient: [Color] {
            switch self {
            case .trending: return [.orange, .red]
            case .sustainable: return [.modaicsAccent, Color(red: 0.15, green: 0.5, blue: 0.3)]
            case .local: return [.blue, .purple]
            case .community: return [.pink, .red]
            case .aiRecommended: return [.modaicsChrome1, .modaicsChrome2]
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced search header
                searchHeader
                
                // Discovery mode selector
                discoveryModeSelector
                
                // Search suggestions (when typing)
                if isSearching && !searchSuggestions.isEmpty {
                    searchSuggestionsView
                }
                
                // Main content
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Featured section based on discovery mode
                        featuredSection
                        
                        // Items grid
                        itemsGrid
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await refreshDiscovery()
                }
            }
            .background(
                LinearGradient(
                    colors: [.modaicsDarkBlue, .modaicsMidBlue],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAdvancedFilters) {
            EnhancedFilterView(filters: $viewModel.selectedFilters)
        }
        .sheet(isPresented: $showAIStyleAssistant) {
            AIStyleAssistantView()
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailView(item: item)
                .environmentObject(viewModel)
        }
        .onAppear {
            generateSearchSuggestions()
        }
    }
    
    private var searchHeader: some View {
        VStack(spacing: 16) {
            // Top bar with logo and actions
            HStack {
                ModaicsLogo(size: 32)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button {
                        showAIStyleAssistant = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.modaicsChrome1, .modaicsChrome2],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    
                    Button {
                        showAdvancedFilters = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.modaicsChrome1)
                        }
                    }
                }
            }
            
            // Enhanced search bar
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.modaicsChrome1.opacity(0.2), lineWidth: 1)
                        )
                    
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.modaicsChrome2)
                        
                        TextField("Search sustainable fashion...", text: $searchText)
                            .font(.modaicsBody(16))
                            .foregroundColor(.modaicsCotton)
                            .onChange(of: searchText) { _, newValue in
                                isSearching = !newValue.isEmpty
                                updateSearchSuggestions(for: newValue)
                            }
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                isSearching = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.modaicsChrome2)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                // Voice search button
                Button {
                    // Voice search action
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.modaicsChrome1)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    private var discoveryModeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DiscoveryMode.allCases, id: \.self) { mode in
                    DiscoveryModeChip(
                        mode: mode,
                        isSelected: selectedDiscoveryMode == mode
                    ) {
                        withAnimation(.modaicsSpring) {
                            selectedDiscoveryMode = mode
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
    }
    
    private var searchSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(searchSuggestions.prefix(5), id: \.self) { suggestion in
                Button {
                    searchText = suggestion
                    isSearching = false
                    // Perform search
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundColor(.modaicsChrome2)
                        
                        Text(suggestion)
                            .font(.modaicsBody(15))
                            .foregroundColor(.modaicsCotton)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.left")
                            .font(.caption)
                            .foregroundColor(.modaicsChrome2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                if suggestion != searchSuggestions.prefix(5).last {
                    Divider()
                        .background(Color.modaicsChrome1.opacity(0.1))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.modaicsChrome1.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: selectedDiscoveryMode.icon)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: selectedDiscoveryMode.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(selectedDiscoveryMode.rawValue)
                        .font(.modaicsHeadline(20))
                        .foregroundColor(.modaicsCotton)
                }
                
                Spacer()
                
                Button("See All") {
                    // See all action
                }
                .font(.modaicsCaption(14))
                .foregroundColor(.modaicsChrome1)
            }
            
            // Featured content based on mode
            featuredContentForMode
        }
    }
    
    @ViewBuilder
    private var featuredContentForMode: some View {
        switch selectedDiscoveryMode {
        case .trending:
            trendingItemsCarousel
        case .sustainable:
            sustainabilityLeaderboard
        case .local:
            localEventsAndItems
        case .community:
            communityPicksCarousel
        case .aiRecommended:
            aiRecommendationsCarousel
        }
    }
    
    private var trendingItemsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.filteredItems.prefix(5)) { item in
                    TrendingItemCard(item: item)
                        .onTapGesture {
                            selectedItem = item
                        }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var sustainabilityLeaderboard: some View {
        VStack(spacing: 12) {
            ForEach(Array(viewModel.filteredItems.sorted { $0.sustainabilityScore.totalScore > $1.sustainabilityScore.totalScore }.prefix(3).enumerated()), id: \.element.id) { index, item in
                SustainabilityLeaderboardRow(item: item, rank: index + 1)
                    .onTapGesture {
                        selectedItem = item
                    }
            }
        }
    }
    
    private var localEventsAndItems: some View {
        VStack(spacing: 16) {
            // Local event preview
            Button {
                // Navigate to events
            } label: {
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "calendar.badge.plus")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fashion Swap Tomorrow")
                            .font(.modaicsHeadline(16))
                            .foregroundColor(.modaicsCotton)
                        
                        Text("Federation Square • 15 attending")
                            .font(.modaicsCaption(13))
                            .foregroundColor(.modaicsCottonLight)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.modaicsChrome2)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }
            
            // Local items
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.filteredItems.prefix(4)) { item in
                        CompactItemCard(item: item)
                            .onTapGesture {
                                selectedItem = item
                            }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var communityPicksCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.filteredItems.prefix(4)) { item in
                    CommunityPickCard(item: item)
                        .onTapGesture {
                            selectedItem = item
                        }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var aiRecommendationsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.recommendedItems.isEmpty ? viewModel.filteredItems.prefix(4) : viewModel.recommendedItems.prefix(4)) { item in
                    AIRecommendationCard(item: item)
                        .onTapGesture {
                            selectedItem = item
                        }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var itemsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(viewModel.filteredItems) { item in
                EnhancedItemCard(item: item)
                    .environmentObject(viewModel)
                    .onTapGesture {
                        viewModel.trackItemView(item)
                        selectedItem = item
                    }
            }
        }
    }
    
    private func generateSearchSuggestions() {
        searchSuggestions = [
            "Vintage denim",
            "Sustainable blazers",
            "Local swap events",
            "Organic cotton",
            "Recycled materials",
            "Melbourne fashion",
            "Zero waste brands"
        ]
    }
    
    private func updateSearchSuggestions(for query: String) {
        if query.isEmpty {
            generateSearchSuggestions()
        } else {
            searchSuggestions = searchSuggestions.filter { 
                $0.lowercased().contains(query.lowercased()) 
            }
        }
    }
    
    private func refreshDiscovery() async {
        // Simulate refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        viewModel.loadInitialData()
    }
}

// MARK: - Discovery Mode Chip
struct DiscoveryModeChip: View {
    let mode: EnhancedDiscoverView.DiscoveryMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(mode.rawValue)
                    .font(.modaicsCaption(13))
                    .fontWeight(.medium)
            }
            .foregroundStyle(
                isSelected 
                ? LinearGradient(colors: [.white], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [.modaicsChrome2], startPoint: .leading, endPoint: .trailing)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isSelected 
                        ? LinearGradient(colors: mode.gradient, startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected 
                                ? Color.clear 
                                : Color.modaicsChrome1.opacity(0.3), 
                                lineWidth: 1
                            )
                    )
            )
        }
    }
}

// MARK: - Specialized Item Cards
struct TrendingItemCard: View {
    let item: FashionItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(3/4, contentMode: .fit)
                    .frame(width: 140)
                
                // Trending badge
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                            Text("TRENDING")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                        .padding(8)
                    }
                    Spacer()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.brand)
                    .font(.modaicsCaption(11))
                    .foregroundColor(.modaicsChrome2)
                
                Text(item.name)
                    .font(.modaicsBody(14))
                    .fontWeight(.medium)
                    .foregroundColor(.modaicsCotton)
                    .lineLimit(1)
                
                Text("$\(Int(item.listingPrice))")
                    .font(.modaicsHeadline(16))
                    .foregroundColor(.modaicsChrome1)
            }
            .padding(8)
        }
        .frame(width: 140)
    }
}

struct SustainabilityLeaderboardRow: View {
    let item: FashionItem
    let rank: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: rank == 1 ? [.yellow, .orange] : 
                                     rank == 2 ? [.gray, .white] : 
                                     [Color(red: 0.8, green: 0.5, blue: 0.2), Color(red: 0.6, green: 0.3, blue: 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Text("\(rank)")
                    .font(.modaicsHeadline(14))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Item image
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 60)
            
            // Item info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.modaicsBody(15))
                    .fontWeight(.medium)
                    .foregroundColor(.modaicsCotton)
                    .lineLimit(1)
                
                Text(item.brand)
                    .font(.modaicsCaption(12))
                    .foregroundColor(.modaicsChrome2)
                
                HStack {
                    SustainabilityIcon(size: 12)
                    Text("\(item.sustainabilityScore.totalScore)/100")
                        .font(.modaicsCaption(12))
                        .fontWeight(.bold)
                        .foregroundColor(.modaicsAccent)
                }
            }
            
            Spacer()
            
            Text("$\(Int(item.listingPrice))")
                .font(.modaicsHeadline(16))
                .foregroundColor(.modaicsChrome1)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.modaicsAccent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct CompactItemCard: View {
    let item: FashionItem
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 100)
            
            VStack(spacing: 2) {
                Text(item.name)
                    .font(.modaicsCaption(12))
                    .foregroundColor(.modaicsCotton)
                    .lineLimit(1)
                
                Text("$\(Int(item.listingPrice))")
                    .font(.modaicsBody(14))
                    .fontWeight(.medium)
                    .foregroundColor(.modaicsChrome1)
            }
        }
        .frame(width: 80)
    }
}

struct CommunityPickCard: View {
    let item: FashionItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(3/4, contentMode: .fit)
                    .frame(width: 120)
                
                // Community badge
                VStack {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                            Text("LOVED")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(colors: [.pink, .red], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                        .padding(8)
                        
                        Spacer()
                    }
                    Spacer()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.modaicsBody(13))
                    .fontWeight(.medium)
                    .foregroundColor(.modaicsCotton)
                    .lineLimit(1)
                
                Text("❤️ 24 likes")
                    .font(.modaicsCaption(11))
                    .foregroundColor(.red)
            }
            .padding(8)
        }
        .frame(width: 120)
    }
}

struct AIRecommendationCard: View {
    let item: FashionItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(3/4, contentMode: .fit)
                    .frame(width: 130)
                
                // AI badge
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text("AI PICK")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundColor(.modaicsDarkBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(colors: [.modaicsChrome1, .modaicsChrome2], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                        .padding(8)
                    }
                    Spacer()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Perfect for you")
                    .font(.modaicsCaption(10))
                    .foregroundColor(.modaicsChrome1)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(item.name)
                    .font(.modaicsBody(14))
                    .fontWeight(.medium)
                    .foregroundColor(.modaicsCotton)
                    .lineLimit(1)
                
                Text("$\(Int(item.listingPrice))")
                    .font(.modaicsHeadline(16))
                    .foregroundColor(.modaicsChrome1)
            }
            .padding(8)
        }
        .frame(width: 130)
    }
}

// MARK: - Enhanced Filter View
struct EnhancedFilterView: View {
    @Binding var filters: FilterOptions
    @Environment(\.dismiss) var dismiss
    @State private var localFilters: FilterOptions
    
    init(filters: Binding<FilterOptions>) {
        self._filters = filters
        self._localFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Price range with visual feedback
                    priceRangeSection
                    
                    // Sustainability focus
                    sustainabilitySection
                    
                    // Category and condition
                    categoriesSection
                    
                    // Advanced filters
                    advancedSection
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: [.modaicsDarkBlue, .modaicsMidBlue],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        localFilters = FilterOptions()
                    }
                    .foregroundColor(.modaicsChrome1)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        filters = localFilters
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.modaicsChrome1)
                }
            }
        }
    }
    
    private var priceRangeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Price Range")
                .font(.modaicsHeadline(18))
                .foregroundColor(.modaicsCotton)
            
            VStack(spacing: 12) {
                HStack {
                    Text("$\(Int(localFilters.minPrice ?? 0))")
                        .font(.modaicsBody(16))
                        .foregroundColor(.modaicsChrome1)
                    
                    Spacer()
                    
                    Text("$\(Int(localFilters.maxPrice ?? 500))")
                        .font(.modaicsBody(16))
                        .foregroundColor(.modaicsChrome1)
                }
                
                // Custom range slider would go here
                // For now, using basic sliders
                VStack(spacing: 8) {
                    HStack {
                        Text("Min")
                        Slider(
                            value: Binding(
                                get: { Double(localFilters.minPrice ?? 0) },
                                set: { localFilters.minPrice = $0 }
                            ),
                            in: 0...200,
                            step: 5
                        )
                        .tint(.modaicsChrome1)
                    }
                    
                    HStack {
                        Text("Max")
                        Slider(
                            value: Binding(
                                get: { Double(localFilters.maxPrice ?? 500) },
                                set: { localFilters.maxPrice = $0 }
                            ),
                            in: 50...1000,
                            step: 10
                        )
                        .tint(.modaicsChrome1)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    private var sustainabilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SustainabilityIcon(size: 16)
                Text("Sustainability")
                    .font(.modaicsHeadline(18))
                    .foregroundColor(.modaicsCotton)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Minimum Score: \(localFilters.minimumSustainabilityScore)")
                        .font(.modaicsBody(15))
                        .foregroundColor(.modaicsCotton)
                    
                    Spacer()
                }
                
                Slider(
                    value: Binding(
                        get: { Double(localFilters.minimumSustainabilityScore) },
                        set: { localFilters.minimumSustainabilityScore = Int($0) }
                    ),
                    in: 0...100,
                    step: 10
                )
                .tint(.modaicsAccent)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    FilterToggle(
                        title: "Recycled Materials",
                        isOn: Binding(
                            get: { localFilters.materials.contains("Recycled") },
                            set: { isOn in
                                if isOn {
                                    localFilters.materials.insert("Recycled")
                                } else {
                                    localFilters.materials.remove("Recycled")
                                }
                            }
                        )
                    )
                    
                    FilterToggle(
                        title: "Organic Cotton",
                        isOn: Binding(
                            get: { localFilters.materials.contains("Organic") },
                            set: { isOn in
                                if isOn {
                                    localFilters.materials.insert("Organic")
                                } else {
                                    localFilters.materials.remove("Organic")
                                }
                            }
                        )
                    )
                    
                    FilterToggle(
                        title: "FibreTrace Verified",
                        isOn: Binding(
                            get: { localFilters.brands.contains("FibreTrace") },
                            set: { isOn in
                                if isOn {
                                    localFilters.brands.insert("FibreTrace")
                                } else {
                                    localFilters.brands.remove("FibreTrace")
                                }
                            }
                        )
                    )
                    
                    FilterToggle(
                        title: "Local Makers",
                        isOn: Binding(
                            get: { localFilters.brands.contains("Local") },
                            set: { isOn in
                                if isOn {
                                    localFilters.brands.insert("Local")
                                } else {
                                    localFilters.brands.remove("Local")
                                }
                            }
                        )
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories & Condition")
                .font(.modaicsHeadline(18))
                .foregroundColor(.modaicsCotton)
            
            VStack(spacing: 16) {
                // Categories
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(Category.allCases.prefix(6), id: \.self) { category in
                        Button {
                            // Toggle category selection
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: category.icon)
                                    .font(.title3)
                                Text(category.rawValue)
                                    .font(.modaicsCaption(12))
                            }
                            .foregroundColor(.modaicsChrome1)
                            .frame(height: 60)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.modaicsChrome1.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                
                // Conditions
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(Condition.allCases, id: \.self) { condition in
                        FilterToggle(
                            title: condition.rawValue,
                            isOn: Binding(
                                get: { localFilters.conditions.contains(condition) },
                                set: { isOn in
                                    if isOn {
                                        localFilters.conditions.insert(condition)
                                    } else {
                                        localFilters.conditions.remove(condition)
                                    }
                                }
                            )
                        )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sort & Display")
                .font(.modaicsHeadline(18))
                .foregroundColor(.modaicsCotton)
            
            VStack(spacing: 12) {
                Picker("Sort by", selection: $localFilters.sortBy) {
                    ForEach(FilterOptions.SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

// MARK: - Filter Toggle
struct FilterToggle: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Button {
            withAnimation(.modaicsSpring) {
                isOn.toggle()
            }
        } label: {
            Text(title)
                .font(.modaicsCaption(13))
                .fontWeight(.medium)
                .foregroundColor(isOn ? .modaicsDarkBlue : .modaicsChrome1)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isOn ? Color.modaicsChrome1 : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.modaicsChrome1.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - AI Style Assistant View
struct AIStyleAssistantView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    @State private var selectedStyles: Set<String> = []
    @State private var selectedOccasions: Set<String> = []
    @State private var sustainabilityPriority = 50.0
    
    let styleOptions = ["Minimalist", "Vintage", "Streetwear", "Formal", "Boho", "Edgy"]
    let occasionOptions = ["Work", "Casual", "Date Night", "Events", "Travel", "Weekend"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: 2)
                    .tint(.modaicsChrome1)
                    .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case 0:
                            styleSelectionStep
                        case 1:
                            occasionSelectionStep
                        case 2:
                            sustainabilityStep
                        default:
                            resultsStep
                        }
                    }
                    .padding(20)
                }
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation(.modaicsSpring) {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.modaicsChrome1)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == 2 ? "Get Recommendations" : "Next") {
                        withAnimation(.modaicsSpring) {
                            if currentStep < 3 {
                                currentStep += 1
                            } else {
                                dismiss()
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.modaicsChrome1)
                    .disabled(
                        (currentStep == 0 && selectedStyles.isEmpty) ||
                        (currentStep == 1 && selectedOccasions.isEmpty)
                    )
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: [.modaicsDarkBlue, .modaicsMidBlue],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("AI Style Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.modaicsChrome1)
                }
            }
        }
    }
    
    private var styleSelectionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your style?")
                    .font(.modaicsDisplay(28))
                    .foregroundColor(.modaicsCotton)
                
                Text("Select all styles that resonate with you")
                    .font(.modaicsBody(16))
                    .foregroundColor(.modaicsCottonLight)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(styleOptions, id: \.self) { style in
                    StyleOptionCard(
                        title: style,
                        isSelected: selectedStyles.contains(style)
                    ) {
                        if selectedStyles.contains(style) {
                            selectedStyles.remove(style)
                        } else {
                            selectedStyles.insert(style)
                        }
                    }
                }
            }
        }
    }
    
    private var occasionSelectionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What occasions?")
                    .font(.modaicsDisplay(28))
                    .foregroundColor(.modaicsCotton)
                
                Text("When do you wear these styles?")
                    .font(.modaicsBody(16))
                    .foregroundColor(.modaicsCottonLight)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(occasionOptions, id: \.self) { occasion in
                    StyleOptionCard(
                        title: occasion,
                        isSelected: selectedOccasions.contains(occasion)
                    ) {
                        if selectedOccasions.contains(occasion) {
                            selectedOccasions.remove(occasion)
                        } else {
                            selectedOccasions.insert(occasion)
                        }
                    }
                }
            }
        }
    }
    
    private var sustainabilityStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sustainability Priority")
                    .font(.modaicsDisplay(28))
                    .foregroundColor(.modaicsCotton)
                
                Text("How important is sustainability in your choices?")
                    .font(.modaicsBody(16))
                    .foregroundColor(.modaicsCottonLight)
            }
            
            VStack(spacing: 16) {
                HStack {
                    Text("Not Important")
                        .font(.modaicsCaption(14))
                        .foregroundColor(.modaicsChrome2)
                    
                    Spacer()
                    
                    Text("Very Important")
                        .font(.modaicsCaption(14))
                        .foregroundColor(.modaicsAccent)
                }
                
                Slider(value: $sustainabilityPriority, in: 0...100, step: 10)
                    .tint(.modaicsAccent)
                
                Text("Priority: \(Int(sustainabilityPriority))%")
                    .font(.modaicsHeadline(18))
                    .foregroundColor(.modaicsCotton)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    private var resultsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Perfect! We're curating items just for you...")
                .font(.modaicsDisplay(24))
                .foregroundColor(.modaicsCotton)
                .multilineTextAlignment(.leading)
            
            // Loading animation
            VStack(spacing: 16) {
                ForEach(0..<3) { index in
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 80)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 16)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 12)
                                .frame(width: 100)
                        }
                        
                        Spacer()
                    }
                    .opacity(0.7)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

// MARK: - Style Option Card
struct StyleOptionCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.modaicsBody(16))
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .modaicsDarkBlue : .modaicsCotton)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected
                              ? AnyShapeStyle(Color.modaicsChrome1)      // selected
                              : AnyShapeStyle(.ultraThinMaterial))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ? Color.clear : Color.modaicsChrome1.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
        }
    }
}
