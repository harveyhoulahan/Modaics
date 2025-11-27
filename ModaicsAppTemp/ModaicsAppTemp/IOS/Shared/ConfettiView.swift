//
//  ConfettiView.swift
//  Modaics
//
//  Confetti animation for celebration moments
//

import SwiftUI

// MARK: - Confetti Manager
@MainActor
class ConfettiManager: ObservableObject {
    static let shared = ConfettiManager()
    
    @Published var isActive = false
    @Published var confettiType: ConfettiType = .regular
    
    private init() {}
    
    func celebrate(type: ConfettiType = .regular) {
        confettiType = type
        isActive = true
        
        Task { @MainActor in
            HapticManager.shared.success()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.isActive = false
        }
    }
}

enum ConfettiType {
    case regular
    case sale
    case firstListing
    case milestone
    
    var colors: [Color] {
        switch self {
        case .regular:
            return [.modaicsChrome1, .modaicsChrome2, .modaicsChrome3, .modaicsDenim1]
        case .sale:
            return [.green, .modaicsChrome1, .yellow, .orange]
        case .firstListing:
            return [.purple, .pink, .modaicsChrome1, .blue]
        case .milestone:
            return [.yellow, .orange, .red, .pink, .purple, .modaicsChrome1]
        }
    }
    
    var particleCount: Int {
        switch self {
        case .regular: return 50
        case .sale: return 75
        case .firstListing: return 100
        case .milestone: return 150
        }
    }
}

// MARK: - Confetti Particle
struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let startX: CGFloat
    let endX: CGFloat
    let duration: Double
    let delay: Double
    let rotation: Double
}

// MARK: - Confetti View
struct ConfettiView: View {
    let confettiType: ConfettiType
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiShape()
                        .fill(particle.color)
                        .frame(width: 10, height: 10)
                        .position(
                            x: isAnimating ? particle.endX : particle.startX,
                            y: isAnimating ? geometry.size.height + 50 : -50
                        )
                        .rotationEffect(.degrees(isAnimating ? particle.rotation : 0))
                        .opacity(isAnimating ? 0 : 1)
                        .animation(
                            .easeOut(duration: particle.duration)
                            .delay(particle.delay),
                            value: isAnimating
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            generateParticles()
            isAnimating = true
        }
    }
    
    private func generateParticles() {
        particles = (0..<confettiType.particleCount).map { _ in
            let startX = CGFloat.random(in: 0...UIScreen.main.bounds.width)
            let endX = startX + CGFloat.random(in: -150...150)
            
            return ConfettiParticle(
                color: confettiType.colors.randomElement() ?? .modaicsChrome1,
                startX: startX,
                endX: endX,
                duration: Double.random(in: 2.0...3.5),
                delay: Double.random(in: 0...0.5),
                rotation: Double.random(in: 0...720)
            )
        }
    }
}

// MARK: - Confetti Shape
struct ConfettiShape: Shape {
    func path(in rect: CGRect) -> Path {
        let shapes = [rectangle, circle, triangle]
        return shapes.randomElement()?(rect) ?? rectangle(rect)
    }
    
    private func rectangle(_ rect: CGRect) -> Path {
        Path(rect)
    }
    
    private func circle(_ rect: CGRect) -> Path {
        Path { path in
            path.addEllipse(in: rect)
        }
    }
    
    private func triangle(_ rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

// MARK: - Confetti Modifier
struct ConfettiModifier: ViewModifier {
    @ObservedObject var confettiManager = ConfettiManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if confettiManager.isActive {
                ConfettiView(confettiType: confettiManager.confettiType)
                    .transition(.opacity)
                    .zIndex(1000)
            }
        }
    }
}

extension View {
    func withConfetti() -> some View {
        self.modifier(ConfettiModifier())
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        LinearGradient(
            colors: [.modaicsDarkBlue, .modaicsMidBlue],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        VStack(spacing: 30) {
            Text("Confetti Celebrations")
                .font(.system(size: 32, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsCotton)
            
            Button("🎉 Regular Celebration") {
                ConfettiManager.shared.celebrate(type: .regular)
            }
            .font(.system(size: 16, weight: .medium, design: .monospaced))
            .foregroundColor(.modaicsDarkBlue)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [.modaicsChrome1, .modaicsChrome2],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Rectangle())
            
            Button("💰 Made a Sale!") {
                ConfettiManager.shared.celebrate(type: .sale)
            }
            .font(.system(size: 16, weight: .medium, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.green)
            .clipShape(Rectangle())
            
            Button("✨ First Listing") {
                ConfettiManager.shared.celebrate(type: .firstListing)
            }
            .font(.system(size: 16, weight: .medium, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.purple)
            .clipShape(Rectangle())
            
            Button("🏆 Milestone Reached") {
                ConfettiManager.shared.celebrate(type: .milestone)
            }
            .font(.system(size: 16, weight: .medium, design: .monospaced))
            .foregroundColor(.modaicsDarkBlue)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.yellow)
            .clipShape(Rectangle())
        }
    }
    .withConfetti()
}
