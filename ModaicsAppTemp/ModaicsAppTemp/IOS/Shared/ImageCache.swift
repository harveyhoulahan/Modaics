//
//  ImageCache.swift
//  ModaicsAppTemp
//
//  High-performance image caching system for optimal loading and memory management
//  Created by Harvey Houlahan on 11/26/2025.
//

import SwiftUI
import UIKit

// MARK: - Image Cache Manager
actor ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private var cache = NSCache<NSString, UIImage>()
    private var downloadTasks: [String: Task<UIImage?, Never>] = [:]
    
    private init() {
        // Configure cache limits
        cache.countLimit = 200 // Maximum 200 images in memory
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
    }
    
    func image(for urlString: String) -> UIImage? {
        return cache.object(forKey: urlString as NSString)
    }
    
    func setImage(_ image: UIImage, for urlString: String) {
        // Estimate image cost (width * height * 4 bytes per pixel)
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: urlString as NSString, cost: cost)
    }
    
    func downloadImage(from urlString: String) async -> UIImage? {
        // Check cache first
        if let cached = cache.object(forKey: urlString as NSString) {
            return cached
        }
        
        // Check if already downloading
        if let existingTask = downloadTasks[urlString] {
            return await existingTask.value
        }
        
        // Create new download task
        let task = Task<UIImage?, Never> {
            guard let url = URL(string: urlString) else { return nil }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                // Decode and optimize image
                guard let image = UIImage(data: data) else { return nil }
                
                // Downsample for better memory usage
                let downsampledImage = await downsample(image: image, to: CGSize(width: 800, height: 800))
                
                // Cache the result
                await setImage(downsampledImage, for: urlString)
                
                return downsampledImage
            } catch {
                return nil
            }
        }
        
        downloadTasks[urlString] = task
        let result = await task.value
        downloadTasks.removeValue(forKey: urlString)
        
        return result
    }
    
    private func downsample(image: UIImage, to targetSize: CGSize) async -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        // Only downsample if image is larger than target
        guard ratio < 1.0 else { return image }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}

// MARK: - Cached Async Image View
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let urlString: String
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    init(
        url urlString: String,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.urlString = urlString
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let uiImage = loadedImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
                    .task {
                        await loadImage()
                    }
            }
        }
    }
    
    private func loadImage() async {
        guard !isLoading else { return }
        isLoading = true
        
        // Check cache synchronously first
        if let cached = await ImageCacheManager.shared.image(for: urlString) {
            loadedImage = cached
            isLoading = false
            return
        }
        
        // Download if not cached
        if let downloaded = await ImageCacheManager.shared.downloadImage(from: urlString) {
            withAnimation(.easeInOut(duration: 0.3)) {
                loadedImage = downloaded
            }
        }
        
        isLoading = false
    }
}

// MARK: - Convenience Initializers
extension CachedAsyncImage where Content == Image, Placeholder == Color {
    init(url urlString: String) {
        self.init(
            url: urlString,
            content: { image in image },
            placeholder: { Color.gray.opacity(0.2) }
        )
    }
}
