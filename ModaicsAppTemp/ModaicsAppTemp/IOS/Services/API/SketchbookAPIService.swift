//
//  SketchbookAPIService.swift
//  Modaics
//
//  Sketchbook API service with full authentication and error handling
//  Replaces/extends the existing SketchbookService with proper APIClient integration
//

import Foundation
import UIKit

// MARK: - Sketchbook API Service

@MainActor
class SketchbookAPIService: ObservableObject {
    
    // MARK: - Shared Instance
    
    static let shared = SketchbookAPIService()
    
    // MARK: - Published Properties
    
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: APIError?
    @Published private(set) var currentSketchbook: Sketchbook?
    @Published private(set) var posts: [SketchbookPost] = []
    @Published private(set) var membership: SketchbookMembership?
    
    // MARK: - Private Properties
    
    private let apiClient: APIClient
    private let cache: SketchbookCache
    
    // MARK: - Initialization
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        self.cache = SketchbookCache()
    }
    
    // MARK: - Sketchbook
    
    /// Get or create sketchbook for a brand
    func getSketchbook(forBrand brandId: String, useCache: Bool = true) async throws -> Sketchbook {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        // Check cache
        if useCache, let cached = await cache.getSketchbook(forKey: brandId) {
            currentSketchbook = cached
            return cached
        }
        
        let request = APIRequest(
            endpoint: .getSketchbook(brandId: brandId),
            requiresAuth: true
        )
        
        do {
            let sketchbook: Sketchbook = try await apiClient.request(request)
            currentSketchbook = sketchbook
            
            if useCache {
                await cache.setSketchbook(sketchbook, forKey: brandId)
            }
            
            return sketchbook
            
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    /// Update sketchbook settings (brand only)
    func updateSketchbookSettings(
        sketchbookId: Int,
        title: String? = nil,
        description: String? = nil,
        accessPolicy: SketchbookAccessPolicy? = nil,
        membershipRule: SketchbookMembershipRule? = nil,
        minSpendAmount: Double? = nil,
        minSpendWindowMonths: Int? = nil
    ) async throws -> Sketchbook {
        isLoading = true
        defer { isLoading = false }
        
        let request = APIRequest(
            endpoint: .updateSketchbookSettings(sketchbookId: sketchbookId),
            body: UpdateSketchbookSettingsRequest(
                title: title,
                description: description,
                accessPolicy: accessPolicy,
                membershipRule: membershipRule,
                minSpendAmount: minSpendAmount,
                minSpendWindowMonths: minSpendWindowMonths
            ),
            requiresAuth: true
        )
        
        do {
            let sketchbook: Sketchbook = try await apiClient.request(request)
            currentSketchbook = sketchbook
            return sketchbook
            
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    // MARK: - Posts
    
    /// Get posts from a sketchbook
    func getPosts(
        sketchbookId: Int,
        userId: String? = nil,
        limit: Int = 50,
        useCache: Bool = true
    ) async throws -> [SketchbookPost] {
        isLoading = true
        defer { isLoading = false }
        
        let cacheKey = "\(sketchbookId)_\(userId ?? "all")_\(limit)"
        if useCache, let cached = await cache.getPosts(forKey: cacheKey) {
            posts = cached
            return cached
        }
        
        let request = APIRequest(
            endpoint: .getSketchbookPosts(sketchbookId: sketchbookId),
            queryParameters: [
                "user_id": userId ?? AuthManager.shared.userId ?? "",
                "limit": "\(limit)"
            ],
            requiresAuth: true
        )
        
        do {
            let response: PostsResponse = try await apiClient.request(request)
            posts = response.posts
            
            if useCache {
                await cache.setPosts(response.posts, forKey: cacheKey)
            }
            
            return response.posts
            
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    /// Create a new post (brand only)
    func createPost(
        sketchbookId: Int,
        title: String,
        body: String? = nil,
        postType: SketchbookPostType = .standard,
        media: [MediaAttachment] = [],
        tags: [String] = [],
        visibility: SketchbookVisibility = .public,
        pollQuestion: String? = nil,
        pollOptions: [PollOption]? = nil,
        pollClosesAt: Date? = nil,
        eventId: Int? = nil,
        eventHighlight: String? = nil
    ) async throws -> SketchbookPost {
        isLoading = true
        defer { isLoading = false }
        
        guard let authorUserId = AuthManager.shared.userId else {
            throw APIError.unauthorized
        }
        
        let request = APIRequest(
            endpoint: .createSketchbookPost(sketchbookId: sketchbookId),
            body: CreatePostRequest(
                authorUserId: authorUserId,
                postType: postType,
                title: title,
                body: body,
                media: media.isEmpty ? nil : media,
                tags: tags.isEmpty ? nil : tags,
                visibility: visibility,
                pollQuestion: pollQuestion,
                pollOptions: pollOptions,
                pollClosesAt: pollClosesAt?.iso8601String,
                eventId: eventId,
                eventHighlight: eventHighlight
            ),
            requiresAuth: true
        )
        
        do {
            let post: SketchbookPost = try await apiClient.request(request)
            posts.insert(post, at: 0)
            return post
            
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    /// Delete a post (author only)
    func deletePost(postId: Int, userId: String? = nil) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let effectiveUserId = userId ?? AuthManager.shared.userId ?? ""
        
        let request = APIRequest(
            endpoint: .deleteSketchbookPost(postId: postId),
            queryParameters: ["user_id": effectiveUserId],
            requiresAuth: true
        )
        
        do {
            try await apiClient.request(request)
            posts.removeAll { $0.id == postId }
            
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    // MARK: - Membership
    
    /// Check membership status
    func checkMembership(
        sketchbookId: Int,
        userId: String? = nil
    ) async throws -> SketchbookMembership? {
        let effectiveUserId = userId ?? AuthManager.shared.userId ?? ""
        
        let request = APIRequest(
            endpoint: .checkMembership(sketchbookId: sketchbookId, userId: effectiveUserId),
            requiresAuth: true
        )
        
        do {
            let membership: SketchbookMembership = try await apiClient.request(request)
            self.membership = membership
            return membership
            
        } catch APIError.notFound {
            membership = nil
            return nil
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    /// Request membership
    func requestMembership(
        sketchbookId: Int,
        joinSource: SketchbookJoinSource = .requestApproved
    ) async throws -> SketchbookMembership {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = AuthManager.shared.userId else {
            throw APIError.unauthorized
        }
        
        let request = APIRequest(
            endpoint: .requestMembership(sketchbookId: sketchbookId),
            body: MembershipRequest(
                userId: userId,
                joinSource: joinSource
            ),
            requiresAuth: true
        )
        
        do {
            let membership: SketchbookMembership = try await apiClient.request(request)
            self.membership = membership
            return membership
            
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    /// Check spend eligibility for spend-threshold sketchbooks
    func checkSpendEligibility(
        sketchbookId: Int,
        userId: String? = nil
    ) async throws -> SpendEligibility {
        let effectiveUserId = userId ?? AuthManager.shared.userId ?? ""
        
        let request = APIRequest(
            endpoint: .checkSpendEligibility(sketchbookId: sketchbookId, userId: effectiveUserId),
            requiresAuth: true
        )
        
        do {
            return try await apiClient.request(request)
            
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    // MARK: - Polls
    
    /// Vote in a poll
    func voteInPoll(
        postId: Int,
        optionId: String,
        userId: String? = nil
    ) async throws -> PollResults {
        guard let effectiveUserId = userId ?? AuthManager.shared.userId else {
            throw APIError.unauthorized
        }
        
        let request = APIRequest(
            endpoint: .voteInPoll(postId: postId),
            body: VoteRequest(
                userId: effectiveUserId,
                optionId: optionId
            ),
            requiresAuth: true
        )
        
        do {
            return try await apiClient.request(request)
            
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    /// Get poll results
    func getPollResults(postId: Int) async throws -> PollResults {
        let request = APIRequest(
            endpoint: .getPollResults(postId: postId),
            requiresAuth: true
        )
        
        do {
            return try await apiClient.request(request)
            
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    // MARK: - Reactions
    
    /// Add a reaction to a post
    func addReaction(
        postId: Int,
        reactionType: SketchbookReactionType = .like,
        userId: String? = nil
    ) async throws {
        guard let effectiveUserId = userId ?? AuthManager.shared.userId else {
            throw APIError.unauthorized
        }
        
        let request = APIRequest(
            endpoint: .addReaction(postId: postId),
            body: ReactionRequest(
                userId: effectiveUserId,
                reactionType: reactionType
            ),
            requiresAuth: true
        )
        
        do {
            try await apiClient.request(request)
            
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    /// Remove a reaction
    func removeReaction(
        postId: Int,
        reactionType: SketchbookReactionType = .like,
        userId: String? = nil
    ) async throws {
        guard let effectiveUserId = userId ?? AuthManager.shared.userId else {
            throw APIError.unauthorized
        }
        
        let request = APIRequest(
            endpoint: .removeReaction(postId: postId),
            queryParameters: [
                "user_id": effectiveUserId,
                "reaction_type": reactionType.rawValue
            ],
            requiresAuth: true
        )
        
        do {
            try await apiClient.request(request)
            
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    // MARK: - Community Feed
    
    /// Get community feed with posts from all accessible sketchbooks
    func getCommunityFeed(
        userId: String? = nil,
        limit: Int = 20,
        useCache: Bool = true
    ) async throws -> [SketchbookPost] {
        isLoading = true
        defer { isLoading = false }
        
        let effectiveUserId = userId ?? AuthManager.shared.userId ?? ""
        let cacheKey = "community_\(effectiveUserId)_\(limit)"
        
        if useCache, let cached = await cache.getPosts(forKey: cacheKey) {
            return cached
        }
        
        let request = APIRequest(
            endpoint: .getCommunityFeed,
            queryParameters: [
                "user_id": effectiveUserId,
                "limit": "\(limit)"
            ],
            requiresAuth: true
        )
        
        do {
            let response: PostsResponse = try await apiClient.request(request)
            
            if useCache {
                await cache.setPosts(response.posts, forKey: cacheKey)
            }
            
            return response.posts
            
        } catch let error as APIError {
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        Task {
            await cache.clear()
        }
    }
    
    func refreshCurrentSketchbook() async {
        guard let sketchbook = currentSketchbook else { return }
        
        do {
            _ = try await getSketchbook(forBrand: sketchbook.brandId, useCache: false)
        } catch {
            print("⚠️ Failed to refresh sketchbook: \(error)")
        }
    }
}

// MARK: - Supporting Types

struct PostsResponse: Codable {
    let posts: [SketchbookPost]
}

struct MembershipRequest: Codable {
    let userId: String
    let joinSource: SketchbookJoinSource
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case joinSource = "join_source"
    }
}

// MARK: - Date Extension

extension Date {
    var iso8601String: String {
        return ISO8601DateFormatter().string(from: self)
    }
}

// MARK: - Sketchbook Cache

@MainActor
private actor SketchbookCache {
    private var sketchbooks: [String: (sketchbook: Sketchbook, timestamp: Date)] = [:]
    private var posts: [String: (posts: [SketchbookPost], timestamp: Date)] = [:]
    private let cacheDuration: TimeInterval = 300 // 5 minutes
    
    func getSketchbook(forKey key: String) -> Sketchbook? {
        guard let entry = sketchbooks[key] else { return nil }
        
        if Date().timeIntervalSince(entry.timestamp) > cacheDuration {
            sketchbooks.removeValue(forKey: key)
            return nil
        }
        
        return entry.sketchbook
    }
    
    func setSketchbook(_ sketchbook: Sketchbook, forKey key: String) {
        sketchbooks[key] = (sketchbook: sketchbook, timestamp: Date())
    }
    
    func getPosts(forKey key: String) -> [SketchbookPost]? {
        guard let entry = posts[key] else { return nil }
        
        if Date().timeIntervalSince(entry.timestamp) > cacheDuration {
            posts.removeValue(forKey: key)
            return nil
        }
        
        return entry.posts
    }
    
    func setPosts(_ posts: [SketchbookPost], forKey key: String) {
        self.posts[key] = (posts: posts, timestamp: Date())
    }
    
    func clear() {
        sketchbooks.removeAll()
        posts.removeAll()
    }
}
