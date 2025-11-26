//
//  AIAnalysisService.swift
//  Modaics
//
//  AI-powered item analysis using GPT-4 Vision + CLIP backend
//

import SwiftUI
import UIKit

struct ItemAnalysisResult {
    var suggestedName: String
    var suggestedBrand: String
    var suggestedCategory: Category
    var suggestedCondition: Condition
    var suggestedSize: String
    var suggestedDescription: String
    var detectedColors: [String]
    var detectedMaterials: [String]
    var suggestedPrice: Double?
    var confidence: Double
}

@MainActor
class AIAnalysisService: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisResult: ItemAnalysisResult?
    @Published var error: String?
    
    private let backendURL = "http://10.20.99.164:8000"
    
    /// Analyze images using AI to extract item details
    func analyzeItem(images: [UIImage]) async -> ItemAnalysisResult? {
        guard !images.isEmpty else { return nil }
        
        isAnalyzing = true
        error = nil
        
        // Step 1: Use CLIP backend for visual similarity
        let visualAnalysis = await analyzeWithCLIP(image: images.first!)
        
        // Step 2: Use GPT-4 Vision for detailed description (if API key configured)
        let detailedAnalysis = await analyzeWithGPT4Vision(images: images)
        
        // Step 3: Combine results
        let result = combineAnalysis(visual: visualAnalysis, detailed: detailedAnalysis)
        
        isAnalyzing = false
        analysisResult = result
        return result
    }
    
    /// CLIP-based analysis using your existing backend
    private func analyzeWithCLIP(image: UIImage) async -> ItemAnalysisResult? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        var request = URLRequest(url: URL(string: "\(backendURL)/analyze_image")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let base64Image = imageData.base64EncodedString()
        let body: [String: Any] = ["image": base64Image]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(CLIPAnalysisResponse.self, from: data)
            
            return ItemAnalysisResult(
                suggestedName: response.detectedItem,
                suggestedBrand: response.likelyBrand,
                suggestedCategory: Category(rawValue: response.category) ?? .tops,
                suggestedCondition: .excellent,
                suggestedSize: response.estimatedSize,
                suggestedDescription: "AI-detected: \(response.description)",
                detectedColors: response.colors,
                detectedMaterials: response.materials,
                suggestedPrice: response.estimatedPrice,
                confidence: response.confidence
            )
        } catch {
            self.error = "CLIP analysis failed: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// GPT-4 Vision analysis for detailed descriptions
    private func analyzeWithGPT4Vision(images: [UIImage]) async -> GPT4VisionResponse? {
        // TODO: Implement GPT-4 Vision API call
        // This requires OpenAI API key configuration
        // For now, return nil and rely on CLIP
        return nil
    }
    
    /// Combine multiple AI analysis sources
    private func combineAnalysis(visual: ItemAnalysisResult?, detailed: GPT4VisionResponse?) -> ItemAnalysisResult {
        // If we have both analyses, merge them intelligently
        if let visual = visual, let detailed = detailed {
            // Map condition string to Condition enum
            let mappedCondition: Condition
            switch detailed.condition.lowercased() {
            case "new with tags", "new":
                mappedCondition = .new
            case "like new":
                mappedCondition = .likeNew
            case "excellent":
                mappedCondition = .excellent
            case "good":
                mappedCondition = .good
            case "fair":
                mappedCondition = .fair
            default:
                mappedCondition = visual.suggestedCondition
            }
            
            return ItemAnalysisResult(
                suggestedName: detailed.itemName.isEmpty ? visual.suggestedName : detailed.itemName,
                suggestedBrand: detailed.brand.isEmpty ? visual.suggestedBrand : detailed.brand,
                suggestedCategory: visual.suggestedCategory,
                suggestedCondition: mappedCondition,
                suggestedSize: detailed.size.isEmpty ? visual.suggestedSize : detailed.size,
                suggestedDescription: detailed.description,
                detectedColors: visual.detectedColors,
                detectedMaterials: detailed.materials.isEmpty ? visual.detectedMaterials : detailed.materials,
                suggestedPrice: detailed.estimatedPrice ?? visual.suggestedPrice,
                confidence: max(visual.confidence, detailed.confidence)
            )
        }
        
        // Fallback to visual analysis only
        return visual ?? ItemAnalysisResult(
            suggestedName: "",
            suggestedBrand: "",
            suggestedCategory: .tops,
            suggestedCondition: .excellent,
            suggestedSize: "M",
            suggestedDescription: "",
            detectedColors: [],
            detectedMaterials: [],
            suggestedPrice: nil,
            confidence: 0.0
        )
    }
}

// MARK: - Response Models

struct CLIPAnalysisResponse: Codable {
    let detectedItem: String
    let likelyBrand: String
    let category: String
    let estimatedSize: String
    let description: String
    let colors: [String]
    let materials: [String]
    let estimatedPrice: Double?
    let confidence: Double
    
    enum CodingKeys: String, CodingKey {
        case detectedItem = "detected_item"
        case likelyBrand = "likely_brand"
        case category
        case estimatedSize = "estimated_size"
        case description
        case colors
        case materials
        case estimatedPrice = "estimated_price"
        case confidence
    }
}

struct GPT4VisionResponse: Codable {
    let itemName: String
    let brand: String
    let condition: String
    let size: String
    let description: String
    let materials: [String]
    let estimatedPrice: Double?
    let confidence: Double
    
    enum CodingKeys: String, CodingKey {
        case itemName = "item_name"
        case brand
        case condition
        case size
        case description
        case materials
        case estimatedPrice = "estimated_price"
        case confidence
    }
}
