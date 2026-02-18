//
//  SignUpView.swift
//  Modaics
//
//  User registration with email/password, Apple Sign In, and Google Sign In
//

import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    let onBack: () -> Void
    let onLogin: () -> Void
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Form fields
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedUserType: UserType = .consumer
    @State private var agreeToTerms = false
    
    // Validation states
    @State private var displayNameError = ""
    @State private var emailError = ""
    @State private var passwordError = ""
    @State private var confirmPasswordError = ""
    
    // UI states
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var shakeOffset: CGFloat = 0
    @State private var animateContent = false
    
    private var isFormValid: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        agreeToTerms &&
        isValidEmail(email) &&
        isValidPassword(password)
    }
    
    var body: some View {
        ZStack {
            background
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // User Type Selection
                    userTypeSection
                    
                    // Form Fields
                    formSection
                    
                    // Terms
                    termsSection
                    
                    // Sign Up Button
                    signUpButton
                    
                    // Divider
                    dividerSection
                    
                    // Social Sign In
                    socialSignInSection
                    
                    // Login Link
                    loginLink
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateContent = true
            }
        }
        .overlay(
            Group {
                if authViewModel.isLoading {
                    LoadingOverlay()
                }
            }
        )
    }
    
    // MARK: - Background
    private var background: some View {
        LinearGradient(
            colors: [.modaicsDarkBlue, .modaicsMidBlue],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(.modaicsChrome1)
                }
                Spacer()
            }
            
            ModaicsMosaicLogo(size: 60)
            
            Text("Create Account")
                .font(.system(size: 32, weight: .ultraLight, design: .serif))
                .foregroundColor(.modaicsCotton)
            
            Text("Join the sustainable fashion movement")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.modaicsCottonLight)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - User Type Section
    private var userTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("I want to join as a...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.modaicsCotton)
            
            HStack(spacing: 12) {
                UserTypeButton(
                    title: "User",
                    icon: "person.fill",
                    description: "Discover & swap fashion",
                    isSelected: selectedUserType == .consumer
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedUserType = .consumer
                    }
                }
                
                UserTypeButton(
                    title: "Brand",
                    icon: "building.2.fill",
                    description: "Showcase your collection",
                    isSelected: selectedUserType == .brand
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedUserType = .brand
                    }
                }
            }
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 16) {
            // Display Name
            AuthTextField(
                title: "Display Name",
                placeholder: "How should we call you?",
                text: $displayName,
                icon: "person"
            )
            .onChange(of: displayName) { _, newValue in
                if newValue.count < 2 {
                    displayNameError = "Name must be at least 2 characters"
                } else {
                    displayNameError = ""
                }
            }
            
            if !displayNameError.isEmpty {
                ErrorText(message: displayNameError)
            }
            
            // Email
            AuthTextField(
                title: "Email",
                placeholder: "your@email.com",
                text: $email,
                icon: "envelope",
                keyboardType: .emailAddress,
                autocapitalization: .none
            )
            .onChange(of: email) { _, newValue in
                if !newValue.isEmpty && !isValidEmail(newValue) {
                    emailError = "Please enter a valid email"
                } else {
                    emailError = ""
                }
            }
            
            if !emailError.isEmpty {
                ErrorText(message: emailError)
            }
            
            // Password
            VStack(alignment: .leading, spacing: 4) {
                AuthSecureField(
                    title: "Password",
                    placeholder: "Create a strong password",
                    text: $password,
                    isVisible: $showPassword
                )
                
                // Password strength indicator
                PasswordStrengthIndicator(password: password)
            }
            .onChange(of: password) { _, newValue in
                if !newValue.isEmpty && !isValidPassword(newValue) {
                    passwordError = "Password must be at least 8 characters"
                } else {
                    passwordError = ""
                }
            }
            
            // Confirm Password
            AuthSecureField(
                title: "Confirm Password",
                placeholder: "Re-enter your password",
                text: $confirmPassword,
                isVisible: $showConfirmPassword
            )
            .onChange(of: confirmPassword) { _, newValue in
                if !newValue.isEmpty && newValue != password {
                    confirmPasswordError = "Passwords do not match"
                } else {
                    confirmPasswordError = ""
                }
            }
            
            if !confirmPasswordError.isEmpty {
                ErrorText(message: confirmPasswordError)
            }
        }
    }
    
    // MARK: - Terms Section
    private var termsSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.2)) {
                    agreeToTerms.toggle()
                }
            } label: {
                Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(agreeToTerms ? .modaicsChrome1 : .modaicsCottonLight)
            }
            
            Text("I agree to the ")
                .font(.system(size: 14))
                .foregroundColor(.modaicsCottonLight)
            + Text("Terms of Service")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.modaicsChrome1)
            + Text(" and ")
                .font(.system(size: 14))
                .foregroundColor(.modaicsCottonLight)
            + Text("Privacy Policy")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.modaicsChrome1)
        }
    }
    
    // MARK: - Sign Up Button
    private var signUpButton: some View {
        Button {
            performSignUp()
        } label: {
            HStack {
                if authViewModel.isLoading {
                    ProgressView()
                        .tint(.modaicsDarkBlue)
                } else {
                    Text("Create Account")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
            }
            .foregroundColor(.modaicsDarkBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: isFormValid ? [.modaicsChrome1, .modaicsChrome2] : [.gray.opacity(0.5), .gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: isFormValid ? .modaicsChrome1.opacity(0.3) : .clear, radius: 10, y: 5)
        }
        .disabled(!isFormValid || authViewModel.isLoading)
        .offset(x: shakeOffset)
    }
    
    // MARK: - Divider Section
    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.modaicsCottonLight.opacity(0.3))
                .frame(height: 1)
            
            Text("or sign up with")
                .font(.system(size: 14))
                .foregroundColor(.modaicsCottonLight)
            
            Rectangle()
                .fill(Color.modaicsCottonLight.opacity(0.3))
                .frame(height: 1)
        }
    }
    
    // MARK: - Social Sign In Section
    private var socialSignInSection: some View {
        VStack(spacing: 12) {
            // Sign in with Apple
            SignInWithAppleButton(
                .signUp,
                onRequest: { request in
                    authViewModel.signInWithAppleRequest(request)
                },
                onCompletion: { result in
                    Task {
                        await authViewModel.signInWithAppleCompletion(result, userType: selectedUserType)
                    }
                }
            )
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Google Sign In
            Button {
                signInWithGoogle()
            } label: {
                HStack {
                    Image(systemName: "g.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    
                    Text("Continue with Google")
                        .fontWeight(.medium)
                        .foregroundColor(.modaicsDarkBlue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Login Link
    private var loginLink: some View {
        HStack {
            Text("Already have an account?")
                .font(.system(size: 16))
                .foregroundColor(.modaicsCottonLight)
            
            Button(action: onLogin) {
                Text("Sign In")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modaicsChrome1)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 20)
    }
    
    // MARK: - Actions
    private func performSignUp() {
        guard validateForm() else {
            shakeButton()
            return
        }
        
        Task {
            await authViewModel.signUp(
                email: email,
                password: password,
                displayName: displayName,
                userType: selectedUserType
            )
        }
    }
    
    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        Task {
            await authViewModel.signInWithGoogle(
                presenting: rootViewController,
                userType: selectedUserType
            )
        }
    }
    
    private func validateForm() -> Bool {
        var isValid = true
        
        if displayName.count < 2 {
            displayNameError = "Name must be at least 2 characters"
            isValid = false
        }
        
        if !isValidEmail(email) {
            emailError = "Please enter a valid email"
            isValid = false
        }
        
        if !isValidPassword(password) {
            passwordError = "Password must be at least 8 characters"
            isValid = false
        }
        
        if password != confirmPassword {
            confirmPasswordError = "Passwords do not match"
            isValid = false
        }
        
        if !agreeToTerms {
            isValid = false
        }
        
        return isValid
    }
    
    private func shakeButton() {
        withAnimation(.spring(response: 0.1, dampingFraction: 0.5)) {
            shakeOffset = -10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.5)) {
                shakeOffset = 10
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.5)) {
                shakeOffset = 0
            }
        }
    }
    
    // MARK: - Validation Helpers
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8
    }
}

