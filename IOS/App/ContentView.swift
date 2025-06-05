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

// MARK: - Enhanced Main App View with ViewModel Integration
struct MainAppView: View {
    let userType: ContentView.UserType
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var selectedTab = 0
    @State private var contentOpacity: Double = 0
    @State private var contentScale: CGFloat = 0.95
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(userType: userType)
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            DiscoverView()
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Discover")
                }
                .tag(1)
            
            SellView(userType: userType)
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text(userType == .user ? "Sell" : "List")
                }
                .tag(2)
            
            CommunityView()
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Community")
                }
                .tag(3)
            
            ProfileView(userType: userType)
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .scaleEffect(contentScale)
        .opacity(contentOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                contentOpacity = 1
                contentScale = 1
            }
        }
    }
}

// MARK: - Enhanced Home View with ViewModel
struct HomeView: View {
    let userType: ContentView.UserType
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var showNotifications = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Custom Header
                    headerView
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Welcome Section
                    welcomeSection
                        .padding(.horizontal)
                    
                    // Feature Grid
                    featureGrid
                        .padding(.horizontal)
                    
                    // Recommended Items Section
                    if !viewModel.recommendedItems.isEmpty {
                        recommendedSection
                    }
                    
                    // Sustainability Score
                    if userType == .user {
                        sustainabilitySection
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    private var headerView: some View {
        HStack {
            // Mini logo
            ModaicsLogoMini()
            
            Text("modaics")
                .font(.headline)
                .foregroundColor(.blue)
            
            Spacer()
            
            // Header buttons
            HStack(spacing: 16) {
                Button(action: { showNotifications = true }) {
                    Image(systemName: "bell")
                        .foregroundColor(.gray)
                        .overlay(
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -8)
                        )
                }
                
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(userType == .user ? "Your Digital Wardrobe" : "Brand Dashboard")
                .font(.largeTitle)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(userType == .user ?
                     "Welcome back, \(viewModel.currentUser?.username ?? "Fashion Lover")!" :
                     "Ready to showcase your sustainable collection?")
                    .font(.headline)
                
                Text(userType == .user ?
                     "You've saved \(viewModel.calculateUserSustainabilityScore())kg of CO2 this month!" :
                     "Your items have reached \(viewModel.userWardrobe.reduce(0) { $0 + $1.viewCount }) views")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(userType == .user ? "Explore Wardrobe" : "View Analytics") {
                    // Action
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
        }
    }
    
    private var featureGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 2), spacing: 15) {
            FeatureTile(
                title: userType == .user ? "Discover Items" : "Manage Catalog",
                icon: "magnifyingglass",
                color: .blue,
                count: viewModel.allItems.count
            )
            
            FeatureTile(
                title: userType == .user ? "My Wardrobe" : "Brand Profile",
                icon: "hanger",
                color: .green,
                count: viewModel.userWardrobe.count
            )
            
            FeatureTile(
                title: "Sustainability Score",
                icon: "leaf.fill",
                color: .teal,
                count: viewModel.calculateUserSustainabilityScore()
            )
            
            FeatureTile(
                title: userType == .user ? "Community" : "Customer Insights",
                icon: "chart.bar.fill",
                color: .orange,
                count: viewModel.currentUser?.followers.count ?? 0
            )
        }
    }
    
    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended for You")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.recommendedItems) { item in
                        RecommendedItemCard(item: item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var sustainabilitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Sustainability Impact")
                .font(.headline)
            
            HStack(spacing: 20) {
                SustainabilityMetric(
                    icon: "drop.fill",
                    value: "2,500L",
                    label: "Water Saved",
                    color: .blue
                )
                
                SustainabilityMetric(
                    icon: "leaf.fill",
                    value: "\(viewModel.calculateUserSustainabilityScore())kg",
                    label: "CO2 Reduced",
                    color: .green
                )
                
                SustainabilityMetric(
                    icon: "arrow.3.trianglepath",
                    value: "\(viewModel.userWardrobe.filter { $0.sustainabilityScore.isRecycled }.count)",
                    label: "Items Recycled",
                    color: .orange
                )
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
        }
    }
}

// MARK: - Supporting Views
struct ModaicsLogoMini: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.blue)
                .frame(width: 3, height: 12)
                .rotationEffect(.degrees(-40), anchor: .topLeading)
                .offset(x: -3, y: 0)
            
            Rectangle()
                .fill(Color.blue.opacity(0.9))
                .frame(width: 3, height: 12)
            
            Rectangle()
                .fill(Color.blue.opacity(0.7))
                .frame(width: 3, height: 12)
                .rotationEffect(.degrees(40), anchor: .topTrailing)
                .offset(x: 3, y: 0)
        }
        .frame(width: 15, height: 15)
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