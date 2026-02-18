//
//  LoginView.swift  (Auth module)
//  — enhanced, animated login screen with dark green Porsche aesthetic
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

                    introSection                  // "Welcome…" + paragraph

                    impactStats                   // Items Saved / Users / CO₂

                    premiumFeatures               // forest cards

                    actionButtons                 // User / Brand
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear { runAnimations() }
    }

    // ───────────────────────────── sub-views
    private var background: some View {
        LinearGradient.forestBackground
            .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            ModaicsMosaicLogo(size: CGFloat(80))
            Text("modaics")
                .font(.forestDisplay(32))
                .foregroundStyle(.luxeGoldGradient)
            Spacer()
        }
        .padding(.horizontal, 24).padding(.top, 60)
    }

    private var introSection: some View {
        VStack(spacing: 20) {
            Text("Welcome to your\ndigital wardrobe")
                .font(.forestDisplay(36))
                .foregroundColor(.sageWhite)
                .multilineTextAlignment(.center)
                .lineSpacing(8)

            Text("Modaics helps you discover, swap and sell fashion items while reducing your environmental footprint.")
                .font(.forestCaption(16))
                .foregroundColor(.sageWhite.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .lineSpacing(4)
        }
        .opacity(introOpacity)
        .offset(y: introOffset)
    }

    private var impactStats: some View {
        HStack(spacing: 30) {
            ImpactStat(value: "2.5M", label: "Items Saved", icon: "arrow.3.trianglepath", color: .emerald)
            ImpactStat(value: "500K", label: "Active Users", icon: "person.2.fill", color: .luxeGold)
            ImpactStat(value: "1.2M", label: "kg CO₂ Saved", icon: "leaf.fill", color: .organicGreen)
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
                .foregroundColor(.luxeGold.opacity(0.6))
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
            .foregroundColor(.forestDeep)
            .frame(maxWidth: .infinity).padding(.vertical, 20)
            .background(.luxeGoldGradient)
            .clipShape(RoundedRectangle(cornerRadius: ForestRadius.large))
            .shadow(color: .luxeGold.opacity(0.3), radius: 10, y: 5)
        }
        .scaleEffect(btnScale[idx])
        .animation(.forestSpring, value: btnScale[idx])
    }

    private func runAnimations() {
        // intro text
        withAnimation(.forestSpring.delay(0.2)) {
            introOpacity = 1; introOffset = 0
        }
        // stats
        withAnimation(.forestSpring.delay(0.4)) { statVisible = true }
        // cards
        for i in featureShown.indices {
            withAnimation(.forestSpring.delay(0.6 + Double(i)*0.2)) {
                featureShown[i] = true
            }
        }
    }
}

// ─────────────────────────────────────────────── MARK: ImpactStat
fileprivate struct ImpactStat: View {
    let value: String; let label: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.forestHeadline(22))
                .foregroundColor(.sageWhite)
            Text(label)
                .font(.caption)
                .foregroundColor(.sageMuted)
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
                .fill(.forestSoft.opacity(0.5))
                .frame(width: 50, height: 50)
                .overlay(Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(.luxeGoldGradient))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).foregroundColor(.sageWhite).font(.headline)
                Text(description).foregroundColor(.sageMuted).font(.subheadline)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: ForestRadius.large)
                .fill(.forestMid.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: ForestRadius.large)
                        .stroke(.luxeGold.opacity(0.2), lineWidth: 1)
                )
        )
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -25)
    }
}

#Preview {
    LoginView(onUserSelect: { _ in })
}
