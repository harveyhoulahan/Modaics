//
//  ProfileView.swift
//  ModaicsAppTemp
//
//  Digital Wardrobe, Eco Points, and Sustainability Dashboard
//  Created by Harvey Houlahan on 6/6/2025.
//

import SwiftUI

struct ProfileView: View {
    let userType: ContentView.UserType
    @EnvironmentObject var viewModel: FashionViewModel
    
    @State private var selectedTab: WardrobeTab = .active
    @State private var showSettings = false
    @State private var showMembershipUpgrade = false
    @State private var selectedItem: FashionItem?
    @State private var showSketchbook = false
    
    enum WardrobeTab: String, CaseIterable {
        case active = "Active"
        case sold = "Sold"
        case swapped = "Swapped"
        case rented = "Rented"
        
        var icon: String {
            switch self {
            case .active: return "tshirt.fill"
            case .sold: return "dollarsign.circle.fill"
            case .swapped: return "arrow.triangle.swap"
            case .rented: return "clock.arrow.circlepath"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.modaicsDarkBlue, .modaicsMidBlue],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with Profile Info
                        profileHeader
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        
                        // Sketchbook CTA (for brands only)
                        if userType == .brand {
                            sketchbookCTA
                                .padding(.horizontal, 20)
                        }
                        
                        // Eco Points & Membership
                        ecoPointsSection
                            .padding(.horizontal, 20)
                        
                        // Sustainability Impact Report
                        sustainabilityReport
                            .padding(.horizontal, 20)
                        
                        // Digital Wardrobe
                        digitalWardrobe
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100) // Extra padding for tab bar
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showMembershipUpgrade) {
            MembershipUpgradeView()
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailView(item: item)
                .environmentObject(viewModel)
        }
        .fullScreenCover(isPresented: $showSketchbook) {
            NavigationView {
                // Use username-based ID for brands
                let brandId = userType == .brand ? "brand-\(viewModel.currentUser?.username ?? "temp")" : "brand-temp"
                BrandSketchbookScreen(brandId: brandId)
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        HStack(spacing: 16) {
            // Profile Picture
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.modaicsChrome1, .modaicsChrome2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: userType == .brand ? "building.2.fill" : "person.fill")
                            .font(.system(size: 32, weight: .medium, design: .monospaced))
                            .foregroundColor(.modaicsDarkBlue)
                    )
                
                // Membership badge
                Circle()
                    .fill(viewModel.currentUser?.membershipTier == .premium ? Color.yellow : Color.gray)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: viewModel.currentUser?.membershipTier == .premium ? "star.fill" : "star")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.currentUser?.username ?? "User")
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCotton)
                
                Text(viewType == .brand ? "Brand Account" : membershipText)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsChrome1)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "tshirt.fill")
                            .font(.caption)
                        Text("\(wardrobeItems.count)")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                        Text("\(viewModel.likedIDs.count)")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                    }
                }
                .foregroundColor(.modaicsCottonLight)
            }
            
            Spacer()
            
            Button {
                HapticManager.shared.buttonTap()
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundColor(.modaicsChrome1)
            }
        }
    }
    
    // MARK: - Eco Points Section
    private var ecoPointsSection: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "leaf.circle.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, Color(red: 0.2, green: 0.8, blue: 0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Eco Points")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(.modaicsCotton)
                        
                        Text("Earned from sustainable actions")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.modaicsCottonLight)
                    }
                }
                
                Spacer()
                
                Text("\(viewModel.currentUser?.ecoPoints ?? 0)")
                    .font(.system(size: 32, weight: .medium, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, Color(red: 0.2, green: 0.8, blue: 0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            // Eco Points breakdown
            VStack(spacing: 10) {
                EcoPointRow(
                    icon: "arrow.triangle.swap",
                    action: "Items Swapped",
                    points: "+50 pts each",
                    color: .blue
                )
                
                EcoPointRow(
                    icon: "dollarsign.circle.fill",
                    action: "Second-hand Purchases",
                    points: "+25 pts each",
                    color: .green
                )
                
                EcoPointRow(
                    icon: "calendar.badge.checkmark",
                    action: "Event Attendance",
                    points: "+75 pts each",
                    color: .orange
                )
                
                EcoPointRow(
                    icon: "star.fill",
                    action: "Sustainability Badge Items",
                    points: "+100 pts",
                    color: .yellow
                )
            }
            
            // Redeem button
            if viewModel.currentUser?.membershipTier != .premium {
                Button {
                    HapticManager.shared.buttonTap()
                    showMembershipUpgrade = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Upgrade to Premium")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsDarkBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.modaicsChrome1, .modaicsChrome2],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Rectangle())
                }
            }
        }
        .padding(20)
        .background(
            Rectangle()
                .fill(Color.modaicsDarkBlue.opacity(0.6))
                .overlay(
                    Rectangle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.modaicsChrome1.opacity(0.15), Color.blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Sustainability Report
    private var sustainabilityReport: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Your Impact")
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCotton)
                
                Spacer()
                
                Text("This Month")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCottonLight)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.modaicsSurface2)
                    .clipShape(Rectangle())
            }
            
            // Impact metrics
            VStack(spacing: 14) {
                SustainabilityMetric(
                    icon: "drop.fill",
                    label: "Water Saved",
                    value: "\(calculateWaterSaved()) L",
                    change: "+12%",
                    color: .blue,
                    description: "vs last month"
                )
                
                SustainabilityMetric(
                    icon: "cloud.fill",
                    label: "CO₂ Offset",
                    value: "\(viewModel.calculateUserSustainabilityScore()) kg",
                    change: "+8%",
                    color: .green,
                    description: "vs last month"
                )
                
                SustainabilityMetric(
                    icon: "arrow.3.trianglepath",
                    label: "Items Circulated",
                    value: "\(circulatedItemsCount)",
                    change: "+5",
                    color: .orange,
                    description: "new this month"
                )
                
                SustainabilityMetric(
                    icon: "leaf.fill",
                    label: "Sustainability Score",
                    value: "\(viewModel.calculateUserSustainabilityScore())%",
                    change: "+3%",
                    color: .green,
                    description: "keep it up!"
                )
            }
        }
        .padding(20)
        .background(
            Rectangle()
                .fill(Color.modaicsDarkBlue.opacity(0.6))
                .overlay(
                    Rectangle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.modaicsChrome1.opacity(0.15), Color.blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Sketchbook CTA (Brand Only)
    private var sketchbookCTA: some View {
        Button {
            HapticManager.shared.buttonTap()
            showSketchbook = true
        } label: {
            HStack(spacing: 16) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.modaicsChrome1, .modaicsChrome2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "pencil.and.scribble")
                            .font(.system(size: 28, weight: .medium, design: .monospaced))
                            .foregroundColor(.modaicsDarkBlue)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("My Sketchbook")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCotton)
                    
                    Text("Share WIPs, drops, and behind-the-scenes with your community")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCottonLight)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsChrome1)
            }
            .padding(20)
            .background(
                Rectangle()
                    .fill(Color.modaicsDarkBlue.opacity(0.6))
                    .overlay(
                        Rectangle()
                            .stroke(
                                LinearGradient(
                                    colors: [.modaicsChrome1, .modaicsChrome2],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
        }
    }
    
    // MARK: - Digital Wardrobe
    private var digitalWardrobe: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Digital Wardrobe")
                    .font(.system(size: 22, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCotton)
                
                Spacer()
                
                Text("\(wardrobeItems.count) items")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCottonLight)
            }
            .padding(.horizontal, 20)
            
            // Wardrobe tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(WardrobeTab.allCases, id: \.self) { tab in
                        WardrobeTabButton(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            count: itemCount(for: tab)
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Wardrobe items grid
            if filteredWardrobeItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: selectedTab.icon)
                        .font(.system(size: 48, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCottonLight.opacity(0.5))
                    
                    Text("No \(selectedTab.rawValue) Items")
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCotton)
                    
                    Text("Items you \(selectedTab.rawValue.lowercased()) will appear here")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCottonLight)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 16
                ) {
                    ForEach(filteredWardrobeItems) { item in
                        WardrobeItemCard(item: item) {
                            selectedItem = item
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var viewType: ContentView.UserType {
        userType
    }
    
    private var membershipText: String {
        switch viewModel.currentUser?.membershipTier {
        case .premium:
            return "Premium Member"
        case .basic, .none:
            return "Free Member"
        }
    }
    
    private var wardrobeItems: [FashionItem] {
        viewModel.userWardrobe
    }
    
    private var filteredWardrobeItems: [FashionItem] {
        switch selectedTab {
        case .active:
            return wardrobeItems.filter { !$0.isSold }
        case .sold:
            return wardrobeItems.filter { $0.isSold }
        case .swapped:
            return wardrobeItems.filter { $0.isSwapped }
        case .rented:
            return wardrobeItems.filter { $0.isRented }
        }
    }
    
    private var circulatedItemsCount: Int {
        wardrobeItems.filter { $0.sustainabilityScore.isRecycled }.count
    }
    
    private func itemCount(for tab: WardrobeTab) -> Int {
        switch tab {
        case .active:
            return wardrobeItems.filter { !$0.isSold }.count
        case .sold:
            return wardrobeItems.filter { $0.isSold }.count
        case .swapped:
            return wardrobeItems.filter { $0.isSwapped }.count
        case .rented:
            return wardrobeItems.filter { $0.isRented }.count
        }
    }
    
    private func calculateWaterSaved() -> Int {
        // Average water saved per garment recycled: ~2700L
        return circulatedItemsCount * 2700
    }
}

// MARK: - Supporting Views

struct EcoPointRow: View {
    let icon: String
    let action: String
    let points: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(action)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsCottonLight)
            
            Spacer()
            
            Text(points)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.green)
        }
    }
}

