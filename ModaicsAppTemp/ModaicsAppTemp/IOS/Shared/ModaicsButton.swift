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
                            .font(.system(size: 15, weight: .medium))
                    }
                    Text(title.uppercased())
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .tracking(1.5)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.modaicsChrome1)
            .clipShape(Rectangle())
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
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .tracking(1.2)
            }
            .foregroundColor(.modaicsCottonLight)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.modaicsMidBlue)
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(Color.modaicsDenim1.opacity(0.3), lineWidth: 1)
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
    var foregroundColor: Color = .modaicsChrome1
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(Color.modaicsMidBlue)
                    .frame(width: size, height: size)
                    .overlay(
                        Rectangle()
                            .stroke(foregroundColor.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .regular))
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
            .background(isSelected ? Color.modaicsChrome1 : Color.modaicsMidBlue)
            .foregroundColor(isSelected ? .white : .modaicsCottonLight)
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(
                        isSelected ? Color.clear : Color.modaicsDenim1.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
    }
}
