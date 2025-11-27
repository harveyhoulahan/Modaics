//
//  SustainabilityLeaderboard.swift
//  ModaicsAppTemp
//
//  Leaderboard showing top eco-conscious users
//  Created by Harvey Houlahan on 26/11/2025.
//

import SwiftUI

struct SustainabilityLeaderboardView: View {
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var selectedPeriod: Period = .thisWeek
    
    enum Period: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case allTime = "All Time"
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
                        // Header
                        header
                        
                        // Period Selector
                        periodSelector
                        
                        // Top 3 Podium
                        topThreePodium
                        
                        // Leaderboard List
                        leaderboardList
                        
                        // Your Position
                        yourPosition
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Header
    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Sustainability Champions")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.modaicsCotton)
            
            Text("Making fashion more sustainable, one swap at a time")
                .font(.system(size: 14))
                .foregroundColor(.modaicsCottonLight)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Period Selector
    private var periodSelector: some View {
        HStack(spacing: 12) {
            ForEach(Period.allCases, id: \.self) { period in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedPeriod == period ? .modaicsCotton : .modaicsCottonLight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedPeriod == period ? Color.modaicsChrome1.opacity(0.2) : Color.modaicsSurface2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            selectedPeriod == period ? Color.modaicsChrome1.opacity(0.5) : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Top 3 Podium
    private var topThreePodium: some View {
        HStack(alignment: .bottom, spacing: 16) {
            // Second Place
            PodiumCard(
                rank: 2,
                userName: "Marcus L.",
                ecoPoints: 2450,
                color: Color(red: 0.75, green: 0.75, blue: 0.75)
            )
            
            // First Place
            PodiumCard(
                rank: 1,
                userName: "Sarah C.",
                ecoPoints: 3200,
                color: .yellow,
                isWinner: true
            )
            
            // Third Place
            PodiumCard(
                rank: 3,
                userName: "Emma W.",
                ecoPoints: 1980,
                color: Color(red: 0.8, green: 0.5, blue: 0.2)
            )
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Leaderboard List
    private var leaderboardList: some View {
        VStack(spacing: 12) {
            Text("Top Contributors")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.modaicsCotton)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                ForEach(4...10, id: \.self) { rank in
                    LeaderboardRow(
                        rank: rank,
                        userName: mockUserNames[rank - 1],
                        ecoPoints: mockEcoPoints[rank - 1],
                        change: mockChanges[rank - 1]
                    )
                }
            }
        }
    }
    
    // MARK: - Your Position
    private var yourPosition: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Position")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.modaicsCotton)
            
            HStack(spacing: 16) {
                Text("#24")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.modaicsChrome1)
                    .frame(width: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.currentUser?.username ?? "You")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.modaicsCotton)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "leaf.fill")
                                .font(.caption)
                            Text("\(viewModel.currentUser?.ecoPoints ?? 0) points")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.green)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.caption)
                            Text("+3 this week")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Top 15%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text("320 pts to #23")
                        .font(.system(size: 11))
                        .foregroundColor(.modaicsCottonLight)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.modaicsChrome1.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.modaicsChrome1.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Mock Data
    private let mockUserNames = [
        "Sarah C.", "Marcus L.", "Emma W.", "James T.", "Olivia R.",
        "Noah K.", "Sophia M.", "Liam P.", "Ava G.", "Ethan B."
    ]
    
    private let mockEcoPoints = [3200, 2450, 1980, 1750, 1620, 1480, 1340, 1190, 1050, 920]
    
    private let mockChanges = [
        "+2", "-1", "+1", "→", "+3", "-2", "+1", "+4", "→", "+2"
    ]
}

// MARK: - Supporting Views

struct PodiumCard: View {
    let rank: Int
    let userName: String
    let ecoPoints: Int
    let color: Color
    var isWinner: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Crown for winner
            if isWinner {
                Image(systemName: "crown.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
                    .offset(y: -10)
            }
            
            // Rank badge
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: isWinner ? 70 : 60, height: isWinner ? 70 : 60)
                
                Text("\(rank)")
                    .font(.system(size: isWinner ? 32 : 24, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: color.opacity(0.5), radius: 10)
            
            VStack(spacing: 4) {
                Text(userName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.modaicsCotton)
                
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.caption2)
                    Text("\(ecoPoints)")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.green)
            }
            
            // Podium height
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: isWinner ? 120 : rank == 2 ? 90 : 70)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.5), lineWidth: 2)
                )
        }
        .frame(maxWidth: .infinity)
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let userName: String
    let ecoPoints: Int
    let change: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            Text("\(rank)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.modaicsCottonLight)
                .frame(width: 40, alignment: .center)
            
            // Avatar placeholder
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(userName.prefix(1)))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.modaicsCotton)
                
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.caption2)
                    Text("\(ecoPoints) points")
                        .font(.system(size: 12))
                }
                .foregroundColor(.green)
            }
            
            Spacer()
            
            // Rank change
            changeIndicator(change)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.modaicsDarkBlue.opacity(0.4))
        )
    }
    
    @ViewBuilder
    private func changeIndicator(_ change: String) -> some View {
        if change.hasPrefix("+") {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.caption)
                Text(change)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.green)
        } else if change.hasPrefix("-") {
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.caption)
                Text(change)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.red)
        } else {
            HStack(spacing: 4) {
                Image(systemName: "minus.circle.fill")
                    .font(.caption)
                Text(change)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.modaicsCottonLight)
        }
    }
}

#Preview {
    SustainabilityLeaderboardView()
        .environmentObject(FashionViewModel())
}
