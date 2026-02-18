//
//  APIConfiguration.swift
//  Modaics
//
//  Centralized API configuration with environment support
//  Handles prod/dev URLs, timeouts, and feature flags
//

import Foundation

// MARK: - Environment

enum APIEnvironment: String, CaseIterable, Identifiable {
    case development = "development"
    case staging = "staging"
    case production = "production"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .development: return "Development"
        case .staging: return "Staging"
        case .production: return "Production"
        }
    }
    
    var baseURL: String {
        switch self {
        case .development:
            // Use localhost for simulator, device IP for physical device
            #if targetEnvironment(simulator)
            return "http://localhost:8000"
            #else
            return "http://10.20.99.164:8000"
            #endif
        case .staging:
            return "https://api-staging.modaics.com"
        case .production:
            return "https://api.modaics.com"
        }
    }
    
    var webSocketURL: String {
        switch self {
        case .development:
            #if targetEnvironment(simulator)
            return "ws://localhost:8000/ws"
            #else
            return "ws://10.20.99.164:8000/ws"
            #endif
        case .staging:
            return "wss://api-staging.modaics.com/ws"
        case .production:
            return "wss://api.modaics.com/ws"
        }
    }
    
    var isProduction: Bool {
        self == .production
    }
    
    var enableLogging: Bool {
        self != .production
    }
}

// MARK: - Configuration

struct APIConfiguration {
    
    // MARK: - Shared Instance
    
    static let shared = APIConfiguration()
    
    // MARK: - Properties
    
    var environment: APIEnvironment {
        get {
            if let saved = UserDefaults.standard.string(forKey: Keys.environment),
               let env = APIEnvironment(rawValue: saved) {
                return env
            }
            // Default to development in debug, production in release
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.environment)
            // Post notification for clients to update
            NotificationCenter.default.post(name: .apiEnvironmentChanged, object: nil)
        }
    }
    
    var baseURL: String { environment.baseURL }
    var webSocketURL: String { environment.webSocketURL }
    var enableLogging: Bool { environment.enableLogging }
    
    // MARK: - Request Configuration
    
    var defaultTimeout: TimeInterval = 30.0
    var uploadTimeout: TimeInterval = 120.0
    var searchTimeout: TimeInterval = 45.0
    var maxRetryAttempts: Int = 3
    var retryDelay: TimeInterval = 1.0
    var maxRetryDelay: TimeInterval = 8.0
    
    // MARK: - Image Configuration
    
    var maxImageDimension: CGFloat = 2048
    var imageCompressionQuality: CGFloat = 0.85
    var maxUploadSizeMB: Double = 10.0
    
    // MARK: - Cache Configuration
    
    var cacheEnabled: Bool = true
    var cacheExpirationHours: Int = 24
    var maxCacheSizeMB: Int = 100
    
    // MARK: - Feature Flags
    
    var enableOfflineSupport: Bool = true
    var enableBackgroundRefresh: Bool = true
    var enableWebSocket: Bool = false // Enable when WebSocket endpoints are ready
    var enablePushNotifications: Bool = true
    
    // MARK: - Private Keys
    
    private struct Keys {
        static let environment = "api_environment"
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - URL Construction
    
    func url(for endpoint: APIEndpoint) -> URL? {
        return URL(string: baseURL + endpoint.path)
    }
    
    func url(forPath path: String) -> URL? {
        return URL(string: baseURL + path)
    }
}

// MARK: - Endpoints

enum APIEndpoint {
    // Health
    case health
    
    // Search
    case searchByImage
    case searchByText
    case searchCombined
    
    // AI Analysis
    case analyzeImage
    case generateDescription
    
    // Items
    case addItem
    case getItem(Int)
    case updateItem(Int)
    case deleteItem(Int)
    
    // Sketchbook
    case getSketchbook(brandId: String)
    case updateSketchbookSettings(sketchbookId: Int)
    case getSketchbookPosts(sketchbookId: Int)
    case createSketchbookPost(sketchbookId: Int)
    case deleteSketchbookPost(postId: Int)
    case checkMembership(sketchbookId: Int, userId: String)
    case requestMembership(sketchbookId: Int)
    case checkSpendEligibility(sketchbookId: Int, userId: String)
    case voteInPoll(postId: Int)
    case getPollResults(postId: Int)
    case addReaction(postId: Int)
    case removeReaction(postId: Int)
    case getCommunityFeed
    
    var path: String {
        switch self {
        case .health:
            return "/health"
            
        case .searchByImage:
            return "/search_by_image"
        case .searchByText:
            return "/search_by_text"
        case .searchCombined:
            return "/search_combined"
            
        case .analyzeImage:
            return "/analyze_image"
        case .generateDescription:
            return "/generate_description"
            
        case .addItem:
            return "/add_item"
        case .getItem(let id):
            return "/items/\(id)"
        case .updateItem(let id):
            return "/items/\(id)"
        case .deleteItem(let id):
            return "/items/\(id)"
            
        case .getSketchbook(let brandId):
            return "/sketchbook/brand/\(brandId)"
        case .updateSketchbookSettings(let sketchbookId):
            return "/sketchbook/\(sketchbookId)/settings"
        case .getSketchbookPosts(let sketchbookId):
            return "/sketchbook/\(sketchbookId)/posts"
        case .createSketchbookPost(let sketchbookId):
            return "/sketchbook/\(sketchbookId)/posts"
        case .deleteSketchbookPost(let postId):
            return "/sketchbook/posts/\(postId)"
        case .checkMembership(let sketchbookId, let userId):
            return "/sketchbook/\(sketchbookId)/membership/\(userId)"
        case .requestMembership(let sketchbookId):
            return "/sketchbook/\(sketchbookId)/membership"
        case .checkSpendEligibility(let sketchbookId, let userId):
            return "/sketchbook/\(sketchbookId)/spend-eligibility/\(userId)"
        case .voteInPoll(let postId):
            return "/sketchbook/posts/\(postId)/vote"
        case .getPollResults(let postId):
            return "/sketchbook/posts/\(postId)/poll"
        case .addReaction(let postId):
            return "/sketchbook/posts/\(postId)/react"
        case .removeReaction(let postId):
            return "/sketchbook/posts/\(postId)/react"
        case .getCommunityFeed:
            return "/community/sketchbook-feed"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .health,
             .searchByImage, .searchByText, .searchCombined,
             .analyzeImage, .generateDescription,
             .getSketchbook, .getSketchbookPosts,
             .checkMembership, .checkSpendEligibility,
             .getPollResults, .getCommunityFeed,
             .getItem:
            return .get
            
        case .addItem,
             .createSketchbookPost, .requestMembership,
             .voteInPoll, .addReaction:
            return .post
            
        case .updateSketchbookSettings, .updateItem:
            return .put
            
        case .deleteSketchbookPost, .removeReaction, .deleteItem:
            return .delete
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Notifications

extension Notification.Name {
    static let apiEnvironmentChanged = Notification.Name("apiEnvironmentChanged")
    static let apiAuthTokenRefreshed = Notification.Name("apiAuthTokenRefreshed")
    static let apiDidEncounterError = Notification.Name("apiDidEncounterError")
}
