//
//  SearchAPIClient+Legacy.swift
//  Modaics
//
//  Legacy compatibility layer - routes calls to new SearchAPIService
//  DEPRECATED: Use SearchAPIService directly for new code
//

import Foundation
import UIKit

// MARK: - Legacy SearchAPIClient
// This maintains backward compatibility while using the new service internally

@MainActor
class SearchAPIClient: ObservableObject {
    
    // MARK: - Properties
    
    private let service: SearchAPIService
    private let analysisService: AIAnalysisService
    
    @Published var isLoading = false
    @Published var lastError: SearchAPIError?
    
    // MARK: - Initialization
    
    init(baseURL: String = APIConfiguration.shared.baseURL) {
        self.service = SearchAPIService.shared
        self.analysisService = AIAnalysisService.shared
        
        // Sync loading states
        Task { @MainActor in
            for await isLoading in service.$isLoading.values {
                self.isLoading = isLoading
            }
        }
    }
    
    // MARK: - Legacy Search Methods
    
    /// Search by text only
    func searchByText(query: String, limit: Int = 20) async throws -> [SearchResult] {
        do {
            let results = try await service.searchByText(query: query, limit: limit)
            return results
        } catch let error as APIError {
            throw mapError(error)
        }
    }
    
    /// Search by image only
    func searchByImage(image: UIImage, limit: Int = 20) async throws -> [SearchResult] {
        do {
            let results = try await service.searchByImage(image, limit: limit)
            return results
        } catch let error as APIError {
            throw mapError(error)
        }
    }
    
    /// Combined search (image + text)
    func searchCombined(query: String?, image: UIImage?, limit: Int = 20) async throws -> [SearchResult] {
        do {
            let results = try await service.searchCombined(
                query: query,
                image: image,
                limit: limit
            )
            return results
        } catch let error as APIError {
            throw mapError(error)
        }
    }
    
    // MARK: - Legacy AI Analysis Methods
    
    /// Analyze an image using the backend AI
    func analyzeImage(_ image: UIImage) async throws -> AIAnalysisResult {
        do {
            let result = try await analysisService.analyzeImage(image)
            return mapAnalysisResult(result)
        } catch let error as APIError {
            throw mapError(error)
        }
    }
    
    /// Generate a professional description using AI
    func generateDescription(
        image: UIImage,
        category: String? = nil,
        brand: String? = nil,
        colors: [String]? = nil,
        condition: String? = nil,
        materials: [String]? = nil,
        size: String? = nil
    ) async throws -> AIDescriptionResult {
        // Use the new service's quick analysis
        do {
            let result = try await analysisService.analyzeImage(image, generateDescription: true)
            return AIDescriptionResult(
                description: result.suggestedDescription,
                method: "gpt4_vision",
                confidence: result.confidence
            )
        } catch let error as APIError {
            throw mapError(error)
        }
    }
    
    // MARK: - Legacy Health Check
    
    func checkHealth() async -> Bool {
        await service.checkHealth()
    }
    
    // MARK: - Legacy Add Item
    
    /// Add a new item to the database
    func addItem(
        image: UIImage,
        title: String,
        description: String,
        price: Double,
        brand: String? = nil,
        category: String? = nil,
        size: String? = nil,
        condition: String? = nil,
        ownerId: String? = nil,
        imageUrl: String? = nil
    ) async throws -> Int {
        do {
            let result = try await ItemService.shared.addItem(
                image: image,
                title: title,
                description: description,
                price: price,
                brand: brand,
                category: category,
                size: size,
                condition: condition,
                imageUrl: imageUrl
            )
            return result.itemId
        } catch let error as APIError {
            throw mapError(error)
        }
    }
    
    // MARK: - Error Mapping
    
