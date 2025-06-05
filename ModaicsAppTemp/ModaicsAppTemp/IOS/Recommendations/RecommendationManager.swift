//
//  RecommendationManager.swift
//  Modaics
//  Created by Harvey Houlahan on 6/6/2025.
//
//  Provides item-to-item recommendations using:
//  – Core ML embeddings  (preferred)
//  – Pre-baked embeddings JSON
//  – Tag / category heuristics (fallback)
//

import Foundation
import CoreML
import Accelerate
import SwiftUI

final class RecommendationManager {

    // MARK: – Singleton
    static let shared = RecommendationManager()
    private init() { loadAssets() }

    // MARK: – Assets
    private var mlModel   : MLModel?
    private var embeddings: [[Float]] = []
    private var itemIDs   : [UUID]    = []
    private var imageCache = NSCache<NSString, UIImage>()

    private func loadAssets() {
        // 1. Try to load the compiled .mlmodelc
        if let url = Bundle.main.url(forResource: "ResNet50Embedding", withExtension: "mlmodelc"),
           let model = try? MLModel(contentsOf: url) {
            mlModel = model
        }

        // 2. Load pre-baked embeddings JSON (optional)
        if  let eURL = Bundle.main.url(forResource: "Embeddings", withExtension: "json"),
            let idURL = Bundle.main.url(forResource: "EmbeddingIDs", withExtension: "json"),
            let eData = try? Data(contentsOf: eURL),
            let idData = try? Data(contentsOf: idURL),
            let vectors = try? JSONDecoder().decode([[Float]].self, from: eData),
            let ids     = try? JSONDecoder().decode([UUID].self,     from: idData) {
            embeddings = vectors
            itemIDs    = ids
        }
    }

    // MARK: – Public API  ---------------------------------------------------
    /// Returns the top *k* similar items to `queryItem`.
    func recommendations(for queryItem: FashionItem,
                         from allItems: [FashionItem],
                         k: Int = 6) -> [FashionItem] {

        // 1. Preferred path – learned embeddings
        if let queryVec = queryItem.embeddingVector,
           !embeddings.isEmpty {
            return topKByEmbedding(queryItem: queryItem,   // NEW ARG
                                   query:     queryVec,
                                   k:         k,
                                   in:        allItems)
        }

        // 2. No stored vector – try to create one on-device (async)
        if let model = mlModel {
            Task.detached(priority: .userInitiated) {
                if let uiImg = await self.loadFirstImage(for: queryItem),
                   let vec   = self.extractEmbedding(from: uiImg, with: model) {

                    // You can store `vec` somewhere persistent later if you wish.
                }
            }
        }

        // 3. Fallback – simple heuristics
        return SimpleHeuristic.similar(to: queryItem, in: allItems, max: k)
    }

    // MARK: – Embedding helpers  -------------------------------------------

    private func topKByEmbedding(
            queryItem : FashionItem,           // NEW
            query     : [Float],
            k         : Int,
            in allItems: [FashionItem]) -> [FashionItem] {

        guard !embeddings.isEmpty, embeddings.count == itemIDs.count else { return [] }

        // cosine similarity …
        var scored: [(Float, UUID)] = []
        for (vec, id) in zip(embeddings, itemIDs) {
            scored.append((cosine(query, vec), id))
        }

        let topIDs = scored.sorted { $0.0 > $1.0 }
                           .prefix(k + 1)          // keep a few extras
                           .map(\.1)

        return allItems
            .filter { topIDs.contains($0.id) && $0.id != queryItem.id } // now compiles
            .prefix(k)
            .map { $0 }
    }

    private func cosine(_ a: [Float], _ b: [Float]) -> Float {
        var dot: Float = 0, normA: Float = 0, normB: Float = 0
        vDSP_dotpr(a, 1, b, 1, &dot, vDSP_Length(a.count))
        vDSP_svesq(a, 1, &normA, vDSP_Length(a.count))
        vDSP_svesq(b, 1, &normB, vDSP_Length(b.count))
        return dot / (sqrt(normA) * sqrt(normB) + 1e-8)
    }

