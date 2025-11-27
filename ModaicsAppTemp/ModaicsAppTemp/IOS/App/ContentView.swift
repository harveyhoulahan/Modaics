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
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Section header
                        SectionHeader(title: "Recent Activity")
                        
                        // Placeholder notification cards
                        ForEach(0..<5, id: \.self) { index in
                            NotificationCard(
                                icon: "bell.fill",
                                title: "New Event Available",
                                message: "Check out the latest sustainable fashion workshop near you",
                                time: "\(index + 1)h ago"
                            )
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("NOTIFICATIONS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("DONE")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.appRed)
                    }
                }
            }
        }
    }
}

struct NotificationCard: View {
    let icon: String
    let title: String
    let message: String
    let time: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Color.appRed.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.appRed)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .tracking(0.5)
                    .foregroundColor(.appTextMain)
                
                Text(message)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.appTextMuted)
                    .lineLimit(2)
                
                Text(time.uppercased())
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(0.5)
                    .foregroundColor(.appTextMuted.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            Rectangle()
                .fill(Color.appSurface)
        )
        .overlay(
            Rectangle()
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Profile section
                        SectionHeader(title: "Profile")
                        
                        SettingsRow(icon: "person.fill", title: "Edit Profile", showChevron: true)
                        SettingsRow(icon: "heart.fill", title: "Saved Items", badge: "12", showChevron: true)
                        SettingsRow(icon: "clock.fill", title: "History", showChevron: true)
                        
                        Divider()
                            .background(Color.appBorder)
                            .padding(.vertical, 16)
                        
                        // Preferences section
                        SectionHeader(title: "Preferences")
                        
                        SettingsRow(icon: "bell.fill", title: "Notifications", showChevron: true)
                        SettingsRow(icon: "globe", title: "Language", value: "English", showChevron: true)
                        SettingsRow(icon: "moon.fill", title: "Dark Mode", showToggle: true)
                        
                        Divider()
                            .background(Color.appBorder)
                            .padding(.vertical, 16)
                        
                        // About section
                        SectionHeader(title: "About")
                        
                        SettingsRow(icon: "info.circle.fill", title: "About Modaics", showChevron: true)
                        SettingsRow(icon: "doc.text.fill", title: "Terms of Service", showChevron: true)
                        SettingsRow(icon: "lock.fill", title: "Privacy Policy", showChevron: true)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("SETTINGS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("DONE")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.appRed)
                    }
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    var badge: String? = nil
    var showChevron: Bool = false
    var showToggle: Bool = false
    @State private var toggleValue = false
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.appSurface)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.appTextMain)
                    )
                
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .tracking(0.5)
                    .foregroundColor(.appTextMain)
                
                Spacer()
                
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.appRed)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Rectangle()
                                .fill(Color.appRed.opacity(0.1))
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.appRed, lineWidth: 1)
                                )
                        )
                }
                
                if let value = value {
                    Text(value.uppercased())
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.appTextMuted)
                }
                
                if showToggle {
                    Toggle("", isOn: $toggleValue)
                        .labelsHidden()
                        .tint(.appRed)
                }
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.appTextMuted)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

