//
//  SearchAPIService.swift
//  Modaics
//
//  Search API service for image and text-based fashion search
//  Integrates with CLIP-powered backend for visual similarity
//

import Foundation
import UIKit
import Combine

// MARK: - Search Service

@MainActor
class SearchAPIService: ObservableObject {
    
    // MARK: - Shared Instance
    
    static let shared = SearchAPIService()
    
    // MARK: - Published Properties
    
    @Published private(set) var isLoading = false
    @Published private(set) var lastResults: [SearchResult] = []
    @Published private(set) var lastError: APIError?
    @Published var recentSearches: [String] = []
    
    // MARK: - Private Properties
    
    private let apiClient: APIClient
    private let cache: SearchCache
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        self.cache = SearchCache()
        loadRecentSearches()
    }
    
    // MARK: - Search by Text
    
    /// Search for items using text query
    func searchByText(
        query: String,
        limit: Int = 20,
        useCache: Bool = true
    ) async throws -> [SearchResult] {
        guard !query.isEmpty else {
            return []
        }
        
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        // Check cache
        let cacheKey = "text_\(query)_\(limit)"
        if useCache, let cached = await cache.get(forKey: cacheKey) {
            return cached
        }
        
        // Build request
        let request = APIRequest(
            endpoint: .searchByText,
            body: SearchRequest(
                query: query,
                imageBase64: nil,
                limit: limit
            ),
            timeout: APIConfiguration.shared.searchTimeout,
            requiresAuth: true
        )
        
        do {
            let response: SearchResponse = try await apiClient.request(request)
            let results = response.items
            
            // Update state
            lastResults = results
            addRecentSearch(query)
            
            // Cache results
            if useCache {
                await cache.set(results, forKey: cacheKey)
            }
            
            return results
            
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    // MARK: - Search by Image
    
    /// Search for visually similar items using an image
    func searchByImage(
        _ image: UIImage,
        limit: Int = 20,
        useCache: Bool = true
    ) async throws -> [SearchResult] {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        // Process image
        let uploadResult = try await ImageUploader.shared.processImage(image)
        
        // Check cache (based on image hash)
        let cacheKey = "image_\(uploadResult.base64String.prefix(100))_\(limit)"
        if useCache, let cached = await cache.get(forKey: cacheKey) {
            return cached
        }
        
        // Build request
        let request = APIRequest(
            endpoint: .searchByImage,
            body: SearchRequest(
                query: nil,
                imageBase64: uploadResult.base64String,
                limit: limit
            ),
            timeout: APIConfiguration.shared.searchTimeout,
            requiresAuth: true
        )
        
        do {
            let response: SearchResponse = try await apiClient.request(request)
            let results = response.items
            
            // Update state
            lastResults = results
            
            // Cache results
            if useCache {
                await cache.set(results, forKey: cacheKey)
            }
            
            return results
            
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    // MARK: - Combined Search
    
    /// Search using both image and text for best results
    func searchCombined(
        query: String? = nil,
        image: UIImage? = nil,
        limit: Int = 20,
        useCache: Bool = true
    ) async throws -> [SearchResult] {
        // Validate inputs
        guard query?.isEmpty == false || image != nil else {
            throw APIError.serverError("At least one of query or image is required", 400)
        }
        
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        // Process image if provided
        var imageBase64: String?
        if let image = image {
            let uploadResult = try await ImageUploader.shared.processImage(image)
            imageBase64 = uploadResult.base64String
        }
        
        // Check cache
        let cacheKey = "combined_\(query ?? "")_\(imageBase64?.prefix(50) ?? "")_\(limit)"
        if useCache, let cached = await cache.get(forKey: cacheKey) {
            return cached
        }
        
        // Build request
        let request = APIRequest(
            endpoint: .searchCombined,
            body: SearchRequest(
                query: query?.isEmpty == false ? query : nil,
                imageBase64: imageBase64,
                limit: limit
            ),
            timeout: APIConfiguration.shared.searchTimeout,
            requiresAuth: true
        )
        
        do {
            let response: SearchResponse = try await apiClient.request(request)
            let results = response.items
            
            // Update state
            lastResults = results
            if let query = query, !query.isEmpty {
                addRecentSearch(query)
            }
            
            // Cache results
            if useCache {
                await cache.set(results, forKey: cacheKey)
            }
            
            return results
            
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    // MARK: - Smart Search
    
    /// Smart search that auto-detects the best method based on inputs
    func smartSearch(
        query: String? = nil,
        image: UIImage? = nil,
        limit: Int = 20
    ) async throws -> [SearchResult] {
        // Determine best search strategy
        if let image = image, let query = query, !query.isEmpty {
            // Both provided - use combined
            return try await searchCombined(query: query, image: image, limit: limit)
        } else if let image = image {
            // Only image
            return try await searchByImage(image, limit: limit)
        } else if let query = query, !query.isEmpty {
            // Only text
            return try await searchByText(query: query, limit: limit)
        } else {
            throw APIError.serverError("Search requires query or image", 400)
        }
    }
    
    // MARK: - Health Check
    
    /// Check if search API is available
    func checkHealth() async -> Bool {
        let request = APIRequest(
            endpoint: .health,
            requiresAuth: false
        )
        
        do {
            let response: HealthCheckResponse = try await apiClient.request(request)
            return response.status == "ok" || response.status == "healthy"
        } catch {
            return false
        }
    }
    
    // MARK: - Recent Searches
    
    private func loadRecentSearches() {
        if let saved = UserDefaults.standard.stringArray(forKey: "recent_searches") {
            recentSearches = saved
        }
    }
    
    private func addRecentSearch(_ query: String) {
        // Remove if exists
        recentSearches.removeAll { $0.lowercased() == query.lowercased() }
        
        // Add to front
        recentSearches.insert(query, at: 0)
        
        // Limit to 20
        if recentSearches.count > 20 {
            recentSearches = Array(recentSearches.prefix(20))
        }
        
        // Save
        UserDefaults.standard.set(recentSearches, forKey: "recent_searches")
    }
    
    func clearRecentSearches() {
        recentSearches.removeAll()
        UserDefaults.standard.removeObject(forKey: "recent_searches")
    }
    
    func removeRecentSearch(_ query: String) {
        recentSearches.removeAll { $0 == query }
        UserDefaults.standard.set(recentSearches, forKey: "recent_searches")
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        Task {
            await cache.clear()
        }
    }
}

// MARK: - Search Cache

private actor SearchCache {
    private var cache: [String: (results: [SearchResult], timestamp: Date)] = [:]
    private let cacheDuration: TimeInterval = 300 // 5 minutes
    
    func get(forKey key: String) -> [SearchResult]? {
        guard let entry = cache[key] else { return nil }
        
        // Check expiration
        if Date().timeIntervalSince(entry.timestamp) > cacheDuration {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return entry.results
    }
    
    func set(_ results: [SearchResult], forKey key: String) {
        cache[key] = (results: results, timestamp: Date())
        
        // Clean old entries periodically
        if cache.count > 100 {
            cleanOldEntries()
        }
    }
    
    func clear() {
        cache.removeAll()
    }
    
    private func cleanOldEntries() {
        let now = Date()
        cache = cache.filter { _, entry in
            now.timeIntervalSince(entry.timestamp) <= cacheDuration
        }
    }
}

// MARK: - Convenience Extensions

extension SearchAPIService {
    
    /// Search with debounce support for live search
    func searchWithDebounce(
        query: String,
        delay: TimeInterval = 0.3
    ) async throws -> [SearchResult] {
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        // Check if task was cancelled
        if Task.isCancelled {
            throw APIError.cancelled
        }
        
        return try await searchByText(query: query)
    }
}
