//
//  NewTheme.swift
//  Modaics Design System
//
//  Dark Green Porsche Aesthetic
//  A luxury sustainable fashion experience
//

import SwiftUI

// MARK: - Color Palette
// Porsche-inspired dark green aesthetic with sustainable luxury vibes

extension Color {
    
    // MARK: Primary Colors - Deep Forest Racing Green
    /// Porsche Racing Green - The signature dark green
    static let modaicsPrimary = Color(hex: "0A1F15")
    /// Deep forest - for primary actions and key UI
    static let modaicsForest = Color(hex: "0F2E1C")
    /// Racing green accent - brighter for interactive elements
    static let modaicsRacingGreen = Color(hex: "1A3D28")
    /// Emerald highlight - for selected states
    static let modaicsEmerald = Color(hex: "2D5A3D")
    
    // MARK: Secondary Colors - Moss & Olive Accents
    /// Rich moss green - organic, sustainable feel
    static let modaicsMoss = Color(hex: "4A5D23")
    /// Olive accent - earthy sophistication
    static let modaicsOlive = Color(hex: "6B7B3C")
    /// Sage highlight - softer green for secondary elements
    static let modaicsSage = Color(hex: "8B9A6D")
    /// Fern green - fresh sustainability indicator
    static let modaicsFern = Color(hex: "5A7A4A")
    
    // MARK: Background Colors - Near-Black with Green Undertones
    /// Primary background - deep void with subtle green
    static let modaicsBackground = Color(hex: "0D120F")
    /// Secondary background - slightly lighter
    static let modaicsBackgroundSecondary = Color(hex: "141B16")
    /// Tertiary background - for cards and surfaces
    static let modaicsBackgroundTertiary = Color(hex: "1C241F")
    /// Elevated background - for modals and sheets
    static let modaicsElevated = Color(hex: "232B26")
    
    // MARK: Surface Colors - Dark Charcoal with Green Tint
    /// Primary surface - charcoal with green undertone
    static let modaicsSurface = Color(hex: "1E2621")
    /// Surface highlight - for hover/active states
    static let modaicsSurfaceHighlight = Color(hex: "28332C")
    /// Surface pressed - deeper for pressed states
    static let modaicsSurfacePressed = Color(hex: "151C18")
    
    // MARK: Accent Colors - Chrome/Silver Metallic (Porsche Wheel Aesthetic)
    /// Chrome silver - primary metallic accent
    static let modaicsChrome = Color(hex: "C4C4C4")
    /// Brushed aluminum - softer metallic
    static let modaicsAluminum = Color(hex: "A8A8A8")
    /// Platinum - bright metallic highlights
    static let modaicsPlatinum = Color(hex: "E8E8E8")
    /// Gunmetal - dark metallic for contrast
    static let modaicsGunmetal = Color(hex: "6B7280")
    /// Silver shimmer - for subtle sparkle effects
    static let modaicsSilver = Color(hex: "D1D5DB")
    
    // MARK: Text Colors - Off-White/Cream for Readability
    /// Primary text - pure white for maximum contrast
    static let modaicsTextPrimary = Color(hex: "FAFAFA")
    /// Secondary text - off-white for body content
    static let modaicsTextSecondary = Color(hex: "E5E7EB")
    /// Tertiary text - muted for captions and hints
    static let modaicsTextTertiary = Color(hex: "9CA3AF")
    /// Disabled text - for non-interactive elements
    static let modaicsTextDisabled = Color(hex: "6B7280")
    /// Cream accent - warm white for luxury feel
    static let modaicsCream = Color(hex: "F5F5DC")
    
    // MARK: Semantic Colors - Success/Eco/Living Green
    /// Eco green - sustainability success indicator
    static let modaicsEco = Color(hex: "4ADE80")
    /// Living green - vibrant for eco-friendly badges
    static let modaicsLivingGreen = Color(hex: "22C55E")
    /// Leaf green - softer eco indicator
    static let modaicsLeaf = Color(hex: "86EFAC")
    /// Success dark - for dark mode success states
    static let modaicsSuccessDark = Color(hex: "166534")
    
    // MARK: Semantic Colors - Warnings & Errors
    /// Warning amber - for caution states
    static let modaicsWarning = Color(hex: "F59E0B")
    /// Error red - for destructive actions
    static let modaicsError = Color(hex: "EF4444")
    /// Info blue - for informational states
    static let modaicsInfo = Color(hex: "3B82F6")
    
