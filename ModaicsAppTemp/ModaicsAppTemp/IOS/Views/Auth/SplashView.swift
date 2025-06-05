//
//  SplashView.swift  (enhanced)
//  Modaics – Auth module
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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

