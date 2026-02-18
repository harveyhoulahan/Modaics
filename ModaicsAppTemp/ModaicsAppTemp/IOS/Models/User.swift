//
//  User.swift
//  Modaics
//
//  User model for Firebase Authentication and Firestore integration
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - User Model
struct User: Identifiable, Codable, Equatable {
    let id: String
    var email: String
    var displayName: String?
    var username: String?
    var bio: String?
    var location: String?
    var profileImageURL: String?
    var userType: UserType
    var sustainabilityPoints: Int
    var ecoPoints: Int
    var wardrobe: [String]
    var preferences: UserPreferences
    var socialLinks: SocialLinks
    var isEmailVerified: Bool
    var createdAt: Date
    var lastLoginAt: Date
    var fcmToken: String? // For push notifications
    
    // Additional profile properties
    var membershipTier: MembershipTier
    var isVerified: Bool
    var following: [String]
    var followers: [String]
    var likedItems: [String]
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        email: String,
        displayName: String? = nil,
        username: String? = nil,
        bio: String? = nil,
        location: String? = nil,
        profileImageURL: String? = nil,
        userType: UserType = .consumer,
        sustainabilityPoints: Int = 0,
        ecoPoints: Int = 0,
        wardrobe: [String] = [],
        preferences: UserPreferences = UserPreferences(),
        socialLinks: SocialLinks = SocialLinks(),
        isEmailVerified: Bool = false,
        createdAt: Date = Date(),
        lastLoginAt: Date = Date(),
        fcmToken: String? = nil,
        membershipTier: MembershipTier = .basic,
        isVerified: Bool = false,
        following: [String] = [],
        followers: [String] = [],
        likedItems: [String] = []
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.username = username
        self.bio = bio
        self.location = location
        self.profileImageURL = profileImageURL
        self.userType = userType
        self.sustainabilityPoints = sustainabilityPoints
        self.ecoPoints = ecoPoints
        self.wardrobe = wardrobe
        self.preferences = preferences
        self.socialLinks = socialLinks
        self.isEmailVerified = isEmailVerified
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.fcmToken = fcmToken
        self.membershipTier = membershipTier
        self.isVerified = isVerified
        self.following = following
        self.followers = followers
        self.likedItems = likedItems
    }
    
    // Initialize from Firebase Auth user
    init(from firebaseUser: FirebaseAuth.User, userType: UserType = .consumer) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.displayName = firebaseUser.displayName
        self.username = nil
        self.bio = nil
        self.location = nil
        self.profileImageURL = firebaseUser.photoURL?.absoluteString
        self.userType = userType
        self.sustainabilityPoints = 0
        self.ecoPoints = 0
        self.wardrobe = []
        self.preferences = UserPreferences()
        self.socialLinks = SocialLinks()
        self.isEmailVerified = firebaseUser.isEmailVerified
        self.createdAt = Date()
        self.lastLoginAt = Date()
        self.fcmToken = nil
        self.membershipTier = .basic
        self.isVerified = false
        self.following = []
        self.followers = []
        self.likedItems = []
    }
}

// MARK: - User Type
enum UserType: String, Codable, CaseIterable {
    case consumer = "consumer"
    case brand = "brand"
    case admin = "admin"
    
    var displayName: String {
        switch self {
        case .consumer:
            return "User"
        case .brand:
            return "Brand"
        case .admin:
            return "Admin"
        }
    }
    
    var icon: String {
        switch self {
        case .consumer:
            return "person.fill"
        case .brand:
            return "building.2.fill"
        case .admin:
            return "shield.fill"
        }
    }
}

// MARK: - Membership Tier
enum MembershipTier: String, Codable {
    case basic = "Basic"
    case premium = "Premium"
}

// MARK: - User Preferences
struct UserPreferences: Codable, Equatable {
    var notificationsEnabled: Bool
    var emailNotificationsEnabled: Bool
    var darkModeEnabled: Bool
    var language: String
    var currency: String
    var sizeUnit: SizeUnit
    var preferredCategories: [String]
    var sustainabilityFilterEnabled: Bool
    
    init(
        notificationsEnabled: Bool = true,
        emailNotificationsEnabled: Bool = true,
        darkModeEnabled: Bool = true,
        language: String = "en",
        currency: String = "USD",
        sizeUnit: SizeUnit = .us,
        preferredCategories: [String] = [],
        sustainabilityFilterEnabled: Bool = false
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.emailNotificationsEnabled = emailNotificationsEnabled
        self.darkModeEnabled = darkModeEnabled
        self.language = language
        self.currency = currency
        self.sizeUnit = sizeUnit
        self.preferredCategories = preferredCategories
        self.sustainabilityFilterEnabled = sustainabilityFilterEnabled
    }
}

// MARK: - Size Unit
enum SizeUnit: String, Codable, CaseIterable {
    case us = "US"
    case uk = "UK"
    case eu = "EU"
    case jp = "JP"
}

// MARK: - Social Links
struct SocialLinks: Codable, Equatable {
    var instagram: String?
    var twitter: String?
    var facebook: String?
    var website: String?
    
    init(
        instagram: String? = nil,
        twitter: String? = nil,
        facebook: String? = nil,
        website: String? = nil
    ) {
        self.instagram = instagram
        self.twitter = twitter
        self.facebook = facebook
        self.website = website
    }
}

