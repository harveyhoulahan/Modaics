//
//  SplashLoginViews.swift
//  Modaics
//
//  Splash screen and login flow views
//

import SwiftUI

// MARK: - Enhanced Splash Screen with Cotton Farm Theme
struct SplashView: View {
    let onAnimationComplete: () -> Void
    @State private var animationState: AnimationState = .initial
    @State private var leftDoorRotation: Double = 0
    @State private var rightDoorRotation: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 10
    @State private var cottonFieldOpacity: Double = 0
    @State private var wardrobeScale: CGFloat = 0.8
    
    enum AnimationState {
        case initial, animating, complete
    }
    
    var body: some View {
        ZStack {
            // Sophisticated gradient background with cotton field inspiration
            backgroundView
            
            VStack(spacing: 40) {
                Spacer()
                
                // Cotton field decorative element
                cottonFieldElement
                    .opacity(cottonFieldOpacity)
                
                // Main wardrobe logo animation
                wardrobeLogo
                    .scaleEffect(wardrobeScale)
                
                // Logo text and tagline
                logoText
                    .opacity(textOpacity)
                    .offset(y: textOffset)
                
                Spacer()
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.15),
                    Color(red: 0.1, green: 0.15, blue: 0.25),
                    Color(red: 0.15, green: 0.2, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Cotton-inspired overlay pattern
            GeometryReader { geometry in
                ForEach(0..<20) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: CGFloat.random(in: 30...80)
                            )
                        )
                        .frame(
                            width: CGFloat.random(in: 50...150),
                            height: CGFloat.random(in: 50...150)
                        )
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .opacity(cottonFieldOpacity * 0.3)
                        .animation(
                            .easeInOut(duration: 3)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: cottonFieldOpacity
                        )
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private var cottonFieldElement: some View {
        HStack(spacing: 20) {
            ForEach(0..<3) { index in
                VStack(spacing: 8) {
                    // Cotton boll
                    ZStack {
                        // Outer petals
                        ForEach(0..<4) { petal in
                            Ellipse()
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 20, height: 30)
                                .rotationEffect(.degrees(Double(petal) * 90))
                        }
                        
                        // Center
                        Circle()
                            .fill(Color(red: 0.9, green: 0.85, blue: 0.8))
                            .frame(width: 15, height: 15)
                    }
                    .rotationEffect(.degrees(Double(index) * 15))
                    
                    // Stem
                    Rectangle()
                        .fill(Color(red: 0.4, green: 0.5, blue: 0.3))
                        .frame(width: 2, height: 30)
                }
                .offset(y: CGFloat(index) * 5)
            }
        }
        .padding(.bottom, 20)
    }
    
    private var wardrobeLogo: some View {
        ZStack {
            // Metallic wardrobe with chrome finish
            Group {
                // Left door with premium metallic gradient
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color(red: 0.85, green: 0.87, blue: 0.9), location: 0),
                                    .init(color: Color(red: 0.6, green: 0.65, blue: 0.7), location: 0.5),
                                    .init(color: Color(red: 0.75, green: 0.78, blue: 0.82), location: 1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 140)
                    
                    // Chrome reflection
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.6), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .frame(width: 50, height: 140)
                        .mask(
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 25, height: 140)
                                .offset(x: -12.5)
                        )
                    
                    // Door details - cotton texture
                    VStack(spacing: 6) {
                        ForEach(0..<4) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 30, height: 3)
                        }
                    }
                    .opacity(contentOpacity)
                    
                    // Chrome handle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white, Color.gray.opacity(0.8)],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 5
                            )
                        )
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .offset(x: 15, y: 0)
                }
                .rotationEffect(.degrees(leftDoorRotation), anchor: .leading)
                .offset(x: -60, y: 0)
                
                // Middle section - denim blue inspired by cotton
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.25, green: 0.45, blue: 0.75),
                                    Color(red: 0.2, green: 0.35, blue: 0.65)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 50, height: 140)
                    
                    // Cotton items inside wardrobe
                    VStack(spacing: 8) {
                        ForEach(0..<6) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.8),
                                            Color.white.opacity(0.6)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 35, height: 5)
                                .offset(x: CGFloat.random(in: -3...3))
                                .rotationEffect(.degrees(Double.random(in: -2...2)))
                        }
                    }
                    .opacity(contentOpacity)
                }
                
                // Right door - matching chrome finish
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color(red: 0.75, green: 0.78, blue: 0.82), location: 0),
                                    .init(color: Color(red: 0.6, green: 0.65, blue: 0.7), location: 0.5),
                                    .init(color: Color(red: 0.85, green: 0.87, blue: 0.9), location: 1)
                                ],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )
                        .frame(width: 50, height: 140)
                    
                    // Chrome reflection
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.6), Color.clear],
                                startPoint: .topTrailing,
                                endPoint: .center
                            )
                        )
                        .frame(width: 50, height: 140)
                        .mask(
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 25, height: 140)
                                .offset(x: 12.5)
                        )
                    
                    // Door details
                    VStack(spacing: 6) {
                        ForEach(0..<4) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 30, height: 3)
                        }
                    }
                    .opacity(contentOpacity)
                    
                    // Chrome handle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white, Color.gray.opacity(0.8)],
                                center: .topTrailing,
                                startRadius: 0,
                                endRadius: 5
                            )
                        )
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .offset(x: -15, y: 0)
                }
                .rotationEffect(.degrees(rightDoorRotation), anchor: .trailing)
                .offset(x: 60, y: 0)
            }
            
            // Top chrome bar
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.9), Color.gray.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 120, height: 6)
                .offset(y: -70)
                .opacity(textOpacity)
        }
        .frame(height: 160)
    }
    
    private var logoText: some View {
        VStack(spacing: 12) {
            // Main logo text with premium typography
            HStack(spacing: 0) {
                Text("m")
                    .font(.system(size: 64, weight: .ultraLight, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.8, green: 0.82, blue: 0.85),
                                Color(red: 0.6, green: 0.65, blue: 0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("odaics")
                    .font(.system(size: 64, weight: .ultraLight, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.8, green: 0.82, blue: 0.85),
                                Color(red: 0.6, green: 0.65, blue: 0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Tagline
            Text("A digital wardrobe for sustainable fashion")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            // Cotton heritage subtitle with animation
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14))
                Text("Born from Australian cotton farms")
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14))
            }
            .foregroundColor(Color(red: 0.8, green: 0.85, blue: 0.8))
            .opacity(textOpacity * 0.8)
            .padding(.top, 8)
        }
    }
    
    private func startAnimation() {
        // Initial delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animationState = .animating
            
            // Wardrobe scale up
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.1)) {
                wardrobeScale = 1.0
            }
            
            // Cotton field fade in
            withAnimation(.easeInOut(duration: 1.5)) {
                cottonFieldOpacity = 1
            }
            
            // Door opening animation with spring
            withAnimation(.spring(response: 1.4, dampingFraction: 0.75, blendDuration: 0.1).delay(0.5)) {
                leftDoorRotation = -50
                rightDoorRotation = 50
            }
            
            // Content fade in
            withAnimation(.easeInOut(duration: 0.8).delay(0.8)) {
                contentOpacity = 1
            }
            
            // Text animation
            withAnimation(.spring(response: 1.0, dampingFraction: 0.85, blendDuration: 0.1).delay(1.0)) {
                textOpacity = 1
                textOffset = 0
            }
            
            // Complete animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                animationState = .complete
                onAnimationComplete()
            }
        }
    }
}

