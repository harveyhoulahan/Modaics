//
//  BrandSketchbookPublicView.swift
//  ModaicsAppTemp
//
//  Consumer view of a brand's Sketchbook (public browsing with unlock CTAs)
//

import SwiftUI

struct BrandSketchbookPublicView: View {
    @StateObject private var viewModel = ConsumerSketchbookViewModel(userId: "user-temp")
    @Environment(\.dismiss) private var dismiss
    
    let brandId: String
    let brandName: String
    
    @State private var selectedPost: SketchbookPost?
    
    var body: some View {
        ZStack {
            // Background gradient - matching other pages exactly
            LinearGradient(
                colors: [.modaicsDarkBlue, .modaicsMidBlue],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.sketchbook == nil {
                loadingView
            } else if let sketchbook = viewModel.sketchbook {
                contentView(sketchbook: sketchbook)
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            }
        }
        .task {
            await viewModel.loadSketchbook(brandId: brandId)
            await viewModel.checkSpendEligibility()
        }
        .sheet(isPresented: $viewModel.showUnlockSheet) {
            unlockSheet
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(brandName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.modaicsCotton)
            }
        }
    }
    
    // MARK: - Content View
    
    private func contentView(sketchbook: Sketchbook) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                SketchbookHeaderView(
                    sketchbook: sketchbook,
                    membership: viewModel.membership,
                    onSettingsTap: nil,
                    onJoinTap: {
                        viewModel.showUnlockSheet = true
                    }
                )
                .padding(.horizontal)
                
                // Unlock CTA (if needed)
                if viewModel.hasLockedContent && viewModel.membership == nil {
                    subscribeCTA
                }
                