// MARK: - Firestore Conversion
extension User {
    var toFirestore: [String: Any] {
        return [
            "id": id,
            "email": email,
            "displayName": displayName as Any,
            "username": username as Any,
            "bio": bio as Any,
            "location": location as Any,
            "profileImageURL": profileImageURL as Any,
            "userType": userType.rawValue,
            "sustainabilityPoints": sustainabilityPoints,
            "ecoPoints": ecoPoints,
            "wardrobe": wardrobe,
            "preferences": preferences.toFirestore,
            "socialLinks": socialLinks.toFirestore,
            "isEmailVerified": isEmailVerified,
            "createdAt": Timestamp(date: createdAt),
            "lastLoginAt": Timestamp(date: lastLoginAt),
            "fcmToken": fcmToken as Any,
            "membershipTier": membershipTier.rawValue,
            "isVerified": isVerified,
            "following": following,
            "followers": followers,
            "likedItems": likedItems
        ]
    }
    
    static func fromFirestore(_ data: [String: Any], id: String) -> User? {
        guard let email = data["email"] as? String else { return nil }
        
        let userTypeString = data["userType"] as? String ?? "consumer"
        let userType = UserType(rawValue: userTypeString) ?? .consumer
        
        let membershipString = data["membershipTier"] as? String ?? "basic"
        let membershipTier = MembershipTier(rawValue: membershipString) ?? .basic
        
        let preferencesData = data["preferences"] as? [String: Any] ?? [:]
        let socialLinksData = data["socialLinks"] as? [String: Any] ?? [:]
        
        return User(
            id: id,
            email: email,
            displayName: data["displayName"] as? String,
            username: data["username"] as? String,
            bio: data["bio"] as? String,
            location: data["location"] as? String,
            profileImageURL: data["profileImageURL"] as? String,
            userType: userType,
            sustainabilityPoints: data["sustainabilityPoints"] as? Int ?? 0,
            ecoPoints: data["ecoPoints"] as? Int ?? 0,
            wardrobe: data["wardrobe"] as? [String] ?? [],
            preferences: UserPreferences.fromFirestore(preferencesData),
            socialLinks: SocialLinks.fromFirestore(socialLinksData),
            isEmailVerified: data["isEmailVerified"] as? Bool ?? false,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            lastLoginAt: (data["lastLoginAt"] as? Timestamp)?.dateValue() ?? Date(),
            fcmToken: data["fcmToken"] as? String,
            membershipTier: membershipTier,
            isVerified: data["isVerified"] as? Bool ?? false,
            following: data["following"] as? [String] ?? [],
            followers: data["followers"] as? [String] ?? [],
            likedItems: data["likedItems"] as? [String] ?? []
        )
    }
}

// MARK: - Preferences Firestore Conversion
extension UserPreferences {
    var toFirestore: [String: Any] {
        return [
            "notificationsEnabled": notificationsEnabled,
            "emailNotificationsEnabled": emailNotificationsEnabled,
            "darkModeEnabled": darkModeEnabled,
            "language": language,
            "currency": currency,
            "sizeUnit": sizeUnit.rawValue,
            "preferredCategories": preferredCategories,
            "sustainabilityFilterEnabled": sustainabilityFilterEnabled
        ]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> UserPreferences {
        let sizeUnitString = data["sizeUnit"] as? String ?? "US"
        return UserPreferences(
            notificationsEnabled: data["notificationsEnabled"] as? Bool ?? true,
            emailNotificationsEnabled: data["emailNotificationsEnabled"] as? Bool ?? true,
            darkModeEnabled: data["darkModeEnabled"] as? Bool ?? true,
            language: data["language"] as? String ?? "en",
            currency: data["currency"] as? String ?? "USD",
            sizeUnit: SizeUnit(rawValue: sizeUnitString) ?? .us,
            preferredCategories: data["preferredCategories"] as? [String] ?? [],
            sustainabilityFilterEnabled: data["sustainabilityFilterEnabled"] as? Bool ?? false
        )
    }
}

// MARK: - Social Links Firestore Conversion
extension SocialLinks {
    var toFirestore: [String: Any] {
        return [
            "instagram": instagram as Any,
            "twitter": twitter as Any,
            "facebook": facebook as Any,
            "website": website as Any
        ]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> SocialLinks {
        return SocialLinks(
            instagram: data["instagram"] as? String,
            twitter: data["twitter"] as? String,
            facebook: data["facebook"] as? String,
            website: data["website"] as? String
        )
    }
}

// MARK: - Sample Data for Testing
extension User {
    static var sampleUser: User {
        User(
            id: "sample-user-id",
            email: "demo@modaics.com",
            displayName: "Demo User",
            username: "demouser",
            bio: "Sustainable fashion enthusiast and vintage collector",
            location: "Melbourne, Australia",
            userType: .consumer,
            sustainabilityPoints: 1250,
            ecoPoints: 500,
            wardrobe: [],
            preferences: UserPreferences(
                notificationsEnabled: true,
                emailNotificationsEnabled: true,
                darkModeEnabled: true,
                currency: "AUD",
                preferredCategories: ["Vintage", "Streetwear"]
            ),
            membershipTier: .basic
        )
    }
    
    static var sampleBrand: User {
        User(
            id: "sample-brand-id",
            email: "brand@example.com",
            displayName: "Eco Brand",
            username: "ecobrand",
            bio: "Sustainable fashion brand focused on ethical production",
            location: "Sydney, Australia",
            userType: .brand,
            sustainabilityPoints: 5000,
            ecoPoints: 1000,
            socialLinks: SocialLinks(
                instagram: "@ecobrand",
                website: "https://ecobrand.com"
            ),
            membershipTier: .premium,
            isVerified: true
        )
    }
}
