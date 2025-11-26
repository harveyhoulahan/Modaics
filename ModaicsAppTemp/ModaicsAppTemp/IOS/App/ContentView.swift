//
//  ContentView.swift
//  Modaics
//
//  Created by Harvey Houlahan on 3/6/2025.
//

import SwiftUI

@main
struct ModaicsApp: App {
    @StateObject private var fashionViewModel = FashionViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fashionViewModel)
                .preferredColorScheme(.dark) // Enhances the chrome aesthetic
        }
    }
}

// MARK: - Enhanced Content View with Mosaic Integration
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
    
    enum UserType {
        case user, brand
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
                    LoginView(onUserSelect: { type in
                        userType = type
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentStage = .transition
                        }
                        
                        // Update user type in view model
                        if type == .brand {
                            viewModel.currentUser?.userType = .brand
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
                    MosaicMainAppView(userType: userType ?? .user)
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

// MARK: - Simple Transition View
struct TransitionLoadingView: View {
    let userType: ContentView.UserType?
    
    var body: some View {
        VStack(spacing: 24) {
            ModaicsMosaicLogo(size: 80)
            
            Text(userType == .user ? "Setting up your wardrobe..." : "Preparing your dashboard...")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.modaicsCotton)
            
            ProgressView()
                .tint(.modaicsChrome1)
        }
    }
}

// MARK: Placeholders for Notifs and Settings - need to be implemented
struct NotificationsView: View {
    var body: some View {
        NavigationView {
            Text("Notifications")
                .navigationTitle("Notifications")
                .navigationBarItems(trailing: Button("Done") {})
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Text("Settings")
                .navigationTitle("Settings")
                .navigationBarItems(trailing: Button("Done") {})
        }
    }
}
