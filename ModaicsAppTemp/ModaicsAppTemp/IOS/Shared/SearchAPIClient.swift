//
//  SearchAPIClient.swift
//  ModaicsAppTemp
//
//  API client for FindThisFit CLIP search backend
//  Integrates multimodal search (image + text) into Modaics Discover tab
//

import Foundation
import UIKit

// MARK: - API Models

struct SearchRequest: Codable {
    let query: String?
    let imageBase64: String?
    let limit: Int?
    
    enum CodingKeys: String, CodingKey {
        case query
        case imageBase64 = "image_base64"
        case limit
    }
}

struct SearchResult: Codable, Identifiable {
    let id: Int
    let externalId: String?
    let title: String?
    let description: String?
    let price: Double?
    let url: String?
    let imageUrl: String?
    let source: String?
    let distance: Double?
    let similarity: Double?
    let redirectUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case externalId = "external_id"
        case title
        case description
        case price
        case url
        case imageUrl = "image_url"
        case source
        case distance
        case similarity
        case redirectUrl = "redirect_url"
    }
    
    // Computed properties for compatibility
    var itemUrl: String {
        redirectUrl ?? url ?? ""
    }
    
    var platform: String {
        source?.capitalized ?? "Unknown"
    }
    
    var brand: String? {
        // Extract brand from title if possible
        extractBrand(from: title)
    }
    
    private func extractBrand(from title: String?) -> String? {
        guard let title = title else { return nil }
        // Common brand patterns - could be enhanced
        let brands = ["Prada", "Gucci", "Rick Owens", "Yohji Yamamoto", "Comme des Garçons", 
                     "Nike", "Adidas", "Supreme", "Palace", "Stone Island", "CP Company",
                     "Burberry", "Louis Vuitton", "Hermès", "Chanel", "Dior"]
        for brand in brands {
            if title.localizedCaseInsensitiveContains(brand) {
                return brand
            }
        }
        return nil
    }
}

struct SearchResponse: Codable {
    let items: [SearchResult]
    
    var count: Int {
        items.count
    }
    
    var queryType: String {
        "search"
    }
}

// MARK: - Network Error

enum SearchAPIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - Search API Client

@MainActor
class SearchAPIClient: ObservableObject {
    
    // MARK: - Configuration
    
    private let baseURL: String
    private let session: URLSession
    
    @Published var isLoading = false
    @Published var lastError: SearchAPIError?
    
    init(baseURL: String = "http://localhost:8000") {
        self.baseURL = baseURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Search Methods
    
    /// Search by text only
    func searchByText(query: String, limit: Int = 20) async throws -> [SearchResult] {
        isLoading = true
        defer { isLoading = false }
        
        let endpoint = "\(baseURL)/search_by_text"
        let request = SearchRequest(query: query, imageBase64: nil, limit: limit)
        
        return try await performSearch(endpoint: endpoint, request: request)
    }
    
    /// Search by image only
    func searchByImage(image: UIImage, limit: Int = 20) async throws -> [SearchResult] {
        isLoading = true
        defer { isLoading = false }
        
        let endpoint = "\(baseURL)/search_by_image"
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw SearchAPIError.invalidResponse
        }
        
        let base64String = imageData.base64EncodedString()
        let request = SearchRequest(query: nil, imageBase64: base64String, limit: limit)
        
        return try await performSearch(endpoint: endpoint, request: request)
    }
    
    /// Combined search (image + text)
    func searchCombined(query: String?, image: UIImage?, limit: Int = 20) async throws -> [SearchResult] {
        isLoading = true
        defer { isLoading = false }
        
        let endpoint = "\(baseURL)/search_combined"
        
        var base64String: String?
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            base64String = imageData.base64EncodedString()
        }
        
        let request = SearchRequest(
            query: query?.isEmpty == false ? query : nil,
            imageBase64: base64String,
            limit: limit
        )
        
        return try await performSearch(endpoint: endpoint, request: request)
    }
    
    // MARK: - Private Methods
    
    private func performSearch(endpoint: String, request: SearchRequest) async throws -> [SearchResult] {
        guard let url = URL(string: endpoint) else {
            throw SearchAPIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw SearchAPIError.decodingError(error)
        }
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SearchAPIError.invalidResponse
        }
        
        // Check status code
        switch httpResponse.statusCode {
        case 200:
            break
        case 400...499:
            throw SearchAPIError.serverError("Client error: \(httpResponse.statusCode)")
        case 500...599:
            throw SearchAPIError.serverError("Server error: \(httpResponse.statusCode)")
        default:
            throw SearchAPIError.invalidResponse
        }
        
        // Decode response
        do {
            let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
            return searchResponse.items
        } catch {
            throw SearchAPIError.decodingError(error)
        }
    }
    
    // MARK: - Health Check
    
    func checkHealth() async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else {
            return false
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }
            
            // Try to decode health response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String {
                return status == "ok" || status == "healthy"
            }
            
            return false
        } catch {
            return false
        }
    }
}

