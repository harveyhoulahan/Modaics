//
//  ModaicsApp.swift
//  Modaics
//
//  Main app entry point with Firebase initialization and auth state routing
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Google Sign In
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        
        // Configure Firebase Auth settings
        let settings = ActionCodeSettings()
        settings.url = URL(string: "https://modaics.app/auth/action")
        settings.handleCodeInApp = true
        settings.setIOSBundleID(Bundle.main.bundleIdentifier ?? "com.modaics.app")
        
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle Google Sign In URL
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - Main App
@main
struct ModaicsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var fashionViewModel = FashionViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(fashionViewModel)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSplash = true
    @State private var splashAnimationComplete = false
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [.modaicsDarkBlue, .modaicsMidBlue],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Main content based on auth state
            Group {
                if showSplash {
                    SplashView(onAnimationComplete: {
                        splashAnimationComplete = true
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSplash = false
                        }
                    })
                } else {
                    switch authViewModel.authState {
                    case .unknown, .loading:
                        LoadingView()
                    case .unauthenticated, .error:
                        AuthFlowView()
                    case .authenticated:
                        MainAppView()
                    }
                }
            }
        }
        .alert("Verify Your Email", isPresented: $authViewModel.showEmailVerificationAlert) {
            Button("OK", role: .cancel) { }
            Button("Resend Email") {
                Task {
                    await authViewModel.sendEmailVerification()
                }
            }
        } message: {
            Text("A verification email has been sent to your email address. Please verify your email to continue.")
        }
    }
}

