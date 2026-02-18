//
//  SketchbookService.swift
//  ModaicsAppTemp
//
//  API service for Sketchbook feature
//

import Foundation

class SketchbookService {
    static let shared = SketchbookService()
    
    private let baseURL: String
    private let session: URLSession
    
    init(baseURL: String = "http://10.20.99.164:8000") {
        self.baseURL = baseURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Decoder Helper
    
    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        
        // Custom date decoder for PostgreSQL timestamp format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try PostgreSQL format first (with microseconds)
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            
            // Fallback to ISO8601
            if let date = ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath,
                                    debugDescription: "Invalid date format: \(dateString)")
            )
        }
        
        // Don't use convertFromSnakeCase - models have explicit CodingKeys
        return decoder
    }
    
    // MARK: - Sketchbook CRUD
    
    func getSketchbook(forBrand brandId: String) async throws -> Sketchbook {
        let url = URL(string: "\(baseURL)/sketchbook/brand/\(brandId)")!
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SketchbookError.invalidResponse
        }
        
        let decoder = createDecoder()
        
        return try decoder.decode(Sketchbook.self, from: data)
    }
    
    func updateSketchbookSettings(
        sketchbookId: Int,
        title: String? = nil,
        description: String? = nil,
        accessPolicy: SketchbookAccessPolicy? = nil,
        membershipRule: SketchbookMembershipRule? = nil,
        minSpendAmount: Double? = nil,
        minSpendWindowMonths: Int? = nil
    ) async throws -> Sketchbook {
        let url = URL(string: "\(baseURL)/sketchbook/\(sketchbookId)/settings")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var payload: [String: Any] = [:]
        if let title = title { payload["title"] = title }
        if let description = description { payload["description"] = description }
        if let accessPolicy = accessPolicy { payload["access_policy"] = accessPolicy.rawValue }
        if let membershipRule = membershipRule { payload["membership_rule"] = membershipRule.rawValue }
        if let minSpendAmount = minSpendAmount { payload["min_spend_amount"] = minSpendAmount }
        if let minSpendWindowMonths = minSpendWindowMonths { payload["min_spend_window_months"] = minSpendWindowMonths }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SketchbookError.invalidResponse
        }
        
        let decoder = createDecoder()
        
        return try decoder.decode(Sketchbook.self, from: data)
    }
    
    // MARK: - Posts
    
    func getPosts(
        forSketchbook sketchbookId: Int,
        userId: String? = nil,
        limit: Int = 50
    ) async throws -> [SketchbookPost] {
        var urlComponents = URLComponents(string: "\(baseURL)/sketchbook/\(sketchbookId)/posts")!
        
        var queryItems: [URLQueryItem] = []
        if let userId = userId {
            queryItems.append(URLQueryItem(name: "user_id", value: userId))
        }
        queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        urlComponents.queryItems = queryItems
        
        let (data, response) = try await session.data(from: urlComponents.url!)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SketchbookError.invalidResponse
        }
        
        let decoder = createDecoder()
        
        let responseObject = try decoder.decode([String: [SketchbookPost]].self, from: data)
        return responseObject["posts"] ?? []
    }
    
    func createPost(
        sketchbookId: Int,
        authorUserId: String,
        postType: SketchbookPostType,
        title: String,
        body: String? = nil,
        media: [MediaAttachment] = [],
        tags: [String] = [],
        visibility: SketchbookVisibility = .public,
        pollQuestion: String? = nil,
        pollOptions: [PollOption]? = nil,
        pollClosesAt: Date? = nil,
        eventId: Int? = nil,
        eventHighlight: String? = nil
    ) async throws -> SketchbookPost {
        let url = URL(string: "\(baseURL)/sketchbook/\(sketchbookId)/posts")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var payload: [String: Any] = [
            "author_user_id": authorUserId,
            "post_type": postType.rawValue,
            "title": title,
            "visibility": visibility.rawValue
        ]
        
        if let body = body { payload["body"] = body }
        if !media.isEmpty {
            let mediaArray = media.map { media -> [String: Any] in
                var dict: [String: Any] = [
                    "id": media.id,
                    "type": media.type.rawValue,
                    "url": media.url
                ]
                if let thumbnail = media.thumbnailURL {
                    dict["thumbnail_url"] = thumbnail
                }
                return dict
            }
            payload["media"] = mediaArray
        }
        if !tags.isEmpty { payload["tags"] = tags }
        if let pollQuestion = pollQuestion { payload["poll_question"] = pollQuestion }
        if let pollOptions = pollOptions {
            let optionsArray = pollOptions.map { ["id": $0.id, "label": $0.label, "votes": $0.votes] }
            payload["poll_options"] = optionsArray
        }
        if let pollClosesAt = pollClosesAt {
            let formatter = ISO8601DateFormatter()
            payload["poll_closes_at"] = formatter.string(from: pollClosesAt)
        }
        if let eventId = eventId { payload["event_id"] = eventId }
        if let eventHighlight = eventHighlight { payload["event_highlight"] = eventHighlight }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SketchbookError.invalidResponse
        }
        
        let decoder = createDecoder()
        
        return try decoder.decode(SketchbookPost.self, from: data)
    }
    
    func deletePost(postId: Int, userId: String) async throws {
        var urlComponents = URLComponents(string: "\(baseURL)/sketchbook/posts/\(postId)")!
        urlComponents.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SketchbookError.invalidResponse
        }
    }
    
    // MARK: - Membership
    
    func checkMembership(sketchbookId: Int, userId: String) async throws -> SketchbookMembership? {
        let url = URL(string: "\(baseURL)/sketchbook/\(sketchbookId)/membership/\(userId)")!
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SketchbookError.invalidResponse
        }
        
        let decoder = createDecoder()
        
        // Try to decode as membership first
        do {
            let membership = try decoder.decode(SketchbookMembership.self, from: data)
            return membership
        } catch {
            // If that fails, check if status is "none"
            if let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = result["status"] as? String,
               status == "none" {
                return nil
            }
            // Re-throw the original decoding error
            throw error
        }
    }
    
    func requestMembership(
        sketchbookId: Int,
        userId: String,
        joinSource: SketchbookJoinSource = .requestApproved
    ) async throws -> SketchbookMembership {
        let url = URL(string: "\(baseURL)/sketchbook/\(sketchbookId)/membership")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "user_id": userId,
            "join_source": joinSource.rawValue
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SketchbookError.invalidResponse
        }
        
        let decoder = createDecoder()
        
        return try decoder.decode(SketchbookMembership.self, from: data)
    }
    
    func checkSpendEligibility(sketchbookId: Int, userId: String) async throws -> SpendEligibility {
        let url = URL(string: "\(baseURL)/sketchbook/\(sketchbookId)/spend-eligibility/\(userId)")!
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SketchbookError.invalidResponse
        }
        
        let decoder = createDecoder()
        
        return try decoder.decode(SpendEligibility.self, from: data)
    }
    
    // MARK: - Polls
    
    func voteInPoll(postId: Int, userId: String, optionId: String) async throws -> PollResults {
        let url = URL(string: "\(baseURL)/sketchbook/posts/\(postId)/vote")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "user_id": userId,
            "option_id": optionId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SketchbookError.invalidResponse
        }
        
        let decoder = createDecoder()
        
        return try decoder.decode(PollResults.self, from: data)
    }
    
    func getPollResults(postId: Int) async throws -> PollResults {
        let url = URL(string: "\(baseURL)/sketchbook/posts/\(postId)/poll")!
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SketchbookError.invalidResponse
        }
        
        let decoder = createDecoder()
        
        return try decoder.decode(PollResults.self, from: data)
    }
    
    // MARK: - Reactions
    
    func addReaction(postId: Int, userId: String, reactionType: SketchbookReactionType = .like) async throws {
        let url = URL(string: "\(baseURL)/sketchbook/posts/\(postId)/react")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "user_id": userId,
            "reaction_type": reactionType.rawValue
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SketchbookError.invalidResponse
        }
    }
    
    func removeReaction(postId: Int, userId: String, reactionType: SketchbookReactionType = .like) async throws {
        var urlComponents = URLComponents(string: "\(baseURL)/sketchbook/posts/\(postId)/react")!
        urlComponents.queryItems = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "reaction_type", value: reactionType.rawValue)
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SketchbookError.invalidResponse
        }
    }
    
    // MARK: - Community Feed
    
    func getCommunityFeed(userId: String, limit: Int = 20) async throws -> [SketchbookPost] {
        var urlComponents = URLComponents(string: "\(baseURL)/community/sketchbook-feed")!
        urlComponents.queryItems = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        let (data, response) = try await session.data(from: urlComponents.url!)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SketchbookError.invalidResponse
        }
        
        // Debug: Print raw JSON
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 Raw JSON response: \(jsonString.prefix(500))")
        }
        
        let decoder = createDecoder()
        
        do {
            let responseObject = try decoder.decode([String: [SketchbookPost]].self, from: data)
            return responseObject["posts"] ?? []
        } catch {
            print("❌ Decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Missing key: \(key.stringValue) at \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch for type \(type) at \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found for type \(type) at \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted at \(context.codingPath)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
            }
            throw error
        }
    }
}

// MARK: - Errors

enum SketchbookError: LocalizedError {
    case invalidResponse
    case networkError
    case decodingError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError:
            return "Network connection error"
        case .decodingError:
            return "Failed to decode response"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}
