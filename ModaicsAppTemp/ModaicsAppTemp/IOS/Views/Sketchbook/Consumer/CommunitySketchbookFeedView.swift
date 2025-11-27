//
//  CommunitySketchbookFeedView.swift
//  ModaicsAppTemp
//
//  Aggregated feed of Sketchbook posts from all followed brands
//

import SwiftUI

struct CommunitySketchbookFeedView: View {
    @StateObject private var viewModel = ConsumerSketchbookViewModel(userId: "consumer-test")
    
    @State private var feedPosts: [SketchbookPost] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedBrand: BrandIdentifier?
    @State private var memberships: [Int: SketchbookMembership] = [:] // sketchbookId -> membership
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .padding(.bottom, 20)
            
            // Feed
            if isLoading && feedPosts.isEmpty {
                loadingView
            } else if let error = errorMessage {
                errorView(message: error)
            } else if feedPosts.isEmpty {
                emptyFeedView
            } else {
                feedContent
            }
        }
        .task {
            await loadFeed()
        }
        .sheet(item: $selectedBrand) { brand in
            NavigationView {
                BrandSketchbookPublicView(brandId: brand.id, brandName: brand.name)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sketchbook Feed")
                        .font(.system(size: 28, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCotton)
                    
                    Text("Latest from brands you follow")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCottonLight)
                }
                
                Spacer()
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.modaicsChrome1, .modaicsChrome2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "pencil.and.scribble")
                            .font(.system(size: 22, weight: .medium, design: .monospaced))
                            .foregroundColor(.modaicsDarkBlue)
                    )
            }
        }
    }
    
    // MARK: - Feed Content
    
    private var feedContent: some View {
        LazyVStack(spacing: 0) {
            ForEach($feedPosts) { $post in
                VStack(alignment: .leading, spacing: 12) {
                    // Brand header
                    brandHeader(for: post)
                        .padding(.horizontal, 16)
                    
                    // Post card - full width with padding to show border
                    SketchbookPostCardView(
                        post: post,
                        userMembership: memberships[post.sketchbookId],
                        onLike: {
                            Task { await toggleReaction(postId: post.id) }
                        },
                        onComment: {
                            // TODO: Open comments
                        },
                        onVote: { optionIndex in
                            Task { await voteInPoll(postId: post.id, optionIndex: optionIndex) }
                        }
                    )
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 24)
            }
        }
    }
    
    private func brandHeader(for post: SketchbookPost) -> some View {
        Button(action: {
            selectedBrand = BrandIdentifier(
                id: post.brandId ?? "unknown",
                name: post.authorDisplayName ?? post.authorUsername ?? "Brand"
            )
        }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.modaicsChrome1.opacity(0.3), .modaicsChrome2.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.modaicsChrome1)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorDisplayName ?? post.authorUsername ?? "Brand")
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCotton)
                    
                    Text("View Sketchbook")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCottonLight)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.modaicsCottonLight)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyFeedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsChrome1.opacity(0.5))
            
            Text("No Sketchbook Updates")
                .font(.system(size: 20, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsCotton)
            
            Text("Follow some brands to see their behind-the-scenes content here")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsCottonLight)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            ModaicsPrimaryButton(
                "Discover Brands",
                icon: "magnifyingglass"
            ) {
                // TODO: Navigate to brand discovery
            }
            .frame(maxWidth: 280)
        }
        .padding(.vertical, 80)
    }
    
    // MARK: - Loading & Error
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.modaicsChrome1)
            Text("Loading feed...")
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsCottonLight)
        }
        .padding(.vertical, 60)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Error Loading Feed")
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsCotton)
            
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsCottonLight)
                .multilineTextAlignment(.center)
            
            ModaicsPrimaryButton("Try Again") {
                Task { await loadFeed() }
            }
            .frame(maxWidth: 200)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func loadFeed() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let service = SketchbookService()
            feedPosts = try await service.getCommunityFeed(userId: "consumer-test")
            
            // Load memberships for all sketchbooks in the feed
            await loadMemberships()
            
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func loadMemberships() async {
        let service = SketchbookService()
        let uniqueSketchbookIds = Set(feedPosts.map { $0.sketchbookId })
        
        print("🔐 Loading memberships for \(uniqueSketchbookIds.count) sketchbooks: \(uniqueSketchbookIds)")
        
        for sketchbookId in uniqueSketchbookIds {
            do {
                let membership = try await service.checkMembership(
                    sketchbookId: sketchbookId,
                    userId: "consumer-test"
                )
                if let membership = membership {
                    print("✅ Found membership for sketchbook \(sketchbookId): status=\(membership.status)")
                    memberships[sketchbookId] = membership
                } else {
                    print("❌ No membership for sketchbook \(sketchbookId)")
                }
            } catch {
                // No membership for this sketchbook, which is fine
                print("⚠️ Error checking membership for sketchbook \(sketchbookId): \(error)")
                continue
            }
        }
        
        print("🔐 Total memberships loaded: \(memberships.count)")
    }
    
    private func toggleReaction(postId: Int) async {
        let service = SketchbookService()
        do {
            // Check if already liked (simplified - should track this)
            _ = try await service.addReaction(
                postId: postId,
                userId: "consumer-test",
                reactionType: .like
            )
            // Update local post
            if let index = feedPosts.firstIndex(where: { $0.id == postId }) {
                feedPosts[index].reactionsCount += 1
            }
        } catch {
            // Handle error
        }
    }
    
    private func voteInPoll(postId: Int, optionIndex: Int) async {
        do {
            let service = SketchbookService()
            
            // Get the option ID from the post
            guard let post = feedPosts.first(where: { $0.id == postId }),
                  let options = post.pollOptions,
                  optionIndex < options.count else {
                return
            }
            
            let optionId = options[optionIndex].id
            
            let results = try await service.voteInPoll(
                postId: postId,
                userId: "consumer-test",
                optionId: optionId
            )
            
            // Update local post with new results
            if let index = feedPosts.firstIndex(where: { $0.id == postId }) {
                feedPosts[index].pollOptions = results.options
            }
        } catch {
            // Handle error
        }
    }
}

// MARK: - Brand Identifier (for sheet)
extension CommunitySketchbookFeedView {
    struct BrandIdentifier: Identifiable {
        let id: String
        let name: String
    }
}

// MARK: - Preview
#Preview {
    CommunitySketchbookFeedView()
}
