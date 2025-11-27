//
//  CommunityFeedView.swift
//  Modaics
//
//  The heart of the community - events, workshops, and user posts
//

import SwiftUI

struct CommunityFeedView: View {
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var selectedTab: FeedTab = .forYou
    @State private var showEventDetail: CommunityEvent?
    @State private var searchText = ""
    
    enum FeedTab: String, CaseIterable {
        case forYou = "For You"
        case sketchbook = "Sketchbook"
        case events = "Events"
        case workshops = "Workshops"
        case swaps = "Swaps"
        
        var icon: String {
            switch self {
            case .forYou: return "sparkles"
            case .sketchbook: return "pencil.and.scribble"
            case .events: return "calendar"
            case .workshops: return "hammer.fill"
            case .swaps: return "arrow.triangle.swap"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [.modaicsDarkBlue, .modaicsMidBlue],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    header
                    
                    // Tab Selector
                    tabSelector
                    
                    // Content
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            switch selectedTab {
                            case .forYou:
                                forYouContent
                            case .sketchbook:
                                sketchbookContent
                            case .events:
                                eventsContent
                            case .workshops:
                                workshopsContent
                            case .swaps:
                                swapsContent
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 100) // Extra padding for tab bar
                    }
                }
            }
            .sheet(item: $showEventDetail) { event in
                EventDetailSheet(event: event)
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Community")
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCotton)
                    
                    Text("Melbourne's sustainable fashion hub")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCottonLight)
                }
                
                Spacer()
                
                Button {
                    // TODO: Navigate to connections
                } label: {
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundColor(.modaicsChrome1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.modaicsCottonLight)
                
                TextField("Search events, workshops...", text: $searchText)
                    .foregroundColor(.modaicsCotton)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.modaicsCottonLight)
                    }
                }
            }
            .padding(12)
            .background(
                Rectangle()
                    .fill(Color.modaicsDarkBlue.opacity(0.6))
                    .overlay(
                        Rectangle()
                            .stroke(Color.modaicsChrome1.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 12)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FeedTab.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.rawValue,
                        icon: tab.icon,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Content Sections
    
    private var forYouContent: some View {
        VStack(spacing: 20) {
            // Weekly Style Challenge
            styleChallengeSection
            
            // Friend Activity Feed
            friendActivitySection
            
            // Local Hub
            localHubSection
            
            // Upcoming Events Banner
            upcomingEventsBanner
            
            // Community Posts
            ForEach(CommunityPost.vibrantFeed) { post in
                CommunityFeedPostCard(post: post)
            }
        }
    }
    
    // MARK: - Style Challenge Section
    private var styleChallengeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("This Week's Challenge")
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCotton)
                }
                
                Spacer()
                
                Text("3 days left")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.modaicsChrome1.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(Color.modaicsChrome1.opacity(0.15), lineWidth: 1)
                            )
                    )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Zero-Waste Outfit Challenge")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCotton)
                
                Text("Create an outfit using only thrifted, swapped, or upcycled items. Share your look and inspire others!")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCottonLight)
                    .lineLimit(3)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("127 participants")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.modaicsCottonLight)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.fill")
                            .font(.caption)
                        Text("+100 Eco Points")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.green)
                }
                
                Button {
                    // Join challenge action
                    HapticManager.shared.success()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Join Challenge")
                    }
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsDarkBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Rectangle())
                }
            }
        }
        .padding(16)
        .background(
            Rectangle()
                .fill(Color.modaicsDarkBlue.opacity(0.6))
                .overlay(
                    Rectangle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.3), Color.modaicsChrome1.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
    }
    
    // MARK: - Friend Activity Section
    private var friendActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsChrome1)
                    
                    Text("Friend Activity")
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCotton)
                }
                
                Spacer()
                
                Button {
                    // View all
                } label: {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.modaicsChrome1)
                }
            }
            
            VStack(spacing: 10) {
                FriendActivityRow(
                    userName: "Sarah Chen",
                    action: "listed a new item",
                    itemName: "Vintage Levi's Jacket",
                    timeAgo: "2 hours ago",
                    icon: "plus.circle.fill",
                    color: .blue
                )
                
                FriendActivityRow(
                    userName: "Marcus Lee",
                    action: "completed a swap",
                    itemName: "Nike Tech Fleece",
                    timeAgo: "5 hours ago",
                    icon: "arrow.triangle.swap",
                    color: .green
                )
                
                FriendActivityRow(
                    userName: "Emma Wilson",
                    action: "joined event",
                    itemName: "Sydney Swap Meet",
                    timeAgo: "1 day ago",
                    icon: "calendar.badge.checkmark",
                    color: .purple
                )
            }
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
    
    // MARK: - Local Hub Section
    private var localHubSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsChrome1)
                    
                    Text("Sydney Hub")
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCotton)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("1.2k active")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.modaicsCottonLight)
                }
            }
            
            Text("Connect with sustainable fashion enthusiasts in your city. Share tips, organize meetups, and build a greener wardrobe together.")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsCottonLight)
            
            HStack(spacing: 12) {
                LocalHubStat(icon: "calendar", value: "24", label: "Events/mo")
                LocalHubStat(icon: "arrow.triangle.swap", value: "156", label: "Swaps/mo")
                LocalHubStat(icon: "leaf.fill", value: "2.1T", label: "CO₂ saved")
            }
        }
        .padding(16)
        .background(
            Rectangle()
                .fill(Color.modaicsDarkBlue.opacity(0.6))
                .overlay(
                    Rectangle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.modaicsChrome1.opacity(0.3), Color.modaicsChrome1.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private var eventsContent: some View {
        VStack(spacing: 16) {
            ForEach(filteredEvents) { event in
                CommunityEventCard(event: event) {
                    showEventDetail = event
                }
            }
        }
    }
    
    private var workshopsContent: some View {
        VStack(spacing: 16) {
            ForEach(CommunityEvent.mockEvents.filter { $0.type == .workshop }) { event in
                CommunityEventCard(event: event) {
                    showEventDetail = event
                }
            }
        }
    }
    
    private var swapsContent: some View {
        VStack(spacing: 16) {
            ForEach(CommunityEvent.mockEvents.filter { $0.type == .swapMeet }) { event in
                CommunityEventCard(event: event) {
                    showEventDetail = event
                }
            }
        }
    }
    
    private var upcomingEventsBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Happening Soon")
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsCotton)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(upcomingEvents.prefix(5)) { event in
                        CompactEventCard(event: event) {
                            showEventDetail = event
                        }
                    }
                }
            }
        }
    }
    
    private var filteredEvents: [CommunityEvent] {
        let events = CommunityEvent.mockEvents
        if searchText.isEmpty {
            return events.sorted { $0.date < $1.date }
        }
        return events.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }.sorted { $0.date < $1.date }
    }
    
    private var upcomingEvents: [CommunityEvent] {
        CommunityEvent.mockEvents
            .filter { $0.date > Date() }
            .sorted { $0.date < $1.date }
    }
}

