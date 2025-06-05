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

// MARK: - Main Content View
// Remove the ModaicsApp declaration as it's already in ContentView.swift
struct ContentView: View {
    @State private var currentStage: AppStage = .splash
    @State private var logoAnimationComplete = false
    @State private var contentReady = false
    @State private var userType: UserType?
    
    #if canImport(UIKit)
    @State private var hapticImpact = UIImpactFeedbackGenerator(style: .medium)
    #endif
    
    enum AppStage {
        case splash, login, transition, main
    }
    
    enum UserType {
        case user, brand
    }
    
    var body: some View {
        ZStack {
            // Sophisticated gradient background
            LinearGradient(
                colors: [.modaicsDarkBlue, .modaicsMidBlue, .modaicsLightBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            switch currentStage {
            case .splash:
                SplashView(onAnimationComplete: {
                    logoAnimationComplete = true
                    #if canImport(UIKit)
                    hapticImpact.impactOccurred()
                    #endif
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.modaicsSpring) {
                            currentStage = .login
                        }
                    }
                })
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .opacity)
                ))
                
            case .login:
                LoginView(onUserSelect: { type in
                    userType = type
                    #if canImport(UIKit)
                    hapticImpact.impactOccurred()
                    #endif
                    withAnimation(.modaicsSpring) {
                        currentStage = .transition
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        contentReady = true
                        withAnimation(.modaicsSpring) {
                            currentStage = .main
                        }
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
            case .transition:
                TransitionView(userType: userType, contentReady: contentReady)
                    .transition(.opacity.combined(with: .scale(scale: 1.1)))
                
            case .main:
                MainAppView(userType: userType ?? .user)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 1.1).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
            }
        }
        .animation(.modaicsSpring, value: currentStage)
    }
}

// MARK: - Enhanced Splash Screen
struct SplashView: View {
    let onAnimationComplete: () -> Void
    @State private var leftDoorRotation: Double = 0
    @State private var rightDoorRotation: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 30
    @State private var shimmerPhase: CGFloat = -1
    @State private var cottonItemOffsets: [CGFloat] = Array(repeating: 0, count: 5)
    @State private var reflectionOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            VStack(spacing: 40) {
                // Sophisticated Logo Animation
                ZStack {
                    // Ambient glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.modaicsChrome1.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .blur(radius: 20)
                        .opacity(contentOpacity)
                    
                    // Chrome wardrobe doors with advanced effects
                    ZStack {
                        // Left door - premium chrome finish
                        ChromeDoor(isLeft: true)
                            .rotationEffect(.degrees(leftDoorRotation), anchor: .leading)
                            .offset(x: -50, y: 0)
                        
                        // Middle section - premium denim with cotton items
                        MiddleSection(
                            contentOpacity: contentOpacity,
                            cottonItemOffsets: cottonItemOffsets
                        )
                        
                        // Right door - premium chrome finish
                        ChromeDoor(isLeft: false)
                            .rotationEffect(.degrees(rightDoorRotation), anchor: .trailing)
                            .offset(x: 50, y: 0)
                    }
                    .scaleEffect(logoScale)
                    
                    // Premium reflection effect
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.8),
                                    Color.white.opacity(0.4),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 140, height: 4)
                        .offset(y: -60)
                        .opacity(reflectionOpacity)
                        .blur(radius: 1)
                }
                .frame(height: 140)
                
                // Premium typography with effects
                VStack(spacing: 12) {
                    HStack(spacing: 0) {
                        Text("m")
                            .font(.system(size: 64, weight: .ultraLight, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.modaicsChrome1, .modaicsChrome2],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("odaics")
                            .font(.system(size: 64, weight: .ultraLight, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.modaicsChrome1, .modaicsChrome2],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .modifier(ShimmerEffect())
                    
                    Text("A digital wardrobe for sustainable fashion")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.modaicsCotton.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Text("Born from Australian Cotton Farms")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.modaicsChrome1.opacity(0.8))
                        .opacity(textOpacity * 0.8)
                }
                .opacity(textOpacity)
                .offset(y: textOffset)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Staggered premium animation sequence
        withAnimation(.modaicsElastic.delay(0.3)) {
            logoScale = 1.0
        }
        
        withAnimation(.modaicsElastic.delay(0.5)) {
            leftDoorRotation = -45
            rightDoorRotation = 45
        }
        
        withAnimation(.modaicsSpring.delay(0.8)) {
            contentOpacity = 1
            
            // Animate cotton items with stagger
            for i in 0..<5 {
                withAnimation(.modaicsSpring.delay(0.8 + Double(i) * 0.1)) {
                    cottonItemOffsets[i] = CGFloat.random(in: -3...3)
                }
            }
        }
        
        withAnimation(.modaicsSmoothSpring.delay(1.0)) {
            textOpacity = 1
            textOffset = 0
        }
        
        withAnimation(.easeInOut(duration: 1.5).delay(1.2)) {
            reflectionOpacity = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onAnimationComplete()
        }
    }
}

