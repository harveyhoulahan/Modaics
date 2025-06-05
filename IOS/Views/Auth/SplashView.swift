//
//  SplashView.swift
//  Modaics – Auth module
//
//  Holds SplashView, LoginView and their small helper components.
//  Nothing in here refers to Home/Tab/Discover views – that keeps
//  those concerns nicely separated.
//

import SwiftUI
#if canImport(UIKit)
import UIKit          // For haptics
#endif

// ───────────────────────────────────────────────────────── MARK: SplashView
struct SplashView: View {
    let onAnimationComplete: () -> Void           // callback → ContentView
    @State private var leftDoorRotation  = 0.0
    @State private var rightDoorRotation = 0.0
    @State private var contentOpacity    = 0.0
    @State private var textOpacity       = 0.0
    @State private var textOffset: CGFloat = 30
    @State private var cottonOffsets     = Array(repeating: 0.0, count: 5)
    @State private var reflectionOpacity = 0.0
    @State private var logoScale: CGFloat = 0.8

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.modaicsDarkBlue, .modaicsMidBlue, .modaicsLightBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                logoBlock
                titleBlock
            }
        }
        .onAppear { animate() }
    }

    // MARK: – Sub-views
    private var logoBlock: some View {
        ZStack {
            // Ambient glow
            Circle()
                .fill(RadialGradient(
                    colors: [Color.modaicsChrome1.opacity(0.25), .clear],
                    center: .center, startRadius: 0, endRadius: 140))
                .blur(radius: 20)
                .opacity(contentOpacity)

            // Doors + middle shelf
            ZStack {
                ChromeDoor(isLeft: true)
                    .rotationEffect(.degrees(leftDoorRotation), anchor: .leading)
                    .offset(x: -50)
                MiddleShelf(contentOpacity: contentOpacity,
                            cottonOffsets: cottonOffsets)
                ChromeDoor(isLeft: false)
                    .rotationEffect(.degrees(rightDoorRotation), anchor: .trailing)
                    .offset(x: 50)
            }
            .scaleEffect(logoScale)

            // Reflection stroke
            RoundedRectangle(cornerRadius: 2)
                .fill(LinearGradient(
                    colors: [.white.opacity(0.8), .clear],
                    startPoint: .leading, endPoint: .trailing))
                .frame(width: 140, height: 4)
                .offset(y: -60)
                .opacity(reflectionOpacity)
        }
        .frame(height: 140)
    }

    private var titleBlock: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                gradientText("m") + gradientText("odaics")
            }
            .font(.system(size: 64, weight: .ultraLight, design: .serif))
            .modifier(Shimmer())

            Text("A digital wardrobe for sustainable fashion")
                .font(.footnote)
                .foregroundColor(Color.modaicsCotton)

            Text("Born from Australian cotton farms")
                .font(.caption)
                .foregroundColor(Color.modaicsChrome1)
                .opacity(textOpacity * 0.8)
        }
        .opacity(textOpacity)
        .offset(y: textOffset)
        .multilineTextAlignment(.center)
    }

    private func gradientText(_ string: String) -> Text {
        Text(string).foregroundStyle(
            LinearGradient(colors: [.modaicsChrome1, .modaicsChrome2],
                           startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    // MARK: – Animation sequence
    private func animate() {
        withAnimation(.modaicsElastic.delay(0.3)) { logoScale = 1 }
        withAnimation(.modaicsElastic.delay(0.5)) {
            leftDoorRotation  = -45
            rightDoorRotation =  45
        }
        withAnimation(.modaicsSpring.delay(0.8)) { contentOpacity = 1 }
        for i in cottonOffsets.indices {
            withAnimation(.modaicsSpring.delay(0.9 + Double(i) * 0.1)) {
                cottonOffsets[i] = Double.random(in: -3...3)
            }
        }
        withAnimation(.modaicsSmoothSpring.delay(1.0)) {
            textOpacity = 1; textOffset = 0
        }
        withAnimation(.easeInOut(duration: 1.5).delay(1.2)) {
            reflectionOpacity = 0.8
        }
        // Hand off control to ContentView
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            onAnimationComplete()
        }
    }
}

// ──────────────────────────────────────────────── MARK: LoginView & helpers
struct LoginView: View {
    let onUserSelect: (ContentView.UserType) -> Void
    @State private var cardsVisible = [false, false, false]
    @State private var buttonPressed = [false, false]

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
                HStack {
                    MiniLogo()
                    Text("modaics")
                        .font(.title)
                        .foregroundColor(.modaicsChrome1)
                    Spacer()
                }
                .padding(.horizontal).padding(.top, 60)

                // Hero copy
                VStack(spacing: 16) {
                    Text("Welcome to your\n**digital wardrobe**")
                        .font(.largeTitle.weight(.light))
                        .foregroundColor(.modaicsCotton)
                        .multilineTextAlignment(.center)

                    Text("Discover, swap and sell fashion items while reducing your environmental footprint.")
                        .font(.body)
                        .foregroundColor(.modaicsCottonLight)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Feature cards
                VStack(spacing: 20) {
                    FeatureCard(icon: "checkmark.seal.fill",
                                title: "Verified Sustainability",
                                text: "Track garment impact via FibreTrace",
                                isVisible: cardsVisible[0])
                    FeatureCard(icon: "person.2.fill",
                                title: "Community-Driven",
                                text: "Connect with local fashion lovers",
                                isVisible: cardsVisible[1])
                    FeatureCard(icon: "sparkles",
                                title: "AI-Powered Styling",
                                text: "Personalised recommendations",
                                isVisible: cardsVisible[2])
                }
                .onAppear { staggerCards() }

                // Actions
                VStack(spacing: 16) {
                    primaryButton(label: "Continue as User", sfSymbol: "person.fill", idx: 0) {
                        onUserSelect(.user)
                    }
                    primaryButton(label: "Continue as Brand", sfSymbol: "building.2.fill", idx: 1) {
                        onUserSelect(.brand)
                    }

                    Text("By continuing you agree to our Terms & Privacy Policy")
                        .font(.caption2).foregroundColor(.modaicsChrome1.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 50)
            }
        }
        .background(
            LinearGradient(colors: [.modaicsDarkBlue, .modaicsMidBlue],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea())
    }

    // helper funcs
    private func staggerCards() {
        for i in cardsVisible.indices {
            withAnimation(.modaicsSpring.delay(0.3 + Double(i)*0.2)) { cardsVisible[i] = true }
        }
    }

    @ViewBuilder
    private func primaryButton(label: String, sfSymbol: String, idx: Int,
                               action: @escaping () -> Void) -> some View {
        Button {
            buttonPressed[idx] = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                buttonPressed[idx] = false; action()
            }
        } label: {
            HStack {
                Image(systemName: sfSymbol)
                Text(label).fontWeight(.medium)
            }
            .foregroundColor(.modaicsDarkBlue)
            .frame(maxWidth: .infinity).padding(.vertical, 18)
            .background(
                LinearGradient(colors: [.modaicsChrome1, .modaicsChrome2],
                               startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .scaleEffect(buttonPressed[idx] ? 0.94 : 1.0)
        .animation(.modaicsSpring, value: buttonPressed[idx])
        .padding(.horizontal, 24)
    }
}

// ──────────────────────────────────────────────── MARK: Small components
private struct ChromeDoor: View {
    let isLeft: Bool
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(LinearGradient(
                colors: isLeft
                      ? [.modaicsChrome1, .modaicsChrome2, .modaicsChrome3]
                      : [.modaicsChrome3, .modaicsChrome2, .modaicsChrome1],
                startPoint: isLeft ? .topLeading : .topTrailing,
                endPoint: isLeft ? .bottomTrailing : .bottomLeading))
            .frame(width: 45, height: 130)
    }
}

private struct MiddleShelf: View {
    let contentOpacity: Double
    let cottonOffsets: [CGFloat]
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(LinearGradient(colors: [.modaicsDenim1, .modaicsDenim2],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: 45, height: 130)
            .overlay(
                VStack(spacing: 8) {
                    ForEach(cottonOffsets.indices, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: [.modaicsCotton, .modaicsCottonLight],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: 32, height: 5)
                            .offset(x: cottonOffsets[i])
                    }
                }
                .opacity(contentOpacity)
            )
    }
}

private struct FeatureCard: View {
    let icon, title, text: String
    let isVisible: Bool
    var body: some View {
        HStack(spacing: 18) {
            Circle()
                .fill(Color.modaicsDenim1.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(Image(systemName: icon)
                            .font(.title2).foregroundColor(.modaicsChrome1))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).foregroundColor(.modaicsCotton).font(.headline)
                Text(text).foregroundColor(.modaicsCottonLight).font(.subheadline)
            }
            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
        .padding(.horizontal, 24)
    }
}

private struct MiniLogo: View {
    var body: some View {
        ZStack {
            Rectangle().fill(Color.modaicsChrome1).frame(width: 4, height: 16)
                .rotationEffect(.degrees(-40), anchor: .topLeading)
                .offset(x: -4)
            Rectangle().fill(Color.modaicsDenim1).frame(width: 4, height: 16)
            Rectangle().fill(Color.modaicsChrome2).frame(width: 4, height: 16)
                .rotationEffect(.degrees(40), anchor: .topTrailing)
                .offset(x: 4)
        }
        .frame(width: 20, height: 20)
    }
}

// ────────────────────────────────────────────── MARK: Visual niceties
private struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1
    func body(content: Content) -> some View {
        content.overlay(
            LinearGradient(colors: [.white.opacity(0), .white.opacity(0.4), .white.opacity(0)],
                           startPoint: .leading, endPoint: .trailing)
                .rotationEffect(.degrees(25))
                .offset(x: phase * 200)
                .mask(content))
            .onAppear {
                withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: – Preview
#Preview {
    VStack {
        SplashView { }
        LoginView { _ in }
    }
    .preferredColorScheme(.dark)
}
