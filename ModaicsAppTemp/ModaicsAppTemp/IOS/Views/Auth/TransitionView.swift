//
//  TransitionView.swift
//  Modaics – Auth module (ultimate blended version)
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
                            colors: [Color.modaicsChrome1.opacity(0.35), .clear],
                            center: .center, startRadius: 0, endRadius: 110))
                    .blur(radius: 20)
                    .scaleEffect(glowPulse)
                    .opacity(wardrobeOpacity)

                // doors + middle shelf
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

            // ───────── loading text + dots
            VStack(spacing: 24) {
                Text(userType == .user
                     ? "Preparing your wardrobe..."
                     : "Setting up your brand dashboard...")
                    .font(.title3.weight(.light))
                    .foregroundStyle(
                        LinearGradient(colors: [.modaicsChrome1, .modaicsChrome2],
                                       startPoint: .leading, endPoint: .trailing))

                HStack(spacing: 12) {
                    ForEach(dotActive.indices, id: \.self) { i in
                        Circle()
                            .fill(
                                LinearGradient(colors: [.modaicsChrome1, .modaicsChrome2],
                                               startPoint: .topLeading, endPoint: .bottomTrailing))
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
            if ready { withAnimation(.modaicsSpring) { wardrobeOpacity = 0 } }
        }
    }

    // ───────── middle shelf helper
    private var middleShelf: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(LinearGradient(colors: [.modaicsDenim1, .modaicsDenim2],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: 45, height: 130)
            .overlay(
                VStack(spacing: 8) {
                    ForEach(barScales.indices, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                userType == .brand
                                ? LinearGradient(colors: [.modaicsChrome1, .modaicsChrome2],
                                                 startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [.modaicsCotton, .modaicsCottonLight],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: 32, height: userType == .brand ? 6 : 5)
                            .scaleEffect(barScales[i])
                    }
                })
    }

    // ───────── master time-line
    private func runSequence() {

        // doors swing + slight zoom
        withAnimation(.modaicsElastic) {
            leftDoorRot  = -70
            rightDoorRot =  70
            wardrobeScale = 1.25
        }

        // bars grow
        for i in barScales.indices {
            withAnimation(.modaicsSpring.delay(Double(i)*0.1)) {
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
