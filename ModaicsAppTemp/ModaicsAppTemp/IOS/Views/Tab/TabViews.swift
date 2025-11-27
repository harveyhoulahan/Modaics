//
//  TabViews.swift
//  Modaics
//
//  Enhanced views for all app tabs with full functionality
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
                // Match HomeView gradient background
                LinearGradient(colors: [.modaicsDarkBlue, .modaicsMidBlue],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Mode Switcher - MOVED TO TOP
                    modeSwitcher
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        .background(Color.modaicsDarkBlue.opacity(0.6))
                    
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
            // Load initial AI recommendations when view appears
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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        discoverMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 14))
                        
                        Text(mode.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(discoverMode == mode ? .modaicsCotton : .modaicsCottonLight)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(discoverMode == mode ? Color.modaicsChrome1.opacity(0.2) : Color.modaicsSurface2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        discoverMode == mode ? Color.modaicsChrome1.opacity(0.5) : Color.clear,
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
            // Items Header (matching Events/Brands style)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discover Items")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.modaicsCotton)
                    
                    Text("AI-powered search across platforms")
                        .font(.system(size: 14))
                        .foregroundColor(.modaicsCottonLight)
                }
                
                Spacer()
                
                // Filter button
                Button {
                    showFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .foregroundColor(.modaicsChrome1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Search Bar (with AI status inside)
            searchBar
                .padding(.horizontal, 20)
                .padding(.top, 12)
            
            // Category Scroll
            categoryScroll
                .padding(.top, 12)
            
            // Items Grid
            if viewModel.isLoading {
                ProgressView()
                    .tint(.modaicsChrome1)
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
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.modaicsCotton)
                        
                        Text("Swaps, pop-ups & workshops")
                            .font(.system(size: 14))
                            .foregroundColor(.modaicsCottonLight)
                    }
                    
                    Spacer()
                    
                    // Location badge
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                        Text("Sydney")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.modaicsChrome1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.modaicsChrome1.opacity(0.2))
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
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.modaicsCotton)
                        
                        Text("Verified ethical & local producers")
                            .font(.system(size: 14))
                            .foregroundColor(.modaicsCottonLight)
                    }
                    
                    Spacer()
                    
                    // Filter button
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title3)
                            .foregroundColor(.modaicsChrome1)
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
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Sustainability Verified")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.modaicsCotton)
                
                Text("FibreTrace certified brands")
                    .font(.system(size: 11))
                    .foregroundColor(.modaicsCottonLight)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(true))
                .labelsHidden()
                .tint(.green)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.modaicsDarkBlue.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
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
    
    private var aiSearchHeader: some View {
        HStack(spacing: 12) {
            // AI Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.isAISearchEnabled ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                
                Text(viewModel.isAISearchEnabled ? "AI Search Active" : "Local Search")
                    .font(.caption)
                    .foregroundColor(.modaicsCottonLight)
            }
            
            Spacer()
            
            // Info button
            Button {
                showAISearchInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .foregroundColor(.modaicsChrome1)
            }
            
            // Toggle button
            Button {
                viewModel.toggleSearchMode()
            } label: {
                Image(systemName: viewModel.isAISearchEnabled ? "sparkles" : "sparkles.slash")
                    .foregroundColor(viewModel.isAISearchEnabled ? .modaicsChrome1 : .modaicsCottonLight)
            }
        }
        .padding()
        .background(Color.modaicsDarkBlue.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            // AI Status Indicator (green dot inside search bar)
            if viewModel.isAISearchEnabled {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
            
            Image(systemName: "magnifyingglass")
                .foregroundColor(.modaicsChrome1)
                .font(.title3)
            
            TextField("Search items, brands, or styles...", text: $viewModel.searchQuery)
                .font(.system(size: 16))
                .foregroundColor(.modaicsCotton)
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
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
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
                        .fill(LinearGradient(
                            colors: [.modaicsChrome1.opacity(0.2), .modaicsChrome2.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "camera.fill")
                        .foregroundColor(.modaicsChrome1)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            
            // Filters button
            Button {
                showFilters = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.modaicsChrome1.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.modaicsChrome1)
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .padding()
        .background(Color.modaicsDarkBlue.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                .foregroundColor(.modaicsChrome1.opacity(0.3))
            
            Text("No items found")
                .font(.system(size: 22, weight: .light, design: .serif))
                .foregroundColor(.modaicsCotton)
            
            Text("Try adjusting your filters or search query")
                .font(.subheadline)
                .foregroundColor(.modaicsCottonLight)
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

// MARK: - Create (List items, events, etc.) View
struct CreateView: View {
    let userType: ContentView.UserType
    @EnvironmentObject var viewModel: FashionViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showImagePicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var itemName = ""
    @State private var brand = ""
    @State private var originalPrice = ""
    @State private var listingPrice = ""
    @State private var description = ""
    @State private var selectedCategory: Category = .tops
    @State private var selectedCondition: Condition = .excellent
    @State private var selectedSize = "M"
    @State private var sustainabilityInfo = SustainabilityInfo()
    
    struct SustainabilityInfo {
        var materials: [Material] = []
        var isRecycled = false
        var isCertified = false
        var certifications: [String] = []
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Match HomeView gradient
                LinearGradient(colors: [.modaicsDarkBlue, .modaicsMidBlue],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        Text(userType == .user ? "Sell Item" : "List Product")
                            .font(.system(size: 32, weight: .ultraLight, design: .serif))
                            .foregroundColor(.modaicsCotton)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 20)
                        
                        // Images Section
                        imageSection
                        
                        // Item Details
                        detailsSection
                        
                        // Pricing
                        pricingSection
                        
                        // Description
                        descriptionSection
                        
                        // Sustainability
                        sustainabilitySection
                        
                        // Submit Button
                        Button {
                            createListing()
                        } label: {
                            Text("List Item")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.modaicsDarkBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [.modaicsChrome1, .modaicsChrome2],
                                                 startPoint: .leading, endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(itemName.isEmpty || brand.isEmpty || selectedImages.isEmpty)
                        .opacity(itemName.isEmpty || brand.isEmpty || selectedImages.isEmpty ? 0.5 : 1)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(images: $selectedImages)
        }
    }
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.modaicsCotton)
            
            if selectedImages.isEmpty {
                Button(action: { showImagePicker = true }) {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.modaicsChrome1)
                        Text("Add Photos")
                            .font(.system(size: 16))
                            .foregroundColor(.modaicsCottonLight)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(Color.modaicsDarkBlue.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(selectedImages.indices, id: \.self) { index in
                            Image(uiImage: selectedImages[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(action: { showImagePicker = true }) {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.modaicsChrome1)
                            }
                            .frame(width: 120, height: 160)
                            .background(Color.modaicsDarkBlue.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Item Details")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.modaicsCotton)
            
            VStack(spacing: 12) {
                // Item Name
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Item Name", text: $itemName)
                        .foregroundColor(.modaicsCotton)
                        .padding()
                        .background(Color.modaicsDarkBlue.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Brand
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Brand", text: $brand)
                        .foregroundColor(.modaicsCotton)
                        .padding()
                        .background(Color.modaicsDarkBlue.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Category Picker
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color.modaicsDarkBlue.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Size Picker
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Size", selection: $selectedSize) {
                        ForEach(["XS", "S", "M", "L", "XL", "XXL"], id: \.self) { size in
                            Text(size).tag(size)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color.modaicsDarkBlue.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Condition Picker
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Condition", selection: $selectedCondition) {
                        ForEach(Condition.allCases, id: \.self) { condition in
                            Text(condition.rawValue).tag(condition)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color.modaicsDarkBlue.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pricing")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.modaicsCotton)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Original Price")
                        .foregroundColor(.modaicsCottonLight)
                    Spacer()
                    TextField("$0", text: $originalPrice)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.modaicsCotton)
                }
                .padding()
                .background(Color.modaicsDarkBlue.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                HStack {
                    Text("Listing Price")
                        .foregroundColor(.modaicsCottonLight)
                    Spacer()
                    TextField("$0", text: $listingPrice)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.modaicsCotton)
                }
                .padding()
                .background(Color.modaicsDarkBlue.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                if let original = Double(originalPrice),
                   let listing = Double(listingPrice),
                   original > listing {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.green)
                        Text("\(Int((original - listing) / original * 100))% off")
                            .foregroundColor(.green)
                    }
                    .font(.subheadline)
                }
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.modaicsCotton)
            
            TextEditor(text: $description)
                .frame(minHeight: 120)
                .padding(8)
                .foregroundColor(.modaicsCotton)
                .scrollContentBackground(.hidden)
                .background(Color.modaicsDarkBlue.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var sustainabilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sustainability")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.modaicsCotton)
            
            VStack(spacing: 12) {
                Toggle("Recycled Materials", isOn: $sustainabilityInfo.isRecycled)
                    .foregroundColor(.modaicsCotton)
                    .padding()
                    .background(Color.modaicsDarkBlue.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Toggle("Certified Sustainable", isOn: $sustainabilityInfo.isCertified)
                    .foregroundColor(.modaicsCotton)
                    .padding()
                    .background(Color.modaicsDarkBlue.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                if sustainabilityInfo.isCertified {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Certifications")
                            .font(.subheadline)
                            .foregroundColor(.modaicsCottonLight)
                        
                        ForEach(["GOTS", "Fair Trade", "B Corp", "OEKO-TEX"], id: \.self) { cert in
                            Button {
                                if sustainabilityInfo.certifications.contains(cert) {
                                    sustainabilityInfo.certifications.removeAll { $0 == cert }
                                } else {
                                    sustainabilityInfo.certifications.append(cert)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: sustainabilityInfo.certifications.contains(cert) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(.modaicsChrome1)
                                    Text(cert)
                                        .foregroundColor(.modaicsCotton)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.modaicsDarkBlue.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func createListing() {
        let item = FashionItem(
            name: itemName,
            brand: brand,
            category: selectedCategory,
            size: selectedSize,
            condition: selectedCondition,
            originalPrice: Double(originalPrice) ?? 0,
            listingPrice: Double(listingPrice) ?? 0,
            description: description,
            sustainabilityScore: SustainabilityScore(
                totalScore: sustainabilityInfo.isRecycled ? 80 : 60,
                carbonFootprint: 5.0,
                waterUsage: 2000,
                isRecycled: sustainabilityInfo.isRecycled,
                isCertified: sustainabilityInfo.isCertified,
                certifications: sustainabilityInfo.certifications,
                fibreTraceVerified: false
            ),
            location: viewModel.currentUser?.location ?? "Unknown",
            ownerId: viewModel.currentUser?.id.uuidString ?? ""
        )
        
        viewModel.createListing(item: item, images: selectedImages)
    }
}

// MARK: - Community View
struct CommunityView: View {
    @EnvironmentObject var viewModel: FashionViewModel
    //@EnvironmentObject var CommunityPost
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Match gradient background
                LinearGradient(colors: [.modaicsDarkBlue, .modaicsMidBlue],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Title
                    HStack {
                        Text("Community")
                            .font(.system(size: 32, weight: .ultraLight, design: .serif))
                            .foregroundColor(.modaicsCotton)
                        
                        Spacer()
                        
                        Button {
                            // Create post action
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.modaicsChrome1)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    
                    // Tab Selection
                    HStack(spacing: 12) {
                        ForEach([("Feed", 0), ("Events", 1), ("Swaps", 2)], id: \.1) { title, tag in
                            Button {
                                selectedTab = tag
                            } label: {
                                Text(title)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(selectedTab == tag ? .modaicsDarkBlue : .modaicsCottonLight)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedTab == tag
                                            ? LinearGradient(colors: [.modaicsChrome1, .modaicsChrome2],
                                                           startPoint: .leading, endPoint: .trailing)
                                            : LinearGradient(colors: [Color.modaicsDarkBlue.opacity(0.4)],
                                                           startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    switch selectedTab {
                    case 0:
                        feedView
                    case 1:
                        eventsView
                    case 2:
                        swapsView
                    default:
                        feedView
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    private var feedView: some View {
        ScrollView {
            if viewModel.communityPosts.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 60))
                        .foregroundColor(.modaicsChrome1.opacity(0.3))
                    
                    Text("No posts yet")
                        .font(.system(size: 22, weight: .light, design: .serif))
                        .foregroundColor(.modaicsCotton)
                    
                    Text("Be the first to share with the community")
                        .font(.subheadline)
                        .foregroundColor(.modaicsCottonLight)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 100)
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.communityPosts) { post in
                        CommunityPostCard(post: post)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }
    
    private var eventsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "calendar")
                    .font(.system(size: 60))
                    .foregroundColor(.modaicsChrome1.opacity(0.3))
                
                Text("No upcoming events")
                    .font(.system(size: 22, weight: .light, design: .serif))
                    .foregroundColor(.modaicsCotton)
                
                Text("Check back soon for community events")
                    .font(.subheadline)
                    .foregroundColor(.modaicsCottonLight)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 100)
        }
    }
    
    private var swapsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 60))
                    .foregroundColor(.modaicsChrome1.opacity(0.3))
                
                Text("No active swaps")
                    .font(.system(size: 22, weight: .light, design: .serif))
                    .foregroundColor(.modaicsCotton)
                
                Text("Start a swap to exchange items sustainably")
                    .font(.subheadline)
                    .foregroundColor(.modaicsCottonLight)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 100)
        }
    }
}

struct ItemCard: View {
    let item: FashionItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.modaicsDarkBlue.opacity(0.4))
                .aspectRatio(3/4, contentMode: .fit)
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.modaicsChrome1.opacity(0.3))
                    }
                )
                .overlay(
                    // Sustainability badge
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "leaf.fill")
                            Text("\(item.sustainabilityScore.totalScore)")
                        }
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.sustainabilityScore.sustainabilityColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .padding(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.brand)
                    .font(.caption)
                    .foregroundColor(.modaicsCottonLight)
                
                Text(item.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsCotton)
                    .lineLimit(2)
                
                HStack {
                    Text("$\(Int(max(0, item.listingPrice.isNaN ? 0 : item.listingPrice)))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.modaicsChrome1)
                    
                    if !item.originalPrice.isNaN && !item.listingPrice.isNaN && 
                       item.originalPrice > item.listingPrice {
                        Text("$\(Int(item.originalPrice))")
                            .font(.caption)
                            .strikethrough()
                            .foregroundColor(.modaicsCottonLight)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "heart")
                        .font(.caption)
                        .foregroundColor(.modaicsChrome1)
                }
            }
        }
        .background(Color.modaicsDarkBlue.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ItemDetailView: View {
    let item: FashionItem

    @EnvironmentObject var viewModel: FashionViewModel
    @Environment(\.dismiss) var dismiss

    // UI state
    @State private var selectedImg = 0
    @State private var localSimilar: [FashionItem] = []

    // MARK: – body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    imageCarousel

                    priceBlock

                    actionButtons

                    detailsCard

                    sustainabilityCard

                    descriptionBlock

                    recommendations
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { share() } label: { Image(systemName: "square.and.arrow.up") }
                }
            }
        }
        .onAppear {
            // ask ViewModel for ML-based recs; if empty, fall back to tag-based
            viewModel.loadRecommendations(for: item)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if viewModel.recommendedItems.isEmpty {
                    localSimilar = SimpleRecommender.similarItems(to: item,
                                                                  in: viewModel.items,
                                                                  maxResults: 5)
                }
            }
        }
    }

    // ───────── sub-views
    private var imageCarousel: some View {
        TabView(selection: $selectedImg) {
            // Use actual imageURLs from the item
            ForEach(Array((item.imageURLs.isEmpty ? [""] : item.imageURLs).enumerated()), id: \.offset) { idx, imageURLString in
                ZStack {
                    if !imageURLString.isEmpty && (imageURLString.hasPrefix("http://") || imageURLString.hasPrefix("https://")) {
                        // Load from URL using AsyncImage
                        AsyncImage(url: URL(string: imageURLString)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .tint(.modaicsChrome1)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.gray.opacity(0.2))
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                placeholderImage
                            @unknown default:
                                placeholderImage
                            }
                        }
                    } else if !imageURLString.isEmpty, let ui = UIImage(named: imageURLString) {
                        // Local image
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                    } else {
                        placeholderImage
                    }
                }
                .tag(idx)
                .clipped()
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .frame(height: 420)
        .background(Color.black.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(Color.gray.opacity(0.2))
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray.opacity(0.5))
                    Text(item.brand)
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.5))
                }
            )
    }

    private var priceBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.brand).font(.subheadline).foregroundColor(.modaicsCottonLight)

            Text(item.name).font(.title2.weight(.bold)).foregroundColor(.modaicsCotton)

            HStack(spacing: 8) {
                Text("$\(Int(max(0, item.listingPrice.isNaN ? 0 : item.listingPrice)))")
                    .font(.title.weight(.bold))
                    .foregroundColor(.modaicsChrome1)

                if !item.originalPrice.isNaN && !item.listingPrice.isNaN && !item.priceReduction.isNaN &&
                   item.originalPrice > item.listingPrice && item.priceReduction > 0 && item.priceReduction.isFinite {
                    Text("$\(Int(item.originalPrice))")
                        .strikethrough()
                        .foregroundColor(.modaicsCottonLight)

                    Text("\(Int(item.priceReduction))% off")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // If item has external URL (from marketplace), show "View on [Platform]" button
            if let externalURL = item.externalURL, !externalURL.isEmpty, let url = URL(string: externalURL) {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    Label("View on \(getPlatformName(from: externalURL))", systemImage: "arrow.up.forward.app")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button { /* checkout flow */ } label: {
                    Label("Buy Now", systemImage: "bag.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            Button { viewModel.toggleLike(for: item) } label: {
                Image(systemName: viewModel.isLiked(item) ? "heart.fill" : "heart")
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func getPlatformName(from urlString: String) -> String {
        if urlString.contains("depop") { return "Depop" }
        if urlString.contains("grailed") { return "Grailed" }
        if urlString.contains("vinted") { return "Vinted" }
        return "Marketplace"
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailRow(label: "Size",       value: item.size)
            DetailRow(label: "Condition",  value: item.condition.rawValue)
            DetailRow(label: "Category",   value: item.category.rawValue)
            DetailRow(label: "Location",   value: item.location)
        }
        .padding()
        .background(Color.modaicsDarkBlue.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var sustainabilityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sustainability Score", systemImage: "leaf.fill")
                .font(.headline)
                .foregroundColor(.modaicsCotton)

            HStack {
                ProgressView(value: Double(item.sustainabilityScore.totalScore), total: 100)
                    .tint(item.sustainabilityScore.sustainabilityColor)
                Text("\(item.sustainabilityScore.totalScore)/100")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.modaicsCotton)
            }

            if !item.sustainabilityScore.certifications.isEmpty {
                HStack {
                    ForEach(item.sustainabilityScore.certifications, id: \.self) { cert in
                        Text(cert)
                            .font(.caption2)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var descriptionBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description").font(.headline).foregroundColor(.modaicsCotton)
            Text(item.description)
                .font(.body).foregroundColor(.modaicsCottonLight)
        }
    }

    private var recommendations: some View {
        let recs = viewModel.recommendedItems.isEmpty ? localSimilar : viewModel.recommendedItems
        return Group {
            if !recs.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Similar Items")
                        .font(.headline)
                        .foregroundColor(.modaicsCotton)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(recs) { rec in
                                EnhancedItemCard(item: item)
                                    .environmentObject(viewModel)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    // MARK: – helpers
    private var background: some View {
        LinearGradient(colors: [.modaicsDarkBlue, .modaicsMidBlue],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }

    private func share() {
        #if canImport(UIKit)
        let activity = UIActivityViewController(
            activityItems: ["Check out \(item.name) on Modaics!"],
            applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activity, animated: true)
        }
        #endif
    }
}

// MARK: – DetailRow helper
fileprivate struct DetailRow: View {
    let label, value: String
    var body: some View {
        HStack {
            Text(label).font(.subheadline.weight(.medium))
            Spacer()
            Text(value).font(.subheadline).foregroundColor(.modaicsCottonLight)
        }
    }
}

//#Preview {
//    // Replace with a real FashionItem in your preview data
//    let sample = FashionItem(id: UUID(),
//                             name: "Vintage Denim Jacket",
//                             brand: "Levi's",
//                             description: "A timeless, sustainably-made denim jacket.",
//                             listingPrice: 120,
//                             originalPrice: 180,
//                             size: "M",
//                             condition: .excellent,
//                            category: .jackets,
//                             location: "Melbourne",
//                             imageName: "sampleDenim",
//                             priceReduction: 33,
//                             sustainabilityScore: 15)   // add a static .demo if needed
//    ItemDetailView(item: sample)
//        .environmentObject(FashionViewModel())
//        .preferredColorScheme(.dark)
//}


struct EventCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 150)
                .overlay(
                    VStack {
                        Text("SWAP")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("PARTY")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Melbourne Sustainable Fashion Swap")
                    .font(.headline)
                
                Label("June 15, 2025", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Label("Federation Square", systemImage: "location")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    HStack(spacing: -8) {
                        ForEach(0..<4) { i in
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Text("\(i+1)")
                                        .font(.caption)
                                )
                        }
                    }
                    
                    Text("+45 attending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Join") {
                        // Join action
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding()
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}

struct SwapRequestCard: View {
    var body: some View {
        HStack(spacing: 16) {
            // Your item
            VStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 100)
                Text("Your Item")
                    .font(.caption)
            }
            
            Image(systemName: "arrow.left.arrow.right")
                .font(.title2)
                .foregroundColor(.blue)
            
            // Their item
            VStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 100)
                Text("Their Item")
                    .font(.caption)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button("Accept") {
                    // Accept action
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Decline") {
                    // Decline action
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}

struct ReviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading) {
                    Text("Sarah M.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < 4 ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                Text("1 week ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Great seller! Item was exactly as described and shipped quickly. Would buy again!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.modaicsChrome1)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.modaicsCottonLight)
        }
    }
}

struct FilterView: View {
    @Binding var filters: FilterOptions
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Price Range") {
                    HStack {
                        Text("Min")
                        TextField("$0", value: $filters.minPrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Max")
                        TextField("$999", value: $filters.maxPrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                Section("Condition") {
                    ForEach(Condition.allCases, id: \.self) { condition in
                        HStack {
                            Text(condition.rawValue)
                            Spacer()
                            if filters.conditions.contains(condition) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if filters.conditions.contains(condition) {
                                filters.conditions.remove(condition)
                            } else {
                                filters.conditions.insert(condition)
                            }
                        }
                    }
                }
                
                Section("Sustainability") {
                    VStack(alignment: .leading) {
                        Text("Minimum Score: \(filters.minimumSustainabilityScore)")
                        Slider(value: Binding(
                            get: { Double(filters.minimumSustainabilityScore) },
                            set: { filters.minimumSustainabilityScore = Int($0) }
                        ), in: 0...100, step: 10)
                    }
                }
                
                Section("Sort By") {
                    Picker("Sort", selection: $filters.sortBy) {
                        ForEach(FilterOptions.SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .navigationTitle("Filters")
            .navigationBarItems(
                leading: Button("Reset") {
                    filters = FilterOptions()
                },
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 5
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.images.append(image)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Camera Image Picker
struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker
        
        init(_ parent: CameraImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Event Map Card
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
                            .font(.system(size: 11))
                        Text(event.type.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(event.type.color)
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Distance badge
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text("2.3 km")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.modaicsChrome1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.modaicsChrome1.opacity(0.2))
                    .clipShape(Capsule())
                }
                
                Text(event.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.modaicsCotton)
                    .lineLimit(2)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(event.date, style: .date)
                            .font(.system(size: 13))
                        
                        Text("•")
                            .foregroundColor(.modaicsCottonLight.opacity(0.5))
                        
                        Text(event.date, style: .time)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.modaicsCottonLight)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text(event.location)
                            .font(.system(size: 13))
                            .lineLimit(1)
                    }
                    .foregroundColor(.modaicsCottonLight)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(event.attendees) attending")
                            .font(.system(size: 13))
                        
                        Spacer()
                        
                        if event.isFree {
                            Text("Free")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    .foregroundColor(.modaicsCottonLight)
                }
                
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.system(size: 13))
                        .foregroundColor(.modaicsCottonLight)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.modaicsDarkBlue.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(event.type.color.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Event Type Filter Chip
struct EventTypeFilterChip: View {
    let type: EventFilterType
    let isSelected: Bool
    
    enum EventFilterType: String {
        case all = "All Events"
        case swap = "Swaps"
        case popUp = "Pop-Ups"
        case workshop = "Workshops"
        case marketplace = "Markets"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2.fill"
            case .swap: return "arrow.triangle.swap"
            case .popUp: return "storefront.fill"
            case .workshop: return "hammer.fill"
            case .marketplace: return "cart.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: type.icon)
                .font(.system(size: 12))
            
            Text(type.rawValue)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(isSelected ? .modaicsCotton : .modaicsCottonLight)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? Color.modaicsChrome1.opacity(0.2) : Color.modaicsSurface2)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.modaicsChrome1.opacity(0.5) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Brand Card
struct BrandCard: View {
    let brand: BrandInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Brand logo/image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.modaicsChrome1.opacity(0.3), Color.modaicsChrome2.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                
                Image(systemName: "building.2.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.modaicsChrome1)
                
                // Sustainability badge overlay
                if brand.hasSustainabilityBadge {
                    VStack {
                        HStack {
                            Spacer()
                            
                            Image(systemName: "leaf.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                                .background(
                                    Circle()
                                        .fill(Color.modaicsDarkBlue)
                                        .padding(-4)
                                )
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(brand.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.modaicsCotton)
                    .lineLimit(1)
                
                Text(brand.tagline)
                    .font(.system(size: 12))
                    .foregroundColor(.modaicsCottonLight)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text(String(format: "%.1f", brand.rating))
                        .font(.system(size: 12, weight: .semibold))
                    
                    Text("(\(brand.itemCount) items)")
                        .font(.system(size: 11))
                        .foregroundColor(.modaicsCottonLight)
                }
                .foregroundColor(.yellow)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.modaicsDarkBlue.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            brand.hasSustainabilityBadge ? Color.green.opacity(0.3) : Color.modaicsChrome1.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Brand Info Model
struct BrandInfo: Identifiable {
    let id = UUID()
    let name: String
    let tagline: String
    let hasSustainabilityBadge: Bool
    let rating: Double
    let itemCount: Int
    let location: String
    
    static let mockBrands: [BrandInfo] = [
        BrandInfo(name: "Earth Threads", tagline: "100% organic cotton from local farms", hasSustainabilityBadge: true, rating: 4.8, itemCount: 127, location: "Sydney"),
        BrandInfo(name: "Revive Collective", tagline: "Upcycled fashion from rescued materials", hasSustainabilityBadge: true, rating: 4.9, itemCount: 89, location: "Melbourne"),
        BrandInfo(name: "Ocean Wear", tagline: "Made from recycled ocean plastic", hasSustainabilityBadge: true, rating: 4.7, itemCount: 156, location: "Brisbane"),
        BrandInfo(name: "Local Makers Co", tagline: "Supporting Australian artisans", hasSustainabilityBadge: true, rating: 4.6, itemCount: 73, location: "Perth"),
        BrandInfo(name: "Zero Waste Studio", tagline: "Circular fashion at its finest", hasSustainabilityBadge: true, rating: 4.9, itemCount: 201, location: "Sydney"),
        BrandInfo(name: "Heritage Textiles", tagline: "Traditional techniques, modern style", hasSustainabilityBadge: true, rating: 4.5, itemCount: 45, location: "Adelaide")
    ]
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category: Category?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category?.rawValue ?? "All")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .modaicsDarkBlue : .modaicsCotton)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.modaicsChrome1 : Color.modaicsSurface2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