// MARK: - Sub Components

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
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

struct CommunityEventCard: View {
    let event: CommunityEvent
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    // Event Type Badge
                    HStack(spacing: 6) {
                        Image(systemName: event.type.icon)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                        Text(event.type.rawValue)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(event.type.color)
                    .clipShape(Rectangle())
                    
                    Spacer()
                    
                    // Price or Free
                    Text(event.isFree ? "FREE" : "$\(Int(event.price))")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(event.isFree ? .green : .modaicsChrome1)
                }
                
                // Title
                Text(event.title)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCotton)
                    .lineLimit(2)
                
                // Host
                Text("by \(event.host)")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsChrome1)
                
                // Details
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(event.date, style: .date)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.modaicsCottonLight)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text(event.location)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .lineLimit(1)
                    }
                    .foregroundColor(.modaicsCottonLight)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(event.attendees)/\(event.maxAttendees) attending")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                        
                        if event.isAlmostFull {
                            Text("• Almost Full!")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                    }
                    .foregroundColor(.modaicsCottonLight)
                }
                
                // Tags
                if !event.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(event.tags.prefix(4), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(.modaicsChrome2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.modaicsDarkBlue.opacity(0.6))
                                    .clipShape(Rectangle())
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.modaicsDarkBlue.opacity(0.6))
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(Color.modaicsChrome1.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CompactEventCard: View {
    let event: CommunityEvent
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: event.type.icon)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(event.type.color)
                    
                    Spacer()
                    
                    Text(event.isFree ? "FREE" : "$\(Int(event.price))")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(event.isFree ? .green : .modaicsChrome1)
                }
                
                Text(event.title)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCotton)
                    .lineLimit(2)
                    .frame(height: 36)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                    Text(event.date, style: .date)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                }
                .foregroundColor(.modaicsCottonLight)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                    Text("\(event.attendees)/\(event.maxAttendees)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                }
                .foregroundColor(.modaicsCottonLight)
            }
            .padding(12)
            .frame(width: 180)
            .background(Color.modaicsDarkBlue.opacity(0.6))
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(Color.modaicsChrome1.opacity(0.15), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CommunityFeedPostCard: View {
    let post: CommunityPost
    @State private var isLiked = false
    @State private var likeCount: Int
    
    init(post: CommunityPost) {
        self.post = post
        _likeCount = State(initialValue: post.likes)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Header
            HStack(spacing: 12) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(post.user.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.modaicsDarkBlue)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.user)
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCotton)
                    
                    Text(timeAgoString(from: post.createdAt))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCottonLight)
                }
                
                Spacer()
            }
            
            // Content
            Text(post.content)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsCotton)
                .fixedSize(horizontal: false, vertical: true)
            
            // Images (if any)
            if !post.imageURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(post.imageURLs, id: \.self) { imageURL in
                            Rectangle()
                                .fill(Color.modaicsDarkBlue.opacity(0.4))
                                .frame(width: 200, height: 200)
                                .overlay(
                                    Text("📷")
                                        .font(.system(size: 48, weight: .medium, design: .monospaced))
                                )
                        }
                    }
                }
            }
            
            // Actions
            HStack(spacing: 24) {
                Button {
                    HapticManager.shared.impact(.light)
                    isLiked.toggle()
                    likeCount += isLiked ? 1 : -1
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .modaicsCottonLight)
                        Text("\(likeCount)")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.modaicsCottonLight)
                    }
                }
                
                Button {
                    HapticManager.shared.impact(.light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                        Text("Reply")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.modaicsCottonLight)
                }
                
                Button {
                    HapticManager.shared.impact(.light)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.modaicsCottonLight)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.modaicsDarkBlue.opacity(0.6))
        .clipShape(Rectangle())
        .overlay(
            Rectangle()
                .stroke(Color.modaicsChrome1.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func timeAgoString(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86400 { return "\(Int(seconds / 3600))h ago" }
        return "\(Int(seconds / 86400))d ago"
    }
}

// MARK: - Event Detail Sheet

struct EventDetailSheet: View {
    let event: CommunityEvent
    @Environment(\.dismiss) var dismiss
    @State private var isRegistered = false
    
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
                    VStack(alignment: .leading, spacing: 20) {
                        // Event Type Badge
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: event.type.icon)
                                Text(event.type.rawValue)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(event.type.color)
                            .clipShape(Rectangle())
                            
                            Spacer()
                        }
                        
                        // Title
                        Text(event.title)
                            .font(.system(size: 28, weight: .medium, design: .monospaced))
                            .foregroundColor(.modaicsCotton)
                        
                        // Host
                        Text("Hosted by \(event.host)")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.modaicsChrome1)
                        
                        Divider()
                            .background(Color.modaicsChrome1.opacity(0.3))
                        
                        // Details Grid
                        VStack(alignment: .leading, spacing: 16) {
                            DetailRow(icon: "calendar", title: "Date", value: event.date.formatted(date: .long, time: .shortened))
                            DetailRow(icon: "mappin.circle.fill", title: "Location", value: event.location)
                            DetailRow(icon: "person.2.fill", title: "Attendees", value: "\(event.attendees)/\(event.maxAttendees)")
                            DetailRow(icon: "dollarsign.circle.fill", title: "Price", value: event.isFree ? "FREE" : "$\(Int(event.price))")
                        }
                        
                        Divider()
                            .background(Color.modaicsChrome1.opacity(0.3))
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                .foregroundColor(.modaicsCotton)
                            
                            Text(event.description)
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(.modaicsCottonLight)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Tags
                        if !event.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Tags")
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                                    .foregroundColor(.modaicsCotton)
                                
                                FlowLayout(spacing: 8) {
                                    ForEach(event.tags, id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                                            .foregroundColor(.modaicsChrome2)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.modaicsDarkBlue.opacity(0.6))
                                            .clipShape(Rectangle())
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
                
                // Bottom Action Button
                VStack {
                    Spacer()
                    
                    ModaicsPrimaryButton(
                        isRegistered ? "Registered ✓" : "Register",
                        icon: isRegistered ? "checkmark.circle.fill" : "calendar.badge.plus"
                    ) {
                        HapticManager.shared.success()
                        isRegistered = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .background(
                        LinearGradient(
                            colors: [.modaicsMidBlue.opacity(0), .modaicsMidBlue],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.modaicsChrome1)
                    }
                }
            }
        }
    }
}

