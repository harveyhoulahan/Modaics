//
//  TransitionView.swift
//  Modaics – Auth module
//

import SwiftUI

struct TransitionView: View {
    let userType: ContentView.UserType?
    let contentReady: Bool

    @State private var wardrobeScale  = 1.0
    @State private var wardrobeOpacity = 1.0
    @State private var leftDoorRot  = -45.0
    @State private var rightDoorRot =  45.0
    @State private var shelfScales  = Array(repeating: 0.8, count: 5)
    @State private var dotPulse     = [false, false, false]
    @State private var glowPulse    = 1.0

    var body: some View {
        VStack(spacing: 50) {
            // Wardrobe
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.modaicsChrome1.opacity(0.35), .clear],
                        center: .center, startRadius: 0, endRadius: 120))
                    .blur(radius: 20)
                    .scaleEffect(glowPulse)
                    .opacity(wardrobeOpacity)

                ZStack {
                    ChromeDoor(isLeft: true)
                        .rotationEffect(.degrees(leftDoorRot), anchor: .leading)
                        .offset(x: -50)
                    middleShelf
                    ChromeDoor(isLeft: false)
                        .rotationEffect(.degrees(rightDoorRot), anchor: .trailing)
                        .offset(x:  50)
                }
                .scaleEffect(wardrobeScale)
                .opacity(wardrobeOpacity)
            }

            // Loading text & dots
            VStack(spacing: 24) {
                Text(userType == .user
                     ? "Preparing your wardrobe..."
                     : "Setting up your brand dashboard...")
                    .font(.title3.weight(.light))
                    .foregroundStyle(LinearGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2],
                        startPoint: .leading, endPoint: .trailing))

                HStack(spacing: 12) {
                    ForEach(dotPulse.indices, id: \.self) { i in
                        Circle()
                            .fill(LinearGradient(
                                colors: [.modaicsChrome1, .modaicsChrome2],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 10, height: 10)
                            .scaleEffect(dotPulse[i] ? 1.4 : 1.0)
                            .opacity(dotPulse[i] ? 1 : 0.4)
                    }
                }
            }
            .opacity(wardrobeOpacity)
        }
        .onAppear   { animate() }
        .onChange(of: contentReady) { _, ready in
            if ready { withAnimation(.modaicsSpring) { wardrobeOpacity = 0 } }
        }
    }

    // Middle shelf with cotton bars
    private var middleShelf: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(LinearGradient(
                colors: [.modaicsDenim1, .modaicsDenim2],
                startPoint: .top, endPoint: .bottom))
            .frame(width: 45, height: 130)
            .overlay(
                VStack(spacing: 8) {
                    ForEach(shelfScales.indices, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(userType == .brand
                                  ? LinearGradient(colors: [.modaicsChrome1, .modaicsChrome2],
                                                   startPoint: .leading, endPoint: .trailing)
                                  : LinearGradient(colors: [.modaicsCotton, .modaicsCottonLight],
                                                   startPoint: .leading, endPoint: .trailing))
                            .frame(width: 32, height: userType == .brand ? 6 : 5)
                            .scaleEffect(shelfScales[i])
                    }
                })
    }

    private func animate() {
        // Doors pop open
        withAnimation(.modaicsElastic) {
            leftDoorRot = -70; rightDoorRot = 70; wardrobeScale = 1.3
        }
        // Shelf items
        for i in shelfScales.indices {
            withAnimation(.modaicsSpring.delay(Double(i)*0.1)) {
                shelfScales[i] = 1.0
            }
        }
        // Glow pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
            glowPulse = 1.2
        }
        // Dots
        for i in dotPulse.indices {
            withAnimation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i)*0.2)) {
                dotPulse[i] = true
            }
        }
    }
}