// MARK: - Enhanced Login View
struct LoginView: View {
    let onUserSelect: (ContentView.UserType) -> Void
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    @State private var featureOpacity: [Double] = [0, 0, 0]
    @State private var selectedUserType: ContentView.UserType?
    @State private var showTypeSelection = false
    
    var body: some View {
        ZStack {
            // Gradient background
            backgroundGradient
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header with logo
                    headerView
                        .padding(.top, 60)
                    
                    // Main content
                    mainContent
                        .opacity(contentOpacity)
                        .offset(y: contentOffset)
                    
                    // Features section
                    featuresSection
                    
                    Spacer(minLength: 50)
                    
                    // Action buttons
                    actionButtons
                        .padding(.bottom, 50)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.97, blue: 1.0),
                Color(red: 0.9, green: 0.95, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerView: some View {
        HStack {
            // Mini wardrobe logo
            ModaicsLogoAnimated()
                .frame(width: 40, height: 40)
            
            Text("modaics")
                .font(.system(size: 32, weight: .light, design: .serif))
                .foregroundColor(.blue)
            
            Spacer()
        }
    }
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Welcome to your\ndigital wardrobe")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.primary)
                .lineHeight(1.2)
            
            Text("Join the sustainable fashion revolution. Discover, swap, and sell fashion items while tracking your environmental impact.")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .lineHeight(1.5)
            
            // Impact statistics
            HStack(spacing: 30) {
                ImpactStat(value: "2.5M", label: "Items Saved", icon: "arrow.3.trianglepath")
                ImpactStat(value: "500K", label: "Active Users", icon: "person.2.fill")
                ImpactStat(value: "1.2M", label: "kg CO2 Saved", icon: "leaf.fill")
            }
            .padding(.vertical, 20)
        }
    }
    
