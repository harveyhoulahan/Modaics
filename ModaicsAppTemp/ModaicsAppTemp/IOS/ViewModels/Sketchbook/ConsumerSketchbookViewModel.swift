//
//  ConsumerSketchbookViewModel.swift
//  ModaicsAppTemp
//
//  Consumer-specific view model with membership handling
//

import Foundation
import SwiftUI

@MainActor
class ConsumerSketchbookViewModel: SketchbookViewModel {
    @Published var spendEligibility: SpendEligibility?
    @Published var showUnlockSheet = false
    
    // MARK: - Membership Access
    
    func checkSpendEligibility() async {
        guard let sketchbookId = sketchbook?.id else { return }
        
        do {
            spendEligibility = try await service.checkSpendEligibility(
                sketchbookId: sketchbookId,
                userId: currentUserId
            )
        } catch {
            // Eligibility check failed, not critical
            spendEligibility = nil
        }
    }
    
    func unlockFromSpend() async -> Bool {
        guard let eligibility = spendEligibility,
              eligibility.eligible else {
            return false
        }
        
        await requestMembership()
        return hasMembership
    }
    
    // MARK: - Filtered Content
    
    var visiblePosts: [SketchbookPost] {
        if canViewMembersOnlyContent {
            return posts
        } else {
            return posts.filter { $0.isPublic }
        }
    }
    
    var lockedPostsCount: Int {
        posts.count - visiblePosts.count
    }
    
    var hasLockedContent: Bool {
        lockedPostsCount > 0
    }
    
    // MARK: - Unlock CTA
    
    var unlockCallToAction: String {
        guard let sketchbook = sketchbook else {
            return "Unlock Sketchbook"
        }
        
        switch sketchbook.membershipRule {
        case .free:
            return "Join for Free"
        case .inviteOnly:
            return "Request Invite"
        case .minSpend:
            if let eligibility = spendEligibility {
                if eligibility.eligible {
                    return "Unlock Now"
                } else {
                    let remaining = eligibility.remainingAmount
                    return "Spend $\(Int(remaining)) to Unlock"
                }
            }
            return sketchbook.membershipRequirementText
        }
    }
    
    var unlockDescription: String {
        guard let sketchbook = sketchbook else {
            return "Get access to members-only content"
        }
        
        switch sketchbook.membershipRule {
        case .free:
            return "Get instant access to all \(lockedPostsCount) exclusive posts"
        case .inviteOnly:
            return "Request access from the brand to unlock \(lockedPostsCount) exclusive posts"
        case .minSpend:
            if let eligibility = spendEligibility {
                if eligibility.eligible {
                    return "You've unlocked access! Tap to activate."
                } else {
                    let progress = Int(eligibility.progressPercentage)
                    return "You're \(progress)% of the way to unlocking \(lockedPostsCount) exclusive posts"
                }
            }
            return "Unlock \(lockedPostsCount) exclusive posts by supporting the brand"
        }
    }
}
