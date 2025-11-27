//
//  CommunityData.swift
//  Modaics
//
//  Mock community events, workshops, swap meets, and posts
//  Created to bring the app to LYYYFEE
//

import Foundation
import SwiftUI

// MARK: - Event Types

enum EventType: String, Codable, CaseIterable {
    case workshop = "Workshop"
    case popUp = "Pop-Up"
    case swapMeet = "Swap Meet"
    case classSession = "Class"
    case market = "Market"
    case exhibition = "Exhibition"
    case talk = "Talk"
    case party = "Party"
    
    var icon: String {
        switch self {
        case .workshop: return "hammer.fill"
        case .popUp: return "sparkles"
        case .swapMeet: return "arrow.triangle.swap"
        case .classSession: return "book.fill"
        case .market: return "cart.fill"
        case .exhibition: return "photo.fill"
        case .talk: return "mic.fill"
        case .party: return "party.popper.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .workshop: return .orange
        case .popUp: return .purple
        case .swapMeet: return .green
        case .classSession: return .blue
        case .market: return .pink
        case .exhibition: return .cyan
        case .talk: return .yellow
        case .party: return .red
        }
    }
}

struct CommunityEvent: Identifiable, Codable {
    let id: UUID
    let title: String
    let type: EventType
    let host: String
    let location: String
    let date: Date
    let attendees: Int
    let maxAttendees: Int
    let price: Double
    let description: String
    let imageURL: String?
    let tags: [String]
    
    init(id: UUID = UUID(),
         title: String,
         type: EventType,
         host: String,
         location: String,
         date: Date,
         attendees: Int,
         maxAttendees: Int,
         price: Double = 0,
         description: String,
         imageURL: String? = nil,
         tags: [String] = []) {
        self.id = id
        self.title = title
        self.type = type
        self.host = host
        self.location = location
        self.date = date
        self.attendees = attendees
        self.maxAttendees = maxAttendees
        self.price = price
        self.description = description
        self.imageURL = imageURL
        self.tags = tags
    }
    
    var isAlmostFull: Bool {
        Double(attendees) / Double(maxAttendees) > 0.8
    }
    
    var isFree: Bool {
        price == 0
    }
}

// MARK: - Mock Events Data

