//
//  ModaicsMosaicLogo.swift
//  ModaicsAppTemp
//
//  Created by Harvey Houlahan on 11/6/2025.
//
//  MosaicLogo.swift
//  Modaics - A beautiful mosaic-inspired logo that represents the interconnected fashion community
//

import SwiftUI

// MARK: - Enhanced Mosaic Logo
struct ModaicsMosaicLogo: View {
    let size: CGFloat
    @State private var animationPhase: Double = 0
    @State private var glowIntensity: Double = 0.5
    @State private var tileRotations: [Double] = Array(repeating: 0, count: 12)
    @State private var tileScales: [CGFloat] = Array(repeating: 1.0, count: 12)
    @State private var hasAnimated = false
    
    init(size: CGFloat = 120) {
        self.size = size
    }
    
    private let mosaicColors: [Color] = [
        Color(red: 0.2, green: 0.4, blue: 0.7),   // Deep blue
        Color(red: 0.3, green: 0.5, blue: 0.8),   // Medium blue
        Color(red: 0.4, green: 0.6, blue: 0.85),  // Light blue
        Color(red: 0.5, green: 0.65, blue: 0.9),  // Chrome blue
        Color(red: 0.6, green: 0.7, blue: 0.85),  // Silver blue
        Color(red: 0.7, green: 0.75, blue: 0.8),  // Chrome accent
    ]
    
    var body: some View {
        ZStack {
            // Ambient glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.modaicsChrome1.opacity(0.4 * glowIntensity),
                            Color.modaicsDenim1.opacity(0.2 * glowIntensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.8
                    )
                )
                .frame(width: size * 1.6, height: size * 1.6)
                .blur(radius: 20)
                .scaleEffect(1 + sin(animationPhase) * 0.1)
            
            // Main mosaic structure
            ZStack {
                // Center piece - represents the core community
                MosaicTile(
                    shape: .hexagon,
                    color: LinearGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    size: size * 0.25,
                    rotation: tileRotations[0],
                    scale: tileScales[0]
                )
                .overlay(
                    Image(systemName: "leaf.fill")
                        .font(.system(size: size * 0.08))
                        .foregroundColor(.white.opacity(0.9))
                        .scaleEffect(tileScales[0])
                )
                
                // Inner ring of mosaic tiles
                ForEach(0..<6, id: \.self) { index in
                    MosaicTile(
                        shape: .diamond,
                        color: LinearGradient(
                            colors: [
                                mosaicColors[index % mosaicColors.count],
                                mosaicColors[(index + 1) % mosaicColors.count]
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        size: size * 0.18,
                        rotation: tileRotations[index + 1],
                        scale: tileScales[index + 1]
                    )
                    .offset(
                        x: cos(Double(index) * .pi / 3 + animationPhase * 0.5) * size * 0.3,
                        y: sin(Double(index) * .pi / 3 + animationPhase * 0.5) * size * 0.3
                    )
                }
                
                // Outer ring of smaller tiles
                ForEach(0..<12, id: \.self) { index in
                    MosaicTile(
                        shape: index % 2 == 0 ? .triangle : .square,
                        color: LinearGradient(
                            colors: [
                                mosaicColors[(index + 2) % mosaicColors.count].opacity(0.8),
                                mosaicColors[(index + 3) % mosaicColors.count].opacity(0.9)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        size: size * 0.12,
                        rotation: tileRotations[(index + 6) % tileRotations.count],
                        scale: tileScales[(index + 6) % tileScales.count]
                    )
                    .offset(
                        x: cos(Double(index) * .pi / 6 - animationPhase * 0.3) * size * 0.5,
                        y: sin(Double(index) * .pi / 6 - animationPhase * 0.3) * size * 0.5
                    )
                }
                
                // Floating accent pieces
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.modaicsChrome1.opacity(0.3)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 5
                            )
                        )
                        .frame(width: size * 0.04, height: size * 0.04)
                        .offset(
                            x: cos(Double(index) * .pi / 2 + animationPhase * 2) * size * 0.35,
                            y: sin(Double(index) * .pi / 2 + animationPhase * 2) * size * 0.35
                        )
                        .blur(radius: 0.5)
                }
            }
            
            // Chrome reflections
            ForEach(0..<3, id: \.self) { index in
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(
                        width: size * CGFloat(0.3 - Double(index) * 0.08),
                        height: size * 0.05
                    )
                    .rotationEffect(.degrees(45 + Double(index) * 30))
                    .offset(
                        x: -size * 0.15 + CGFloat(index) * 10,
                        y: -size * 0.15 + CGFloat(index) * 5
                    )
                    .blur(radius: 1)
                    .opacity(0.3 + sin(animationPhase + Double(index)) * 0.2)
            }
        }
        .onAppear {
            // Only animate once to prevent jarring re-animations
            guard !hasAnimated else { return }
            hasAnimated = true
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Subtle main rotation animation
        withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
        
        // Gentle glow pulsing
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            glowIntensity = 0.8
        }
        
        // Very subtle tile animations
        for index in tileRotations.indices {
            withAnimation(
                .easeInOut(duration: Double.random(in: 3...5))
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.15)
            ) {
                tileRotations[index] = Double.random(in: -15...15)
                tileScales[index] = CGFloat.random(in: 0.95...1.05)
            }
        }
    }
}

// MARK: - Mosaic Tile Shape
enum MosaicShape {
    case hexagon, diamond, triangle, square
}

struct MosaicTile<S: ShapeStyle>: View {
    let shape: MosaicShape
    let color: S
    let size: CGFloat
    let rotation: Double
    let scale: CGFloat
    
    var body: some View {
        Group {
            switch shape {
            case .hexagon:
                HexagonShape()
                    .fill(color)
                    .frame(width: size, height: size)
            case .diamond:
                DiamondShape()
                    .fill(color)
                    .frame(width: size, height: size)
            case .triangle:
                TriangleShape()
                    .fill(color)
                    .frame(width: size, height: size)
            case .square:
                RoundedRectangle(cornerRadius: size * 0.1)
                    .fill(color)
                    .frame(width: size * 0.8, height: size * 0.8)
            }
        }
        .rotationEffect(.degrees(rotation))
        .scaleEffect(scale)
        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
        .overlay(
            // Glossy effect
            Group {
                switch shape {
                case .hexagon:
                    HexagonShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                case .diamond:
                    DiamondShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                case .triangle:
                    TriangleShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                case .square:
                    RoundedRectangle(cornerRadius: size * 0.1)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .frame(width: size * 0.8, height: size * 0.8)
        )
    }
}

// MARK: - Custom Shapes
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let minDimension = min(width, height)
        let radius = minDimension / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 6
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        
        return path
    }
}

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Mini Mosaic Logo (for navigation/headers)
struct MiniMosaicLogo: View {
    @State private var shimmer: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Simplified mosaic pattern
            ForEach(0..<7, id: \.self) { index in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.modaicsChrome1.opacity(0.8),
                                Color.modaicsChrome2.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 8, height: 8)
                    .offset(
                        x: cos(Double(index) * .pi / 3.5) * 12,
                        y: sin(Double(index) * .pi / 3.5) * 12
                    )
            }
            
            // Center piece
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2],
                        center: .center,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
        .frame(width: 32, height: 32)
    }
}
