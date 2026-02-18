//
//  APIModels.swift
//  Modaics
//
//  Request and Response models matching the FastAPI backend
//

import Foundation

// MARK: - Base Response

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: APIErrorDetail?
    let message: String?
}

struct APIErrorDetail: Codable {
    let code: String
    let message: String
    let details: [String: String]?
}

// MARK: - Search Models

struct SearchRequest: Codable {
    let query: String?
    let imageBase64: String?
    let limit: Int?
    
    enum CodingKeys: String, CodingKey {
        case query
        case imageBase64 = "image_base64"
        case limit
    }
}

struct SearchResponse: Codable {
    let items: [SearchResult]
}

struct SearchResult: Codable, Identifiable, Hashable {
    let id: Int
    let externalId: String?
    let title: String?
    let description: String?
    let price: Double?
    let url: String?
    let imageUrl: String?
    let source: String?
    let distance: Double?
    let similarity: Double?  // Stored property for backend compatibility
    let redirectUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case externalId = "external_id"
        case title
        case description
        case price
        case url
        case imageUrl = "image_url"
        case source
        case distance
        case similarity
        case redirectUrl = "redirect_url"
    }
    
    // MARK: - Computed Properties
    
    var itemUrl: String {
        redirectUrl ?? url ?? ""
    }
    
    var platform: String {
        source?.capitalized ?? "Unknown"
    }
    
    var computedSimilarity: Double? {
        if let similarity = similarity { return similarity }
        guard let distance = distance else { return nil }
        return max(0, min(1, 1.0 - distance))
    }
    
    var formattedPrice: String {
        guard let price = price else { return "Price unavailable" }
        return String(format: "$%.2f", price)
    }
    
    // MARK: - Brand Extraction
    
    var brand: String? {
        extractBrand(from: title)
    }
    
    private func extractBrand(from title: String?) -> String? {
        guard let title = title else { return nil }
        
        let brands = [
            // Luxury
            "Prada", "Gucci", "Louis Vuitton", "Chanel", "Dior", "Balenciaga",
            "Versace", "Fendi", "Burberry", "Saint Laurent", "YSL", "Hermès",
            "Givenchy", "Valentino", "Celine", "Bottega Veneta",
            // Streetwear
            "Supreme", "Palace", "BAPE", "A Bathing Ape", "Stüssy", "Off-White",
            "Kith", "Anti Social Social Club", "ASSC", "Fear of God", "Essentials",
            // Athletic
            "Nike", "Adidas", "Puma", "Reebok", "New Balance", "Under Armour",
            "ASICS", "Vans", "Converse", "Champion", "Fila", "Lululemon",
            // Contemporary
            "AMI Paris", "Acne Studios", "A.P.C.", "Stone Island", "C.P. Company",
            "Carhartt", "Dickies", "Carhartt WIP", "Polo Ralph Lauren", "Ralph Lauren",
            "Tommy Hilfiger", "Lacoste", "Patagonia", "The North Face", "Arc'teryx",
            // Denim
            "Levi's", "Wrangler", "Lee", "Diesel", "True Religion", "G-Star",
            // Fast Fashion
            "Zara", "H&M", "Uniqlo", "Gap", "Old Navy"
        ]
        
        for brand in brands {
            if title.localizedCaseInsensitiveContains(brand) {
                return brand
            }
        }
        return nil
    }
}

// MARK: - Legacy AI Analysis Result (for SearchAPIClient compatibility)

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

// MARK: - Legacy Search API Error (for SearchAPIClient compatibility)

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

// MARK: - AI Analysis Models

struct AIAnalysisRequest: Codable {
    let image: String
}

struct AIAnalysisResponse: Codable {
    let detectedItem: String
    let likelyBrand: String
    let category: String
    let specificCategory: String?
    let estimatedSize: String
    let estimatedCondition: String
    let description: String
    let colors: [String]
    let pattern: String?
    let materials: [String]
    let estimatedPrice: Double?
    let confidence: Double
    let confidenceScores: ConfidenceScores?
    
    enum CodingKeys: String, CodingKey {
        case detectedItem = "detected_item"
        case likelyBrand = "likely_brand"
        case category
        case specificCategory = "specific_category"
        case estimatedSize = "estimated_size"
        case estimatedCondition = "estimated_condition"
        case description
        case colors
        case pattern
        case materials
        case estimatedPrice = "estimated_price"
        case confidence
        case confidenceScores = "confidence_scores"
    }
}

struct ConfidenceScores: Codable {
    let category: Double?
    let colors: [Double]?
    let pattern: Double?
    let brand: Double?
}

struct GenerateDescriptionRequest: Codable {
    let image: String
    let category: String?
    let brand: String?
    let colors: [String]?
    let condition: String?
    let materials: [String]?
    let size: String?
    
    enum CodingKeys: String, CodingKey {
        case image
        case category
        case brand
        case colors
        case condition
        case materials
        case size
    }
}

struct GenerateDescriptionResponse: Codable {
    let description: String
    let method: String
    let confidence: Double
}

