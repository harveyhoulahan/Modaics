//
//  ContentView.swift
//  Modaics
//
//  Legacy ContentView - maintained for backward compatibility
//  New apps should use RootView from ModaicsApp.swift
//

import SwiftUI

// MARK: - Legacy Content View
// This view is maintained for backward compatibility
// The main app entry point is now ModaicsApp with RootView
struct ContentView: View {
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var currentStage: AppStage = .splash
    @State private var logoAnimationComplete = false
    @State private var contentReady = false
    @State private var userType: UserType?
    @State private var mosaicTransition = false
    
    enum AppStage {
        case splash, login, transition, main
    }
    
    var body: some View {
        ZStack {
            // Base gradient that persists through transitions
            LinearGradient(
                colors: [.modaicsDarkBlue, .modaicsMidBlue],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content with mosaic transitions
            Group {
                switch currentStage {
                case .splash:
                    SplashView(onAnimationComplete: {
                        logoAnimationComplete = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentStage = .login
                            }
                        }
                    })
                    .transition(.opacity)
                    
                case .login:
                    LegacyLoginView(onUserSelect: { type in
                        userType = type
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentStage = .transition
                        }
                        
                        // Update user type in view model
                        if type == .brand {
                            viewModel.setupBrandUser(brandName: "nike")
                        }
                        
                        // Preload data for smooth transition
                        Task {
                            await preloadUserData()
                            contentReady = true
                            // Add small delay before showing main content
                            try? await Task.sleep(nanoseconds: 200_000_000)
                            withAnimation(.easeInOut(duration: 0.6)) {
                                currentStage = .main
                            }
                        }
                    })
                    .transition(.opacity)
                    
                case .transition:
                    TransitionLoadingView(userType: userType)
                        .transition(.opacity)
                    
                case .main:
                    MosaicMainAppView(userType: userType ?? .consumer)
                        .environmentObject(viewModel)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentStage)
    }
    
    // MARK: - Helper Functions
    private func withMosaicTransition<Result>(_ body: () throws -> Result) rethrows -> Result {
        mosaicTransition = true
        let result = try body()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            mosaicTransition = false
        }
        return result
    }
    
    private func preloadUserData() async {
        // Simulate data loading - replace with actual API calls
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        
        // Preload recommendations
        if let firstItem = viewModel.allItems.first {
            viewModel.loadRecommendations(for: firstItem)
        }
    }
}

// MARK: - Legacy Login View (for ContentView compatibility)
struct LegacyLoginView: View {
    let onUserSelect: (UserType) -> Void
    
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
            primaryButton(label: "Continue as User", sfSymbol: "person.fill", idx: 0) {
                onUserSelect(.consumer)
            }
            primaryButton(label: "Continue as Brand", sfSymbol: "building.2.fill", idx: 1) {
                onUserSelect(.brand)
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

// MARK: - Simple Transition View
struct TransitionLoadingView: View {
    let userType: UserType?
    
    var body: some View {
        VStack(spacing: 24) {
            ModaicsMosaicLogo(size: 80)
            
            Text(userType == .consumer ? "Setting up your wardrobe..." : "Preparing your dashboard...")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.modaicsCotton)
            
            ProgressView()
                .tint(.modaicsChrome1)
        }
    }
}

// MARK: - Notifications and Settings Placeholders
struct NotificationsView: View {
    var body: some View {
        NavigationView {
            Text("Notifications")
                .navigationTitle("Notifications")
                .navigationBarItems(trailing: Button("Done") {})
        }
    }
}

// SettingsView is now in Views/Settings/SettingsView.swift
