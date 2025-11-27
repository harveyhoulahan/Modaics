//
//  VisionAnalysisService.swift
//  Modaics
//
//  Real computer vision AI using Vision framework + CLIP backend
//

import SwiftUI
import Vision
import CoreML
import UIKit

@MainActor
class VisionAnalysisService: ObservableObject {
    static let shared = VisionAnalysisService()
    
    @Published var isAnalyzing: Bool = false
    @Published var analysisResult: ItemAnalysisResult?
    @Published var error: String?
    
    private let backendURL: String = "http://10.20.99.164:8000"
    private lazy var searchClient = SearchAPIClient(baseURL: backendURL)
    
    // Core ML Models
    private var categoryModel: FashionCategoryClassifier?
    private var colorModel: FashionColourClassifier?
    private var brandModel: FashionBrandClassifier?
    
    private init() {
        loadModels()
    }
    
    /// Load all Create ML models
    private func loadModels() {
        do {
            categoryModel = try FashionCategoryClassifier(configuration: MLModelConfiguration())
            print("✅ Loaded FashionCategoryClassifier")
        } catch {
            print("❌ Failed to load category model: \(error)")
        }
        
        do {
            colorModel = try FashionColourClassifier(configuration: MLModelConfiguration())
            print("✅ Loaded FashionColourClassifier")
        } catch {
            print("❌ Failed to load color model: \(error)")
        }
        
        do {
            brandModel = try FashionBrandClassifier(configuration: MLModelConfiguration())
            print("✅ Loaded FashionBrandClassifier")
        } catch {
            print("❌ Failed to load brand model: \(error)")
        }
    }
    
    /// Full AI analysis pipeline using Vision + CLIP + Create ML
    func analyzeItem(images: [UIImage]) async -> ItemAnalysisResult? {
        guard !images.isEmpty else { return nil }
        
        isAnalyzing = true
        error = nil
        
        // Try backend AI first (uses CLIP + 39,809 item database)
        if let backendResult = await analyzeWithBackendAI(image: images.first!) {
            print("✅ Using backend AI analysis")
            isAnalyzing = false
            analysisResult = backendResult
            return backendResult
        }
        
        print("⚠️ Backend AI unavailable, falling back to local ML")
        
        // Fallback to local ML models
        // Run all analyses in parallel
        async let mlCategory = classifyWithML(image: images.first!)
        async let mlColor = classifyColorWithML(image: images.first!)
        async let mlBrand = classifyBrandWithML(image: images.first!)
        async let visionColor = detectColors(in: images.first!) // Fallback for ML
        async let textAnalysis = detectText(in: images.first!)
        
        // Wait for all results
        let category = await mlCategory
        let color = await mlColor
        let brand = await mlBrand
        let visionColors = await visionColor
        let texts = await textAnalysis
        
        // Combine all analyses
        let result = combineAnalyses(
            mlCategory: category,
            mlColor: color,
            mlBrand: brand,
            visionColors: visionColors,
            texts: texts,
            clipResult: nil
        )
        
        isAnalyzing = false
        analysisResult = result
        return result
    }
    
    // MARK: - Backend AI Analysis
    
    /// Analyze using backend CLIP AI (uses 39,809 item database)
    private func analyzeWithBackendAI(image: UIImage) async -> ItemAnalysisResult? {
        print("🔍 Attempting backend AI analysis at \(backendURL)...")
        do {
            let analysis = try await searchClient.analyzeImage(image)
            
            print("✅ Backend returned: \(analysis.detectedItem) - \(analysis.likelyBrand) - \(Int(analysis.confidence * 100))%")
            
            // Map to CategoryEnum
            let categoryEnum = mapCategoryStringToEnum(analysis.category)
            
            // Map condition
            let conditionEnum = mapConditionString(analysis.estimatedCondition)
            
            // Build a suggested name from the analysis
            let primaryColor = analysis.colors.first ?? "Unknown"
            let suggestedName = "\(primaryColor) \(categoryEnum.rawValue.capitalized)"
            
            return ItemAnalysisResult(
                suggestedName: suggestedName,
                suggestedBrand: analysis.likelyBrand,
                suggestedCategory: categoryEnum,
                suggestedCondition: conditionEnum,
                suggestedSize: analysis.estimatedSize,
                suggestedDescription: analysis.description,
                detectedColors: analysis.colors,
                detectedMaterials: analysis.materials,
                suggestedPrice: analysis.estimatedPrice,
                confidence: analysis.confidence
            )
        } catch {
            print("❌ Backend AI analysis failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("❌ URL Error code: \(urlError.code)")
                print("❌ URL: \(urlError.failureURLString ?? "unknown")")
            }
            return nil
        }
    }
    