struct SustainabilityMetric: View {
    let icon: String
    let label: String
    let value: String
    let change: String
    let color: Color
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCottonLight)
                
                HStack(spacing: 8) {
                    Text(value)
                        .font(.system(size: 22, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCotton)
                    
                    Text(change)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.modaicsChrome1.opacity(0.15))
                        .clipShape(Rectangle())
                }
                
                Text(description)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCottonLight.opacity(0.7))
            }
            
            Spacer()
        }
    }
}

struct WardrobeTabButton: View {
    let tab: ProfileView.WardrobeTab
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                
                Text(tab.rawValue)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                
                Text("\(count)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? .modaicsDarkBlue : .modaicsCottonLight)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        isSelected ? Color.modaicsChrome1 : Color.modaicsSurface2
                    )
                    .clipShape(Rectangle())
            }
            .foregroundColor(isSelected ? .modaicsCotton : .modaicsCottonLight)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.modaicsChrome1.opacity(0.2) : Color.modaicsSurface2)
                    .overlay(
                        Rectangle()
                            .stroke(
                                isSelected ? Color.modaicsChrome1.opacity(0.5) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WardrobeItemCard: View {
    let item: FashionItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Image
                Rectangle()
                    .fill(Color.modaicsSurface2)
                    .aspectRatio(3/4, contentMode: .fit)
                    .overlay(
                        Group {
                            if let imageURL = item.imageURLs.first {
                                PremiumCachedImage(url: imageURL, contentMode: .fill)
                            }
                        }
                    )
                    .clipShape(Rectangle())
                    .overlay(
                        // Status badge
                        VStack {
                            HStack {
                                Spacer()
                                
                                if item.isSold {
                                    statusBadge(text: "Sold", color: .green)
                                } else if item.isSwapped {
                                    statusBadge(text: "Swapped", color: .blue)
                                } else if item.isRented {
                                    statusBadge(text: "Rented", color: .orange)
                                }
                            }
                            Spacer()
                        }
                        .padding(8)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.brand)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.modaicsChrome1)
                    
                    Text(item.name)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCotton)
                        .lineLimit(2)
                    
                    if item.listingPrice > 0 {
                        Text("$\(Int(item.listingPrice))")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.modaicsChrome2)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Rectangle())
    }
}

