//
//  TransitionView.swift
//  Modaics – Auth module (dark green Porsche aesthetic)
//

import SwiftUI

struct TransitionView: View {
    let userType: ContentView.UserType?   // .user  / .brand
    let contentReady: Bool                // set to true from ContentView when dashboards loaded

    // ───────── animation state
    @State private var wardrobeScale   : CGFloat = 1.0
    @State private var wardrobeOpacity : Double  = 1.0
    @State private var leftDoorRot     : Double  = -45          // start closed
    @State private var rightDoorRot    : Double  =  45
    @State private var barScales       = Array(repeating: 0.8, count: 5)
    @State private var glowPulse       : CGFloat = 1.0
    @State private var dotActive       = [false, false, false]

    var body: some View {
        VStack(spacing: 50) {

            // ───────── wardrobe icon
            ZStack {
                // ambient pulse
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.luxeGold.opacity(0.35), .clear],
                            center: .center, startRadius: 0, endRadius: 110))
                    .blur(radius: 20)
                    .scaleEffect(glowPulse)
                    .opacity(wardrobeOpacity)

                // doors + middle shelf
                ZStack {
                    GoldDoor(isLeft: true)
                        .rotationEffect(.degrees(leftDoorRot), anchor: .leading)
                        .offset(x: -50)

                    middleShelf

                    GoldDoor(isLeft: false)
                        .rotationEffect(.degrees(rightDoorRot), anchor: .trailing)
                        .offset(x:  50)
                }
                .scaleEffect(wardrobeScale)
                .opacity(wardrobeOpacity)
            }

            // ───────── loading text + dots
            VStack(spacing: 24) {
                Text(userType == .user
                     ? "Assembling your wardrobe..."
                     : "Setting up your brand dashboard...")
                    .font(.forestTitle(20))
                    .foregroundStyle(.luxeGoldGradient)

                HStack(spacing: 12) {
                    ForEach(dotActive.indices, id: \.self) { i in
                        Circle()
                            .fill(.luxeGoldGradient)
                            .frame(width: 10, height: 10)
                            .scaleEffect(dotActive[i] ? 1.5 : 1)
                            .opacity(dotActive[i] ? 1 : 0.4)
                    }
                }
            }
            .opacity(wardrobeOpacity)
        }
        .onAppear   { runSequence() }
        .onChange(of: contentReady) { _, ready in
            if ready { withAnimation(.forestSpring) { wardrobeOpacity = 0 } }
        }
    }

    // ───────── middle shelf helper
    private var middleShelf: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(LinearGradient(colors: [.forestSoft, .forestLight],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: 45, height: 130)
            .overlay(
                VStack(spacing: 8) {
                    ForEach(barScales.indices, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                userType == .brand
                                ? .luxeGoldGradient
                                : LinearGradient(colors: [.sageWhite, .sageMuted],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: 32, height: userType == .brand ? 6 : 5)
                            .scaleEffect(barScales[i])
                    }
                })
    }

    // ───────── master time-line
    private func runSequence() {

        // doors swing + slight zoom
        withAnimation(.forestSpring) {
            leftDoorRot  = -70
            rightDoorRot =  70
            wardrobeScale = 1.25
        }

        // bars grow
        for i in barScales.indices {
            withAnimation(.forestSpring.delay(Double(i)*0.1)) {
                barScales[i] = 1.0
            }
        }

        // glow pulse (infinite)
        withAnimation(.easeInOut(duration: 1.6).repeatForever()) {
            glowPulse = 1.2
        }

        // dot loader
        for i in dotActive.indices {
            withAnimation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i)*0.2)) {
                dotActive[i] = true
            }
        }
    }
}

// ─────────────────────────────────────────────── MARK: GoldDoor
struct GoldDoor: View {
    let isLeft: Bool
    @State private var handleGlow: Bool = false
    
    var body: some View {
        ZStack {
            // Main door body with premium gold gradient
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: isLeft ?
                            [.luxeGold, .luxeGoldBright, .luxeGoldDeep] :
                            [.luxeGoldDeep, .luxeGoldBright, .luxeGold],
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
            
            // Texture overlay
            VStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 28, height: 2)
                        .blur(radius: 0.5)
                }
            }
            
            // Premium gold handle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, .luxeGold],
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

#Preview {
    TransitionView(userType: .user, contentReady: false)
}
