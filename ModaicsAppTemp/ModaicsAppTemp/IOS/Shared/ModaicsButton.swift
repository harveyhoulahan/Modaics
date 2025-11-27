//
//  ModaicsButton.swift
//  Modaics
//
//  Reusable button component with consistent theming
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
                        .tint(.white)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                    }
                    Text(title.uppercased())
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .tracking(1.5)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Rectangle()
                    .fill(Color.appRed)
            )
            .overlay(
                Rectangle()
                    .stroke(Color.appRed.opacity(0.5), lineWidth: 1)
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
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                }
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .tracking(1.2)
            }
            .foregroundColor(.appTextMain)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(Color.appSurface)
            )
            .overlay(
                Rectangle()
                    .stroke(Color.appBorder, lineWidth: 1)
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
    var foregroundColor: Color = .appTextMain
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(Color.appSurface)
                    .frame(width: size, height: size)
                    .overlay(
                        Rectangle()
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .medium, design: .monospaced))
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
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                }
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(0.8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.appRed.opacity(0.2) : Color.appSurface)
            )
            .foregroundColor(isSelected ? .white : .appTextMuted)
            .overlay(
                Rectangle()
                    .stroke(
                        isSelected ? Color.appRed : Color.appBorder,
                        lineWidth: 1
                    )
            )
        }
    }
}
