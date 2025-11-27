//
//  BrandSketchbookViewModel.swift
//  ModaicsAppTemp
//
//  Brand-specific view model with post creation/management
//

import Foundation
import SwiftUI

@MainActor
class BrandSketchbookViewModel: SketchbookViewModel {
    @Published var isCreatingPost = false
    @Published var showSettings = false
    
    // MARK: - Post Management
    
    func createPost(
        type: SketchbookPostType,
        title: String,
        body: String?,
        media: [MediaAttachment] = [],
        tags: [String] = [],
        visibility: SketchbookVisibility = .public,
        pollQuestion: String? = nil,
        pollOptions: [PollOption]? = nil,
        pollClosesAt: Date? = nil
    ) async -> Bool {
        guard let sketchbookId = sketchbook?.id else { return false }
        
        isCreatingPost = true
        errorMessage = nil
        
        do {
            let newPost = try await service.createPost(
                sketchbookId: sketchbookId,
                authorUserId: currentUserId,
                postType: type,
                title: title,
                body: body,
                media: media,
                tags: tags,
                visibility: visibility,
                pollQuestion: pollQuestion,
                pollOptions: pollOptions,
                pollClosesAt: pollClosesAt
            )
            
            // Add to local posts at the top
            posts.insert(newPost, at: 0)
            
            // Update sketchbook posts count
            if var updatedSketchbook = sketchbook {
                updatedSketchbook.postsCount += 1
                sketchbook = updatedSketchbook
            }
            
            isCreatingPost = false
            return true
        } catch {
            errorMessage = "Failed to create post: \(error.localizedDescription)"
            isCreatingPost = false
            return false
        }
    }
    
    func deletePost(_ post: SketchbookPost) async -> Bool {
        do {
            try await service.deletePost(postId: post.id, userId: currentUserId)
            
            // Remove from local posts
            posts.removeAll { $0.id == post.id }
            
            // Update sketchbook posts count
            if var updatedSketchbook = sketchbook {
                updatedSketchbook.postsCount = max(0, updatedSketchbook.postsCount - 1)
                sketchbook = updatedSketchbook
            }
            
            return true
        } catch {
            errorMessage = "Failed to delete post"
            return false
        }
    }
    
    // MARK: - Settings Management
    
    func updateSettings(
        title: String? = nil,
        description: String? = nil,
        accessPolicy: SketchbookAccessPolicy? = nil,
        membershipRule: SketchbookMembershipRule? = nil,
        minSpendAmount: Double? = nil,
        minSpendWindowMonths: Int? = nil
    ) async -> Bool {
        guard let sketchbookId = sketchbook?.id else { return false }
        
        do {
            let updatedSketchbook = try await service.updateSketchbookSettings(
                sketchbookId: sketchbookId,
                title: title,
                description: description,
                accessPolicy: accessPolicy,
                membershipRule: membershipRule,
                minSpendAmount: minSpendAmount,
                minSpendWindowMonths: minSpendWindowMonths
            )
            
            sketchbook = updatedSketchbook
            return true
        } catch {
            errorMessage = "Failed to update settings: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Analytics (Stub for future)
    
    var totalViews: Int {
        posts.reduce(0) { $0 + $1.viewsCount }
    }
    
    var totalReactions: Int {
        posts.reduce(0) { $0 + $1.reactionsCount }
    }
    
    var totalComments: Int {
        posts.reduce(0) { $0 + $1.commentsCount }
    }
    
    var engagementRate: Double {
        guard !posts.isEmpty, totalViews > 0 else { return 0 }
        let totalEngagements = totalReactions + totalComments
        return (Double(totalEngagements) / Double(totalViews)) * 100
    }
    
    var topPost: SketchbookPost? {
        posts.max { post1, post2 in
            let engagement1 = post1.reactionsCount + post1.commentsCount
            let engagement2 = post2.reactionsCount + post2.commentsCount
            return engagement1 < engagement2
        }
    }
}