// MARK: - Item Models

struct AddItemRequest: Codable {
    let imageBase64: String
    let title: String
    let description: String
    let price: Double?
    let brand: String?
    let category: String?
    let size: String?
    let condition: String?
    let ownerId: String?
    let source: String?
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case imageBase64 = "image_base64"
        case title
        case description
        case price
        case brand
        case category
        case size
        case condition
        case ownerId = "owner_id"
        case source
        case imageUrl = "image_url"
    }
}

struct AddItemResponse: Codable {
    let success: Bool
    let itemId: Int
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case itemId = "item_id"
        case message
    }
}

struct ItemDetail: Codable, Identifiable {
    let id: Int
    let externalId: String?
    let title: String
    let description: String?
    let price: Double?
    let brand: String?
    let category: String?
    let size: String?
    let condition: String?
    let imageUrl: String?
    let source: String?
    let ownerId: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case externalId = "external_id"
        case title
        case description
        case price
        case brand
        case category
        case size
        case condition
        case imageUrl = "image_url"
        case source
        case ownerId = "owner_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Sketchbook Models

struct Sketchbook: Codable, Identifiable {
    let id: Int
    let brandId: String
    let title: String?
    let description: String?
    let accessPolicy: SketchbookAccessPolicy
    let membershipRule: SketchbookMembershipRule
    let minSpendAmount: Double?
    let minSpendWindowMonths: Int?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case brandId = "brand_id"
        case title
        case description
        case accessPolicy = "access_policy"
        case membershipRule = "membership_rule"
        case minSpendAmount = "min_spend_amount"
        case minSpendWindowMonths = "min_spend_window_months"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum SketchbookAccessPolicy: String, Codable {
    case public_access = "public"
    case members_only = "members_only"
    case private_access = "private"
}

enum SketchbookMembershipRule: String, Codable {
    case autoApprove = "auto_approve"
    case requestApproval = "request_approval"
    case spendThreshold = "spend_threshold"
    case inviteOnly = "invite_only"
}

enum SketchbookPostType: String, Codable {
    case standard = "standard"
    case poll = "poll"
    case event = "event"
    case announcement = "announcement"
    case drop = "drop"
}

enum SketchbookVisibility: String, Codable {
    case `public` = "public"
    case membersOnly = "members_only"
    case private_visibility = "private"
}

struct SketchbookPost: Codable, Identifiable {
    let id: Int
    let sketchbookId: Int
    let authorUserId: String
    let postType: SketchbookPostType
    let title: String
    let body: String?
    let media: [MediaAttachment]?
    let tags: [String]?
    let visibility: SketchbookVisibility
    let pollQuestion: String?
    let pollOptions: [PollOption]?
    let pollClosesAt: Date?
    let eventId: Int?
    let eventHighlight: String?
    let reactionCount: Int?
    let commentCount: Int?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case sketchbookId = "sketchbook_id"
        case authorUserId = "author_user_id"
        case postType = "post_type"
        case title
        case body
        case media
        case tags
        case visibility
        case pollQuestion = "poll_question"
        case pollOptions = "poll_options"
        case pollClosesAt = "poll_closes_at"
        case eventId = "event_id"
        case eventHighlight = "event_highlight"
        case reactionCount = "reaction_count"
        case commentCount = "comment_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct MediaAttachment: Codable, Identifiable {
    let id: String
    let type: MediaType
    let url: String
    let thumbnailURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case url
        case thumbnailURL = "thumbnail_url"
    }
}

enum MediaType: String, Codable {
    case image = "image"
    case video = "video"
    case link = "link"
}

struct PollOption: Codable, Identifiable {
    let id: String
    let label: String
    let votes: Int
    
    var percentage: Double {
        // Calculated on client side based on total votes
        0
    }
}

struct PollResults: Codable {
    let question: String
    let options: [PollOption]
    let closesAt: Date?
    let isClosed: Bool
    
    enum CodingKeys: String, CodingKey {
        case question
        case options
        case closesAt = "closes_at"
        case isClosed = "is_closed"
    }
    
    var totalVotes: Int {
        options.reduce(0) { $0 + $1.votes }
    }
    
    func percentage(for option: PollOption) -> Double {
        guard totalVotes > 0 else { return 0 }
        return Double(option.votes) / Double(totalVotes) * 100
    }
}

struct SketchbookMembership: Codable, Identifiable {
    let id: Int
    let sketchbookId: Int
    let userId: String
    let status: MembershipStatus
    let joinSource: SketchbookJoinSource
    let joinedAt: Date?
    let expiresAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case sketchbookId = "sketchbook_id"
        case userId = "user_id"
        case status
        case joinSource = "join_source"
        case joinedAt = "joined_at"
        case expiresAt = "expires_at"
    }
}

enum MembershipStatus: String, Codable {
    case active = "active"
    case pending = "pending"
    case expired = "expired"
    case revoked = "revoked"
}

