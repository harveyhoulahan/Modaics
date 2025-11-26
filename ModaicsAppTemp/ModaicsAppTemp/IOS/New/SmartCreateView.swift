//
//  SmartCreateView.swift
//  Modaics
//
//  AI-powered sell flow with automatic item detection
//

import SwiftUI

struct SmartCreateView: View {
    let userType: ContentView.UserType
    @EnvironmentObject var viewModel: FashionViewModel
    @Environment(\.dismiss) var dismiss
    
    // Image Selection
    @State private var showImagePicker = false
    @State private var selectedImages: [UIImage] = []
    
    // AI Analysis State
    @State private var isAnalyzing = false
    @State private var hasAnalyzed = false
    @State private var analysisProgress: Double = 0.0
    
    // Item Details (AI-populated)
    @State private var itemName = ""
    @State private var brand = ""
    @State private var originalPrice = ""
    @State private var listingPrice = ""
    @State private var description = ""
    @State private var selectedCategory: Category = .tops
    @State private var selectedCondition: Condition = .excellent
    @State private var selectedSize = "M"
    @State private var detectedColors: [String] = []
    @State private var detectedMaterials: [String] = []
    
    // UI State
    @State private var showSuccessAnimation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.modaicsDarkBlue, .modaicsMidBlue],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Image Upload Section
                        imageUploadSection
                        
                        // AI Analysis Status
                        if isAnalyzing {
                            aiAnalysisLoadingView
                        } else if hasAnalyzed {
                            aiConfidenceBadge
                        }
                        
                        // Auto-filled Details
                        if hasAnalyzed {
                            VStack(spacing: 20) {
                                itemDetailsSection
                                pricingSection
                                descriptionSection
                                sustainabilitySection
                                
                                // Submit Button
                                ModaicsPrimaryButton(
                                    "List Item",
                                    icon: "checkmark.circle.fill",
                                    isEnabled: isFormValid
                                ) {
                                    createListing()
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ModaicsIconButton(icon: "xmark") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Smart Sell")
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.modaicsChrome1, .modaicsChrome2],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(images: $selectedImages)
        }
        .onChange(of: selectedImages) { oldValue, newValue in
            if !newValue.isEmpty && !hasAnalyzed {
                Task {
                    await performAIAnalysis()
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(hasAnalyzed ? "Review AI Analysis" : "Upload Photos to Get Started")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.modaicsCotton)
                .multilineTextAlignment(.center)
            
            if !hasAnalyzed {
                Text("Our AI will automatically detect item details")
                    .font(.system(size: 14))
                    .foregroundColor(.modaicsCottonLight)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Image Upload Section
    
    private var imageUploadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundColor(.modaicsChrome1)
                Text("Photos")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modaicsCotton)
                Spacer()
                if !selectedImages.isEmpty {
                    Text("\(selectedImages.count) photo\(selectedImages.count == 1 ? "" : "s")")
                        .font(.system(size: 14))
                        .foregroundColor(.modaicsCottonLight)
                }
            }
            
            if selectedImages.isEmpty {
                Button(action: { showImagePicker = true }) {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.modaicsChrome1, .modaicsChrome2],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(spacing: 6) {
                            Text("Add Photos")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.modaicsCotton)
                            Text("AI will analyze your item")
                                .font(.system(size: 14))
                                .foregroundColor(.modaicsCottonLight)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 240)
                    .background(Color.modaicsDarkBlue.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.modaicsChrome1.opacity(0.3), .modaicsChrome2.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(selectedImages.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                
                                // Remove button
                                Button {
                                    withAnimation {
                                        selectedImages.remove(at: index)
                                        if selectedImages.isEmpty {
                                            hasAnalyzed = false
                                        }
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.modaicsCotton)
                                        .background(Circle().fill(Color.modaicsDarkBlue))
                                }
                                .padding(8)
                            }
                        }
                        
                        // Add more button
                        Button(action: { showImagePicker = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.modaicsChrome1)
                                Text("Add More")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.modaicsCottonLight)
                            }
                            .frame(width: 140, height: 180)
                            .background(Color.modaicsDarkBlue.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.modaicsChrome1.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - AI Analysis Loading
    
    private var aiAnalysisLoadingView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ProgressView()
                    .tint(.modaicsChrome1)
                Text("AI is analyzing your item...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.modaicsCotton)
            }
            
            ProgressView(value: analysisProgress)
                .tint(.modaicsChrome1)
                .background(Color.modaicsDarkBlue.opacity(0.3))
                .clipShape(Capsule())
        }
        .padding(20)
        .background(Color.modaicsDarkBlue.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var aiConfidenceBadge: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(
                    LinearGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Analysis Complete")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modaicsCotton)
                if let confidence = VisionAnalysisService.shared.analysisResult?.confidence {
                    Text("\(Int(confidence * 100))% confidence")
                        .font(.system(size: 14))
                        .foregroundColor(.modaicsCottonLight)
                }
            }
            
            Spacer()
            
            ModaicsSecondaryButton("Re-analyze", icon: "arrow.clockwise") {
                Task {
                    await performAIAnalysis()
                }
            }
        }
        .padding(16)
        .background(Color.modaicsDarkBlue.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.modaicsChrome1.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Item Details Section
    
    private var itemDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(.modaicsChrome1)
                Text("Item Details")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modaicsCotton)
            }
            
            ModaicsTextField(label: "", placeholder: "Item Name", text: $itemName, icon: "tshirt.fill")
            ModaicsTextField(label: "", placeholder: "Brand", text: $brand, icon: "bag.fill")
            
            // Category chips
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsCottonLight)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Category.allCases, id: \.self) { category in
                            ModaicsChip(
                                category.rawValue,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
            
            // Size chips
            VStack(alignment: .leading, spacing: 8) {
                Text("Size")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsCottonLight)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["XS", "S", "M", "L", "XL", "XXL"], id: \.self) { size in
                            ModaicsChip(
                                size,
                                isSelected: selectedSize == size
                            ) {
                                selectedSize = size
                            }
                        }
                    }
                }
            }
            
            // Condition chips
            VStack(alignment: .leading, spacing: 8) {
                Text("Condition")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsCottonLight)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Condition.allCases, id: \.self) { condition in
                            ModaicsChip(
                                condition.rawValue,
                                isSelected: selectedCondition == condition
                            ) {
                                selectedCondition = condition
                            }
                        }
                    }
                }
            }
            
            // Detected colors & materials
            if !detectedColors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Colors")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.modaicsCottonLight)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(detectedColors, id: \.self) { color in
                                Text(color)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.modaicsCotton)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.modaicsDarkBlue.opacity(0.6))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Pricing Section
    
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.modaicsChrome1)
                Text("Pricing")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modaicsCotton)
            }
            
            HStack(spacing: 12) {
                ModaicsTextField(
                    label: "Original Price",
                    placeholder: "$0",
                    text: $originalPrice,
                    icon: "tag",
                    keyboardType: .decimalPad
                )
                
                ModaicsTextField(
                    label: "Your Price",
                    placeholder: "$0",
                    text: $listingPrice,
                    icon: "tag.fill",
                    keyboardType: .decimalPad
                )
            }
            
            if let original = Double(originalPrice.replacingOccurrences(of: "$", with: "")),
               let listing = Double(listingPrice.replacingOccurrences(of: "$", with: "")),
               original > listing {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)
                    Text("\(Int((original - listing) / original * 100))% off retail")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(12)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.modaicsChrome1)
                Text("Description")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modaicsCotton)
                
                Spacer()
                
                Button {
                    // Enhance description with AI
                    Task {
                        await enhanceDescription()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("Enhance")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.modaicsChrome1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.modaicsDarkBlue.opacity(0.6))
                    .clipShape(Capsule())
                }
            }
            
            ModaicsTextField(
                label: "",
                placeholder: "Describe your item...",
                text: $description,
                isMultiline: true
            )
        }
    }
    
    // MARK: - Sustainability Section
    
    private var sustainabilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("Sustainability")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modaicsCotton)
            }
            
            if !detectedMaterials.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Materials")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.modaicsCottonLight)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(detectedMaterials, id: \.self) { material in
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text(material)
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.modaicsCotton)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: "arrow.3.trianglepath")
                    .foregroundColor(.green)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Secondhand Marketplace")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.modaicsCotton)
                    Text("Help reduce fashion waste")
                        .font(.system(size: 12))
                        .foregroundColor(.modaicsCottonLight)
                }
                Spacer()
            }
            .padding(12)
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - AI Analysis Function
    
    private func performAIAnalysis() async {
        guard !selectedImages.isEmpty else { return }
        
        isAnalyzing = true
        hasAnalyzed = false
        
        // Simulate progress
        for progress in stride(from: 0.0, through: 0.9, by: 0.1) {
            analysisProgress = progress
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        // Perform actual AI analysis
        if let result = await VisionAnalysisService.shared.analyzeItem(images: selectedImages) {
            itemName = result.suggestedName
            brand = result.suggestedBrand
            selectedCategory = result.suggestedCategory
            selectedCondition = result.suggestedCondition
            selectedSize = result.suggestedSize
            description = result.suggestedDescription
            detectedColors = result.detectedColors
            detectedMaterials = result.detectedMaterials
            
            if let price = result.suggestedPrice {
                listingPrice = "$\(Int(price))"
                originalPrice = "$\(Int(price * 1.3))"
            }
        }
        
        analysisProgress = 1.0
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        isAnalyzing = false
        hasAnalyzed = true
    }
    
    private func enhanceDescription() async {
        guard let image = selectedImages.first else {
            print("❌ No image available for description enhancement")
            return
        }
        
        print("✨ Enhancing description with AI...")
        
        // Show loading state (you could add a @State variable for this)
        let (enhancedDesc, confidence) = await VisionAnalysisService.shared.generateEnhancedDescription(
            image: image,
            category: selectedCategory.rawValue,
            brand: brand,
            colors: detectedColors,
            condition: selectedCondition,
            materials: detectedMaterials,
            size: selectedSize
        )
        
        // Update description with AI-generated text
        description = enhancedDesc
        
        print("✅ Description enhanced with confidence: \(Int(confidence * 100))%")
    }
    
    private var isFormValid: Bool {
        !itemName.isEmpty && !brand.isEmpty && !listingPrice.isEmpty
    }
    
    private func createListing() {
        let item = FashionItem(
            name: itemName,
            brand: brand,
            category: selectedCategory,
            size: selectedSize,
            condition: selectedCondition,
            originalPrice: Double(originalPrice.replacingOccurrences(of: "$", with: "")) ?? 0,
            listingPrice: Double(listingPrice.replacingOccurrences(of: "$", with: "")) ?? 0,
            description: description,
            sustainabilityScore: SustainabilityScore(
                totalScore: 75,
                carbonFootprint: 3.5,
                waterUsage: 1500,
                isRecycled: true,
                isCertified: false,
                certifications: [],
                fibreTraceVerified: false
            ),
            location: viewModel.currentUser?.location ?? "Unknown",
            ownerId: viewModel.currentUser?.id.uuidString ?? ""
        )
        
        viewModel.createListing(item: item, images: selectedImages)
        showSuccessAnimation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}
