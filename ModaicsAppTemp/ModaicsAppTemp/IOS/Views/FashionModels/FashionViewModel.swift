//
//  FashionViewModel.swift
//  ModaicsAppTemp
//
//  Created by Harvey Houlahan on 5/6/2025.
//  Main view model for managing fashion items and user interactions
//

import Foundation
import SwiftUI
import Combine
import CoreML
import UIKit

// MARK: - Main Fashion View Model
@MainActor
class FashionViewModel: ObservableObject {
    // Published properties for UI binding
    @Published var currentUser: User?
    @Published var allItems: [FashionItem] = []
    @Published var filteredItems: [FashionItem] = []
    @Published var userWardrobe: [FashionItem] = []
    @Published var recommendedItems: [FashionItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchQuery: String = ""
    @Published var selectedCategory: Category?
    @Published var selectedFilters = FilterOptions()
    @Published private(set) var likedIDs: [UUID] = []
    @Published var communityPosts: [CommunityPost] = CommunityPost.demoFeed
    
    // AI Search properties
    @Published var aiSearchResults: [FashionItem] = []
    @Published var isAISearchEnabled: Bool = false
    @Published var selectedSearchImage: UIImage?
    private let searchClient = SearchAPIClient(baseURL: "http://10.20.99.164:8000")

        // KEEP this implementation fuck sake
        // MARK: - Likes
        func toggleLike(for item: FashionItem) {
            if let idx = likedIDs.firstIndex(of: item.id) {
                likedIDs.remove(at: idx)
            } else {
                likedIDs.append(item.id)
            }
        }

        func isLiked(_ item: FashionItem) -> Bool {
            likedIDs.contains(item.id)
        }
    
    // Private properties
    private var cancellables = Set<AnyCancellable>()
    private let recommendationManager = RecommendationManager.shared
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadInitialData()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Search query debouncing with AI search support
        $searchQuery
            .removeDuplicates()
            .debounce(for: .milliseconds(800), scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self = self else { return }
                if self.isAISearchEnabled && !query.isEmpty {
                    Task {
                        await self.performAISearch(query: query, image: self.selectedSearchImage)
                    }
                } else {
                    self.filterItems()
                }
            }
            .store(in: &cancellables)
        
        // Filter changes
        $selectedCategory
            .sink { [weak self] _ in
                self?.filterItems()
            }
            .store(in: &cancellables)
        
        $selectedFilters
            .sink { [weak self] _ in
                self?.filterItems()
            }
            .store(in: &cancellables)
        
        // Check AI search availability on init
        Task {
            await checkAISearchAvailability()
        }
    }
    
