//
//  ProfileView.swift
//  ModaicsAppTemp
//
//  Digital Wardrobe, Eco Points, and Sustainability Dashboard
//  Dark Green Porsche Aesthetic - Luxury Sustainable Fashion
//  Created by Harvey Houlahan on 6/6/2025.
//

import SwiftUI

struct ProfileView: View {
    let userType: ContentView.UserType
    @EnvironmentObject var viewModel: FashionViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
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
                // Premium dark green gradient background
                LinearGradient.forestBackground
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
                .environmentObject(authViewModel)
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
                let brandId = userType == .brand ? "brand-\(authViewModel.currentUser?.username ?? "temp")" : "brand-temp"
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
                    .fill(.luxeGoldGradient)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: userType == .brand ? "building.2.fill" : "person.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.forestDeep)
                    )
                
                // Membership badge
                Circle()
                    .fill(authViewModel.currentUser?.membershipTier == .premium ? Color.earthAmber : Color.sageSubtle)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: authViewModel.currentUser?.membershipTier == .premium ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(.sageWhite)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(authViewModel.currentUser?.displayName ?? authViewModel.currentUser?.username ?? "User")
                    .font(.forestHeadline(24))
                    .foregroundColor(.sageWhite)
                
                Text(viewType == .brand ? "Brand Account" : membershipText)
                    .font(.forestCaption(14))
                    .foregroundColor(.luxeGold)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "tshirt.fill")
                            .font(.caption)
                        Text("\(wardrobeItems.count)")
                            .font(.forestCaption(13))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                        Text("\(viewModel.likedIDs.count)")
                            .font(.forestCaption(13))
                    }
                }
                .foregroundColor(.sageMuted)
            }
            
            Spacer()
            
            Button {
                HapticManager.shared.buttonTap()
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundColor(.luxeGold)
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
                        .foregroundStyle(.emeraldGradient)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Eco Points")
                            .font(.forestHeadline(18))
                            .foregroundColor(.sageWhite)
                        
                        Text("Earned from sustainable actions")
                            .font(.forestCaption(12))
                            .foregroundColor(.sageMuted)
                    }
                }
                
                Spacer()
                
                Text("\(authViewModel.currentUser?.ecoPoints ?? 0)")
                    .font(.forestDisplay(32))
                    .foregroundStyle(.emeraldGradient)
            }
            
            // Eco Points breakdown
            VStack(spacing: 10) {
                EcoPointRow(
                    icon: "arrow.triangle.swap",
                    action: "Items Swapped",
                    points: "+50 pts each",
                    color: .natureTeal
                )
                
                EcoPointRow(
                    icon: "dollarsign.circle.fill",
                    action: "Second-hand Purchases",
                    points: "+25 pts each",
                    color: .emerald
                )
                
                EcoPointRow(
                    icon: "calendar.badge.checkmark",
                    action: "Event Attendance",
                    points: "+75 pts each",
                    color: .earthAmber
                )
                
                EcoPointRow(
                    icon: "star.fill",
                    action: "Sustainability Badge Items",
                    points: "+100 pts",
                    color: .luxeGold
                )
            }
            
            // Redeem button
            if authViewModel.currentUser?.membershipTier != .premium {
                Button {
                    HapticManager.shared.buttonTap()
                    showMembershipUpgrade = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Upgrade to Premium")
                        Image(systemName: "arrow.right")
                    }
                    .font(.forestCaption(15))
                    .foregroundColor(.forestDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.luxeGoldGradient)
                    .clipShape(RoundedRectangle(cornerRadius: ForestRadius.medium))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: ForestRadius.xlarge)
                .fill(.forestMid.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: ForestRadius.xlarge)
                        .stroke(
                            LinearGradient(
                                colors: [.emerald.opacity(0.3), .natureTeal.opacity(0.3)],
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
                    .foregroundColor(.emerald)
                
                Text("Your Impact")
                    .font(.forestHeadline(20))
                    .foregroundColor(.sageWhite)
                
                Spacer()
                
                Text("This Month")
                    .font(.forestCaption(12))
                    .foregroundColor(.sageMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.surfaceElevated)
                    .clipShape(Capsule())
            }
            
            // Impact metrics
            VStack(spacing: 14) {
                SustainabilityMetric(
                    icon: "drop.fill",
                    label: "Water Saved",
                    value: "\(calculateWaterSaved()) L",
                    change: "+12%",
                    color: .natureTeal,
                    description: "vs last month"
                )
                
                SustainabilityMetric(
                    icon: "cloud.fill",
                    label: "CO₂ Offset",
                    value: "\(viewModel.calculateUserSustainabilityScore()) kg",
                    change: "+8%",
                    color: .emerald,
                    description: "vs last month"
                )
                
                SustainabilityMetric(
                    icon: "arrow.3.trianglepath",
                    label: "Items Circulated",
                    value: "\(circulatedItemsCount)",
                    change: "+5",
                    color: .earthAmber,
                    description: "new this month"
                )
                
                SustainabilityMetric(
                    icon: "leaf.fill",
                    label: "Sustainability Score",
                    value: "\(viewModel.calculateUserSustainabilityScore())%",
                    change: "+3%",
                    color: .organicGreen,
                    description: "keep it up!"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: ForestRadius.xlarge)
                .fill(.forestMid.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: ForestRadius.xlarge)
                        .stroke(
                            LinearGradient(
                                colors: [.emerald.opacity(0.3), .natureTeal.opacity(0.3)],
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
                    .fill(.luxeGoldGradient)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "pencil.and.scribble")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.forestDeep)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("My Sketchbook")
                        .font(.forestHeadline(20))
                        .foregroundColor(.sageWhite)
                    
                    Text("Share WIPs, drops, and behind-the-scenes with your community")
                        .font(.forestCaption(13))
                        .foregroundColor(.sageMuted)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.luxeGold)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: ForestRadius.xlarge)
                    .fill(.forestMid.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: ForestRadius.xlarge)
                            .stroke(.luxeGoldGradient, lineWidth: 2)
                    )
            )
        }
    }
    
    // MARK: - Digital Wardrobe
    private var digitalWardrobe: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Digital Wardrobe")
                    .font(.forestHeadline(22))
                    .foregroundColor(.sageWhite)
                
                Spacer()
                
                Text("\(wardrobeItems.count) items")
                    .font(.forestCaption(14))
                    .foregroundColor(.sageMuted)
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
                            withAnimation(.forestSpring) {
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
                        .font(.system(size: 48))
                        .foregroundColor(.sageMuted.opacity(0.5))
                    
                    Text("No \(selectedTab.rawValue) Items")
                        .font(.forestHeadline(18))
                        .foregroundColor(.sageWhite)
                    
                    Text("Items you \(selectedTab.rawValue.lowercased()) will appear here")
                        .font(.forestCaption(14))
                        .foregroundColor(.sageMuted)
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
        switch authViewModel.currentUser?.membershipTier {
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
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(action)
                .font(.forestCaption(13))
                .foregroundColor(.sageMuted)
            
            Spacer()
            
            Text(points)
                .font(.forestCaption(13))
                .foregroundColor(.emerald)
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
                    .font(.forestCaption(13))
                    .foregroundColor(.sageMuted)
                
                HStack(spacing: 8) {
                    Text(value)
                        .font(.forestHeadline(22))
                        .foregroundColor(.sageWhite)
                    
                    Text(change)
                        .font(.forestCaption(12))
                        .foregroundColor(.emerald)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.emerald.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                Text(description)
                    .font(.forestCaption(11))
                    .foregroundColor(.sageSubtle)
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
                    .font(.system(size: 14))
                
                Text(tab.rawValue)
                    .font(.forestCaption(14))
                
                Text("\(count)")
                    .font(.forestCaption(12))
                    .foregroundColor(isSelected ? .forestDeep : .sageMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        isSelected ? Color.luxeGold : Color.surfaceElevated
                    )
                    .clipShape(Capsule())
            }
            .foregroundColor(isSelected ? .sageWhite : .sageMuted)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: ForestRadius.medium)
                    .fill(isSelected ? Color.luxeGold.opacity(0.2) : Color.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: ForestRadius.medium)
                            .stroke(
                                isSelected ? Color.luxeGold.opacity(0.5) : Color.clear,
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
                RoundedRectangle(cornerRadius: ForestRadius.medium)
                    .fill(.surfaceElevated)
                    .aspectRatio(3/4, contentMode: .fit)
                    .overlay(
                        Group {
                            if let imageURL = item.imageURLs.first {
                                PremiumCachedImage(url: imageURL, contentMode: .fill)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: ForestRadius.medium))
                    .overlay(
                        // Status badge
                        VStack {
                            HStack {
                                Spacer()
                                
                                if item.isSold {
                                    statusBadge(text: "Sold", color: .organicGreen)
                                } else if item.isSwapped {
                                    statusBadge(text: "Swapped", color: .natureTeal)
                                } else if item.isRented {
                                    statusBadge(text: "Rented", color: .earthAmber)
                                }
                            }
                            Spacer()
                        }
                        .padding(8)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.brand)
                        .font(.forestCaption(11))
                        .foregroundColor(.luxeGold)
                    
                    Text(item.name)
                        .font(.forestBody(14))
                        .foregroundColor(.sageWhite)
                        .lineLimit(2)
                    
                    if item.listingPrice > 0 {
                        Text("$\(Int(item.listingPrice))")
                            .font(.forestCaption(13))
                            .foregroundColor(.luxeGoldBright)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.forestCaption(10))
            .foregroundColor(.sageWhite)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - Membership Upgrade View
struct MembershipUpgradeView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.forestBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.earthAmber, .luxeGold],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Upgrade to Premium")
                                .font(.forestDisplay(32))
                                .foregroundColor(.sageWhite)
                            
                            Text("Unlock unlimited potential")
                                .font(.forestCaption(16))
                                .foregroundColor(.sageMuted)
                        }
                        .padding(.top, 40)
                        
                        // Pricing
                        VStack(spacing: 8) {
                            Text("$10")
                                .font(.forestDisplay(56))
                                .foregroundStyle(.luxeGoldGradient)
                            
                            Text("per month")
                                .font(.forestCaption(16))
                                .foregroundColor(.sageMuted)
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
                            HapticManager.shared.success()
                        } label: {
                            Text("Start Free Trial")
                                .font(.forestHeadline(18))
                                .foregroundColor(.forestDeep)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.luxeGoldGradient)
                                .clipShape(RoundedRectangle(cornerRadius: ForestRadius.large))
                        }
                        .padding(.horizontal, 20)
                        
                        Text("7 days free, then $10/month. Cancel anytime.")
                            .font(.forestCaption(12))
                            .foregroundColor(.sageMuted)
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
                            .foregroundColor(.sageMuted)
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
                .foregroundColor(.luxeGold)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.forestHeadline(16))
                    .foregroundColor(.sageWhite)
                
                Text(description)
                    .font(.forestCaption(13))
                    .foregroundColor(.sageMuted)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.emerald)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: ForestRadius.medium)
                .fill(.forestMid.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: ForestRadius.medium)
                        .stroke(.luxeGold.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ProfileView(userType: .user)
        .environmentObject(FashionViewModel())
}
