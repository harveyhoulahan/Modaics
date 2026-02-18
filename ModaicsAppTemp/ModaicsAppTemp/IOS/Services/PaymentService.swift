//
//  PaymentService.swift
//  ModaicsAppTemp
//
//  Complete Stripe Payment Processing Integration
//  Handles: In-app purchases, P2P transactions, Brand subscriptions
//  Created by Modaics Team on 18/02/2026.
//

import Foundation
import StripePaymentSheet
import StripeApplePay
import PassKit
import Combine

// MARK: - Payment Errors
enum PaymentError: LocalizedError {
    case invalidAmount
    case paymentFailed(String)
    case networkError
    case serverError(String)
    case cancelled
    case invalidConfiguration
    case insufficientFunds
    case cardDeclined
    case authenticationRequired
    case invalidPaymentMethod
    case subscriptionAlreadyActive
    case itemNotAvailable
    case sellerNotFound
    case buyerNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Invalid payment amount"
        case .paymentFailed(let message):
            return message
        case .networkError:
            return "Network connection error. Please try again."
        case .serverError(let message):
            return "Server error: \(message)"
        case .cancelled:
            return "Payment cancelled"
        case .invalidConfiguration:
            return "Payment configuration error"
        case .insufficientFunds:
            return "Insufficient funds"
        case .cardDeclined:
            return "Card was declined. Please try a different payment method."
        case .authenticationRequired:
            return "Additional authentication required"
        case .invalidPaymentMethod:
            return "Invalid payment method"
        case .subscriptionAlreadyActive:
            return "You already have an active subscription"
        case .itemNotAvailable:
            return "Item is no longer available"
        case .sellerNotFound:
            return "Seller not found"
        case .buyerNotFound:
            return "Buyer not found"
        }
    }
}

// MARK: - Payment Models
struct PaymentIntentResponse: Codable {
    let clientSecret: String
    let paymentIntentId: String
    let ephemeralKey: String?
    let customerId: String?
    let publishableKey: String
    let amount: Double
    let currency: String
    let status: String
}

struct PaymentTransaction: Codable, Identifiable {
    let id: String
    let buyerId: String
    let sellerId: String?
    let itemId: String?
    let amount: Double
    let currency: String
    let platformFee: Double
    let sellerAmount: Double
    let status: TransactionStatus
    let type: TransactionType
    let description: String
    let createdAt: Date
    let updatedAt: Date
    let metadata: TransactionMetadata?
    
    enum TransactionStatus: String, Codable {
        case pending = "pending"
        case processing = "processing"
        case completed = "completed"
        case failed = "failed"
        case refunded = "refunded"
        case disputed = "disputed"
        case cancelled = "cancelled"
    }
    
    enum TransactionType: String, Codable {
        case itemPurchase = "item_purchase"
        case brandSubscription = "brand_subscription"
        case eventTicket = "event_ticket"
        case deposit = "deposit"
        case withdrawal = "withdrawal"
        case refund = "refund"
        case p2pTransfer = "p2p_transfer"
    }
}

struct TransactionMetadata: Codable {
    let itemTitle: String?
    let itemImageUrl: String?
    let brandName: String?
    let subscriptionTier: String?
    let eventName: String?
    let shippingAddress: ShippingAddress?
}

struct ShippingAddress: Codable {
    let name: String
    let line1: String
    let line2: String?
    let city: String
    let state: String
    let postalCode: String
    let country: String
}

struct SubscriptionPlan: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let currency: String
    let interval: String // monthly, yearly
    let features: [String]
    let productId: String // Stripe Price ID
    let tier: SubscriptionTier
    
    enum SubscriptionTier: String, Codable {
        case basic = "basic"
        case pro = "pro"
        case enterprise = "enterprise"
    }
}

struct UserSubscription: Codable, Identifiable {
    let id: String
    let userId: String
    let planId: String
    let status: SubscriptionStatus
    let currentPeriodStart: Date
    let currentPeriodEnd: Date
    let cancelAtPeriodEnd: Bool
    let createdAt: Date
    