// MARK: - Chrome Door Component
struct ChromeDoor: View {
    let isLeft: Bool
    @State private var handleGlow: Bool = false
    
    var body: some View {
        ZStack {
            // Main door body with premium gradient
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: isLeft ?
                            [.modaicsChrome1, .modaicsChrome2, .modaicsChrome3] :
                            [.modaicsChrome3, .modaicsChrome2, .modaicsChrome1],
                        startPoint: isLeft ? .topLeading : .topTrailing,
                        endPoint: isLeft ? .bottomTrailing : .bottomLeading
                    )
                )
                .frame(width: 45, height: 130)
                .overlay(
                    // Metallic sheen effect
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear,
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .blendMode(.overlay)
                )
            
            // Cotton texture overlay
            VStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 28, height: 2)
                        .blur(radius: 0.5)
                }
            }
            
            // Premium chrome handle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, .modaicsChrome1],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: 8
                    )
                )
                .frame(width: 10, height: 10)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 0.5)
                )
                .scaleEffect(handleGlow ? 1.2 : 1.0)
                .offset(x: isLeft ? 15 : -15, y: 0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2).repeatForever()) {
                        handleGlow = true
                    }
                }
        }
    }
}

// MARK: - Middle Section Component
struct MiddleSection: View {
    let contentOpacity: Double
    let cottonItemOffsets: [CGFloat]
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [.modaicsDenim1, .modaicsDenim2],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 45, height: 130)
            .overlay(
                // Cotton items with animation
                VStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [.modaicsCotton, .modaicsCottonLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 32, height: 5)
                            .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                            .offset(x: cottonItemOffsets[i])
                    }
                }
                .opacity(contentOpacity)
            )
    }
}

// MARK: - Enhanced Login Screen
struct LoginView: View {
    let onUserSelect: (ContentView.UserType) -> Void
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 30
    @State private var featureAnimations: [Bool] = Array(repeating: false, count: 3)
    @State private var buttonScale: [CGFloat] = [1.0, 1.0]
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Premium header
                    HStack {
                        MiniLogo()
                        
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
                    
                    VStack(spacing: 40) {
                        // Welcome content with premium styling
                        VStack(spacing: 20) {
                            Text("Welcome to your\ndigital wardrobe")
                                .font(.system(size: 36, weight: .ultraLight, design: .serif))
                                .foregroundColor(.modaicsCotton)
                                .multilineTextAlignment(.center)
                                .lineSpacing(8)
                            
                            Text("Modaics helps you discover, swap, and sell fashion items while reducing your environmental footprint.")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(.modaicsCotton.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .lineSpacing(4)
                        }
                        .opacity(contentOpacity)
                        .offset(y: contentOffset)
                        
                        // Premium feature cards
                        VStack(spacing: 20) {
                            ForEach(0..<3, id: \.self) { index in
                                PremiumFeatureCard(
                                    icon: ["checkmark.seal.fill", "person.2.fill", "sparkles"][index],
                                    title: ["Verified Sustainability", "Community-Driven", "AI-Powered Styling"][index],
                                    description: [
                                        "Track your environmental impact with FibreTrace technology",
                                        "Connect with like-minded fashion enthusiasts locally",
                                        "Get personalized recommendations that match your style"
                                    ][index],
                                    isVisible: featureAnimations[index]
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Premium action buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            buttonScale[0] = 0.95
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                buttonScale[0] = 1.0
                                onUserSelect(.user)
                            }
                        }) {
                            HStack {
                                Image(systemName: "person.fill")
                                Text("Continue as User")
                                    .fontWeight(.medium)
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
                        .scaleEffect(buttonScale[0])
                        .animation(.modaicsSpring, value: buttonScale[0])
                        
                        Button(action: {
                            buttonScale[1] = 0.95
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                buttonScale[1] = 1.0
                                onUserSelect(.brand)
                            }
                        }) {
                            HStack {
                                Image(systemName: "building.2.fill")
                                Text("Continue as Brand")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.modaicsChrome1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.modaicsDarkBlue.opacity(0.5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.modaicsChrome1, .modaicsChrome2],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .scaleEffect(buttonScale[1])
                        .animation(.modaicsSpring, value: buttonScale[1])
                        
                        Text("By continuing, you agree to our Terms and Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.modaicsChrome1.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.top, 10)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            withAnimation(.modaicsSpring.delay(0.2)) {
                contentOpacity = 1
                contentOffset = 0
            }
            
            // Stagger feature animations
            for i in 0..<3 {
                withAnimation(.modaicsSpring.delay(0.5 + Double(i) * 0.2)) {
                    featureAnimations[i] = true
                }
            }
        }
    }
}

// MARK: - Premium Feature Card
struct PremiumFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let isVisible: Bool
    
    var body: some View {
        HStack(spacing: 18) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.modaicsDenim1.opacity(0.3), .modaicsDenim2.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.modaicsChrome1, .modaicsChrome2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.modaicsCotton)
                
                Text(description)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.modaicsCotton.opacity(0.7))
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -30)
    }
}

