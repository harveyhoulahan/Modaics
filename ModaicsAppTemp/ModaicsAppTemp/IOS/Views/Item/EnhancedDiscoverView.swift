//
//  EnhancedDiscoverView.swift
//  ModaicsAppTemp
//
//  Enhanced discovery with dark green Porsche aesthetic
//  Created by Harvey Houlahan on 6/6/2025.
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
            case .trending: return [.earthAmber, .coralError]
            case .sustainable: return [.emerald, .organicGreen]
            case .local: return [.natureTeal, .forestLight]
            case .community: return [.luxeGold, .luxeGoldDeep]
            case .aiRecommended: return [.luxeGoldBright, .luxeGold]
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
                LinearGradient.forestBackground
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
                                .foregroundStyle(.luxeGoldGradient)
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
                                .foregroundColor(.luxeGold)
                        }
                    }
                }
            }
            
            // Enhanced search bar
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: ForestRadius.large)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: ForestRadius.large)
                                .stroke(.luxeGold.opacity(0.2), lineWidth: 1)
                        )
                    
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.luxeGold)
                        
                        TextField("Search sustainable fashion...", text: $searchText)
                            .font(.forestBody(16))
                            .foregroundColor(.sageWhite)
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
                                    .foregroundColor(.sageMuted)
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
                        RoundedRectangle(cornerRadius: ForestRadius.medium)
                            .fill(.ultraThinMaterial)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.luxeGold)
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
                        withAnimation(.forestSpring) {
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
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundColor(.luxeGold)
                        
                        Text(suggestion)
                            .font(.forestBody(15))
                            .foregroundColor(.sageWhite)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.left")
                            .font(.caption)
                            .foregroundColor(.sageMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                if suggestion != searchSuggestions.prefix(5).last {
                    Divider()
                        .background(.luxeGold.opacity(0.1))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: ForestRadius.large)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: ForestRadius.large)
                        .stroke(.luxeGold.opacity(0.2), lineWidth: 1)
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
                        .font(.forestHeadline(20))
                        .foregroundColor(.sageWhite)
                }
                
                Spacer()
                
                Button("See All") {
                    // See all action
                }
                .font(.forestCaption(14))
                .foregroundColor(.luxeGold)
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
                                colors: [.natureTeal, .forestLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "calendar.badge.plus")
                                .font(.title2)
                                .foregroundColor(.sageWhite)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fashion Swap Tomorrow")
                            .font(.forestHeadline(16))
                            .foregroundColor(.sageWhite)
                        
                        Text("Federation Square • 15 attending")
                            .font(.forestCaption(13))
                            .foregroundColor(.sageMuted)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.sageMuted)
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
                    .font(.forestCaption(13))
            }
            .foregroundStyle(
                isSelected 
                ? LinearGradient(colors: [.sageWhite], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [.sageMuted], startPoint: .leading, endPoint: .trailing)
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
                                : Color.luxeGold.opacity(0.3), 
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
                RoundedRectangle(cornerRadius: ForestRadius.medium)
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
                        .foregroundColor(.sageWhite)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(colors: [.earthAmber, .coralError], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                        .padding(8)
                    }
                    Spacer()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.brand)
                    .font(.forestCaption(11))
                    .foregroundColor(.luxeGold)
                
                Text(item.name)
                    .font(.forestBody(14))
                    .foregroundColor(.sageWhite)
                    .lineLimit(1)
                
                Text("$\(Int(item.listingPrice))")
                    .font(.forestHeadline(16))
                    .foregroundColor(.luxeGoldBright)
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
                            colors: rank == 1 ? [.luxeGold, .luxeGoldBright] : 
                                     rank == 2 ? [.sageMuted, .sageWhite] : 
                                     [Color.forestLight, Color.forestSoft],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Text("\(rank)")
                    .font(.forestHeadline(14))
                    .fontWeight(.bold)
                    .foregroundColor(.forestDeep)
            }
            
            // Item image
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 60)
            
            // Item info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.forestBody(15))
                    .foregroundColor(.sageWhite)
                    .lineLimit(1)
                
                Text(item.brand)
                    .font(.forestCaption(12))
                    .foregroundColor(.sageMuted)
                
                HStack {
                    SustainabilityIcon(size: 12)
                    Text("\(item.sustainabilityScore.totalScore)/100")
                        .font(.forestCaption(12))
                        .foregroundColor(.emerald)
                }
            }
            
            Spacer()
            
            Text("$\(Int(item.listingPrice))")
                .font(.forestHeadline(16))
                .foregroundColor(.luxeGold)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: ForestRadius.medium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: ForestRadius.medium)
                        .stroke(.emerald.opacity(0.2), lineWidth: 1)
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
                    .font(.forestCaption(12))
                    .foregroundColor(.sageWhite)
                    .lineLimit(1)
                
                Text("$\(Int(item.listingPrice))")
                    .font(.forestBody(14))
                    .foregroundColor(.luxeGold)
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
                RoundedRectangle(cornerRadius: ForestRadius.medium)
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
                        .foregroundColor(.sageWhite)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(colors: [.luxeGold, .luxeGoldDeep], startPoint: .leading, endPoint: .trailing)
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
                    .font(.forestBody(13))
                    .foregroundColor(.sageWhite)
                    .lineLimit(1)
                
                Text("❤️ 24 likes")
                    .font(.forestCaption(11))
                    .foregroundColor(.luxeGold)
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
                RoundedRectangle(cornerRadius: ForestRadius.medium)
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
                        .foregroundColor(.forestDeep)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.luxeGoldGradient)
                        .clipShape(Capsule())
                        .padding(8)
                    }
                    Spacer()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Perfect for you")
                    .font(.forestCaption(10))
                    .foregroundColor(.luxeGold)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(item.name)
                    .font(.forestBody(14))
                    .foregroundColor(.sageWhite)
                    .lineLimit(1)
                
                Text("$\(Int(item.listingPrice))")
                    .font(.forestHeadline(16))
                    .foregroundColor(.luxeGold)
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
                    // Price range
                    priceRangeSection
                    
                    // Sustainability
                    sustainabilitySection
                    
                    // Categories
                    categoriesSection
                }
                .padding(20)
            }
            .background(
                LinearGradient.forestBackground
                    .ignoresSafeArea()
            )
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        localFilters = FilterOptions()
                    }
                    .foregroundColor(.luxeGold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        filters = localFilters
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.luxeGold)
                }
            }
        }
    }
    
    private var priceRangeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Price Range")
                .font(.forestHeadline(18))
                .foregroundColor(.sageWhite)
            
            // Price range content
        }
    }
    
    private var sustainabilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sustainability")
                .font(.forestHeadline(18))
                .foregroundColor(.sageWhite)
            
            // Sustainability content
        }
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.forestHeadline(18))
                .foregroundColor(.sageWhite)
            
            // Categories content
        }
    }
}

// MARK: - AI Style Assistant View
struct AIStyleAssistantView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.forestBackground
                    .ignoresSafeArea()
                
                VStack {
                    Text("AI Style Assistant")
                        .font(.forestDisplay(28))
                        .foregroundColor(.sageWhite)
                    
                    Spacer()
                    
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(ForestPrimaryButtonStyle())
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.luxeGold)
                }
            }
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
                .font(.forestBody(16))
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .forestDeep : .sageWhite)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: ForestRadius.medium)
                        .fill(isSelected
                              ? AnyShapeStyle(Color.luxeGold)
                              : AnyShapeStyle(.ultraThinMaterial))
                        .overlay(
                            RoundedRectangle(cornerRadius: ForestRadius.medium)
                                .stroke(
                                    isSelected ? Color.clear : Color.luxeGold.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
        }
    }
}

#Preview {
    EnhancedDiscoverView()
        .environmentObject(FashionViewModel())
}
