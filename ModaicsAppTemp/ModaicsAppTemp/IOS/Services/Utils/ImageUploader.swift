//
//  ImageUploader.swift
//  Modaics
//
//  Image compression, resizing, and upload utilities
//

import UIKit
import Foundation

// MARK: - Image Upload Result

struct ImageUploadResult {
    let base64String: String
    let originalSize: Int
    let compressedSize: Int
    let dimensions: CGSize
    let compressionRatio: Double
    
    var sizeReductionPercentage: Double {
        guard originalSize > 0 else { return 0 }
        return Double(originalSize - compressedSize) / Double(originalSize) * 100
    }
}

// MARK: - Image Upload Error

enum ImageUploadError: Error, LocalizedError {
    case invalidImage
    case compressionFailed
    case resizeFailed
    case base64EncodingFailed
    case fileTooLarge(maxSize: Double)
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        case .compressionFailed:
            return "Failed to compress image"
        case .resizeFailed:
            return "Failed to resize image"
        case .base64EncodingFailed:
            return "Failed to encode image"
        case .fileTooLarge(let maxSize):
            return "Image too large (max \(Int(maxSize))MB)"
        case .unsupportedFormat:
            return "Unsupported image format"
        }
    }
}

// MARK: - Image Uploader

@MainActor
class ImageUploader: ObservableObject {
    
    // MARK: - Shared Instance
    
    static let shared = ImageUploader()
    
    // MARK: - Configuration
    
    private let config: APIConfiguration
    private let cache: ImageUploadCache
    
    // MARK: - Published Properties
    
    @Published private(set) var isProcessing = false
    @Published private(set) var currentProgress: Double = 0
    
    // MARK: - Initialization
    
    init(configuration: APIConfiguration = .shared) {
        self.config = configuration
        self.cache = ImageUploadCache()
    }
    
    // MARK: - Image Processing
    
    /// Process image for upload with compression and resizing
    func processImage(
        _ image: UIImage,
        targetSize: CGSize? = nil,
        compressionQuality: CGFloat? = nil,
        useCache: Bool = true
    ) async throws -> ImageUploadResult {
        isProcessing = true
        currentProgress = 0
        
        defer {
            isProcessing = false
            currentProgress = 1.0
        }
        
        // Check cache
        let cacheKey = image.cacheKey
        if useCache, let cached = await cache.get(forKey: cacheKey) {
            return cached
        }
        
        // Get original data size estimate
        let originalSize = estimateImageSize(image)
        currentProgress = 0.1
        
        // Resize if needed
        let maxDimension = config.maxImageDimension
        let resizedImage: UIImage
        if image.size.width > maxDimension || image.size.height > maxDimension {
            resizedImage = resizeImage(image, toMaxDimension: maxDimension)
        } else {
            resizedImage = image
        }
        currentProgress = 0.3
        
        // Compress image
        let quality = compressionQuality ?? config.imageCompressionQuality
        guard let compressedData = compressImage(resizedImage, quality: quality) else {
            throw ImageUploadError.compressionFailed
        }
        currentProgress = 0.6
        
        // Check file size
        let maxSizeBytes = Int(config.maxUploadSizeMB * 1024 * 1024)
        guard compressedData.count <= maxSizeBytes else {
            // Try higher compression
            guard let highlyCompressed = compressImage(resizedImage, quality: 0.5),
                  highlyCompressed.count <= maxSizeBytes else {
                throw ImageUploadError.fileTooLarge(maxSize: config.maxUploadSizeMB)
            }
            currentProgress = 0.8
            
            let base64String = highlyCompressed.base64EncodedString()
            let result = ImageUploadResult(
                base64String: base64String,
                originalSize: originalSize,
                compressedSize: highlyCompressed.count,
                dimensions: resizedImage.size,
                compressionRatio: Double(highlyCompressed.count) / Double(originalSize)
            )
            
            if useCache {
                await cache.set(result, forKey: cacheKey)
            }
            
            return result
        }
        currentProgress = 0.8
        
        // Encode to base64
        let base64String = compressedData.base64EncodedString()
        currentProgress = 0.9
        
        let result = ImageUploadResult(
            base64String: base64String,
            originalSize: originalSize,
            compressedSize: compressedData.count,
            dimensions: resizedImage.size,
            compressionRatio: Double(compressedData.count) / Double(originalSize)
        )
        currentProgress = 1.0
        
        // Cache result
        if useCache {
            await cache.set(result, forKey: cacheKey)
        }
        
        return result
    }
    