    // Helper to map category strings to enum
    private func mapCategoryStringToEnum(_ category: String) -> Category {
        let lowercased = category.lowercased()
        switch lowercased {
        case "tops", "top", "shirt", "tshirt", "blouse": return .tops
        case "bottoms", "pants", "jeans", "shorts": return .bottoms
        case "dresses", "dress": return .dresses
        case "outerwear", "jacket", "coat": return .outerwear
        case "shoes", "shoe", "sneakers": return .shoes
        case "accessories", "accessory": return .accessories
        case "bags", "bag": return .bags
        case "jewelry": return .jewelry
        default: return .other
        }
    }
    
    // Helper to map condition strings to enum
    private func mapConditionString(_ condition: String) -> Condition {
        let lowercased = condition.lowercased()
        switch lowercased {
        case "new", "new with tags": return .new
        case "like new", "likenew": return .likeNew
        case "excellent": return .excellent
        case "good": return .good
        case "fair": return .fair
        default: return .good
        }
    }
    
    // MARK: - Create ML Classification
    
    /// Classify category using trained Create ML model
    private func classifyWithML(image: UIImage) async -> (category: String, confidence: Double)? {
        guard let categoryModel = categoryModel,
              let pixelBuffer = image.pixelBuffer() else { return nil }
        
        do {
            let prediction = try categoryModel.prediction(image: pixelBuffer)
            let targetLabel = prediction.target
            let confidence = prediction.targetProbability[targetLabel] ?? 0.0
            print("🏷️ ML Category: \(targetLabel) (\(String(format: "%.1f%%", confidence * 100)))")
            return (targetLabel, confidence)
        } catch {
            print("❌ Category classification error: \(error)")
            return nil
        }
    }
    
    /// Classify color using trained Create ML model
    private func classifyColorWithML(image: UIImage) async -> (color: String, confidence: Double)? {
        guard let colorModel = colorModel,
              let pixelBuffer = image.pixelBuffer() else { return nil }
        
        do {
            let prediction = try colorModel.prediction(image: pixelBuffer)
            let targetLabel = prediction.target
            let confidence = prediction.targetProbability[targetLabel] ?? 0.0
            print("🎨 ML Color: \(targetLabel) (\(String(format: "%.1f%%", confidence * 100)))")
            return (targetLabel, confidence)
        } catch {
            print("❌ Color classification error: \(error)")
            return nil
        }
    }
    
    /// Classify brand using trained Create ML model
    private func classifyBrandWithML(image: UIImage) async -> (brand: String, confidence: Double)? {
        guard let brandModel = brandModel,
              let pixelBuffer = image.pixelBuffer() else { return nil }
        
        do {
            let prediction = try brandModel.prediction(image: pixelBuffer)
            let targetLabel = prediction.target
            let confidence = prediction.targetProbability[targetLabel] ?? 0.0
            
            // Only return brand if confidence is high enough (>30%)
            // Many items won't have visible brand markers
            if confidence > 0.3 {
                print("👔 ML Brand: \(targetLabel) (\(String(format: "%.1f%%", confidence * 100)))")
                return (targetLabel, confidence)
            } else {
                print("👔 ML Brand: Low confidence (\(String(format: "%.1f%%", confidence * 100))), skipping")
                return nil
            }
        } catch {
            print("❌ Brand classification error: \(error)")
            return nil
        }
    }
    
    // MARK: - Legacy Vision Framework Analysis (Fallback)
    