    private var featuresSection: some View {
        VStack(spacing: 25) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                FeatureRowAnimated(
                    icon: feature.icon,
                    title: feature.title,
                    description: feature.description,
                    color: feature.color,
                    delay: Double(index) * 0.15
                )
                .opacity(featureOpacity[safe: index] ?? 0)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Primary CTA
            Button(action: { showTypeSelection = true }) {
                HStack {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .medium))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .opacity(contentOpacity)
            
            // Secondary options
            HStack(spacing: 20) {
                Button("Sign In") {
                    // Sign in action
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                
                Text("•")
                    .foregroundColor(.gray.opacity(0.5))
                
                Button("Learn More") {
                    // Learn more action
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
            }
            .opacity(contentOpacity * 0.8)
            
            // Terms
            Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .opacity(contentOpacity * 0.6)
        }
        .sheet(isPresented: $showTypeSelection) {
            UserTypeSelectionView(onSelect: onUserSelect)
        }
    }
    
    private let features = [
        (icon: "checkmark.seal.fill", title: "FibreTrace Verified", description: "Track the journey of your garments from cotton farm to closet", color: Color.green),
        (icon: "person.2.fill", title: "Local Community", description: "Connect with fashion enthusiasts in Melbourne and beyond", color: Color.blue),
        (icon: "brain", title: "AI Recommendations", description: "Get personalized style suggestions based on your preferences", color: Color.purple)
    ]
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            contentOpacity = 1
            contentOffset = 0
        }
        
        for index in 0..<features.count {
            withAnimation(.easeOut(duration: 0.6).delay(0.5 + Double(index) * 0.15)) {
                if index < featureOpacity.count {
                    featureOpacity[index] = 1
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct ModaicsLogoAnimated: View {
    @State private var doorOpen = false
    
    var body: some View {
        ZStack {
            // Left door
            Rectangle()
                .fill(Color.blue)
                .frame(width: 8, height: 20)
                .rotationEffect(.degrees(doorOpen ? -40 : 0), anchor: .topLeading)
                .offset(x: -10, y: 0)
            
            // Middle
            Rectangle()
                .fill(Color.blue.opacity(0.9))
                .frame(width: 8, height: 20)
            
            // Right door
            Rectangle()
                .fill(Color.blue.opacity(0.7))
                .frame(width: 8, height: 20)
                .rotationEffect(.degrees(doorOpen ? 40 : 0), anchor: .topTrailing)
                .offset(x: 10, y: 0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                doorOpen = true
            }
        }
    }
}

struct ImpactStat: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FeatureRowAnimated: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let delay: Double
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            .scaleEffect(isVisible ? 1 : 0.8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineHeight(1.3)
            }
            
            Spacer()
        }
        .offset(x: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
    }
}

struct UserTypeSelectionView: View {
    let onSelect: (ContentView.UserType) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedType: ContentView.UserType?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("How will you use Modaics?")
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding(.top, 40)
                
                // User option
                UserTypeCard(
                    type: .user,
                    title: "Personal User",
                    description: "Buy, sell, and swap fashion items. Track your sustainable fashion journey.",
                    icon: "person.fill",
                    features: ["Digital wardrobe", "Swap with locals", "Track sustainability"],
                    isSelected: selectedType == .user,
                    action: { selectedType = .user }
                )
                
                // Brand option
                UserTypeCard(
                    type: .brand,
                    title: "Fashion Brand",
                    description: "Showcase your sustainable collection. Connect with conscious consumers.",
                    icon: "building.2.fill",
                    features: ["Brand dashboard", "Analytics", "Customer insights"],
                    isSelected: selectedType == .brand,
                    action: { selectedType = .brand }
                )
                
                Spacer()
                
                // Continue button
                Button(action: {
                    if let type = selectedType {
                        dismiss()
                        onSelect(type)
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedType == nil)
                .opacity(selectedType == nil ? 0.5 : 1)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
        }
    }
}

struct UserTypeCard: View {
    let type: ContentView.UserType
    let title: String
    let description: String
    let icon: String
    let features: [String]
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            
            HStack(spacing: 12) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.caption)
                        Text(feature)
                            .font(.caption)
                    }
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal)
        .onTapGesture {
            action()
        }
    }
}

// MARK: - Array Safe Subscript Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}