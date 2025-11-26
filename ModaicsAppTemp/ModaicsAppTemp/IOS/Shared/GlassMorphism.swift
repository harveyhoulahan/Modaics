//
//  GlassMorphism.swift
//  ModaicsAppTemp
//
//  Modern glass morphism components with depth and blur effects
//  Created by Harvey Houlahan on 11/26/2025.
//

import SwiftUI

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    let content: () -> Content
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16
    var borderColor: Color = .white.opacity(0.2)
    var shadowRadius: CGFloat = 20
    var shadowOpacity: Double = 0.1
    
    init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16,
        borderColor: Color = .white.opacity(0.2),
        shadowRadius: CGFloat = 20,
        shadowOpacity: Double = 0.1,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.borderColor = borderColor
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(padding)
            .background(
                ZStack {
                    // Glass background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.1),
                                    .white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: 10)
    }
}

// MARK: - Glass Button
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    var style: GlassButtonStyle = .primary
    var size: GlassButtonSize = .medium
    var fullWidth: Bool = false
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        icon: String? = nil,
        style: GlassButtonStyle = .primary,
        size: GlassButtonSize = .medium,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.fullWidth = fullWidth
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: size.fontSize, weight: .semibold))
            }
            .foregroundStyle(style.foregroundColor)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(style.backgroundColor)
                    
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: style.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(0.6)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .strokeBorder(style.borderColor, lineWidth: 1)
            )
            .shadow(color: style.shadowColor, radius: 15, x: 0, y: 5)
        }
        .buttonStyle(HapticButtonStyle(scaleEffect: 0.97))
    }
}

enum GlassButtonStyle {
    case primary
    case secondary
    case tertiary
    case success
    case danger
    
    var backgroundColor: Color {
        switch self {
        case .primary: return .modaicsChrome1.opacity(0.3)
        case .secondary: return .modaicsDenim1.opacity(0.3)
        case .tertiary: return .gray.opacity(0.2)
        case .success: return .green.opacity(0.3)
        case .danger: return .red.opacity(0.3)
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .primary: return [.modaicsChrome1, .modaicsChrome2]
        case .secondary: return [.modaicsDenim1, .modaicsDenim2]
        case .tertiary: return [.gray.opacity(0.3), .gray.opacity(0.1)]
        case .success: return [.green.opacity(0.5), .green.opacity(0.2)]
        case .danger: return [.red.opacity(0.5), .red.opacity(0.2)]
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary: return .white
        case .secondary: return .white
        case .tertiary: return .modaicsCotton
        case .success: return .white
        case .danger: return .white
        }
    }
    
    var borderColor: Color {
        switch self {
        case .primary: return .white.opacity(0.3)
        case .secondary: return .white.opacity(0.2)
        case .tertiary: return .gray.opacity(0.3)
        case .success: return .green.opacity(0.3)
        case .danger: return .red.opacity(0.3)
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .primary: return .modaicsChrome1.opacity(0.3)
        case .secondary: return .modaicsDenim1.opacity(0.3)
        case .tertiary: return .black.opacity(0.1)
        case .success: return .green.opacity(0.3)
        case .danger: return .red.opacity(0.3)
        }
    }
}

enum GlassButtonSize {
    case small
    case medium
    case large
    
    var height: CGFloat {
        switch self {
        case .small: return 36
        case .medium: return 44
        case .large: return 52
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 20
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 12
        case .large: return 14
        }
    }
}

// MARK: - Glass Badge
struct GlassBadge: View {
    let text: String
    var color: Color = .modaicsChrome1
    var size: BadgeSize = .medium
    
    enum BadgeSize {
        case small, medium, large
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .medium: return EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
            case .large: return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: size.fontSize, weight: .semibold))
            .foregroundColor(.white)
            .padding(size.padding)
            .background(
                Capsule()
                    .fill(color.opacity(0.8))
                    .overlay(
                        Capsule()
                            .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Glass Divider
struct GlassDivider: View {
    var height: CGFloat = 1
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: height)
    }
}