    /// Detect dominant colors using Vision framework with nuanced color detection (FALLBACK)
    private func detectColors(in image: UIImage) async -> [String] {
        guard image.cgImage != nil else { return [] }
        
        return await withCheckedContinuation { continuation in
            var detectedColors: [String] = []
            
            // Sample multiple regions to find garment color (avoiding background)
            if let inputImage = CIImage(image: image) {
                let extent = inputImage.extent
                
                // Define multiple sampling regions - focus on where garment likely is
                // Avoid edges where background is more common
                let regions: [(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, name: String)] = [
                    (0.35, 0.30, 0.30, 0.30, "Center"),       // Center of image
                    (0.25, 0.35, 0.20, 0.20, "Left-Center"),  // Left side
                    (0.55, 0.35, 0.20, 0.20, "Right-Center"), // Right side
                    (0.35, 0.45, 0.30, 0.20, "Lower-Center"), // Lower center
                    (0.35, 0.25, 0.30, 0.20, "Upper-Center")  // Upper center
                ]
                
                var allDetectedColors: [(color: String, brightness: CGFloat, saturation: CGFloat)] = []
                
                for region in regions {
                    let sampleRect = CGRect(
                        x: extent.width * region.x,
                        y: extent.height * region.y,
                        width: extent.width * region.w,
                        height: extent.height * region.h
                    )
                    
                    if let croppedImage = inputImage.cropped(to: sampleRect).averageColor() {
                        var hue: CGFloat = 0
                        var saturation: CGFloat = 0
                        var brightness: CGFloat = 0
                        
                        UIColor(ciColor: croppedImage).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
                        
                        print("🎨 Region \(region.name): H:\(String(format: "%.2f", hue)) S:\(String(format: "%.2f", saturation)) B:\(String(format: "%.2f", brightness))")
                        
                        let colorName = classifyNuancedColor(hue: hue, saturation: saturation, brightness: brightness)
                        
                        allDetectedColors.append((color: colorName, brightness: brightness, saturation: saturation))
                    }
                }
                
                // Filter out very dark colors (likely background) - brightness < 0.25 is usually background/shadow
                // BUT keep dark blues/navys (they're garment colors, not background)
                let lightColors = allDetectedColors.filter { colorData in
                    // Keep if brightness > 0.25 (light enough)
                    if colorData.brightness > 0.25 {
                        return true
                    }
                    // Also keep dark blues/navys even if brightness < 0.25
                    if colorData.color.contains("Blue") || colorData.color == "Navy" {
                        return true
                    }
                    return false
                }
                
                print("🎨 Filtered colors: \(lightColors.map { "\($0.color) (B:\(String(format: "%.2f", $0.brightness)))" })")
                
                // Count frequency of light colors
                var colorCounts: [String: Int] = [:]
                for colorData in lightColors {
                    colorCounts[colorData.color, default: 0] += 1
                }
                
                // Sort by frequency
                let sortedColors = colorCounts.sorted { $0.value > $1.value }
                
                // Take top color if it appears in multiple regions
                if let topColor = sortedColors.first, topColor.value >= 2 {
                    detectedColors.append(topColor.key)
                    print("🎨 Primary color (appears \(topColor.value) times): \(topColor.key)")
                }
                
                // If we still don't have a color, take the brightest non-black color
                if detectedColors.isEmpty {
                    if let brightestColor = allDetectedColors
                        .filter({ $0.brightness > 0.3 && $0.color != "Black" && $0.color != "Charcoal" })
                        .max(by: { $0.brightness < $1.brightness }) {
                        detectedColors.append(brightestColor.color)
                        print("🎨 Using brightest color: \(brightestColor.color) (B:\(brightestColor.brightness))")
                    }
                }
            }
            
            print("🎨 Final detected colors: \(detectedColors)")
            continuation.resume(returning: detectedColors)
        }
    }
    
