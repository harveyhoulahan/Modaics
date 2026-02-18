//
//  BrandAssets.swift
//  Modaics
//
//  Enhanced logo and brand components for Modaics
//  Dark Green Porsche Aesthetic
//

import SwiftUI

// MARK: - New Modaics Logo
struct ModaicsLogo: View {
    let size: CGFloat
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    init(size: CGFloat = 60) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background circle with subtle gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.luxeGold.opacity(0.1),
                            Color.forestDeep.opacity(0.05)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size/2
                    )
                )
                .frame(width: size, height: size)
                .scaleEffect(pulseScale)
            
            // Circular fashion cycle (main logo element)
            ZStack {
                // Outer ring - representing the circular economy
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.luxeGold, .luxeGoldBright, .luxeGold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: size * 0.06
                    )
                    .frame(width: size * 0.7, height: size * 0.7)
                    .rotationEffect(.degrees(rotationAngle))
                
                // Inner elements - fashion items flowing in circle
                ForEach(0..<6, id: \.self) { index in
                    FashionDot(
                        size: size * 0.08,
                        angle: Double(index) * 60 + rotationAngle,
                        radius: size * 0.25,
                        delay: Double(index) * 0.1
                    )
                }
                
                // Center element - sustainable core
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.emerald, .emeraldDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size * 0.25, height: size * 0.25)
                    
                    // Leaf symbol for sustainability
                    Image(systemName: "leaf.fill")
                        .font(.system(size: size * 0.08, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.sageWhite, .sageMuted],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
    }
}

// MARK: - Fashion Dot Component
struct FashionDot: View {
    let size: CGFloat
    let angle: Double
    let radius: CGFloat
    let delay: Double
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.6
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.luxeGold, .luxeGoldBright],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(
                x: cos(angle * .pi / 180) * radius,
                y: sin(angle * .pi / 180) * radius
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    scale = 1.2
                    opacity = 1.0
                }
            }
    }
}

// MARK: - Enhanced Mini Logo
struct MiniLogo: View {
    var body: some View {
        ModaicsLogo(size: 32)
    }
}

// MARK: - Brand Wordmark
struct ModaicsWordmark: View {
    let size: CGFloat
    @State private var shimmerOffset: CGFloat = -200
    
    init(size: CGFloat = 32) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Main text
            Text("modaics")
                .font(.forestDisplay(size))
                .foregroundStyle(.luxeGoldGradient)
            
            // Shimmer effect
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.4),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 60, height: size + 4)
            .offset(x: shimmerOffset)
            .mask(
                Text("modaics")
                    .font(.forestDisplay(size))
            )
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                shimmerOffset = 200
            }
        }
    }
}

// MARK: - Enhanced Feature Icons
struct SustainabilityIcon: View {
    var size: CGFloat
    @State private var leafRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.emerald.opacity(0.2),
                            Color.emerald.opacity(0.05)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size/2
                    )
                )
                .frame(width: size * 1.5, height: size * 1.5)
            
            // Animated leaf
            Image(systemName: "leaf.fill")
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.emerald, .organicGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(leafRotation))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                leafRotation = 10
            }
        }
    }
}

struct CommunityIcon: View {
    let size: CGFloat = 24
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Connection lines
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.natureTeal.opacity(0.3))
                    .frame(width: size * 0.6, height: 2)
                    .rotationEffect(.degrees(Double(index) * 60))
                    .scaleEffect(pulseScale)
            }
            
            // Center nodes
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.natureTeal, .forestLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.25, height: size * 0.25)
                    .offset(
                        x: cos(Double(index) * 120 * .pi / 180) * size * 0.3,
                        y: sin(Double(index) * 120 * .pi / 180) * size * 0.3
                    )
                    .scaleEffect(pulseScale)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.2
            }
        }
    }
}

// MARK: - Brand Colors Extension
extension Color {
    // Enhanced color palette - Porsche Dark Green Aesthetic
    static let modaicsPrimary = Color.luxeGold
    static let modaicsSecondary = Color.emerald
    static let modaicsAccent = Color.emerald
    static let modaicsWarning = Color.earthAmber
    static let modaicsError = Color.coralError
    
    // Surface colors for better hierarchy
    static let modaicsSurface1 = Color.forestDeep.opacity(0.8)
    static let modaicsSurface2 = Color.surfaceElevated
    static let modaicsSurface3 = Color.forestSoft.opacity(0.4)
}

// MARK: - Brand Typography
extension Font {
    static func modaicsDisplay(_ size: CGFloat) -> Font {
        .forestDisplay(size)
    }
    
    static func modaicsHeadline(_ size: CGFloat) -> Font {
        .forestHeadline(size)
    }
    
    static func modaicsBody(_ size: CGFloat) -> Font {
        .forestBody(size)
    }
    
    static func modaicsCaption(_ size: CGFloat) -> Font {
        .forestCaption(size)
    }
}

// MARK: - Color Theme Compatibility
// These ensure backward compatibility while using new theme
extension Color {
    // Dark sophisticated background colors
    static let modaicsDarkBlue = Color.forestDeep
    static let modaicsMidBlue = Color.forestRich
    static let modaicsLightBlue = Color.forestMid
    
    // Gold/metallic colors replace chrome
    static let modaicsChrome1 = Color.luxeGold
    static let modaicsChrome2 = Color.luxeGoldBright
    static let modaicsChrome3 = Color.luxeGoldDeep
    
    // Forest tones replace denim
    static let modaicsDenim1 = Color.forestSoft
    static let modaicsDenim2 = Color.forestLight
    
    // Sage whites replace cotton
    static let modaicsCotton = Color.sageWhite
    static let modaicsCottonLight = Color.sageMuted
}

// MARK: - Custom Modifiers
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    let speed: Double
    let angle: Double
    let intensity: Double
    
    init(speed: Double = 2.0, angle: Double = 30, intensity: Double = 0.6) {
        self.speed = speed
        self.angle = angle
        self.intensity = intensity
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.luxeGold.opacity(intensity * 0.3),
                            Color.luxeGoldBright.opacity(intensity * 0.5),
                            Color.luxeGold.opacity(intensity * 0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .rotationEffect(.degrees(angle))
                    .offset(x: phase * (geometry.size.width + 200) - 200)
                    .mask(content)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: speed).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer(speed: Double = 2.0, angle: Double = 30, intensity: Double = 0.6) -> some View {
        self.modifier(ShimmerEffect(speed: speed, angle: angle, intensity: intensity))
    }
}

// MARK: - Custom Animations
extension Animation {
    static let modaicsSpring = Animation.forestSpring
    static let modaicsSmoothSpring = Animation.forestElegant
    static let modaicsElastic = Animation.forestSpring
}

// MARK: - Preview
#Preview {
    ZStack {
        LinearGradient.forestBackground
            .ignoresSafeArea()
        
        VStack(spacing: 40) {
            ModaicsLogo(size: 100)
            
            ModaicsWordmark(size: 32)
            
            HStack(spacing: 20) {
                SustainabilityIcon(size: 24)
                CommunityIcon()
            }
        }
    }
}
