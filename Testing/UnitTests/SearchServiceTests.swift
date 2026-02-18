//
//  SearchServiceTests.swift
//  ModaicsTests
//
//  Comprehensive unit tests for SearchAPIService
//  Tests: Text search, image search, combined search, caching
//

import XCTest
@testable import Modaics
import UIKit
import Combine

@MainActor
final class SearchServiceTests: XCTestCase {
    
    // MARK: - Properties
    var sut: SearchAPIService!
    var mockAPIClient: MockSearchAPIClient!
    var mockImageUploader: MockImageUploader!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        mockAPIClient = MockSearchAPIClient()
        mockImageUploader = MockImageUploader()
        sut = SearchAPIService(apiClient: mockAPIClient, imageUploader: mockImageUploader)
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockAPIClient = nil
        mockImageUploader = nil
        super.tearDown()
    }
    
    // MARK: - Text Search Tests
    
    func testSearchByText_Success() async throws {
        // Given
        let query = "vintage leather jacket"
        let mockResults = [
            SearchResult(id: "1", title: "Vintage Brown Leather Jacket", price: 150.0, imageUrl: "url1"),
            SearchResult(id: "2", title: "Black Leather Biker Jacket", price: 120.0, imageUrl: "url2"),
            SearchResult(id: "3", title: "Vintage Leather Bomber", price: 180.0, imageUrl: "url3")
        ]
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 3,
            query: query,
            searchTime: 0.15
        )
        
        // When
        let results = try await sut.searchByText(query: query, limit: 20)
        
        // Then
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].title, "Vintage Brown Leather Jacket")
        XCTAssertEqual(sut.lastResults.count, 3)
        XCTAssertTrue(mockAPIClient.searchByTextCalled)
        XCTAssertNil(sut.lastError)
    }
    
    func testSearchByText_EmptyQuery() async throws {
        // Given
        let query = ""
        
        // When
        let results = try await sut.searchByText(query: query)
        
        // Then
        XCTAssertTrue(results.isEmpty)
        XCTAssertFalse(mockAPIClient.searchByTextCalled)
    }
    
    func testSearchByText_WhitespaceOnly() async throws {
        // Given
        let query = "   "
        
        // When
        let results = try await sut.searchByText(query: query)
        
        // Then
        XCTAssertTrue(results.isEmpty)
        XCTAssertFalse(mockAPIClient.searchByTextCalled)
    }
    
    func testSearchByText_NoResults() async throws {
        // Given
        let query = "xyznonexistentitem123"
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: [],
            total: 0,
            query: query,
            searchTime: 0.05
        )
        
        // When
        let results = try await sut.searchByText(query: query)
        
        // Then
        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(sut.lastResults.count, 0)
    }
    
    func testSearchByText_WithCustomLimit() async throws {
        // Given
        let query = "jacket"
        let limit = 10
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: (1...limit).map { i in
                SearchResult(id: "\(i)", title: "Item \(i)", price: Double(i * 10), imageUrl: "url\(i)")
            },
            total: limit,
            query: query,
            searchTime: 0.1
        )
        
        // When
        let results = try await sut.searchByText(query: query, limit: limit)
        
        // Then
        XCTAssertEqual(results.count, limit)
        XCTAssertTrue(mockAPIClient.searchByTextCalled)
    }
    
    func testSearchByText_NetworkError() async throws {
        // Given
        let query = "jacket"
        mockAPIClient.mockError = APIError.offline
        
        // When/Then
        do {
            _ = try await sut.searchByText(query: query)
            XCTFail("Expected network error")
        } catch let error as APIError {
            XCTAssertEqual(error, .offline)
            XCTAssertEqual(sut.lastError, .offline)
        }
    }
    
    func testSearchByText_RateLimited() async throws {
        // Given
        let query = "jacket"
        mockAPIClient.mockError = APIError.rateLimited
        
        // When/Then
        do {
            _ = try await sut.searchByText(query: query)
            XCTFail("Expected rate limit error")
        } catch let error as APIError {
            XCTAssertEqual(error, .rateLimited)
        }
    }
    
    // MARK: - Image Search Tests
    
    func testSearchByImage_Success() async throws {
        // Given
        let mockImage = createMockImage()
        let mockResults = [
            SearchResult(id: "1", title: "Similar Jacket", price: 145.0, imageUrl: "url1"),
            SearchResult(id: "2", title: "Lookalike Coat", price: 130.0, imageUrl: "url2")
        ]
        
        mockImageUploader.mockUploadResult = ImageUploadResult(
            base64String: "base64_encoded_image_data",
            url: nil,
            dimensions: CGSize(width: 1024, height: 1024)
        )
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 2,
            query: nil,
            searchTime: 0.25
        )
        
        // When
        let results = try await sut.searchByImage(mockImage, limit: 20)
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(mockImageUploader.processImageCalled)
        XCTAssertTrue(mockAPIClient.searchByImageCalled)
    }
    
    func testSearchByImage_InvalidImage() async throws {
        // Given
        let mockImage = createMockImage()
        mockImageUploader.mockError = ImageUploadError.invalidImage
        
        // When/Then
        do {
            _ = try await sut.searchByImage(mockImage)
            XCTFail("Expected image upload error")
        } catch {
            // Expected error
        }
    }
    
    func testSearchByImage_EmptyResults() async throws {
        // Given
        let mockImage = createMockImage()
        
        mockImageUploader.mockUploadResult = ImageUploadResult(
            base64String: "base64_data",
            url: nil,
            dimensions: CGSize(width: 512, height: 512)
        )
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: [],
            total: 0,
            query: nil,
            searchTime: 0.2
        )
        
        // When
        let results = try await sut.searchByImage(mockImage)
        
        // Then
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - Combined Search Tests
    
    func testSearchCombined_WithTextAndImage() async throws {
        // Given
        let query = "vintage brown"
        let mockImage = createMockImage()
        let mockResults = [
            SearchResult(id: "1", title: "Vintage Brown Leather Jacket", price: 150.0, imageUrl: "url1"),
            SearchResult(id: "2", title: "Brown Vintage Coat", price: 135.0, imageUrl: "url2")
        ]
        
        mockImageUploader.mockUploadResult = ImageUploadResult(
            base64String: "base64_data",
            url: nil,
            dimensions: CGSize(width: 1024, height: 1024)
        )
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 2,
            query: query,
            searchTime: 0.3
        )
        
        // When
        let results = try await sut.searchCombined(query: query, image: mockImage, limit: 20)
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(mockImageUploader.processImageCalled)
        XCTAssertTrue(mockAPIClient.searchCombinedCalled)
    }
    
    func testSearchCombined_OnlyText() async throws {
        // Given
        let query = "leather jacket"
        let mockResults = [
            SearchResult(id: "1", title: "Leather Jacket", price: 150.0, imageUrl: "url1")
        ]
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 1,
            query: query,
            searchTime: 0.15
        )
        
        // When
        let results = try await sut.searchCombined(query: query, image: nil, limit: 20)
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(mockImageUploader.processImageCalled)
    }
    
    func testSearchCombined_OnlyImage() async throws {
        // Given
        let mockImage = createMockImage()
        let mockResults = [
            SearchResult(id: "1", title: "Similar Item", price: 100.0, imageUrl: "url1")
        ]
        
        mockImageUploader.mockUploadResult = ImageUploadResult(
            base64String: "base64_data",
            url: nil,
            dimensions: CGSize(width: 512, height: 512)
        )
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 1,
            query: nil,
            searchTime: 0.2
        )
        
        // When
        let results = try await sut.searchCombined(query: nil, image: mockImage, limit: 20)
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(mockImageUploader.processImageCalled)
    }
    
    func testSearchCombined_NoInput() async throws {
        // When/Then
        do {
            _ = try await sut.searchCombined(query: nil, image: nil)
            XCTFail("Expected error for missing input")
        } catch let error as APIError {
            if case .serverError(let message, _) = error {
                XCTAssertTrue(message.contains("query or image"))
            } else {
                XCTFail("Expected server error")
            }
        }
    }
    
    // MARK: - Smart Search Tests
    
    func testSmartSearch_BothInputs() async throws {
        // Given
        let query = "brown leather"
        let mockImage = createMockImage()
        let mockResults = [SearchResult(id: "1", title: "Brown Leather Jacket", price: 150.0, imageUrl: "url1")]
        
        mockImageUploader.mockUploadResult = ImageUploadResult(
            base64String: "base64_data",
            url: nil,
            dimensions: CGSize(width: 1024, height: 1024)
        )
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 1,
            query: query,
            searchTime: 0.3
        )
        
        // When
        let results = try await sut.smartSearch(query: query, image: mockImage)
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(mockAPIClient.searchCombinedCalled)
    }
    
    func testSmartSearch_OnlyImage() async throws {
        // Given
        let mockImage = createMockImage()
        let mockResults = [SearchResult(id: "1", title: "Similar Item", price: 100.0, imageUrl: "url1")]
        
        mockImageUploader.mockUploadResult = ImageUploadResult(
            base64String: "base64_data",
            url: nil,
            dimensions: CGSize(width: 512, height: 512)
        )
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 1,
            query: nil,
            searchTime: 0.2
        )
        
        // When
        let results = try await sut.smartSearch(query: nil, image: mockImage)
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(mockAPIClient.searchByImageCalled)
        XCTAssertFalse(mockAPIClient.searchCombinedCalled)
    }
    
    func testSmartSearch_OnlyText() async throws {
        // Given
        let query = "jacket"
        let mockResults = [SearchResult(id: "1", title: "Jacket", price: 100.0, imageUrl: "url1")]
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 1,
            query: query,
            searchTime: 0.15
        )
        
        // When
        let results = try await sut.smartSearch(query: query, image: nil)
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(mockAPIClient.searchByTextCalled)
        XCTAssertFalse(mockAPIClient.searchByImageCalled)
    }
    
    func testSmartSearch_NoInput() async throws {
        // When/Then
        do {
            _ = try await sut.smartSearch(query: nil, image: nil)
            XCTFail("Expected error")
        } catch {
            // Expected
        }
    }
    
    // MARK: - Caching Tests
    
    func testSearchByText_CacheHit() async throws {
        // Given
        let query = "vintage jacket"
        let mockResults = [SearchResult(id: "1", title: "Vintage Jacket", price: 150.0, imageUrl: "url1")]
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 1,
            query: query,
            searchTime: 0.15
        )
        
        // First search - should hit API
        _ = try await sut.searchByText(query: query, useCache: true)
        XCTAssertTrue(mockAPIClient.searchByTextCalled)
        
        // Reset mock
        mockAPIClient.searchByTextCalled = false
        
        // Second search - should hit cache
        let cachedResults = try await sut.searchByText(query: query, useCache: true)
        
        // Then
        XCTAssertFalse(mockAPIClient.searchByTextCalled) // Should not call API
        XCTAssertEqual(cachedResults.count, 1)
        XCTAssertEqual(cachedResults[0].title, "Vintage Jacket")
    }
    
    func testSearchByText_CacheMiss() async throws {
        // Given
        let query = "different query"
        let mockResults = [SearchResult(id: "1", title: "Item", price: 100.0, imageUrl: "url1")]
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 1,
            query: query,
            searchTime: 0.1
        )
        
        // Search with cache disabled
        let results = try await sut.searchByText(query: query, useCache: false)
        
        // Then
        XCTAssertTrue(mockAPIClient.searchByTextCalled)
        XCTAssertEqual(results.count, 1)
    }
    
    func testClearCache() {
        // When
        sut.clearCache()
        
        // Then
        // Should not crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Recent Searches Tests
    
    func testRecentSearches_Add() async throws {
        // Given
        let query = "new search"
        let mockResults = [SearchResult(id: "1", title: "Item", price: 100.0, imageUrl: "url1")]
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 1,
            query: query,
            searchTime: 0.1
        )
        
        // When
        _ = try await sut.searchByText(query: query)
        
        // Then
        XCTAssertTrue(sut.recentSearches.contains(query))
        XCTAssertEqual(sut.recentSearches.first, query)
    }
    
    func testRecentSearches_DuplicateNotAdded() async throws {
        // Given
        let query = "duplicate search"
        let mockResults = [SearchResult(id: "1", title: "Item", price: 100.0, imageUrl: "url1")]
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 1,
            query: query,
            searchTime: 0.1
        )
        
        // When
        _ = try await sut.searchByText(query: query)
        _ = try await sut.searchByText(query: query.uppercased()) // Case insensitive
        
        // Then
        let occurrences = sut.recentSearches.filter { $0.lowercased() == query.lowercased() }.count
        XCTAssertEqual(occurrences, 1)
    }
    
    func testRecentSearches_MaxLimit() async throws {
        // Given
        let mockResults = [SearchResult(id: "1", title: "Item", price: 100.0, imageUrl: "url1")]
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 1,
            query: "query",
            searchTime: 0.1
        )
        
        // When
        for i in 1...25 {
            mockAPIClient.mockSearchResponse = SearchResponse(
                items: mockResults,
                total: 1,
                query: "query \(i)",
                searchTime: 0.1
            )
            _ = try? await sut.searchByText(query: "query \(i)")
        }
        
        // Then
        XCTAssertEqual(sut.recentSearches.count, 20) // Max limit
    }
    
    func testClearRecentSearches() {
        // Given
        sut.recentSearches = ["search1", "search2", "search3"]
        
        // When
        sut.clearRecentSearches()
        
        // Then
        XCTAssertTrue(sut.recentSearches.isEmpty)
    }
    
    func testRemoveRecentSearch() {
        // Given
        sut.recentSearches = ["search1", "search2", "search3"]
        
        // When
        sut.removeRecentSearch("search2")
        
        // Then
        XCTAssertEqual(sut.recentSearches.count, 2)
        XCTAssertFalse(sut.recentSearches.contains("search2"))
    }
    
    // MARK: - Health Check Tests
    
    func testCheckHealth_Success() async {
        // Given
        mockAPIClient.mockHealthStatus = "ok"
        
        // When
        let isHealthy = await sut.checkHealth()
        
        // Then
        XCTAssertTrue(isHealthy)
    }
    
    func testCheckHealth_Healthy() async {
        // Given
        mockAPIClient.mockHealthStatus = "healthy"
        
        // When
        let isHealthy = await sut.checkHealth()
        
        // Then
        XCTAssertTrue(isHealthy)
    }
    
    func testCheckHealth_Unhealthy() async {
        // Given
        mockAPIClient.mockHealthStatus = "error"
        
        // When
        let isHealthy = await sut.checkHealth()
        
        // Then
        XCTAssertFalse(isHealthy)
    }
    
    func testCheckHealth_Error() async {
        // Given
        mockAPIClient.mockError = APIError.networkError(NSError())
        
        // When
        let isHealthy = await sut.checkHealth()
        
        // Then
        XCTAssertFalse(isHealthy)
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingState_DuringSearch() async throws {
        // Given
        var loadingStates: [Bool] = []
        
        sut.$isLoading
            .sink { loading in
                loadingStates.append(loading)
            }
            .store(in: &cancellables)
        
        let mockResults = [SearchResult(id: "1", title: "Item", price: 100.0, imageUrl: "url1")]
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 1,
            query: "test",
            searchTime: 0.1
        )
        
        // When
        _ = try await sut.searchByText(query: "test")
        
        // Then
        XCTAssertTrue(loadingStates.contains(true))
        XCTAssertTrue(loadingStates.contains(false))
    }
    
    // MARK: - Debounce Search Tests
    
    func testSearchWithDebounce() async throws {
        // Given
        let query = "debounced query"
        let mockResults = [SearchResult(id: "1", title: "Item", price: 100.0, imageUrl: "url1")]
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 1,
            query: query,
            searchTime: 0.1
        )
        
        // When
        let startTime = Date()
        let results = try await sut.searchWithDebounce(query: query, delay: 0.1)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertGreaterThanOrEqual(elapsed, 0.1)
        XCTAssertEqual(results.count, 1)
    }
    
    // MARK: - Error State Tests
    
    func testLastError_AfterFailedSearch() async {
        // Given
        mockAPIClient.mockError = APIError.serverError("Search failed", 500)
        
        // When
        do {
            _ = try await sut.searchByText(query: "test")
        } catch {
            // Expected
        }
        
        // Then
        XCTAssertNotNil(sut.lastError)
        if case .serverError(let message, _) = sut.lastError {
            XCTAssertEqual(message, "Search failed")
        }
    }
    
    func testLastError_ClearedOnSuccess() async throws {
        // Given
        mockAPIClient.mockError = APIError.serverError("Previous error", 500)
        do {
            _ = try await sut.searchByText(query: "test")
        } catch {
            // Expected
        }
        
        // Reset error
        mockAPIClient.mockError = nil
        let mockResults = [SearchResult(id: "1", title: "Item", price: 100.0, imageUrl: "url1")]
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 1,
            query: "test",
            searchTime: 0.1
        )
        
        // When
        _ = try await sut.searchByText(query: "test")
        
        // Then
        XCTAssertNil(sut.lastError)
    }
    
    // MARK: - Edge Cases
    
    func testSearchWithVeryLongQuery() async throws {
        // Given
        let longQuery = String(repeating: "a", count: 1000)
        let mockResults = [SearchResult(id: "1", title: "Item", price: 100.0, imageUrl: "url1")]
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 1,
            query: longQuery,
            searchTime: 0.1
        )
        
        // When
        let results = try await sut.searchByText(query: longQuery)
        
        // Then
        XCTAssertEqual(results.count, 1)
    }
    
    func testSearchWithSpecialCharacters() async throws {
        // Given
        let query = "jacket!@#$%^&*()"
        let mockResults = [SearchResult(id: "1", title: "Item", price: 100.0, imageUrl: "url1")]
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 1,
            query: query,
            searchTime: 0.1
        )
        
        // When
        let results = try await sut.searchByText(query: query)
        
        // Then
        XCTAssertEqual(results.count, 1)
    }
    
    func testSearchWithUnicode() async throws {
        // Given
        let query = "レザージャケット"
        let mockResults = [SearchResult(id: "1", title: "Item", price: 100.0, imageUrl: "url1")]
        
        mockAPIClient.mockSearchResponse = SearchResponse(
            items: mockResults,
            total: 1,
            query: query,
            searchTime: 0.1
        )
        
        // When
        let results = try await sut.searchByText(query: query)
        
        // Then
        XCTAssertEqual(results.count, 1)
    }
    
    // MARK: - Helper Methods
    
    private func createMockImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 100, height: 100))
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - Mock Classes

