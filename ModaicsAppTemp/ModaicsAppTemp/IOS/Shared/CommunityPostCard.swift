//
//  CommunityPostCard.swift
//  ModaicsAppTemp
//
//  Industrial-themed community post card
//  Created by Harvey Houlahan on 11/27/2025.
//

import SwiftUI

struct CommunityPostCard: View {
    let post: CommunityPost
    @State private var isLiked = false
    @State private var likeCount: Int
    
    init(post: CommunityPost) {
        self.post = post
        self._likeCount = State(initialValue: post.likes)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User header
            HStack {
                Rectangle()
                    .fill(Color.appRed)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(post.user.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(post.user)")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.appTextMain)
                    
                    Text("2H AGO")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .tracking(0.5)
                        .foregroundColor(.appTextMuted)
                }
                
                Spacer()
                
                Button {
                    HapticManager.shared.impact(.light)
                } label: {
                    Text("FOLLOW")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(1)
                        .foregroundColor(.appRed)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Rectangle()
                                .stroke(Color.appRed, lineWidth: 1)
                        )
                }
            }
            
            // Content
            Text(post.content)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.appTextMain)
                .lineSpacing(4)
            
            // Actions
            HStack(spacing: 20) {
                Button {
                    HapticManager.shared.impact(.light)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isLiked.toggle()
                        likeCount += isLiked ? 1 : -1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isLiked ? .appRed : .appTextMuted)
                            .scaleEffect(isLiked ? 1.1 : 1.0)
                        
                        Text("\(likeCount)")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.appTextMuted)
                    }
                }
                
                Button {
                    HapticManager.shared.impact(.light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appTextMuted)
                        
                        Text("5")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.appTextMuted)
                    }
                }
                
                Spacer()
                
                Button {
                    HapticManager.shared.impact(.light)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appTextMuted)
                }
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .overlay(
            Rectangle()
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}