                // Posts
                postsSection
            }
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Subscribe CTA
    
    private var subscribeCTA: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.modaicsChrome1, .modaicsChrome2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.lockedPostsCount) Exclusive Posts")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.modaicsCotton)
                    
                    Text(viewModel.unlockDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.modaicsCottonLight)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            Button(action: {
                viewModel.showUnlockSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                    
                    Text(viewModel.unlockCallToAction.replacingOccurrences(of: "Join", with: "Subscribe").replacingOccurrences(of: "Unlock", with: "Subscribe"))
                        .font(.system(size: 16, weight: .semibold))
                }
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
        .padding(20)
        .background(
            Rectangle()
                .fill(Color.modaicsDarkBlue.opacity(0.6))
        )
        .overlay(
            Rectangle()
                .stroke(
                    LinearGradient(
                        colors: [.modaicsChrome1.opacity(0.5), .modaicsChrome2.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.modaicsChrome1.opacity(0.2), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
    }
    
    // MARK: - Posts Section
    
    private var postsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Posts")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.modaicsCotton)
                
                Spacer()
                
                if viewModel.hasLockedContent {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.caption)
                        Text("\(viewModel.visiblePosts.count) of \(viewModel.posts.count)")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.modaicsCottonLight)
                }
            }
            .padding(.horizontal)
            
            if viewModel.visiblePosts.isEmpty {
                emptyPostsView
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.visiblePosts) { post in
                        SketchbookPostCardView(
                            post: post,
                            userMembership: viewModel.membership,
                            onLike: {
                                Task { await viewModel.toggleReaction(for: post) }
                            },
                            onComment: {
                                selectedPost = post
                            },
                            onVote: { optionIndex in
                                // Get the option ID from the post
                                if let options = post.pollOptions, optionIndex < options.count {
                                    let optionId = options[optionIndex].id
                                    Task { await viewModel.voteInPoll(post: post, optionId: optionId) }
                                }
                            }
                        )
                    }
                    
                    // Locked content teaser
                    if viewModel.hasLockedContent {
                        lockedContentTeaser
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var emptyPostsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "pencil.and.scribble")
                .font(.system(size: 50))
                .foregroundColor(.modaicsChrome1.opacity(0.5))
            
            Text("No posts yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.modaicsCotton)
            
            Text("This Sketchbook is just getting started")
                .font(.system(size: 14))
                .foregroundColor(.modaicsCottonLight)
        }
        .padding(.vertical, 60)
    }
    
    private var lockedContentTeaser: some View {
        Button(action: { viewModel.showUnlockSheet = true }) {
            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.modaicsChrome1.opacity(0.7))
                
                Text("+\(viewModel.lockedPostsCount) More Exclusive Posts")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.modaicsCotton)
                
                Text(viewModel.unlockCallToAction)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsChrome1)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.modaicsChrome1.opacity(0.2))
                    .clipShape(Rectangle())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 50)
            .background(Color.modaicsSurface2)
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
                    .foregroundColor(.modaicsChrome1.opacity(0.3))
            )
        }
    }
    
    // MARK: - Subscribe Sheet
    
    private var unlockSheet: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.modaicsDarkBlue,
                        Color.modaicsMidBlue.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.modaicsChrome1, .modaicsChrome2],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "star.fill")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.modaicsDarkBlue)
                            )
                            .shadow(color: Color.modaicsChrome1.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        // Title
                        Text("Subscribe to \(brandName)")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.modaicsCotton)
                        
                        Text(viewModel.unlockDescription)
                            .font(.system(size: 15))
                            .foregroundColor(.modaicsCottonLight)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Benefits
                        benefitsList
                        
                        Spacer()
                        
                        // CTA Button
                        if viewModel.membership != nil {
                            // Already subscribed
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("You're subscribed!")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.modaicsCotton)
                                }
                                
                                ModaicsSecondaryButton("Done") {
                                    viewModel.showUnlockSheet = false
                                }
                            }
                        } else if let eligibility = viewModel.spendEligibility, eligibility.eligible {
                            // Can subscribe now
                            ModaicsPrimaryButton(
                                "Subscribe Now",
                                icon: "checkmark.circle.fill"
                            ) {
                                Task {
                                    let success = await viewModel.unlockFromSpend()
                                    if success {
                                        viewModel.showUnlockSheet = false
                                    }
                                }
                            }
                        } else {
                        // Need to take action
                        VStack(spacing: 12) {
                            if let eligibility = viewModel.spendEligibility {
                                // Progress indicator
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Progress")
                                            .font(.system(size: 14))
                                            .foregroundColor(.modaicsCottonLight)
                                        Spacer()
                                        Text("\(Int(eligibility.progressPercentage))%")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.modaicsChrome1)
                                    }
                                    
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(Color.modaicsSurface2)
                                            
                                            Rectangle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [.modaicsChrome1, .modaicsChrome2],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: geometry.size.width * (eligibility.progressPercentage / 100))
                                        }
                                    }
                                    .frame(height: 8)
                                }
                                .padding(.bottom, 8)
                            }
                            
                            ModaicsPrimaryButton(
                                "Shop Now",
                                icon: "bag.fill"
                            ) {
                                // TODO: Navigate to brand shop
                                viewModel.showUnlockSheet = false
                            }
                            
                            ModaicsSecondaryButton("Maybe Later") {
                                viewModel.showUnlockSheet = false
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Subscribe")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.modaicsCotton)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showUnlockSheet = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.modaicsCottonLight)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            benefitRow(icon: "star.fill", text: "Access to all exclusive posts")
            benefitRow(icon: "chart.bar.fill", text: "Vote in polls and influence decisions")
            benefitRow(icon: "calendar.badge.clock", text: "Early access to drops and events")
            benefitRow(icon: "bell.badge.fill", text: "Get notified of new updates")
        }
        .padding(20)
        .background(
            Rectangle()
                .fill(Color.modaicsDarkBlue.opacity(0.6))
        )
        .overlay(
            Rectangle()
                .stroke(
                    LinearGradient(
                        colors: [.modaicsChrome1.opacity(0.3), .modaicsChrome2.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.modaicsChrome1)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.modaicsCotton)
            
            Spacer()
        }
    }
    
    // MARK: - Loading & Error
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.modaicsChrome1)
            Text("Loading Sketchbook...")
                .font(.system(size: 15))
                .foregroundColor(.modaicsCottonLight)
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Error")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.modaicsCotton)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.modaicsCottonLight)
                .multilineTextAlignment(.center)
            
            ModaicsPrimaryButton("Try Again") {
                Task { await viewModel.loadSketchbook(brandId: brandId) }
            }
            .frame(maxWidth: 200)
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        BrandSketchbookPublicView(brandId: "brand-123", brandName: "Sustainable Brand")
    }
}
