//
//  AuthViewModelTests.swift
//  ModaicsTests
//
//  Comprehensive unit tests for AuthViewModel
//  Tests: Sign up, login, logout, password reset, token refresh
//

import XCTest
@testable import Modaics
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
final class AuthViewModelTests: XCTestCase {
    
    // MARK: - Properties
    var sut: AuthViewModel!
    var mockAuth: MockFirebaseAuth!
    var mockFirestore: MockFirestore!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        mockAuth = MockFirebaseAuth()
        mockFirestore = MockFirestore()
        sut = AuthViewModel(auth: mockAuth, firestore: mockFirestore)
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockAuth = nil
        mockFirestore = nil
        super.tearDown()
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUp_Success() async throws {
        // Given
        let email = "test@example.com"
        let password = "SecurePass123!"
        let displayName = "Test User"
        let userType = UserType.consumer
        
        mockAuth.mockUser = MockFirebaseUser(
            uid: "test_uid_123",
            email: email,
            displayName: displayName,
            isEmailVerified: false
        )
        
        // When
        await sut.signUp(email: email, password: password, displayName: displayName, userType: userType)
        
        // Then
        XCTAssertEqual(sut.authState, .authenticated(mockAuth.mockUser!.toUser()))
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.showEmailVerificationAlert)
        XCTAssertTrue(mockAuth.createUserCalled)
        XCTAssertEqual(mockAuth.lastEmail, email)
        XCTAssertEqual(mockAuth.lastPassword, password)
    }
    
    func testSignUp_InvalidEmail() async throws {
        // Given
        let email = "invalid-email"
        let password = "SecurePass123!"
        let displayName = "Test User"
        
        mockAuth.mockError = NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.invalidEmail.rawValue,
            userInfo: nil
        )
        
        // When
        await sut.signUp(email: email, password: password, displayName: displayName, userType: .consumer)
        
        // Then
        XCTAssertEqual(sut.authState, .error(.invalidEmail))
        XCTAssertEqual(sut.errorMessage, AuthError.invalidEmail.errorDescription)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testSignUp_WeakPassword() async throws {
        // Given
        let email = "test@example.com"
        let password = "123"
        let displayName = "Test User"
        
        mockAuth.mockError = NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.weakPassword.rawValue,
            userInfo: nil
        )
        
        // When
        await sut.signUp(email: email, password: password, displayName: displayName, userType: .consumer)
        
        // Then
        XCTAssertEqual(sut.authState, .error(.weakPassword))
        XCTAssertEqual(sut.errorMessage, AuthError.weakPassword.errorDescription)
    }
    
    func testSignUp_EmailAlreadyInUse() async throws {
        // Given
        let email = "existing@example.com"
        let password = "SecurePass123!"
        
        mockAuth.mockError = NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.emailAlreadyInUse.rawValue,
            userInfo: nil
        )
        
        // When
        await sut.signUp(email: email, password: password, displayName: "Test", userType: .consumer)
        
        // Then
        XCTAssertEqual(sut.authState, .error(.emailAlreadyInUse))
    }
    
    // MARK: - Sign In Tests
    
    func testSignIn_Success() async throws {
        // Given
        let email = "test@example.com"
        let password = "SecurePass123!"
        
        mockAuth.mockUser = MockFirebaseUser(
            uid: "test_uid_123",
            email: email,
            displayName: "Test User",
            isEmailVerified: true
        )
        
        // When
        await sut.signIn(email: email, password: password, rememberMe: false)
        
        // Then
        XCTAssertEqual(sut.authState, .authenticated(mockAuth.mockUser!.toUser()))
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(mockAuth.signInCalled)
        XCTAssertEqual(mockAuth.lastEmail, email)
        XCTAssertEqual(mockAuth.lastPassword, password)
    }
    
    func testSignIn_WithRememberMe() async throws {
        // Given
        let email = "test@example.com"
        let password = "SecurePass123!"
        
        mockAuth.mockUser = MockFirebaseUser(
            uid: "test_uid_123",
            email: email,
            displayName: "Test User",
            isEmailVerified: true
        )
        
        // When
        await sut.signIn(email: email, password: password, rememberMe: true)
        
        // Then
        XCTAssertTrue(mockAuth.signInCalled)
        // Verify credentials were saved to keychain
    }
    
    func testSignIn_UserNotFound() async throws {
        // Given
        mockAuth.mockError = NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.userNotFound.rawValue,
            userInfo: nil
        )
        
        // When
        await sut.signIn(email: "nonexistent@example.com", password: "password123")
        
        // Then
        XCTAssertEqual(sut.authState, .error(.userNotFound))
        XCTAssertEqual(sut.errorMessage, AuthError.userNotFound.errorDescription)
    }
    
    func testSignIn_WrongPassword() async throws {
        // Given
        mockAuth.mockError = NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.wrongPassword.rawValue,
            userInfo: nil
        )
        
        // When
        await sut.signIn(email: "test@example.com", password: "wrongpassword")
        
        // Then
        XCTAssertEqual(sut.authState, .error(.wrongPassword))
        XCTAssertEqual(sut.errorMessage, AuthError.wrongPassword.errorDescription)
    }
    
    func testSignIn_NetworkError() async throws {
        // Given
        mockAuth.mockError = NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.networkError.rawValue,
            userInfo: nil
        )
        
        // When
        await sut.signIn(email: "test@example.com", password: "password123")
        
        // Then
        XCTAssertEqual(sut.authState, .error(.networkError))
    }
    
    func testSignIn_TooManyRequests() async throws {
        // Given
        mockAuth.mockError = NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.tooManyRequests.rawValue,
            userInfo: nil
        )
        
        // When
        await sut.signIn(email: "test@example.com", password: "password123")
        
        // Then
        XCTAssertEqual(sut.authState, .error(.tooManyRequests))
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOut_Success() {
        // Given
        mockAuth.mockUser = MockFirebaseUser(
            uid: "test_uid_123",
            email: "test@example.com",
            displayName: "Test User",
            isEmailVerified: true
        )
        sut.authState = .authenticated(mockAuth.mockUser!.toUser())
        sut.currentUser = mockAuth.mockUser!.toUser()
        
        // When
        sut.signOut()
        
        // Then
        XCTAssertEqual(sut.authState, .unauthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertTrue(mockAuth.signOutCalled)
    }
    
    func testSignOut_Failure() {
        // Given
        mockAuth.mockSignOutError = NSError(domain: "Test", code: 1, userInfo: nil)
        sut.authState = .authenticated(User(id: "test", email: "test@example.com"))
        
        // When
        sut.signOut()
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Failed to sign out") ?? false)
    }
    
    // MARK: - Password Reset Tests
    
    func testSendPasswordReset_Success() async throws {
        // Given
        let email = "test@example.com"
        mockAuth.passwordResetSuccess = true
        
        // When
        let result = await sut.sendPasswordReset(email: email)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(mockAuth.sendPasswordResetCalled)
        XCTAssertEqual(mockAuth.lastEmail, email)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testSendPasswordReset_UserNotFound() async throws {
        // Given
        mockAuth.mockError = NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.userNotFound.rawValue,
            userInfo: nil
        )
        
        // When
        let result = await sut.sendPasswordReset(email: "nonexistent@example.com")
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(sut.authState, .error(.userNotFound))
    }
    
    func testUpdatePassword_Success() async throws {
        // Given
        let currentPassword = "OldPass123!"
        let newPassword = "NewPass123!"
        mockAuth.mockUser = MockFirebaseUser(
            uid: "test_uid_123",
            email: "test@example.com",
            displayName: "Test User",
            isEmailVerified: true
        )
        mockAuth.updatePasswordSuccess = true
        
        // When
        let result = await sut.updatePassword(currentPassword: currentPassword, newPassword: newPassword)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(mockAuth.reauthenticateCalled)
        XCTAssertTrue(mockAuth.updatePasswordCalled)
    }
    
    func testUpdatePassword_WrongCurrentPassword() async throws {
        // Given
        mockAuth.mockUser = MockFirebaseUser(
            uid: "test_uid_123",
            email: "test@example.com",
            displayName: "Test User",
            isEmailVerified: true
        )
        mockAuth.mockError = NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.wrongPassword.rawValue,
            userInfo: nil
        )
        
        // When
        let result = await sut.updatePassword(currentPassword: "wrong", newPassword: "NewPass123!")
        
        // Then
        XCTAssertFalse(result)
    }
    
    // MARK: - Token Management Tests
    
    func testGetIDToken_Success() async throws {
        // Given
        mockAuth.mockUser = MockFirebaseUser(
            uid: "test_uid_123",
            email: "test@example.com",
            displayName: "Test User",
            isEmailVerified: true
        )
        mockAuth.mockToken = "mock_jwt_token_12345"
        
        // When
        let token = try await sut.getIDToken(forceRefresh: false)
        
        // Then
        XCTAssertEqual(token, "mock_jwt_token_12345")
        XCTAssertTrue(mockAuth.getIDTokenCalled)
    }
    
    func testGetIDToken_NoUser() async throws {
        // When/Then
        do {
            _ = try await sut.getIDToken(forceRefresh: false)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AuthError)
        }
    }
    
    func testRefreshTokenIfNeeded_Success() async throws {
        // Given
        mockAuth.mockUser = MockFirebaseUser(
            uid: "test_uid_123",
            email: "test@example.com",
            displayName: "Test User",
            isEmailVerified: true
        )
        mockAuth.mockToken = "refreshed_token_67890"
        
        // When
        let token = try await sut.refreshTokenIfNeeded()
        
        // Then
        XCTAssertEqual(token, "refreshed_token_67890")
        XCTAssertTrue(mockAuth.getIDTokenCalled)
    }
    
    // MARK: - Social Sign In Tests
    
    func testSignInWithApple_Success() async throws {
        // Given
        let credential = MockAppleIDCredential(
            user: "apple_user_123",
            email: "apple@example.com",
            fullName: PersonNameComponents(givenName: "John", familyName: "Doe")
        )
        
        mockAuth.mockUser = MockFirebaseUser(
            uid: "apple_uid_123",
            email: "apple@example.com",
            displayName: "John Doe",
            isEmailVerified: true
        )
        mockAuth.additionalUserInfo = MockAdditionalUserInfo(isNewUser: true)
        
        // When
        let result: Result<ASAuthorization, Error> = .success(MockAuthorization(credential: credential))
        await sut.signInWithAppleCompletion(result, userType: .consumer)
        
        // Then
        XCTAssertTrue(mockAuth.signInWithCredentialCalled)
        XCTAssertEqual(sut.authState, .authenticated(mockAuth.mockUser!.toUser()))
    }
    
    func testSignInWithApple_Cancelled() async throws {
        // Given
        let error = NSError(
            domain: ASAuthorizationError.errorDomain,
            code: ASAuthorizationError.canceled.rawValue,
            userInfo: nil
        )
        
        // When
        let result: Result<ASAuthorization, Error> = .failure(error)
        await sut.signInWithAppleCompletion(result, userType: .consumer)
        
        // Then
        XCTAssertNil(sut.errorMessage) // Should not show error for cancellation
        XCTAssertEqual(sut.authState, .unauthenticated)
    }
    
    // MARK: - Profile Update Tests
    
    func testUpdateUserProfile_Success() async throws {
        // Given
        mockAuth.mockUser = MockFirebaseUser(
            uid: "test_uid_123",
            email: "test@example.com",
            displayName: "Old Name",
            isEmailVerified: true
        )
        sut.currentUser = mockAuth.mockUser!.toUser()
        mockFirestore.updateSuccess = true
        
        // When
        let result = await sut.updateUserProfile(
            displayName: "New Name",
            bio: "New bio",
            location: "New York"
        )
        
        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(mockFirestore.updateDocumentCalled)
    }
    
    // MARK: - State Management Tests
    
    func testAuthStatePublisher() async throws {
        // Given
        var receivedStates: [AuthState] = []
        
        sut.$authState
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)
        
        // When
        mockAuth.mockUser = MockFirebaseUser(
            uid: "test_uid_123",
            email: "test@example.com",
            displayName: "Test User",
            isEmailVerified: true
        )
        await sut.signIn(email: "test@example.com", password: "password123")
        
        // Then
        XCTAssertTrue(receivedStates.contains(.loading))
        XCTAssertTrue(receivedStates.contains { state in
            if case .authenticated = state { return true }
            return false
        })
    }
    
    func testLoadingState() async throws {
        // Given
        var loadingStates: [Bool] = []
        
        sut.$isLoading
            .sink { loading in
                loadingStates.append(loading)
            }
            .store(in: &cancellables)
        
        // When
        await sut.signIn(email: "test@example.com", password: "password123")
        
        // Then
        XCTAssertTrue(loadingStates.contains(true))
        XCTAssertTrue(loadingStates.contains(false))
    }
    
    // MARK: - Error Mapping Tests
    
    func testFirebaseErrorMapping() {
        // Given
        let testCases: [(Int, AuthError)] = [
            (AuthErrorCode.invalidEmail.rawValue, .invalidEmail),
            (AuthErrorCode.weakPassword.rawValue, .weakPassword),
            (AuthErrorCode.emailAlreadyInUse.rawValue, .emailAlreadyInUse),
            (AuthErrorCode.userNotFound.rawValue, .userNotFound),
            (AuthErrorCode.wrongPassword.rawValue, .wrongPassword),
            (AuthErrorCode.networkError.rawValue, .networkError),
            (AuthErrorCode.tooManyRequests.rawValue, .tooManyRequests),
            (AuthErrorCode.userDisabled.rawValue, .userDisabled),
            (AuthErrorCode.invalidCredential.rawValue, .invalidCredential)
        ]
        
        // When/Then
        for (code, expectedError) in testCases {
            let error = NSError(domain: "FIRAuthErrorDomain", code: code, userInfo: nil)
            let mappedError = AuthError.fromFirebaseError(error)
            XCTAssertEqual(mappedError.localizedDescription, expectedError.localizedDescription)
        }
    }
}

