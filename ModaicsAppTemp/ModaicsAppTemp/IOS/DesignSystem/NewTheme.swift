//
//  NewTheme.swift
//  Modaics
//
//  Dark Green Porsche Aesthetic - Premium Sustainable Fashion Theme
//  Luxury, sustainable, premium dark mode design system
//

import SwiftUI

// MARK: - Dark Green Porsche Color Palette
public extension Color {
    
    // MARK: Primary Background Colors (Dark Green Hierarchy)
    /// Deepest forest green - main app background
    static let forestDeep = Color(red: 0.05, green: 0.12, blue: 0.08)
    
    /// Rich emerald green - secondary surfaces
    static let forestRich = Color(red: 0.08, green: 0.18, blue: 0.11)
    
    /// Mid forest green - cards and elevated surfaces
    static let forestMid = Color(red: 0.11, green: 0.22, blue: 0.14)
    
    /// Soft forest green - subtle backgrounds
    static let forestSoft = Color(red: 0.14, green: 0.26, blue: 0.17)
    
    /// Lighter forest for contrast areas
    static let forestLight = Color(red: 0.18, green: 0.32, blue: 0.22)
    
    // MARK: Accent Colors (Luxury Gold & Emerald)
    /// Premium gold - primary accent (like Porsche gold badging)
    static let luxeGold = Color(red: 0.85, green: 0.74, blue: 0.42)
    
    /// Brighter gold for highlights
    static let luxeGoldBright = Color(red: 0.92, green: 0.82, blue: 0.52)
    
    /// Deep gold for subtle accents
    static let luxeGoldDeep = Color(red: 0.72, green: 0.62, blue: 0.32)
    
    /// Emerald green accent - sustainability focus
    static let emerald = Color(red: 0.20, green: 0.72, blue: 0.45)
    
    /// Bright emerald for CTAs
    static let emeraldBright = Color(red: 0.28, green: 0.82, blue: 0.52)
    
    /// Deep emerald for shadows
    static let emeraldDeep = Color(red: 0.12, green: 0.55, blue: 0.32)
    
    // MARK: Text Colors
    /// Off-white primary text - reduced blue tint for warmth
    static let sageWhite = Color(red: 0.96, green: 0.95, blue: 0.93)
    
    /// Secondary text - slightly muted
    static let sageMuted = Color(red: 0.75, green: 0.78, blue: 0.72)
    
    /// Tertiary text - for less important info
    static let sageSubtle = Color(red: 0.55, green: 0.58, blue: 0.52)
    
    /// Gold tinted text for luxury accents
    static let goldText = Color(red: 0.82, green: 0.72, blue: 0.42)
    
    // MARK: Surface Colors
    /// Elevated card surface
    static let surfaceElevated = Color(red: 0.10, green: 0.20, blue: 0.13)
    
    /// Input field background
    static let surfaceInput = Color(red: 0.07, green: 0.15, blue: 0.10)
    
    /// Selected/highlighted surface
    static let surfaceSelected = Color(red: 0.16, green: 0.30, blue: 0.20)
    
    // MARK: Utility Colors
    /// Success green (organic)
    static let organicGreen = Color(red: 0.35, green: 0.68, blue: 0.35)
    
    /// Warning amber (earth tones)
    static let earthAmber = Color(red: 0.85, green: 0.65, blue: 0.25)
    
    /// Error coral (softened red)
    static let coralError = Color(red: 0.85, green: 0.45, blue: 0.40)
    
    /// Info teal (nature inspired)
    static let natureTeal = Color(red: 0.30, green: 0.65, blue: 0.60)
}

// MARK: - Gradients
public extension LinearGradient {
    