// MARK: - Membership Upgrade View
struct MembershipUpgradeView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.modaicsDarkBlue, .modaicsMidBlue],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 64, weight: .medium, design: .monospaced))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Upgrade to Premium")
                                .font(.system(size: 32, weight: .medium, design: .monospaced))
                                .foregroundColor(.modaicsCotton)
                            
                            Text("Unlock unlimited potential")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(.modaicsCottonLight)
                        }
                        .padding(.top, 40)
                        
                        // Pricing
                        VStack(spacing: 8) {
                            Text("$10")
                                .font(.system(size: 56, weight: .medium, design: .monospaced))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.modaicsChrome1, .modaicsChrome2],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("per month")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(.modaicsCottonLight)
                        }
                        
                        // Features
                        VStack(alignment: .leading, spacing: 16) {
                            PremiumFeature(
                                icon: "infinity",
                                title: "Unlimited Listings",
                                description: "List as many items as you want"
                            )
                            
                            PremiumFeature(
                                icon: "eye.trianglebadge.exclamationmark.fill",
                                title: "AR Try-Ons",
                                description: "See how items look before buying"
                            )
                            
                            PremiumFeature(
                                icon: "chart.bar.fill",
                                title: "Advanced Analytics",
                                description: "Track your wardrobe trends"
                            )
                            
                            PremiumFeature(
                                icon: "sparkles",
                                title: "Priority AI Recommendations",
                                description: "Get the best matches first"
                            )
                            
                            PremiumFeature(
                                icon: "leaf.fill",
                                title: "2x Eco Points",
                                description: "Earn rewards faster"
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // CTA Button
                        Button {
                            // Handle upgrade
                            HapticManager.shared.success()
                        } label: {
                            Text("Start Free Trial")
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                .foregroundColor(.modaicsDarkBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.modaicsChrome1, .modaicsChrome2],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Rectangle())
                        }
                        .padding(.horizontal, 20)
                        
                        Text("7 days free, then $10/month. Cancel anytime.")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.modaicsCottonLight)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.modaicsCottonLight)
                    }
                }
            }
        }
    }
}

struct PremiumFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.modaicsChrome1)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCotton)
                
                Text(description)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCottonLight)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
        }
        .padding(16)
        .background(
            Rectangle()
                .fill(Color.modaicsDarkBlue.opacity(0.6))
                .overlay(
                    Rectangle()
                        .stroke(Color.modaicsChrome1.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

