//
//  PremiumImageLoader.swift
//  Modaics
//
//  High-quality image loading with caching and progressive enhancement
//  Created to bring the app to life with premium visuals
//

import SwiftUI
import Combine

// MARK: - Image Loader
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var loadProgress: Double = 0
    
    private var cancellable: AnyCancellable?
    private var url: String
    
    init(url: String) {
        self.url = url
    }
    
    deinit {
        cancellable?.cancel()
    }
    
    func load() {
        isLoading = true
        loadProgress = 0
        
        // Check if it's a URL or local asset
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            loadFromURL()
        } else {
            loadLocalImage()
        }
    }
    
    private func loadLocalImage() {
        // Try loading from assets with @2x and @3x scale variants
        if let uiImage = UIImage(named: url) {
            self.image = uiImage
            self.loadProgress = 1.0
            self.isLoading = false
        } else {
            // Try with common extensions
            let extensions = ["", ".jpg", ".jpeg", ".png", ".webp"]
            var found = false
            
            for ext in extensions {
                if let uiImage = UIImage(named: url + ext) {
                    self.image = uiImage
                    self.loadProgress = 1.0
                    found = true
                    break
                }
            }
            
            if !found {
                // Use a demo/placeholder URL from Unsplash instead
                let demoURL = "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&q=80"
                self.url = demoURL
                loadFromURL()
                return
            }
            
            self.isLoading = false
            self.loadProgress = 1.0
        }
    }
    
    private func loadFromURL() {
        // Upgrade Depop thumbnail URLs to high-resolution versions
        var finalURL = url
        if url.contains("depop.com") && url.hasSuffix("/P10.jpg") {
            finalURL = url.replacingOccurrences(of: "/P10.jpg", with: "/P0.jpg")
            print("🔧 Upgraded Depop URL: P10 → P0")
        }
        
        guard let imageURL = URL(string: finalURL) else {
            print("❌ Invalid URL: \(finalURL)")
            isLoading = false
            return
        }
        
        // Configure URLRequest for better image quality and CDN compatibility
        var request = URLRequest(url: imageURL)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 30
        
        // Add headers to handle different CDNs (especially Depop's CloudFront)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("image/webp,image/apng,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("https://www.depop.com", forHTTPHeaderField: "Referer")
        
        print("🔄 Loading image from: \(finalURL)")
        
        cancellable = URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data: Data, response: URLResponse) -> UIImage in
                // Check HTTP response status
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status: \(httpResponse.statusCode) for \(finalURL)")
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        throw URLError(.badServerResponse)
                    }
                }
                
                // Create UIImage directly without re-rendering
                guard let image = UIImage(data: data) else {
                    print("❌ Failed to decode image data (\(data.count) bytes) from: \(finalURL)")
                    throw URLError(.cannotDecodeContentData)
                }
                
                print("✅ Successfully loaded image (\(data.count) bytes): \(finalURL)")
                return image
            }
            .catch { error -> Just<UIImage?> in
                print("❌ Error loading image: \(error.localizedDescription) - URL: \(finalURL)")
                return Just(nil)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (loadedImage: UIImage?) in
                guard let self = self else { return }
                
                if let loadedImage = loadedImage {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.image = loadedImage
                        self.loadProgress = 1.0
                    }
                } else {
                    print("⚠️ Image load failed, using fallback for: \(finalURL)")
                    // Use a fashion-related demo image as fallback
                    self.useFallbackImage()
                }
                
                self.isLoading = false
            }
    }
    
    private func useFallbackImage() {
        // Use different demo images based on the URL source
        let fallbackURL: String
        if url.contains("depop") {
            fallbackURL = "https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800&q=80"
        } else {
            fallbackURL = "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&q=80"
        }
        
        self.url = fallbackURL
        loadFromURL()
    }
    
    func cancel() {
        cancellable?.cancel()
        isLoading = false
    }
}

// MARK: - Premium Cached Image View
struct PremiumCachedImage: View {
    let url: String
    var contentMode: ContentMode = .fill
    var showProgress: Bool = true
    
    @StateObject private var loader: ImageLoader
    @State private var imageAppeared = false
    
    init(url: String, contentMode: ContentMode = .fill, showProgress: Bool = true) {
        self.url = url
        self.contentMode = contentMode
        self.showProgress = showProgress
        _loader = StateObject(wrappedValue: ImageLoader(url: url))
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .renderingMode(.original)
                    .interpolation(.high)
                    .aspectRatio(contentMode: contentMode)
                    .opacity(imageAppeared ? 1 : 0)
                    .drawingGroup() // Force high-quality rendering
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.3)) {
                            imageAppeared = true
                        }
                    }
            } else {
                // Sophisticated loading placeholder
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: [
                            Color.modaicsSurface2,
                            Color.modaicsSurface3
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack(spacing: 16) {
                        if loader.isLoading && showProgress {
                            // Circular progress
                            ZStack {
                                Circle()
                                    .stroke(
                                        Color.modaicsChrome1.opacity(0.2),
                                        lineWidth: 3
                                    )
                                    .frame(width: 40, height: 40)
                                
                                Circle()
                                    .trim(from: 0, to: loader.loadProgress)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.modaicsChrome1, .modaicsChrome2],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                    )
                                    .frame(width: 40, height: 40)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut, value: loader.loadProgress)
                            }
                        } else {
                            // Elegant icon
                            Image(systemName: "photo.artframe")
                                .font(.system(size: 32, weight: .ultraLight))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            .modaicsChrome1.opacity(0.6),
                                            .modaicsChrome2.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                }
            }
        }
        .onAppear {
            loader.load()
        }
        .onDisappear {
            loader.cancel()
        }
    }
}
