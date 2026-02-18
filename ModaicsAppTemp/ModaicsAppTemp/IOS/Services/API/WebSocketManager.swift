//
//  WebSocketManager.swift
//  Modaics
//
//  WebSocket connection manager for real-time features
//  Supports sketchbook updates, notifications, and live interactions
//

import Foundation
import Combine

// MARK: - WebSocket Event

enum WebSocketEvent: Equatable {
    case connected
    case disconnected
    case message(WebSocketMessage)
    case error(Error)
    
    static func == (lhs: WebSocketEvent, rhs: WebSocketEvent) -> Bool {
        switch (lhs, rhs) {
        case (.connected, .connected), (.disconnected, .disconnected):
            return true
        case (.message(let lhsMsg), .message(let rhsMsg)):
            return lhsMsg.id == rhsMsg.id
        case (.error, .error):
            return true // Errors are equal for simplicity
        default:
            return false
        }
    }
}

// MARK: - WebSocket Message

struct WebSocketMessage: Codable, Identifiable {
    let id: String
    let type: MessageType
    let payload: MessagePayload
    let timestamp: Date
    
    enum MessageType: String, Codable {
        case newPost = "new_post"
        case postUpdated = "post_updated"
        case postDeleted = "post_deleted"
        case newReaction = "new_reaction"
        case pollUpdate = "poll_update"
        case membershipUpdate = "membership_update"
        case notification = "notification"
        case ping = "ping"
        case pong = "pong"
    }
}

struct MessagePayload: Codable {
    let sketchbookId: Int?
    let postId: Int?
    let userId: String?
    let data: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case sketchbookId = "sketchbook_id"
        case postId = "post_id"
        case userId = "user_id"
        case data
    }
}

// MARK: - WebSocket Manager

@MainActor
class WebSocketManager: ObservableObject {
    
    // MARK: - Shared Instance
    
    static let shared = WebSocketManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var lastError: Error?
    