    // MARK: Utility Colors
    /// Transparent overlay - for modals
    static let modaicsOverlay = Color.black.opacity(0.7)
    /// Subtle border - for dividers and borders
    static let modaicsBorder = Color.white.opacity(0.1)
    /// Green-tinted border - for themed dividers
    static let modaicsBorderGreen = Color(hex: "1A3D28").opacity(0.5)
    
    // MARK: Gradient Colors - Helper Components
    /// Gradient start - deep forest
    static let gradientStart = Color(hex: "0A1F15")
    /// Gradient mid - forest blend
    static let gradientMid = Color(hex: "1A3D28")
    /// Gradient end - moss transition
    static let gradientEnd = Color(hex: "2D5A3D")
    /// Metallic start - bright silver
    static let metallicStart = Color(hex: "F5F5F5")
    /// Metallic mid - chrome
    static let metallicMid = Color(hex: "C4C4C4")
    /// Metallic end - aluminum
    static let metallicEnd = Color(hex: "8A8A8A")
}

// MARK: - Hex Color Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography System
// SF Pro variants with luxury fashion hierarchy

enum ModaicsFont {
    // MARK: Font Families
    static let primary = "SF Pro Display"
    static let text = "SF Pro Text"
    static let rounded = "SF Pro Rounded"
    
    // MARK: Font Sizes - Hierarchy Scale
    enum Size {
        static let largeTitle: CGFloat = 34
        static let title1: CGFloat = 28
        static let title2: CGFloat = 22
        static let title3: CGFloat = 20
        static let headline: CGFloat = 17
        static let body: CGFloat = 16
        static let callout: CGFloat = 15
        static let subheadline: CGFloat = 14
        static let footnote: CGFloat = 13
        static let caption1: CGFloat = 12
        static let caption2: CGFloat = 11
    }
}

// MARK: Typography Extensions
extension Font {
    static var modaicsLargeTitle: Font {
        .system(size: ModaicsFont.Size.largeTitle, weight: .bold, design: .default)
    }
    static var modaicsTitle1: Font {
        .system(size: ModaicsFont.Size.title1, weight: .bold, design: .default)
    }
    static var modaicsTitle2: Font {
        .system(size: ModaicsFont.Size.title2, weight: .bold, design: .default)
    }
    static var modaicsTitle3: Font {
        .system(size: ModaicsFont.Size.title3, weight: .semibold, design: .default)
    }
    static var modaicsHeadline: Font {
        .system(size: ModaicsFont.Size.headline, weight: .semibold, design: .default)
    }
    static var modaicsBody: Font {
        .system(size: ModaicsFont.Size.body, weight: .regular, design: .default)
    }
    static var modaicsSubheadline: Font {
        .system(size: ModaicsFont.Size.subheadline, weight: .regular, design: .default)
    }
    static var modaicsCaption1: Font {
        .system(size: ModaicsFont.Size.caption1, weight: .regular, design: .default)
    }
    static var modaicsCaption1Medium: Font {
        .system(size: ModaicsFont.Size.caption1, weight: .medium, design: .default)
    }
    static var modaicsButton: Font {
        .system(size: ModaicsFont.Size.callout, weight: .semibold, design: .default)
    }
    static var modaicsPrice: Font {
        .system(size: ModaicsFont.Size.title3, weight: .bold, design: .default)
    }
    static var modaicsBadge: Font {
        .system(size: ModaicsFont.Size.caption2, weight: .bold, design: .default)
    }
}

// MARK: Text Style
enum ModaicsTextStyle {
    case largeTitle, title1, title2, title3, headline, body, bodySecondary, caption, button, price, ecoBadge
    
    var font: Font {
        switch self {
        case .largeTitle: return .modaicsLargeTitle
        case .title1: return .modaicsTitle1
        case .title2: return .modaicsTitle2
        case .title3: return .modaicsTitle3
        case .headline: return .modaicsHeadline
        case .body: return .modaicsBody
        case .bodySecondary: return .modaicsSubheadline
        case .caption: return .modaicsCaption1
        case .button: return .modaicsButton
        case .price: return .modaicsPrice
        case .ecoBadge: return .modaicsBadge
        }
    }
    
    var color: Color {
        switch self {
        case .largeTitle, .title1, .title2, .title3, .headline, .price:
            return .modaicsTextPrimary
        case .body:
            return .modaicsTextSecondary
        case .bodySecondary, .caption:
            return .modaicsTextTertiary
        case .button:
            return .modaicsCream
        case .ecoBadge:
            return .modaicsEco
        }
    }
}

