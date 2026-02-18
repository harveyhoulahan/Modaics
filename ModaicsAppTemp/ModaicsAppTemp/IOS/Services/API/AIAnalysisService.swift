//
//  AIAnalysisService.swift
//  Modaics
//
//  AI-powered item analysis using GPT-4 Vision + CLIP backend
//  Enhanced with retry logic, progress tracking, and offline support
//

import Foundation
import UIKit
import Combine

// MARK: - Analysis Result

struct ItemAnalysisResult: Identifiable {
    let id = UUID()
    var suggestedName: String
    var suggestedBrand: String
    var suggestedCategory: Category
    var suggestedCondition: Condition
    var suggestedSize: String
    var suggestedDescription: String
    var detectedColors: [String]
    var detectedPattern: String?
    var detectedMaterials: [String]
    var suggestedPrice: Double?
    var confidence: Double
    var confidenceScores: ConfidenceScores?
    var rawResponse: AIAnalysisResponse?
    
    // MARK: - Factory Methods
    
    static func empty() -> ItemAnalysisResult {
        ItemAnalysisResult(
            suggestedName: "",
            suggestedBrand: "",
            suggestedCategory: .tops,
            suggestedCondition: .good,
            suggestedSize: "M",
            suggestedDescription: "",
            detectedColors: [],
            detectedPattern: nil,
            detectedMaterials: [],
            suggestedPrice: nil,
            confidence: 0,
            confidenceScores: nil,
            rawResponse: nil
        )
    }
    
    static func from(response: AIAnalysisResponse) -> ItemAnalysisResult {
        ItemAnalysisResult(
            suggestedName: response.detectedItem,
            suggestedBrand: response.likelyBrand,
            suggestedCategory: Category.from(string: response.category),
            suggestedCondition: Condition.from(string: response.estimatedCondition),
            suggestedSize: response.estimatedSize,
            suggestedDescription: response.description,
            detectedColors: response.colors,
            detectedPattern: response.pattern,
            detectedMaterials: response.materials,
            suggestedPrice: response.estimatedPrice,
            confidence: response.confidence,
            confidenceScores: response.confidenceScores,
            rawResponse: response
        )
    }
}

// MARK: - Category & Condition Extensions

extension Category {
    static func from(string: String) -> Category {
        switch string.lowercased() {
        case "dresses", "dress": return .dresses
        case "tops", "top", "shirts", "shirt", "blouses", "blouse", "tees", "tee": return .tops
        case "bottoms", "bottom", "pants", "pant", "shorts", "short", "jeans", "jean", "skirts", "skirt": return .bottoms
        case "outerwear", "jackets", "jacket", "coats", "coat", "hoodies", "hoodie", "sweaters", "sweater": return .outerwear
        case "shoes", "shoe", "sneakers", "sneaker", "boots", "boot", "sandals", "sandal": return .shoes
        case "accessories", "accessory", "bags", "bag", "hats", "hat", "jewelry": return .accessories
        default: return .tops
        }
    }
}

extension Condition {
    static func from(string: String) -> Condition {
        switch string.lowercased() {
        case "new", "new with tags", "nwt", "brand new": return .new
        case "like new", "likenew", "excellent": return .likeNew
        case "good": return .good
        case "fair": return .fair
        default: return .good
        }
    }
}

// MARK: - Analysis Progress

enum AnalysisPhase: Equatable {
    case preparing
    case uploading(progress: Double)
    case analyzing
    case generatingDescription
    case complete
    case failed(Error)
    
    var description: String {
        switch self {
        case .preparing: return "Preparing image..."
        case .uploading: return "Uploading image..."
        case .analyzing: return "Analyzing with AI..."
        case .generatingDescription: return "Generating description..."
        case .complete: return "Complete!"
        case .failed: return "Analysis failed"
        }
    }
    