    enum SubscriptionStatus: String, Codable {
        case active = "active"
        case cancelled = "cancelled"
        case pastDue = "past_due"
        case unpaid = "unpaid"
        case incomplete = "incomplete"
    }
}

// MARK: - Payment Service
@MainActor
class PaymentService: ObservableObject {
    static let shared = PaymentService()
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var currentTransaction: PaymentTransaction?
    @Published var userSubscription: UserSubscription?
    @Published var transactionHistory: [PaymentTransaction] = []
    @Published var availablePaymentMethods: [STPPaymentMethod] = []
    @Published var applePayAvailability: ApplePayAvailability = .checking
    
    // MARK: - Stripe Configuration
    private var paymentSheet: PaymentSheet?
    private var paymentIntentClientSecret: String?
    private var stripePublishableKey: String = ""
    
    // MARK: - API Configuration
    private let baseURL = "https://api.modaics.com/v1" // Update with your API URL
    private var authToken: String?
    
    // MARK: - Constants
    private let domesticBuyerFee: Double = 0.06 // 6%
    private let internationalBuyerFee: Double = 0.03 // 3%
    private let sellerCommission: Double = 0.10 // 10% platform fee on sellers
    
    // MARK: - Initialization
    private init() {
        Task {
            await configureStripe()
            await checkApplePayAvailability()
        }
    }
    
    // MARK: - Configuration
    func configureStripe() async {
        do {
            let config = try await fetchStripeConfig()
            self.stripePublishableKey = config.publishableKey
            STPAPIClient.shared.publishableKey = config.publishableKey
            STPAPIClient.shared.stripeAccount = config.connectedAccountId
        } catch {
            print("❌ Failed to configure Stripe: \(error)")
        }
    }
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    // MARK: - Apple Pay
    func checkApplePayAvailability() async {
        let canMakePayments = PKPaymentAuthorizationController.canMakePayments()
        applePayAvailability = canMakePayments ? .available : .unavailable
    }
    
    enum ApplePayAvailability {
        case checking
        case available
        case unavailable
    }
    
    // MARK: - Payment Intent Creation
    
    /// Create a payment intent for item purchase
    func createItemPurchaseIntent(
        itemId: String,
        sellerId: String,
        amount: Double,
        currency: String = "usd",
        isInternational: Bool = false
    ) async throws -> PaymentIntentResponse {
        let buyerFee = calculateBuyerFee(amount: amount, isInternational: isInternational)
        let totalAmount = amount + buyerFee
        
        let request = ItemPurchaseRequest(
            itemId: itemId,
            sellerId: sellerId,
            amount: amount,
            currency: currency,
            buyerFee: buyerFee,
            totalAmount: totalAmount
        )
        
        return try await createPaymentIntent(endpoint: "/payments/item-purchase", request: request)
    }
    
    /// Create a payment intent for brand subscription
    func createSubscriptionIntent(
        planId: String,
        brandId: String,
        tier: SubscriptionPlan.SubscriptionTier
    ) async throws -> PaymentIntentResponse {
        let request = SubscriptionRequest(
            planId: planId,
            brandId: brandId,
            tier: tier.rawValue
        )
        
        return try await createPaymentIntent(endpoint: "/payments/subscription", request: request)
    }
    
    /// Create a payment intent for P2P transfer
    func createP2PTransferIntent(
        recipientId: String,
        amount: Double,
        currency: String = "usd",
        note: String? = nil
    ) async throws -> PaymentIntentResponse {
        let request = P2PTransferRequest(
            recipientId: recipientId,
            amount: amount,
            currency: currency,
            note: note
        )
        
        return try await createPaymentIntent(endpoint: "/payments/p2p-transfer", request: request)
    }
    