// MARK: - Enhanced Transition Screen
struct TransitionView: View {
    let userType: ContentView.UserType?
    let contentReady: Bool
    @State private var wardrobeScale: CGFloat = 1
    @State private var wardrobeOpacity: Double = 1
    @State private var leftDoorRotation: Double = -45
    @State private var rightDoorRotation: Double = 45
    @State private var cottonItemScales: [CGFloat] = Array(repeating: 0.8, count: 5)
    @State private var loadingDots: [Bool] = Array(repeating: false, count: 3)
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            VStack(spacing: 50) {
                // Expanding wardrobe with advanced effects
                ZStack {
                    // Pulsing glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.modaicsChrome1.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)
                        .scaleEffect(pulseScale)
                        .opacity(wardrobeOpacity)
                    
                    // Wardrobe doors
                    ZStack {
                        ChromeDoor(isLeft: true)
                            .rotationEffect(.degrees(leftDoorRotation), anchor: .leading)
                            .offset(x: -50, y: 0)
                        
                        // Middle section with animated content
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.modaicsDenim1, .modaicsDenim2],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 45, height: 130)
                            .overlay(
                                VStack(spacing: 8) {
                                    ForEach(0..<5, id: \.self) { i in
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(
                                                userType == .brand ?
                                                LinearGradient(
                                                    colors: [.modaicsChrome1, .modaicsChrome2],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ) :
                                                LinearGradient(
                                                    colors: [.modaicsCotton, .modaicsCottonLight],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: 32, height: userType == .brand ? 6 : 5)
                                            .scaleEffect(cottonItemScales[i])
                                    }
                                }
                            )
                        
                        ChromeDoor(isLeft: false)
                            .rotationEffect(.degrees(rightDoorRotation), anchor: .trailing)
                            .offset(x: 50, y: 0)
                    }
                    .scaleEffect(wardrobeScale)
                }
                .opacity(wardrobeOpacity)
                
                // Premium loading indicator
                VStack(spacing: 24) {
                    Text(userType == .user ? "Preparing your wardrobe..." : "Setting up your brand dashboard...")
                        .font(.system(size: 24, weight: .ultraLight, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.modaicsChrome1, .modaicsChrome2],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.modaicsChrome1, .modaicsChrome2],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 10, height: 10)
                                .scaleEffect(loadingDots[index] ? 1.5 : 1.0)
                                .opacity(loadingDots[index] ? 1.0 : 0.5)
                        }
                    }
                }
                .opacity(wardrobeOpacity)
            }
        }
        .onAppear {
            startTransition()
        }
        .onChange(of: contentReady) { _, newValue in
            if newValue {
                withAnimation(.modaicsSpring) {
                    wardrobeOpacity = 0
                }
            }
        }
    }
    
    private func startTransition() {
        // Sophisticated transition sequence
        withAnimation(.modaicsElastic) {
            leftDoorRotation = -70
            rightDoorRotation = 70
            wardrobeScale = 1.3
        }
        
        // Animate cotton items
        for i in 0..<5 {
            withAnimation(.modaicsSpring.delay(Double(i) * 0.1)) {
                cottonItemScales[i] = 1.0
            }
        }
        
        // Pulsing effect
        withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
            pulseScale = 1.2
        }
        
        // Loading dots animation
        for i in 0..<3 {
            withAnimation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.2)) {
                loadingDots[i] = true
            }
        }
    }
}