    private func mapError(_ error: APIError) -> SearchAPIError {
        switch error {
        case .invalidURL:
            return .invalidURL
        case .networkError(let underlying):
            return .networkError(underlying)
        case .invalidResponse:
            return .invalidResponse
        case .decodingError(let underlying):
            return .decodingError(underlying)
        case .serverError(let message, _):
            return .serverError(message)
        case .unauthorized:
            return .serverError("Unauthorized")
        case .forbidden:
            return .serverError("Forbidden")
        case .notFound:
            return .serverError("Not found")
        case .rateLimited:
            return .serverError("Rate limited")
        case .requestTimeout:
            return .serverError("Request timeout")
        case .offline:
            return .networkError(NSError(domain: "SearchAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Offline"]))
        case .cancelled:
            return .serverError("Cancelled")
        case .unknown:
            return .invalidResponse
        }
    }
    
    // MARK: - Result Mapping
    
    private func mapAnalysisResult(_ result: ItemAnalysisResult) -> AIAnalysisResult {
        AIAnalysisResult(
            detectedItem: result.suggestedName,
            likelyBrand: result.suggestedBrand,
            category: result.suggestedCategory.rawValue,
            estimatedSize: result.suggestedSize,
            estimatedCondition: result.suggestedCondition.rawValue,
            description: result.suggestedDescription,
            colors: result.detectedColors,
            materials: result.detectedMaterials,
            estimatedPrice: result.suggestedPrice,
            confidence: result.confidence
        )
    }
}

// MARK: - Legacy Error Enum

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

// MARK: - Legacy AI Analysis Result

struct AIAnalysisResult: Codable {
    let detectedItem: String
    let likelyBrand: String
    let category: String
    let estimatedSize: String
    let estimatedCondition: String
    let description: String
    let colors: [String]
    let materials: [String]
    let estimatedPrice: Double?
    let confidence: Double
}

struct AIDescriptionResult: Codable {
    let description: String
    let method: String
    let confidence: Double
}

// MARK: - Legacy FashionItem Extension

extension SearchAPIClient {
    
    /// Convert SearchResult to FashionItem (maintains compatibility with existing UI)
    static func toFashionItem(_ result: SearchResult) -> FashionItem {
        // Use the existing implementation from the original file
        // This ensures backward compatibility with the existing FashionItem model
        
        let title = result.title ?? "Unknown Item"
        let platform = result.platform
        
        let price = result.price ?? 0.0
        let safePrice = price.isNaN || price.isInfinite ? 0.0 : max(0, price)
        let originalPrice = safePrice > 0 ? safePrice * 1.5 : 0.0
        
        // Map category
        let category: Category = {
            let searchText = (title + " " + (result.description ?? "")).lowercased()
            if searchText.contains("dress") || searchText.contains("gown") { return .dresses }
            if searchText.contains("shirt") || searchText.contains("top") || searchText.contains("tee") { return .tops }
            if searchText.contains("pant") || searchText.contains("jean") || searchText.contains("short") { return .bottoms }
            if searchText.contains("jacket") || searchText.contains("coat") || searchText.contains("blazer") { return .outerwear }
            if searchText.contains("shoe") || searchText.contains("boot") || searchText.contains("sneaker") { return .shoes }
            if searchText.contains("bag") || searchText.contains("accessory") || searchText.contains("hat") { return .accessories }
            return .accessories
        }()
        
        // Map condition
        let condition: Condition = {
            let desc = (result.description ?? "").lowercased()
            if desc.contains("new with tags") || desc.contains("nwt") { return .likeNew }
            if desc.contains("excellent") || desc.contains("mint") { return .excellent }
            if desc.contains("good") || desc.contains("great") { return .good }
            if desc.contains("fair") || desc.contains("used") { return .fair }
            return .good
        }()
        
        // Calculate sustainability
        let baseScore = 70
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
            isRecycled: true,
            isCertified: false,
            certifications: [],
            fibreTraceVerified: false
        )
        
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
            imageURLs: result.imageUrl.map { [$0] } ?? [],
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
