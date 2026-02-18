//
//  TabViews.swift
//  Modaics
//
//  Enhanced views for all app tabs with full functionality
//  Dark Green Porsche Aesthetic - Luxury Sustainable Fashion
//

import SwiftUI
import PhotosUI

// MARK: - Discover View
struct DiscoverView: View {
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var showFilters = false
    @State private var selectedItem: FashionItem?
    @State private var showImagePicker = false
    @State private var showImageSourcePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showAISearchInfo = false
    @State private var discoverMode: DiscoverMode = .items
    @State private var selectedEvent: CommunityEvent?
    
    enum DiscoverMode: String, CaseIterable {
        case items = "Items"
        case events = "Events"
        case brands = "Brands"
        
        var icon: String {
            switch self {
            case .items: return "tshirt.fill"
            case .events: return "calendar.badge.clock"
            case .brands: return "building.2.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark green forest gradient background
                LinearGradient.forestBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Mode Switcher - MOVED TO TOP
                    modeSwitcher
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        .background(.forestMid.opacity(0.6))
                    
                    // Content based on mode
                    switch discoverMode {
                    case .items:
                        itemsContent
                    case .events:
                        eventsContent
                    case .brands:
                        brandsContent
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            Task {
                if viewModel.currentSearchResults.isEmpty {
                    await viewModel.loadInitialRecommendations()
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            FilterView(filters: $viewModel.selectedFilters)
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailView(item: item)
                .environmentObject(viewModel)
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(event: event)
        }
        .sheet(isPresented: $showImagePicker) {
            CameraImagePicker(
                image: Binding(
                    get: { viewModel.selectedSearchImage },
                    set: { image in
                        if let image = image {
                            viewModel.selectedSearchImage = image
                            Task {
                                await viewModel.performAISearch(query: viewModel.searchQuery.isEmpty ? nil : viewModel.searchQuery, image: image)
                            }
                        }
                    }
                ),
                sourceType: imageSourceType
            )
        }
        .confirmationDialog("Choose Image Source", isPresented: $showImageSourcePicker, titleVisibility: .visible) {
            Button("Take Photo") {
                imageSourceType = .camera
                showImagePicker = true
            }
            Button("Choose from Library") {
                imageSourceType = .photoLibrary
                showImagePicker = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("AI Search", isPresented: $showAISearchInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.isAISearchEnabled 
                ? "AI search is active. Upload an image or enter text to find similar items across Depop, Grailed, and Vinted."
                : "AI search is unavailable. Make sure the backend server is running on http://localhost:8000")
        }
    }
    
    // MARK: - Mode Switcher
    private var modeSwitcher: some View {
        HStack(spacing: 12) {
            ForEach(DiscoverMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.forestSpring) {
                        discoverMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 14))
                        
                        Text(mode.rawValue)
                            .font(.forestCaption(15))
                    }
                    .foregroundColor(discoverMode == mode ? .sageWhite : .sageMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: ForestRadius.medium)
                            .fill(discoverMode == mode ? Color.luxeGold.opacity(0.2) : Color.surfaceElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: ForestRadius.medium)
                                    .stroke(
                                        discoverMode == mode ? Color.luxeGold.opacity(0.5) : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Items Content
    private var itemsContent: some View {
        VStack(spacing: 0) {
            // Items Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discover Items")
                        .font(.forestDisplay(24))
                        .foregroundColor(.sageWhite)
                    
                    Text("AI-powered search across platforms")
                        .font(.forestCaption(14))
                        .foregroundColor(.sageMuted)
                }
                
                Spacer()
                
                // Filter button
                Button {
                    showFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .foregroundColor(.luxeGold)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Search Bar
            searchBar
                .padding(.horizontal, 20)
                .padding(.top, 12)
            
            // Category Scroll
            categoryScroll
                .padding(.top, 12)
            
            // Items Grid
            if viewModel.isLoading {
                ProgressView()
                    .tint(.luxeGold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.currentSearchResults.isEmpty {
                emptyState
            } else {
                itemsGrid
            }
        }
    }
    
    // MARK: - Events Content
    private var eventsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Event Map Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Events Near You")
                            .font(.forestDisplay(24))
                            .foregroundColor(.sageWhite)
                        
                        Text("Swaps, pop-ups & workshops")
                            .font(.forestCaption(14))
                            .foregroundColor(.sageMuted)
                    }
                    
                    Spacer()
                    
                    // Location badge
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                        Text("Sydney")
                            .font(.forestCaption(13))
                    }
                    .foregroundColor(.luxeGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.luxeGold.opacity(0.2))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Event type filters
                eventTypeFilters
                    .padding(.horizontal, 20)
                
                // Events list
                ForEach(nearbyEvents) { event in
                    EventMapCard(event: event) {
                        selectedEvent = event
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Brands Content
    private var brandsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Brands Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sustainable Brands")
                            .font(.forestDisplay(24))
                            .foregroundColor(.sageWhite)
                        
                        Text("Verified ethical & local producers")
                            .font(.forestCaption(14))
                            .foregroundColor(.sageMuted)
                    }
                    
                    Spacer()
                    
                    // Filter button
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title3)
                            .foregroundColor(.luxeGold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Sustainability badge filter
                sustainabilityBadgeFilter
                    .padding(.horizontal, 20)
                
                // Brands grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(sustainableBrands) { brand in
                        BrandCard(brand: brand)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Event Type Filters
    private var eventTypeFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                EventTypeFilterChip(type: .all, isSelected: true)
                EventTypeFilterChip(type: .swap, isSelected: false)
                EventTypeFilterChip(type: .popUp, isSelected: false)
                EventTypeFilterChip(type: .workshop, isSelected: false)
                EventTypeFilterChip(type: .marketplace, isSelected: false)
            }
        }
    }
    
    // MARK: - Sustainability Badge Filter
    private var sustainabilityBadgeFilter: some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.circle.fill")
                .font(.title3)
                .foregroundColor(.emerald)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Sustainability Verified")
                    .font(.forestCaption(14))
                    .foregroundColor(.sageWhite)
                
                Text("FibreTrace certified brands")
                    .font(.forestCaption(11))
                    .foregroundColor(.sageMuted)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(true))
                .labelsHidden()
                .tint(.emerald)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: ForestRadius.medium)
                .fill(.forestMid.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: ForestRadius.medium)
                        .stroke(.emerald.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Computed Properties
    private var nearbyEvents: [CommunityEvent] {
        CommunityEvent.mockEvents
            .filter { $0.date > Date() }
            .sorted { $0.date < $1.date }
    }
    
    private var sustainableBrands: [BrandInfo] {
        BrandInfo.mockBrands.filter { $0.hasSustainabilityBadge }
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            // AI Status Indicator (green dot inside search bar)
            if viewModel.isAISearchEnabled {
                Circle()
                    .fill(Color.emerald)
                    .frame(width: 8, height: 8)
            }
            
            Image(systemName: "magnifyingglass")
                .foregroundColor(.luxeGold)
                .font(.title3)
            
            TextField("Search items, brands, or styles...", text: $viewModel.searchQuery)
                .font(.forestBody(16))
                .foregroundColor(.sageWhite)
                .textFieldStyle(.plain)
            
            // Image search button with preview
            if viewModel.selectedSearchImage != nil {
                Button {
                    viewModel.selectedSearchImage = nil
                    Task {
                        await viewModel.performAISearch(query: viewModel.searchQuery.isEmpty ? nil : viewModel.searchQuery, image: nil)
                    }
                } label: {
                    ZStack {
                        if let searchImage = viewModel.selectedSearchImage {
                            Image(uiImage: searchImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.sageWhite)
                            .background(Circle().fill(Color.forestDeep.opacity(0.5)))
                            .font(.caption)
                            .offset(x: 12, y: -12)
                    }
                    .frame(width: 32, height: 32)
                }
            }
            
            // Camera/Gallery button
            Button {
                showImageSourcePicker = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.luxeGold.opacity(0.2), .luxeGoldBright.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "camera.fill")
                        .foregroundColor(.luxeGold)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            
            // Filters button
            Button {
                showFilters = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.luxeGold.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.luxeGold)
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .padding()
        .background(.forestMid.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: ForestRadius.large))
    }
    
    private var categoryScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    category: nil,
                    isSelected: viewModel.selectedCategory == nil,
                    action: { viewModel.selectedCategory = nil }
                )
                
                ForEach(Category.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: viewModel.selectedCategory == category,
                        action: { viewModel.selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var itemsGrid: some View {
        RefreshableGrid(
            items: viewModel.currentSearchResults,
            columns: 2,
            spacing: 20,
            horizontalPadding: 20,
            onRefresh: {
                await viewModel.loadInitialRecommendations()
            }
        ) { item in
            OptimizedItemCard(item: item)
                .environmentObject(viewModel)
                .onTapGesture {
                    HapticManager.shared.cardTap()
                    viewModel.trackItemView(item)
                    selectedItem = item
                }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.luxeGold.opacity(0.3))
            
            Text("No items found")
                .font(.forestTitle(22))
                .foregroundColor(.sageWhite)
            
            Text("Try adjusting your filters or search query")
                .font(.forestCaption(14))
                .foregroundColor(.sageMuted)
                .multilineTextAlignment(.center)
            
            GlassButton(
                "Clear Filters",
                icon: "xmark.circle.fill",
                style: .primary,
                size: .medium
            ) {
                viewModel.selectedFilters = FilterOptions()
                viewModel.searchQuery = ""
                viewModel.selectedCategory = nil
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Supporting Views for TabViews

struct EventMapCard: View {
    let event: CommunityEvent
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Event type badge
                    HStack(spacing: 6) {
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
                    
                    Text(event.isFree ? "FREE" : "\(Int(event.price))")
                        .font(.forestCaption(14))
                        .foregroundColor(event.isFree ? .emerald : .luxeGold)
                }
                
                Text(event.title)
                    .font(.forestHeadline(18))
                    .foregroundColor(.sageWhite)
                
                Text("by \(event.host)")
                    .font(.forestCaption(14))
                    .foregroundColor(.luxeGold)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.sageMuted)
                        Text(event.date, style: .date)
                            .font(.forestCaption(13))
                            .foregroundColor(.sageMuted)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(.sageMuted)
                        Text(event.location)
                            .font(.forestCaption(13))
                            .foregroundColor(.sageMuted)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: ForestRadius.large)
                    .fill(.forestMid.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: ForestRadius.large)
                            .stroke(.luxeGold.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BrandCard: View {
    let brand: BrandInfo
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(.luxeGoldGradient)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.forestDeep)
                )
            
            Text(brand.name)
                .font(.forestHeadline(14))
                .foregroundColor(.sageWhite)
            
            if brand.hasSustainabilityBadge {
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.caption)
                    Text("Verified")
                        .font(.forestCaption(10))
                }
                .foregroundColor(.emerald)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.emerald.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: ForestRadius.large)
                .fill(.forestMid.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: ForestRadius.large)
                        .stroke(.luxeGold.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct CategoryChip: View {
    let category: Category?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let category = category {
                    Image(systemName: iconForCategory(category))
                        .font(.system(size: 14))
                }
                Text(category?.rawValue ?? "All")
                    .font(.forestCaption(14))
            }
            .foregroundColor(isSelected ? .forestDeep : .sageMuted)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.luxeGold : Color.surfaceElevated)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.luxeGold.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForCategory(_ category: Category) -> String {
        switch category {
        case .tops: return "tshirt.fill"
        case .bottoms: return "rectangle.fill"
        case .dresses: return "figure.dress"
        case .outerwear: return "jacket.fill"
        case .shoes: return "shoe.fill"
        case .accessories: return "bag.fill"
        case .bags: return "handbag.fill"
        case .jewelry: return "sparkles"
        case .other: return "questionmark.circle"
        case .jackets: return "coat"
        }
    }
}

struct EventTypeFilterChip: View {
    let type: EventType
    let isSelected: Bool
    
    var body: some View {
        Text(type.rawValue)
            .font(.forestCaption(13))
            .foregroundColor(isSelected ? .forestDeep : .sageMuted)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.luxeGold : Color.surfaceElevated)
            )
    }
}

enum EventType: String, CaseIterable {
    case all = "All"
    case swap = "Swap"
    case popUp = "Pop-up"
    case workshop = "Workshop"
    case marketplace = "Market"
}

struct BrandInfo: Identifiable {
    let id = UUID()
    let name: String
    let hasSustainabilityBadge: Bool
    
    static var mockBrands: [BrandInfo] {
        [
            BrandInfo(name: "Patagonia", hasSustainabilityBadge: true),
            BrandInfo(name: "Everlane", hasSustainabilityBadge: true),
            BrandInfo(name: "Reformation", hasSustainabilityBadge: true),
            BrandInfo(name: "Stella McCartney", hasSustainabilityBadge: true),
            BrandInfo(name: "Eileen Fisher", hasSustainabilityBadge: true),
            BrandInfo(name: "Veja", hasSustainabilityBadge: true)
        ]
    }
}

#Preview {
    DiscoverView()
        .environmentObject(FashionViewModel())
}