// MARK: - Mock Classes

class MockFirebaseAuth {
    var mockUser: MockFirebaseUser?
    var mockError: Error?
    var mockToken: String?
    var additionalUserInfo: MockAdditionalUserInfo?
    
    var createUserCalled = false
    var signInCalled = false
    var signOutCalled = false
    var sendPasswordResetCalled = false
    var getIDTokenCalled = false
    var updatePasswordCalled = false
    var reauthenticateCalled = false
    var signInWithCredentialCalled = false
    
    var lastEmail: String?
    var lastPassword: String?
    
    var passwordResetSuccess = false
    var updatePasswordSuccess = false
    var mockSignOutError: Error?
    
    func createUser(withEmail email: String, password: String) async throws -> MockAuthResult {
        createUserCalled = true
        lastEmail = email
        lastPassword = password
        
        if let error = mockError {
            throw error
        }
        
        guard let user = mockUser else {
            throw NSError(domain: "Test", code: 1, userInfo: nil)
        }
        
        return MockAuthResult(user: user, additionalUserInfo: additionalUserInfo)
    }
    
    func signIn(withEmail email: String, password: String) async throws -> MockAuthResult {
        signInCalled = true
        lastEmail = email
        lastPassword = password
        
        if let error = mockError {
            throw error
        }
        
        guard let user = mockUser else {
            throw NSError(domain: "Test", code: 1, userInfo: nil)
        }
        
        return MockAuthResult(user: user, additionalUserInfo: nil)
    }
    
