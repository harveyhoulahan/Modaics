//
//  EnhancedLoginView.swift
//  Modaics
//
//  Login view with email/password, Apple Sign In, and Google Sign In
//

import SwiftUI
import AuthenticationServices

struct EnhancedLoginView: View {
    let onBack: () -> Void
    let onSignUp: () -> Void
    let onForgotPassword: () -> Void
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Form fields
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    
    // UI states
    @State private var showPassword = false
    @State private var shakeOffset: CGFloat = 0
    @State private var animateContent = false
    @State private var selectedUserType: UserType = .consumer
    
    // Error states
    @State private var showError = false
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && isValidEmail(email)
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
                    
                    // Remember Me & Forgot Password
                    optionsSection
                    
                    // Sign In Button
                    signInButton
                    
                    // Error Message
                    if let errorMessage = authViewModel.errorMessage {
                        ErrorText(message: errorMessage)
                            .transition(.opacity)
                    }
                    
                    // Divider
                    dividerSection
                    
                    // Social Sign In
                    socialSignInSection
                    
                    // Sign Up Link
                    signUpLink
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
            }
        }
        .onAppear {
            loadRememberedCredentials()
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
            
            Text("Welcome Back")
                .font(.system(size: 32, weight: .ultraLight, design: .serif))
                .foregroundColor(.modaicsCotton)
            
            Text("Sign in to continue your sustainable fashion journey")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.modaicsCottonLight)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - User Type Section
    private var userTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Signing in as...")
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
            // Email
            AuthTextField(
                title: "Email",
                placeholder: "your@email.com",
                text: $email,
                icon: "envelope",
                keyboardType: .emailAddress,
                autocapitalization: .none
            )
            .autocorrectionDisabled()
            
            // Password
            AuthSecureField(
                title: "Password",
                placeholder: "Enter your password",
                text: $password,
                isVisible: $showPassword
            )
        }
    }
    
    // MARK: - Options Section
    private var optionsSection: some View {
        HStack {
            // Remember Me
            Button {
                withAnimation(.spring(response: 0.2)) {
                    rememberMe.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                        .foregroundColor(rememberMe ? .modaicsChrome1 : .modaicsCottonLight)
                    
                    Text("Remember me")
                        .font(.system(size: 14))
                        .foregroundColor(.modaicsCottonLight)
                }
            }
            
            Spacer()
            
            // Forgot Password
            Button(action: onForgotPassword) {
                Text("Forgot Password?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsChrome1)
            }
        }
    }
    
    // MARK: - Sign In Button
    private var signInButton: some View {
        Button {
            performSignIn()
        } label: {
            HStack {
                if authViewModel.isLoading {
                    ProgressView()
                        .tint(.modaicsDarkBlue)
                } else {
                    Text("Sign In")
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
        .padding(.top, 8)
    }
    
    // MARK: - Divider Section
    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.modaicsCottonLight.opacity(0.3))
                .frame(height: 1)
            
            Text("or continue with")
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
                .signIn,
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
    
    // MARK: - Sign Up Link
    private var signUpLink: some View {
        HStack {
            Text("Don't have an account?")
                .font(.system(size: 16))
                .foregroundColor(.modaicsCottonLight)
            
            Button(action: onSignUp) {
                Text("Sign Up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modaicsChrome1)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 20)
    }
    
    // MARK: - Actions
    private func performSignIn() {
        guard isFormValid else {
            shakeButton()
            return
        }
        
        Task {
            await authViewModel.signIn(
                email: email,
                password: password,
                rememberMe: rememberMe
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
    
    private func loadRememberedCredentials() {
        let credentials = authViewModel.getRememberedCredentials()
        if let email = credentials.email {
            self.email = email
            self.rememberMe = true
        }
        if let password = credentials.password {
            self.password = password
        }
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
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}

// MARK: - Reusable Auth Components

struct AuthTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.modaicsCotton)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.modaicsChrome1)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.modaicsCotton)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.modaicsDarkBlue.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.modaicsCottonLight.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct AuthSecureField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.modaicsCotton)
            
            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .foregroundColor(.modaicsChrome1)
                    .frame(width: 20)
                
                if isVisible {
                    TextField(placeholder, text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.modaicsCotton)
                } else {
                    SecureField(placeholder, text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.modaicsCotton)
                }
                
                Button {
                    withAnimation(.spring(response: 0.2)) {
                        isVisible.toggle()
                    }
                } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .foregroundColor(.modaicsCottonLight)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.modaicsDarkBlue.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.modaicsCottonLight.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct ErrorText: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.caption)
            
            Text(message)
                .font(.system(size: 14))
        }
        .foregroundColor(.red.opacity(0.9))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
        )
    }
}

// MARK: - Preview
#Preview {
    EnhancedLoginView(onBack: {}, onSignUp: {}, onForgotPassword: {})
        .environmentObject(AuthViewModel())
}
