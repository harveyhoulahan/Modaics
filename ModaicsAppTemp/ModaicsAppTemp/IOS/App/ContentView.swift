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
                            withMosaicTransition {
                                currentStage = .login
                            }
                        }
                    })
                    .transition(.mosaicDissolve)
                    
                case .login:
                    LoginView(onUserSelect: { type in
                        userType = type
                        withMosaicTransition {
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
                            withMosaicTransition {
                                currentStage = .main
                            }
                        }
                    })
                    .transition(.mosaicAssemble)
                    
                case .transition:
                    MosaicTransitionView(userType: userType, contentReady: contentReady)
                        .transition(.opacity.combined(with: .scale))
                    
                case .main:
                    MosaicMainAppView(userType: userType ?? .user)
                        .environmentObject(viewModel)
                        .transition(.mosaicReveal)
                }
            }
        }
        .animation(.easeInOut(duration: 0.8), value: currentStage)
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
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Preload recommendations
        if let firstItem = viewModel.allItems.first {
            viewModel.loadRecommendations(for: firstItem)
        }
    }
}

// MARK: - Mosaic Transition View
struct MosaicTransitionView: View {
    let userType: ContentView.UserType?
    let contentReady: Bool
    
    @State private var tilePositions: [CGPoint] = []
    @State private var tilesVisible = false
    
    var body: some View {
        ZStack {
            // Animated mosaic pattern forming
            ForEach(0..<20, id: \.self) { index in
                MosaicTransitionTile(
                    index: index,
                    totalTiles: 20,
                    isVisible: tilesVisible
                )
            }
            
            VStack(spacing: 20) {
                ModaicsMosaicLogo(size: 80)
                    .scaleEffect(tilesVisible ? 1 : 0.8)
                    .opacity(tilesVisible ? 1 : 0)
                
                Text(userType == .user ? "Assembling your wardrobe..." : "Preparing your brand dashboard...")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.modaicsCotton)
                    .opacity(tilesVisible ? 1 : 0)
                
                MosaicLoadingIndicator()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                tilesVisible = true
            }
        }
    }
}

// MARK: - Mosaic Transition Tile
struct MosaicTransitionTile: View {
    let index: Int
    let totalTiles: Int
    let isVisible: Bool
    
    @State private var position: CGPoint = .zero
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        Color.modaicsChrome1.opacity(0.3),
                        Color.modaicsChrome2.opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 60, height: 60)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .position(position)
            .onAppear {
                calculateInitialPosition()
                if isVisible {
                    animateIn()
                }
            }
            .onChange(of: isVisible) { oldValue, newValue in
                if newValue {
                    animateIn()
                }
            }
    }
    
    private func calculateInitialPosition() {
        let angle = (Double(index) / Double(totalTiles)) * 2 * .pi
        let radius = 150.0
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2
        
        position = CGPoint(
            x: centerX + cos(angle) * radius * 2,
            y: centerY + sin(angle) * radius * 2
        )
        rotation = Double.random(in: 0...360)
    }
    
    private func animateIn() {
        let angle = (Double(index) / Double(totalTiles)) * 2 * .pi
        let radius = 100.0
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2
        
        withAnimation(
            .spring(response: 0.8, dampingFraction: 0.6)
            .delay(Double(index) * 0.05)
        ) {
            position = CGPoint(
                x: centerX + cos(angle) * radius,
                y: centerY + sin(angle) * radius
            )
            rotation = 0
            scale = 1
        }
    }
}

// MARK: - Custom Mosaic Transitions
extension AnyTransition {
    static var mosaicDissolve: AnyTransition {
        .asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .modifier(
                active: MosaicDissolveModifier(progress: 1),
                identity: MosaicDissolveModifier(progress: 0)
            )
        )
    }
    
    static var mosaicAssemble: AnyTransition {
        .modifier(
            active: MosaicAssembleModifier(progress: 0),
            identity: MosaicAssembleModifier(progress: 1)
        )
    }
    
    static var mosaicReveal: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: MosaicRevealModifier(progress: 0),
                identity: MosaicRevealModifier(progress: 1)
            ),
            removal: .scale.combined(with: .opacity)
        )
    }
}

// MARK: - Transition Modifiers
struct MosaicDissolveModifier: ViewModifier {
    let progress: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(1 - progress)
            .scaleEffect(1 - progress * 0.2)
            .blur(radius: progress * 10)
    }
}

struct MosaicAssembleModifier: ViewModifier {
    let progress: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(progress)
            .scaleEffect(0.8 + progress * 0.2)
            .rotationEffect(.degrees((1 - progress) * 5))
    }
}

struct MosaicRevealModifier: ViewModifier {
    let progress: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(progress)
            .mask(
                MosaicRevealMask(progress: progress)
            )
    }
}

struct MosaicRevealMask: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<5, id: \.self) { row in
                ForEach(0..<5, id: \.self) { col in
                    let index = row * 5 + col
                    let delay = Double(index) / 25.0
                    let tileProgress = max(0, min(1, (progress - delay) * 2))
                    
                    Rectangle()
                        .frame(
                            width: geometry.size.width / 5,
                            height: geometry.size.height / 5
                        )
                        .scaleEffect(tileProgress)
                        .position(
                            x: CGFloat(col) * geometry.size.width / 5 + geometry.size.width / 10,
                            y: CGFloat(row) * geometry.size.height / 5 + geometry.size.height / 10
                        )
                }
            }
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
