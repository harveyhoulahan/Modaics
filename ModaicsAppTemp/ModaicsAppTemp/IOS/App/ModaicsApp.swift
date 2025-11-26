//
//  MosaicMainAppView.swift
//  ModaicsAppTemp
//
//  Created by Harvey Houlahan on 8/6/2025.
//


//
//  MosaicMainAppView.swift
//  Modaics - Main app structure with mosaic-themed navigation
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Enhanced Main App View with Mosaic Navigation
struct MosaicMainAppView: View {
    let userType: ContentView.UserType
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var selectedTab = 0
    @State private var tabConnections: [TabConnection] = []
    @State private var mosaicPulse: CGFloat = 1.0
    
    struct TabConnection {
        let from: Int
        let to: Int
        let strength: CGFloat
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case 0:
                    HomeView(userType: userType)
                        .environmentObject(viewModel)
                case 1:
                    DiscoverView()
                        .environmentObject(viewModel)
                case 2:
                    SmartCreateView(userType: userType)
                        .environmentObject(viewModel)
                case 3:
                    CommunityView()
                        .environmentObject(viewModel)
                case 4:
                    ProfileView(userType: userType)
                        .environmentObject(viewModel)
                default:
                    EmptyView()
                }
            }
            
            // Simplified tab bar
            SimplifiedTabBar(
                selectedTab: $selectedTab,
                userType: userType
            )
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
    }
}

// MARK: - Simplified Tab Bar
struct SimplifiedTabBar: View {
    @Binding var selectedTab: Int
    let userType: ContentView.UserType
    
    private let tabs = [
        ("Home", "house.fill"),
        ("Discover", "magnifyingglass"),
        ("Create", "plus.circle.fill"),
        ("Community", "person.2.fill"),
        ("Profile", "person.fill")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].1)
                            .font(.system(size: 22))
                            .foregroundColor(selectedTab == index ? .modaicsChrome1 : .modaicsCottonLight.opacity(0.6))
                        
                        Text(tabs[index].0)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedTab == index ? .modaicsChrome1 : .modaicsCottonLight.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.bottom, 8)
        .background(Color.modaicsDarkBlue)
    }
}

// MARK: - Old Complex Tab Bar (keeping for reference, not used)
struct MosaicTabBar: View {
    @Binding var selectedTab: Int
    let userType: ContentView.UserType
    @Binding var connections: [MosaicMainAppView.TabConnection]
    
    @State private var tileScales: [CGFloat] = Array(repeating: 1.0, count: 5)
    @State private var connectionOpacity: Double = 0.3
    
    let tabIcons = ["house.fill", "magnifyingglass", "plus.circle.fill", "person.2.fill", "person.fill"]
    let tabTitles = ["Home", "Discover", "Create", "Community", "Profile"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Connection lines between tabs
                Canvas { context, size in
                    for connection in connections {
                        drawConnection(
                            context: context,
                            size: size,
                            from: connection.from,
                            to: connection.to,
                            strength: connection.strength
                        )
                    }
                }
                .opacity(connectionOpacity)
                
                // Tab items
                HStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { index in
                        MosaicTabItem(
                            icon: tabIcons[index],
                            title: tabTitles[index],
                            isSelected: selectedTab == index,
                            scale: tileScales[index]
                        )
                        .onTapGesture {
                            selectTab(index)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(height: 88)
        .onAppear {
            animateConnections()
        }
    }
    
    private func selectTab(_ index: Int) {
        let previousTab = selectedTab
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Animate selection
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedTab = index
            
            // Scale animation for selected tile
            tileScales[index] = 1.2
            
            // Create ripple effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    tileScales[index] = 1.0
                }
            }
        }
        
        // Update connections
        updateConnections(from: previousTab, to: index)
    }
    
    private func updateConnections(from: Int, to: Int) {
        // Strengthen connection between selected tabs
        if let index = connections.firstIndex(where: {
            ($0.from == from && $0.to == to) || ($0.from == to && $0.to == from)
        }) {
            withAnimation(.easeInOut(duration: 0.5)) {
                connections[index] = MosaicMainAppView.TabConnection(
                    from: from,
                    to: to,
                    strength: min(1.0, connections[index].strength + 0.1)
                )
            }
        }
    }
    
    private func animateConnections() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            connectionOpacity = 0.6
        }
    }
    
    private func drawConnection(context: GraphicsContext, size: CGSize, from: Int, to: Int, strength: CGFloat) {
        let itemWidth = size.width / 5
        let fromX = CGFloat(from) * itemWidth + itemWidth / 2
        let toX = CGFloat(to) * itemWidth + itemWidth / 2
        let y = size.height / 2
        
        var path = Path()
        path.move(to: CGPoint(x: fromX, y: y))
        
        // Create curved connection
        let controlY = y - 20 * strength
        path.addQuadCurve(
            to: CGPoint(x: toX, y: y),
            control: CGPoint(x: (fromX + toX) / 2, y: controlY)
        )
        
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [
                    Color.modaicsChrome1.opacity(strength * 0.3),
                    Color.modaicsChrome2.opacity(strength * 0.5),
                    Color.modaicsChrome1.opacity(strength * 0.3)
                ]),
                startPoint: CGPoint(x: fromX, y: y),
                endPoint: CGPoint(x: toX, y: y)
            ),
            lineWidth: 2 * strength
        )
    }
}

