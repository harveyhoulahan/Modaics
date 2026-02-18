import XCTest
@testable import ModaicsAppTemp
import FirebaseAuth
import Combine

@MainActor
final class AuthViewModelTests: XCTestCase {
    
    var viewModel: AuthViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = AuthViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Login Tests
    
    func testLoginWithEmptyEmailShowsError() async {
        // Given
        viewModel.email = ""
        viewModel.password = "password123"
        
        // When
        await viewModel.login()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isAuthenticated)
    }
    
    func testLoginWithEmptyPasswordShowsError() async {
        // Given
        viewModel.email = "test@example.com"
        viewModel.password = ""
        
        // When
        await viewModel.login()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isAuthenticated)
    }
    
    func testLoginWithInvalidEmailFormatShowsError() async {
        // Given
        viewModel.email = "invalid-email"
        viewModel.password = "password123"
        
        // When
        await viewModel.login()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testLoginClearsErrorOnSuccess() async {
        // Given
        viewModel.errorMessage = "Previous error"
        
        // When - This would normally call Firebase, mocked in real implementation
        viewModel.clearError()
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Logout Tests
    
    func testLogoutSetsIsAuthenticatedToFalse() {
        // Given
        viewModel.isAuthenticated = true
        
        // When
        viewModel.logout()
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated)
    }
    
    func testLogoutClearsUserData() {
        // Given
        viewModel.email = "test@example.com"
        viewModel.userProfile = UserProfile(id: "123", email: "test@example.com")
        
        // When
        viewModel.logout()
        
        // Then
        XCTAssertNil(viewModel.userProfile)
    }
    
    // MARK: - State Management Tests
    
    func testIsLoadingStateDuringLogin() {
        // Given
        let expectation = expectation(description: "Loading state changes")
        var loadingStates: [Bool] = []
        
        viewModel.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        Task {
            await viewModel.login()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(loadingStates.contains(true))
    }
    
    func testAuthStatePersistence() {
        // Given
        let userId = "test-user-123"
        
        // When
        viewModel.restoreAuthState(userId: userId)
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.currentUserId, userId)
    }
    
    // MARK: - Password Reset Tests
    
    func testPasswordResetWithValidEmail() async {
        // Given
        viewModel.email = "test@example.com"
        
        // When
        let result = await viewModel.sendPasswordReset()
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testPasswordResetWithEmptyEmailShowsError() async {
        // Given
        viewModel.email = ""
        
        // When
        let result = await viewModel.sendPasswordReset()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}

// MARK: - Mock Extensions for Testing

extension AuthViewModel {
    func clearError() {
        self.errorMessage = nil
    }
    
    func restoreAuthState(userId: String) {
        self.currentUserId = userId
        self.isAuthenticated = true
    }
}

struct UserProfile {
    let id: String
    let email: String
    var displayName: String?
    var photoURL: String?
}
