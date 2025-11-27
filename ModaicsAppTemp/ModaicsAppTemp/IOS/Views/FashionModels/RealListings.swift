//
//  RealListings.swift
//  Modaics
//
//  MASSIVE collection of realistic fashion listings to bring the app to LIFE!
//  Created by Harvey Houlahan on 27/11/2025
//

import Foundation

extension FashionItem {
    /// 100+ REAL looking listings across all categories
    static var realListings: [FashionItem] {
        var items: [FashionItem] = []
        
        // MARK: - Streetwear & Supreme
        items.append(FashionItem(
            name: "Supreme Box Logo Hoodie FW18",
            brand: "Supreme",
            category: .outerwear,
            size: "L",
            condition: .excellent,
            originalPrice: 650.00,
            listingPrice: 520.00,
            description: "Ash Grey box logo from Fall/Winter 2018. Barely worn, no cracking on logo. Purchased from Supreme NYC.",
            imageURLs: ["supreme_bogo_grey"],
            sustainabilityScore: SustainabilityScore(totalScore: 75, carbonFootprint: 4.5, waterUsage: 3200, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Grey", "Red"],
            styleTags: ["Streetwear", "Hype", "Box Logo"],
            location: "Melbourne CBD",
            ownerId: "user_supreme_collector"
        ))
        
        items.append(FashionItem(
            name: "Palace Tri-Ferg Hoodie",
            brand: "Palace",
            category: .outerwear,
            size: "M",
            condition: .likeNew,
            originalPrice: 180.00,
            listingPrice: 145.00,
            description: "Black tri-ferg hoodie, worn 3x. Still has tags. Cozy and clean.",
            imageURLs: ["palace_triferg"],
            sustainabilityScore: SustainabilityScore(totalScore: 70, carbonFootprint: 4.0, waterUsage: 2800, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black", "White"],
            styleTags: ["Streetwear", "Skatewear"],
            location: "Fitzroy",
            ownerId: "user_skater_kid"
        ))
        
        items.append(FashionItem(
            name: "Stussy 8-Ball Hoodie Vintage",
            brand: "Stüssy",
            category: .outerwear,
            size: "L",
            condition: .good,
            originalPrice: 150.00,
            listingPrice: 85.00,
            description: "Vintage Stussy from early 2000s. Some fading adds to the character. Authentic grail.",
            imageURLs: ["stussy_8ball"],
            sustainabilityScore: SustainabilityScore(totalScore: 82, carbonFootprint: 3.0, waterUsage: 2000, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black", "Yellow"],
            styleTags: ["Vintage", "Y2K", "Streetwear"],
            location: "Brunswick",
            ownerId: "user_vintage_dealer"
        ))
        
        // MARK: - Nike & Sportswear
        items.append(FashionItem(
            name: "Nike Air Max 97 Silver Bullet",
            brand: "Nike",
            category: .shoes,
            size: "US 10",
            condition: .excellent,
            originalPrice: 280.00,
            listingPrice: 195.00,
            description: "Classic Silver Bullet colorway. Worn 5x, still fresh. Box included.",
            imageURLs: ["airmax97_silver"],
            sustainabilityScore: SustainabilityScore(totalScore: 65, carbonFootprint: 5.5, waterUsage: 1200, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Silver", "Red"],
            styleTags: ["Sneakers", "Retro", "Running"],
            location: "Collingwood",
            ownerId: "user_sneakerhead"
        ))
        
        items.append(FashionItem(
            name: "Nike Tech Fleece Joggers",
            brand: "Nike",
            category: .bottoms,
            size: "M",
            condition: .likeNew,
            originalPrice: 140.00,
            listingPrice: 95.00,
            description: "Black tech fleece joggers. Super comfy, barely worn. No pilling.",
            imageURLs: ["nike_techfleece"],
            sustainabilityScore: SustainabilityScore(totalScore: 60, carbonFootprint: 3.8, waterUsage: 2200, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black"],
            styleTags: ["Athleisure", "Comfort", "Minimal"],
            location: "South Yarra",
            ownerId: "user_gymrat"
        ))
        
        items.append(FashionItem(
            name: "Vintage Nike Windrunner Jacket 90s",
            brand: "Nike",
            category: .outerwear,
            size: "L",
            condition: .good,
            originalPrice: 200.00,
            listingPrice: 75.00,
            description: "Vintage 90s windrunner in teal/grey. Some wear but that's the vibe. Rare colorway.",
            imageURLs: ["nike_windrunner_90s"],
            sustainabilityScore: SustainabilityScore(totalScore: 88, carbonFootprint: 2.5, waterUsage: 1500, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Teal", "Grey", "White"],
            styleTags: ["Vintage", "90s", "Sportswear"],
            location: "Northcote",
            ownerId: "user_90s_archive"
        ))
        
        // MARK: - Luxury & Designer
        items.append(FashionItem(
            name: "Prada Nylon Re-Edition 2005",
            brand: "Prada",
            category: .bags,
            size: "One Size",
            condition: .excellent,
            originalPrice: 1100.00,
            listingPrice: 850.00,
            description: "Black nylon shoulder bag with iconic triangle logo. Barely used, comes with authenticity card.",
            imageURLs: ["prada_reedition"],
            sustainabilityScore: SustainabilityScore(totalScore: 70, carbonFootprint: 6.0, waterUsage: 800, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black"],
            styleTags: ["Luxury", "Designer", "It-Bag"],
            location: "Prahran",
            ownerId: "user_luxury_reseller"
        ))
        
        items.append(FashionItem(
            name: "Rick Owens DRKSHDW Ramones Low",
            brand: "Rick Owens",
            category: .shoes,
            size: "EU 43",
            condition: .good,
            originalPrice: 520.00,
            listingPrice: 320.00,
            description: "Black canvas ramones. Worn but still tons of life left. Signature toebox wear.",
            imageURLs: ["rick_ramones"],
            sustainabilityScore: SustainabilityScore(totalScore: 75, carbonFootprint: 5.0, waterUsage: 1800, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black", "White"],
            styleTags: ["Designer", "Avant-Garde", "Grunge"],
            location: "Chapel Street",
            ownerId: "user_rick_head"
        ))
        
        items.append(FashionItem(
            name: "Margiela Replica GATs",
            brand: "Maison Margiela",
            category: .shoes,
            size: "EU 42",
            condition: .excellent,
            originalPrice: 550.00,
            listingPrice: 395.00,
            description: "White/grey replica GATs. Minimal creasing, super clean condition. OG box.",
            imageURLs: ["margiela_gats"],
            sustainabilityScore: SustainabilityScore(totalScore: 68, carbonFootprint: 5.2, waterUsage: 1500, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["White", "Grey"],
            styleTags: ["Designer", "Minimal", "Luxury"],
            location: "Melbourne CBD",
            ownerId: "user_margiela_fan"
        ))
        
        items.append(FashionItem(
            name: "Gucci Ace Bee Sneakers",
            brand: "Gucci",
            category: .shoes,
            size: "EU 41",
            condition: .likeNew,
            originalPrice: 790.00,
            listingPrice: 580.00,
            description: "White leather with signature bee embroidery. Worn 2x. Comes with box and dust bag.",
            imageURLs: ["gucci_ace_bee"],
            sustainabilityScore: SustainabilityScore(totalScore: 62, carbonFootprint: 7.0, waterUsage: 2000, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["White", "Gold"],
            styleTags: ["Luxury", "Designer", "Statement"],
            location: "South Yarra",
            ownerId: "user_designer_kicks"
        ))
        
        // MARK: - Denim
        items.append(FashionItem(
            name: "Vintage Levi's 501 Made in USA",
            brand: "Levi's",
            category: .bottoms,
            size: "W32 L34",
            condition: .excellent,
            originalPrice: 180.00,
            listingPrice: 95.00,
            description: "True vintage 501s from 1990s. Made in USA. Perfect fade, no holes. Iconic fit.",
            imageURLs: ["levis_501_vintage"],
            sustainabilityScore: SustainabilityScore(totalScore: 90, carbonFootprint: 2.0, waterUsage: 1000, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Blue", "Denim"],
            styleTags: ["Vintage", "Denim", "Classic"],
            location: "Fitzroy",
            ownerId: "user_denim_dealer"
        ))
        
        items.append(FashionItem(
            name: "Wrangler Cowboy Cut Jeans",
            brand: "Wrangler",
            category: .bottoms,
            size: "W33 L32",
            condition: .good,
            originalPrice: 120.00,
            listingPrice: 45.00,
            description: "Authentic cowboy cuts. Great for a western vibe. Some distressing on knees.",
            imageURLs: ["wrangler_cowboy"],
            sustainabilityScore: SustainabilityScore(totalScore: 85, carbonFootprint: 2.2, waterUsage: 1200, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Blue"],
            styleTags: ["Western", "Workwear", "Vintage"],
            location: "Footscray",
            ownerId: "user_cowboy"
        ))
        
        items.append(FashionItem(
            name: "Carhartt Double Knee Pants",
            brand: "Carhartt",
            category: .bottoms,
            size: "32x32",
            condition: .likeNew,
            originalPrice: 110.00,
            listingPrice: 75.00,
            description: "Hamilton Brown duck canvas. Reinforced knees, barely broken in.",
            imageURLs: ["carhartt_doublekn knee"],
            sustainabilityScore: SustainabilityScore(totalScore: 80, carbonFootprint: 3.0, waterUsage: 1800, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Brown", "Tan"],
            styleTags: ["Workwear", "Durable", "Skate"],
            location: "Collingwood",
            ownerId: "user_workwear_king"
        ))
        
        // MARK: - Vintage Tees & Band Tees
        items.append(FashionItem(
            name: "Vintage Metallica '91 Tour Tee",
            brand: "Vintage",
            category: .tops,
            size: "L",
            condition: .good,
            originalPrice: 250.00,
            listingPrice: 180.00,
            description: "Original 1991 Black Album tour tee. Single stitch, thin fabric. Grail for collectors.",
            imageURLs: ["metallica_91"],
            sustainabilityScore: SustainabilityScore(totalScore: 95, carbonFootprint: 1.5, waterUsage: 800, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black"],
            styleTags: ["Vintage", "Band-Tee", "Rock"],
            location: "Brunswick",
            ownerId: "user_vintage_tees"
        ))
        
        items.append(FashionItem(
            name: "Harley Davidson Vintage Logo Tee",
            brand: "Harley Davidson",
            category: .tops,
            size: "XL",
            condition: .good,
            originalPrice: 180.00,
            listingPrice: 65.00,
            description: "Faded black Harley tee from 90s. Perfect oversized fit.",
            imageURLs: ["harley_vintage"],
            sustainabilityScore: SustainabilityScore(totalScore: 88, carbonFootprint: 1.8, waterUsage: 900, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black", "Orange"],
            styleTags: ["Vintage", "Motorcycles", "Americana"],
            location: "Northcote",
            ownerId: "user_biker"
        ))
        
        items.append(FashionItem(
            name: "Nirvana In Utero Tee",
            brand: "Band Merch",
            category: .tops,
            size: "M",
            condition: .excellent,
            originalPrice: 160.00,
            listingPrice: 120.00,
            description: "Rare In Utero angel graphics. From 2000s reprint but hard to find. Great condition.",
            imageURLs: ["nirvana_inutero"],
            sustainabilityScore: SustainabilityScore(totalScore: 82, carbonFootprint: 2.0, waterUsage: 1000, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black"],
            styleTags: ["Grunge", "Band-Tee", "90s"],
            location: "Fitzroy",
            ownerId: "user_grunge_kid"
        ))
        
        // MARK: - Patagonia & Outdoor
        items.append(FashionItem(
            name: "Patagonia Synchilla Fleece Vintage",
            brand: "Patagonia",
            category: .outerwear,
            size: "L",
            condition: .excellent,
            originalPrice: 180.00,
            listingPrice: 120.00,
            description: "Purple/teal synchilla from 90s. Super cozy and warm. Vintage grail.",
            imageURLs: ["patagonia_synchilla"],
            sustainabilityScore: SustainabilityScore(totalScore: 92, carbonFootprint: 2.8, waterUsage: 1500, isRecycled: true, isCertified: true, certifications: ["Fair Trade", "Recycled Materials"], fibreTraceVerified: true),
            colorTags: ["Purple", "Teal"],
            styleTags: ["Vintage", "Fleece", "Outdoor"],
            location: "Kew",
            ownerId: "user_patagonia_archive"
        ))
        
        items.append(FashionItem(
            name: "The North Face Nuptse 700",
            brand: "The North Face",
            category: .outerwear,
            size: "M",
            condition: .likeNew,
            originalPrice: 450.00,
            listingPrice: 320.00,
            description: "Black puffer jacket. 700-fill down. Barely worn, still puffy. OG tags.",
            imageURLs: ["tnf_nuptse"],
            sustainabilityScore: SustainabilityScore(totalScore: 75, carbonFootprint: 5.0, waterUsage: 2000, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black"],
            styleTags: ["Outdoor", "Puffer", "Winter"],
            location: "Richmond",
            ownerId: "user_tnf_collector"
        ))
        
        items.append(FashionItem(
            name: "Arc'teryx Beta LT Shell Jacket",
            brand: "Arc'teryx",
            category: .outerwear,
            size: "M",
            condition: .excellent,
            originalPrice: 650.00,
            listingPrice: 480.00,
            description: "Navy GORE-TEX shell. Perfect for hiking or street. Lifetime warranty.",
            imageURLs: ["arcteryx_beta"],
            sustainabilityScore: SustainabilityScore(totalScore: 85, carbonFootprint: 4.5, waterUsage: 2200, isRecycled: false, isCertified: true, certifications: ["GORE-TEX", "Bluesign"], fibreTraceVerified: false),
            colorTags: ["Navy"],
            styleTags: ["Technical", "Outdoor", "Techwear"],
            location: "Carlton",
            ownerId: "user_hiker"
        ))
        
        // MARK: - Thrifted Gems
        items.append(FashionItem(
            name: "Vintage Tommy Hilfiger Polo",
            brand: "Tommy Hilfiger",
            category: .tops,
            size: "L",
            condition: .good,
            originalPrice: 90.00,
            listingPrice: 35.00,
            description: "Classic yellow polo with big logo. 90s vibes. Minor fading.",
            imageURLs: ["tommy_polo"],
            sustainabilityScore: SustainabilityScore(totalScore: 87, carbonFootprint: 1.8, waterUsage: 1100, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Yellow", "Navy"],
            styleTags: ["Preppy", "90s", "Vintage"],
            location: "Brunswick",
            ownerId: "user_thrifter"
        ))
        
        items.append(FashionItem(
            name: "Gap Heavyweight Hoodie",
            brand: "Gap",
            category: .outerwear,
            size: "XL",
            condition: .excellent,
            originalPrice: 80.00,
            listingPrice: 40.00,
            description: "Grey heavyweight hoodie. Perfect oversized fit. Thick and warm.",
            imageURLs: ["gap_hoodie"],
            sustainabilityScore: SustainabilityScore(totalScore: 78, carbonFootprint: 3.2, waterUsage: 2000, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Grey"],
            styleTags: ["Basics", "Comfort", "Oversized"],
            location: "Footscray",
            ownerId: "user_basics_lover"
        ))
        
        items.append(FashionItem(
            name: "Vintage Dickies Work Shirt",
            brand: "Dickies",
            category: .tops,
            size: "L",
            condition: .good,
            originalPrice: 70.00,
            listingPrice: 30.00,
            description: "Tan dickies shirt with patch pockets. Perfect for layering or solo.",
            imageURLs: ["dickies_workshirt"],
            sustainabilityScore: SustainabilityScore(totalScore: 85, carbonFootprint: 2.5, waterUsage: 1300, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Tan", "Khaki"],
            styleTags: ["Workwear", "Vintage", "Minimal"],
            location: "Collingwood",
            ownerId: "user_workwear"
        ))
        
        // MARK: - More Sneakers
        items.append(FashionItem(
            name: "New Balance 550 White Green",
            brand: "New Balance",
            category: .shoes,
            size: "US 11",
            condition: .likeNew,
            originalPrice: 180.00,
            listingPrice: 140.00,
            description: "White/green colorway. Worn 3x. Still super clean.",
            imageURLs: ["nb550_green"],
            sustainabilityScore: SustainabilityScore(totalScore: 68, carbonFootprint: 4.8, waterUsage: 1400, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["White", "Green"],
            styleTags: ["Retro", "Basketball", "Sneakers"],
            location: "South Yarra",
            ownerId: "user_nb_head"
        ))
        
        items.append(FashionItem(
            name: "Vans Old Skool Black/White",
            brand: "Vans",
            category: .shoes,
            size: "US 9",
            condition: .good,
            originalPrice: 90.00,
            listingPrice: 45.00,
            description: "Classic black and white old skools. Some wear but tons of life left.",
            imageURLs: ["vans_oldskool"],
            sustainabilityScore: SustainabilityScore(totalScore: 75, carbonFootprint: 3.5, waterUsage: 1100, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black", "White"],
            styleTags: ["Skate", "Classic", "Everyday"],
            location: "St Kilda",
            ownerId: "user_skater"
        ))
        
        items.append(FashionItem(
            name: "Adidas Samba OG Black",
            brand: "Adidas",
            category: .shoes,
            size: "UK 10",
            condition: .excellent,
            originalPrice: 130.00,
            listingPrice: 90.00,
            description: "Black leather sambas. Minimal creasing. Super versatile.",
            imageURLs: ["adidas_samba"],
            sustainabilityScore: SustainabilityScore(totalScore: 70, carbonFootprint: 4.2, waterUsage: 1300, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black", "White"],
            styleTags: ["Football", "Retro", "Casual"],
            location: "Fitzroy",
            ownerId: "user_3stripes"
        ))
        
        // Add 50 MORE varied items to really fill it out...
        
        items.append(FashionItem(
            name: "Uniqlo U Wide Fit Jeans",
            brand: "Uniqlo",
            category: .bottoms,
            size: "32",
            condition: .likeNew,
            originalPrice: 80.00,
            listingPrice: 45.00,
            description: "Black wide fit jeans. Barely worn. Great quality for the price.",
            sustainabilityScore: SustainabilityScore(totalScore: 65, carbonFootprint: 3.5, waterUsage: 2500, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black"],
            styleTags: ["Wide-Leg", "Minimal", "Basics"],
            location: "Melbourne CBD",
            ownerId: "user_minimal"
        ))
        
        items.append(FashionItem(
            name: "Stone Island Overshirt Garment Dyed",
            brand: "Stone Island",
            category: .outerwear,
            size: "L",
            condition: .excellent,
            originalPrice: 480.00,
            listingPrice: 350.00,
            description: "Olive green garment dyed overshirt. Compass badge intact. Premium piece.",
            sustainabilityScore: SustainabilityScore(totalScore: 72, carbonFootprint: 4.0, waterUsage: 2000, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Olive", "Green"],
            styleTags: ["Designer", "Italian", "Casual"],
            location: "Prahran",
            ownerId: "user_stoney"
        ))
        
        items.append(FashionItem(
            name: "Champion Reverse Weave Hoodie",
            brand: "Champion",
            category: .outerwear,
            size: "L",
            condition: .good,
            originalPrice: 95.00,
            listingPrice: 55.00,
            description: "Navy reverse weave. Some pilling but still cozy. Classic piece.",
            sustainabilityScore: SustainabilityScore(totalScore: 80, carbonFootprint: 3.0, waterUsage: 2200, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Navy"],
            styleTags: ["Sportswear", "Comfort", "Classic"],
            location: "Northcote",
            ownerId: "user_champion_fan"
        ))
        
        // Keep going with MORE items...
        items.append(FashionItem(
            name: "AMI Paris Heart Logo Tee",
            brand: "AMI Paris",
            category: .tops,
            size: "M",
            condition: .likeNew,
            originalPrice: 120.00,
            listingPrice: 80.00,
            description: "White tee with AMI de Coeur logo. Worn once. Fits true to size.",
            sustainabilityScore: SustainabilityScore(totalScore: 68, carbonFootprint: 2.5, waterUsage: 1200, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["White", "Red"],
            styleTags: ["Designer", "French", "Minimal"],
            location: "South Yarra",
            ownerId: "user_ami_lover"
        ))
        
        // MARK: - Y2K & Archive
        items.append(FashionItem(
            name: "Vintage Juicy Couture Velour Tracksuit",
            brand: "Juicy Couture",
            category: .outerwear,
            size: "S",
            condition: .good,
            originalPrice: 280.00,
            listingPrice: 95.00,
            description: "Pink velour zip-up and pants set. Peak Y2K vibes. Some pilling but still soft.",
            sustainabilityScore: SustainabilityScore(totalScore: 88, carbonFootprint: 2.0, waterUsage: 1500, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Pink"],
            styleTags: ["Y2K", "Vintage", "2000s"],
            location: "Prahran",
            ownerId: "user_y2k_queen"
        ))
        
        items.append(FashionItem(
            name: "Ed Hardy Graphic Tee 2007",
            brand: "Ed Hardy",
            category: .tops,
            size: "M",
            condition: .excellent,
            originalPrice: 85.00,
            listingPrice: 35.00,
            description: "Black tee with tiger graphics and rhinestones. So bad it's good. Peak 2000s.",
            sustainabilityScore: SustainabilityScore(totalScore: 82, carbonFootprint: 2.2, waterUsage: 1100, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black", "Multicolor"],
            styleTags: ["Y2K", "Kitsch", "Ironic"],
            location: "Brunswick",
            ownerId: "user_early2000s"
        ))
        
        items.append(FashionItem(
            name: "Von Dutch Trucker Hat",
            brand: "Von Dutch",
            category: .accessories,
            size: "One Size",
            condition: .good,
            originalPrice: 45.00,
            listingPrice: 20.00,
            description: "Pink and white mesh trucker hat. Y2K icon piece.",
            sustainabilityScore: SustainabilityScore(totalScore: 75, carbonFootprint: 1.5, waterUsage: 400, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Pink", "White"],
            styleTags: ["Y2K", "Accessories", "2000s"],
            location: "Fitzroy",
            ownerId: "user_trucker_hats"
        ))
        
        // MARK: - Japanese Brands
        items.append(FashionItem(
            name: "Comme des Garçons PLAY Heart Tee",
            brand: "Comme des Garçons",
            category: .tops,
            size: "M",
            condition: .likeNew,
            originalPrice: 140.00,
            listingPrice: 95.00,
            description: "White tee with iconic heart logo. Made in Japan. Worn 2x.",
            sustainabilityScore: SustainabilityScore(totalScore: 70, carbonFootprint: 3.5, waterUsage: 1300, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["White", "Red"],
            styleTags: ["Designer", "Japanese", "Minimal"],
            location: "Melbourne CBD",
            ownerId: "user_cdg_fan"
        ))
        
        items.append(FashionItem(
            name: "A Bathing Ape Shark Hoodie",
            brand: "BAPE",
            category: .outerwear,
            size: "L",
            condition: .excellent,
            originalPrice: 550.00,
            listingPrice: 380.00,
            description: "Grey camo shark hoodie. Full zip with teeth. Authentic from Japan.",
            sustainabilityScore: SustainabilityScore(totalScore: 65, carbonFootprint: 4.5, waterUsage: 2800, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Grey", "Green"],
            styleTags: ["Streetwear", "Japanese", "Hype"],
            location: "South Yarra",
            ownerId: "user_bape_collector"
        ))
        
        items.append(FashionItem(
            name: "Neighborhood Skull Tee",
            brand: "Neighborhood",
            category: .tops,
            size: "L",
            condition: .good,
            originalPrice: 110.00,
            listingPrice: 60.00,
            description: "Black tee with skull graphics. Japanese streetwear classic.",
            sustainabilityScore: SustainabilityScore(totalScore: 72, carbonFootprint: 2.8, waterUsage: 1200, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black"],
            styleTags: ["Streetwear", "Japanese", "Graphic"],
            location: "Collingwood",
            ownerId: "user_nbhd"
        ))
        
        // MARK: - Skate Brands
        items.append(FashionItem(
            name: "Thrasher Magazine Hoodie",
            brand: "Thrasher",
            category: .outerwear,
            size: "L",
            condition: .likeNew,
            originalPrice: 75.00,
            listingPrice: 50.00,
            description: "Black hoodie with flame logo. Skateboard magazine classic.",
            sustainabilityScore: SustainabilityScore(totalScore: 70, carbonFootprint: 3.2, waterUsage: 2100, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black", "Red"],
            styleTags: ["Skate", "Streetwear", "Classic"],
            location: "St Kilda",
            ownerId: "user_skater_dude"
        ))
        
        items.append(FashionItem(
            name: "Hockey Andrew Allen Deck",
            brand: "Hockey",
            category: .accessories,
            size: "8.25",
            condition: .new,
            originalPrice: 90.00,
            listingPrice: 75.00,
            description: "Unused Andrew Allen pro model. Still has shrink wrap.",
            sustainabilityScore: SustainabilityScore(totalScore: 60, carbonFootprint: 2.5, waterUsage: 500, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Multicolor"],
            styleTags: ["Skate", "Deck", "Collectible"],
            location: "Prahran",
            ownerId: "user_deck_collector"
        ))
        
        // MARK: - Accessories & Bags
        items.append(FashionItem(
            name: "Fjällräven Kånken Backpack",
            brand: "Fjällräven",
            category: .bags,
            size: "16L",
            condition: .excellent,
            originalPrice: 130.00,
            listingPrice: 85.00,
            description: "Yellow classic Kånken. Barely used, just some light marks.",
            sustainabilityScore: SustainabilityScore(totalScore: 80, carbonFootprint: 3.0, waterUsage: 800, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Yellow"],
            styleTags: ["Outdoor", "Scandinavian", "Functional"],
            location: "Carlton",
            ownerId: "user_backpacker"
        ))
        
        items.append(FashionItem(
            name: "Herschel Little America Backpack",
            brand: "Herschel",
            category: .bags,
            size: "25L",
            condition: .good,
            originalPrice: 140.00,
            listingPrice: 65.00,
            description: "Navy backpack with laptop sleeve. Some wear on bottom.",
            sustainabilityScore: SustainabilityScore(totalScore: 70, carbonFootprint: 3.5, waterUsage: 900, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Navy"],
            styleTags: ["Functional", "Casual", "Student"],
            location: "Parkville",
            ownerId: "user_student"
        ))
        
        items.append(FashionItem(
            name: "Ray-Ban Wayfarer Sunglasses",
            brand: "Ray-Ban",
            category: .accessories,
            size: "54mm",
            condition: .excellent,
            originalPrice: 190.00,
            listingPrice: 110.00,
            description: "Classic black wayfarers. Comes with case. Minimal scratches.",
            sustainabilityScore: SustainabilityScore(totalScore: 65, carbonFootprint: 2.0, waterUsage: 200, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black"],
            styleTags: ["Classic", "Accessories", "Timeless"],
            location: "South Yarra",
            ownerId: "user_sunnies"
        ))
        
        // MARK: - Dress Shoes & Boots
        items.append(FashionItem(
            name: "Dr. Martens 1460 Boots",
            brand: "Dr. Martens",
            category: .shoes,
            size: "UK 9",
            condition: .good,
            originalPrice: 220.00,
            listingPrice: 95.00,
            description: "Black smooth leather 8-eye boots. Broken in perfectly. Still have years left.",
            sustainabilityScore: SustainabilityScore(totalScore: 85, carbonFootprint: 4.0, waterUsage: 1500, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black"],
            styleTags: ["Punk", "Classic", "Durable"],
            location: "Fitzroy",
            ownerId: "user_docs_lover"
        ))
        
        items.append(FashionItem(
            name: "Blundstone 500 Chelsea Boots",
            brand: "Blundstone",
            category: .shoes,
            size: "AU 10",
            condition: .excellent,
            originalPrice: 250.00,
            listingPrice: 165.00,
            description: "Brown leather Blunnies. Worn 10x. Still breaking in. Aussie icon.",
            sustainabilityScore: SustainabilityScore(totalScore: 88, carbonFootprint: 3.5, waterUsage: 1200, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Brown"],
            styleTags: ["Australian", "Workwear", "Classic"],
            location: "Richmond",
            ownerId: "user_blunnies"
        ))
        
        items.append(FashionItem(
            name: "Red Wing Iron Ranger Boots",
            brand: "Red Wing",
            category: .shoes,
            size: "US 10.5",
            condition: .good,
            originalPrice: 480.00,
            listingPrice: 280.00,
            description: "Amber harness leather. Well-worn but tons of life. These age beautifully.",
            sustainabilityScore: SustainabilityScore(totalScore: 90, carbonFootprint: 4.2, waterUsage: 1800, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Brown", "Tan"],
            styleTags: ["Heritage", "Workwear", "BIFL"],
            location: "Melbourne CBD",
            ownerId: "user_heritage_boots"
        ))
        
        // MARK: - Formal & Smart Casual
        items.append(FashionItem(
            name: "Uniqlo Supima Cotton Oxford Shirt",
            brand: "Uniqlo",
            category: .tops,
            size: "M",
            condition: .likeNew,
            originalPrice: 50.00,
            listingPrice: 25.00,
            description: "White button-down oxford. Perfect for interviews or dates.",
            sustainabilityScore: SustainabilityScore(totalScore: 68, carbonFootprint: 2.5, waterUsage: 1400, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["White"],
            styleTags: ["Formal", "Minimal", "Basics"],
            location: "Melbourne CBD",
            ownerId: "user_officewear"
        ))
        
        items.append(FashionItem(
            name: "Polo Ralph Lauren Chinos",
            brand: "Polo Ralph Lauren",
            category: .bottoms,
            size: "32x32",
            condition: .excellent,
            originalPrice: 140.00,
            listingPrice: 70.00,
            description: "Khaki chinos. Classic fit. Barely worn, still crisp.",
            sustainabilityScore: SustainabilityScore(totalScore: 72, carbonFootprint: 3.0, waterUsage: 1800, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Khaki", "Tan"],
            styleTags: ["Preppy", "Classic", "Smart-Casual"],
            location: "Toorak",
            ownerId: "user_preppy"
        ))
        
        // MARK: - Women's Pieces
        items.append(FashionItem(
            name: "Reformation Linen Midi Dress",
            brand: "Reformation",
            category: .dresses,
            size: "S",
            condition: .excellent,
            originalPrice: 280.00,
            listingPrice: 160.00,
            description: "Floral linen dress. Perfect for summer. Sustainably made.",
            sustainabilityScore: SustainabilityScore(totalScore: 92, carbonFootprint: 2.8, waterUsage: 1200, isRecycled: false, isCertified: true, certifications: ["Sustainable Fabrics"], fibreTraceVerified: true),
            colorTags: ["Floral", "Green"],
            styleTags: ["Sustainable", "Feminine", "Summer"],
            location: "Prahran",
            ownerId: "user_sustainable_queen"
        ))
        
        items.append(FashionItem(
            name: "Levi's Ribcage Jeans",
            brand: "Levi's",
            category: .bottoms,
            size: "26",
            condition: .likeNew,
            originalPrice: 140.00,
            listingPrice: 85.00,
            description: "Black high-rise jeans. Worn 3x. Fits like a dream.",
            sustainabilityScore: SustainabilityScore(totalScore: 75, carbonFootprint: 3.5, waterUsage: 2200, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black"],
            styleTags: ["Denim", "High-Rise", "Classic"],
            location: "Fitzroy",
            ownerId: "user_denim_girl"
        ))
        
        items.append(FashionItem(
            name: "Zara Faux Leather Blazer",
            brand: "Zara",
            category: .outerwear,
            size: "M",
            condition: .excellent,
            originalPrice: 120.00,
            listingPrice: 55.00,
            description: "Black faux leather blazer. Super versatile, dress up or down.",
            sustainabilityScore: SustainabilityScore(totalScore: 60, carbonFootprint: 4.0, waterUsage: 1500, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black"],
            styleTags: ["Smart-Casual", "Edgy", "Versatile"],
            location: "South Yarra",
            ownerId: "user_zara_addict"
        ))
        
        // MARK: - Athletic & Performance
        items.append(FashionItem(
            name: "Lululemon Align Leggings",
            brand: "Lululemon",
            category: .bottoms,
            size: "4",
            condition: .excellent,
            originalPrice: 128.00,
            listingPrice: 75.00,
            description: "Black 25\" align leggings. No pilling. Buttery soft.",
            sustainabilityScore: SustainabilityScore(totalScore: 65, carbonFootprint: 3.8, waterUsage: 1600, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black"],
            styleTags: ["Athleisure", "Yoga", "Comfort"],
            location: "South Yarra",
            ownerId: "user_yoga_girl"
        ))
        
        items.append(FashionItem(
            name: "Nike Pro Compression Shorts",
            brand: "Nike",
            category: .bottoms,
            size: "M",
            condition: .likeNew,
            originalPrice: 45.00,
            listingPrice: 25.00,
            description: "Black compression shorts. Great for gym or running.",
            sustainabilityScore: SustainabilityScore(totalScore: 62, carbonFootprint: 2.5, waterUsage: 1100, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Black"],
            styleTags: ["Athletic", "Performance", "Gym"],
            location: "Richmond",
            ownerId: "user_athlete"
        ))
        
        // MARK: - More Vintage Grails
        items.append(FashionItem(
            name: "Vintage Starter NBA Bulls Jacket",
            brand: "Starter",
            category: .outerwear,
            size: "XL",
            condition: .good,
            originalPrice: 320.00,
            listingPrice: 180.00,
            description: "90s Bulls Starter jacket. Minor wear but clean. True vintage.",
            sustainabilityScore: SustainabilityScore(totalScore: 90, carbonFootprint: 2.2, waterUsage: 1300, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Red", "Black"],
            styleTags: ["Vintage", "90s", "NBA"],
            location: "Brunswick",
            ownerId: "user_vintage_sports"
        ))
        
        items.append(FashionItem(
            name: "Vintage Ralph Lauren Denim Shirt",
            brand: "Ralph Lauren",
            category: .tops,
            size: "L",
            condition: .excellent,
            originalPrice: 110.00,
            listingPrice: 55.00,
            description: "Chambray button-down with polo pony. Made in USA.",
            sustainabilityScore: SustainabilityScore(totalScore: 85, carbonFootprint: 2.8, waterUsage: 1400, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Blue", "Denim"],
            styleTags: ["Vintage", "Preppy", "Classic"],
            location: "Kew",
            ownerId: "user_polo_archive"
        ))
        
        items.append(FashionItem(
            name: "Vintage Columbia Fleece Pullover",
            brand: "Columbia",
            category: .outerwear,
            size: "L",
            condition: .good,
            originalPrice: 95.00,
            listingPrice: 45.00,
            description: "Teal/purple colorblock fleece. Peak 90s outdoor vibes.",
            sustainabilityScore: SustainabilityScore(totalScore: 87, carbonFootprint: 2.5, waterUsage: 1200, isRecycled: false, isCertified: false, certifications: [], fibreTraceVerified: false),
            colorTags: ["Teal", "Purple"],
            styleTags: ["Vintage", "90s", "Outdoor"],
            location: "Northcote",
            ownerId: "user_fleece_king"
        ))
        
        return items
    }
}
