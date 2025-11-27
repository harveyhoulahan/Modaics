//
//  SketchbookHeaderView.swift
//  ModaicsAppTemp
//
//  Header component for Sketchbook screens
//

import SwiftUI

struct SketchbookHeaderView: View {
    let sketchbook: Sketchbook
    let membership: SketchbookMembership?
    let onSettingsTap: (() -> Void)?
    let onJoinTap: (() -> Void)?
    
    var isBrandView: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Brand Badge
            HStack(spacing: 16) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "pencil.and.scribble")
                            .font(.system(size: 34, weight: .medium, design: .monospaced))
                            .foregroundColor(.modaicsDarkBlue)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(sketchbook.title)
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCotton)
                    
                    if let description = sketchbook.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.modaicsCottonLight)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                if isBrandView, let onSettingsTap = onSettingsTap {
                    ModaicsIconButton(icon: "gearshape.fill", action: onSettingsTap)
                }
            }
            
            // Stats
            HStack(spacing: 24) {
                statItem(
                    value: "\(sketchbook.membersCount)",
                    label: "Members",
                    icon: "person.2.fill"
                )
                
                statItem(
                    value: "\(sketchbook.postsCount)",
                    label: "Posts",
                    icon: "square.stack.3d.up.fill"
                )
                
                Spacer()
                
                // Access badge
                accessBadge
            }
            
            // Membership status / CTA
            if !isBrandView {
                membershipSection
            }
        }
        .padding(20)
        .background(Color.modaicsSurface2)
        .clipShape(Rectangle())
        .overlay(
            Rectangle()
                .stroke(Color.modaicsChrome1.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Subviews
    
    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsChrome1)
                Text(value)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCotton)
            }
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsCottonLight)
        }
    }
    
    private var accessBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: sketchbook.isPublic ? "globe" : "lock.fill")
                .font(.caption)
            Text(sketchbook.accessPolicy.displayName)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(.modaicsCotton)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.modaicsDarkBlue.opacity(0.5))
        .clipShape(Rectangle())
        .overlay(
            Capsule()
                .stroke(Color.modaicsChrome1.opacity(0.15), lineWidth: 1)
        )
    }
    
    private var membershipSection: some View {
        VStack(spacing: 12) {
            if let membership = membership {
                // Already a member
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.green)
                    
                    Text("You're a member")
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCotton)
                    
                    Spacer()
                    
                    Text("Since \(membership.joinedAt.formatted(.dateTime.month(.abbreviated).year()))")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCottonLight)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.modaicsChrome1.opacity(0.15))
                .clipShape(Rectangle())
                .overlay(
                    Rectangle()
                        .stroke(Color.modaicsChrome1.opacity(0.15), lineWidth: 1)
                )
            } else if !sketchbook.isPublic {
                // Need to join
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.modaicsChrome1)
                        
                        Text(sketchbook.membershipRequirementText)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.modaicsCottonLight)
                    }
                    
                    if let onJoinTap = onJoinTap {
                        ModaicsPrimaryButton(
                            joinButtonText,
                            icon: "plus.circle.fill"
                        ) {
                            onJoinTap()
                        }
                    }
                }
            }
        }
    }
    
    private var joinButtonText: String {
        switch sketchbook.membershipRule {
        case .free:
            return "Join for Free"
        case .inviteOnly:
            return "Request Access"
        case .minSpend:
            return "Unlock Sketchbook"
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Brand view
        SketchbookHeaderView(
            sketchbook: .sample,
            membership: nil,
            onSettingsTap: {},
            onJoinTap: nil,
            isBrandView: true
        )
        
        // Consumer view (not member)
        SketchbookHeaderView(
            sketchbook: .memberOnly,
            membership: nil,
            onSettingsTap: nil,
            onJoinTap: {}
        )
        
        // Consumer view (member)
        SketchbookHeaderView(
            sketchbook: .sample,
            membership: SketchbookMembership(
                id: 1,
                sketchbookId: 1,
                userId: "user123",
                status: .active,
                joinSource: .free,
                joinedAt: Date().addingTimeInterval(-86400 * 30)
            ),
            onSettingsTap: nil,
            onJoinTap: nil
        )
    }
    .padding()
    .background(Color.modaicsDarkBlue)
}
