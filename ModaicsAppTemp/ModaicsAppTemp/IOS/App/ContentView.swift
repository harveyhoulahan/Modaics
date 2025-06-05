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
        }
    }
}

// MARK: - Content View with App State Management
struct ContentView: View {
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var currentStage: AppStage = .splash
    @State private var logoAnimationComplete = false
    @State private var contentReady = false
    @State private var userType: UserType?
    
    enum AppStage {
        case splash, login, transition, main
    }
    
    enum UserType {
        case user, brand
    }
    
    var body: some View {
        ZStack {
            switch currentStage {
            case .splash:
                SplashView(onAnimationComplete: {
                    logoAnimationComplete = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        contentReady = true
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentStage = .main
                        }
                    }
                })
                .transition(.opacity)
                
            case .transition:
                TransitionView(userType: userType, contentReady: contentReady)
                    .transition(.opacity)
                
            case .main:
                MainAppView(userType: userType ?? .user)
                    .environmentObject(viewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentStage)
    }
}

struct FeatureTile: View {
    let title: String
    let icon: String
    let color: Color
    let count: Int
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            Text("\(count)")
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}

struct RecommendedItemCard: View {
    let item: FashionItem
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Item image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 140, height: 180)
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.brand)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack {
                    Text("$\(Int(item.listingPrice))")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "leaf.fill")
                            .font(.caption)
                        Text("\(item.sustainabilityScore.totalScore)")
                            .font(.caption)
                    }
                    .foregroundColor(item.sustainabilityScore.sustainabilityColor)
                }
            }
        }
        .frame(width: 140)
    }
}

struct SustainabilityMetric: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// Placeholder views for other tabs
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