enum SketchbookJoinSource: String, Codable {
    case autoApproved = "auto_approved"
    case requestApproved = "request_approved"
    case invite = "invite"
    case spendThreshold = "spend_threshold"
    case loyaltyPoints = "loyalty_points"
}

enum SketchbookReactionType: String, Codable {
    case like = "like"
    case love = "love"
    case fire = "fire"
    case celebrate = "celebrate"
}

struct SpendEligibility: Codable {
    let eligible: Bool
    let spentAmount: Double
    let requiredAmount: Double
    let withinWindow: Bool
    let windowMonths: Int
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case eligible
        case spentAmount = "spent_amount"
        case requiredAmount = "required_amount"
        case withinWindow = "within_window"
        case windowMonths = "window_months"
        case message
    }
}

struct UpdateSketchbookSettingsRequest: Codable {
    let title: String?
    let description: String?
    let accessPolicy: SketchbookAccessPolicy?
    let membershipRule: SketchbookMembershipRule?
    let minSpendAmount: Double?
    let minSpendWindowMonths: Int?
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case accessPolicy = "access_policy"
        case membershipRule = "membership_rule"
        case minSpendAmount = "min_spend_amount"
        case minSpendWindowMonths = "min_spend_window_months"
    }
}

struct CreatePostRequest: Codable {
    let authorUserId: String
    let postType: SketchbookPostType
    let title: String
    let body: String?
    let media: [MediaAttachment]?
    let tags: [String]?
    let visibility: SketchbookVisibility
    let pollQuestion: String?
    let pollOptions: [PollOption]?
    let pollClosesAt: String? // ISO8601 string
    let eventId: Int?
    let eventHighlight: String?
    
    enum CodingKeys: String, CodingKey {
        case authorUserId = "author_user_id"
        case postType = "post_type"
        case title
        case body
        case media
        case tags
        case visibility
        case pollQuestion = "poll_question"
        case pollOptions = "poll_options"
        case pollClosesAt = "poll_closes_at"
        case eventId = "event_id"
        case eventHighlight = "event_highlight"
    }
}

struct VoteRequest: Codable {
    let userId: String
    let optionId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case optionId = "option_id"
    }
}

struct ReactionRequest: Codable {
    let userId: String
    let reactionType: SketchbookReactionType
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case reactionType = "reaction_type"
    }
}

// MARK: - Health Check

struct HealthCheckResponse: Codable {
    let status: String
    let version: String?
    let timestamp: String?
}

// MARK: - Error Models

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(String, Int)
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case requestTimeout
    case offline
    case cancelled
    case unknown
    
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
        case .serverError(let message, let code):
            return "Server error (\(code)): \(message)"
        case .unauthorized:
            return "Unauthorized. Please sign in again."
        case .forbidden:
            return "Access denied"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .requestTimeout:
            return "Request timed out. Please try again."
        case .offline:
            return "No internet connection"
        case .cancelled:
            return "Request cancelled"
        case .unknown:
            return "An unknown error occurred"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError, .requestTimeout, .rateLimited, .offline:
            return true
        case .unauthorized, .forbidden, .notFound, .invalidURL, .decodingError, .invalidResponse, .cancelled, .unknown:
            return false
        }
    }
}

// MARK: - Sample Data Extensions

extension Sketchbook {
    static let sample = Sketchbook(
        id: 1,
        brandId: "brand-sample",
        title: "Sample Sketchbook",
        description: "A sample sketchbook for preview purposes",
        accessPolicy: .public_access,
        membershipRule: .autoApprove,
        minSpendAmount: nil,
        minSpendWindowMonths: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
}

extension SketchbookPost {
    static let sampleUpdate = SketchbookPost(
        id: 1,
        sketchbookId: 1,
        authorUserId: "user-1",
        postType: .standard,
        title: "New Collection Drop!",
        body: "Check out our latest sustainable fashion collection. Made with 100% organic materials.",
        media: nil,
        tags: ["sustainable", "organic", "new"],
        visibility: .public,
        pollQuestion: nil,
        pollOptions: nil,
        pollClosesAt: nil,
        eventId: nil,
        eventHighlight: nil,
        reactionCount: 42,
        commentCount: 8,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let samplePoll = SketchbookPost(
        id: 2,
        sketchbookId: 1,
        authorUserId: "user-1",
        postType: .poll,
        title: "Which color should we release next?",
        body: "Help us decide the next color for our popular eco-denim line.",
        media: nil,
        tags: ["poll", "denim", "community"],
        visibility: .public,
        pollQuestion: "Which color should we release next?",
        pollOptions: [
            PollOption(id: "opt-1", label: "Ocean Blue", votes: 145),
            PollOption(id: "opt-2", label: "Forest Green", votes: 89),
            PollOption(id: "opt-3", label: "Earth Brown", votes: 67)
        ],
        pollClosesAt: Date().addingTimeInterval(86400 * 7),
        eventId: nil,
        eventHighlight: nil,
        reactionCount: 23,
        commentCount: 12,
        createdAt: Date(),
        updatedAt: Date()
    )
}