// MARK: - Mini Logo Component
struct MiniLogo: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 4, height: 16)
                .rotationEffect(.degrees(-40), anchor: .topLeading)
                .offset(x: -4, y: 0)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.modaicsDenim1, .modaicsDenim2],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4, height: 16)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.modaicsChrome2, .modaicsChrome3],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 4, height: 16)
                .rotationEffect(.degrees(40), anchor: .topTrailing)
                .offset(x: 4, y: 0)
        }
        .frame(width: 20, height: 20)
    }
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
            
            CreateView(userType: userType)
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

// MARK: - Enhanced Home View
struct HomeView: View {
    let userType: ContentView.UserType
    @State private var headerOffset: CGFloat = -50
    @State private var cardsVisible: [Bool] = Array(repeating: false, count: 4)
    @State private var welcomeScale: CGFloat = 0.9
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Sophisticated background
                LinearGradient(
                    colors: [.modaicsDarkBlue, .modaicsMidBlue],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Premium header
                        HStack {
                            MiniLogo()
                            
                            Text("modaics")
                                .font(.system(size: 24, weight: .ultraLight, design: .serif))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.modaicsChrome1, .modaicsChrome2],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Spacer()
                            
                            HStack(spacing: 20) {
                                Button(action: {}) {
                                    Image(systemName: "bell")
                                        .font(.title3)
                                        .foregroundColor(.modaicsChrome1)
                                }
                                
                                Button(action: {}) {
                                    Image(systemName: "gearshape")
                                        .font(.title3)
                                        .foregroundColor(.modaicsChrome1)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .offset(y: headerOffset)
                        
                        Text(userType == .user ? "Your Digital Wardrobe" : "Brand Dashboard")
                            .font(.system(size: 36, weight: .ultraLight, design: .serif))
                            .foregroundColor(.modaicsCotton)
                            .padding(.horizontal, 20)
                            .offset(y: headerOffset)
                        
                        // Welcome card with premium design
                        PremiumWelcomeCard(userType: userType)
                            .padding(.horizontal, 20)
                            .scaleEffect(welcomeScale)
                        
                        // Feature grid with staggered animation
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2),
                            spacing: 16
                        ) {
                            ForEach(0..<4, id: \.self) { index in
                                PremiumFeatureTile(
                                    title: getFeatureTitle(index: index),
                                    icon: getFeatureIcon(index: index),
                                    gradient: getFeatureGradient(index: index),
                                    isVisible: cardsVisible[index]
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                    .padding(.vertical)
                }
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
        .onAppear {
            withAnimation(.modaicsSpring) {
                headerOffset = 0
                welcomeScale = 1.0
            }
            
            // Stagger feature cards
            for i in 0..<4 {
                withAnimation(.modaicsSpring.delay(Double(i) * 0.1 + 0.3)) {
                    cardsVisible[i] = true
                }
            }
        }
    }
    
    private func getFeatureTitle(index: Int) -> String {
        let titles = [
            userType == .user ? "Discover Items" : "Manage Catalog",
            userType == .user ? "My Wardrobe" : "Brand Profile",
            "Sustainability Score",
            userType == .user ? "Community" : "Customer Insights"
        ]
        return titles[index]
    }
    
    private func getFeatureIcon(index: Int) -> String {
        ["magnifyingglass", "square.grid.3x3.fill", "leaf.fill", "chart.bar.fill"][index]
    }
    
    private func getFeatureGradient(index: Int) -> [Color] {
        [
            [.modaicsDenim1, .modaicsDenim2],
            [.modaicsChrome1, .modaicsChrome2],
            [Color(red: 0.2, green: 0.6, blue: 0.4), Color(red: 0.15, green: 0.5, blue: 0.3)],
            [.modaicsChrome2, .modaicsChrome3]
        ][index]
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

// MARK: - Other Tab Views with Premium Styling
struct DiscoverView: View {
    @StateObject private var viewModel = FashionViewModel()
    @State private var searchText: String = ""

    var filteredItems: [FashionItem] {
        guard !searchText.isEmpty else { return viewModel.items }
        return viewModel.items.filter {
            $0.name.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.modaicsDarkBlue, .modaicsMidBlue],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack {
                    // — MARK: Search Bar —
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.modaicsChrome1)

                        TextField("Search sustainable fashion...", text: $searchText)
                            .foregroundColor(.modaicsCotton)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.modaicsDarkBlue.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.modaicsChrome1.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)

                    // — MARK: List of Items —
                    List {
                        ForEach(filteredItems) { item in
                            NavigationLink(destination: ItemDetailView(item: item)) {
                                HStack(spacing: 16) {
                                    Image(item.imageName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipped()
                                        .cornerRadius(8)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.modaicsCotton)
                                        Text(String(format: "$%.2f", item.price))
                                            .font(.system(size: 14, weight: .light))
                                            .foregroundColor(.modaicsCotton.opacity(0.7))
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .listRowBackground(Color.modaicsMidBlue.opacity(0.3))
                        }
                    }
                    .listStyle(PlainListStyle())
                    .accentColor(.modaicsChrome1)
                }
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
    }
}


struct CreateView: View {
    let userType: ContentView.UserType
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.modaicsDarkBlue, .modaicsMidBlue],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.modaicsChrome1, .modaicsChrome2],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: .modaicsChrome1.opacity(0.5), radius: 20)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.modaicsDarkBlue)
                    }
                    
                    Text(userType == .user ? "List & Sell" : "Add Product")
                        .font(.system(size: 36, weight: .ultraLight, design: .serif))
                        .foregroundColor(.modaicsCotton)
                        .padding(.top, 30)
                    
                    Spacer()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct CommunityView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.modaicsDarkBlue, .modaicsMidBlue],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                Text("Community")
                    .font(.system(size: 48, weight: .ultraLight, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.modaicsChrome1, .modaicsChrome2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
    }
}

