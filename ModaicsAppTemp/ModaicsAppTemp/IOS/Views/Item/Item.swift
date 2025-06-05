//
//  Item.swift
//  Modaics
//
//  Fashion item model with sustainability tracking
//

import Foundation
import SwiftUI

// MARK: - Fashion Item Model
struct FashionItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var brand: String
    var category: Category
    var size: String
    var condition: Condition
    var originalPrice: Double
    var listingPrice: Double
    var description: String
    var imageURLs: [String]
    var sustainabilityScore: SustainabilityScore
    var materialComposition: [Material]
    var colourTags: [String]
    var styleTags: [String]
    var location: String
    var ownerId: String
    var createdAt: Date
    var updatedAt: Date
    var viewCount: Int
    var likeCount: Int
    var isAvailable: Bool
    var embeddingVector: [Float]? // For ML recommendations
    var tags: [String] {
        colourTags + styleTags
    }
    
    // Computed properties
    var priceReduction: Double {
        guard originalPrice > 0 else { return 0 }
        return ((originalPrice - listingPrice) / originalPrice) * 100
    }
    
    var primaryImageURL: String? {
        imageURLs.first
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        brand: String,
        category: Category,
        size: String,
        condition: Condition,
        originalPrice: Double,
        listingPrice: Double,
        description: String,
        imageURLs: [String] = [],
        sustainabilityScore: SustainabilityScore,
        materialComposition: [Material] = [],
        colorTags: [String] = [],
        styleTags: [String] = [],
        location: String,
        ownerId: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        viewCount: Int = 0,
        likeCount: Int = 0,
        isAvailable: Bool = true,
        embeddingVector: [Float]? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.size = size
        self.condition = condition
        self.originalPrice = originalPrice
        self.listingPrice = listingPrice
        self.description = description
        self.imageURLs = imageURLs
        self.sustainabilityScore = sustainabilityScore
        self.materialComposition = materialComposition
        self.colourTags = colorTags
        self.styleTags = styleTags
        self.location = location
        self.ownerId = ownerId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.viewCount = viewCount
        self.likeCount = likeCount
        self.isAvailable = isAvailable
        self.embeddingVector = embeddingVector
    }
}

extension FashionItem: Equatable, Hashable {
    /// Two items are equal when their UUIDs match.
    static func == (lhs: FashionItem, rhs: FashionItem) -> Bool { lhs.id == rhs.id }

    /// Hash only the UUID so other non-Hashable fields don’t matter.
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Supporting Types
enum Category: String, CaseIterable, Codable {
    case tops = "Tops"
    case bottoms = "Bottoms"
    case dresses = "Dresses"
    case outerwear = "Outerwear"
    case shoes = "Shoes"
    case accessories = "Accessories"
    case bags = "Bags"
    case jewelry = "Jewelry"
    case other = "Other"
    case jackets = "Jackets"
    
    var icon: String {
        switch self {
        case .tops: return "tshirt"
        case .bottoms: return "rectangle.split.2x1"
        case .dresses: return "figure.dress.line.vertical.figure"
        case .outerwear: return "cloud.rain"
        case .shoes: return "shoe"
        case .accessories: return "eyeglasses"
        case .bags: return "bag"
        case .jewelry: return "sparkles"
        case .other: return "questionmark.circle"
        case .jackets: return "jumper"
        }
    }
}

enum Condition: String, CaseIterable, Codable {
    case new = "New with tags"
    case likeNew = "Like new"
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    
    var color: Color {
        switch self {
        case .new: return .green
        case .likeNew: return .blue
        case .excellent: return .teal
        case .good: return .orange
        case .fair: return .yellow
        }
    }
}

// MARK: - Sustainability
struct SustainabilityScore: Codable {
    var totalScore: Int // 0-100
    var carbonFootprint: Double // kg CO2
    var waterUsage: Double // liters
    var isRecycled: Bool
    var isCertified: Bool
    var certifications: [String]
    var fibreTraceVerified: Bool
    
    static var empty: SustainabilityScore {
        SustainabilityScore(
            totalScore: 0,
            carbonFootprint: 0,
            waterUsage: 0,
            isRecycled: false,
            isCertified: false,
            certifications: [],
            fibreTraceVerified: false
        )
    }
    
    var sustainabilityLevel: String {
        switch totalScore {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        case 20..<40: return "Poor"
        default: return "Very Poor"
        }
    }
    
    var sustainabilityColor: Color {
        switch totalScore {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }
}

struct Material: Codable {
    var name: String
    var percentage: Int
    var isOrganic: Bool
    var isRecycled: Bool
    