    // Ensure Core ML runs on a background thread
    private func extractEmbedding(from image: UIImage, with model: MLModel) -> [Float]? {
        // Resize to 224×224
        let size = CGSize(width: 224, height: 224)
        UIGraphicsBeginImageContextWithOptions(size, true, 1)
        image.draw(in: CGRect(origin: .zero, size: size))
        guard let resized = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()

        guard let buffer = resized.toMLPixelBuffer() else { return nil }          // <— use your existing helper
        guard let out = try? model.prediction(from: MLDictionaryFeatureProvider(
                            dictionary: ["input_image": buffer])) else { return nil }
        guard let arr = out.featureValue(for: "output")?.multiArrayValue else { return nil }
        return (0..<arr.count).map { Float(truncating: arr[$0]) }
    }
    
    @available(*, deprecated, message: "Use recommendations(for:from:) instead")
    func topKSimilarItems(query: [Float], k: Int = 5) -> [UUID] {
        // Return only IDs so legacy code can filter
        let dummy = recommendations(for: .init(
            id: .init(), name: "", brand: "", category: .other, size: "",
            condition: .good, originalPrice: 0, listingPrice: 0, description: "",
            imageURLs: [], sustainabilityScore: .empty, location: "", ownerId: ""
        ), from: [])                                   // empty because we’re stubbing
        return dummy.prefix(k).map(\.id)
    }

    @available(*, deprecated, message: "Embeddings now extracted automatically")
    func computeEmbedding(for _: UIImage) -> [Float]? { nil }
    
    // Load first image – bundled asset or download once
    private func loadFirstImage(for item: FashionItem) async -> UIImage? {
        guard let urlStr = item.primaryImageURL else { return nil }

        // 1. Try bundled asset
        if let img = UIImage(named: urlStr) { return img }

        // 2. Look in cache
        if let cached = imageCache.object(forKey: urlStr as NSString) { return cached }

        // 3. Download from remote URL
        guard let url = URL(string: urlStr) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = UIImage(data: data) {
                imageCache.setObject(img, forKey: urlStr as NSString)
                return img
            }
        } catch { return nil }

        return nil
    }

    
}

// MARK: – Tag / category heuristic fallback
fileprivate struct SimpleHeuristic {
    static func similar(to item: FashionItem,
                        in all: [FashionItem],
                        max k: Int) -> [FashionItem] {

        let others = all.filter { $0.id != item.id }
        let scored = others.map { other -> (Int, FashionItem) in
            let overlap = Set(other.tags).intersection(item.tags).count
            let catBonus = other.category == item.category ? 1 : 0
            return (overlap + catBonus, other)
        }
        return scored.sorted { $0.0 > $1.0 }
                     .prefix(k)
                     .map(\.1)
    }
}

// MARK: - UIImage → CVPixelBuffer helper  (inline fallback)
import UIKit
import CoreVideo

fileprivate extension UIImage {
    func toMLPixelBuffer() -> CVPixelBuffer? {
        let size = CGSize(width: 224, height: 224)

        // Draw into 224×224 bitmap
        UIGraphicsBeginImageContextWithOptions(size, true, 1)
        self.draw(in: CGRect(origin: .zero, size: size))
        guard let cg = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            UIGraphicsEndImageContext(); return nil
        }
        UIGraphicsEndImageContext()

        // Create empty pixel buffer
        var pb: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        guard CVPixelBufferCreate(kCFAllocatorDefault,
                                  Int(size.width), Int(size.height),
                                  kCVPixelFormatType_32BGRA,
                                  attrs as CFDictionary, &pb) == kCVReturnSuccess,
              let pixelBuffer = pb else { return nil }

        // Render into buffer
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        if let ctx = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                               width: Int(size.width), height: Int(size.height),
                               bitsPerComponent: 8,
                               bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                               space: CGColorSpaceCreateDeviceRGB(),
                               bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) {
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        return pixelBuffer
    }
}
