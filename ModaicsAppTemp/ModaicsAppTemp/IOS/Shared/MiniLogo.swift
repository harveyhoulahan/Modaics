//
//  MiniLogo.swift
//  ModaicsAppTemp
//
//  Created by Harvey Houlahan on 5/6/2025.
//

// MARK: - Mini Logo Component
struct MiniLogo: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 4, height: 16)
                .rotationEffect(.degrees(-40), anchor: .topLeading)
                .offset(x: -4, y: 0)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.modaicsDenim1, .modaicsDenim2],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4, height: 16)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.modaicsChrome2, .modaicsChrome3],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 4, height: 16)
                .rotationEffect(.degrees(40), anchor: .topTrailing)
                .offset(x: 4, y: 0)
        }
        .frame(width: 20, height: 20)
    }
}