// MARK: - User Type Button
struct UserTypeButton: View {
    let title: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .modaicsDarkBlue : .modaicsCotton)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .modaicsDarkBlue : .modaicsCotton)
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .modaicsDarkBlue.opacity(0.8) : .modaicsCottonLight)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.modaicsChrome1 : Color.modaicsDarkBlue.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.modaicsChrome2 : Color.modaicsCottonLight.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Password Strength Indicator
struct PasswordStrengthIndicator: View {
    let password: String
    
    private var strength: PasswordStrength {
        if password.isEmpty { return .empty }
        if password.count < 8 { return .weak }
        if password.count < 12 { return .medium }
        
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecial = password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
        
        let score = [hasUppercase, hasLowercase, hasNumbers, hasSpecial].filter { $0 }.count
        
        if score >= 3 && password.count >= 12 {
            return .strong
        } else if score >= 2 {
            return .medium
        } else {
            return .weak
        }
    }
    
    enum PasswordStrength {
        case empty, weak, medium, strong
        
        var color: Color {
            switch self {
            case .empty: return .clear
            case .weak: return .red
            case .medium: return .orange
            case .strong: return .green
            }
        }
        
        var text: String {
            switch self {
            case .empty: return ""
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Strength bars
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(strengthBarColor(for: index))
                        .frame(height: 4)
                }
            }
            
            Text(strength.text)
                .font(.system(size: 12))
                .foregroundColor(strength.color)
        }
    }
    
    private func strengthBarColor(for index: Int) -> Color {
        let strengthValue: Int = {
            switch strength {
            case .empty: return 0
            case .weak: return 1
            case .medium: return 2
            case .strong: return 3
            }
        }()
        
        return index < strengthValue ? strength.color : Color.modaicsCottonLight.opacity(0.2)
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.modaicsChrome1)
                    .scaleEffect(1.5)
                
                Text("Creating your account...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.modaicsCotton)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.modaicsDarkBlue)
                    .shadow(radius: 10)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    SignUpView(onBack: {}, onLogin: {})
        .environmentObject(AuthViewModel())
}
