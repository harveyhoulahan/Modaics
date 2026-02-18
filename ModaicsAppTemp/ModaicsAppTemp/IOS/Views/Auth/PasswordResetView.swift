//
//  PasswordResetView.swift
//  Modaics
//
//  Password reset functionality
//

import SwiftUI

struct PasswordResetView: View {
    let onBack: () -> Void
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Form fields
    @State private var email = ""
    @State private var isSuccess = false
    @State private var shakeOffset: CGFloat = 0
    @State private var animateContent = false
    
    private var isFormValid: Bool {
        !email.isEmpty && isValidEmail(email)
    }
    
    var body: some View {
        ZStack {
            background
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    headerSection
                    
                    if isSuccess {
                        successSection
                    } else {
                        // Form
                        formSection
                        
                        // Submit Button
                        submitButton
                        
                        // Error Message
                        if let errorMessage = authViewModel.errorMessage {
                            ErrorText(message: errorMessage)
                                .transition(.opacity)
                        }
                    }
                    
                    Spacer()
                    
                    // Back Link
                    backLink
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
        VStack(spacing: 20) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(.modaicsChrome1)
                }
                Spacer()
            }
            
            // Lock icon
            ZStack {
                Circle()
                    .fill(Color.modaicsChrome1.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Circle()
                    .stroke(Color.modaicsChrome1.opacity(0.3), lineWidth: 2)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "lock.rotation")
                    .font(.system(size: 40))
                    .foregroundColor(.modaicsChrome1)
            }
            
            VStack(spacing: 12) {
                Text("Reset Password")
                    .font(.system(size: 32, weight: .ultraLight, design: .serif))
                    .foregroundColor(.modaicsCotton)
                
                Text("Enter your email address and we'll send you instructions to reset your password.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.modaicsCottonLight)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 16) {
            AuthTextField(
                title: "Email Address",
                placeholder: "your@email.com",
                text: $email,
                icon: "envelope",
                keyboardType: .emailAddress,
                autocapitalization: .none
            )
            .autocorrectionDisabled()
        }
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            performPasswordReset()
        } label: {
            HStack {
                if authViewModel.isLoading {
                    ProgressView()
                        .tint(.modaicsDarkBlue)
                } else {
                    Text("Send Reset Link")
                        .fontWeight(.semibold)
                    Image(systemName: "paperplane.fill")
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
    
    // MARK: - Success Section
    private var successSection: some View {
        VStack(spacing: 24) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                Text("Check Your Email")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.modaicsCotton)
                
                Text("We've sent password reset instructions to")
                    .font(.system(size: 16))
                    .foregroundColor(.modaicsCottonLight)
                
                Text(email)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modaicsChrome1)
                
                Text("Didn't receive the email? Check your spam folder or try again.")
                    .font(.system(size: 14))
                    .foregroundColor(.modaicsCottonLight.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            
            Button {
                resendEmail()
            } label: {
                Text("Resend Email")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modaicsChrome1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.modaicsChrome1, lineWidth: 1)
                    )
            }
            .disabled(authViewModel.isLoading)
            .padding(.top, 16)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.modaicsDarkBlue.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.modaicsChrome1.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Back Link
    private var backLink: some View {
        Button(action: onBack) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left")
                Text("Back to Sign In")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.modaicsChrome1)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Actions
    private func performPasswordReset() {
        guard isFormValid else {
            shakeButton()
            return
        }
        
        Task {
            let success = await authViewModel.sendPasswordReset(email: email)
            if success {
                withAnimation(.spring(response: 0.5)) {
                    isSuccess = true
                }
            }
        }
    }
    
    private func resendEmail() {
        Task {
            _ = await authViewModel.sendPasswordReset(email: email)
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

// MARK: - Preview
#Preview {
    PasswordResetView(onBack: {})
        .environmentObject(AuthViewModel())
}