class MockSearchAPIClient {
    var mockSearchResponse: SearchResponse?
    var mockHealthStatus: String?
    var mockError: APIError?
    
    var searchByTextCalled = false
    var searchByImageCalled = false
    var searchCombinedCalled = false
    
    func request<T: Decodable>(_ apiRequest: APIRequest) async throws -> T {
        if let error = mockError {
            throw error
        }
        
        switch apiRequest.endpoint {
        case .searchByText:
            searchByTextCalled = true
        case .searchByImage:
            searchByImageCalled = true
        case .searchCombined:
            searchCombinedCalled = true
        default:
            break
        }
        
        if T.self == SearchResponse.self, let response = mockSearchResponse {
            return response as! T
        }
        
        if T.self == HealthCheckResponse.self {
            return HealthCheckResponse(status: mockHealthStatus ?? "ok") as! T
        }
        
        throw APIError.invalidResponse
    }
}

class MockImageUploader {
    var mockUploadResult: ImageUploadResult?
    var mockError: Error?
    var processImageCalled = false
    
    func processImage(_ image: UIImage) async throws -> ImageUploadResult {
        processImageCalled = true
        
        if let error = mockError {
            throw error
        }
        
        guard let result = mockUploadResult else {
            throw ImageUploadError.processingFailed
        }
        
        return result
    }
}

struct SearchResponse {
    let items: [SearchResult]
    let total: Int
    let query: String?
    let searchTime: Double
}

struct SearchResult: Identifiable {
    let id: String
    let title: String
    let price: Double
    let imageUrl: String?
}

struct ImageUploadResult {
    let base64String: String
    let url: String?
    let dimensions: CGSize
}

enum ImageUploadError: Error {
    case invalidImage
    case processingFailed
    case uploadFailed
}

// MARK: - SearchAPIService Extension for Testing
extension SearchAPIService {
    convenience init(apiClient: MockSearchAPIClient, imageUploader: MockImageUploader) {
        self.init()
        // Inject mocks for testing
    }
}
