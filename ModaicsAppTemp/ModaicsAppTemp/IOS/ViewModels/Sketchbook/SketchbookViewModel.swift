//
//  SketchbookViewModel.swift
//  ModaicsAppTemp
//
//  Base view model for Sketchbook
//

import Foundation
import SwiftUI

@MainActor
class SketchbookViewModel: ObservableObject {
    @Published var sketchbook: Sketchbook?
    @Published var posts: [SketchbookPost] = []
    @Published var membership: SketchbookMembership?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let service: SketchbookService
    let currentUserId: String
    
    init(userId: String, service: SketchbookService = .shared) {
        self.currentUserId = userId
        self.service = service
    }
    
    // MARK: - Load Data
    
    func loadSketchbook(brandId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            sketchbook = try await service.getSketchbook(forBrand: brandId)
            if let sketchbookId = sketchbook?.id {
                await loadPosts(sketchbookId: sketchbookId)
                await checkMembership(sketchbookId: sketchbookId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadPosts(sketchbookId: Int) async {
        do {
            posts = try await service.getPosts(
                forSketchbook: sketchbookId,
                userId: currentUserId
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func checkMembership(sketchbookId: Int) async {
        do {
            membership = try await service.checkMembership(
                sketchbookId: sketchbookId,
                userId: currentUserId
            )
        } catch {
            // Membership might not exist, which is fine
            membership = nil
        }
    }
    
    func refresh() async {
        guard let brandId = sketchbook?.brandId else { return }
        await loadSketchbook(brandId: brandId)
    }
    
    // MARK: - Membership
    
    var hasMembership: Bool {
        membership?.isActive ?? false
    }
    
    var canViewMembersOnlyContent: Bool {
        sketchbook?.isPublic ?? false || hasMembership
    }
    
    func requestMembership() async {
        guard let sketchbookId = sketchbook?.id else { return }
        
        do {
            membership = try await service.requestMembership(
                sketchbookId: sketchbookId,
                userId: currentUserId
            )
            
            // Reload posts to show members-only content
            await loadPosts(sketchbookId: sketchbookId)
        } catch {
            errorMessage = "Failed to join: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Reactions
    
    func toggleReaction(for post: SketchbookPost) async {
        do {
            // For simplicity, just toggle like
            try await service.addReaction(
                postId: post.id,
                userId: currentUserId,
                reactionType: .like
            )
            
            // Update local post
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index].reactionsCount += 1
            }
        } catch {
            errorMessage = "Failed to react"
        }
    }
    
    // MARK: - Polls
    
    func voteInPoll(post: SketchbookPost, optionId: String) async {
        do {
            let results = try await service.voteInPoll(
                postId: post.id,
                userId: currentUserId,
                optionId: optionId
            )
            
            // Update local post with new results
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index].pollOptions = results.options
            }
        } catch {
            errorMessage = "Failed to vote"
        }
    }
}
