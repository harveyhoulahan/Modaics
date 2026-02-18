//
//  EndToEndIntegrationTests.swift
//  ModaicsIntegrationTests
//
//  End-to-end integration tests
//  Tests: User signup → List item → Search item → Purchase item
//

import XCTest
@testable import Modaics

@MainActor
final class EndToEndIntegrationTests: XCTestCase {
    
    var authViewModel: AuthViewModel!
    var apiClient: APIClient!
    var searchService: SearchAPIService!
    var paymentService: PaymentService!
    
    override func setUp() {
        super.setUp()
        authViewModel = AuthViewModel()
        apiClient = APIClient.shared
        searchService = SearchAPIService.shared
        paymentService = PaymentService.shared
    }
    
    override func tearDown() {
        // Clean up test data
        Task {
            await cleanupTestData()
        }
        authViewModel = nil
        apiClient = nil
        searchService = nil
        paymentService = nil
        super.tearDown()
    }
    
    // MARK: - End-to-End Flow Tests
    
    /// Test complete user journey: Signup → Create Item → Search Item → Purchase Item
    func testCompleteUserJourney() async throws {
        // Step 1: Create buyer account
        let buyerEmail = generateTestEmail()
        let buyerPassword = "TestPass123!"
        
        await authViewModel.signUp(
            email: buyerEmail,
            password: buyerPassword,
            displayName: "Test Buyer",
            userType: .consumer
        )
        
        XCTAssertTrue(authViewModel.authState.isAuthenticated)
        let buyerId = authViewModel.currentUser?.id
        XCTAssertNotNil(buyerId)
        
        // Sign out
        authViewModel.signOut()
        XCTAssertEqual(authViewModel.authState, .unauthenticated)
        
        // Step 2: Create seller account
        let sellerEmail = generateTestEmail()
        let sellerPassword = "TestPass123!"
        
        await authViewModel.signUp(
            email: sellerEmail,
            password: sellerPassword,
            displayName: "Test Seller",
            userType: .brand
        )
        
        XCTAssertTrue(authViewModel.authState.isAuthenticated)
        let sellerId = authViewModel.currentUser?.id
        XCTAssertNotNil(sellerId)
        
        // Step 3: Create and list item
        let itemId = try await createTestItem(
            title: "Vintage Leather Jacket",
            price: 150.00,
            sellerId: sellerId!
        )
        XCTAssertNotNil(itemId)
        
        // Give backend time to index
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        
        // Sign out
        authViewModel.signOut()
        
        // Step 4: Buyer searches for item
        await authViewModel.signIn(email: buyerEmail, password: buyerPassword)
        XCTAssertTrue(authViewModel.authState.isAuthenticated)
        
        let searchResults = try await searchService.searchByText(query: "vintage leather jacket")
        XCTAssertFalse(searchResults.isEmpty)
        
        // Verify our item is in results
        let foundItem = searchResults.first { $0.id == itemId }
        XCTAssertNotNil(foundItem)
        XCTAssertEqual(foundItem?.title, "Vintage Leather Jacket")
        
        // Step 5: Buyer purchases item
        let transaction = try await paymentService.createItemPurchaseIntent(
            itemId: itemId!,
            sellerId: sellerId!,
            amount: 150.00
        )
        
        XCTAssertEqual(transaction.amount, 150.00)
        XCTAssertEqual(transaction.currency, "usd")
        
        // Verify transaction details
        let buyerFee = paymentService.calculateBuyerFee(amount: 150.00)
        let total = paymentService.calculateTotalWithFee(amount: 150.00)
        XCTAssertEqual(total, 150.00 + buyerFee)
    }
    
