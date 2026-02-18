//
//  MockAPIService.swift
//  Modaics
//
//  Mock API responses for testing and development
//

import Foundation
import UIKit

// MARK: - Mock API Service

@MainActor
class MockAPIService {
    
    // MARK: - Shared Instance
    
    static let shared = MockAPIService()
    
    // MARK: - Configuration
    
    var shouldSimulateNetworkDelay = true
    var simulatedDelay: TimeInterval = 1.0
    var shouldSimulateErrors = false
    var errorRate: Double = 0.1 // 10% error rate
    
    // MARK: - Helpers
    
    private func simulateDelay() async {
        if shouldSimulateNetworkDelay {
            try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
    }
    
    private func maybeThrowError() throws {
        guard shouldSimulateErrors else { return }
        if Double.random(in: 0...1) < errorRate {
            throw APIError.serverError("Simulated error", 500)
        }
    }
}

// MARK: - Mock Search

extension MockAPIService {
    
    func mockSearchByText(query: String) async throws -> [SearchResult] {
        try maybeThrowError()
        await simulateDelay()
        
        return [
            SearchResult(
                id: 1,
                externalId: "mock1",
                title: "Vintage \(query) - Black",
                description: "Authentic vintage piece in excellent condition",
                price: 250.00,
                url: "https://example.com/item/1",
                imageUrl: "https://example.com/image1.jpg",
                source: "depop",
                distance: 0.15,
                similarity: nil,
                redirectUrl: nil
            ),
            SearchResult(
                id: 2,
                externalId: "mock2",
                title: "Designer \(query)",
                description: "High quality designer piece",
                price: 450.00,
                url: "https://example.com/item/2",
                imageUrl: "https://example.com/image2.jpg",
                source: "grailed",
                distance: 0.22,
                similarity: nil,
                redirectUrl: nil
            ),
            SearchResult(
                id: 3,
                externalId: "mock3",
                title: "Rare \(query) Limited Edition",
                description: "Limited edition release, hard to find",
                price: 650.00,
                url: "https://example.com/item/3",
                imageUrl: "https://example.com/image3.jpg",
                source: "vestiaire",
                distance: 0.28,
                similarity: nil,
                redirectUrl: nil
            )
        ]
    }
    
    func mockSearchByImage() async throws -> [SearchResult] {
        try maybeThrowError()
        await simulateDelay()
        
        return [
            SearchResult(
                id: 4,
                externalId: "mock4",
                title: "Similar Style Item",
                description: "Visually similar to your uploaded image",
                price: 180.00,
                url: "https://example.com/item/4",
                imageUrl: "https://example.com/image4.jpg",
                source: "depop",
                distance: 0.05,
                similarity: nil,
                redirectUrl: nil
            ),
            SearchResult(
                id: 5,
                externalId: "mock5",
                title: "Alternative Colorway",
                description: "Same item in different color",
                price: 220.00,
                url: "https://example.com/item/5",
                imageUrl: "https://example.com/image5.jpg",
                source: "grailed",
                distance: 0.12,
                similarity: nil,
                redirectUrl: nil
            )
        ]
    }
}

// MARK: - Mock AI Analysis

extension MockAPIService {
    
    func mockAnalyzeImage() async throws -> AIAnalysisResponse {
        try maybeThrowError()
        await simulateDelay()
        
        return AIAnalysisResponse(
            detectedItem: "Vintage Denim Jacket",
            likelyBrand: "Levi's",
            category: "outerwear",
            specificCategory: "denim_jacket",
            estimatedSize: "M",
            estimatedCondition: "good",
            description: "Classic Levi's denim jacket in medium wash",
            colors: ["Blue", "Indigo"],
            pattern: "Denim Wash",
            materials: ["Cotton", "Denim"],
            estimatedPrice: 85.00,
            confidence: 0.87,
            confidenceScores: ConfidenceScores(
                category: 0.92,
                colors: [0.88, 0.85],
                pattern: 0.90,
                brand: 0.78
            )
        )
    }
    
