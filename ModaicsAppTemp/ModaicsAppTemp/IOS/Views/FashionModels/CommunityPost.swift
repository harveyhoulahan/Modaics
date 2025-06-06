//
//  CommunityPost.swift
//  ModaicsAppTemp
//
//  Created by Harvey Houlahan on 6/6/2025.
//


//
//  CommunityPost.swift
//  Modaics
//
//  A single, canonical representation of a user-generated community post.
//

import Foundation

struct CommunityPost: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    var user: String          // <-- keep naming consistent with UI (“user”)
    var content: String
    var imageURLs: [String]
    var createdAt: Date
    var likes: Int
    
    init(id: UUID = UUID(),
         user: String,
         content: String,
         imageURLs: [String] = [],
         createdAt: Date = Date(),
         likes: Int = 0) {
        self.id        = id
        self.user      = user
        self.content   = content
        self.imageURLs = imageURLs
        self.createdAt = createdAt
        self.likes     = likes
    }
    
    /// Handy seed data for previews / feed generation
    static let sample = CommunityPost(
        user: "modaics",
        content: "Welcome to our sustainable community!",
        imageURLs: [],
        likes: 0
    )
    
    static let demoFeed: [CommunityPost] = [
        .sample,
        CommunityPost(user: "eco_fashionista",
                      content: "Thrift-flip of an old shirt into a cute crop ✂️👚",
                      imageURLs: ["thrift_1"],
                      likes: 18),
        CommunityPost(user: "upcycle_lover",
                      content: "Tips for repairing denim ➰",
                      imageURLs: ["denim_1","denim_2"],
                      likes: 42)
    ]
}