    /// Classify color with nuanced naming (light blue, navy, sky blue, etc.)
    private func classifyNuancedColor(hue: CGFloat, saturation: CGFloat, brightness: CGFloat) -> String {
        print("🎨 HSB values - H:\(hue) S:\(saturation) B:\(brightness)")
        
        // Handle achromatic colors (low saturation)
        if saturation < 0.15 {
            if brightness < 0.2 {
                return "Black"
            } else if brightness > 0.85 {
                return "White"
            } else if brightness > 0.65 {
                return "Light Gray"
            } else if brightness > 0.35 {
                return "Gray"
            } else {
                return "Charcoal"
            }
        }
        
        // Very light/pastel colors with low-medium saturation
        if saturation >= 0.15 && saturation < 0.3 && brightness > 0.7 {
            // Warm tones (yellow/orange/red hues) -> Cream/Beige
            if hue >= 0.0 && hue <= 0.18 {
                return "Cream"
            } else if hue >= 0.18 && hue <= 0.3 {
                return "Beige"
            }
        }
        
        // Handle colors by hue range (0-1 scale)
        // Red: 0.95-1.0 and 0.0-0.05
        if (hue >= 0.95 || hue <= 0.05) {
            if brightness > 0.8 && saturation > 0.7 {
                return "Bright Red"
            } else if brightness > 0.7 {
                return "Red"
            } else if brightness < 0.4 {
                return "Burgundy"
            } else if saturation < 0.4 {
                return "Rose"
            }
            return "Red"
        }
        
        // Orange: 0.05-0.15
        if hue >= 0.05 && hue <= 0.15 {
            if brightness > 0.8 && saturation < 0.4 {
                return "Cream"
            } else if brightness > 0.7 && saturation > 0.6 {
                return "Orange"
            } else if brightness < 0.5 {
                return "Rust"
            } else if saturation < 0.4 {
                return "Peach"
            }
            return "Orange"
        }
        
        // Yellow: 0.15-0.30 (expanded for cream/beige detection)
        if hue >= 0.15 && hue <= 0.30 {
            if brightness > 0.75 && saturation < 0.35 {
                return "Cream"
            } else if brightness > 0.65 && saturation < 0.4 {
                return "Beige"
            } else if brightness > 0.8 && saturation > 0.4 {
                return "Light Yellow"
            } else if brightness < 0.5 {
                return "Mustard"
            } else if saturation > 0.4 {
                return "Yellow"
            }
            return "Tan"
        }
        
        // Green: 0.25-0.45
        if hue >= 0.25 && hue <= 0.45 {
            if brightness > 0.7 && saturation > 0.6 {
                return "Bright Green"
            } else if brightness > 0.6 && saturation < 0.5 {
                return "Sage"
            } else if brightness < 0.4 {
                return "Forest Green"
            } else if saturation < 0.3 {
                return "Olive"
            }
            return "Green"
        }
        
        // Blue: 0.45-0.7 (expanded range for better detection)
        if hue >= 0.45 && hue <= 0.7 {
            // Very light/pastel blues
            if brightness > 0.65 && saturation < 0.5 {
                return "Light Blue"
            }
            // Light blues with more saturation
            else if brightness > 0.6 {
                if saturation > 0.5 {
                    return "Sky Blue"
                } else if saturation > 0.2 {
                    return "Light Blue"
                } else {
                    return "Powder Blue"
                }
            }
            // Dark blues
            else if brightness < 0.4 {
                if saturation > 0.5 {
                    return "Navy"
                } else {
                    return "Dark Blue"
                }
            }
            // Mid-tone blues
            else {
                if saturation > 0.6 {
                    return "Royal Blue"
                } else if saturation > 0.3 {
                    return "Blue"
                } else {
                    return "Slate Blue"
                }
            }
        }
        
        // Purple: 0.7-0.85
        if hue >= 0.7 && hue <= 0.85 {
            if brightness > 0.7 {
                return "Lavender"
            } else if saturation > 0.6 {
                return "Purple"
            } else {
                return "Mauve"
            }
        }
        
        // Pink: 0.85-0.95
        if hue >= 0.85 && hue <= 0.95 {
            if brightness > 0.8 {
                return "Light Pink"
            } else if saturation > 0.6 {
                return "Hot Pink"
            } else {
                return "Pink"
            }
        }
        
        // Brown (low saturation, warm hues)
        if saturation >= 0.1 && saturation < 0.4 && hue >= 0.0 && hue <= 0.15 {
            if brightness > 0.6 {
                return "Tan"
            } else if brightness > 0.4 {
                return "Brown"
            } else {
                return "Dark Brown"
            }
        }
        
        // Default fallback
        return "Multicolor"
    }
    
