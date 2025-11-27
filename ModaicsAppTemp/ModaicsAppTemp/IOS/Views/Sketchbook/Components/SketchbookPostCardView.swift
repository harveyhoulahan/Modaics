//
//  SketchbookPostCardView.swift
//  ModaicsAppTemp
//
//  Reusable card for displaying Sketchbook posts
//

import SwiftUI

struct SketchbookPostCardView: View {
    let post: SketchbookPost
    let userMembership: SketchbookMembership?
    let onLike: () -> Void
    let onComment: () -> Void
    let onVote: ((Int) -> Void)?
    let onImageTap: ((String) -> Void)?
    
    @State private var likeCount: Int
    @State private var hasLiked: Bool = false
    @State private var showFullCaption: Bool = false
    
    init(
        post: SketchbookPost,
        userMembership: SketchbookMembership? = nil,
        onLike: @escaping () -> Void = {},
        onComment: @escaping () -> Void = {},
        onVote: ((Int) -> Void)? = nil,
        onImageTap: ((String) -> Void)? = nil
    ) {
        self.post = post
        self.userMembership = userMembership
        self.onLike = onLike
        self.onComment = onComment
        self.onVote = onVote
        self.onImageTap = onImageTap
        _likeCount = State(initialValue: post.reactionsCount)
    }
    
    var canViewContent: Bool {
        post.isPublic || userMembership != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                postTypeIndicator
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(post.postType.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.modaicsCotton)
                        
                        if !post.isPublic {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.modaicsChrome1)
                        }
                    }
                    
                    Text(timeAgoString(from: post.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.modaicsCottonLight)
                }
                
                Spacer()
                
                // Event highlight badge
                if let eventHighlight = post.eventHighlight {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Event")
                            .font(.caption2)
                            .foregroundColor(.modaicsCottonLight)
                        Text(eventHighlight)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.modaicsChrome1)
                            .lineLimit(1)
                    }
                }
            }
            
            // Content
            if canViewContent {
                contentView
            } else {
                lockedContentView
            }
            
            // Engagement bar
            if canViewContent {
                engagementBar
            }
        }
        .padding(20)
        .background(
            Rectangle()
                .fill(Color.modaicsDarkBlue.opacity(0.7))
        )
        .overlay(
            Rectangle()
                .stroke(
                    LinearGradient(
                        colors: [
                            post.postType.gradientColors[0].opacity(0.6),
                            post.postType.gradientColors[1].opacity(0.5),
                            post.postType.gradientColors[0].opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: post.postType.accentColor.opacity(0.25), radius: 15, x: 0, y: 8)
    }
    
    // MARK: - Subviews
    
    private var postTypeIndicator: some View {
        Circle()
            .fill(LinearGradient(
                colors: post.postType.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: post.postType.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            )
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(post.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.modaicsCotton)
            
            // Media
            if !post.media.isEmpty {
                mediaGallery
            }
            
            // Caption/Body
            if let body = post.body, !body.isEmpty {
                captionView(body)
            }
            
            // Poll
            if let pollQuestion = post.pollQuestion, let pollOptions = post.pollOptions {
                SketchbookPollView(
                    question: pollQuestion,
                    options: pollOptions,
                    totalVotes: pollOptions.reduce(0) { $0 + $1.votes },
                    isPollClosed: post.isPollClosed,
                    userHasVoted: false, // TODO: Track user votes
                    onVote: onVote
                )
            }
        }
    }
    
    private var mediaGallery: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(post.media) { mediaAttachment in
                    AsyncImage(url: URL(string: mediaAttachment.url)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 280, height: 350)
                                .clipShape(Rectangle())
                                .onTapGesture {
                                    onImageTap?(mediaAttachment.url)
                                }
                        case .failure:
                            mediaPlaceholder
                        case .empty:
                            mediaPlaceholder
                        @unknown default:
                            mediaPlaceholder
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var mediaPlaceholder: some View {
        Rectangle()
            .fill(Color.modaicsDarkBlue.opacity(0.3))
            .frame(width: 280, height: 350)
            .overlay(
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.modaicsCottonLight)
            )
    }
    
    private func captionView(_ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(caption)
                .font(.system(size: 15))
                .foregroundColor(.modaicsCotton)
                .lineLimit(showFullCaption ? nil : 3)
            
            if caption.count > 150 {
                Button(action: { showFullCaption.toggle() }) {
                    Text(showFullCaption ? "Show less" : "Show more")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.modaicsChrome1)
                }
            }
        }
    }
    
    private var lockedContentView: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundColor(.modaicsChrome1.opacity(0.5))
            
            Text("Members-Only Content")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.modaicsCotton)
            
            Text("Join the Sketchbook to view this exclusive post")
                .font(.system(size: 13))
                .foregroundColor(.modaicsCottonLight)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var engagementBar: some View {
        HStack(spacing: 20) {
            // Like button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    if !hasLiked {
                        likeCount += 1
                        hasLiked = true
                    } else {
                        likeCount -= 1
                        hasLiked = false
                    }
                    onLike()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: hasLiked ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(hasLiked ? .pink : .modaicsCottonLight)
                        .scaleEffect(hasLiked ? 1.1 : 1.0)
                    Text("\(likeCount)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.modaicsCottonLight)
                }
            }
            
            // Comment button
            Button(action: onComment) {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.right.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.modaicsChrome1.opacity(0.8))
                    Text("\(post.commentsCount)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.modaicsCottonLight)
                }
            }
            
            // View count
            HStack(spacing: 6) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.modaicsChrome2.opacity(0.8))
                Text("\(post.viewsCount)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsCottonLight)
            }
            
            Spacer()
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear], from: date, to: now)
        
        if let weeks = components.weekOfYear, weeks > 0 {
            return "\(weeks)w ago"
        } else if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        SketchbookPostCardView(post: .sampleUpdate)
        SketchbookPostCardView(post: .samplePoll)
    }
    .padding()
    .background(Color.modaicsDarkBlue)
}