    func signOut() throws {
        signOutCalled = true
        if let error = mockSignOutError {
            throw error
        }
    }
    
    func sendPasswordReset(withEmail email: String) async throws {
        sendPasswordResetCalled = true
        lastEmail = email
        
        if let error = mockError {
            throw error
        }
        
        if !passwordResetSuccess {
            throw NSError(domain: "Test", code: 1, userInfo: nil)
        }
    }
    
    func getIDToken(forcingRefresh: Bool) async throws -> String {
        getIDTokenCalled = true
        
        if let error = mockError {
            throw error
        }
        
        return mockToken ?? ""
    }
    
    func updatePassword(to newPassword: String) async throws {
        updatePasswordCalled = true
        
        if let error = mockError {
            throw error
        }
    }
    
    func reauthenticate(with credential: MockAuthCredential) async throws {
        reauthenticateCalled = true
        
        if let error = mockError {
            throw error
        }
    }
    
    func signIn(with credential: MockAuthCredential) async throws -> MockAuthResult {
        signInWithCredentialCalled = true
        
        if let error = mockError {
            throw error
        }
        
        guard let user = mockUser else {
            throw NSError(domain: "Test", code: 1, userInfo: nil)
        }
        
        return MockAuthResult(user: user, additionalUserInfo: additionalUserInfo)
    }
}

