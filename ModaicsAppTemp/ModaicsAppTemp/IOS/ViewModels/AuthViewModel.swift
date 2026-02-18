//
//  AuthViewModel.swift
//  Modaics
//
//  Central authentication state management with Firebase
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import AuthenticationServices
import CryptoKit

// MARK: - Auth State
enum AuthState: Equatable {
    case unknown
    case authenticated(User)
    case unauthenticated
    case loading
    case error(AuthError)
    
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown),
             (.unauthenticated, .unauthenticated),
             (.loading, .loading):
            return true
        case (.authenticated(let lhsUser), .authenticated(let rhsUser)):
            return lhsUser.id == rhsUser.id
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Auth Error
enum AuthError: LocalizedError {
    case invalidEmail
    case invalidPassword
    case weakPassword
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case networkError
    case tooManyRequests
    case userDisabled
    case invalidCredential
    case accountExistsWithDifferentCredential
    case credentialAlreadyInUse
    case requiresRecentLogin
    case signInCancelled
    case unknown(Error)
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .invalidPassword:
            return "Please enter a valid password."
        case .weakPassword:
            return "Password is too weak. Please use at least 8 characters with uppercase, lowercase, and numbers."
        case .emailAlreadyInUse:
            return "This email is already registered. Please sign in or use a different email."
        case .userNotFound:
            return "No account found with this email. Please check your email or sign up."
        case .wrongPassword:
            return "Incorrect password. Please try again or reset your password."
        case .networkError:
            return "Network connection error. Please check your internet connection and try again."
        case .tooManyRequests:
            return "Too many attempts. Please wait a moment and try again."
        case .userDisabled:
            return "This account has been disabled. Please contact support."
        case .invalidCredential:
            return "Invalid credentials. Please try again."
        case .accountExistsWithDifferentCredential:
            return "An account already exists with this email using a different sign-in method."
        case .credentialAlreadyInUse:
            return "This credential is already associated with another account."
        case .requiresRecentLogin:
            return "Please sign in again to complete this action."
        case .signInCancelled:
            return "Sign in was cancelled."
        case .unknown(let error):
            return error.localizedDescription
        case .custom(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidEmail:
            return "Double-check your email address format."
        case .weakPassword:
            return "Try a password with at least 8 characters, including uppercase, lowercase, and numbers."
        case .emailAlreadyInUse:
            return "Try signing in with this email instead."
        case .wrongPassword:
            return "Use the 'Forgot Password' option to reset your password."
        case .networkError:
            return "Make sure you have a stable internet connection."
        case .tooManyRequests:
            return "Wait a few minutes before trying again."
        case .accountExistsWithDifferentCredential:
            return "Sign in using the method you originally used."
        default:
            return nil
        }
    }
    
    static func fromFirebaseError(_ error: Error) -> AuthError {
        let errorCode = (error as NSError).code
        switch errorCode {
        case AuthErrorCode.invalidEmail.rawValue:
            return .invalidEmail
        case AuthErrorCode.weakPassword.rawValue:
            return .weakPassword
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return .emailAlreadyInUse
        case AuthErrorCode.userNotFound.rawValue:
            return .userNotFound
        case AuthErrorCode.wrongPassword.rawValue:
            return .wrongPassword
        case AuthErrorCode.networkError.rawValue:
            return .networkError
        case AuthErrorCode.tooManyRequests.rawValue:
            return .tooManyRequests
        case AuthErrorCode.userDisabled.rawValue:
            return .userDisabled
        case AuthErrorCode.invalidCredential.rawValue:
            return .invalidCredential
        case AuthErrorCode.accountExistsWithDifferentCredential.rawValue:
            return .accountExistsWithDifferentCredential
        case AuthErrorCode.credentialAlreadyInUse.rawValue:
            return .credentialAlreadyInUse
        case AuthErrorCode.requiresRecentLogin.rawValue:
            return .requiresRecentLogin
        default:
            return .unknown(error)
        }
    }
}