    /// Detect objects and classify clothing type (DEPRECATED - now using Create ML)
    private func detectObjects(in image: UIImage) async -> [String] {
        // No longer needed - Create ML handles this
        return []
    }
    
    /// Detect text in image (brand names, tags, etc.)
    private func detectText(in image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }
        
        return await withCheckedContinuation { continuation in
            var detectedTexts: [String] = []
            
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }
                    detectedTexts.append(topCandidate.string)
                }
                
                continuation.resume(returning: detectedTexts)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Vision text detection error: \(error)")
                continuation.resume(returning: [])
            }
        }
    }
    
    // MARK: - CLIP Backend Analysis
    
    /// Use CLIP backend for semantic understanding
    private func analyzeWithCLIP(image: UIImage) async -> CLIPAnalysisResult? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        var request = URLRequest(url: URL(string: "\(backendURL)/analyze_image")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let base64Image = imageData.base64EncodedString()
        let body: [String: Any] = ["image": base64Image]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(CLIPAnalysisResult.self, from: data)
            return response
        } catch {
            self.error = "CLIP analysis failed: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Combine Analyses
    
    private func combineAnalyses(
        mlCategory: (category: String, confidence: Double)?,
        mlColor: (color: String, confidence: Double)?,
        mlBrand: (brand: String, confidence: Double)?,
        visionColors: [String],
        texts: [String],
        clipResult: CLIPAnalysisResult?
    ) -> ItemAnalysisResult {
        
        // Category: Use ML if confidence > 50% and not "other"
        // For low confidence, use CLIP or context clues
        let category: Category
        var categorySource = "ML"
        
        if let mlCat = mlCategory, mlCat.confidence > 0.5 && mlCat.category.lowercased() != "other" {
            // Good ML prediction
            category = Category(rawValue: mlCat.category) ?? .tops
            categorySource = "ML (\(String(format: "%.1f%%", mlCat.confidence * 100)))"
        } else if let mlCat = mlCategory, mlCat.confidence > 0.35 {
            // Low confidence ML - check if it makes sense
            let catLower = mlCat.category.lowercased()
            
            // If ML says "shirt" but confidence is low, check if it's actually outerwear
            if catLower == "shirt" && (visionColors.first?.lowercased().contains("navy") == true || 
                                       visionColors.first?.lowercased().contains("blue") == true) {
                // Blue/Navy items are often jackets mislabeled as shirts
                category = .outerwear
                categorySource = "Vision override (blue/navy suggests jacket)"
            } else {
                category = Category(rawValue: mlCat.category) ?? .tops
                categorySource = "ML low confidence (\(String(format: "%.1f%%", mlCat.confidence * 100)))"
            }
        } else if let clip = clipResult {
            category = Category(rawValue: clip.category) ?? .tops
            categorySource = "CLIP fallback"
        } else {
            category = .tops
            categorySource = "default"
        }
        
        print("🏷️ Final category: \(category.rawValue) from \(categorySource)")
        
        // Color: Use ML only if NOT "unknown" and confidence > 40%
        // Otherwise fall back to Vision color detection
        var primaryColor: String
        if let mlCol = mlColor, 
           mlCol.color.lowercased() != "unknown" && mlCol.confidence > 0.4 {
            primaryColor = mlCol.color
            print("✅ Using ML color: \(mlCol.color) (\(String(format: "%.1f%%", mlCol.confidence * 100)))")
        } else {
            primaryColor = visionColors.first ?? "Gray"
            print("✅ Using Vision fallback color: \(primaryColor)")
        }
        
        // Use ML brand if available with good confidence
        var detectedBrand = mlBrand?.brand ?? ""
        
        // Fallback: Try to find brand from OCR text
        if detectedBrand.isEmpty {
            let brandKeywords = ["AMI", "AMI PARIS", "Nike", "Adidas", "Prada", "Gucci", "Louis Vuitton", 
                               "Chanel", "Dior", "Balenciaga", "Versace", "Fendi", "Burberry",
                               "Zara", "H&M", "Uniqlo", "Gap", "Levi's", "Ralph Lauren", "Polo",
                               "Supreme", "Palace", "Stone Island", "Carhartt", "Dickies"]
            
            for text in texts {
                let cleanText = text.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                for brand in brandKeywords {
                    if cleanText.contains(brand.uppercased()) {
                        detectedBrand = brand
                        break
                    }
                }
                if !detectedBrand.isEmpty { break }
            }
        }
        
        // Last resort: CLIP brand
        if detectedBrand.isEmpty, let clip = clipResult {
            detectedBrand = clip.likelyBrand
        }
        
        // Build item name: [Color] [Type]
        var nameParts: [String] = []
        
        // Add color
        nameParts.append(primaryColor)
        
        // Add specific item type from category or CLIP
        var itemType = category.rawValue.capitalized
        if let clip = clipResult {
            let itemLower = clip.detectedItem.lowercased()
            if itemLower.contains("polo") {
                itemType = "Polo"
            } else if itemLower.contains("t-shirt") || itemLower.contains("tee") {
                itemType = "T-Shirt"
            } else if itemLower.contains("hoodie") {
                itemType = "Hoodie"
            } else if itemLower.contains("sweater") || itemLower.contains("knit") {
                itemType = "Sweater"
            } else if itemLower.contains("jacket") {
                itemType = "Jacket"
            } else if itemLower.contains("jeans") {
                itemType = "Jeans"
            } else if itemLower.contains("sneaker") || itemLower.contains("trainer") {
                itemType = "Sneakers"
            }
        }
        
        nameParts.append(itemType)
        
        let itemName = nameParts.joined(separator: " ")
        
        // Generate description
        var description = ""
        
        if !detectedBrand.isEmpty {
            description = "\(detectedBrand) \(itemName.lowercased()). "
        } else {
            description = "\(itemName). "
        }
        
        // Add material info if available
        if let clip = clipResult, !clip.materials.isEmpty {
            description += "Made from \(clip.materials[0].lowercased()). "
        }
        
        // Add condition
        if let clip = clipResult {
            switch clip.estimatedCondition {
            case .new:
                description += "Brand new with tags. "
            case .likeNew:
                description += "In like-new condition, barely worn. "
            case .excellent:
                description += "Excellent pre-owned condition. "
            case .good:
                description += "Good condition with minimal wear. "
            case .fair:
                description += "Fair condition with some signs of use. "
            }
        }
        
        description += "Perfect for \(category == .tops ? "casual styling" : category == .outerwear ? "layering" : category == .shoes ? "everyday wear" : "your wardrobe")."
        
        // Calculate overall confidence (average of ML predictions)
        var confidences: [Double] = []
        if let catConf = mlCategory?.confidence { confidences.append(catConf) }
        if let colConf = mlColor?.confidence { confidences.append(colConf) }
        if let brandConf = mlBrand?.confidence { confidences.append(brandConf) }
        let avgConfidence = confidences.isEmpty ? 0.5 : confidences.reduce(0, +) / Double(confidences.count)
        
        return ItemAnalysisResult(
            suggestedName: itemName,
            suggestedBrand: detectedBrand,
            suggestedCategory: category,
            suggestedCondition: clipResult?.estimatedCondition ?? .excellent,
            suggestedSize: clipResult?.estimatedSize ?? "M",
            suggestedDescription: description,
            detectedColors: [primaryColor],
            detectedMaterials: clipResult?.materials ?? [],
            suggestedPrice: clipResult?.estimatedPrice,
            confidence: avgConfidence
        )
    }
    
    // MARK: - Enhanced Description Generation
    
    /// Generate a professional product description using backend AI
    func generateEnhancedDescription(
        image: UIImage,
        category: String,
        brand: String,
        colors: [String],
        condition: Condition,
        materials: [String],
        size: String
    ) async -> (description: String, confidence: Double) {
        
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            return ("Unable to process image", 0.0)
        }
        let base64Image = imageData.base64EncodedString()
        
        // Prepare request payload
        let payload: [String: Any] = [
            "image": base64Image,
            "category": category,
            "brand": brand,
            "colors": colors,
            "condition": condition.rawValue,
            "materials": materials,
            "size": size
        ]
        
        do {
            // Call backend /generate_description endpoint
            let url = URL(string: "http://10.20.99.164:8000/generate_description")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            request.timeoutInterval = 30 // GPT-4 Vision can take time
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Description generation failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return fallbackDescription(category: category, brand: brand, colors: colors, materials: materials)
            }
            
            // Parse response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let description = json["description"] as? String,
               let confidence = json["confidence"] as? Double {
                
                let method = json["method"] as? String ?? "unknown"
                print("✅ Generated description using \(method): \(description.prefix(50))...")
                
                return (description, confidence)
            }
            
            return fallbackDescription(category: category, brand: brand, colors: colors, materials: materials)
            
        } catch {
            print("❌ Description generation error: \(error)")
            return fallbackDescription(category: category, brand: brand, colors: colors, materials: materials)
        }
    }
    
    /// Fallback description when backend is unavailable
    private func fallbackDescription(
        category: String,
        brand: String,
        colors: [String],
        materials: [String]
    ) -> (description: String, confidence: Double) {
        
        var parts: [String] = []
        
        if !brand.isEmpty && !colors.isEmpty {
            parts.append("\(colors.joined(separator: " ")) \(category.lowercased()) from \(brand).")
        } else if !colors.isEmpty {
            parts.append("\(colors.joined(separator: " ")) \(category.lowercased()).")
        } else if !brand.isEmpty {
            parts.append("\(brand) \(category.lowercased()).")
        } else {
            parts.append("Premium \(category.lowercased()).")
        }
        
        if !materials.isEmpty {
            parts.append("Made from \(materials.joined(separator: " and ")).")
        }
        
        parts.append("A versatile piece perfect for any wardrobe.")
        
        return (parts.joined(separator: " "), 0.6)
    }
}

