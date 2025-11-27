//
//  IndustrialComponents.swift
//  ModaicsAppTemp
//
//  Industrial Design System Components
//  Reusable UI components for minimal, industrial aesthetic
//

import SwiftUI

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let trailing: String?
    let trailingAction: (() -> Void)?
    
    init(title: String, trailing: String? = nil, trailingAction: (() -> Void)? = nil) {
        self.title = title
        self.trailing = trailing
        self.trailingAction = trailingAction
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .tracking(1.5)
                .foregroundColor(.appTextMain)
            
            Spacer()
            
            if let trailing = trailing {
                Button(action: { trailingAction?() }) {
                    Text(trailing.uppercased())
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(0.5)
                        .foregroundColor(.appRed)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let accentColor: Color
    
    init(icon: String, value: String, label: String, accentColor: Color = .appRed) {
        self.icon = icon
        self.value = value
        self.label = label
        self.accentColor = accentColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(accentColor)
            
            Text(value)
                .font(.system(size: 24, weight: .medium, design: .monospaced))
                .foregroundColor(.appTextMain)
            
            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(0.5)
                .foregroundColor(.appTextMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            Rectangle()
                .fill(Color.appSurface)
        )
        .overlay(
            Rectangle()
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}

// MARK: - Tag Pill
struct TagPill: View {
    let label: String
    let color: Color
    
    init(label: String, color: Color = .appRed) {
        self.label = label
        self.color = color
    }
    
    var body: some View {
        Text(label.uppercased())
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .tracking(0.5)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Rectangle()
                    .fill(color.opacity(0.3))
            )
            .overlay(
                Rectangle()
                    .stroke(color, lineWidth: 1)
            )
    }
}

// MARK: - Event Card
struct EventCard: View {
    let event: CommunityEvent
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                // Background image or gradient
                if let imageUrl = event.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.appSurfaceAlt)
                    }
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.appSurfaceAlt, Color.appSurface],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Dark gradient overlay at bottom
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, Color.black.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 100)
                }
                
                VStack(alignment: .leading) {
                    // Tag pill at top
                    TagPill(label: event.type.rawValue)
                        .padding(12)
                    
                    Spacer()
                    
                    // Event info at bottom
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        HStack(spacing: 8) {
                            Text(event.date)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.appTextMuted)
                            
                            Text("•")
                                .foregroundColor(.appTextMuted)
                            
                            Text("\(event.attendingCount) ATTENDING")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .tracking(0.5)
                                .foregroundColor(.appTextMuted)
                        }
                    }
                    .padding(12)
                }
            }
            .frame(width: 280, height: 340)
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(Color.appBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - App Card Wrapper
struct AppCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    
    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                Rectangle()
                    .fill(Color.appSurface)
            )
            .overlay(
                Rectangle()
                    .stroke(Color.appBorder, lineWidth: 1)
            )
    }
}

// MARK: - Image Card (for Picked For You)
struct ImageCard: View {
    let imageUrl: String?
    let title: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                // Background image
                if let imageUrl = imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.appSurfaceAlt)
                    }
                } else {
                    Rectangle()
                        .fill(Color.appSurfaceAlt)
                }
                
                // Optional title overlay
                if let title = title {
                    Text(title.uppercased())
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(0.5)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(
                            Rectangle()
                                .fill(Color.black.opacity(0.6))
                        )
                }
            }
            .frame(width: 200, height: 240)
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(Color.appBorder.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