    /// Process multiple images
    func processImages(
        _ images: [UIImage],
        useCache: Bool = true
    ) async throws -> [ImageUploadResult] {
        var results: [ImageUploadResult] = []
        
        for (index, image) in images.enumerated() {
            let result = try await processImage(image, useCache: useCache)
            results.append(result)
            currentProgress = Double(index + 1) / Double(images.count)
        }
        
        return results
    }
    
    // MARK: - Image Resizing
    
    private func resizeImage(_ image: UIImage, toMaxDimension maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        // Calculate new size maintaining aspect ratio
        let widthRatio = maxDimension / size.width
        let heightRatio = maxDimension / size.height
        let ratio = min(widthRatio, heightRatio)
        
        // Only resize if needed
        guard ratio < 1.0 else { return image }
        
        let newSize = CGSize(
            width: size.width * ratio,
            height: size.height * ratio
        )
        
        return resizeImage(image, to: newSize)
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // Maintain original scale
        format.opaque = false
        format.preferredRange = .standard
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            context.cgContext.interpolationQuality = .high
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // MARK: - Image Compression
    
    private func compressImage(_ image: UIImage, quality: CGFloat) -> Data? {
        // Try JPEG compression
        if let jpegData = image.jpegData(compressionQuality: quality) {
            return jpegData
        }
        
        // Fallback to PNG for transparency support
        return image.pngData()
    }
    
    private func estimateImageSize(_ image: UIImage) -> Int {
        // Estimate based on dimensions and 4 bytes per pixel (RGBA)
        let pixelCount = Int(image.size.width * image.size.height * image.scale * image.scale)
        return pixelCount * 4
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        Task {
            await cache.clear()
        }
    }
    
    // MARK: - Helpers
    
    /// Format file size for display
    static func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Image Upload Cache

@MainActor
private actor ImageUploadCache {
    private var cache: [String: ImageUploadResult] = [:]
    private let maxCacheSize = 50
    private var accessOrder: [String] = []
    
    func get(forKey key: String) -> ImageUploadResult? {
        guard let result = cache[key] else { return nil }
        
        // Update access order
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
        
        return result
    }
    
    func set(_ result: ImageUploadResult, forKey key: String) {
        // Evict oldest if needed
        if cache.count >= maxCacheSize, let oldest = accessOrder.first {
            cache.removeValue(forKey: oldest)
            accessOrder.removeFirst()
        }
        
        cache[key] = result
        accessOrder.append(key)
    }
    
    func clear() {
        cache.removeAll()
        accessOrder.removeAll()
    }
}

// MARK: - UIImage Extension

extension UIImage {
    var cacheKey: String {
        // Create a simple hash based on image data
        if let data = self.jpegData(compressionQuality: 0.9) {
            return data.base64EncodedString().prefix(32).description
        }
        return "\(size.width)_\(size.height)_\(hashValue)"
    }
}

// MARK: - Quick Processing

extension ImageUploader {
    
    /// Quick method to get base64 string from UIImage
    static func toBase64(
        _ image: UIImage,
        maxDimension: CGFloat = 2048,
        quality: CGFloat = 0.85
    ) async throws -> String {
        let result = try await ImageUploader.shared.processImage(
            image,
            targetSize: nil,
            compressionQuality: quality
        )
        return result.base64String
    }
    
    /// Quick method to get base64 with size info
    static func toBase64WithInfo(
        _ image: UIImage
    ) async throws -> (base64: String, size: Int, compressionRatio: Double) {
        let result = try await ImageUploader.shared.processImage(image)
        return (
            base64: result.base64String,
            size: result.compressedSize,
            compressionRatio: result.compressionRatio
        )
    }
}
