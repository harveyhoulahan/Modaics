//
//  HapticManager.swift
//  ModaicsAppTemp
//
//  Centralized haptic feedback system for tactile UI interactions
//  Created by Harvey Houlahan on 11/26/2025.
//

import UIKit
import SwiftUI

// MARK: - Haptic Manager
@MainActor
class HapticManager {
    static let shared = HapticManager()
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    
    private init() {
        // Prepare generators for faster response
        impactLight.prepare()
        impactMedium.prepare()
        selectionGenerator.prepare()
    }
    
    // MARK: - Impact Feedback
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        switch style {
        case .light:
            impactLight.impactOccurred()
            impactLight.prepare()
        case .medium:
            impactMedium.impactOccurred()
            impactMedium.prepare()
        case .heavy:
            impactHeavy.impactOccurred()
            impactHeavy.prepare()
        case .soft:
            if #available(iOS 17.0, *) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            } else {
                impactLight.impactOccurred()
            }
        case .rigid:
            if #available(iOS 17.0, *) {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            } else {
                impactHeavy.impactOccurred()
            }
        @unknown default:
            impactMedium.impactOccurred()
        }
    }
    
    // MARK: - Selection Feedback
    func selectionChanged() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
    
    // MARK: - Notification Feedback
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notification.notificationOccurred(type)
        notification.prepare()
    }
    
    // MARK: - Convenience Methods
    func buttonTap() {
        impact(.light)
    }
    
    func cardTap() {
        impact(.medium)
    }
    
    func success() {
        notification(.success)
    }
    
    func warning() {
        notification(.warning)
    }
    
    func error() {
        notification(.error)
    }
    
    func toggleOn() {
        impact(.medium)
    }
    
    func toggleOff() {
        impact(.light)
    }
    
    func swipe() {
        impact(.light)
    }
    
    func dismiss() {
        impact(.soft)
    }
}

// MARK: - View Extension for Haptic Feedback
extension View {
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, onTap: Bool = true) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                if onTap {
                    HapticManager.shared.impact(style)
                }
            }
        )
    }
}

// MARK: - Button Style with Haptics
struct HapticButtonStyle: ButtonStyle {
    var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium
    var scaleEffect: CGFloat = 0.95
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
            .animation(.modaicsSpring, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) {
                if configuration.isPressed {
                    HapticManager.shared.impact(hapticStyle)
                }
            }
    }
}

extension ButtonStyle where Self == HapticButtonStyle {
    static var haptic: HapticButtonStyle {
        HapticButtonStyle()
    }
    
    static func haptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, scale: CGFloat = 0.95) -> HapticButtonStyle {
        HapticButtonStyle(hapticStyle: style, scaleEffect: scale)
    }
}