extension Text {
    func modaicsStyle(_ style: ModaicsTextStyle) -> some View {
        self.font(style.font).foregroundColor(style.color)
    }
}

// MARK: - Gradients
enum ModaicsGradients {
    static let darkGreenGradient = LinearGradient(
        colors: [Color(hex: "0A1F15"), Color(hex: "0F2E1C"), Color(hex: "1A3D28"), Color(hex: "2D5A3D")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let darkGreenVertical = LinearGradient(
        colors: [Color(hex: "0A1F15"), Color(hex: "1A3D28")],
        startPoint: .top, endPoint: .bottom
    )
    static let mossGradient = LinearGradient(
        colors: [Color(hex: "3D4F1C"), Color(hex: "4A5D23"), Color(hex: "5A6F2B")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let metallicGradient = LinearGradient(
        colors: [Color(hex: "E8E8E8"), Color(hex: "C4C4C4"), Color(hex: "A8A8A8"), Color(hex: "8A8A8A")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let metallicHorizontal = LinearGradient(
        colors: [Color(hex: "8A8A8A"), Color(hex: "C4C4C4"), Color(hex: "E8E8E8"), Color(hex: "C4C4C4"), Color(hex: "8A8A8A")],
        startPoint: .leading, endPoint: .trailing
    )
    static let ecoGradient = LinearGradient(
        colors: [Color(hex: "4ADE80"), Color(hex: "22C55E")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let luxurySheen = LinearGradient(
        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05), Color.clear],
        startPoint: .top, endPoint: .center
    )
    static let centerGlow = RadialGradient(
        colors: [Color(hex: "2D5A3D").opacity(0.4), Color.clear],
        center: .center, startRadius: 0, endRadius: 200
    )
}

// MARK: - Effects
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

struct GlassmorphismStyle {
    let backgroundColor: Color
    let blurRadius: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat
}

enum ModaicsEffects {
    static let elevatedShadow = ShadowStyle(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 8)
    static let softShadow = ShadowStyle(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 4)
    static let standardBlur: CGFloat = 20
    static let heavyBlur: CGFloat = 40
    
    static let glassBackground = GlassmorphismStyle(
        backgroundColor: Color(hex: "1C241F").opacity(0.7),
        blurRadius: 20,
        borderColor: Color.white.opacity(0.1),
        borderWidth: 1
    )
    static let greenGlass = GlassmorphismStyle(
        backgroundColor: Color(hex: "1A3D28").opacity(0.6),
        blurRadius: 25,
        borderColor: Color(hex: "2D5A3D").opacity(0.3),
        borderWidth: 1
    )
}

// MARK: - Button Styles
struct ModaicsPrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    var isFullWidth: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.modaicsButton)
            .foregroundColor(.modaicsCream)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                ZStack {
                    ModaicsGradients.darkGreenGradient
                    VStack {
                        ModaicsGradients.metallicHorizontal.frame(height: 2)
                        Spacer()
                    }
                    ModaicsGradients.luxurySheen
                    Color.black.opacity(configuration.isPressed ? 0.2 : 0)
                }
            )
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.modaicsChrome.opacity(0.3), lineWidth: 1))
            .shadow(color: Color(hex: "0A1F15").opacity(0.5), radius: configuration.isPressed ? 4 : 8, x: 0, y: configuration.isPressed ? 2 : 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isLoading ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ModaicsSecondaryButtonStyle: ButtonStyle {
    var isFullWidth: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.modaicsButton)
            .foregroundColor(.modaicsTextPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                ZStack {
                    Color.modaicsSurface
                    Color(hex: "1A3D28").opacity(0.3).blur(radius: 8)
                    Color.black.opacity(configuration.isPressed ? 0.2 : 0)
                }
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LinearGradient(colors: [Color(hex: "1A3D28"), Color(hex: "2D5A3D").opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.2), radius: configuration.isPressed ? 2 : 4, x: 0, y: configuration.isPressed ? 1 : 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ModaicsTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.modaicsButton)
            .foregroundColor(.modaicsEco)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.modaicsEco.opacity(configuration.isPressed ? 0.1 : 0))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ModaicsIconButtonStyle: ButtonStyle {
    enum Size { case small, medium, large }
    enum Variant { case `default`, filled, outlined, glass }
    
    var size: Size = .medium
    var variant: Variant = .default
    
    private var dimension: CGFloat {
        switch size { case .small: 32; case .medium: 44; case .large: 56 }
    }
    private var iconSize: CGFloat {
        switch size { case .small: 16; case .medium: 20; case .large: 24 }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: iconSize, weight: .semibold))
            .foregroundColor(foregroundColor)
            .frame(width: dimension, height: dimension)
            .background(background(configuration: configuration))
            .overlay(borderOverlay)
            .cornerRadius(dimension / 2)
            .shadow(color: shadowColor.opacity(configuration.isPressed ? 0.2 : 0.4), radius: configuration.isPressed ? 4 : 8, x: 0, y: configuration.isPressed ? 2 : 4)
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .default, .outlined: return .modaicsTextPrimary
        case .filled: return .modaicsCream
        case .glass: return .modaicsChrome
        }
    }
    