// MARK: - Mosaic Tab Item
struct MosaicTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let scale: CGFloat
    
    @State private var tileRotation: Double = 0
    @State private var glowIntensity: Double = 0
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Hexagonal background
                HexagonShape()
                    .fill(
                        LinearGradient(
                            colors: isSelected ?
                                [Color.modaicsChrome1, Color.modaicsChrome2] :
                                [Color.modaicsChrome2.opacity(0.3), Color.modaicsChrome3.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(
                        color: isSelected ? Color.modaicsChrome1.opacity(0.5) : .clear,
                        radius: isSelected ? 8 : 0,
                        y: 2
                    )
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(tileRotation))
                
                // Glow effect for selected state
                if isSelected {
                    HexagonShape()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.5), Color.modaicsChrome1.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 44, height: 44)
                        .scaleEffect(scale * (1 + glowIntensity * 0.1))
                        .blur(radius: 1)
                }
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .modaicsDarkBlue : .modaicsCotton.opacity(0.7))
                    .scaleEffect(scale)
            }
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isSelected ? .modaicsChrome1 : .modaicsCotton.opacity(0.6))
                .scaleEffect(isSelected ? 1 : 0.9)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            if isSelected {
                animateSelection()
            }
        }
        .onChange(of: isSelected) { oldValue, newValue in
            if newValue {
                animateSelection()
            }
        }
    }
    
    private func animateSelection() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            tileRotation = 360
        }
        
        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            glowIntensity = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            tileRotation = 0
        }
    }
}

// MARK: - Mosaic Background View
struct MosaicBackgroundView: View {
    let activeTab: Int
    @State private var tiles: [BackgroundTile] = []
    @State private var animationPhase: Double = 0
    
    struct BackgroundTile: Identifiable {
        let id = UUID()
        var position: CGPoint
        var size: CGFloat
        var color: Color
        var opacity: Double
        var rotation: Double
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1)) { timeline in
            Canvas { context, size in
                for tile in tiles {
                    drawTile(context: &context, tile: tile, time: timeline.date.timeIntervalSince1970)
                }
            }
        }
        .onAppear {
            generateTiles()
        }
        .onChange(of: activeTab) { oldTab, newTab in
            animateTileTransition(from: oldTab, to: newTab)
        }
    }
    
    private func generateTiles() {
        tiles = (0..<30).map { index in
            BackgroundTile(
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                ),
                size: CGFloat.random(in: 20...60),
                color: [Color.modaicsChrome1, .modaicsChrome2, .modaicsChrome3, .modaicsDenim1].randomElement()!,
                opacity: Double.random(in: 0.05...0.15),
                rotation: Double.random(in: 0...360)
            )
        }
    }
    
    private func drawTile(context: inout GraphicsContext, tile: BackgroundTile, time: TimeInterval) {
            let animatedY = tile.position.y + sin(time + Double(tile.id.hashValue)) * 20
            let animatedRotation = tile.rotation + time * 10
            
            context.opacity = tile.opacity
            context.translateBy(x: tile.position.x, y: animatedY)
            context.rotate(by: .degrees(animatedRotation))
            
            let rect = CGRect(x: -tile.size/2, y: -tile.size/2, width: tile.size, height: tile.size)
            context.fill(
                RoundedRectangle(cornerRadius: tile.size * 0.2).path(in: rect),
                with: .linearGradient(
                    Gradient(colors: [tile.color, tile.color.opacity(0.5)]),
                    startPoint: rect.origin,
                    endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                )
            )
        }
    
    private func animateTileTransition(from: Int, to: Int) {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            // Rearrange tiles based on new tab
            for index in tiles.indices {
                tiles[index].opacity = Double.random(in: 0.05...0.15)
                tiles[index].rotation += Double(to - from) * 45
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
