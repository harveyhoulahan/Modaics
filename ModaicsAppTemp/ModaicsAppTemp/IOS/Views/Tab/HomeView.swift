//
//  HomeView.swift
//  ModaicsAppTemp
//
//  Created by Harvey Houlahan on 6/6/2025.
//

import SwiftUI

struct HomeView: View {
    let userType: ContentView.UserType            // .user or .brand
    @EnvironmentObject var viewModel: FashionViewModel

    // ───────── UI state
    @State private var headerOffset:  CGFloat = -50
    @State private var welcomeScale:  CGFloat = 0.90
    @State private var cardVisible               = [false, false, false, false]

    // sheets
    @State private var showNotifications = false
    @State private var showSettings      = false

    // MARK: - body
    var body: some View {
        NavigationStack {
            ZStack {
                // premium gradient background
                LinearGradient(colors: [.modaicsDarkBlue, .modaicsMidBlue],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {

                        header.padding(.horizontal, 20)
                               .padding(.top, 12)
                               .offset(y: headerOffset)

                        Text(userType == .user ? "Your Digital Wardrobe"
                                               : "Brand Dashboard")
                            .font(.system(size: 36, weight: .ultraLight, design: .serif))
                            .foregroundColor(.modaicsCotton)
                            .padding(.horizontal, 20)
                            .offset(y: headerOffset)

                        PremiumWelcomeCard(userType: userType)
                            .padding(.horizontal, 20)
                            .scaleEffect(welcomeScale)

                        featureGrid
                            .padding(.horizontal, 20)

                        // Recommended carousel
                        if !viewModel.recommendedItems.isEmpty {
                            recommendedSection
                        }

                        // Sustainability snapshot (User only)
                        if userType == .user {
                            sustainabilitySection.padding(.horizontal, 20)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.vertical)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showNotifications) { NotificationsView() }
        .sheet(isPresented: $showSettings)      { SettingsView()      }
        .onAppear { runAppearAnimations() }
    }

    // MARK: - header
    private var header: some View {
        HStack {
            ModaicsMosaicLogo(size: 100)
            Text("modaics")
                .font(.system(size: 24, weight: .ultraLight, design: .serif))
                .foregroundStyle(
                    LinearGradient(colors: [.modaicsChrome1, .modaicsChrome2],
                                   startPoint: .leading, endPoint: .trailing))

            Spacer()

            HStack(spacing: 20) {
                Button { showNotifications = true } label: {
                    Image(systemName: "bell")
                        .font(.title3)
                        .foregroundColor(.modaicsChrome1)
                }
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundColor(.modaicsChrome1)
                }
            }
        }
    }

    // MARK: - feature grid
    private var featureGrid: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 16), count: 2),
                  spacing: 16) {
            ForEach(0..<4, id: \.self) { idx in
                PremiumFeatureTile(
                    title: featureTitle(idx),
                    icon:  featureIcon(idx),
                    gradient: featureGradient(idx),
                    isVisible: cardVisible[idx]
                )
            }
        }
    }

    // MARK: - recommended carousel
    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended for You")
                .font(.headline)
                .foregroundColor(.modaicsCotton)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.recommendedItems) { item in
                        EnhancedItemCard(item: item)
                            .environmentObject(viewModel)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - sustainability block
    private var sustainabilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Sustainability Impact")
                .font(.headline)
                .foregroundColor(.modaicsCotton)

            HStack(spacing: 20) {
                SustainabilityMetric(icon: "drop.fill",
                                     value: "2,500L",
                                     label: "Water Saved",
                                     color: .blue)
                SustainabilityMetric(icon: "leaf.fill",
                                     value: "\(viewModel.calculateUserSustainabilityScore())kg",
                                     label: "CO₂ Reduced",
                                     color: .green)
                SustainabilityMetric(icon: "arrow.3.trianglepath",
                                     value: "\(viewModel.userWardrobe.filter { $0.sustainabilityScore.isRecycled }.count)",
                                     label: "Items Recycled",
                                     color: .orange)
            }
            .padding()
            .background(Color.modaicsDarkBlue.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.modaicsChrome1.opacity(0.3), lineWidth: 1))
        }
    }

    // MARK: - helpers
    private func featureTitle(_ idx: Int) -> String {
        [
            userType == .user ? "Discover Items" : "Manage Catalog",
            userType == .user ? "My Wardrobe"    : "Brand Profile",
            "Sustainability Score",
            userType == .user ? "Community"      : "Customer Insights"
        ][idx]
    }
    private func featureIcon(_ idx: Int) -> String {
        ["magnifyingglass", "square.grid.3x3.fill", "leaf.fill", "chart.bar.fill"][idx]
    }
    private func featureGradient(_ idx: Int) -> [Color] {
        [
            [.modaicsDenim1, .modaicsDenim2],
            [.modaicsChrome1, .modaicsChrome2],
            [Color(red: 0.2, green: 0.6, blue: 0.4),
             Color(red: 0.15, green: 0.5, blue: 0.3)],
            [.modaicsChrome2, .modaicsChrome3]
        ][idx]
    }

    private func runAppearAnimations() {
        withAnimation(.modaicsSpring) {
            headerOffset  = 0
            welcomeScale  = 1
        }
        for i in cardVisible.indices {
            withAnimation(.modaicsSpring.delay(0.3 + Double(i)*0.1)) {
                cardVisible[i] = true
            }
        }
    }
}