// MARK: - Supporting Types

struct CLIPAnalysisResult: Codable {
    let detectedItem: String
    let likelyBrand: String
    let category: String
    let estimatedSize: String
    let estimatedCondition: Condition
    let description: String
    let colors: [String]
    let materials: [String]
    let estimatedPrice: Double?
    let confidence: Double
    
    enum CodingKeys: String, CodingKey {
        case detectedItem = "detected_item"
        case likelyBrand = "likely_brand"
        case category
        case estimatedSize = "estimated_size"
        case estimatedCondition = "estimated_condition"
        case description
        case colors
        case materials
        case estimatedPrice = "estimated_price"
        case confidence
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        detectedItem = try container.decode(String.self, forKey: .detectedItem)
        likelyBrand = try container.decode(String.self, forKey: .likelyBrand)
        category = try container.decode(String.self, forKey: .category)
        estimatedSize = try container.decode(String.self, forKey: .estimatedSize)
        description = try container.decode(String.self, forKey: .description)
        colors = try container.decode([String].self, forKey: .colors)
        materials = try container.decode([String].self, forKey: .materials)
        estimatedPrice = try? container.decode(Double.self, forKey: .estimatedPrice)
        confidence = try container.decode(Double.self, forKey: .confidence)
        
        // Parse condition string to enum
        if let conditionStr = try? container.decode(String.self, forKey: .estimatedCondition) {
            switch conditionStr.lowercased() {
            case "new with tags", "new":
                estimatedCondition = .new
            case "like new":
                estimatedCondition = .likeNew
            case "excellent":
                estimatedCondition = .excellent
            case "good":
                estimatedCondition = .good
            case "fair":
                estimatedCondition = .fair
            default:
                estimatedCondition = .excellent
            }
        } else {
            estimatedCondition = .excellent
        }
    }
}

// MARK: - CIImage Extension for Color Detection

extension CIImage {
    func averageColor() -> CIColor? {
        let extentVector = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: self, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        return CIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}

// MARK: - UIImage Extension for ML Models

extension UIImage {
    /// Convert UIImage to CVPixelBuffer for Core ML
    func pixelBuffer() -> CVPixelBuffer? {
        let width = Int(size.width)
        let height = Int(size.height)
        
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }
        
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
}
