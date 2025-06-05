//
//  ModaicsLogo.swift
//  ModaicsAppTemp
//
//  Created by Harvey Houlahan on 6/6/2025.
//


//
//  ModaicsLogo.swift
//  Enhanced logo and brand components for Modaics
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
                            Color.modaicsChrome1.opacity(0.1),
                            Color.modaicsDarkBlue.opacity(0.05)
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
                            colors: [.modaicsChrome1, .modaicsChrome2, .modaicsChrome1],
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
                                colors: [.modaicsDenim1, .modaicsDenim2],
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
                                colors: [.modaicsCotton, .modaicsCottonLight],
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
                    colors: [.modaicsChrome1, .modaicsChrome2],
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
                .font(.system(size: size, weight: .ultraLight, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2, .modaicsChrome1],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
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
                    .font(.system(size: size, weight: .ultraLight, design: .serif))
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
    let size: CGFloat = 24
    @State private var leafRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.green.opacity(0.2),
                            Color.green.opacity(0.05)
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
                        colors: [.green, Color(red: 0.2, green: 0.6, blue: 0.3)],
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
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: size * 0.6, height: 2)
                    .rotationEffect(.degrees(Double(index) * 60))
                    .scaleEffect(pulseScale)
            }
            
            // Center nodes
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
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
    // Enhanced color palette
    static let modaicsPrimary = Color.modaicsChrome1
    static let modaicsSecondary = Color.modaicsDenim1
    static let modaicsAccent = Color(red: 0.2, green: 0.6, blue: 0.4) // Sustainable green
    static let modaicsWarning = Color(red: 0.9, green: 0.6, blue: 0.2) // Warm orange
    static let modaicsError = Color(red: 0.8, green: 0.3, blue: 0.3) // Soft red
    
    // Surface colors for better hierarchy
    static let modaicsSurface1 = Color.modaicsDarkBlue.opacity(0.8)
    static let modaicsSurface2 = Color.modaicsMidBlue.opacity(0.6)
    static let modaicsSurface3 = Color.modaicsLightBlue.opacity(0.4)
}

// MARK: - Brand Typography
extension Font {
    static func modaicsDisplay(_ size: CGFloat) -> Font {
        .system(size: size, weight: .ultraLight, design: .serif)
    }
    
    static func modaicsHeadline(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
    
    static func modaicsBody(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    
    static func modaicsCaption(_ size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .default)
    }
}