    private var shadowColor: Color {
        switch variant { case .filled: return Color(hex: "0A1F15"); default: return .black }
    }
    
    private func background(configuration: Configuration) -> some View {
        Group {
            switch variant {
            case .default: Color.modaicsSurface.overlay(Color.black.opacity(configuration.isPressed ? 0.2 : 0))
            case .filled: ModaicsGradients.darkGreenGradient.overlay(Color.black.opacity(configuration.isPressed ? 0.2 : 0))
            case .outlined: Color.clear.overlay(Color.modaicsEco.opacity(configuration.isPressed ? 0.1 : 0))
            case .glass: Color.modaicsSurface.opacity(0.8).background(.ultraThinMaterial).overlay(Color.black.opacity(configuration.isPressed ? 0.1 : 0))
            }
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        switch variant {
        case .outlined: Circle().stroke(Color.modaicsBorderGreen, lineWidth: 1.5)
        case .glass: Circle().stroke(Color.white.opacity(0.1), lineWidth: 1)
        default: EmptyView()
        }
    }
}

// MARK: - Chip Style
enum ChipVariant {
    case `default`, moss, eco, outlined, glass
}

struct ModaicsChipStyle: ViewModifier {
    var variant: ChipVariant = .default
    var isSelected: Bool = false
    
    func body(content: Content) -> some View {
        content
            .font(.modaicsCaption1Medium)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundView)
            .overlay(borderOverlay)
            .cornerRadius(16)
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .default: return isSelected ? .modaicsCream : .modaicsTextSecondary
        case .moss: return .modaicsCream
        case .eco: return .modaicsEco
        case .outlined: return isSelected ? .modaicsEco : .modaicsTextTertiary
        case .glass: return .modaicsTextPrimary
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .default: isSelected ? AnyView(ModaicsGradients.darkGreenGradient) : AnyView(Color.modaicsSurface)
        case .moss: ModaicsGradients.mossGradient
        case .eco: Color.modaicsEco.opacity(0.15)
        case .outlined: Color.clear
        case .glass: Color.modaicsSurface.opacity(0.6).background(.ultraThinMaterial)
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        switch variant {
        case .outlined: Capsule().stroke(isSelected ? Color.modaicsEco : Color.modaicsBorderGreen, lineWidth: 1.5)
        case .glass: Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1)
        default: EmptyView()
        }
    }
}

// MARK: - Card Style
enum CardVariant {
    case `default`, elevated, glass, outlined, featured
}

struct ModaicsCardStyle: ViewModifier {
    var variant: CardVariant = .default
    var padding: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundView)
            .overlay(borderOverlay)
            .cornerRadius(16)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowYOffset)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .default: Color.modaicsSurface
        case .elevated: Color.modaicsElevated
        case .glass: Color.modaicsSurface.opacity(0.7).background(.ultraThinMaterial)
        case .outlined: Color.clear
        case .featured: ZStack { Color.modaicsSurface; ModaicsGradients.centerGlow }
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        switch variant {
        case .outlined: RoundedRectangle(cornerRadius: 16).stroke(Color.modaicsBorderGreen, lineWidth: 1.5)
        case .featured: RoundedRectangle(cornerRadius: 16).stroke(LinearGradient(colors: [Color.modaicsChrome.opacity(0.3), Color.modaicsBorderGreen], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
        default: EmptyView()
        }
    }
    
    private var shadowColor: Color {
        switch variant {
        case .elevated, .featured: return Color.black.opacity(0.4)
        case .glass: return Color.black.opacity(0.2)
        default: return Color.black.opacity(0.25)
        }
    }
    
    private var shadowRadius: CGFloat {
        switch variant {
        case .elevated, .featured: return 20
        case .glass: return 8
        default: return 12
        }
    }
    
    private var shadowYOffset: CGFloat {
        switch variant {
        case .elevated, .featured: return 8
        case .glass: return 4
        default: return 4
        }
    }
}

