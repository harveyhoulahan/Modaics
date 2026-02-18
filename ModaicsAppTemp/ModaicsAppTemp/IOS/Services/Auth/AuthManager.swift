//
//  AuthManager.swift
//  Modaics
//
//  Firebase Authentication token management
//  Handles Bearer token refresh and storage
//

import Foundation
import FirebaseAuth
import Combine

// MARK: - Auth Manager
// Note: AuthState enum is defined in AuthViewModel.swift

@MainActor
class AuthManager: ObservableObject {
    
    // MARK: - Shared Instance
    
    static let shared = AuthManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var state: AuthState = .unknown
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: Error?
    
    // MARK: - Private Properties
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var currentToken: String?
    private var tokenExpirationDate: Date?
    private let tokenRefreshInterval: TimeInterval = 3000 // Refresh 5 minutes before expiry ( Firebase tokens last 1 hour)
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
    // MARK: - Auth State Listener
    
    private func setupAuthStateListener() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    self?.state = .authenticated(user)
                    // Pre-fetch token on auth change
                    await self?.refreshTokenIfNeeded()
                } else {
                    self?.state = .unauthenticated
                    self?.currentToken = nil
                    self?.tokenExpirationDate = nil
                }
            }
        }
    }
    
    // MARK: - Token Management
    
    /// Get valid Bearer token for API requests
    func getValidToken() async throws -> String {
        // Check if we have a cached token that's still valid
        if let token = currentToken,
           let expiration = tokenExpirationDate,
           Date() < expiration.addingTimeInterval(-300) { // 5 min buffer
            return token
        }
        
        // Need to refresh
        return try await refreshToken()
    }
    
    /// Force refresh the Firebase token
    func refreshToken() async throws -> String {
        guard case .authenticated(let user) = state else {
            throw AuthError.notAuthenticated
        }
        
        do {
            let token = try await user.getIDTokenResult(forcingRefresh: true)
            currentToken = token.token
            tokenExpirationDate = token.expirationDate
            
            // Notify listeners
            NotificationCenter.default.post(name: .apiAuthTokenRefreshed, object: nil)
            
            return token.token
        } catch {
            throw AuthError.tokenRefreshFailed(error)
        }
    }
    
    /// Refresh token if it's about to expire
    private func refreshTokenIfNeeded() async {
        guard case .authenticated = state else { return }
        
        if currentToken == nil ||
           tokenExpirationDate == nil ||
           Date() > tokenExpirationDate!.addingTimeInterval(-tokenRefreshInterval) {
            do {
                _ = try await refreshToken()
            } catch {
                print("⚠️ Token refresh failed: \(error)")
            }
        }
    }
    
    // MARK: - Current User Info
    
    var currentUser: User? {
        if case .authenticated(let user) = state {
            return user
        }
        return nil
    }
    
    var userId: String? {
        currentUser?.uid
    }
    
    var userEmail: String? {
        currentUser?.email
    }
    
    var displayName: String? {
        currentUser?.displayName
    }
    
    var photoURL: URL? {
        currentUser?.photoURL
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            currentToken = nil
            tokenExpirationDate = nil
            state = .unauthenticated
        } catch {
            throw AuthError.signOutFailed(error)
        }
    }
    
    // MARK: - Anonymous Auth (for testing)
    
    func signInAnonymously() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().signInAnonymously()
            state = .authenticated(result.user)
        } catch {
            lastError = error
            throw AuthError.anonymousSignInFailed(error)
        }
    }
}

// MARK: - Auth Errors

enum AuthError: Error, LocalizedError {
    case notAuthenticated
    case tokenRefreshFailed(Error)
    case signOutFailed(Error)
    case anonymousSignInFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please sign in."
        case .tokenRefreshFailed(let error):
            return "Failed to refresh authentication: \(error.localizedDescription)"
        case .signOutFailed(let error):
            return "Failed to sign out: \(error.localizedDescription)"
        case .anonymousSignInFailed(let error):
            return "Anonymous sign in failed: \(error.localizedDescription)"
        }
    }
}
