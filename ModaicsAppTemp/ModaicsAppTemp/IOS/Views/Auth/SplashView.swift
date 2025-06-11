//
//  EnhancedSplashView.swift
//  ModaicsAppTemp
//
//  Created by Harvey Houlahan on 8/6/2025.
//


//
//  SplashView.swift
//  Modaics - A mesmerizing mosaic-themed splash screen
//

import SwiftUI

struct SplashView: View {
    let onAnimationComplete: () -> Void
    
    // Animation states
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var logoRotation: Double = -180
    @State private var mosaicTilesVisible = false
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 50
    @State private var shimmerOffset: CGFloat = -300
    @State private var backgroundTiles: [TileData] = []
    @State private var taglineOpacity: Double = 0
    
    // Mosaic tile data for background animation
    struct TileData: Identifiable {
        let id = UUID()
        let position: CGPoint
        let size: CGFloat
        let color: Color
        let delay: Double
        let rotation: Double
        var opacity: Double = 0
        var scale: CGFloat = 0
    }
    
    var body: some View {
        ZStack {
            // Dynamic mosaic background
            backgroundMosaic
            
            // Main content
            VStack(spacing: 40) {
                Spacer()
                
                // Main mosaic logo with effects
                ZStack {
                    // Secondary glow layer
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.modaicsChrome1.opacity(0.3),
                                    Color.modaicsDenim1.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 30)
                        .scaleEffect(logoScale * 1.5)
                        .opacity(logoOpacity)
                    
                    // Main logo
                    ModaicsMosaicLogo(size: 140)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .rotationEffect(.degrees(logoRotation))
                }
                
                // Brand typography with shimmer
                VStack(spacing: 16) {
                    ZStack {
                        Text("modaics")
                            .font(.system(size: 56, weight: .ultraLight, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.modaicsChrome1, .modaicsChrome2, .modaicsChrome3],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        // Shimmer overlay
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 80)
                        .offset(x: shimmerOffset)
                        .mask(
                            Text("modaics")
                                .font(.system(size: 56, weight: .ultraLight, design: .serif))
                        )
                    }
                    
                    Text("A digital mosaic of sustainable fashion")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.modaicsCotton.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(taglineOpacity)
                    
                    HStack(spacing: 20) {
                        FeatureTag(icon: "leaf.fill", text: "Sustainable")
                        FeatureTag(icon: "person.2.fill", text: "Community")
                        FeatureTag(icon: "sparkles", text: "AI-Powered")
                    }
                    .opacity(taglineOpacity * 0.8)
                }
                .opacity(textOpacity)
                .offset(y: textOffset)
                
                Spacer()
                
                // Loading indicator
                MosaicLoadingIndicator()
                    .opacity(textOpacity)
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            generateBackgroundTiles()
            startAnimationSequence()
        }
        .onDisappear{
            backgroundTiles.removeAll()
        }
    }
    
    // MARK: - Background Mosaic
    private var backgroundMosaic: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.modaicsDarkBlue,
                    Color.modaicsMidBlue,
                    Color.modaicsLightBlue.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated mosaic tiles
            ForEach(backgroundTiles) { tile in
                MosaicBackgroundTile(
                    color: tile.color,
                    size: tile.size,
                    rotation: tile.rotation
                )
                .position(tile.position)
                .opacity(tile.opacity)
                .scaleEffect(tile.scale)
            }
        }
    }
    
    // MARK: - Animation Sequence
    private func startAnimationSequence() {
        // Logo entrance
        withAnimation(.spring(response: 1.2, dampingFraction: 0.7, blendDuration: 0)) {
            logoScale = 1.0
            logoOpacity = 1.0
            logoRotation = 0
        }
        
        // Background tiles cascade
        for (index, _) in backgroundTiles.enumerated() {
            withAnimation(
                .spring(response: 0.8, dampingFraction: 0.6)
                .delay(Double(index) * 0.02 + 0.3)
            ) {
                backgroundTiles[index].opacity = 0.15
                backgroundTiles[index].scale = 1.0
            }
        }
        
        // Text appearance
        withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
            textOpacity = 1.0
            textOffset = 0
        }
        
        // Shimmer effect
        withAnimation(.linear(duration: 2).delay(1.2).repeatForever(autoreverses: false)) {
            shimmerOffset = 300
        }
        
        // Tagline fade in
        withAnimation(.easeIn(duration: 0.6).delay(1.0)) {
            taglineOpacity = 1.0
        }
        
        // Trigger completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            onAnimationComplete()
        }
    }
    
    // MARK: - Generate Background Tiles
    private func generateBackgroundTiles() {
        let tileCount = 50
        let colors: [Color] = [
            .modaicsChrome1.opacity(0.3),
            .modaicsChrome2.opacity(0.3),
            .modaicsChrome3.opacity(0.3),
            .modaicsDenim1.opacity(0.2),
            .modaicsDenim2.opacity(0.2)
        ]
        
        for _ in 0..<tileCount {
            let randomX = CGFloat.random(in: 0...UIScreen.main.bounds.width)
            let randomY = CGFloat.random(in: 0...UIScreen.main.bounds.height)
            let randomSize = CGFloat.random(in: 20...60)
            let randomColor = colors.randomElement() ?? .modaicsChrome1
            let randomDelay = Double.random(in: 0...0.5)
            let randomRotation = Double.random(in: 0...360)
            
            backgroundTiles.append(
                TileData(
                    position: CGPoint(x: randomX, y: randomY),
                    size: randomSize,
                    color: randomColor,
                    delay: randomDelay,
                    rotation: randomRotation
                )
            )
        }
    }
}

// MARK: - Supporting Components
struct FeatureTag: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.modaicsChrome1)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.modaicsChrome1.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(Color.modaicsChrome1.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct MosaicBackgroundTile: View {
    let color: Color
    let size: CGFloat
    let rotation: Double
    
    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.15)
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .blur(radius: 1)
    }
}

struct MosaicLoadingIndicator: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.modaicsChrome1, .modaicsChrome2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 8, height: 8)
                    .rotationEffect(.degrees(rotation + Double(index) * 120))
                    .scaleEffect(1 + sin(rotation * .pi / 180 + Double(index)) * 0.2)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