    // MARK: - Data Loading
    func loadInitialData() {
        isLoading = true
        
        // Simulate loading data (replace with actual API calls)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.allItems = FashionItem.sampleItems
            self?.filterItems()
            self?.loadUserData()
            self?.isLoading = false
        }
    }
    
    private func loadUserData() {
        // Create sample user
        currentUser = User(
            username: "fashion_lover",
            email: "user@example.com",
            bio: "Sustainable fashion enthusiast",
            location: "Melbourne, VIC",
            userType: .consumer,
            sustainabilityPoints: 250
        )
        
        // Load user's wardrobe
        loadUserWardrobe()
    }
    
    func loadUserWardrobe() {
        guard let user = currentUser else { return }
        
        // Filter items owned by current user
        userWardrobe = allItems.filter { $0.ownerId == user.id.uuidString }
    }
    
    // MARK: - Filtering
    func filterItems() {
        filteredItems = allItems.filter { item in
            // Category filter
            if let category = selectedCategory, item.category != category {
                return false
            }
            
            // Search query filter
            if !searchQuery.isEmpty {
                let searchLower = searchQuery.lowercased()
                let matchesName = item.name.lowercased().contains(searchLower)
                let matchesBrand = item.brand.lowercased().contains(searchLower)
                let matchesTags = item.styleTags.contains { $0.lowercased().contains(searchLower) }
                
                if !matchesName && !matchesBrand && !matchesTags {
                    return false
                }
            }
            
            // Price filter
            if let minPrice = selectedFilters.minPrice,
               item.listingPrice < minPrice {
                return false
            }
            
            if let maxPrice = selectedFilters.maxPrice,
               item.listingPrice > maxPrice {
                return false
            }
            
            // Condition filter
            if !selectedFilters.conditions.isEmpty,
               !selectedFilters.conditions.contains(item.condition) {
                return false
            }
            
            // Size filter
            if !selectedFilters.sizes.isEmpty,
               !selectedFilters.sizes.contains(item.size) {
                return false
            }
            
            // Sustainability filter
            if selectedFilters.minimumSustainabilityScore > 0,
               item.sustainabilityScore.totalScore < selectedFilters.minimumSustainabilityScore {
                return false
            }
            
            return true
        }
    }
    
    // MARK: - Recommendations
    func loadRecommendations(for item: FashionItem) {
        // Try using existing embedding first
        if item.embeddingVector != nil {
            // Map filenames to items (skip the item itself)
            recommendedItems = RecommendationManager.shared
                .recommendations(for: item, from: allItems, k: 6)
            return
        }
        
        // If no embedding, generate recommendations anyway
        generateEmbeddingAndRecommend(for: item)
    }
    
    private func generateEmbeddingAndRecommend(for item: FashionItem) {
        guard let firstImageName = item.imageURLs.first,
              let _ = UIImage(named: firstImageName) else {
            return
        }
        
        isLoading = true
        
        Task { @MainActor in
            // Use the new recommendations API
            let recommendations = recommendationManager.recommendations(for: item, from: allItems, k: 6)
            
            // Update item with any generated embedding (if needed)
            if let _ = allItems.firstIndex(where: { $0.id == item.id }),
               let _ = item.imageURLs.first,
               let _ = UIImage(named: firstImageName) {
                // Embedding will be extracted automatically by the recommendation manager
            }
            
            // Load recommendations
            recommendedItems = recommendations
            isLoading = false
        }
    }
    
    
    func addToWardrobe(_ item: FashionItem) {
        guard var user = currentUser else { return }
        
        let itemId = item.id.uuidString
        if !user.wardrobe.contains(itemId) {
            user.wardrobe.append(itemId)
            currentUser = user
            userWardrobe.append(item)
        }
    }
    
    func createListing(item: FashionItem, images: [UIImage]) {
        isLoading = true
        
        // Create item with user ID
        var newItem = item
        newItem.ownerId = currentUser?.id.uuidString ?? ""
        
        // Add to items (embeddings will be generated automatically when needed)
        allItems.append(newItem)
        filterItems()
        
        isLoading = false
    }
    
    // MARK: - AI-Powered Search
    
    /// Perform AI search using text, image, or both
    func performAISearch(query: String? = nil, image: UIImage? = nil) async {
        print("🔍 performAISearch called - query: \(query ?? "nil"), hasImage: \(image != nil), isAISearchEnabled: \(isAISearchEnabled)")
        
        guard isAISearchEnabled else {
            // Fall back to traditional search
            print("⚠️ AI search disabled, using local search")
            filterItems()
            return
        }
        
        // Check if backend is available
        let isHealthy = await searchClient.checkHealth()
        print("🏥 Backend health check: \(isHealthy)")
        
        if !isHealthy {
            errorMessage = "AI search is unavailable. Using local search instead."
            isAISearchEnabled = false
            filterItems()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let results: [SearchResult]
            
            // Determine search type
            if let query = query, !query.isEmpty, let image = image {
                // Combined search
                print("🎨 Performing combined search for: \(query)")
                results = try await searchClient.searchCombined(query: query, image: image, limit: 50)
            } else if let image = image {
                // Image-only search
                print("📸 Performing image-only search")
                results = try await searchClient.searchByImage(image: image, limit: 50)
            } else if let query = query, !query.isEmpty {
                // Text-only search
                print("📝 Performing text-only search for: \(query)")
                results = try await searchClient.searchByText(query: query, limit: 50)
            } else {
                // No search criteria
                print("⚠️ No search criteria provided")
                aiSearchResults = []
                isLoading = false
                return
            }
            
            print("✅ Received \(results.count) results from backend")
            
            // Convert results to FashionItems
            aiSearchResults = results.map { SearchAPIClient.toFashionItem($0) }
            
            print("✅ Converted to \(aiSearchResults.count) FashionItems")
            
            // Sort by similarity if available
            aiSearchResults.sort { ($0.similarity ?? 0) > ($1.similarity ?? 0) }
            
            print("✅ AI search complete, aiSearchResults count: \(aiSearchResults.count)")
            
            isLoading = false
            
        } catch let error as SearchAPIError {
            print("❌ Search API error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isLoading = false
            
            // Fall back to local search
            isAISearchEnabled = false
            filterItems()
            
        } catch {
            print("❌ Unknown error: \(error.localizedDescription)")
            errorMessage = "Search failed: \(error.localizedDescription)"
            isLoading = false
            
            // Fall back to local search
            isAISearchEnabled = false
            filterItems()
        }
    }
    
    /// Perform text-only AI search
    func searchByText(query: String) async {
        await performAISearch(query: query, image: nil)
    }
    
    /// Perform image-only AI search
    func searchByImage(image: UIImage) async {
        await performAISearch(query: nil, image: image)
    }
    
    /// Perform combined text + image AI search
    func searchCombined(query: String, image: UIImage) async {
        await performAISearch(query: query, image: image)
    }
    
    /// Check if AI search backend is available
    func checkAISearchAvailability() async {
        let isHealthy = await searchClient.checkHealth()
        isAISearchEnabled = isHealthy
        
        if !isHealthy {
            print("AI search backend is not available. Using local search.")
        }
    }
    
    /// Toggle between AI search and local search
    func toggleSearchMode() {
        isAISearchEnabled.toggle()
        
        if !isAISearchEnabled {
            aiSearchResults = []
            filterItems()
        }
    }
    
    /// Load initial AI recommendations on app launch
    func loadInitialRecommendations() async {
        print("🎯 Loading initial AI recommendations...")
        
        // Check if backend is available
        let isHealthy = await searchClient.checkHealth()
        guard isHealthy else {
            print("❌ Backend not available, skipping initial recommendations")
            return
        }
        
        isLoading = true
        
        do {
            // Fetch trending/popular items - you can customize this query
            // For now, let's just fetch a diverse set of items
            let results = try await searchClient.searchByText(query: "fashion streetwear vintage designer", limit: 50)
            
            print("✅ Loaded \(results.count) initial items")
            
            // Convert to FashionItems
            let items = results.map { SearchAPIClient.toFashionItem($0) }
            
            // If AI search is enabled, show in AI results
            // Otherwise, add to filteredItems so they appear by default
            if isAISearchEnabled {
                aiSearchResults = items
            } else {
                // Merge with local items
                allItems = items
                filterItems()
            }
            
            isLoading = false
            
        } catch {
            print("❌ Failed to load initial recommendations: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    /// Get current search results (AI or local)
    var currentSearchResults: [FashionItem] {
        isAISearchEnabled ? aiSearchResults : filteredItems
    }
    
    // MARK: - Analytics
    func trackItemView(_ item: FashionItem) {
        if let index = allItems.firstIndex(where: { $0.id == item.id }) {
            allItems[index].viewCount += 1
        }
    }
    
    func calculateUserSustainabilityScore() -> Int {
        guard let user = currentUser else { return 0 }
        
        // Calculate based on wardrobe items' sustainability scores
        let wardrobeItems = allItems.filter { user.wardrobe.contains($0.id.uuidString) }
        
        guard !wardrobeItems.isEmpty else { return 0 }
        
        let totalScore = wardrobeItems.reduce(0) { $0 + $1.sustainabilityScore.totalScore }
        return totalScore / wardrobeItems.count
    }
}

extension FashionViewModel {
    /// Legacy support for TabViews.swift
    var items: [FashionItem] { allItems }   // or whatever your master array is
}

// MARK: - Filter Options
struct FilterOptions {
    var minPrice: Double?
    var maxPrice: Double?
    var conditions: Set<Condition> = []
    var sizes: Set<String> = []
    var minimumSustainabilityScore: Int = 0
    var brands: Set<String> = []
    var materials: Set<String> = []
    var colors: Set<String> = []
    var sortBy: SortOption = .relevance
    
    enum SortOption: String, CaseIterable {
        case relevance = "Relevance"
        case priceLowToHigh = "Price: Low to High"
        case priceHighToLow = "Price: High to Low"
        case newest = "Newest First"
        case mostSustainable = "Most Sustainable"
        case mostPopular = "Most Popular"
    }
}

// MARK: - Mock Data Service (Replace with actual API)
class DataService {
    static let shared = DataService()
    
    func fetchItems() async throws -> [FashionItem] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return FashionItem.sampleItems
    }
    
    func uploadImages(_ images: [UIImage]) async throws -> [String] {
        // Simulate upload and return URLs
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return images.enumerated().map { "uploaded_image_\($0.offset)" }
    }
    
    func searchItems(query: String) async throws -> [FashionItem] {
        // Simulate search
        try await Task.sleep(nanoseconds: 500_000_000)
        return FashionItem.sampleItems.filter {
            $0.name.lowercased().contains(query.lowercased()) ||
            $0.brand.lowercased().contains(query.lowercased())
        }
    }
}