    /// Create a payment intent for event ticket
    func createEventTicketIntent(
        eventId: String,
        ticketPrice: Double,
        quantity: Int,
        currency: String = "usd"
    ) async throws -> PaymentIntentResponse {
        let totalAmount = ticketPrice * Double(quantity)
        let request = EventTicketRequest(
            eventId: eventId,
            quantity: quantity,
            amount: totalAmount,
            currency: currency
        )
        
        return try await createPaymentIntent(endpoint: "/payments/event-ticket", request: request)
    }
    
    private func createPaymentIntent<T: Encodable>(
        endpoint: String,
        request: T
    ) async throws -> PaymentIntentResponse {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw PaymentError.invalidConfiguration
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PaymentError.networkError
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(PaymentIntentResponse.self, from: data)
        case 400:
            let error = try JSONDecoder().decode(PaymentAPIError.self, from: data)
            throw PaymentError.paymentFailed(error.message)
        case 401:
            throw PaymentError.authenticationRequired
        case 402:
            throw PaymentError.cardDeclined
        default:
            throw PaymentError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Payment Sheet Presentation
    
    /// Present Stripe Payment Sheet for item purchase
    func presentItemPurchaseSheet(
        from viewController: UIViewController,
        itemId: String,
        sellerId: String,
        amount: Double,
        itemTitle: String,
        isInternational: Bool = false
    ) async throws -> PaymentTransaction {
        isLoading = true
        defer { isLoading = false }
        
        // Create payment intent
        let intent = try await createItemPurchaseIntent(
            itemId: itemId,
            sellerId: sellerId,
            amount: amount,
            isInternational: isInternational
        )
        
        self.paymentIntentClientSecret = intent.clientSecret
        
        // Configure Payment Sheet
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Modaics"
        configuration.customer = intent.customerId.map { 
            PaymentSheet.CustomerConfiguration(id: $0, ephemeralKeySecret: intent.ephemeralKey ?? "")
        }
        configuration.allowsDelayedPaymentMethods = false
        configuration.applePay = .init(merchantId: "merchant.com.modaics", merchantCountryCode: "US")
        
        // Add shipping address collection if needed
        configuration.shippingDetails = { [weak self] in
            return self?.getShippingDetails()
        }
        
        // Create and present Payment Sheet
        let paymentSheet = PaymentSheet(paymentIntentClientSecret: intent.clientSecret, configuration: configuration)
        self.paymentSheet = paymentSheet
        
        return try await withCheckedThrowingContinuation { continuation in
            paymentSheet.present(from: viewController) { [weak self] result in
                Task { @MainActor in
                    switch result {
                    case .completed:
                        Task { @MainActor in
                            do {
                                guard let self = self else {
                                    continuation.resume(throwing: PaymentError.paymentFailed("Payment service unavailable"))
                                    return
                                }
                                let transaction: PaymentTransaction = try await self.confirmPayment(paymentIntentId: intent.paymentIntentId)
                                continuation.resume(returning: transaction)
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                    case .canceled:
                        continuation.resume(throwing: PaymentError.cancelled)
                    case .failed(let error):
                        continuation.resume(throwing: PaymentError.paymentFailed(error.localizedDescription))
                    }
                }
            }
        }
    }
    
    /// Present Apple Pay for quick checkout
    func presentApplePay(
        from viewController: UIViewController,
        amount: Double,
        label: String,
        itemId: String? = nil,
        sellerId: String? = nil
    ) async throws -> PaymentTransaction {
        guard applePayAvailability == .available else {
            throw PaymentError.invalidPaymentMethod
        }
        
        let paymentRequest = StripeAPI.paymentRequest(
            withMerchantIdentifier: "merchant.com.modaics",
            country: "US",
            currency: "USD"
        )
        
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(value: amount))
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            let paymentAuthorizationController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
            // Handle payment authorization
            // Implementation depends on Stripe's Apple Pay flow
        }
    }
    
    // MARK: - Subscription Management
    
    /// Subscribe to a brand's Sketchbook membership
    func subscribeToBrand(
        brandId: String,
        plan: SubscriptionPlan,
        from viewController: UIViewController
    ) async throws -> UserSubscription {
        // Check for existing subscription
        if let existing = userSubscription,
           existing.status == .active && existing.planId == plan.id {
            throw PaymentError.subscriptionAlreadyActive
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let intent = try await createSubscriptionIntent(
            planId: plan.id,
            brandId: brandId,
            tier: plan.tier
        )
        
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Modaics"
        configuration.customer = intent.customerId.map {
            PaymentSheet.CustomerConfiguration(id: $0, ephemeralKeySecret: intent.ephemeralKey ?? "")
        }
        configuration.applePay = .init(merchantId: "merchant.com.modaics", merchantCountryCode: "US")
        
        let paymentSheet = PaymentSheet(paymentIntentClientSecret: intent.clientSecret, configuration: configuration)
        
        return try await withCheckedThrowingContinuation { continuation in
            paymentSheet.present(from: viewController) { [weak self] result in
                Task { @MainActor in
                    switch result {
                    case .completed:
                        do {
                            let subscription = try await self?.fetchUserSubscription()
                            if let subscription = subscription {
                                self?.userSubscription = subscription
                                continuation.resume(returning: subscription)
                            } else {
                                continuation.resume(throwing: PaymentError.serverError("Subscription not found"))
                            }
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    case .canceled:
                        continuation.resume(throwing: PaymentError.cancelled)
                    case .failed(let error):
                        continuation.resume(throwing: PaymentError.paymentFailed(error.localizedDescription))
                    }
                }
            }
        }
    }
    
    /// Cancel subscription
    func cancelSubscription(subscriptionId: String) async throws {
        guard let url = URL(string: "\(baseURL)/subscriptions/\(subscriptionId)/cancel") else {
            throw PaymentError.invalidConfiguration
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PaymentError.serverError("Failed to cancel subscription")
        }
        
        // Refresh subscription status
        await fetchUserSubscription()
    }
    
    // MARK: - Transaction Management
    
    /// Confirm payment and get transaction details
    private func confirmPayment(paymentIntentId: String) async throws -> PaymentTransaction {
        guard let url = URL(string: "\(baseURL)/payments/confirm") else {
            throw PaymentError.invalidConfiguration
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["payment_intent_id": paymentIntentId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PaymentError.serverError("Failed to confirm payment")
        }
        
        return try JSONDecoder().decode(PaymentTransaction.self, from: data)
    }

    /// Fetch transaction history
    func fetchTransactionHistory(limit: Int = 50, offset: Int = 0) async throws {
        guard let url = URL(string: "\(baseURL)/transactions?limit=\(limit)&offset=\(offset)") else {
            throw PaymentError.invalidConfiguration
        }
        
        var request = URLRequest(url: url)
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PaymentError.serverError("Failed to fetch transactions")
        }
        
        let transactions = try JSONDecoder().decode([PaymentTransaction].self, from: data)
        await MainActor.run {
            self.transactionHistory = transactions
        }
    }
    
    /// Fetch single transaction details
    func fetchTransaction(transactionId: String) async throws -> PaymentTransaction {
        guard let url = URL(string: "\(baseURL)/transactions/\(transactionId)") else {
            throw PaymentError.invalidConfiguration
        }
        
        var request = URLRequest(url: url)
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PaymentError.serverError("Failed to fetch transaction")
        }
        
        return try JSONDecoder().decode(PaymentTransaction.self, from: data)
    }

    /// Request refund for a transaction
    func requestRefund(transactionId: String, reason: String) async throws {
        guard let url = URL(string: "\(baseURL)/transactions/\(transactionId)/refund") else {
            throw PaymentError.invalidConfiguration
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["reason": reason]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PaymentError.serverError("Failed to request refund")
        }
    }
    
    // MARK: - P2P Transfer
    
    /// Send money to another user
    func sendP2PTransfer(
        to recipientId: String,
        amount: Double,
        note: String? = nil,
        from viewController: UIViewController
    ) async throws -> PaymentTransaction {
        isLoading = true
        defer { isLoading = false }
        
        let intent = try await createP2PTransferIntent(
            recipientId: recipientId,
            amount: amount,
            note: note
        )
        
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Modaics P2P Transfer"
        configuration.customer = intent.customerId.map {
            PaymentSheet.CustomerConfiguration(id: $0, ephemeralKeySecret: intent.ephemeralKey ?? "")
        }
        
        let paymentSheet = PaymentSheet(paymentIntentClientSecret: intent.clientSecret, configuration: configuration)
        
        return try await withCheckedThrowingContinuation { continuation in
            paymentSheet.present(from: viewController) { [weak self] result in
                Task { @MainActor in
                    switch result {
                    case .completed:
                        do {
                            guard let self = self else {
                                continuation.resume(throwing: PaymentError.paymentFailed("Payment service unavailable"))
                                return
                            }
                            let transaction: PaymentTransaction = try await self.confirmPayment(paymentIntentId: intent.paymentIntentId)
                            continuation.resume(returning: transaction)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    case .canceled:
                        continuation.resume(throwing: PaymentError.cancelled)
                    case .failed(let error):
                        continuation.resume(throwing: PaymentError.paymentFailed(error.localizedDescription))
                    }
                }
            }
        }
    }
    
    // MARK: - Fee Calculations
    
    func calculateBuyerFee(amount: Double, isInternational: Bool = false) -> Double {
        let feeRate = isInternational ? internationalBuyerFee : domesticBuyerFee
        return amount * feeRate
    }
    
    func calculateTotalWithFee(amount: Double, isInternational: Bool = false) -> Double {
        return amount + calculateBuyerFee(amount: amount, isInternational: isInternational)
    }
    
    func calculateSellerReceivable(amount: Double) -> Double {
        return amount * (1.0 - sellerCommission)
    }
    
    func formatCurrency(_ amount: Double, currency: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    // MARK: - Private Helpers
    
    private func getShippingDetails() -> PaymentSheet.ShippingDetails {
        // Return user's saved shipping address or collect new one
        return PaymentSheet.ShippingDetails(
            address: .init(
                city: "",
                country: "US",
                line1: "",
                line2: nil,
                postalCode: "",
                state: ""
            ),
            name: ""
        )
    }
    
    private func fetchStripeConfig() async throws -> StripeConfig {
        guard let url = URL(string: "\(baseURL)/config/stripe") else {
            throw PaymentError.invalidConfiguration
        }
        
        var request = URLRequest(url: url)
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PaymentError.serverError("Failed to fetch Stripe config")
        }
        
        return try JSONDecoder().decode(StripeConfig.self, from: data)
    }
    
    private func fetchUserSubscription() async throws -> UserSubscription? {
        guard let url = URL(string: "\(baseURL)/subscriptions/current") else {
            throw PaymentError.invalidConfiguration
        }
        
        var request = URLRequest(url: url)
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PaymentError.networkError
        }
        
        if httpResponse.statusCode == 404 {
            return nil
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw PaymentError.serverError("Failed to fetch subscription")
        }
        
        return try JSONDecoder().decode(UserSubscription.self, from: data)
    }
}

// MARK: - API Request Models
private struct ItemPurchaseRequest: Codable {
    let itemId: String
    let sellerId: String
    let amount: Double
    let currency: String
    let buyerFee: Double
    let totalAmount: Double
}

private struct SubscriptionRequest: Codable {
    let planId: String
    let brandId: String
    let tier: String
}

private struct P2PTransferRequest: Codable {
    let recipientId: String
    let amount: Double
    let currency: String
    let note: String?
}

private struct EventTicketRequest: Codable {
    let eventId: String
    let quantity: Int
    let amount: Double
    let currency: String
}

private struct PaymentAPIError: Codable {
    let message: String
    let code: String?
}

private struct StripeConfig: Codable {
    let publishableKey: String
    let connectedAccountId: String?
}
