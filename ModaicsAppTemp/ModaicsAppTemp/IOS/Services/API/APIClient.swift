//
//  APIClient.swift
//  Modaics
//
//  Base API client with authentication, retry logic, and error handling
//

import Foundation
import UIKit
import Combine

// MARK: - Request Builder

struct APIRequest {
    let endpoint: APIEndpoint
    var queryParameters: [String: String]?
    var body: Encodable?
    var timeout: TimeInterval?
    var requiresAuth: Bool = true
    var retryPolicy: RetryPolicy?
    
    struct RetryPolicy {
        let maxAttempts: Int
        let delay: TimeInterval
        let maxDelay: TimeInterval
        let retryableStatusCodes: Set<Int>
        
        static let `default` = RetryPolicy(
            maxAttempts: 3,
            delay: 1.0,
            maxDelay: 8.0,
            retryableStatusCodes: [408, 429, 500, 502, 503, 504]
        )
        
        static let noRetry = RetryPolicy(
            maxAttempts: 1,
            delay: 0,
            maxDelay: 0,
            retryableStatusCodes: []
        )
    }
}

// MARK: - API Client

@MainActor
class APIClient: ObservableObject {
    
    // MARK: - Shared Instance
    
    static let shared = APIClient()
    
    // MARK: - Published Properties
    
    @Published var isReachable = true
    @Published private(set) var isRefreshingToken = false
    
    // MARK: - Private Properties
    
    private let configuration: APIConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var activeTasks: [String: Task<Data, Error>] = [:]
    private let networkMonitor = NetworkMonitor.shared
    
    // MARK: - Initialization
    
    init(configuration: APIConfiguration = .shared) {
        self.configuration = configuration
        
        // Configure URLSession
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = configuration.defaultTimeout
        config.timeoutIntervalForResource = configuration.uploadTimeout
        config.waitsForConnectivity = true
        config.requestCachePolicy = .returnCacheDataElseLoad
        
        // Trust certificates for development
        #if DEBUG
        // In production, use proper certificate pinning
        #endif
        
        self.session = URLSession(configuration: config)
        
        // Configure JSON decoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try multiple date formats
            let formatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
                "yyyy-MM-dd'T'HH:mm:ss.SSS",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd HH:mm:ss"
            ]
            
            for format in formatters {
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            // Try ISO8601
            if let date = ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }
        self.decoder = decoder
        
        // Configure JSON encoder
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .useDefaultKeys
        self.encoder = encoder
        