    // MARK: Background Gradients
    /// Main app background gradient - deep forest tones
    static let forestBackground = LinearGradient(
        colors: [.forestDeep, .forestRich],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Card surface gradient - subtle elevation
    static let forestSurface = LinearGradient(
        colors: [.forestMid, .forestSoft],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Premium gold gradient - luxury accents
    static let luxeGoldGradient = LinearGradient(
        colors: [.luxeGoldBright, .luxeGold, .luxeGoldDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Emerald gradient - sustainability focus
    static let emeraldGradient = LinearGradient(
        colors: [.emeraldBright, .emerald, .emeraldDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Subtle shimmer gradient for loading states
    static let forestShimmer = LinearGradient(
        colors: [
            .clear,
            .luxeGold.opacity(0.3),
            .luxeGoldBright.opacity(0.5),
            .luxeGold.opacity(0.3),
            .clear
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Button gradient - premium gold
    static let primaryButton = LinearGradient(
        colors: [.luxeGoldBright, .luxeGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Secondary button gradient - emerald
    static let secondaryButton = LinearGradient(
        colors: [.emerald, .emeraldDeep],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Shadows & Elevation
public struct ForestShadow {
    /// Subtle shadow for cards
    static let subtle = Color.black.opacity(0.2)
    
    /// Medium shadow for elevated elements
    static let medium = Color.black.opacity(0.35)
    
    /// Strong shadow for modals/sheets
    static let strong = Color.black.opacity(0.5)
    
    /// Gold glow for premium elements
    static let goldGlow = Color.luxeGold.opacity(0.3)
    
    /// Emerald glow for eco elements
    static let emeraldGlow = Color.emerald.opacity(0.4)
}

// MARK: - Typography
public extension Font {
    
    // MARK: Display Typography (Porsche-inspired, clean luxury)
    static func forestDisplay(_ size: CGFloat) -> Font {
        .system(size: size, weight: .thin, design: .default)
    }
    
    static func forestTitle(_ size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .default)
    }
    
    static func forestHeadline(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
    
    static func forestBody(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    
    static func forestCaption(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
}

// MARK: - Corner Radius
public struct ForestRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xlarge: CGFloat = 20
    static let round: CGFloat = 999
}

// MARK: - Spacing
public struct ForestSpacing {
    static let xs: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xlarge: CGFloat = 20
    static let xxlarge: CGFloat = 24
    static let section: CGFloat = 32
}

// MARK: - Animation
public extension Animation {
    /// Smooth, premium animation for interactions
    static let forestSpring = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)
    
    /// Quick feedback animation
    static let forestQuick = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    /// Elegant, slower animation for reveals
    static let forestElegant = Animation.spring(response: 0.7, dampingFraction: 0.9)
    
    /// Shimmer animation duration
    static let shimmerDuration: Double = 1.8
}

// MARK: - View Modifiers
public struct ForestCardModifier: ViewModifier {
    var isElevated: Bool
    var hasBorder: Bool
    var borderColor: Color
    
    public init(isElevated: Bool = true, hasBorder: Bool = true, borderColor: Color = .luxeGold.opacity(0.2)) {
        self.isElevated = isElevated
        self.hasBorder = hasBorder
        self.borderColor = borderColor
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: ForestRadius.large)
                    .fill(Color.forestMid.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: ForestRadius.large)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            .shadow(
                color: isElevated ? ForestShadow.subtle : .clear,
                radius: isElevated ? 12 : 0,
                x: 0,
                y: isElevated ? 6 : 0
            )
    }
}

public struct ForestGoldShimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    var duration: Double = 2.0
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient.forestShimmer
                        .rotationEffect(.degrees(30))
                        .offset(x: -geometry.size.width + (geometry.size.width * 2.5 * phase))
                        .mask(content)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

public extension View {
    func forestCard(isElevated: Bool = true, hasBorder: Bool = true, borderColor: Color = .luxeGold.opacity(0.2)) -> some View {
        modifier(ForestCardModifier(isElevated: isElevated, hasBorder: hasBorder, borderColor: borderColor))
    }
    
    func forestShimmer(duration: Double = 2.0) -> some View {
        modifier(ForestGoldShimmer(duration: duration))
    }
}

// MARK: - Theme Compatibility (Legacy Bridge)
// These bridge the old chrome-based colors to the new theme
public extension Color {
    // Legacy compatibility - redirects to new theme
    static var modaicsDarkBlue: Color { .forestDeep }
    static var modaicsMidBlue: Color { .forestRich }
    static var modaicsLightBlue: Color { .forestMid }
    static var modaicsSurface2: Color { .surfaceElevated }
    
    // Chrome colors -> Gold
    static var modaicsChrome1: Color { .luxeGold }
    static var modaicsChrome2: Color { .luxeGoldBright }
    static var modaicsChrome3: Color { .luxeGoldDeep }
    
    // Denim -> Forest tones
    static var modaicsDenim1: Color { .forestSoft }
    static var modaicsDenim2: Color { .forestLight }
    
    // Cotton -> Sage whites
    static var modaicsCotton: Color { .sageWhite }
    static var modaicsCottonLight: Color { .sageMuted }
    
    // Accent
    static var modaicsAccent: Color { .emerald }
}

// MARK: - Legacy Animation Compatibility
public extension Animation {
    static var modaicsSpring: Animation { .forestSpring }
    static var modaicsSmoothSpring: Animation { .forestElegant }
    static var modaicsElastic: Animation { .forestSpring }
}

// MARK: - Legacy Font Compatibility
public extension Font {
    static func modaicsDisplay(_ size: CGFloat) -> Font { .forestDisplay(size) }
    static func modaicsHeadline(_ size: CGFloat) -> Font { .forestHeadline(size) }
    static func modaicsBody(_ size: CGFloat) -> Font { .forestBody(size) }
    static func modaicsCaption(_ size: CGFloat) -> Font { .forestCaption(size) }
}

// MARK: - Theme Preview Helper
public struct ForestThemePreview: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            LinearGradient.forestBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Forest Porsche Theme")
                        .font(.forestDisplay(32))
                        .foregroundStyle(.luxeGoldGradient)
                    
                    // Color Palette Preview
                    VStack(spacing: 12) {
                        colorRow("Forest Deep", .forestDeep)
                        colorRow("Forest Rich", .forestRich)
                        colorRow("Forest Mid", .forestMid)
                        colorRow("Forest Soft", .forestSoft)
                        colorRow("Luxe Gold", .luxeGold)
                        colorRow("Emerald", .emerald)
                        colorRow("Sage White", .sageWhite)
                    }
                    
                    // Button Preview
                    VStack(spacing: 16) {
                        Button("Primary Gold Button") {}
                            .buttonStyle(ForestPrimaryButtonStyle())
                        
                        Button("Secondary Emerald Button") {}
                            .buttonStyle(ForestSecondaryButtonStyle())
                        
                        Button("Ghost Button") {}
                            .buttonStyle(ForestGhostButtonStyle())
                    }
                    
                    // Card Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Premium Card")
                            .font(.forestHeadline(18))
                            .foregroundColor(.sageWhite)
                        
                        Text("This is how cards look with the new forest theme.")
                            .font(.forestBody(14))
                            .foregroundColor(.sageMuted)
                    }
                    .padding(20)
                    .forestCard()
                }
                .padding(20)
            }
        }
    }
    
    private func colorRow(_ name: String, _ color: Color) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 60, height: 40)
            
            Text(name)
                .font(.forestBody(14))
                .foregroundColor(.sageWhite)
            
            Spacer()
        }
    }
}

// MARK: - Button Styles
public struct ForestPrimaryButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.forestCaption(16))
            .foregroundColor(.forestDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient.primaryButton
                    .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ForestRadius.medium))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.forestQuick, value: configuration.isPressed)
    }
}

public struct ForestSecondaryButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.forestCaption(16))
            .foregroundColor(.sageWhite)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient.secondaryButton
                    .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ForestRadius.medium))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.forestQuick, value: configuration.isPressed)
    }
}

public struct ForestGhostButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.forestCaption(16))
            .foregroundColor(.luxeGold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: ForestRadius.medium)
                    .stroke(.luxeGold.opacity(0.5), lineWidth: 1.5)
                    .background(.luxeGold.opacity(configuration.isPressed ? 0.15 : 0.05))
            )
            .clipShape(RoundedRectangle(cornerRadius: ForestRadius.medium))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.forestQuick, value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    ForestThemePreview()
}
