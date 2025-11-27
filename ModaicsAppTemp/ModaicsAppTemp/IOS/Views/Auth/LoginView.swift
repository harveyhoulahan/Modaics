//
//  LoginView.swift  (Auth module)
//  — enhanced, animated login screen
//

import SwiftUI

// ───────────────────────────────────────────────────────── MARK: LoginView
struct LoginView: View {
    let onUserSelect: (ContentView.UserType) -> Void

    // animation states
    @State private var introOpacity  = 0.0
    @State private var introOffset:  CGFloat = 30
    @State private var statVisible   = false
    @State private var featureShown  = [false, false, false]
    @State private var btnScale      = [1.0, 1.0]

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: 40) {

                    header                         // mini-logo + word-mark

                    introSection                  // “Welcome…” + paragraph

                    impactStats                   // Items Saved / Users / CO₂

                    premiumFeatures               // chrome cards

                    actionButtons                 // User / Brand
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear { runAnimations() }
    }

    // ───────────────────────────── sub-views
    private var background: some View {
        LinearGradient(colors: [.modaicsDarkBlue, .modaicsMidBlue],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            ModaicsMosaicLogo(size: CGFloat(80))
            Text("modaics")
                .font(.system(size: 32, weight: .ultraLight, design: .serif))
                .foregroundStyle(
                    LinearGradient(colors: [.modaicsChrome1, .modaicsChrome2],
                                   startPoint: .leading, endPoint: .trailing))
            Spacer()
        }
        .padding(.horizontal, 24).padding(.top, 60)
    }

    private var introSection: some View {
        VStack(spacing: 20) {
            Text("Welcome to your\ndigital wardrobe")
                .font(.system(size: 36, weight: .ultraLight, design: .serif))
                .foregroundColor(.modaicsCotton)
                .multilineTextAlignment(.center)
                .lineSpacing(8)

            Text("Modaics helps you discover, swap and sell fashion items while reducing your environmental footprint.")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.modaicsCotton.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .lineSpacing(4)
        }
        .opacity(introOpacity)
        .offset(y: introOffset)
    }

    private var impactStats: some View {
        HStack(spacing: 30) {
            ImpactStat(value: "2.5M", label: "Items Saved", icon: "arrow.3.trianglepath")
            ImpactStat(value: "500K", label: "Active Users", icon: "person.2.fill")
            ImpactStat(value: "1.2M", label: "kg CO₂ Saved", icon: "leaf.fill")
        }
        .padding(.vertical, 10)
        .opacity(statVisible ? 1 : 0)
        .offset(y: statVisible ? 0 : 20)
    }

    private var premiumFeatures: some View {
        VStack(spacing: 20) {
            PremiumFeatureCard(
                icon: "checkmark.seal.fill",
                title: "Verified Sustainability",
                description: "Track your impact via FibreTrace",
                isVisible: featureShown[0]
            )
            PremiumFeatureCard(
                icon: "person.2.fill",
                title: "Community-Driven",
                description: "Connect with local fashion lovers",
                isVisible: featureShown[1]
            )
            PremiumFeatureCard(
                icon: "sparkles",
                title: "AI-Powered Styling",
                description: "Personalised recommendations",
                isVisible: featureShown[2]
            )
        }
        .padding(.horizontal, 24)
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            primaryButton(label: "Continue as User", sfSymbol: "person.fill", idx: 0) {
                onUserSelect(.user)
            }
            primaryButton(label: "Continue as Brand", sfSymbol: "building.2.fill", idx: 1) {
                onUserSelect(.brand)
            }

            Text("By continuing you agree to our Terms & Privacy Policy")
                .font(.caption2)
                .foregroundColor(.modaicsChrome1.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.horizontal, 24)
    }

    // helpers
    @ViewBuilder
    private func primaryButton(label: String, sfSymbol: String, idx: Int,
                               action: @escaping () -> Void) -> some View {
        Button {
            btnScale[idx] = 0.94
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                btnScale[idx] = 1.0
                action()
            }
        } label: {
            HStack {
                Image(systemName: sfSymbol)
                Text(label).fontWeight(.medium)
            }
            .foregroundColor(.modaicsDarkBlue)
            .frame(maxWidth: .infinity).padding(.vertical, 20)
            .background(
                LinearGradient(colors: [.modaicsChrome1, .modaicsChrome2],
                               startPoint: .leading, endPoint: .trailing))
            .clipShape(Rectangle())
            
        }
        .scaleEffect(btnScale[idx])
        .animation(.modaicsSpring, value: btnScale[idx])
    }

    private func runAnimations() {
        // intro text
        withAnimation(.modaicsSpring.delay(0.2)) {
            introOpacity = 1; introOffset = 0
        }
        // stats
        withAnimation(.modaicsSpring.delay(0.4)) { statVisible = true }
        // cards
        for i in featureShown.indices {
            withAnimation(.modaicsSpring.delay(0.6 + Double(i)*0.2)) {
                featureShown[i] = true
            }
        }
    }
}

// ─────────────────────────────────────────────── MARK: ImpactStat
fileprivate struct ImpactStat: View {
    let value: String; let label: String; let icon: String
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.modaicsChrome1)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.modaicsCotton)
            Text(label)
                .font(.caption)
                .foregroundColor(.modaicsCottonLight)
        }
        .frame(maxWidth: .infinity)
    }
}

// ─────────────────────────────────────────────── MARK: PremiumFeatureCard
fileprivate struct PremiumFeatureCard: View {
    let icon, title, description: String
    let isVisible: Bool
    var body: some View {
        HStack(spacing: 18) {
            Circle()
                .fill(Color.modaicsDenim1.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(colors: [.modaicsChrome1, .modaicsChrome2],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).foregroundColor(.modaicsCotton).font(.headline)
                Text(description).foregroundColor(.modaicsCottonLight).font(.subheadline)
            }
            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -25)
    }
}