// MARK: - Text Field Style
struct ModaicsTextFieldStyle: TextFieldStyle {
    var icon: Image? = nil
    var isError: Bool = false
    @Binding var text: String
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        HStack(spacing: 12) {
            if let icon = icon {
                icon.foregroundColor(.modaicsTextTertiary).font(.system(size: 16))
            }
            configuration.font(.modaicsBody).foregroundColor(.modaicsTextPrimary).tint(.modaicsEco)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.modaicsTextTertiary).font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(ZStack { Color.modaicsSurface; Color.modaicsEco.opacity(0.05).blur(radius: 8) })
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isError ? Color.modaicsError : Color.modaicsBorderGreen, lineWidth: isError ? 2 : 1))
    }
}

// MARK: - View Extensions
extension View {
    func modaicsChip(variant: ChipVariant = .default, isSelected: Bool = false) -> some View {
        modifier(ModaicsChipStyle(variant: variant, isSelected: isSelected))
    }
    func modaicsCard(variant: CardVariant = .default, padding: CGFloat = 16) -> some View {
        modifier(ModaicsCardStyle(variant: variant, padding: padding))
    }
    func modaicsGlass(style: GlassmorphismStyle = ModaicsEffects.glassBackground) -> some View {
        self.background(style.backgroundColor).background(.ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(style.borderColor, lineWidth: style.borderWidth))
    }
}

// MARK: - Preview
#if DEBUG
struct ModaicsDesignSystemPreview: View {
    @State private var text = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Modaics Design System").modaicsStyle(.largeTitle)
                Text("Dark Green Porsche Aesthetic").modaicsStyle(.bodySecondary)
                
                Divider().background(Color.modaicsBorder)
                
                // Colors
                Text("Colors").modaicsStyle(.title2)
                HStack { 
                    Circle().fill(Color.modaicsPrimary).frame(width: 44)
                    Circle().fill(Color.modaicsForest).frame(width: 44)
                    Circle().fill(Color.modaicsRacingGreen).frame(width: 44)
                    Circle().fill(Color.modaicsMoss).frame(width: 44)
                    Circle().fill(Color.modaicsChrome).frame(width: 44)
                    Circle().fill(Color.modaicsEco).frame(width: 44)
                }
                
                // Typography
                Text("Typography").modaicsStyle(.title2)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Large Title").modaicsStyle(.largeTitle)
                    Text("Title 1").modaicsStyle(.title1)
                    Text("Headline").modaicsStyle(.headline)
                    Text("Body text").modaicsStyle(.body)
                    Text("Caption").modaicsStyle(.caption)
                }
                
                // Buttons
                Text("Buttons").modaicsStyle(.title2)
                VStack(spacing: 12) {
                    Button("Primary") {}.buttonStyle(ModaicsPrimaryButtonStyle())
                    Button("Secondary") {}.buttonStyle(ModaicsSecondaryButtonStyle())
                    Button("Text") {}.buttonStyle(ModaicsTextButtonStyle())
                    HStack(spacing: 16) {
                        Button("★") {}.buttonStyle(ModaicsIconButtonStyle(size: .medium, variant: .filled))
                        Button("♡") {}.buttonStyle(ModaicsIconButtonStyle(size: .medium, variant: .outlined))
                    }
                }
                
                // Chips
                Text("Chips").modaicsStyle(.title2)
                HStack(spacing: 8) {
                    Text("Default").modaicsChip()
                    Text("Moss").modaicsChip(variant: .moss)
                    Text("Eco").modaicsChip(variant: .eco)
                    Text("Glass").modaicsChip(variant: .glass)
                }
                
                // Cards
                Text("Cards").modaicsStyle(.title2)
                VStack(spacing: 16) {
                    Text("Default Card").modaicsCard().frame(height: 60)
                    Text("Elevated Card").modaicsCard(variant: .elevated).frame(height: 60)
                    Text("Featured Card").modaicsCard(variant: .featured).frame(height: 60)
                }
                
                // Gradients
                Text("Gradients").modaicsStyle(.title2)
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12).fill(ModaicsGradients.darkGreenGradient).frame(height: 50)
                    RoundedRectangle(cornerRadius: 12).fill(ModaicsGradients.mossGradient).frame(height: 50)
                    RoundedRectangle(cornerRadius: 12).fill(ModaicsGradients.metallicGradient).frame(height: 50)
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color.modaicsBackground)
    }
}

#Preview {
    ModaicsDesignSystemPreview()
}
#endif