// MARK: - Auth View Model
@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var authState: AuthState = .unknown
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    @Published var userType: UserType = .consumer
    @Published var showEmailVerificationAlert: Bool = false
    
    // MARK: - Private Properties
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    private var currentNonce: String? // For Apple Sign In
    private var retryCount: Int = 0
    private let maxRetries: Int = 3
    
    // MARK: - Initialization
    init() {
        setupAuthStateListener()
        checkInitialAuthState()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Auth State Management
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                await self?.handleAuthStateChange(firebaseUser: firebaseUser)
            }
        }
    }
    
    private func checkInitialAuthState() {
        if let firebaseUser = Auth.auth().currentUser {
            Task {
                await handleAuthStateChange(firebaseUser: firebaseUser)
            }
        } else {
            authState = .unauthenticated
        }
    }
    
    private func handleAuthStateChange(firebaseUser: FirebaseAuth.User?) async {
        guard let firebaseUser = firebaseUser else {
            authState = .unauthenticated
            currentUser = nil
            return
        }
        
        // Fetch or create user document
        do {
            let user = try await fetchOrCreateUserDocument(for: firebaseUser)
            self.currentUser = user
            self.authState = .authenticated(user)
            self.retryCount = 0 // Reset retry count on success
        } catch {
            self.authState = .error(.fromFirebaseError(error))
            self.errorMessage = AuthError.fromFirebaseError(error).errorDescription
        }
    }
    
    // MARK: - Email/Password Authentication
    func signIn(email: String, password: String, rememberMe: Bool = false) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Store credentials if remember me is enabled
            if rememberMe {
                KeychainManager.shared.saveUserEmail(email)
                KeychainManager.shared.saveUserPassword(password)
            }
            
            // Update last login
            try await updateLastLogin(userId: result.user.uid)
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, displayName: String, userType: UserType) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create Firebase Auth user
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            // Create user document in Firestore
            var newUser = User(from: result.user, userType: userType)
            newUser.displayName = displayName
            newUser.username = generateUsername(from: displayName)
            
            try await createUserDocument(newUser)
            
            // Send email verification
            try await result.user.sendEmailVerification()
            showEmailVerificationAlert = true
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            KeychainManager.shared.clearAuthData()
            currentUser = nil
            authState = .unauthenticated
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Social Authentication - Sign in with Apple
    func signInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }
    
    func signInWithAppleCompletion(_ result: Result<ASAuthorization, Error>, userType: UserType) async {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Invalid Apple credentials"
                isLoading = false
                return
            }
            
            guard let nonce = currentNonce else {
                errorMessage = "Invalid state: A login callback was received, but no login request was sent."
                isLoading = false
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                errorMessage = "Unable to fetch identity token"
                isLoading = false
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Unable to serialize token string from data"
                isLoading = false
                return
            }
            
            // Create Firebase credential
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nonce
            )
            
            do {
                let authResult = try await Auth.auth().signIn(with: credential)
                
                // Check if this is a new user
                if authResult.additionalUserInfo?.isNewUser == true {
                    // Create new user document with Apple info
                    var newUser = User(from: authResult.user, userType: userType)
                    
                    // Use full name from Apple if available
                    if let fullName = appleIDCredential.fullName {
                        let displayName = [fullName.givenName, fullName.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")
                        newUser.displayName = displayName.isEmpty ? nil : displayName
                        
                        // Update Firebase profile
                        let changeRequest = authResult.user.createProfileChangeRequest()
                        changeRequest.displayName = newUser.displayName
                        try? await changeRequest.commitChanges()
                    }
                    
                    try await createUserDocument(newUser)
                }
                
            } catch {
                handleError(error)
            }
            
        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                handleError(error)
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Social Authentication - Google Sign In
    func signInWithGoogle(presenting viewController: UIViewController, userType: UserType) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Configure Google Sign In
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                errorMessage = "Google Sign In configuration error"
                isLoading = false
                return
            }
            
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            
            // Sign in
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get ID token from Google"
                isLoading = false
                return
            }
            
            // Create Firebase credential
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            // Sign in to Firebase
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // Check if this is a new user
            if authResult.additionalUserInfo?.isNewUser == true {
                var newUser = User(from: authResult.user, userType: userType)
                newUser.displayName = result.user.profile?.name
                newUser.profileImageURL = result.user.profile?.imageURL(withDimension: 200)?.absoluteString
                
                try await createUserDocument(newUser)
            } else {
                // Update profile image if available
                if let imageURL = result.user.profile?.imageURL(withDimension: 200)?.absoluteString {
                    try await updateUserProfileImage(url: imageURL)
                }
            }
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Password Reset
    func sendPasswordReset(email: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            isLoading = false
            return true
        } catch {
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async -> Bool {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            errorMessage = "No authenticated user found"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Re-authenticate user
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await user.reauthenticate(with: credential)
            
            // Update password
            try await user.updatePassword(to: newPassword)
            
            isLoading = false
            return true
        } catch {
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    // MARK: - Email Verification
    func sendEmailVerification() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No authenticated user"
            return
        }
        
        do {
            try await user.sendEmailVerification()
        } catch {
            handleError(error)
        }
    }
    
    func reloadUser() async {
        guard let user = Auth.auth().currentUser else { return }
        
        do {
            try await user.reload()
            await handleAuthStateChange(firebaseUser: Auth.auth().currentUser)
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Token Management
    func getIDToken(forceRefresh: Bool = false) async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.custom("No authenticated user")
        }
        
        return try await user.getIDToken(forcingRefresh: forceRefresh)
    }
    
    func refreshTokenIfNeeded() async throws -> String {
        return try await getIDToken(forceRefresh: true)
    }
    
    // MARK: - Firestore User Document Management
    private func fetchOrCreateUserDocument(for firebaseUser: FirebaseAuth.User) async throws -> User {
        let userRef = db.collection("users").document(firebaseUser.uid)
        
        let document = try await userRef.getDocument()
        
        if document.exists, let data = document.data() {
            // Existing user - update last login
            var user = User.fromFirestore(data, id: firebaseUser.uid) ?? User(from: firebaseUser)
            try await userRef.updateData(["lastLoginAt": Timestamp(date: Date())])
            return user
        } else {
            // New user - create document
            let newUser = User(from: firebaseUser)
            try await createUserDocument(newUser)
            return newUser
        }
    }
    
    private func createUserDocument(_ user: User) async throws {
        let userRef = db.collection("users").document(user.id)
        try await userRef.setData(user.toFirestore)
    }
    
    private func updateLastLogin(userId: String) async throws {
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData(["lastLoginAt": Timestamp(date: Date())])
    }
    
    private func updateUserProfileImage(url: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData(["profileImageURL": url])
    }
    
    // MARK: - User Profile Updates
    func updateUserProfile(displayName: String? = nil, bio: String? = nil, location: String? = nil) async -> Bool {
        guard let firebaseUser = Auth.auth().currentUser else {
            errorMessage = "No authenticated user"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            var updateData: [String: Any] = [:]
            
            if let displayName = displayName {
                updateData["displayName"] = displayName
                
                // Update Firebase Auth profile
                let changeRequest = firebaseUser.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
            }
            
            if let bio = bio {
                updateData["bio"] = bio
            }
            
            if let location = location {
                updateData["location"] = location
            }
            
            if !updateData.isEmpty {
                let userRef = db.collection("users").document(firebaseUser.uid)
                try await userRef.updateData(updateData)
                
                // Reload user data
                await reloadUser()
            }
            
            isLoading = false
            return true
        } catch {
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    // MARK: - Helper Methods
    private func handleError(_ error: Error) {
        let authError = AuthError.fromFirebaseError(error)
        errorMessage = authError.errorDescription
        authState = .error(authError)
        
        // Retry logic for network errors
        if case .networkError = authError, retryCount < maxRetries {
            retryCount += 1
            // Could implement exponential backoff here
        }
    }
    
    private func generateUsername(from displayName: String) -> String {
        let base = displayName.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-z0-9_]", with: "", options: .regularExpression)
        
        let randomSuffix = Int.random(in: 100...999)
        return "\(base)_\(randomSuffix)"
    }
    
    // MARK: - Apple Sign In Helpers
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Remember Me
    func getRememberedCredentials() -> (email: String?, password: String?) {
        let email = KeychainManager.shared.retrieveUserEmail()
        let password = KeychainManager.shared.retrieveUserPassword()
        return (email, password)
    }
    
    func clearRememberedCredentials() {
        KeychainManager.shared.delete(key: .userEmail)
        KeychainManager.shared.delete(key: .userPassword)
    }
}