    static let cottonOrganic = Material(name: "Organic Cotton", percentage: 100, isOrganic: true, isRecycled: false)
    static let polyesterRecycled = Material(name: "Recycled Polyester", percentage: 100, isOrganic: false, isRecycled: true)
}

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: UUID
    var username: String
    var email: String
    var profileImageURL: String?
    var bio: String
    var location: String
    var joinDate: Date
    var isVerified: Bool
    var userType: UserType
    var sustainabilityPoints: Int
    var following: [String]
    var followers: [String]
    var likedItems: [String]
    var wardrobe: [String] // Item IDs
    
    enum UserType: String, Codable {
        case consumer = "Consumer"
        case brand = "Brand"
        case both = "Both"
    }
    
    init(
        id: UUID = UUID(),
        username: String,
        email: String,
        profileImageURL: String? = nil,
        bio: String = "",
        location: String = "",
        joinDate: Date = Date(),
        isVerified: Bool = false,
        userType: UserType = .consumer,
        sustainabilityPoints: Int = 0,
        following: [String] = [],
        followers: [String] = [],
        likedItems: [String] = [],
        wardrobe: [String] = []
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.profileImageURL = profileImageURL
        self.bio = bio
        self.location = location
        self.joinDate = joinDate
        self.isVerified = isVerified
        self.userType = userType
        self.sustainabilityPoints = sustainabilityPoints
        self.following = following
        self.followers = followers
        self.likedItems = likedItems
        self.wardrobe = wardrobe
    }
}

// MARK: - Transaction Model
struct Transaction: Identifiable, Codable {
    let id: UUID
    var itemId: String
    var sellerId: String
    var buyerId: String
    var transactionType: TransactionType
    var price: Double
    var status: TransactionStatus
    var createdAt: Date
    var completedAt: Date?
    var trackingNumber: String?
    var review: Review?
    
    enum TransactionType: String, Codable {
        case purchase = "Purchase"
        case swap = "Swap"
        case rent = "Rent"
    }
    
    enum TransactionStatus: String, Codable {
        case pending = "Pending"
        case processing = "Processing"
        case shipped = "Shipped"
        case delivered = "Delivered"
        case completed = "Completed"
        case cancelled = "Cancelled"
        case disputed = "Disputed"
    }
}

struct Review: Codable {
    var rating: Int // 1-5
    var comment: String
    var createdAt: Date
}

// MARK: - Sample Data Generator
extension FashionItem {
    static var sampleItems: [FashionItem] {
        [
            FashionItem(
                name: "Organic Cotton T-Shirt",
                brand: "Patagonia",
                category: .tops,
                size: "M",
                condition: .likeNew,
                originalPrice: 45.00,
                listingPrice: 25.00,
                description: "Comfortable organic cotton tee, barely worn",
                imageURLs: ["patagonia_tee_1", "patagonia_tee_2"],
                sustainabilityScore: SustainabilityScore(
                    totalScore: 85,
                    carbonFootprint: 2.5,
                    waterUsage: 1800,
                    isRecycled: false,
                    isCertified: true,
                    certifications: ["GOTS", "Fair Trade"],
                    fibreTraceVerified: true
                ),
                materialComposition: [Material.cottonOrganic],
                colorTags: ["Navy", "Blue"],
                styleTags: ["Casual", "Basics", "Sustainable"],
                location: "Melbourne, VIC",
                ownerId: "user123"
            ),
            FashionItem(
                name: "Recycled Denim Jacket",
                brand: "Everlane",
                category: .outerwear,
                size: "L",
                condition: .excellent,
                originalPrice: 120.00,
                listingPrice: 65.00,
                description: "Classic denim jacket made from recycled materials",
                imageURLs: ["everlane_jacket_1"],
                sustainabilityScore: SustainabilityScore(
                    totalScore: 92,
                    carbonFootprint: 3.2,
                    waterUsage: 2500,
                    isRecycled: true,
                    isCertified: true,
                    certifications: ["B Corp", "Recycled Content"],
                    fibreTraceVerified: true
                ),
                materialComposition: [
                    Material(name: "Recycled Cotton", percentage: 70, isOrganic: false, isRecycled: true),
                    Material(name: "Recycled Polyester", percentage: 30, isOrganic: false, isRecycled: true)
                ],
                colorTags: ["Denim", "Blue"],
                styleTags: ["Classic", "Streetwear", "Sustainable"],
                location: "Sydney, NSW",
                ownerId: "user456"
            )
        ]
    }
}
