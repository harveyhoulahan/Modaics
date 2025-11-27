//
//  AnimationModifiers.swift
//  Modaics
//
//  Smooth animations for cards, buttons, and transitions
//

import SwiftUI

// MARK: - Card Appear Animation
struct CardAppearAnimation: ViewModifier {
    @State private var appeared = false
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1.0 : 0.8)
            .opacity(appeared ? 1.0 : 0)
            .onAppear {
                withAnimation(
                    .spring(response: 0.6, dampingFraction: 0.8)
                    .delay(delay)
                ) {
                    appeared = true
                }
            }
    }
}

// MARK: - Press Animation
struct PressAnimation: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .brightness(isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

// MARK: - Bounce Animation
struct BounceAnimation: ViewModifier {
    @State private var bounce = false
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(bounce ? 1.1 : 1.0)
            .onChange(of: trigger) { _, _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    bounce = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        bounce = false
                    }
                }
            }
    }
}

// MARK: - Slide In Animation
struct SlideInAnimation: ViewModifier {
    @State private var offset: CGFloat = 100
    @State private var opacity: Double = 0
    let delay: Double
    let edge: Edge
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: edge == .leading ? offset : (edge == .trailing ? -offset : 0),
                y: edge == .top ? offset : (edge == .bottom ? -offset : 0)
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .spring(response: 0.6, dampingFraction: 0.8)
                    .delay(delay)
                ) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

// MARK: - Fade In Animation
struct FadeInAnimation: ViewModifier {
    @State private var opacity: Double = 0
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

// MARK: - Wiggle Animation
struct WiggleAnimation: ViewModifier {
    @State private var rotation: Double = 0
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onChange(of: trigger) { _, _ in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
                    rotation = 5
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
                        rotation = -5
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        rotation = 0
                    }
                }
            }
    }
}

// MARK: - Pulse Animation
struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    let continuous: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                if continuous {
                    withAnimation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        isPulsing = true
                    }
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    func cardAppear(delay: Double = 0) -> some View {
        self.modifier(CardAppearAnimation(delay: delay))
    }
    
    func pressAnimation() -> some View {
        self.modifier(PressAnimation())
    }
    
    func bounce(trigger: Bool) -> some View {
        self.modifier(BounceAnimation(trigger: trigger))
    }
    
    func slideIn(from edge: Edge = .bottom, delay: Double = 0) -> some View {
        self.modifier(SlideInAnimation(delay: delay, edge: edge))
    }
    
    func fadeIn(delay: Double = 0) -> some View {
        self.modifier(FadeInAnimation(delay: delay))
    }
    
    func wiggle(trigger: Bool) -> some View {
        self.modifier(WiggleAnimation(trigger: trigger))
    }
    
    func pulse(continuous: Bool = false) -> some View {
        self.modifier(PulseAnimation(continuous: continuous))
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
        
        ScrollView {
            VStack(spacing: 30) {
                Text("Animation Showcase")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.modaicsCotton)
                    .fadeIn()
                
                // Card Appear
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.modaicsChrome1, .modaicsChrome2],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 100)
                            .overlay(
                                Text("Card \(index + 1)")
                                    .foregroundColor(.modaicsDarkBlue)
                                    .font(.headline)
                            )
                            .cardAppear(delay: Double(index) * 0.1)
                    }
                }
                .padding(.horizontal, 20)
                
                // Press Animation
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.modaicsDenim1)
                    .frame(height: 80)
                    .overlay(
                        Text("Press Me")
                            .foregroundColor(.white)
                            .font(.headline)
                    )
                    .pressAnimation()
                    .padding(.horizontal, 20)
                
                // Pulse Animation
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.modaicsChrome1, .modaicsChrome3],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 80, height: 80)
                    .pulse(continuous: true)
            }
            .padding(.vertical, 40)
        }
    }
}