fileprivate struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsChrome1)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCottonLight)
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.modaicsCotton)
            }
        }
    }
}

// Simple FlowLayout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let totalHeight = rows.reduce(0) { total, row in
            let rowHeight = row.map { $0.sizeThatFits(proposal).height }.max() ?? 0
            return total + rowHeight + spacing
        }
        return CGSize(width: proposal.width ?? 0, height: max(0, totalHeight - spacing))
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(proposal).height }.max() ?? 0
            
            for subview in row {
                subview.place(at: CGPoint(x: x, y: y), proposal: proposal)
                x += subview.sizeThatFits(proposal).width + spacing
            }
            y += rowHeight + spacing
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[Subviews.Element]] {
        var rows: [[Subviews.Element]] = [[]]
        var currentRowWidth: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(proposal)
            if currentRowWidth + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([subview])
                currentRowWidth = size.width
            } else {
                rows[rows.count - 1].append(subview)
                currentRowWidth += size.width + spacing
            }
        }
        return rows
    }
}

// MARK: - Friend Activity Row
struct FriendActivityRow: View {
    let userName: String
    let action: String
    let itemName: String
    let timeAgo: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(userName)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCotton)
                    
                    Text(action)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.modaicsCottonLight)
                }
                
                Text(itemName)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsChrome1)
                
                Text(timeAgo)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCottonLight.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.modaicsCottonLight.opacity(0.5))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Sketchbook Content
extension CommunityFeedView {
    private var sketchbookContent: some View {
        CommunitySketchbookFeedView()
    }
}

// MARK: - Local Hub Stat
struct LocalHubStat: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsChrome1)
            
            Text(value)
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsCotton)
            
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.modaicsCottonLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color.modaicsSurface2)
        )
    }
}

#Preview {
    CommunityFeedView()
        .environmentObject(FashionViewModel())
}