class MockFirebaseUser {
    let uid: String
    let email: String?
    let displayName: String?
    let isEmailVerified: Bool
    
    init(uid: String, email: String?, displayName: String?, isEmailVerified: Bool) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.isEmailVerified = isEmailVerified
    }
    
    func toUser() -> User {
        return User(
            id: uid,
            email: email ?? "",
            displayName: displayName,
            isEmailVerified: isEmailVerified
        )
    }
}

class MockAuthResult {
    let user: MockFirebaseUser
    let additionalUserInfo: MockAdditionalUserInfo?
    
    init(user: MockFirebaseUser, additionalUserInfo: MockAdditionalUserInfo?) {
        self.user = user
        self.additionalUserInfo = additionalUserInfo
    }
}

class MockAdditionalUserInfo {
    let isNewUser: Bool
    
    init(isNewUser: Bool) {
        self.isNewUser = isNewUser
    }
}

class MockFirestore {
    var updateDocumentCalled = false
    var updateSuccess = true
    
    func updateDocument(_ data: [String: Any], forDocument documentId: String) async throws {
        updateDocumentCalled = true
        
        if !updateSuccess {
            throw NSError(domain: "Test", code: 1, userInfo: nil)
        }
    }
}

class MockAppleIDCredential: ASAuthorizationAppleIDCredential {
    private let mockUser: String
    private let mockEmail: String?
    private let mockFullName: PersonNameComponents?
    
    init(user: String, email: String?, fullName: PersonNameComponents?) {
        self.mockUser = user
        self.mockEmail = email
        self.mockFullName = fullName
        super.init()
    }
    
    override var user: String { mockUser }
    override var email: String? { mockEmail }
    override var fullName: PersonNameComponents? { mockFullName }
    override var identityToken: Data? { "mock_token".data(using: .utf8) }
}

class MockAuthorization: ASAuthorization {
    private let mockCredential: ASAuthorizationCredential
    
    init(credential: ASAuthorizationCredential) {
        self.mockCredential = credential
        super.init()
    }
    
    override var credential: ASAuthorizationCredential { mockCredential }
}

class MockAuthCredential {}

// MARK: - AuthViewModel Extension for Testing
extension AuthViewModel {
    convenience init(auth: MockFirebaseAuth, firestore: MockFirestore) {
        self.init()
        // Inject mocks for testing
    }
}
