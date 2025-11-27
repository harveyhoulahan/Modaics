//
//  PaymentService.swift
//  ModaicsAppTemp
//
//  Handles payment processing and subscription management
//  Created by Harvey Houlahan on 26/11/2025.
//

import Foundation
import StoreKit

@MainActor
class PaymentService: ObservableObject {
    static let shared = PaymentService()
    
    @Published var isPremiumUser = false
    @Published var transactionInProgress = false
    
    // Product IDs (configured in App Store Connect)
    private let premiumMonthlyProductID = "com.modaics.premium.monthly"
    private let premiumYearlyProductID = "com.modaics.premium.yearly"
    
    // Brand subscription tiers
    private let brandBasicProductID = "com.modaics.brand.basic"
    private let brandProProductID = "com.modaics.brand.pro"
    private let brandEnterpriseProductID = "com.modaics.brand.enterprise"
    
    private init() {
        // Check existing subscription status on init
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    // MARK: - Subscription Management
    
    func checkSubscriptionStatus() async {
        // In production, this would check StoreKit 2 for active subscriptions
        // For now, we'll use UserDefaults for demo purposes
        isPremiumUser = UserDefaults.standard.bool(forKey: "isPremiumUser")
    }
    
    func purchasePremiumMonthly() async throws {
        transactionInProgress = true
        defer { transactionInProgress = false }
        
        // Simulate purchase flow
        // In production: Use StoreKit 2 to handle the actual purchase
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Update subscription status
        isPremiumUser = true
        UserDefaults.standard.set(true, forKey: "isPremiumUser")
        
        print("✅ Premium subscription activated")
    }
    
    func purchaseBrandTier(tier: BrandTier) async throws {
        transactionInProgress = true
        defer { transactionInProgress = false }
        
        let productID: String
        switch tier {
        case .basic:
            productID = brandBasicProductID
        case .pro:
            productID = brandProProductID
        case .enterprise:
            productID = brandEnterpriseProductID
        }
        
        // Simulate purchase
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        print("✅ Brand tier \(tier) subscription activated")
    }
    
    func cancelSubscription() async throws {
        // Direct users to subscription management in Settings
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            #if canImport(UIKit)
            await UIApplication.shared.open(url)
            #endif
        }
    }
    
    func restorePurchases() async throws {
        transactionInProgress = true
        defer { transactionInProgress = false }
        
        // In production: Use StoreKit 2 to restore purchases
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        await checkSubscriptionStatus()
        print("✅ Purchases restored")
    }
    
    // MARK: - Feature Access Checks
    
    func canAccessFeature(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .unlimitedListings, .arTryOn, .advancedAnalytics, .priorityAI, .doubleEcoPoints:
            return isPremiumUser
        case .basicListing:
            return true // Available to all users
        }
    }
    
    func hasReachedListingLimit(currentCount: Int) -> Bool {
        if isPremiumUser {
            return false // Unlimited
        }
        return currentCount >= 10 // Free users: 10 listings max
    }
    
    enum PremiumFeature {
        case basicListing
        case unlimitedListings
        case arTryOn
        case advancedAnalytics
        case priorityAI
        case doubleEcoPoints
    }
    
    enum BrandTier: String {
        case basic = "Basic"
        case pro = "Pro"
        case enterprise = "Enterprise"
        
        var monthlyPrice: Double {
            switch self {
            case .basic: return 0
            case .pro: return 50
            case .enterprise: return 200
            }
        }
        
        var features: [String] {
            switch self {
            case .basic:
                return [
                    "1 event per month",
                    "Community posts",
                    "Basic analytics"
                ]
            case .pro:
                return [
                    "5 events per month",
                    "Sustainability Badge application",
                    "Advanced analytics",
                    "Priority support"
                ]
            case .enterprise:
                return [
                    "Unlimited events",
                    "FibreTrace integration",
                    "Custom AI insights",
                    "Dedicated account manager",
                    "API access"
                ]
            }
        }
    }
}

// MARK: - Transaction Fee Calculator
class TransactionFeeService {
    static let shared = TransactionFeeService()
    
    // Fee percentages
    private let domesticBuyerFee: Double = 0.06 // 6%
    private let internationalBuyerFee: Double = 0.03 // 3%
    private let eventPlacementFee: Double = 50.0 // $50 flat fee
    private let ticketSalesCommission: Double = 0.10 // 10%
    
    private init() {}
    
    func calculateBuyerFee(itemPrice: Double, isInternational: Bool = false) -> Double {
        let feeRate = isInternational ? internationalBuyerFee : domesticBuyerFee
        return itemPrice * feeRate
    }
    
    func calculateTotalWithFee(itemPrice: Double, isInternational: Bool = false) -> Double {
        return itemPrice + calculateBuyerFee(itemPrice: itemPrice, isInternational: isInternational)
    }
    
    func calculateEventPlacementFee(isFeatured: Bool) -> Double {
        return isFeatured ? eventPlacementFee : 0
    }
    
    func calculateTicketCommission(ticketPrice: Double, ticketsSold: Int) -> Double {
        return ticketPrice * Double(ticketsSold) * ticketSalesCommission
    }
    
    func formatFee(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
}

// MARK: - Eco Points Service
class EcoPointsService {
    static let shared = EcoPointsService()
    
    private init() {}
    
    enum EcoAction {
        case itemSwapped
        case secondHandPurchase
        case eventAttendance
        case sustainabilityBadgeItem
        case challengeCompleted
        case referralBonus
        
        var basePoints: Int {
            switch self {
            case .itemSwapped: return 50
            case .secondHandPurchase: return 25
            case .eventAttendance: return 75
            case .sustainabilityBadgeItem: return 100
            case .challengeCompleted: return 150
            case .referralBonus: return 200
            }
        }
    }
    
    func awardPoints(for action: EcoAction, isPremium: Bool = false) -> Int {
        let points = action.basePoints
        return isPremium ? points * 2 : points // Premium users get 2x points
    }
    
    func calculateSustainabilityScore(ecoPoints: Int) -> Int {
        // Convert eco points to sustainability percentage (0-100)
        // Formula: Score = min(100, points / 50)
        return min(100, ecoPoints / 50)
    }
    
    func getLeaderboardRank(ecoPoints: Int, totalUsers: Int) -> String {
        let percentage = Double(ecoPoints) / Double(totalUsers)
        
        switch percentage {
        case 0.9...:
            return "Top 10% 🏆"
        case 0.75..<0.9:
            return "Top 25% 🥇"
        case 0.5..<0.75:
            return "Top 50% 🥈"
        default:
            return "Keep going! 💪"
        }
    }
    
    func canRedeemReward(ecoPoints: Int, rewardCost: Int) -> Bool {
        return ecoPoints >= rewardCost
    }
}