    var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }
    
    // MARK: - Private Properties
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let configuration: APIConfiguration
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var reconnectTimer: Timer?
    private var pingTimer: Timer?
    
    private var eventSubject = PassthroughSubject<WebSocketEvent, Never>()
    var eventPublisher: AnyPublisher<WebSocketEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    private init(configuration: APIConfiguration = .shared) {
        self.configuration = configuration
    }
    
    deinit {
        disconnect()
    }
    
    // MARK: - Connection Management
    
    /// Connect to WebSocket server
    func connect() async {
        guard configuration.enableWebSocket else {
            print("⚠️ WebSocket is disabled in configuration")
            return
        }
        
        guard webSocketTask == nil || webSocketTask?.state == .completed else {
            print("⚠️ WebSocket already connected or connecting")
            return
        }
        
        connectionState = .connecting
        
        do {
            let token = try await AuthManager.shared.getValidToken()
            
            guard let url = URL(string: configuration.webSocketURL) else {
                connectionState = .failed(WebSocketError.invalidURL)
                return
            }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let session = URLSession(configuration: .default)
            webSocketTask = session.webSocketTask(with: request)
            
            // Use a nonisolated handler for receive completion
            webSocketTask?.receive(completionHandler: { [weak self] result in
                // Handle on a detached task to avoid MainActor isolation issues
                Task { @MainActor [weak self] in
                    self?.handleReceiveResult(result)
                }
            })
            webSocketTask?.resume()
            
            startPingTimer()
            
        } catch {
            connectionState = .failed(error)
            attemptReconnect()
        }
    }
    
    /// Disconnect from WebSocket server
    func disconnect() {
        stopPingTimer()
        stopReconnectTimer()
        
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        
        connectionState = .disconnected
        eventSubject.send(.disconnected)
    }
    
    /// Reconnect to WebSocket server
    func reconnect() {
        disconnect()
        Task {
            await connect()
        }
    }
    
    // MARK: - Message Handling
    
    private func handleReceiveResult(_ result: Result<URLSessionWebSocketTask.Message, Error>) {
        switch result {
        case .success(let message):
            handleMessage(message)
            // Continue receiving
            webSocketTask?.receive(completionHandler: { [weak self] result in
                Task { @MainActor [weak self] in
                    self?.handleReceiveResult(result)
                }
            })
            
        case .failure(let error):
            handleError(error)
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleTextMessage(text)
        case .data(let data):
            handleBinaryMessage(data)
        @unknown default:
            break
        }
    }
    
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
            
            // Handle ping/pong internally
            if message.type == .ping {
                sendPong()
                return
            }
            
            eventSubject.send(.message(message))
            
        } catch {
            print("⚠️ Failed to decode WebSocket message: \(error)")
        }
    }
    
    private func handleBinaryMessage(_ data: Data) {
        // Handle binary data if needed
        print("📦 Received binary data: \(data.count) bytes")
    }
    
    private func handleError(_ error: Error) {
        lastError = error
        connectionState = .failed(error)
        eventSubject.send(.error(error))
        attemptReconnect()
    }
    
    // MARK: - Send Messages
    
    /// Send a message to the server
    func send(_ message: WebSocketMessage) {
        guard isConnected else {
            print("⚠️ Cannot send message: WebSocket not connected")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            let message = URLSessionWebSocketTask.Message.data(data)
            webSocketTask?.send(message) { [weak self] error in
                if let error = error {
                    Task { @MainActor [weak self] in
                        self?.handleError(error)
                    }
                }
            }
        } catch {
            print("⚠️ Failed to encode message: \(error)")
        }
    }
    
    /// Send text message
    func send(text: String) {
        guard isConnected else { return }
        
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                Task { @MainActor [weak self] in
                    self?.handleError(error)
                }
            }
        }
    }
    
    /// Send subscription request for sketchbook updates
    func subscribeToSketchbook(_ sketchbookId: Int) {
        let message = WebSocketMessage(
            id: UUID().uuidString,
            type: .notification,
            payload: MessagePayload(
                sketchbookId: sketchbookId,
                postId: nil,
                userId: AuthManager.shared.userId,
                data: ["action": "subscribe", "sketchbook_id": "\(sketchbookId)"]
            ),
            timestamp: Date()
        )
        send(message)
    }
    
    /// Unsubscribe from sketchbook updates
    func unsubscribeFromSketchbook(_ sketchbookId: Int) {
        let message = WebSocketMessage(
            id: UUID().uuidString,
            type: .notification,
            payload: MessagePayload(
                sketchbookId: sketchbookId,
                postId: nil,
                userId: AuthManager.shared.userId,
                data: ["action": "unsubscribe", "sketchbook_id": "\(sketchbookId)"]
            ),
            timestamp: Date()
        )
        send(message)
    }
    
    private func sendPong() {
        let message = WebSocketMessage(
            id: UUID().uuidString,
            type: .pong,
            payload: MessagePayload(sketchbookId: nil, postId: nil, userId: nil, data: nil),
            timestamp: Date()
        )
        send(message)
    }
    
    // MARK: - Reconnection
    
    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("❌ Max reconnect attempts reached")
            return
        }
        
        reconnectAttempts += 1
        let delay = min(Double(reconnectAttempts) * 2.0, 30.0) // Exponential backoff, max 30s
        
        print("🔄 Reconnecting in \(delay)s... (attempt \(reconnectAttempts)/\(maxReconnectAttempts))")
        
        // Use a detached timer that can call back to MainActor
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.connect()
            }
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        reconnectAttempts = 0
    }
    
    // MARK: - Ping/Pong
    
    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.sendPing()
            }
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() {
        let message = WebSocketMessage(
            id: UUID().uuidString,
            type: .ping,
            payload: MessagePayload(sketchbookId: nil, postId: nil, userId: nil, data: nil),
            timestamp: Date()
        )
        send(message)
    }
}

// MARK: - Connection State

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(Error)
    
    static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected),
             (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

// MARK: - WebSocket Error

enum WebSocketError: Error, LocalizedError {
    case invalidURL
    case notConnected
    case encodingFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .notConnected:
            return "WebSocket not connected"
        case .encodingFailed:
            return "Failed to encode message"
        case .decodingFailed:
            return "Failed to decode message"
        }
    }
}
