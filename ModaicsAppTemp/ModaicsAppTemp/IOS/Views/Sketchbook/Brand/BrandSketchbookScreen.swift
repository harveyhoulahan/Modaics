//
//  BrandSketchbookScreen.swift
//  ModaicsAppTemp
//
//  Main Sketchbook management screen for brands
//

import SwiftUI

struct BrandSketchbookScreen: View {
    @StateObject private var viewModel: BrandSketchbookViewModel
    @Environment(\.dismiss) private var dismiss
    
    let brandId: String
    
    @State private var showPostEditor = false
    @State private var showSettings = false
    @State private var selectedPost: SketchbookPost?
    
    init(brandId: String) {
        self.brandId = brandId
        _viewModel = StateObject(wrappedValue: BrandSketchbookViewModel(userId: brandId))
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.modaicsDarkBlue,
                    Color.modaicsMidBlue.opacity(0.8),
                    Color.modaicsDarkBlue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
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
        }
        .sheet(isPresented: $showPostEditor) {
            SketchbookPostEditorView(viewModel: viewModel)
        }
        .sheet(isPresented: $showSettings) {
            if let sketchbook = viewModel.sketchbook {
                SketchbookSettingsView(sketchbook: sketchbook, viewModel: viewModel)
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
                    onSettingsTap: { showSettings = true },
                    onJoinTap: nil,
                    isBrandView: true
                )
                .padding(.horizontal)
                
                // Analytics
                analyticsSection
                
                // Create Post Button
                ModaicsPrimaryButton(
                    "Create New Post",
                    icon: "plus.circle.fill"
                ) {
                    showPostEditor = true
                }
                .padding(.horizontal)
                
                // Posts
                postsSection
            }
            .padding(.vertical)
        }
        .navigationTitle("My Sketchbook")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.modaicsCotton)
                }
            }
        }
    }
    
    // MARK: - Analytics Section
    
    private var analyticsSection: some View {
        VStack(spacing: 16) {
            Text("Analytics")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.modaicsCotton)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                analyticsCard(
                    title: "Total Views",
                    value: "\(viewModel.totalViews)",
                    icon: "eye.fill",
                    color: .modaicsChrome1
                )
                
                analyticsCard(
                    title: "Engagement",
                    value: String(format: "%.1f%%", viewModel.engagementRate),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
            }
            
            if let topPost = viewModel.topPost {
                topPostCard(post: topPost)
            }
        }
        .padding(.horizontal)
    }
    
    private func analyticsCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.modaicsCottonLight)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.modaicsCotton)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.modaicsSurface2)
        .clipShape(Rectangle())
        .overlay(
            Rectangle()
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func topPostCard(post: SketchbookPost) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.modaicsChrome1)
                Text("Top Performing Post")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.modaicsCotton)
            }
            
            Text(post.title)
                .font(.system(size: 14))
                .foregroundColor(.modaicsCottonLight)
                .lineLimit(2)
            
            HStack(spacing: 16) {
                statLabel(icon: "eye.fill", value: post.viewsCount)
                statLabel(icon: "heart.fill", value: post.reactionsCount)
                statLabel(icon: "bubble.right.fill", value: post.commentsCount)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color.modaicsChrome1.opacity(0.1),
                    Color.modaicsChrome2.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Rectangle())
        .overlay(
            Rectangle()
                .stroke(Color.modaicsLightBlue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func statLabel(icon: String, value: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text("\(value)")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.modaicsCottonLight)
    }
    
    // MARK: - Posts Section
    
    private var postsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Posts")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.modaicsCotton)
                
                Spacer()
                
                Text("\(viewModel.posts.count) total")
                    .font(.system(size: 13))
                    .foregroundColor(.modaicsCottonLight)
            }
            .padding(.horizontal)
            
            if viewModel.posts.isEmpty {
                emptyPostsView
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.posts) { post in
                        SketchbookPostCardView(
                            post: post,
                            userMembership: viewModel.membership,
                            onLike: {
                                Task { await viewModel.toggleReaction(for: post) }
                            },
                            onComment: {
                                selectedPost = post
                            }
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await viewModel.deletePost(post) }
                            } label: {
                                Label("Delete Post", systemImage: "trash")
                            }
                        }
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
            
            Text("Share your first update with your community")
                .font(.system(size: 14))
                .foregroundColor(.modaicsCottonLight)
                .multilineTextAlignment(.center)
            
            ModaicsPrimaryButton(
                "Create Post",
                icon: "plus.circle.fill"
            ) {
                showPostEditor = true
            }
            .frame(maxWidth: 280)
        }
        .padding(.vertical, 60)
        .padding(.horizontal)
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
        BrandSketchbookScreen(brandId: "brand-123")
    }
}
