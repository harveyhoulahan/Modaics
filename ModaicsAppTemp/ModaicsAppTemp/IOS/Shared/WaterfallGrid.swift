//
//  WaterfallGrid.swift
//  Modaics
//
//  Waterfall item card component for Pinterest-style layouts
//

import SwiftUI

// MARK: - Waterfall Item Card Wrapper
struct WaterfallItemCard: View {
    let item: FashionItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Image
                CachedImageView(url: item.imageURLs.first, contentMode: .fill)
                    .aspectRatio(randomAspectRatio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(alignment: .leading, spacing: 4) {
                    // Brand
                    if !item.brand.isEmpty {
                        Text(item.brand)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.modaicsChrome1)
                            .lineLimit(1)
                    }
                    
                    // Name
                    Text(item.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.modaicsCotton)
                        .lineLimit(2)
                    
                    // Price & condition
                    HStack(spacing: 8) {
                        Text("$\(Int(item.listingPrice))")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.modaicsChrome1)
                        
                        Text(item.condition.rawValue)
                            .font(.system(size: 11))
                            .foregroundColor(.modaicsCottonLight)
                    }
                    
                    // Sustainability badge
                    if item.sustainabilityScore.totalScore >= 70 {
                        HStack(spacing: 4) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 10))
                            Text("Sustainable")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Random aspect ratio for variety (fashion items vary)
    private var randomAspectRatio: CGFloat {
        let ratios: [CGFloat] = [0.7, 0.8, 0.9, 1.0, 1.1, 1.2]
        return ratios[abs(item.id.hashValue) % ratios.count]
    }
}

// MARK: - Preview
#Preview {
    let sampleItems = (0..<20).map { index in
        FashionItem(
            id: UUID(),
            name: "Item \(index + 1)",
            brand: ["Nike", "Adidas", "Vintage", "Thrifted"][index % 4],
            category: .tops,
            size: "M",
            condition: .good,
            originalPrice: Double.random(in: 40...300),
            listingPrice: Double.random(in: 20...200),
            description: "Sample item description",
            imageURLs: ["https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600"],
            sustainabilityScore: SustainabilityScore(
                totalScore: Int.random(in: 50...100),
                carbonFootprint: 5.0,
                waterUsage: 2000,
                isRecycled: false,
                isCertified: false,
                certifications: [],
                fibreTraceVerified: false
            ),
            colorTags: ["Blue", "Black"][index % 2].split(separator: " ").map(String.init),
            location: "Melbourne",
            ownerId: UUID().uuidString
        )
    }
    
    ZStack {
        LinearGradient(
            colors: [.modaicsDarkBlue, .modaicsMidBlue],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        WaterfallGrid(items: sampleItems, columns: 2) { item in
            WaterfallItemCard(item: item) {
                print("Tapped item: \(item.name)")
            }
        }
        .padding(.horizontal, 20)
    }
}
