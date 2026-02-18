//
//  OnboardingFlowUITests.swift
//  ModaicsUITests
//
//  UI Tests for complete onboarding flow
//  Tests: Splash, Login, Sign Up, Password Reset
//

import XCTest

final class OnboardingFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state"]
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Splash Screen Tests
    
    func testSplashScreen_Appears() {
        // Verify splash screen elements
        let logo = app.images["splashLogo"]
        let tagline = app.staticTexts["sustainableFashionTagline"]
        
        XCTAssertTrue(logo.waitForExistence(timeout: 5))
        XCTAssertTrue(tagline.exists)
        XCTAssertTrue(tagline.label.contains("Sustainable Fashion"))
    }
    
    func testSplashScreen_TransitionsToOnboarding() {
        // Wait for splash to transition
        let getStartedButton = app.buttons["getStartedButton"]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 10))
    }
    
    // MARK: - Welcome Screen Tests
    
    func testWelcomeScreen_Elements() {
        // Navigate to welcome screen
        waitForWelcomeScreen()
        
        // Verify UI elements
        let title = app.staticTexts["welcomeTitle"]
        let subtitle = app.staticTexts["welcomeSubtitle"]
        let signUpButton = app.buttons["signUpButton"]
        let loginButton = app.buttons["loginButton"]
        
        XCTAssertTrue(title.exists)
        XCTAssertTrue(subtitle.exists)
        XCTAssertTrue(signUpButton.exists)
        XCTAssertTrue(loginButton.exists)
    }
    
    func testWelcomeScreen_SignUpNavigation() {
        waitForWelcomeScreen()
        
        let signUpButton = app.buttons["signUpButton"]
        signUpButton.tap()
        
        // Verify navigation to sign up
        let signUpTitle = app.staticTexts["signUpTitle"]
        XCTAssertTrue(signUpTitle.waitForExistence(timeout: 5))
    }
    
    func testWelcomeScreen_LoginNavigation() {
        waitForWelcomeScreen()
        
        let loginButton = app.buttons["loginButton"]
        loginButton.tap()
        
        // Verify navigation to login
        let loginTitle = app.staticTexts["loginTitle"]
        XCTAssertTrue(loginTitle.waitForExistence(timeout: 5))
    }
    
    // MARK: - Login Flow Tests
    
    func testLogin_Success() {
        navigateToLogin()
        
        // Enter credentials
        let emailField = app.textFields["emailTextField"]
        let passwordField = app.secureTextFields["passwordTextField"]
        let loginButton = app.buttons["loginButton"]
        
        emailField.tap()
        emailField.typeText("test@modaics.com")
        
        passwordField.tap()
        passwordField.typeText("TestPass123!")
        
        // Tap login
        loginButton.tap()
        
        // Verify successful login (home screen appears)
        let homeTab = app.tabBars["mainTabBar"].buttons["homeTab"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10))
    }
    
    func testLogin_InvalidEmail() {
        navigateToLogin()
        
        let emailField = app.textFields["emailTextField"]
        let loginButton = app.buttons["loginButton"]
        
        emailField.tap()
        emailField.typeText("invalid-email")
        
        loginButton.tap()
        
        // Verify error message
        let errorMessage = app.staticTexts["errorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5))
        XCTAssertTrue(errorMessage.label.contains("valid email"))
    }
    
    func testLogin_WrongPassword() {
        navigateToLogin()
        
        let emailField = app.textFields["emailTextField"]
        let passwordField = app.secureTextFields["passwordTextField"]
        let loginButton = app.buttons["loginButton"]
        
        emailField.tap()
        emailField.typeText("test@modaics.com")
        
        passwordField.tap()
        passwordField.typeText("wrongpassword")
        
        loginButton.tap()
        
        // Verify error
        let errorMessage = app.staticTexts["errorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5))
    }
    
    func testLogin_ForgotPasswordNavigation() {
        navigateToLogin()
        
        let forgotPasswordButton = app.buttons["forgotPasswordButton"]
        forgotPasswordButton.tap()
        
        // Verify password reset screen
        let resetTitle = app.staticTexts["passwordResetTitle"]
        XCTAssertTrue(resetTitle.waitForExistence(timeout: 5))
    }
    
    func testLogin_RememberMeToggle() {
        navigateToLogin()
        
        let rememberMeSwitch = app.switches["rememberMeSwitch"]
        XCTAssertTrue(rememberMeSwitch.exists)
        
        // Toggle remember me
        rememberMeSwitch.tap()
        
        // Verify toggle state changed
        XCTAssertEqual(rememberMeSwitch.value as? String, "1")
    }
    
    // MARK: - Sign Up Flow Tests
    
    func testSignUp_Success() {
        navigateToSignUp()
        
        // Fill form
        fillSignUpForm(
            displayName: "Test User",
            email: "newuser\(Int.random(in: 1000...9999))@test.com",
            password: "SecurePass123!",
            userType: .consumer
        )
        
        let signUpButton = app.buttons["signUpButton"]
        signUpButton.tap()
        
        // Verify email verification alert or home screen
        let alert = app.alerts["emailVerificationAlert"]
        let homeTab = app.tabBars["mainTabBar"].buttons["homeTab"]
        
        let exists = alert.waitForExistence(timeout: 5) || homeTab.waitForExistence(timeout: 5)
        XCTAssertTrue(exists)
    }
    
    func testSignUp_WeakPassword() {
        navigateToSignUp()
        
        let passwordField = app.secureTextFields["passwordTextField"]
        passwordField.tap()
        passwordField.typeText("123")
        
        let signUpButton = app.buttons["signUpButton"]
        signUpButton.tap()
        
        // Verify password strength indicator
        let strengthIndicator = app.staticTexts["passwordStrengthLabel"]
        XCTAssertTrue(strengthIndicator.waitForExistence(timeout: 5))
        XCTAssertTrue(strengthIndicator.label.contains("weak") || strengthIndicator.label.contains("Weak"))
    }
    
    func testSignUp_PasswordMismatch() {
        navigateToSignUp()
        
        let passwordField = app.secureTextFields["passwordTextField"]
        let confirmPasswordField = app.secureTextFields["confirmPasswordTextField"]
        
        passwordField.tap()
        passwordField.typeText("Password123!")
        
        confirmPasswordField.tap()
        confirmPasswordField.typeText("DifferentPass123!")
        
        let signUpButton = app.buttons["signUpButton"]
        signUpButton.tap()
        
        // Verify error
        let errorMessage = app.staticTexts["errorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5))
    }
    
    func testSignUp_InvalidEmail() {
        navigateToSignUp()
        
        let emailField = app.textFields["emailTextField"]
        emailField.tap()
        emailField.typeText("not-an-email")
        
        let signUpButton = app.buttons["signUpButton"]
        signUpButton.tap()
        
        // Verify validation error
        let errorMessage = app.staticTexts["errorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5))
    }
    
    func testSignUp_UserTypeSelection() {
        navigateToSignUp()
        
        // Select brand type
        let brandSegment = app.segmentedControls["userTypeSegmentedControl"].buttons["Brand"]
        brandSegment.tap()
        
        // Verify brand-specific fields appear
        let brandNameField = app.textFields["brandNameTextField"]
        XCTAssertTrue(brandNameField.waitForExistence(timeout: 5))
    }
    
    func testSignUp_TermsAgreement() {
        navigateToSignUp()
        
        let termsSwitch = app.switches["termsAgreementSwitch"]
        XCTAssertTrue(termsSwitch.exists)
        
        // Try to sign up without agreeing
        termsSwitch.tap() // Toggle off if on by default
        
        let signUpButton = app.buttons["signUpButton"]
        signUpButton.tap()
        
        // Verify error
        let errorMessage = app.staticTexts["errorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5))
    }
    
    // MARK: - Social Sign In Tests
    
    func testSignInWithApple_ButtonExists() {
        waitForWelcomeScreen()
        
        let appleSignInButton = app.buttons["signInWithAppleButton"]
        XCTAssertTrue(appleSignInButton.exists)
    }
    
    func testGoogleSignIn_ButtonExists() {
        waitForWelcomeScreen()
        
        let googleSignInButton = app.buttons["signInWithGoogleButton"]
        XCTAssertTrue(googleSignInButton.exists)
    }
    
    // MARK: - Password Reset Tests
    
    func testPasswordReset_Success() {
        navigateToPasswordReset()
        
        let emailField = app.textFields["emailTextField"]
        emailField.tap()
        emailField.typeText("test@modaics.com")
        
        let resetButton = app.buttons["resetPasswordButton"]
        resetButton.tap()
        
        // Verify success message
        let successMessage = app.staticTexts["successMessage"]
        XCTAssertTrue(successMessage.waitForExistence(timeout: 5))
    }
    
    func testPasswordReset_InvalidEmail() {
        navigateToPasswordReset()
        
        let emailField = app.textFields["emailTextField"]
        emailField.tap()
        emailField.typeText("invalid-email")
        
        let resetButton = app.buttons["resetPasswordButton"]
        resetButton.tap()
        
        // Verify error
        let errorMessage = app.staticTexts["errorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5))
    }
    
    func testPasswordReset_BackNavigation() {
        navigateToPasswordReset()
        
        let backButton = app.buttons["backButton"]
        backButton.tap()
        
        // Verify back on login screen
        let loginTitle = app.staticTexts["loginTitle"]
        XCTAssertTrue(loginTitle.waitForExistence(timeout: 5))
    }
    
    // MARK: - Helper Methods
    
    private func waitForWelcomeScreen() {
        let getStartedButton = app.buttons["getStartedButton"]
        if getStartedButton.waitForExistence(timeout: 5) {
            getStartedButton.tap()
        }
        
        let welcomeTitle = app.staticTexts["welcomeTitle"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 5))
    }
    
    private func navigateToLogin() {
        waitForWelcomeScreen()
        
        let loginButton = app.buttons["loginButton"]
        loginButton.tap()
        
        let loginTitle = app.staticTexts["loginTitle"]
        XCTAssertTrue(loginTitle.waitForExistence(timeout: 5))
    }
    
    private func navigateToSignUp() {
        waitForWelcomeScreen()
        
        let signUpButton = app.buttons["signUpButton"]
        signUpButton.tap()
        
        let signUpTitle = app.staticTexts["signUpTitle"]
        XCTAssertTrue(signUpTitle.waitForExistence(timeout: 5))
    }
    
    private func navigateToPasswordReset() {
        navigateToLogin()
        
        let forgotPasswordButton = app.buttons["forgotPasswordButton"]
        forgotPasswordButton.tap()
        
        let resetTitle = app.staticTexts["passwordResetTitle"]
        XCTAssertTrue(resetTitle.waitForExistence(timeout: 5))
    }
    
    private func fillSignUpForm(displayName: String, email: String, password: String, userType: UserType) {
        let displayNameField = app.textFields["displayNameTextField"]
        let emailField = app.textFields["emailTextField"]
        let passwordField = app.secureTextFields["passwordTextField"]
        let confirmPasswordField = app.secureTextFields["confirmPasswordTextField"]
        
        displayNameField.tap()
        displayNameField.typeText(displayName)
        
        emailField.tap()
        emailField.typeText(email)
        
        passwordField.tap()
        passwordField.typeText(password)
        
        confirmPasswordField.tap()
        confirmPasswordField.typeText(password)
        
        // Select user type
        let segment = userType == .consumer ? "User" : "Brand"
        app.segmentedControls["userTypeSegmentedControl"].buttons[segment].tap()
    }
    
    enum UserType {
        case consumer
        case brand
    }
}