struct ProfileView: View {
    let userType: ContentView.UserType
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.modaicsDarkBlue, .modaicsMidBlue],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Profile avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.modaicsChrome1.opacity(0.3), .modaicsChrome2.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.modaicsChrome1, .modaicsChrome2],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Text(userType == .user ? "Your Profile" : "Brand Profile")
                        .font(.system(size: 36, weight: .ultraLight, design: .serif))
                        .foregroundColor(.modaicsCotton)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: – Item Detail Screen

struct ItemDetailView: View {
    let item: FashionItem

    // 1. Add @State for storing similar items
    @State private var similarItems: [FashionItem] = []

    // 2. Load similar items (using your SimpleRecommender or ViewModel)
    private func loadSimilarItems() {
        let all = FashionViewModel().items
        self.similarItems = SimpleRecommender.similarItems(to: item, in: all, maxResults: 5)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Large image at top
                Image(item.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .clipped()

                // Name, price, description
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.modaicsCotton)

                    Text(String(format: "$%.2f", item.price))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.modaicsChrome1)

                    Text(item.description)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.modaicsCotton.opacity(0.8))
                        .lineSpacing(4)
                        .padding(.top, 8)
                }
                .padding(.horizontal)

                Spacer()

                // “Add to Wardrobe” button
                Button(action: {
                    // TODO: Hook up “Add to Wardrobe” logic
                }) {
                    Text("Add to Wardrobe")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.modaicsDarkBlue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.modaicsChrome1, .modaicsChrome2],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom, 30)

                // “People also like” horizontal strip
                if !similarItems.isEmpty {
                    Text("People also like")
                        .font(.headline)
                        .foregroundColor(.modaicsCotton)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(similarItems) { sim in
                                VStack {
                                    Image(sim.imageName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(8)

                                    Text(sim.name)
                                        .font(.caption)
                                        .foregroundColor(.modaicsCotton)
                                        .lineLimit(1)
                                }
                                .onTapGesture {
                                    // Optional: navigate to sim item’s detail
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
        }
        .background(
            LinearGradient(
                colors: [.modaicsDarkBlue, .modaicsMidBlue],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // iOS: back button auto‐provided by NavigationLink
        }
        .onAppear {
            loadSimilarItems()
        }
    }
}