// MARK: - Auth Flow View
struct AuthFlowView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var authRoute: AuthRoute = .welcome
    @State private var selectedUserType: ContentView.UserType?
    
    enum AuthRoute {
        case welcome
        case login
        case signup
        case passwordReset
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch authRoute {
                case .welcome:
                    WelcomeView(
                        onLogin: { authRoute = .login },
                        onSignUp: { authRoute = .signup }
                    )
                case .login:
                    EnhancedLoginView(
                        onBack: { authRoute = .welcome },
                        onSignUp: { authRoute = .signup },
                        onForgotPassword: { authRoute = .passwordReset }
                    )
                case .signup:
                    SignUpView(
                        onBack: { authRoute = .welcome },
                        onLogin: { authRoute = .login }
                    )
                case .passwordReset:
                    PasswordResetView(
                        onBack: { authRoute = .login }
                    )
                }
            }
        }
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    let onLogin: () -> Void
    let onSignUp: () -> Void
    
    @State private var introOpacity = 0.0
    @State private var introOffset: CGFloat = 30
    @State private var statVisible = false
    @State private var featureShown = [false, false, false]
    @State private var btnScale = [1.0, 1.0]
    
    var body: some View {
        ZStack {
            background
            
            ScrollView {
                VStack(spacing: 40) {
                    header
                    introSection
                    impactStats
                    premiumFeatures
                    actionButtons
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear { runAnimations() }
    }
    
    private var background: some View {
        LinearGradient(
            colors: [.modaicsDarkBlue, .modaicsMidBlue],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var header: some View {
        HStack {
            ModaicsMosaicLogo(size: 80)
            Text("modaics")
                .font(.system(size: 32, weight: .ultraLight, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }
    
    private var introSection: some View {
        VStack(spacing: 20) {
            Text("Welcome to your\ndigital wardrobe")
                .font(.system(size: 36, weight: .ultraLight, design: .serif))
                .foregroundColor(.modaicsCotton)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
            
            Text("Modaics helps you discover, swap and sell fashion items while reducing your environmental footprint.")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.modaicsCotton.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .lineSpacing(4)
        }
        .opacity(introOpacity)
        .offset(y: introOffset)
    }
    
    private var impactStats: some View {
        HStack(spacing: 30) {
            ImpactStat(value: "2.5M", label: "Items Saved", icon: "arrow.3.trianglepath")
            ImpactStat(value: "500K", label: "Active Users", icon: "person.2.fill")
            ImpactStat(value: "1.2M", label: "kg CO₂ Saved", icon: "leaf.fill")
        }
        .padding(.vertical, 10)
        .opacity(statVisible ? 1 : 0)
        .offset(y: statVisible ? 0 : 20)
    }
    
    private var premiumFeatures: some View {
        VStack(spacing: 20) {
            PremiumFeatureCard(
                icon: "checkmark.seal.fill",
                title: "Verified Sustainability",
                description: "Track your impact via FibreTrace",
                isVisible: featureShown[0]
            )
            PremiumFeatureCard(
                icon: "person.2.fill",
                title: "Community-Driven",
                description: "Connect with local fashion lovers",
                isVisible: featureShown[1]
            )
            PremiumFeatureCard(
                icon: "sparkles",
                title: "AI-Powered Styling",
                description: "Personalised recommendations",
                isVisible: featureShown[2]
            )
        }
        .padding(.horizontal, 24)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            primaryButton(label: "Get Started", sfSymbol: "person.fill", idx: 0) {
                onSignUp()
            }
            
            Button {
                onLogin()
            } label: {
                Text("Already have an account? Sign In")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.modaicsChrome1)
            }
            
            Text("By continuing you agree to our Terms & Privacy Policy")
                .font(.caption2)
                .foregroundColor(.modaicsChrome1.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.horizontal, 24)
    }
    
    private func primaryButton(label: String, sfSymbol: String, idx: Int, action: @escaping () -> Void) -> some View {
        Button {
            btnScale[idx] = 0.94
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                btnScale[idx] = 1.0
                action()
            }
        } label: {
            HStack {
                Image(systemName: sfSymbol)
                Text(label).fontWeight(.medium)
            }
            .foregroundColor(.modaicsDarkBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [.modaicsChrome1, .modaicsChrome2],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .modaicsChrome1.opacity(0.3), radius: 10, y: 5)
        }
        .scaleEffect(btnScale[idx])
        .animation(.modaicsSpring, value: btnScale[idx])
    }
    
    private func runAnimations() {
        withAnimation(.modaicsSpring.delay(0.2)) {
            introOpacity = 1
            introOffset = 0
        }
        withAnimation(.modaicsSpring.delay(0.4)) { statVisible = true }
        for i in featureShown.indices {
            withAnimation(.modaicsSpring.delay(0.6 + Double(i) * 0.2)) {
                featureShown[i] = true
            }
        }
    }
}

// MARK: - Main App View
struct MainAppView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var fashionViewModel: FashionViewModel
    @State private var selectedTab = 0
    @State private var userType: ContentView.UserType = .user
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case 0:
                    HomeView(userType: userType)
                        .environmentObject(fashionViewModel)
                case 1:
                    DiscoverView()
                        .environmentObject(fashionViewModel)
                case 2:
                    UnifiedCreateView(userType: userType)
                        .environmentObject(fashionViewModel)
                case 3:
                    CommunityFeedView()
                        .environmentObject(fashionViewModel)
                case 4:
                    ProfileView(userType: userType)
                        .environmentObject(fashionViewModel)
                        .environmentObject(authViewModel)
                default:
                    EmptyView()
                }
            }
            
            // Tab bar
            SimplifiedTabBar(selectedTab: $selectedTab, userType: userType)
                .background(
                    Color.modaicsDarkBlue.opacity(0.95)
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.modaicsChrome1.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        }
        .withToast()
        .withConfetti()
        .onAppear {
            syncUserData()
        }
        .onChange(of: authViewModel.currentUser) { _, _ in
            syncUserData()
        }
    }
    
    private func syncUserData() {
        // Sync FashionViewModel with Auth user
        fashionViewModel.syncWithAuthUser(authViewModel.currentUser)
        
        // Set user type based on auth
        if let user = authViewModel.currentUser {
            userType = user.userType == .brand ? .brand : .user
            if userType == .brand {
                fashionViewModel.setupBrandUser(brandName: user.displayName ?? "brand")
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            ModaicsMosaicLogo(size: 100)
            
            ProgressView()
                .tint(.modaicsChrome1)
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.modaicsCotton)
        }
    }
}

// MARK: - Preview
#Preview("Root View") {
    RootView()
        .environmentObject(AuthViewModel())
        .environmentObject(FashionViewModel())
}
