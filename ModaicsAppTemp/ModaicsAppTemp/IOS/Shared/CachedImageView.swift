//
//  CachedImageView.swift
//  Modaics
//
//  High-performance cached image loading with placeholder and error states
//

import SwiftUI

struct CachedImageView: View {
    let url: String?
    let contentMode: ContentMode
    let showShimmer: Bool
    
    init(url: String?, contentMode: ContentMode = .fill, showShimmer: Bool = true) {
        self.url = url
        self.contentMode = contentMode
        self.showShimmer = showShimmer
    }
    
    var body: some View {
        if let urlString = url, let imageURL = URL(string: urlString) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    if showShimmer {
                        ShimmerPlaceholder()
                    } else {
                        Color.modaicsDarkBlue.opacity(0.3)
                    }
                case .success(let image):
                    image
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .aspectRatio(contentMode: contentMode)
                        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                case .failure:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
        } else {
            // Fallback for no URL
            placeholderView
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: [.modaicsDarkBlue.opacity(0.3), .modaicsMidBlue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "photo")
                .font(.system(size: 40))
                .foregroundColor(.modaicsCottonLight.opacity(0.5))
        }
    }
}

struct ShimmerPlaceholder: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [.modaicsDarkBlue.opacity(0.3), .modaicsMidBlue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                LinearGradient(
                    colors: [
                        .clear,
                        .modaicsChrome1.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * geometry.size.width)
                .mask(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                phase = 1
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        CachedImageView(
            url: "https://picsum.photos/400/600",
            contentMode: .fill
        )
        .frame(width: 200, height: 300)
        .clipShape(Rectangle())
        
        CachedImageView(url: nil)
            .frame(width: 200, height: 300)
            .clipShape(Rectangle())
    }
    .padding()
    .background(Color.modaicsDarkBlue)
}