        // Setup network monitoring
        setupNetworkMonitoring()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        Task { @MainActor in
            for await isReachable in networkMonitor.isReachableStream() {
                self.isReachable = isReachable
            }
        }
    }
    
    // MARK: - Request Execution
    
    /// Execute a request and decode the response
    func request<T: Decodable>(_ apiRequest: APIRequest) async throws -> T {
        // Check network connectivity
        guard isReachable else {
            throw APIError.offline
        }
        
        // Build URL request
        let urlRequest = try await buildURLRequest(for: apiRequest)
        
        // Create task identifier for cancellation support
        let taskId = "\(apiRequest.endpoint.path)_\(UUID().uuidString)"
        
        // Execute with retry logic
        let retryPolicy = apiRequest.retryPolicy ?? .default
        var lastError: Error?
        
        for attempt in 1...retryPolicy.maxAttempts {
            do {
                let data = try await executeRequest(urlRequest, taskId: taskId)
                
                // Clear task reference
                activeTasks.removeValue(forKey: taskId)
                
                // Log response if enabled
                if configuration.enableLogging {
                    logResponse(data: data, for: apiRequest.endpoint)
                }
                
                // Decode response
                return try decoder.decode(T.self, from: data)
                
            } catch let error as APIError {
                lastError = error
                
                // Don't retry non-retryable errors
                if !error.isRetryable {
                    activeTasks.removeValue(forKey: taskId)
                    throw error
                }
                
                // Don't retry on last attempt
                if attempt == retryPolicy.maxAttempts {
                    break
                }
                
                // Check if we should retry based on status code
                if case .serverError(_, let statusCode) = error,
                   !retryPolicy.retryableStatusCodes.contains(statusCode) {
                    activeTasks.removeValue(forKey: taskId)
                    throw error
                }
                
                // Calculate exponential backoff delay
                let delay = min(
                    retryPolicy.delay * pow(2.0, Double(attempt - 1)),
                    retryPolicy.maxDelay
                )
                
                if configuration.enableLogging {
                    print("⏳ Retrying \(apiRequest.endpoint.path) in \(delay)s (attempt \(attempt + 1)/\(retryPolicy.maxAttempts))")
                }
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            } catch {
                lastError = error
                activeTasks.removeValue(forKey: taskId)
                throw error
            }
        }
        
        // All retries exhausted
        activeTasks.removeValue(forKey: taskId)
        throw lastError ?? APIError.unknown
    }
    
    /// Execute a request without decoding (for void responses)
    func request(_ apiRequest: APIRequest) async throws {
        let _: EmptyResponse = try await request(apiRequest)
    }
    
    /// Execute raw request and return Data
    private func executeRequest(_ urlRequest: URLRequest, taskId: String) async throws -> Data {
        // Check for cancellation
        if Task.isCancelled {
            throw APIError.cancelled
        }
        
        // Create and store task for cancellation support
        let task = Task<Data, Error> {
            do {
                let (data, response) = try await session.data(for: urlRequest)
                
                // Validate response
                try validateResponse(data: data, response: response)
                
                return data
            } catch let error as APIError {
                throw error
            } catch let error as URLError {
                switch error.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    throw APIError.offline
                case .timedOut:
                    throw APIError.requestTimeout
                case .cancelled:
                    throw APIError.cancelled
                default:
                    throw APIError.networkError(error)
                }
            } catch {
                throw APIError.networkError(error)
            }
        }
        
        activeTasks[taskId] = task
        
        do {
            return try await task.value
        } catch {
            throw error
        }
    }
    
    // MARK: - Request Building
    
    private func buildURLRequest(for apiRequest: APIRequest) async throws -> URLRequest {
        // Build URL
        guard let url = configuration.url(for: apiRequest.endpoint) else {
            throw APIError.invalidURL
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        
        // Add query parameters
        if let params = apiRequest.queryParameters, !params.isEmpty {
            components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let finalURL = components?.url else {
            throw APIError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: finalURL)
        request.httpMethod = apiRequest.endpoint.httpMethod.rawValue
        
        // Set timeout if specified
        if let timeout = apiRequest.timeout {
            request.timeoutInterval = timeout
        }
        
        // Add headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add auth token if required
        if apiRequest.requiresAuth {
            let token = try await AuthManager.shared.getValidToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body if present
        if let body = apiRequest.body {
            request.httpBody = try encoder.encode(body)
        }
        
        // Log request if enabled
        if configuration.enableLogging {
            logRequest(request, endpoint: apiRequest.endpoint)
        }
        
        return request
    }
    
    // MARK: - Response Validation
    
    private func validateResponse(data: Data, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        let statusCode = httpResponse.statusCode
        
        switch statusCode {
        case 200...299:
            return // Success
            
        case 401:
            throw APIError.unauthorized
            
        case 403:
            throw APIError.forbidden
            
        case 404:
            throw APIError.notFound
            
        case 429:
            throw APIError.rateLimited
            
        case 400...499:
            // Try to extract error message
            let message = extractErrorMessage(from: data) ?? "Client error"
            throw APIError.serverError(message, statusCode)
            
        case 500...599:
            let message = extractErrorMessage(from: data) ?? "Server error"
            throw APIError.serverError(message, statusCode)
            
        default:
            throw APIError.invalidResponse
        }
    }
    
    private func extractErrorMessage(from data: Data) -> String? {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json["detail"] as? String ?? json["message"] as? String
        }
        return nil
    }
    
    // MARK: - Logging
    
    private func logRequest(_ request: URLRequest, endpoint: APIEndpoint) {
        print("📤 [API] \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        if let headers = request.allHTTPHeaderFields {
            print("   Headers: \(headers.filter { $0.key != "Authorization" })")
        }
        if let body = request.httpBody,
           let json = try? JSONSerialization.jsonObject(with: body),
           let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let string = String(data: data, encoding: .utf8) {
            print("   Body: \(string)")
        }
    }
    
    private func logResponse(data: Data, for endpoint: APIEndpoint) {
        if let json = try? JSONSerialization.jsonObject(with: data),
           let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let string = String(data: data, encoding: .utf8) {
            print("📥 [API] Response from \(endpoint.path):")
            print("   \(string.prefix(1000))\(string.count > 1000 ? "..." : "")")
        }
    }
    
    // MARK: - Cancellation
    
    func cancelAllRequests() {
        for (_, task) in activeTasks {
            task.cancel()
        }
        activeTasks.removeAll()
    }
    
    func cancelRequests(for endpoint: APIEndpoint) {
        for (key, task) in activeTasks where key.hasPrefix(endpoint.path) {
            task.cancel()
            activeTasks.removeValue(forKey: key)
        }
    }
}

// MARK: - Empty Response

private struct EmptyResponse: Codable {}

// MARK: - Network Monitor

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    private init() {}
    
    func isReachableStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            // Simple implementation - in production use NWPathMonitor
            // For now, just return true
            continuation.yield(true)
            continuation.finish()
        }
    }
}
