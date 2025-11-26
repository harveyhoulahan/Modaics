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
    let title: String
    let price: Double
    let imageUrl: String
    let itemUrl: String
    let platform: String
    let brand: String?
    let size: String?
    let condition: String?
    let similarity: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, title, price, platform, brand, size, condition, similarity
        case imageUrl = "image_url"
        case itemUrl = "item_url"
    }
}

struct SearchResponse: Codable {
    let results: [SearchResult]
    let count: Int
    let queryType: String
    
    enum CodingKeys: String, CodingKey {
        case results, count
        case queryType = "query_type"
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
            return searchResponse.results
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
                return status == "healthy"
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
        // Map platform to category
        let category: Category = {
            let title = result.title.lowercased()
            if title.contains("dress") { return .dresses }
            if title.contains("shirt") || title.contains("top") || title.contains("tee") { return .tops }
            if title.contains("pant") || title.contains("jean") || title.contains("trouser") { return .bottoms }
            if title.contains("jacket") || title.contains("coat") { return .outerwear }
            if title.contains("shoe") || title.contains("boot") || title.contains("sneaker") { return .shoes }
            return .accessories
        }()
        
        // Map condition string to Condition enum
        let condition: Condition = {
            guard let conditionStr = result.condition?.lowercased() else { return .good }
            if conditionStr.contains("new") || conditionStr.contains("like new") { return .likeNew }
            if conditionStr.contains("excellent") { return .excellent }
            if conditionStr.contains("fair") || conditionStr.contains("used") { return .fair }
            return .good
        }()
        
        // Calculate sustainability score based on platform/condition
        let sustainabilityScore = SustainabilityScore(
            totalScore: 70, // Default score for secondhand items
            carbonFootprint: 2.5,
            waterUsage: 500,
            isRecycled: true, // All secondhand items are "recycled"
            isCertified: false,
            certifications: [],
            fibreTraceVerified: false
        )
        
        return FashionItem(
            id: UUID(),
            name: result.title,
            brand: result.brand ?? "Unknown",
            category: category,
            size: result.size ?? "N/A",
            condition: condition,
            originalPrice: result.price * 1.5, // Estimate original price
            listingPrice: result.price,
            description: "Sourced from \(result.platform.capitalized)",
            imageURLs: [result.imageUrl],
            sustainabilityScore: sustainabilityScore,
            materialComposition: [],
            colorTags: [],
            styleTags: [],
            location: "Secondhand Marketplace",
            ownerId: "marketplace",
            createdAt: Date(),
            updatedAt: Date(),
            viewCount: 0,
            likeCount: 0,
            isAvailable: true
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
            title: "Vintage Prada Nylon Bag",
            price: 450.00,
            imageUrl: "https://example.com/bag.jpg",
            itemUrl: "https://depop.com/item/123",
            platform: "depop",
            brand: "Prada",
            size: "One Size",
            condition: "Excellent",
            similarity: 0.95
        ),
        SearchResult(
            id: 2,
            title: "Rick Owens DRKSHDW Ramones",
            price: 325.00,
            imageUrl: "https://example.com/shoes.jpg",
            itemUrl: "https://grailed.com/item/456",
            platform: "grailed",
            brand: "Rick Owens",
            size: "42 EU",
            condition: "Good",
            similarity: 0.89
        )
    ]
}
#endif
