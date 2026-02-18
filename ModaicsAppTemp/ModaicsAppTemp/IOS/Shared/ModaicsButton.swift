//
//  ModaicsButton.swift
//  Modaics
//
//  Reusable button component with dark green Porsche aesthetic
//

import SwiftUI

// MARK: - Primary Button
struct ModaicsPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false
    
    init(_ title: String, icon: String? = nil, isEnabled: Bool = true, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.forestDeep)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(.forestHeadline(18))
                }
            }
            .foregroundColor(.forestDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.luxeGoldGradient)
            .clipShape(RoundedRectangle(cornerRadius: ForestRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: ForestRadius.large)
                    .stroke(.luxeGold.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

// MARK: - Secondary Button
struct ModaicsSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isEnabled: Bool = true
    
    init(_ title: String, icon: String? = nil, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                Text(title)
                    .font(.forestCaption(16))
            }
            .foregroundColor(.sageWhite)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.forestMid.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: ForestRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: ForestRadius.medium)
                    .stroke(.luxeGold.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

// MARK: - Icon Button
struct ModaicsIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 44
    var foregroundColor: Color = .luxeGold
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: ForestRadius.medium)
                    .fill(.forestMid.opacity(0.6))
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: ForestRadius.medium)
                            .stroke(foregroundColor.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(foregroundColor)
            }
        }
    }
}

// MARK: - Chip/Tag Button
struct ModaicsChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, isSelected: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.forestCaption(14))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? .luxeGoldGradient
                    : LinearGradient(
                        colors: [.forestMid.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .foregroundColor(isSelected ? .forestDeep : .sageWhite)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.luxeGold.opacity(0.5) : Color.luxeGold.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Glass Button
struct GlassButton: View {
    let title: String
    let icon: String
    let style: ButtonStyle
    let size: ButtonSize
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case ghost
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
    }
    
    init(_ title: String, icon: String, style: ButtonStyle = .primary, size: ButtonSize = .medium, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.forestCaption(size == .small ? 12 : 14))
            .foregroundColor(style == .primary ? .forestDeep : .luxeGold)
            .padding(.horizontal, size == .small ? 12 : 16)
            .padding(.vertical, size == .small ? 8 : 12)
            .background(
                style == .primary
                    ? .luxeGoldGradient
                    : Color.clear
            )
            .background(
                style != .primary
                    ? .ultraThinMaterial
                    : Color.clear
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(.luxeGold.opacity(style == .ghost ? 0.5 : 0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ZStack {
        LinearGradient.forestBackground
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            ModaicsPrimaryButton("Primary Button", icon: "checkmark") {}
            
            ModaicsSecondaryButton("Secondary Button", icon: "arrow.right") {}
            
            ModaicsIconButton(icon: "gear") {}
            
            HStack(spacing: 12) {
                ModaicsChip("Chip Selected", isSelected: true) {}
                ModaicsChip("Chip Default", isSelected: false) {}
            }
            
            HStack(spacing: 12) {
                GlassButton("Small", icon: "star", style: .primary, size: .small) {}
                GlassButton("Medium", icon: "star", style: .secondary, size: .medium) {}
                GlassButton("Ghost", icon: "star", style: .ghost, size: .small) {}
            }
        }
        .padding()
    }
}