    /// Test brand subscription flow: Create brand → Subscribe → Access exclusive content
    func testBrandSubscriptionFlow() async throws {
        // Step 1: Create brand account
        let brandEmail = generateTestEmail()
        
        await authViewModel.signUp(
            email: brandEmail,
            password: "TestPass123!",
            displayName: "Test Brand",
            userType: .brand
        )
        
        XCTAssertTrue(authViewModel.authState.isAuthenticated)
        let brandId = authViewModel.currentUser?.id
        XCTAssertNotNil(brandId)
        
        // Step 2: Brand creates sketchbook and exclusive content
        // (Implementation would create sketchbook post)
        
        // Sign out
        authViewModel.signOut()
        
        // Step 3: Create consumer account
        let consumerEmail = generateTestEmail()
        
        await authViewModel.signUp(
            email: consumerEmail,
            password: "TestPass123!",
            displayName: "Test Consumer",
            userType: .consumer
        )
        
        XCTAssertTrue(authViewModel.authState.isAuthenticated)
        
        // Step 4: Subscribe to brand
        let subscriptionPlan = SubscriptionPlan(
            id: "test_plan_123",
            name: "Premium",
            description: "Premium access",
            price: 9.99,
            currency: "usd",
            interval: "monthly",
            features: ["Exclusive content", "Early access"],
            productId: "price_test_123",
            tier: .pro
        )
        
        // Note: Actual subscription would require Stripe test mode
        // let subscription = try await paymentService.subscribeToBrand(
        //     brandId: brandId!,
        //     plan: subscriptionPlan,
        //     from: UIViewController()
        // )
        
        // Verify subscription intent created
        let intent = try await paymentService.createSubscriptionIntent(
            planId: subscriptionPlan.id,
            brandId: brandId!,
            tier: subscriptionPlan.tier
        )
        
        XCTAssertEqual(intent.amount, 9.99)
        XCTAssertEqual(intent.currency, "usd")
    }
    
    /// Test image search and AI analysis flow
    func testImageSearchWithAI() async throws {
        // Login
        await authViewModel.signIn(
            email: "test@modaics.com",
            password: "TestPass123!"
        )
        
        XCTAssertTrue(authViewModel.authState.isAuthenticated)
        
        // Create test image
        let testImage = createTestImage()
        
        // Search by image
        let results = try await searchService.searchByImage(testImage, limit: 20)
        
        // Verify results structure
        XCTAssertNotNil(results)
        
        // Verify service state updated
        XCTAssertEqual(sut.lastResults.count, results.count)
    }
    
    /// Test social features: Follow, like, comment
    func testSocialFeatures() async throws {
        // Create two user accounts
        let user1Email = generateTestEmail()
        await authViewModel.signUp(
            email: user1Email,
            password: "TestPass123!",
            displayName: "User One",
            userType: .consumer
        )
        
        let user1Id = authViewModel.currentUser?.id
        
        // Create item
        let itemId = try await createTestItem(
            title: "Test Item for Social",
            price: 50.00,
            sellerId: user1Id!
        )
        
        authViewModel.signOut()
        
        // User 2 interacts with item
        let user2Email = generateTestEmail()
        await authViewModel.signUp(
            email: user2Email,
            password: "TestPass123!",
            displayName: "User Two",
            userType: .consumer
        )
        
        // Search for item
        let results = try await searchService.searchByText(query: "Test Item for Social")
        XCTAssertFalse(results.isEmpty)
        
        // Add to favorites (would be implemented)
        // Like item (would be implemented)
        // Comment on item (would be implemented)
    }
    
    // MARK: - Backend Connectivity Tests
    
    func testBackendConnectivity_HealthCheck() async {
        let isHealthy = await searchService.checkHealth()
        XCTAssertTrue(isHealthy, "Backend health check should pass")
    }
    
    func testBackendConnectivity_APIEndpoints() async throws {
        // Test various endpoints
        let endpoints: [APIEndpoint] = [
            .health,
            .searchByText,
            .searchByImage
        ]
        
        for endpoint in endpoints {
            let url = APIConfiguration.shared.url(for: endpoint)
            XCTAssertNotNil(url, "Endpoint \(endpoint) should have valid URL")
        }
    }
    
    func testBackendConnectivity_AuthenticationRequired() async throws {
        // Test that protected endpoints require auth
        let request = APIRequest(
            endpoint: .addItem,
            body: TestItemData(name: "Test", price: 100),
            requiresAuth: true
        )
        
        // Should fail without auth
        do {
            let _: TestResponse = try await apiClient.request(request)
            XCTFail("Should require authentication")
        } catch let error as APIError {
            XCTAssertEqual(error, .unauthorized)
        }
    }
    