    func mockGenerateDescription() async throws -> GenerateDescriptionResponse {
        try maybeThrowError()
        await simulateDelay()
        
        return GenerateDescriptionResponse(
            description: "Authentic Levi's denim jacket in medium indigo wash. Features classic trucker styling with button front closure and chest pockets. Good vintage condition with authentic fade and wear.",
            method: "gpt4_vision",
            confidence: 0.95
        )
    }
}

// MARK: - Mock Items

extension MockAPIService {
    
    func mockAddItem() async throws -> AddItemResponse {
        try maybeThrowError()
        await simulateDelay()
        
        return AddItemResponse(
            success: true,
            itemId: Int.random(in: 1000...9999),
            message: "Item added successfully with CLIP embeddings"
        )
    }
}

// MARK: - Mock Sketchbook

extension MockAPIService {
    
    func mockSketchbook(brandId: String) -> Sketchbook {
        Sketchbook(
            id: 1,
            brandId: brandId,
            title: "\(brandId) Sketchbook",
            description: "Exclusive community for \(brandId) enthusiasts",
            accessPolicy: .members_only,
            membershipRule: .autoApprove,
            minSpendAmount: nil,
            minSpendWindowMonths: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    func mockPosts(count: Int = 5) -> [SketchbookPost] {
        (0..<count).map { index in
            SketchbookPost(
                id: index,
                sketchbookId: 1,
                authorUserId: "user_\(index)",
                postType: index % 3 == 0 ? .poll : .standard,
                title: "Sample Post \(index + 1)",
                body: "This is a sample post body for testing purposes.",
                media: [],
                tags: ["fashion", "vintage"],
                visibility: .public,
                pollQuestion: index % 3 == 0 ? "What's your favorite color?" : nil,
                pollOptions: index % 3 == 0 ? [
                    PollOption(id: "1", label: "Blue", votes: 10),
                    PollOption(id: "2", label: "Red", votes: 5),
                    PollOption(id: "3", label: "Green", votes: 8)
                ] : nil,
                pollClosesAt: index % 3 == 0 ? Date().addingTimeInterval(86400) : nil,
                eventId: nil,
                eventHighlight: nil,
                reactionCount: Int.random(in: 5...50),
                commentCount: Int.random(in: 0...10),
                createdAt: Date().addingTimeInterval(-Double(index * 3600)),
                updatedAt: Date()
            )
        }
    }
    
    func mockMembership() -> SketchbookMembership {
        SketchbookMembership(
            id: 1,
            sketchbookId: 1,
            userId: "current_user",
            status: .active,
            joinSource: .autoApproved,
            joinedAt: Date(),
            expiresAt: nil
        )
    }
}

// MARK: - Mock Service Integration

extension SearchAPIService {
    
    /// Enable mock mode for testing
    func enableMockMode() {
        APIConfiguration.shared.useMockData = true
    }
    
    /// Disable mock mode
    func disableMockMode() {
        APIConfiguration.shared.useMockData = false
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension MockAPIService {
    
    /// Simulate various error scenarios for testing
    func simulateError(_ error: APIError) async throws {
        await simulateDelay()
        throw error
    }
    
    /// Generate random search results for load testing
    func generateRandomResults(count: Int) -> [SearchResult] {
        let sources = ["depop", "grailed", "vestiaire", "theRealReal", "eBay"]
        let brands = ["Nike", "Adidas", "Prada", "Gucci", "Levi's", "Vintage"]
        
        return (0..<count).map { index in
            SearchResult(
                id: index,
                externalId: "random_\(index)",
                title: "\(brands.randomElement()!) Item \(index)",
                description: "Randomly generated item for testing",
                price: Double.random(in: 50...500),
                url: "https://example.com/item/\(index)",
                imageUrl: "https://example.com/image\(index).jpg",
                source: sources.randomElement(),
                distance: Double.random(in: 0...0.5),
                similarity: nil,
                redirectUrl: nil
            )
        }
    }
}
#endif
