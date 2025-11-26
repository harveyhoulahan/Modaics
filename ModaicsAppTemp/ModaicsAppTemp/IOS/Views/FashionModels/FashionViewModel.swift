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
        // Search query debouncing
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.filterItems()
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
        guard let embedding = item.embeddingVector else {
            // If no embedding, generate one from the first image
            generateEmbeddingAndRecommend(for: item)
            return
        }
        
        // Get similar items using the recommendation manager
        _ = recommendationManager.recommendations(for: item, from: allItems, k: 6)
        
        // Map filenames to items (skip the item itself)
        recommendedItems = RecommendationManager.shared
            .recommendations(for: item, from: allItems, k: 6)
    }
    
    private func generateEmbeddingAndRecommend(for item: FashionItem) {
        guard let firstImageName = item.imageURLs.first,
              let image = UIImage(named: firstImageName) else {
            return
        }
        
        isLoading = true
        
        Task { @MainActor in
            // Use the new recommendations API
            let recommendations = recommendationManager.recommendations(for: item, from: allItems, k: 6)
            
            // Update item with any generated embedding
            if let index = allItems.firstIndex(where: { $0.id == item.id }),
               let firstImageName = item.imageURLs.first,
               let image = UIImage(named: firstImageName) {
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