extension CommunityEvent {
    static let mockEvents: [CommunityEvent] = [
        // SWAP MEETS
        CommunityEvent(
            title: "Fitzroy Vintage Swap",
            type: .swapMeet,
            host: "@vintage_vibes_melb",
            location: "Fitzroy Community Hall, Melbourne",
            date: Date().addingTimeInterval(3 * 24 * 3600), // 3 days from now
            attendees: 47,
            maxAttendees: 60,
            price: 0,
            description: "Bring 5 items, take home 5 new-to-you pieces! Focus on 90s/00s streetwear this month. Refreshments provided.",
            tags: ["swap", "vintage", "streetwear", "fitzroy"]
        ),
        
        CommunityEvent(
            title: "Luxury Handbag Exchange",
            type: .swapMeet,
            host: "@preloved_luxury",
            location: "Prahran Town Hall",
            date: Date().addingTimeInterval(5 * 24 * 3600),
            attendees: 28,
            maxAttendees: 30,
            price: 15,
            description: "Curated swap for designer bags only. Authentication on-site. Brands: YSL, Prada, Gucci, LV, Celine.",
            tags: ["luxury", "handbags", "designer", "curated"]
        ),
        
        CommunityEvent(
            title: "Northcote Denim Swap & Repair",
            type: .swapMeet,
            host: "@denim_doctors",
            location: "Northcote Social Club",
            date: Date().addingTimeInterval(7 * 24 * 3600),
            attendees: 34,
            maxAttendees: 50,
            price: 5,
            description: "Swap jeans + free hemming service! Bring your old Levi's, Wrangler, Lee and trade for something fresh.",
            tags: ["denim", "repair", "northcote", "free-alterations"]
        ),
        
        // WORKSHOPS
        CommunityEvent(
            title: "Sashiko Visible Mending",
            type: .workshop,
            host: "@mend_with_meaning",
            location: "Brunswick Made, 97 Weston St",
            date: Date().addingTimeInterval(4 * 24 * 3600),
            attendees: 12,
            maxAttendees: 15,
            price: 65,
            description: "Learn Japanese repair art. All materials included - bring a garment to mend! Tea + snacks provided.",
            tags: ["sashiko", "repair", "japanese", "handcraft"]
        ),
        
        CommunityEvent(
            title: "Screen Printing 101",
            type: .workshop,
            host: "@print_collective",
            location: "Collingwood Yards Studio 7",
            date: Date().addingTimeInterval(6 * 24 * 3600),
            attendees: 18,
            maxAttendees: 20,
            price: 85,
            description: "Design and print your own tees! Learn screen prep, ink mixing, and print techniques. Take home 3 custom pieces.",
            tags: ["screenprinting", "DIY", "collingwood", "artisan"]
        ),
        
        CommunityEvent(
            title: "Denim Distressing Masterclass",
            type: .workshop,
            host: "@destroy_rebuild",
            location: "Footscray Community Arts Centre",
            date: Date().addingTimeInterval(8 * 24 * 3600),
            attendees: 9,
            maxAttendees: 12,
            price: 55,
            description: "Rips, frays, bleach splatter - create that perfect worn-in look. Bring 2 pairs of jeans (we provide practice denim too).",
            tags: ["denim", "distressing", "vintage-effect", "hands-on"]
        ),
        
        CommunityEvent(
            title: "Natural Dye Workshop",
            type: .workshop,
            host: "@earth_tones_studio",
            location: "Abbotsford Convent, Studio 12",
            date: Date().addingTimeInterval(10 * 24 * 3600),
            attendees: 14,
            maxAttendees: 16,
            price: 75,
            description: "Plant-based dyes from scratch! Learn indigo, turmeric, and avocado pit dyeing. Bring white cotton items.",
            tags: ["natural-dye", "eco-friendly", "botanical", "zero-waste"]
        ),
        
        CommunityEvent(
            title: "Embroidery for Fashion",
            type: .workshop,
            host: "@stitch_society",
            location: "Carlton Library Meeting Room",
            date: Date().addingTimeInterval(12 * 24 * 3600),
            attendees: 11,
            maxAttendees: 15,
            price: 50,
            description: "Hand embroidery techniques to customize your wardrobe. Chain stitch, satin stitch, French knots. Materials included.",
            tags: ["embroidery", "handcraft", "customization", "beginner-friendly"]
        ),
        
        // POP-UPS
        CommunityEvent(
            title: "Archive Rick Owens Pop-Up",
            type: .popUp,
            host: "@grail_archive",
            location: "Chapel St, Prahran (exact address on RSVP)",
            date: Date().addingTimeInterval(2 * 24 * 3600),
            attendees: 89,
            maxAttendees: 100,
            price: 0,
            description: "Rare RO pieces from 2008-2015. DRKSHDW, mainline, leather. Cash/card accepted. First come, first served.",
            tags: ["rick-owens", "archive", "grailed", "luxury"]
        ),
        
        CommunityEvent(
            title: "Local Designers Market",
            type: .popUp,
            host: "@melb_makers_collective",
            location: "NGV Forecourt",
            date: Date().addingTimeInterval(9 * 24 * 3600),
            attendees: 156,
            maxAttendees: 200,
            price: 0,
            description: "20+ Melbourne designers selling sustainable pieces. Upcycled, handmade, zero-waste. Live DJ, coffee cart.",
            tags: ["local-designers", "sustainable", "handmade", "market"]
        ),
        
        CommunityEvent(
            title: "Vintage Patagonia Warehouse Sale",
            type: .popUp,
            host: "@patagonia_preloved",
            location: "Cremorne Warehouse, 45 Citizens Rd",
            date: Date().addingTimeInterval(11 * 24 * 3600),
            attendees: 234,
            maxAttendees: 300,
            price: 0,
            description: "Fleeces, jackets, vests from 80s-00s. $30-$150. All authenticated and cleaned. BYO bag for 10% discount.",
            tags: ["patagonia", "vintage", "outdoor", "warehouse-sale"]
        ),
        
        // CLASSES (Multi-session)
        CommunityEvent(
            title: "Sewing Fundamentals (4-Week Course)",
            type: .classSession,
            host: "@stitch_school_melb",
            location: "Richmond Library, Sewing Lab",
            date: Date().addingTimeInterval(14 * 24 * 3600),
            attendees: 8,
            maxAttendees: 10,
            price: 280,
            description: "Beginner sewing course. Week 1: Machine basics. Week 2: Seams & hems. Week 3: Simple garment. Week 4: Alterations. Machines provided.",
            tags: ["sewing", "beginner", "4-week", "fundamentals"]
        ),
        
        CommunityEvent(
            title: "Pattern Making for Beginners",
            type: .classSession,
            host: "@pattern_lab",
            location: "Collingwood Design Studio",
            date: Date().addingTimeInterval(21 * 24 * 3600),
            attendees: 6,
            maxAttendees: 8,
            price: 350,
            description: "6-week intensive. Learn to draft patterns from measurements. Create custom pieces. Industry pro instructor.",
            tags: ["pattern-making", "advanced", "custom-fit", "6-week"]
        ),
        
        CommunityEvent(
            title: "Sustainable Fashion Business 101",
            type: .classSession,
            host: "@eco_fashion_school",
            location: "RMIT Building 94, Room 203",
            date: Date().addingTimeInterval(15 * 24 * 3600),
            attendees: 22,
            maxAttendees: 25,
            price: 120,
            description: "3-week course for aspiring sustainable fashion entrepreneurs. Supply chains, marketing, ethics, scaling.",
            tags: ["business", "sustainable", "entrepreneurship", "RMIT"]
        ),
        
        // MARKETS
        CommunityEvent(
            title: "South Melbourne Vintage Market",
            type: .market,
            host: "@south_melb_markets",
            location: "South Melbourne Market, Outdoor Area",
            date: Date().addingTimeInterval(1 * 24 * 3600),
            attendees: 412,
            maxAttendees: 500,
            price: 0,
            description: "Monthly vintage & secondhand market. 50+ stalls. Clothing, accessories, homewares. Cash preferred.",
            tags: ["vintage", "secondhand", "south-melbourne", "monthly"]
        ),
        
        CommunityEvent(
            title: "Camberwell Sunday Market",
            type: .market,
            host: "@camberwell_market",
            location: "Camberwell Fresh Food Market Car Park",
            date: Date().addingTimeInterval(13 * 24 * 3600),
            attendees: 1250,
            maxAttendees: 2000,
            price: 0,
            description: "Iconic Melb market! Vintage clothes, records, books, antiques. Cash only. Come early for best finds (6AM start).",
            tags: ["camberwell", "vintage", "iconic", "sunday"]
        ),
        
        // EXHIBITIONS
        CommunityEvent(
            title: "Fast Fashion vs. Slow Fashion",
            type: .exhibition,
            host: "@sustainability_institute",
            location: "Melbourne Museum, Special Exhibits",
            date: Date().addingTimeInterval(20 * 24 * 3600),
            attendees: 89,
            maxAttendees: 150,
            price: 12,
            description: "Visual comparison of production methods, environmental impact, worker conditions. Runs for 3 months.",
            tags: ["exhibition", "education", "sustainability", "museum"]
        ),
        
        CommunityEvent(
            title: "Queer Fashion Through The Decades",
            type: .exhibition,
            host: "@pride_collective_melb",
            location: "Gasworks Arts Park",
            date: Date().addingTimeInterval(25 * 24 * 3600),
            attendees: 156,
            maxAttendees: 200,
            price: 0,
            description: "Celebrating LGBTQIA+ fashion history from 1920s-now. Archival pieces, photography, oral histories. Opening night drinks.",
            tags: ["queer", "pride", "history", "exhibition"]
        ),
        
        // TALKS/PANELS
        CommunityEvent(
            title: "Circular Fashion Economy Panel",
            type: .talk,
            host: "@fashion_revolution_aus",
            location: "State Library Victoria, Theatrette",
            date: Date().addingTimeInterval(18 * 24 * 3600),
            attendees: 67,
            maxAttendees: 80,
            price: 0,
            description: "Industry leaders discuss rental, resale, repair. Q&A with founders from The Volte, AirRobe, Clothing Loop.",
            tags: ["panel", "circular-economy", "industry", "innovation"]
        ),
        
        CommunityEvent(
            title: "From Thrift Flip to Fashion Brand",
            type: .talk,
            host: "@upcycle_academy",
            location: "The Commons, Collingwood",
            date: Date().addingTimeInterval(16 * 24 * 3600),
            attendees: 34,
            maxAttendees: 40,
            price: 15,
            description: "Meet 3 founders who started on Depop and now run sustainable brands. Learn their journey, tips, mistakes.",
            tags: ["talk", "depop", "entrepreneurship", "upcycling"]
        ),
        
        // PARTIES/SOCIALS
        CommunityEvent(
            title: "Sustainable Fashion Week Closing Party",
            type: .party,
            host: "@melb_fashion_week",
            location: "Substation, Newport",
            date: Date().addingTimeInterval(28 * 24 * 3600),
            attendees: 189,
            maxAttendees: 250,
            price: 25,
            description: "Dress code: Thrifted glam. DJ sets, sustainable fashion show, vintage clothing auction. Bar + food trucks.",
            tags: ["party", "fashion-week", "fundraiser", "glam"]
        ),
        
        CommunityEvent(
            title: "Repair Café Social",
            type: .party,
            host: "@fix_it_society",
            location: "Brunswick Mechanics Institute",
            date: Date().addingTimeInterval(19 * 24 * 3600),
            attendees: 45,
            maxAttendees: 60,
            price: 0,
            description: "Casual hang while we mend clothes together. BYO items to fix, we provide tools + snacks. All skill levels welcome!",
            tags: ["repair-cafe", "community", "social", "BYO"]
        ),
        
        // MORE WORKSHOPS (getting wild with it)
        CommunityEvent(
            title: "Bleach Tie-Dye Frenzy",
            type: .workshop,
            host: "@chaos_craft_co",
            location: "Footscray Arts Centre",
            date: Date().addingTimeInterval(17 * 24 * 3600),
            attendees: 16,
            maxAttendees: 20,
            price: 45,
            description: "Reverse tie-dye with bleach! Bring black/dark garments and we'll create wild patterns. Protective gear provided.",
            tags: ["bleach", "tie-dye", "DIY", "experimental"]
        ),
        
        CommunityEvent(
            title: "Leather Working Basics",
            type: .workshop,
            host: "@leather_craft_melb",
            location: "Kensington Studio Space",
            date: Date().addingTimeInterval(22 * 24 * 3600),
            attendees: 7,
            maxAttendees: 10,
            price: 120,
            description: "Make a custom leather patch for your denim jacket! Learn stamping, dyeing, and stitching techniques.",
            tags: ["leather", "crafting", "custom", "patches"]
        ),
        
        CommunityEvent(
            title: "Thrift Styling Session",
            type: .workshop,
            host: "@style_swap_queen",
            location: "Savers Footscray (meeting at entrance)",
            date: Date().addingTimeInterval(5 * 24 * 3600),
            attendees: 14,
            maxAttendees: 15,
            price: 30,
            description: "Personal stylist takes you thrift shopping! Learn to spot quality, style outside your comfort zone. 2hr session.",
            tags: ["styling", "thrifting", "personal-shopping", "confidence"]
        ),
        
        CommunityEvent(
            title: "Crochet Your Own Cardigan",
            type: .workshop,
            host: "@yarn_together",
            location: "Northcote Town Hall Arts Centre",
            date: Date().addingTimeInterval(24 * 24 * 3600),
            attendees: 9,
            maxAttendees: 12,
            price: 90,
            description: "4-week course. Make a chunky cardigan from scratch! Beginners welcome - we teach everything. Yarn included.",
            tags: ["crochet", "knitwear", "handmade", "cozy"]
        ),
        
        CommunityEvent(
            title: "Sneaker Customization Lab",
            type: .workshop,
            host: "@custom_kicks_melb",
            location: "Collingwood Warehouse Studio",
            date: Date().addingTimeInterval(13 * 24 * 3600),
            attendees: 11,
            maxAttendees: 12,
            price: 95,
            description: "Paint, distress, and customize your sneakers. Bring white/beige kicks. All paints, brushes, finishes provided.",
            tags: ["sneakers", "customization", "streetwear", "art"]
        ),
        
        // BONUS NICHE EVENTS
        CommunityEvent(
            title: "Visible Mending Circle",
            type: .workshop,
            host: "@mending_community",
            location: "Fitzroy Library, Community Room",
            date: Date().addingTimeInterval(6 * 24 * 3600),
            attendees: 8,
            maxAttendees: 15,
            price: 0,
            description: "Free weekly gathering. Bring clothes to mend, share techniques, hang out. All ages, all skills. Tea provided.",
            tags: ["mending", "community", "free", "weekly"]
        ),
        
        CommunityEvent(
            title: "Fashion Photography Workshop",
            type: .workshop,
            host: "@shoot_style_repeat",
            location: "Hosier Lane (street shoot)",
            date: Date().addingTimeInterval(11 * 24 * 3600),
            attendees: 13,
            maxAttendees: 15,
            price: 70,
            description: "Learn fashion photography + styling for resale platforms. Take better Depop/Grailed photos! DSLR not required.",
            tags: ["photography", "styling", "resale", "depop"]
        ),
        
        CommunityEvent(
            title: "Zine Making: Fashion Activism",
            type: .workshop,
            host: "@punk_press_melb",
            location: "Brunswick Bound, Print Studio",
            date: Date().addingTimeInterval(26 * 24 * 3600),
            attendees: 10,
            maxAttendees: 12,
            price: 40,
            description: "Create a mini zine about fashion activism, sustainability, or personal style. Collage, writing, illustration.",
            tags: ["zine", "activism", "art", "publishing"]
        ),
        
        CommunityEvent(
            title: "Wardrobe Detox Party",
            type: .party,
            host: "@minimal_wardrobe_club",
            location: "The Commons South Yarra",
            date: Date().addingTimeInterval(9 * 24 * 3600),
            attendees: 23,
            maxAttendees: 30,
            price: 10,
            description: "Bring clothes you don't wear + swap with others! Stylist on hand for advice. Donate leftovers to charity.",
            tags: ["declutter", "swap", "minimalism", "styling"]
        )
    ]
}