// MARK: - Convenience Extensions

extension SearchAPIClient {
    
    /// Convert SearchResult to FashionItem for compatibility with existing UI
    static func toFashionItem(_ result: SearchResult) -> FashionItem {
        let title = result.title ?? "Unknown Item"
        let platform = result.platform
        
        // Safely extract price with fallback to 0
        let price = result.price ?? 0.0
        let safePrice = price.isNaN || price.isInfinite ? 0.0 : max(0, price)
        let originalPrice = safePrice > 0 ? safePrice * 1.5 : 0.0
        
        // Map title/description to category
        let category: Category = {
            let searchText = (title + " " + (result.description ?? "")).lowercased()
            if searchText.contains("dress") || searchText.contains("gown") { return .dresses }
            if searchText.contains("shirt") || searchText.contains("top") || searchText.contains("tee") || searchText.contains("blouse") { return .tops }
            if searchText.contains("pant") || searchText.contains("jean") || searchText.contains("trouser") || searchText.contains("short") { return .bottoms }
            if searchText.contains("jacket") || searchText.contains("coat") || searchText.contains("blazer") || searchText.contains("cardigan") { return .outerwear }
            if searchText.contains("shoe") || searchText.contains("boot") || searchText.contains("sneaker") || searchText.contains("trainer") { return .shoes }
            if searchText.contains("bag") || searchText.contains("accessory") || searchText.contains("hat") || searchText.contains("scarf") { return .accessories }
            return .accessories
        }()
        
        // Map platform/condition to Condition enum
        let condition: Condition = {
            let desc = (result.description ?? "").lowercased()
            if desc.contains("new with tags") || desc.contains("nwt") || desc.contains("brand new") { return .likeNew }
            if desc.contains("excellent") || desc.contains("mint") || desc.contains("perfect") { return .excellent }
            if desc.contains("good") || desc.contains("great") { return .good }
            if desc.contains("fair") || desc.contains("used") || desc.contains("worn") { return .fair }
            return .good // Default for secondhand
        }()
        
        // Calculate sustainability score based on platform/condition and similarity
        let baseScore = 70 // Secondhand items start at 70
        let conditionBonus: Int = {
            switch condition {
            case .new: return 15
            case .likeNew: return 10
            case .excellent: return 8
            case .good: return 5
            case .fair: return 2
            }
        }()
        
        let sustainabilityScore = SustainabilityScore(
            totalScore: min(baseScore + conditionBonus, 100),
            carbonFootprint: 2.5,
            waterUsage: 500,
            isRecycled: true, // All secondhand items are "recycled"
            isCertified: false,
            certifications: [],
            fibreTraceVerified: false
        )
        
        // Get image URL, fallback to empty string
        let imageURLs = result.imageUrl.map { [$0] } ?? []
        
        return FashionItem(
            id: UUID(),
            name: title,
            brand: result.brand ?? platform,
            category: category,
            size: "N/A",
            condition: condition,
            originalPrice: originalPrice,
            listingPrice: safePrice,
            description: result.description ?? "Sourced from \(platform)",
            imageURLs: imageURLs,
            sustainabilityScore: sustainabilityScore,
            materialComposition: [],
            colorTags: [],
            styleTags: [platform.lowercased(), "secondhand", "vintage"],
            location: "Secondhand Marketplace",
            ownerId: "marketplace_\(platform.lowercased())",
            createdAt: Date(),
            updatedAt: Date(),
            viewCount: 0,
            likeCount: 0,
            isAvailable: true,
            externalURL: result.itemUrl,
            similarity: result.similarity
        )
    }
}

// MARK: - Preview Helper

#if DEBUG
extension SearchAPIClient {
    static let mock = SearchAPIClient(baseURL: "http://localhost:8000")
    
    static let sampleResults: [SearchResult] = [
        SearchResult(
            id: 1,
            externalId: "123",
            title: "Vintage Prada Nylon Bag",
            description: "Authentic vintage Prada bag in excellent condition",
            price: 450.00,
            url: "https://depop.com/item/123",
            imageUrl: "https://example.com/bag.jpg",
            source: "depop",
            distance: 0.05,
            similarity: 0.95,
            redirectUrl: "depop://product/123"
        ),
        SearchResult(
            id: 2,
            externalId: "456",
            title: "Rick Owens DRKSHDW Ramones",
            description: "Classic Rick Owens sneakers, size 42",
            price: 325.00,
            url: "https://grailed.com/item/456",
            imageUrl: "https://example.com/shoes.jpg",
            source: "grailed",
            distance: 0.11,
            similarity: 0.89,
            redirectUrl: "https://grailed.com/listings/456"
        )
    ]
}
#endif