    var progress: Double {
        switch self {
        case .preparing: return 0.1
        case .uploading(let p): return 0.1 + (p * 0.3)
        case .analyzing: return 0.5
        case .generatingDescription: return 0.8
        case .complete: return 1.0
        case .failed: return 0
        }
    }
}

// MARK: - AI Analysis Service

@MainActor
class AIAnalysisService: ObservableObject {
    
    // MARK: - Shared Instance
    
    static let shared = AIAnalysisService()
    
    // MARK: - Published Properties
    
    @Published private(set) var currentPhase: AnalysisPhase = .preparing
    @Published private(set) var isAnalyzing = false
    @Published private(set) var analysisResult: ItemAnalysisResult?
    @Published private(set) var lastError: APIError?
    @Published private(set) var uploadProgress: Double = 0
    
    // MARK: - Private Properties
    
    private let apiClient: APIClient
    private let cache: AnalysisCache
    private var currentTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        self.cache = AnalysisCache()
    }
    
    // MARK: - Analysis
    
    /// Analyze a single image with full AI capabilities
    func analyzeImage(
        _ image: UIImage,
        useCache: Bool = true,
        generateDescription: Bool = true
    ) async throws -> ItemAnalysisResult {
        // Cancel any existing analysis
        cancelAnalysis()
        
        isAnalyzing = true
        lastError = nil
        currentPhase = .preparing
        defer {
            isAnalyzing = false
        }
        
        // Check cache
        let cacheKey = image.cacheKey
        if useCache, let cached = await cache.get(forKey: cacheKey) {
            currentPhase = .complete
            analysisResult = cached
            return cached
        }
        
        // Step 1: Process image
        currentPhase = .uploading(progress: 0)
        let uploadResult = try await ImageUploader.shared.processImage(image)
        currentPhase = .uploading(progress: 1.0)
        
        // Step 2: Analyze image
        currentPhase = .analyzing
        let analysisResponse = try await performAnalysis(imageBase64: uploadResult.base64String)
        
        var result = ItemAnalysisResult.from(response: analysisResponse)
        
        // Step 3: Generate enhanced description if requested
        if generateDescription {
            currentPhase = .generatingDescription
            let descriptionResponse = try await generateDescription(
                imageBase64: uploadResult.base64String,
                analysis: analysisResponse
            )
            result.suggestedDescription = descriptionResponse.description
        }
        
        // Complete
        currentPhase = .complete
        analysisResult = result
        
        // Cache result
        if useCache {
            await cache.set(result, forKey: cacheKey)
        }
        
        return result
    }
    
    /// Analyze multiple images and combine results
    func analyzeImages(
        _ images: [UIImage],
        useCache: Bool = true
    ) async throws -> ItemAnalysisResult {
        guard !images.isEmpty else {
            throw APIError.serverError("At least one image is required", 400)
        }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // Analyze first image as primary
        let primaryResult = try await analyzeImage(images[0], useCache: useCache)
        
        // If only one image, return immediately
        guard images.count > 1 else {
            return primaryResult
        }
        
        // Analyze additional images for verification
        var allColors = Set(primaryResult.detectedColors)
        var allMaterials = Set(primaryResult.detectedMaterials)
        var totalConfidence = primaryResult.confidence
        
        for (index, image) in images.dropFirst().enumerated() {
            // Update progress
            currentPhase = .analyzing
            
            do {
                let result = try await analyzeImage(image, useCache: useCache, generateDescription: false)
                allColors.formUnion(result.detectedColors)
                allMaterials.formUnion(result.detectedMaterials)
                totalConfidence += result.confidence
            } catch {
                print("⚠️ Failed to analyze image \(index + 2): \(error)")
            }
        }
        
        // Combine results
        var combinedResult = primaryResult
        combinedResult.detectedColors = Array(allColors).sorted()
        combinedResult.detectedMaterials = Array(allMaterials).sorted()
        combinedResult.confidence = totalConfidence / Double(images.count)
        
        currentPhase = .complete
        analysisResult = combinedResult
        
        return combinedResult
    }
    
    // MARK: - Private Methods
    
    private func performAnalysis(imageBase64: String) async throws -> AIAnalysisResponse {
        let request = APIRequest(
            endpoint: .analyzeImage,
            body: AIAnalysisRequest(image: imageBase64),
            timeout: 60,
            requiresAuth: true,
            retryPolicy: APIRequest.RetryPolicy(
                maxAttempts: 3,
                delay: 2.0,
                maxDelay: 10.0,
                retryableStatusCodes: [408, 429, 500, 502, 503, 504]
            )
        )
        
        do {
            return try await apiClient.request(request)
        } catch let error as APIError {
            lastError = error
            currentPhase = .failed(error)
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            currentPhase = .failed(apiError)
            throw apiError
        }
    }
    
    private func generateDescription(
        imageBase64: String,
        analysis: AIAnalysisResponse
    ) async throws -> GenerateDescriptionResponse {
        let request = APIRequest(
            endpoint: .generateDescription,
            body: GenerateDescriptionRequest(
                image: imageBase64,
                category: analysis.category,
                brand: analysis.likelyBrand,
                colors: analysis.colors,
                condition: analysis.estimatedCondition,
                materials: analysis.materials,
                size: analysis.estimatedSize
            ),
            timeout: 45,
            requiresAuth: true
        )
        
        do {
            return try await apiClient.request(request)
        } catch {
            // Fallback to template description if generation fails
            return GenerateDescriptionResponse(
                description: analysis.description,
                method: "template",
                confidence: 0.75
            )
        }
    }
    
    // MARK: - Quick Analysis
    
    /// Quick analysis without progress tracking (for background tasks)
    func quickAnalyze(_ image: UIImage) async throws -> ItemAnalysisResult {
        let uploadResult = try await ImageUploader.shared.processImage(image)
        let response: AIAnalysisResponse = try await apiClient.request(
            APIRequest(
                endpoint: .analyzeImage,
                body: AIAnalysisRequest(image: uploadResult.base64String),
                requiresAuth: true
            )
        )
        return ItemAnalysisResult.from(response: response)
    }
    
    // MARK: - Cancellation
    
    func cancelAnalysis() {
        currentTask?.cancel()
        apiClient.cancelRequests(for: .analyzeImage)
        apiClient.cancelRequests(for: .generateDescription)
        isAnalyzing = false
        currentPhase = .preparing
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        Task {
            await cache.clear()
        }
    }
    
    // MARK: - Reset
    
    func reset() {
        cancelAnalysis()
        analysisResult = nil
        lastError = nil
        currentPhase = .preparing
        uploadProgress = 0
    }
}

// MARK: - Analysis Cache

@MainActor
private actor AnalysisCache {
    private var cache: [String: (result: ItemAnalysisResult, timestamp: Date)] = [:]
    private let cacheDuration: TimeInterval = 3600 // 1 hour
    
    func get(forKey key: String) -> ItemAnalysisResult? {
        guard let entry = cache[key] else { return nil }
        
        // Check expiration
        if Date().timeIntervalSince(entry.timestamp) > cacheDuration {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return entry.result
    }
    
    func set(_ result: ItemAnalysisResult, forKey key: String) {
        cache[key] = (result: result, timestamp: Date())
        
        // Clean old entries periodically
        if cache.count > 50 {
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

// MARK: - UI Helpers

extension AIAnalysisService {
    
    /// Get confidence color based on score
    func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
    
    /// Get confidence label
    func confidenceLabel(_ confidence: Double) -> String {
        switch confidence {
        case 0.8...1.0: return "High confidence"
        case 0.6..<0.8: return "Good confidence"
        case 0.4..<0.6: return "Moderate confidence"
        default: return "Low confidence"
        }
    }
}

// For SwiftUI Color compatibility
import SwiftUI
