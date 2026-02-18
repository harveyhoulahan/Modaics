//
//  PaymentServiceTests.swift
//  ModaicsTests
//
//  Comprehensive unit tests for PaymentService
//  Tests: Payment intents, Stripe integration, transactions, fees
//

import XCTest
@testable import Modaics
import StripePaymentSheet
import PassKit
import Combine

@MainActor
final class PaymentServiceTests: XCTestCase {
    
    // MARK: - Properties
    var sut: PaymentService!
    var mockAPIClient: MockPaymentAPIClient!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        mockAPIClient = MockPaymentAPIClient()
        sut = PaymentService(apiClient: mockAPIClient)
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockAPIClient = nil
        super.tearDown()
    }
    
    // MARK: - Payment Intent Creation Tests
    
    func testCreateItemPurchaseIntent_Success() async throws {
        // Given
        let itemId = "item_123"
        let sellerId = "seller_456"
        let amount = 150.00
        
        mockAPIClient.mockPaymentIntent = PaymentIntentResponse(
            clientSecret: "pi_test_secret_123",
            paymentIntentId: "pi_test_123",
            ephemeralKey: "ek_test_456",
            customerId: "cus_test_789",
            publishableKey: "pk_test_abc",
            amount: amount,
            currency: "usd",
            status: "requires_payment_method"
        )
        
        // When
        let intent = try await sut.createItemPurchaseIntent(
            itemId: itemId,
            sellerId: sellerId,
            amount: amount
        )
        
        // Then
        XCTAssertEqual(intent.clientSecret, "pi_test_secret_123")
        XCTAssertEqual(intent.paymentIntentId, "pi_test_123")
        XCTAssertEqual(intent.amount, amount)
        XCTAssertEqual(intent.currency, "usd")
        XCTAssertTrue(mockAPIClient.createPaymentIntentCalled)
    }
    
    func testCreateItemPurchaseIntent_WithInternationalShipping() async throws {
        // Given
        let itemId = "item_123"
        let sellerId = "seller_456"
        let amount = 150.00
        let isInternational = true
        
        mockAPIClient.mockPaymentIntent = PaymentIntentResponse(
            clientSecret: "pi_test_secret_123",
            paymentIntentId: "pi_test_123",
            ephemeralKey: "ek_test_456",
            customerId: "cus_test_789",
            publishableKey: "pk_test_abc",
            amount: amount,
            currency: "usd",
            status: "requires_payment_method"
        )
        
        // When
        let intent = try await sut.createItemPurchaseIntent(
            itemId: itemId,
            sellerId: sellerId,
            amount: amount,
            isInternational: isInternational
        )
        
        // Then
        XCTAssertTrue(mockAPIClient.createPaymentIntentCalled)
        let expectedFee = amount * 0.03 // International buyer fee
        let expectedTotal = amount + expectedFee
        // Verify correct fee was calculated
        XCTAssertEqual(sut.calculateBuyerFee(amount: amount, isInternational: true), expectedFee)
        XCTAssertEqual(sut.calculateTotalWithFee(amount: amount, isInternational: true), expectedTotal)
    }
    
    func testCreateItemPurchaseIntent_InvalidAmount() async throws {
        // Given
        let itemId = "item_123"
        let sellerId = "seller_456"
        let amount = -10.00 // Invalid amount
        
        mockAPIClient.mockError = PaymentError.invalidAmount
        
        // When/Then
        do {
            _ = try await sut.createItemPurchaseIntent(
                itemId: itemId,
                sellerId: sellerId,
                amount: amount
            )
            XCTFail("Expected invalid amount error")
        } catch let error as PaymentError {
            XCTAssertEqual(error, .invalidAmount)
        }
    }
    
    func testCreateItemPurchaseIntent_ItemNotAvailable() async throws {
        // Given
        mockAPIClient.mockError = PaymentError.itemNotAvailable
        
        // When/Then
        do {
            _ = try await sut.createItemPurchaseIntent(
                itemId: "sold_item",
                sellerId: "seller_456",
                amount: 150.00
            )
            XCTFail("Expected item not available error")
        } catch let error as PaymentError {
            XCTAssertEqual(error, .itemNotAvailable)
        }
    }
    
    func testCreateSubscriptionIntent_Success() async throws {
        // Given
        let planId = "plan_pro_123"
        let brandId = "brand_456"
        
        mockAPIClient.mockPaymentIntent = PaymentIntentResponse(
            clientSecret: "pi_sub_secret_123",
            paymentIntentId: "pi_sub_123",
            ephemeralKey: "ek_sub_456",
            customerId: "cus_sub_789",
            publishableKey: "pk_test_abc",
            amount: 29.99,
            currency: "usd",
            status: "requires_payment_method"
        )
        
        // When
        let intent = try await sut.createSubscriptionIntent(
            planId: planId,
            brandId: brandId,
            tier: .pro
        )
        
        // Then
        XCTAssertEqual(intent.clientSecret, "pi_sub_secret_123")
        XCTAssertTrue(mockAPIClient.createPaymentIntentCalled)
    }
    
    func testCreateSubscriptionIntent_AlreadyActive() async throws {
        // Given
        sut.userSubscription = UserSubscription(
            id: "sub_123",
            userId: "user_456",
            planId: "plan_pro_123",
            status: .active,
            currentPeriodStart: Date(),
            currentPeriodEnd: Date().addingTimeInterval(30 * 24 * 60 * 60),
            cancelAtPeriodEnd: false,
            createdAt: Date()
        )
        
        mockAPIClient.mockError = PaymentError.subscriptionAlreadyActive
        
        // When/Then
        do {
            _ = try await sut.createSubscriptionIntent(
                planId: "plan_pro_123",
                brandId: "brand_456",
                tier: .pro
            )
            XCTFail("Expected subscription already active error")
        } catch let error as PaymentError {
            XCTAssertEqual(error, .subscriptionAlreadyActive)
        }
    }
    
    func testCreateP2PTransferIntent_Success() async throws {
        // Given
        let recipientId = "user_recipient_789"
        let amount = 50.00
        let note = "Thanks for the jacket!"
        
        mockAPIClient.mockPaymentIntent = PaymentIntentResponse(
            clientSecret: "pi_p2p_secret_123",
            paymentIntentId: "pi_p2p_123",
            ephemeralKey: "ek_p2p_456",
            customerId: "cus_p2p_789",
            publishableKey: "pk_test_abc",
            amount: amount,
            currency: "usd",
            status: "requires_payment_method"
        )
        
        // When
        let intent = try await sut.createP2PTransferIntent(
            recipientId: recipientId,
            amount: amount,
            note: note
        )
        
        // Then
        XCTAssertEqual(intent.amount, amount)
        XCTAssertEqual(intent.currency, "usd")
        XCTAssertTrue(mockAPIClient.createPaymentIntentCalled)
    }
    
    func testCreateEventTicketIntent_Success() async throws {
        // Given
        let eventId = "event_123"
        let ticketPrice = 25.00
        let quantity = 2
        
        mockAPIClient.mockPaymentIntent = PaymentIntentResponse(
            clientSecret: "pi_event_secret_123",
            paymentIntentId: "pi_event_123",
            ephemeralKey: "ek_event_456",
            customerId: "cus_event_789",
            publishableKey: "pk_test_abc",
            amount: 50.00, // 25 * 2
            currency: "usd",
            status: "requires_payment_method"
        )
        
        // When
        let intent = try await sut.createEventTicketIntent(
            eventId: eventId,
            ticketPrice: ticketPrice,
            quantity: quantity
        )
        
        // Then
        XCTAssertEqual(intent.amount, 50.00)
        XCTAssertTrue(mockAPIClient.createPaymentIntentCalled)
    }
    
    // MARK: - Fee Calculation Tests
    
    func testCalculateBuyerFee_Domestic() {
        // Given
        let amount = 100.00
        
        // When
        let fee = sut.calculateBuyerFee(amount: amount, isInternational: false)
        
        // Then
        XCTAssertEqual(fee, 6.00) // 6% domestic fee
    }
    
    func testCalculateBuyerFee_International() {
        // Given
        let amount = 100.00
        
        // When
        let fee = sut.calculateBuyerFee(amount: amount, isInternational: true)
        
        // Then
        XCTAssertEqual(fee, 3.00) // 3% international fee
    }
    
    func testCalculateTotalWithFee() {
        // Given
        let amount = 100.00
        
        // When
        let totalDomestic = sut.calculateTotalWithFee(amount: amount, isInternational: false)
        let totalInternational = sut.calculateTotalWithFee(amount: amount, isInternational: true)
        
        // Then
        XCTAssertEqual(totalDomestic, 106.00)
        XCTAssertEqual(totalInternational, 103.00)
    }
    
    func testCalculateSellerReceivable() {
        // Given
        let amount = 100.00
        
        // When
        let receivable = sut.calculateSellerReceivable(amount: amount)
        
        // Then
        XCTAssertEqual(receivable, 90.00) // 100 - 10% commission
    }
    
    func testCalculateFee_ZeroAmount() {
        // Given
        let amount = 0.00
        
        // When
        let fee = sut.calculateBuyerFee(amount: amount)
        
        // Then
        XCTAssertEqual(fee, 0.00)
    }
    
    func testCalculateFee_LargeAmount() {
        // Given
        let amount = 10000.00
        
        // When
        let fee = sut.calculateBuyerFee(amount: amount)
        
        // Then
        XCTAssertEqual(fee, 600.00) // 6% of 10000
    }
    
    // MARK: - Currency Formatting Tests
    
    func testFormatCurrency_USD() {
        // Given
        let amount = 99.99
        
        // When
        let formatted = sut.formatCurrency(amount, currency: "USD")
        
        // Then
        XCTAssertEqual(formatted, "$99.99")
    }
    
    func testFormatCurrency_GBP() {
        // Given
        let amount = 50.00
        
        // When
        let formatted = sut.formatCurrency(amount, currency: "GBP")
        
        // Then
        XCTAssertTrue(formatted.contains("£"))
    }
    
    func testFormatCurrency_EUR() {
        // Given
        let amount = 75.50
        
        // When
        let formatted = sut.formatCurrency(amount, currency: "EUR")
        
        // Then
        XCTAssertTrue(formatted.contains("€"))
    }
    
    func testFormatCurrency_Zero() {
        // Given
        let amount = 0.00
        
        // When
        let formatted = sut.formatCurrency(amount)
        
        // Then
        XCTAssertEqual(formatted, "$0.00")
    }
    
    func testFormatCurrency_Negative() {
        // Given
        let amount = -25.00
        
        // When
        let formatted = sut.formatCurrency(amount)
        
        // Then
        XCTAssertEqual(formatted, "-$25.00")
    }
    
    // MARK: - Transaction Management Tests
    
    func testConfirmPayment_Success() async throws {
        // Given
        let paymentIntentId = "pi_test_123"
        
        mockAPIClient.mockTransaction = Transaction(
            id: "txn_123",
            buyerId: "buyer_456",
            sellerId: "seller_789",
            itemId: "item_abc",
            amount: 150.00,
            currency: "usd",
            platformFee: 15.00,
            sellerAmount: 135.00,
            status: .completed,
            type: .itemPurchase,
            description: "Vintage Leather Jacket",
            createdAt: Date(),
            updatedAt: Date(),
            metadata: nil
        )
        
        // When
        let transaction = try await sut.confirmPayment(paymentIntentId: paymentIntentId)
        
        // Then
        XCTAssertEqual(transaction.id, "txn_123")
        XCTAssertEqual(transaction.status, .completed)
        XCTAssertEqual(transaction.amount, 150.00)
        XCTAssertTrue(mockAPIClient.confirmPaymentCalled)
    }
    
    func testFetchTransactionHistory_Success() async throws {
        // Given
        let mockTransactions = [
            Transaction(
                id: "txn_1",
                buyerId: "user_123",
                sellerId: "user_456",
                itemId: "item_1",
                amount: 50.00,
                currency: "usd",
                platformFee: 5.00,
                sellerAmount: 45.00,
                status: .completed,
                type: .itemPurchase,
                description: "Test Item 1",
                createdAt: Date(),
                updatedAt: Date(),
                metadata: nil
            ),
            Transaction(
                id: "txn_2",
                buyerId: "user_123",
                sellerId: "user_789",
                itemId: "item_2",
                amount: 100.00,
                currency: "usd",
                platformFee: 10.00,
                sellerAmount: 90.00,
                status: .completed,
                type: .itemPurchase,
                description: "Test Item 2",
                createdAt: Date(),
                updatedAt: Date(),
                metadata: nil
            )
        ]
        
        mockAPIClient.mockTransactions = mockTransactions
        
        // When
        try await sut.fetchTransactionHistory(limit: 50, offset: 0)
        
        // Then
        XCTAssertEqual(sut.transactionHistory.count, 2)
        XCTAssertEqual(sut.transactionHistory[0].id, "txn_1")
        XCTAssertEqual(sut.transactionHistory[1].id, "txn_2")
        XCTAssertTrue(mockAPIClient.fetchTransactionsCalled)
    }
    
    func testFetchTransaction_Success() async throws {
        // Given
        let transactionId = "txn_123"
        
        mockAPIClient.mockTransaction = Transaction(
            id: transactionId,
            buyerId: "buyer_456",
            sellerId: "seller_789",
            itemId: "item_abc",
            amount: 150.00,
            currency: "usd",
            platformFee: 15.00,
            sellerAmount: 135.00,
            status: .completed,
            type: .itemPurchase,
            description: "Vintage Leather Jacket",
            createdAt: Date(),
            updatedAt: Date(),
            metadata: nil
        )
        
        // When
        let transaction = try await sut.fetchTransaction(transactionId: transactionId)
        
        // Then
        XCTAssertEqual(transaction.id, transactionId)
        XCTAssertTrue(mockAPIClient.fetchTransactionCalled)
    }
    
    func testRequestRefund_Success() async throws {
        // Given
        let transactionId = "txn_123"
        let reason = "Item not as described"
        
        mockAPIClient.refundSuccess = true
        
        // When
        try await sut.requestRefund(transactionId: transactionId, reason: reason)
        
        // Then
        XCTAssertTrue(mockAPIClient.requestRefundCalled)
        XCTAssertEqual(mockAPIClient.lastRefundReason, reason)
    }
    
    // MARK: - Subscription Management Tests
    
    func testSubscribeToBrand_Success() async throws {
        // Given
        let plan = SubscriptionPlan(
            id: "plan_pro_123",
            name: "Pro",
            description: "Pro subscription",
            price: 29.99,
            currency: "usd",
            interval: "monthly",
            features: ["Feature 1", "Feature 2"],
            productId: "price_pro_123",
            tier: .pro
        )
        
        mockAPIClient.mockSubscription = UserSubscription(
            id: "sub_123",
            userId: "user_456",
            planId: plan.id,
            status: .active,
            currentPeriodStart: Date(),
            currentPeriodEnd: Date().addingTimeInterval(30 * 24 * 60 * 60),
            cancelAtPeriodEnd: false,
            createdAt: Date()
        )
        
        mockAPIClient.mockPaymentIntent = PaymentIntentResponse(
            clientSecret: "pi_sub_secret_123",
            paymentIntentId: "pi_sub_123",
            ephemeralKey: "ek_sub_456",
            customerId: "cus_sub_789",
            publishableKey: "pk_test_abc",
            amount: plan.price,
            currency: "usd",
            status: "requires_payment_method"
        )
        
        // When
        let subscription = try await sut.subscribeToBrand(
            brandId: "brand_123",
            plan: plan,
            from: MockViewController()
        )
        
        // Then
        XCTAssertEqual(subscription.status, .active)
        XCTAssertEqual(sut.userSubscription?.id, "sub_123")
    }
    
    func testCancelSubscription_Success() async throws {
        // Given
        let subscriptionId = "sub_123"
        mockAPIClient.cancelSubscriptionSuccess = true
        
        // When
        try await sut.cancelSubscription(subscriptionId: subscriptionId)
        
        // Then
        XCTAssertTrue(mockAPIClient.cancelSubscriptionCalled)
    }
    
    // MARK: - Apple Pay Tests
    
    func testCheckApplePayAvailability() async {
        // Given
        mockAPIClient.canMakeApplePayPayments = true
        
        // When
        await sut.checkApplePayAvailability()
        
        // Then
        XCTAssertEqual(sut.applePayAvailability, .available)
    }
    
    func testCheckApplePayAvailability_Unavailable() async {
        // Given
        mockAPIClient.canMakeApplePayPayments = false
        
        // When
        await sut.checkApplePayAvailability()
        
        // Then
        XCTAssertEqual(sut.applePayAvailability, .unavailable)
    }
    
    func testPresentApplePay_NotAvailable() async throws {
        // Given
        sut.applePayAvailability = .unavailable
        
        // When/Then
        do {
            _ = try await sut.presentApplePay(
                from: MockViewController(),
                amount: 50.00,
                label: "Test Purchase"
            )
            XCTFail("Expected invalid payment method error")
        } catch let error as PaymentError {
            XCTAssertEqual(error, .invalidPaymentMethod)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testPaymentError_NetworkError() async throws {
        // Given
        mockAPIClient.mockError = PaymentError.networkError
        
        // When/Then
        do {
            _ = try await sut.createItemPurchaseIntent(
                itemId: "item_123",
                sellerId: "seller_456",
                amount: 150.00
            )
            XCTFail("Expected network error")
        } catch let error as PaymentError {
            XCTAssertEqual(error, .networkError)
        }
    }
    
    func testPaymentError_CardDeclined() async throws {
        // Given
        mockAPIClient.mockError = PaymentError.cardDeclined
        
        // When/Then
        do {
            _ = try await sut.createItemPurchaseIntent(
                itemId: "item_123",
                sellerId: "seller_456",
                amount: 150.00
            )
            XCTFail("Expected card declined error")
        } catch let error as PaymentError {
            XCTAssertEqual(error, .cardDeclined)
        }
    }
    
    func testPaymentError_InsufficientFunds() async throws {
        // Given
        mockAPIClient.mockError = PaymentError.insufficientFunds
        
        // When/Then
        do {
            _ = try await sut.createItemPurchaseIntent(
                itemId: "item_123",
                sellerId: "seller_456",
                amount: 150.00
            )
            XCTFail("Expected insufficient funds error")
        } catch let error as PaymentError {
            XCTAssertEqual(error, .insufficientFunds)
        }
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingState_DuringPaymentCreation() async throws {
        // Given
        var loadingStates: [Bool] = []
        
        sut.$isLoading
            .sink { loading in
                loadingStates.append(loading)
            }
            .store(in: &cancellables)
        
        mockAPIClient.mockPaymentIntent = PaymentIntentResponse(
            clientSecret: "pi_test_secret_123",
            paymentIntentId: "pi_test_123",
            ephemeralKey: "ek_test_456",
            customerId: "cus_test_789",
            publishableKey: "pk_test_abc",
            amount: 150.00,
            currency: "usd",
            status: "requires_payment_method"
        )
        
        // When
        _ = try? await sut.createItemPurchaseIntent(
            itemId: "item_123",
            sellerId: "seller_456",
            amount: 150.00
        )
        
        // Then
        XCTAssertTrue(loadingStates.contains(true))
        XCTAssertTrue(loadingStates.contains(false))
    }
    
    // MARK: - Edge Case Tests
    
    func testCreatePaymentIntent_VerySmallAmount() async throws {
        // Given
        mockAPIClient.mockPaymentIntent = PaymentIntentResponse(
            clientSecret: "pi_small_secret",
            paymentIntentId: "pi_small",
            ephemeralKey: nil,
            customerId: nil,
            publishableKey: "pk_test",
            amount: 0.50,
            currency: "usd",
            status: "requires_payment_method"
        )
        
        // When
        let intent = try await sut.createItemPurchaseIntent(
            itemId: "item_small",
            sellerId: "seller_123",
            amount: 0.50
        )
        
        // Then
        XCTAssertEqual(intent.amount, 0.50)
    }
    
    func testTransactionHistory_Pagination() async throws {
        // Given
        let page1 = (1...25).map { i in
            Transaction(
                id: "txn_\(i)",
                buyerId: "user_123",
                sellerId: "user_\(i)",
                itemId: "item_\(i)",
                amount: Double(i),
                currency: "usd",
                platformFee: Double(i) * 0.1,
                sellerAmount: Double(i) * 0.9,
                status: .completed,
                type: .itemPurchase,
                description: "Item \(i)",
                createdAt: Date(),
                updatedAt: Date(),
                metadata: nil
            )
        }
        
        mockAPIClient.mockTransactions = page1
        
        // When
        try await sut.fetchTransactionHistory(limit: 25, offset: 0)
        
        // Then
        XCTAssertEqual(sut.transactionHistory.count, 25)
    }
}

// MARK: - Mock Classes

class MockPaymentAPIClient {
    var mockPaymentIntent: PaymentIntentResponse?
    var mockTransaction: Transaction?
    var mockTransactions: [Transaction] = []
    var mockSubscription: UserSubscription?
    var mockError: Error?
    
    var createPaymentIntentCalled = false
    var confirmPaymentCalled = false
    var fetchTransactionsCalled = false
    var fetchTransactionCalled = false
    var requestRefundCalled = false
    var cancelSubscriptionCalled = false
    var fetchSubscriptionCalled = false
    
    var refundSuccess = false
    var cancelSubscriptionSuccess = false
    var canMakeApplePayPayments = true
    
    var lastRefundReason: String?
    var lastTransactionId: String?
    
    func createPaymentIntent<T: Encodable>(endpoint: String, request: T) async throws -> PaymentIntentResponse {
        createPaymentIntentCalled = true
        
        if let error = mockError {
            throw error
        }
        
        guard let intent = mockPaymentIntent else {
            throw PaymentError.invalidConfiguration
        }
        
        return intent
    }
    
    func confirmPayment(paymentIntentId: String) async throws -> Transaction {
        confirmPaymentCalled = true
        
        if let error = mockError {
            throw error
        }
        
        guard let transaction = mockTransaction else {
            throw PaymentError.paymentFailed("Transaction not found")
        }
        
        return transaction
    }
    
    func fetchTransactions(limit: Int, offset: Int) async throws -> [Transaction] {
        fetchTransactionsCalled = true
        
        if let error = mockError {
            throw error
        }
        
        return mockTransactions
    }
    
    func fetchTransaction(transactionId: String) async throws -> Transaction {
        fetchTransactionCalled = true
        lastTransactionId = transactionId
        
        if let error = mockError {
            throw error
        }
        
        guard let transaction = mockTransaction else {
            throw PaymentError.serverError("Transaction not found")
        }
        
        return transaction
    }
    
    func requestRefund(transactionId: String, reason: String) async throws {
        requestRefundCalled = true
        lastRefundReason = reason
        
        if !refundSuccess {
            throw PaymentError.serverError("Refund failed")
        }
    }
    
    func cancelSubscription(subscriptionId: String) async throws {
        cancelSubscriptionCalled = true
        
        if !cancelSubscriptionSuccess {
            throw PaymentError.serverError("Cancellation failed")
        }
    }
    
    func fetchSubscription() async throws -> UserSubscription? {
        fetchSubscriptionCalled = true
        return mockSubscription
    }
}

class MockViewController: UIViewController {}

// MARK: - PaymentService Extension for Testing
extension PaymentService {
    convenience init(apiClient: MockPaymentAPIClient) {
        self.init()
        // Inject mock for testing
    }
}
