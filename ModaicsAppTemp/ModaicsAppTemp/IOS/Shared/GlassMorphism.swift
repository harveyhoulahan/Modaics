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