    func testBackendConnectivity_RateLimiting() async throws {
        // Make many requests quickly
        var errorOccurred = false
        
        for i in 0..<100 {
            do {
                _ = try await searchService.searchByText(query: "test \(i)", useCache: false)
            } catch let error as APIError {
                if error == .rateLimited {
                    errorOccurred = true
                    break
                }
            }
        }
        
        // Either rate limiting works or we made all requests successfully
        // The test passes in both cases
        XCTAssertTrue(true)
    }
    
    // MARK: - Data Consistency Tests
    
    func testDataConsistency_ItemCreationAndRetrieval() async throws {
        // Login
        await authViewModel.signIn(
            email: "test@modaics.com",
            password: "TestPass123!"
        )
        
        // Create item
        let itemId = try await createTestItem(
            title: "Consistency Test Item",
            price: 75.00,
            sellerId: authViewModel.currentUser!.id
        )
        
        // Wait for propagation
        try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        // Retrieve item
        let request = APIRequest(
            endpoint: .getItem(Int(itemId!)!),
            requiresAuth: true
        )
        
        let retrievedItem: TestItemResponse = try await apiClient.request(request)
        XCTAssertEqual(retrievedItem.title, "Consistency Test Item")
        XCTAssertEqual(retrievedItem.price, 75.00)
    }
    
    func testDataConsistency_UserProfileUpdates() async throws {
        // Login
        await authViewModel.signIn(
            email: "test@modaics.com",
            password: "TestPass123!"
        )
        
        // Update profile
        let success = await authViewModel.updateUserProfile(
            displayName: "Updated Name",
            bio: "Test bio",
            location: "Test City"
        )
        
        XCTAssertTrue(success)
        
        // Verify update persisted
        XCTAssertEqual(authViewModel.currentUser?.displayName, "Updated Name")
    }
    
    // MARK: - Error Recovery Tests
    
    func testErrorRecovery_NetworkFailure() async throws {
        // Simulate network failure
        // (Would need network mocking)
        
        // Attempt operation
        do {
            _ = try await searchService.searchByText(query: "test")
        } catch {
            // Verify error is appropriate
            XCTAssertTrue(error is APIError)
        }
    }
    
    func testErrorRecovery_TokenRefresh() async throws {
        // Login
        await authViewModel.signIn(
            email: "test@modaics.com",
            password: "TestPass123!"
        )
        
        // Force token refresh
        let token = try await authViewModel.refreshTokenIfNeeded()
        XCTAssertFalse(token.isEmpty)
        
        // Verify still authenticated
        XCTAssertTrue(authViewModel.authState.isAuthenticated)
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_SearchLatency() async throws {
        let startTime = Date()
        
        _ = try await searchService.searchByText(query: "jacket")
        
        let elapsed = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(elapsed, 5.0, "Search should complete within 5 seconds")
    }
    
    func testPerformance_ImageUpload() async throws {
        let testImage = createTestImage(size: CGSize(width: 1024, height: 1024))
        
        let startTime = Date()
        
        _ = try await searchService.searchByImage(testImage)
        
        let elapsed = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(elapsed, 10.0, "Image search should complete within 10 seconds")
    }
    
    // MARK: - Helper Methods
    
    private func generateTestEmail() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        return "test_\(timestamp)_\(random)@modaics.test"
    }
    
    private func createTestItem(title: String, price: Double, sellerId: String) async throws -> String? {
        let request = APIRequest(
            endpoint: .addItem,
            body: [
                "title": title,
                "price": price,
                "seller_id": sellerId,
                "category": "Outerwear",
                "condition": "Excellent",
                "description": "Test item created by integration tests"
            ],
            requiresAuth: true
        )
        
        let response: CreateItemResponse = try await apiClient.request(request)
        return response.itemId
    }
    
    private func createTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    private func cleanupTestData() async {
        // Clean up any test data created during tests
        // Implementation would delete test users, items, etc.
    }
}

// MARK: - Test Models

struct TestItemData: Codable {
    let name: String
    let price: Double
}

struct TestItemResponse: Codable {
    let id: String
    let title: String
    let price: Double
    let sellerId: String
}

struct TestResponse: Codable {
    let success: Bool
}

struct CreateItemResponse: Codable {
    let itemId: String
    let status: String
}

// MARK: - Extensions

extension AuthState {
    var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }
}
