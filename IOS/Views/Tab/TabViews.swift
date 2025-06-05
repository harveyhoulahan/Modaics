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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Category Scroll
                categoryScroll
                
                // Items Grid
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredItems.isEmpty {
                    emptyState
                } else {
                    itemsGrid
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Discover")
            .navigationBarItems(
                trailing: Button(action: { showFilters = true }) {
                    Image(systemName: "slider.horizontal.3")
                }
            )
            .sheet(isPresented: $showFilters) {
                FilterView(filters: $viewModel.selectedFilters)
            }
            .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item)
                    .environmentObject(viewModel)
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search items, brands, or styles...", text: $viewModel.searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
        .background(Color.white)
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
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.white)
    }
    
    private var itemsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(viewModel.filteredItems) { item in
                    ItemCard(item: item)
                        .onTapGesture {
                            viewModel.trackItemView(item)
                            selectedItem = item
                        }
                }
            }
            .padding()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No items found")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Try adjusting your filters or search query")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button("Clear Filters") {
                viewModel.selectedFilters = FilterOptions()
                viewModel.searchQuery = ""
                viewModel.selectedCategory = nil
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Sell/List View
struct SellView: View {
    let userType: ContentView.UserType
    @EnvironmentObject var viewModel: FashionViewModel
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
        NavigationView {
            Form {
                // Images Section
                Section {
                    if selectedImages.isEmpty {
                        Button(action: { showImagePicker = true }) {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("Add Photos")
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(selectedImages.indices, id: \.self) { index in
                                    Image(uiImage: selectedImages[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                Button(action: { showImagePicker = true }) {
                                    VStack {
                                        Image(systemName: "plus")
                                            .font(.title2)
                                    }
                                    .frame(width: 100, height: 150)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
                
                // Basic Info
                Section("Item Details") {
                    TextField("Item Name", text: $itemName)
                    TextField("Brand", text: $brand)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    
                    Picker("Size", selection: $selectedSize) {
                        ForEach(["XS", "S", "M", "L", "XL", "XXL"], id: \.self) { size in
                            Text(size).tag(size)
                        }
                    }
                    
                    Picker("Condition", selection: $selectedCondition) {
                        ForEach(Condition.allCases, id: \.self) { condition in
                            Text(condition.rawValue).tag(condition)
                        }
                    }
                }
                
                // Pricing
                Section("Pricing") {
                    HStack {
                        Text("Original Price")
                        Spacer()
                        TextField("$0", text: $originalPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Listing Price")
                        Spacer()
                        TextField("$0", text: $listingPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    if let original = Double(originalPrice),
                       let listing = Double(listingPrice),
                       original > listing {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.green)
                            Text("\(Int((original - listing) / original * 100))% off")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Description
                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
                
                // Sustainability
                Section("Sustainability Information") {
                    Toggle("Recycled Materials", isOn: $sustainabilityInfo.isRecycled)
                    Toggle("Certified Sustainable", isOn: $sustainabilityInfo.isCertified)
                    
                    if sustainabilityInfo.isCertified {
                        VStack(alignment: .leading) {
                            Text("Certifications")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(["GOTS", "Fair Trade", "B Corp", "OEKO-TEX"], id: \.self) { cert in
                                HStack {
                                    Image(systemName: sustainabilityInfo.certifications.contains(cert) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(.blue)
                                    Text(cert)
                                }
                                .onTapGesture {
                                    if sustainabilityInfo.certifications.contains(cert) {
                                        sustainabilityInfo.certifications.removeAll { $0 == cert }
                                    } else {
                                        sustainabilityInfo.certifications.append(cert)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(userType == .user ? "Sell Item" : "List Product")
            .navigationBarItems(
                leading: Button("Cancel") {},
                trailing: Button("List") {
                    createListing()
                }
                .disabled(itemName.isEmpty || brand.isEmpty || selectedImages.isEmpty)
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(images: $selectedImages)
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
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selection
                Picker("Community", selection: $selectedTab) {
                    Text("Feed").tag(0)
                    Text("Events").tag(1)
                    Text("Swaps").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
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
            .navigationTitle("Community")
            .navigationBarItems(
                trailing: Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                }
            )
        }
    }
    
    private var feedView: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<5) { _ in
                    CommunityPostCard()
                }
            }
            .padding()
        }
    }
    
    private var eventsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<3) { _ in
                    EventCard()
                }
            }
            .padding()
        }
    }
    
    private var swapsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                SwapRequestCard()
                SwapRequestCard()
            }
            .padding()
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    let userType: ContentView.UserType
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    profileHeader
                    
                    // Stats
                    statsSection
                    
                    // Tab Selection
                    Picker("Profile Content", selection: $selectedTab) {
                        Text("Wardrobe").tag(0)
                        Text("Liked").tag(1)
                        Text("Reviews").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Content based on selection
                    contentSection
                }
            }
            .navigationTitle("Profile")
            .navigationBarItems(
                trailing: Button(action: {}) {
                    Image(systemName: "gearshape")
                }
            )
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 100, height: 100)
                .overlay(
                    Text(viewModel.currentUser?.username.prefix(1).uppercased() ?? "U")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(spacing: 8) {
                HStack {
                    Text(viewModel.currentUser?.username ?? "Username")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if viewModel.currentUser?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                Text(viewModel.currentUser?.bio ?? "No bio yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(viewModel.currentUser?.location ?? "Location")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                Button("Edit Profile") {
                    // Edit action
                }
                .buttonStyle(.bordered)
                
                Button("Share") {
                    // Share action
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    private var statsSection: some View {
        HStack(spacing: 30) {
            StatItem(value: "\(viewModel.userWardrobe.count)", label: "Items")
            StatItem(value: "\(viewModel.currentUser?.followers.count ?? 0)", label: "Followers")
            StatItem(value: "\(viewModel.currentUser?.following.count ?? 0)", label: "Following")
            StatItem(value: "\(viewModel.calculateUserSustainabilityScore())", label: "Eco Score")
        }
        .padding(.horizontal)
    }
    
    private var contentSection: some View {
        Group {
            switch selectedTab {
            case 0:
                // Wardrobe items
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(viewModel.userWardrobe) { item in
                        ItemCard(item: item)
                    }
                }
                .padding()
            case 1:
                // Liked items
                Text("Liked items will appear here")
                    .foregroundColor(.secondary)
                    .padding()
            case 2:
                // Reviews
                VStack(spacing: 16) {
                    ForEach(0..<3) { _ in
                        ReviewCard()
                    }
                }
                .padding()
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Supporting Components
struct CategoryChip: View {
    let category: Category?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.caption)
                }
                Text(category?.rawValue ?? "All")
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

struct ItemCard: View {
    let item: FashionItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(3/4, contentMode: .fit)
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray.opacity(0.5))
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
                        .font(.caption)
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
                    .foregroundColor(.secondary)
                
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                HStack {
                    Text("$\(Int(item.listingPrice))")
                        .font(.headline)
                    
                    if item.originalPrice > item.listingPrice {
                        Text("$\(Int(item.originalPrice))")
                            .font(.caption)
                            .strikethrough()
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "heart")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct ItemDetailView: View {
    let item: FashionItem
    @EnvironmentObject var viewModel: FashionViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedImageIndex = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image carousel
                    TabView(selection: $selectedImageIndex) {
                        ForEach(0..<3) { index in
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color.gray.opacity(0.2))
                                .aspectRatio(3/4, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray.opacity(0.5))
                                )
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: 400)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Basic info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.brand)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(item.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            HStack {
                                Text("$\(Int(item.listingPrice))")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                if item.originalPrice > item.listingPrice {
                                    Text("$\(Int(item.originalPrice))")
                                        .font(.body)
                                        .strikethrough()
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(Int(item.priceReduction))% off")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: {}) {
                                Label("Buy Now", systemImage: "bag.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button(action: { viewModel.toggleLike(for: item) }) {
                                Image(systemName: "heart")
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        // Details
                        VStack(alignment: .leading, spacing: 12) {
                            DetailRow(label: "Size", value: item.size)
                            DetailRow(label: "Condition", value: item.condition.rawValue)
                            DetailRow(label: "Category", value: item.category.rawValue)
                            DetailRow(label: "Location", value: item.location)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Sustainability
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Sustainability Score", systemImage: "leaf.fill")
                                .font(.headline)
                            
                            HStack {
                                ProgressView(value: Double(item.sustainabilityScore.totalScore), total: 100)
                                    .tint(item.sustainabilityScore.sustainabilityColor)
                                
                                Text("\(item.sustainabilityScore.totalScore)/100")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            if !item.sustainabilityScore.certifications.isEmpty {
                                HStack {
                                    ForEach(item.sustainabilityScore.certifications, id: \.self) { cert in
                                        Text(cert)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.green.opacity(0.1))
                                            .foregroundColor(.green)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            
                            Text(item.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Recommendations
                        if !viewModel.recommendedItems.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Similar Items")
                                    .font(.headline)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.recommendedItems) { recommendedItem in
                                            RecommendedItemCard(item: recommendedItem)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") { dismiss() },
                trailing: Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                }
            )
        }
        .onAppear {
            viewModel.loadRecommendations(for: item)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct CommunityPostCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading) {
                    Text("@sustainable_style")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("2 hours ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text("Just swapped my old denim jacket for this amazing vintage piece! Love the Modaics community 💚")
                .font(.body)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)
            
            HStack(spacing: 20) {
                Button(action: {}) {
                    Label("24", systemImage: "heart")
                        .font(.subheadline)
                }
                
                Button(action: {}) {
                    Label("5", systemImage: "bubble.left")
                        .font(.subheadline)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "bookmark")
                }
            }
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}

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
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
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