// MARK: - Community Posts (Feed Content)

extension CommunityPost {
    static let vibrantFeed: [CommunityPost] = [
        CommunityPost(
            user: "@thrift_queen_melb",
            content: "Found this vintage Patagonia fleece for $15 at Savers. Sometimes you just get lucky. Who else is hitting the thrifts this weekend?",
            imageURLs: ["patagonia_fleece"],
            likes: 142
        ),
        
        CommunityPost(
            user: "@upcycle_wizard",
            content: "Turned old jeans into a tote bag. Tutorial on my profile if anyone wants to try it. Zero waste fashion at its finest.",
            imageURLs: ["denim_tote_1", "denim_tote_2"],
            likes: 267
        ),
        
        CommunityPost(
            user: "@sustainable_sam",
            content: "Reminder: buying less but better quality is more sustainable than constantly buying 'eco-friendly' fast fashion.",
            likes: 489
        ),
        
        CommunityPost(
            user: "@vintage_archive_melb",
            content: "1997 Supreme box logo tee just dropped in our Fitzroy store. DM for details. First come first served.",
            imageURLs: ["supreme_box_logo"],
            likes: 356
        ),
        
        CommunityPost(
            user: "@denim_doctor",
            content: "Before and after of today's repair job. Blowout in the crotch area, happens to all of us. Darned it back to life with reinforcement patches. These jeans have at least another 5 years.",
            imageURLs: ["denim_before", "denim_after"],
            likes: 178
        ),
        
        CommunityPost(
            user: "@style_swap_queen",
            content: "Hot take: You don't need a new wardrobe, you need new styling ideas. Try shopping your own closet differently.",
            likes: 523
        ),
        
        CommunityPost(
            user: "@melb_vintage_king",
            content: "Just picked up this insane Rick Owens DRKSHDW jacket from Grailed. Seller was in Brunswick. Always check local pickups to save on shipping.",
            imageURLs: ["rick_owens_jacket"],
            likes: 891
        ),
        
        CommunityPost(
            user: "@eco_conscious_fits",
            content: "Fit check: Thrifted blazer ($12), vintage Levi's ($35), secondhand Docs ($80). Total outfit cost: $127. Looking fly and sustainable 😎",
            imageURLs: ["full_outfit_mirror"],
            likes: 634
        ),
        
        CommunityPost(
            user: "@repair_cafe_melb",
            content: "Next Repair Café is this Saturday! Bring your broken zippers, lost buttons, ripped seams. We'll help you fix them for free. See you there 🧵",
            likes: 198
        ),
        
        CommunityPost(
            user: "@local_designer_jess",
            content: "New drop tomorrow at 12pm! All pieces made from deadstock fabrics I sourced from Melbourne textile studios. DM for preview 👀",
            imageURLs: ["collection_preview"],
            likes: 412
        ),
        
        CommunityPost(
            user: "@fashion_activist",
            content: "Did you know the average Australian throws away 23kg of clothes per year? Let's break that cycle. Buy less, choose well, make it last.",
            likes: 756
        ),
        
        CommunityPost(
            user: "@sneakerhead_melb",
            content: "Cleaned and restored these beat up AF1s. Cost of supplies: $15. Cost of new AF1s: $180. You do the math 🧮",
            imageURLs: ["af1_restoration"],
            likes: 445
        ),
        
        CommunityPost(
            user: "@sashiko_studio",
            content: "Another visible mending project done! Client's favorite jeans had a huge rip. Now they're a unique piece of wearable art 🎨",
            imageURLs: ["sashiko_repair_1", "sashiko_repair_2"],
            likes: 523
        ),
        
        CommunityPost(
            user: "@depop_seller_tips",
            content: "Depop tip: Natural light + plain background = more sales. Stop using that messy bedroom mirror pic 😅 #DepopTips",
            likes: 289
        ),
        
        CommunityPost(
            user: "@wardrobe_minimalist",
            content: "Been wearing the same 30-piece capsule wardrobe for 6 months. Best decision ever. Less stress, more style, way less shopping.",
            likes: 678
        ),
        
        CommunityPost(
            user: "@textile_nerd",
            content: "Just learned that organic cotton uses 91% less water than conventional cotton 💧 The more you know!",
            likes: 234
        ),
        
        CommunityPost(
            user: "@grailed_grails",
            content: "Finally copped the Margiela GATs I've been hunting for 2 years. Patience pays off in the secondhand game 🙏",
            imageURLs: ["margiela_gats"],
            likes: 567
        ),
        
        CommunityPost(
            user: "@diy_fashion_lab",
            content: "Turned a men's XL shirt into a cute cropped top! Tutorial coming soon. Who says you need to know how to sew? ✂️",
            imageURLs: ["shirt_transform"],
            likes: 892
        ),
        
        CommunityPost(
            user: "@sustainable_fits",
            content: "Wearing my mom's vintage Levi's jacket from the 80s today. Sustainable fashion is also about keeping family pieces alive 💙",
            imageURLs: ["mom_levis_jacket"],
            likes: 1243
        ),
        
        CommunityPost(
            user: "@fashion_revolution",
            content: "Who made my clothes? This Fashion Revolution Week, ask brands for transparency. Our clothes shouldn't come at the cost of people or planet. #WhoMadeMyClothes",
            likes: 934
        ),
        
        CommunityPost(
            user: "@embroidery_enthusiast",
            content: "Added custom embroidery to this plain hoodie I thrifted. Now it's one of a kind! 🌸",
            imageURLs: ["embroidered_hoodie"],
            likes: 445
        ),
        
        CommunityPost(
            user: "@vintage_shopping_guide",
            content: "Best thrift stores in Melbourne thread 🧵 Drop your favorites below! I'll start: Savers Footscray and Brotherhood of St Laurence Brunswick",
            likes: 567
        ),
        
        CommunityPost(
            user: "@climate_closet",
            content: "Friendly reminder that the most sustainable piece of clothing is the one already in your closet 🌍",
            likes: 823
        ),
        
        CommunityPost(
            user: "@sneaker_restoration_melb",
            content: "Someone threw these Jordan 1s in the trash!! Found them on hard rubbish day. A good clean and they're fire again 🔥",
            imageURLs: ["jordan_rescue"],
            likes: 1456
        ),
        
        CommunityPost(
            user: "@slow_fashion_advocate",
            content: "Cost per wear is the real metric. That $200 jacket you'll wear 100 times? $2 per wear. That $20 top you'll wear twice? $10 per wear. Think about it.",
            likes: 678
        ),
        
        CommunityPost(
            user: "@tailoring_queen",
            content: "Hemmed these pants, took in the waist, and tapered the legs. $30 thrift + $40 alterations = perfect fit designer-quality pants. This is the way.",
            imageURLs: ["tailored_pants"],
            likes: 389
        ),
        
        CommunityPost(
            user: "@circular_fashion_aus",
            content: "Rental, resale, repair, remake. These are the 4 R's we should be talking about instead of fast fashion's endless new drops.",
            likes: 512
        ),
        
        CommunityPost(
            user: "@bleach_dye_projects",
            content: "Reverse tie-dyed this black hoodie and I'm obsessed!! Tutorial in bio. You need: bleach, rubber bands, and bravery 😂",
            imageURLs: ["bleach_dye_hoodie"],
            likes: 734
        ),
        
        CommunityPost(
            user: "@community_swap_melb",
            content: "Our biggest swap meet yet this Saturday! 60 people confirmed. If you signed up, remember: bring 5, take 5. Let's keep it fair for everyone 💚",
            likes: 156
        ),
        
        CommunityPost(
            user: "@archive_fashion_melb",
            content: "2000s Raf Simons just landed. Size M. DM for price. Serious inquiries only please.",
            imageURLs: ["raf_simons_piece"],
            likes: 923
        )
    ]
}
