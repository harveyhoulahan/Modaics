//
//  ModaicsApp.swift
//  Modaics
//
//  Created by Harvey Houlahan on 3/6/2025.
//

//
//  ModaicsApp.swift
//  Modaics
//
//  Created by Harvey Houlahan on 3/6/2025.
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Color Theme
extension Color {
    // Dark sophisticated background colors
    static let modaicsDarkBlue = Color(red: 0.1, green: 0.15, blue: 0.2)
    static let modaicsMidBlue = Color(red: 0.15, green: 0.2, blue: 0.3)
    static let modaicsLightBlue = Color(red: 0.2, green: 0.25, blue: 0.35)
    
    // Chrome/metallic colors
    static let modaicsChrome1 = Color(red: 0.7, green: 0.75, blue: 0.8)
    static let modaicsChrome2 = Color(red: 0.5, green: 0.55, blue: 0.65)
    static let modaicsChrome3 = Color(red: 0.6, green: 0.65, blue: 0.75)
    
    // Denim blue for middle section
    static let modaicsDenim1 = Color(red: 0.2, green: 0.4, blue: 0.7)
    static let modaicsDenim2 = Color(red: 0.15, green: 0.3, blue: 0.6)
    
    // Cotton white variations
    static let modaicsCotton = Color.white.opacity(0.9)
    static let modaicsCottonLight = Color.white.opacity(0.6)
}

// MARK: - Custom Modifiers
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase * 200 - 100)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Custom Animations
extension Animation {
    static let modaicsSpring = Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.1)
    static let modaicsSmoothSpring = Animation.spring(response: 0.8, dampingFraction: 0.9, blendDuration: 0.1)
    static let modaicsElastic = Animation.spring(response: 1.2, dampingFraction: 0.6, blendDuration: 0.1)
}


// MARK: - Enhanced Main App View
struct MainAppView: View {
    let userType: ContentView.UserType
    @State private var selectedTab = 0
    @State private var contentOpacity: Double = 0
    @State private var tabBarOffset: CGFloat = 100
    
    init(userType: ContentView.UserType) {
        self.userType = userType
        
        // Customize tab bar appearance only on iOS
        #if canImport(UIKit)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.modaicsDarkBlue.opacity(0.95))
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.modaicsChrome1)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.modaicsChrome1)
        ]
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.modaicsChrome2.opacity(0.6))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.modaicsChrome2.opacity(0.6))
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(userType: userType)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            SellView(userType: userType)
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            CommunityView()
                .tabItem {
                    Label("Community", systemImage: "person.2.fill")
                }
                .tag(3)
            
            ProfileView(userType: userType)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .opacity(contentOpacity)
        .onAppear {
            withAnimation(.modaicsSpring) {
                contentOpacity = 1
                tabBarOffset = 0
            }
        }
    }
}

// MARK: - Premium Welcome Card
struct PremiumWelcomeCard: View {
    let userType: ContentView.UserType
    @State private var shimmerPhase: CGFloat = -1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(userType == .user ?
                 "Welcome to your sustainable fashion journey!" :
                 "Ready to showcase your sustainable collection?")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.modaicsCotton)
            
            Text(userType == .user ?
                 "Discover, swap, and add items to your digital wardrobe." :
                 "Manage your catalog, track sustainability metrics, and connect with conscious consumers.")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.modaicsCotton.opacity(0.8))
                .lineSpacing(4)
            
            Button(action: {}) {
                HStack {
                    Text(userType == .user ? "Get Started" : "View Analytics")
                        .fontWeight(.medium)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.modaicsDarkBlue)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.modaicsDarkBlue.opacity(0.6),
                            Color.modaicsMidBlue.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.modaicsChrome1.opacity(0.3), .modaicsChrome2.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
}

// MARK: - Premium Feature Tile
struct PremiumFeatureTile: View {
    let title: String
    let icon: String
    let gradient: [Color]
    let isVisible: Bool
    @State private var isPressed: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.3) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.modaicsCotton)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.modaicsDarkBlue.opacity(0.6),
                            Color.modaicsMidBlue.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: gradient.map { $0.opacity(0.3) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 15, y: 8)
        .scaleEffect(isPressed ? 0.95 : (isVisible ? 1.0 : 0.8))
        .opacity(isVisible ? 1.0 : 0)
        .onTapGesture {
            withAnimation(.modaicsSpring) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.modaicsSpring) {
                    isPressed = false
                }
            }
        }
    }
}
struct SimpleRecommender {
    static func similarItems(
        to target: FashionItem,
        in allItems: [FashionItem],
        maxResults: Int = 5
    ) -> [FashionItem] {
        let others = allItems.filter { $0.id != target.id }
        let scored = others.map { item -> (score: Int, item: FashionItem) in
            let commonTags = Set(item.tags).intersection(Set(target.tags))
            return (commonTags.count, item)
        }
        let filtered = scored
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }
            .map { $0.item }
        if filtered.isEmpty {
            return Array(others.prefix(maxResults))
        } else {
            return Array(filtered.prefix(maxResults))
        }
    }
}
