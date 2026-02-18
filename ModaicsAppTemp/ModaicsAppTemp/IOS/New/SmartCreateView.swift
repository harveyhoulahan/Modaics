//
//  SmartCreateView.swift
//  Modaics
//
//  AI-powered sell flow with automatic item detection
//  Dark Green Porsche Aesthetic
//

import SwiftUI

struct SmartCreateView: View {
    let userType: UserType
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
                // Dark green gradient background
                LinearGradient.forestBackground
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
                        .font(.forestDisplay(20))
                        .foregroundStyle(.luxeGoldGradient)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(images: $selectedImages)
        }
        .onChange(of: selectedImages) { oldValue, newValue in
            if oldValue.isEmpty && !newValue.isEmpty && !hasAnalyzed {
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
                .foregroundStyle(.luxeGoldGradient)
            
            Text(hasAnalyzed ? "Review AI Analysis" : "Upload Photos to Get Started")
                .font(.forestHeadline(18))
                .foregroundColor(.sageWhite)
                .multilineTextAlignment(.center)
            
            if !hasAnalyzed {
                Text("Our AI will automatically detect item details")
                    .font(.forestCaption(14))
                    .foregroundColor(.sageMuted)
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
                    .foregroundColor(.luxeGold)
                Text("Photos")
                    .font(.forestHeadline(16))
                    .foregroundColor(.sageWhite)
                Spacer()
                if !selectedImages.isEmpty {
                    Text("\(selectedImages.count) photo\(selectedImages.count == 1 ? "" : "s")")
                        .font(.forestBody(14))
                        .foregroundColor(.sageMuted)
                }
            }
            
            if selectedImages.isEmpty {
                Button(action: { showImagePicker = true }) {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.luxeGoldGradient)
                        
                        VStack(spacing: 6) {
                            Text("Add Photos")
                                .font(.forestHeadline(18))
                                .foregroundColor(.sageWhite)
                            Text("AI will analyze your item")
                                .font(.forestCaption(14))
                                .foregroundColor(.sageMuted)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 240)
                    .background(.forestMid.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: ForestRadius.xlarge))
                    .overlay(
                        RoundedRectangle(cornerRadius: ForestRadius.xlarge)
                            .stroke(.luxeGoldGradient, lineWidth: 2)
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
                                    .clipShape(RoundedRectangle(cornerRadius: ForestRadius.large))
                                
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
                                        .foregroundColor(.sageWhite)
                                        .background(Circle().fill(.forestDeep))
                                }
                                .padding(8)
                            }
                        }
                        
                        // Add more button
                        Button(action: { showImagePicker = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.luxeGold)
                                Text("Add More")
                                    .font(.forestCaption(12))
                                    .foregroundColor(.sageMuted)
                            }
                            .frame(width: 140, height: 180)
                            .background(.forestMid.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: ForestRadius.large))
                            .overlay(
                                RoundedRectangle(cornerRadius: ForestRadius.large)
                                    .stroke(.luxeGold.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
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
                    .tint(.luxeGold)
                Text("AI is analyzing your item...")
                    .font(.forestHeadline(16))
                    .foregroundColor(.sageWhite)
            }
            
            ProgressView(value: analysisProgress)
                .tint(.luxeGold)
                .background(.forestMid.opacity(0.3))
                .clipShape(Capsule())
        }
        .padding(20)
        .background(.forestMid.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: ForestRadius.large))
    }
    
    private var aiConfidenceBadge: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.luxeGoldGradient)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Analysis Complete")
                    .font(.forestHeadline(16))
                    .foregroundColor(.sageWhite)
                if let confidence = VisionAnalysisService.shared.analysisResult?.confidence {
                    Text("\(Int(confidence * 100))% confidence")
                        .font(.forestBody(14))
                        .foregroundColor(.sageMuted)
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
        .background(.forestMid.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: ForestRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: ForestRadius.large)
                .stroke(.luxeGold.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Item Details Section
    
    private var itemDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(.luxeGold)
                Text("Item Details")
                    .font(.forestHeadline(16))
                    .foregroundColor(.sageWhite)
            }
            
            ModaicsTextField(label: "", placeholder: "Item Name", text: $itemName, icon: "tshirt.fill")
            ModaicsTextField(label: "", placeholder: "Brand", text: $brand, icon: "bag.fill")
            
            // Category chips
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.forestCaption(14))
                    .foregroundColor(.sageMuted)
                
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
                    .font(.forestCaption(14))
                    .foregroundColor(.sageMuted)
                
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
                    .font(.forestCaption(14))
                    .foregroundColor(.sageMuted)
                
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
                        .font(.forestCaption(14))
                        .foregroundColor(.sageMuted)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(detectedColors, id: \.self) { color in
                                Text(color)
                                    .font(.forestCaption(13))
                                    .foregroundColor(.sageWhite)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.forestMid.opacity(0.6))
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
                    .foregroundColor(.luxeGold)
                Text("Pricing")
                    .font(.forestHeadline(16))
                    .foregroundColor(.sageWhite)
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
                        .foregroundColor(.emerald)
                    Text("\(Int((original - listing) / original * 100))% off retail")
                        .font(.forestCaption(14))
                        .foregroundColor(.emerald)
                }
                .padding(12)
                .background(.emerald.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.luxeGold)
                Text("Description")
                    .font(.forestHeadline(16))
                    .foregroundColor(.sageWhite)
                
                Text("(Optional)")
                    .font(.forestCaption(12))
                    .foregroundColor(.sageMuted)
                
                Spacer()
            }
            
            ModaicsTextField(
                label: "",
                placeholder: "AI suggested description (edit as you like or write your own)",
                text: $description,
                isMultiline: true
            )
            
            // Show AI suggestion hint if description is populated
            if !description.isEmpty && hasAnalyzed {
                Text("💡 AI-generated. Feel free to edit or replace with your own description.")
                    .font(.forestCaption(12))
                    .foregroundColor(.sageMuted.opacity(0.8))
                    .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Sustainability Section
    
    private var sustainabilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.emerald)
                Text("Sustainability")
                    .font(.forestHeadline(16))
                    .foregroundColor(.sageWhite)
            }
            
            if !detectedMaterials.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Materials")
                        .font(.forestCaption(14))
                        .foregroundColor(.sageMuted)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(detectedMaterials, id: \.self) { material in
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.emerald)
                                    Text(material)
                                        .font(.forestCaption(13))
                                }
                                .foregroundColor(.sageWhite)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.emerald.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: "arrow.3.trianglepath")
                    .foregroundColor(.emerald)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Secondhand Marketplace")
                        .font(.forestCaption(14))
                        .foregroundColor(.sageWhite)
                    Text("Help reduce fashion waste")
                        .font(.forestCaption(12))
                        .foregroundColor(.sageMuted)
                }
                Spacer()
            }
            .padding(12)
            .background(.emerald.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: ForestRadius.medium))
        }
    }
    
    // MARK: - AI Analysis Function
    
    private func performAIAnalysis() async {
        guard !selectedImages.isEmpty else { return }
        guard !isAnalyzing else {
            print("⚠️ Analysis already in progress, skipping duplicate call")
            return
        }
        
        isAnalyzing = true
        hasAnalyzed = false
        
        print("🤖 Starting AI analysis for \(selectedImages.count) image(s)")
        
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

#Preview("Smart Create View") {
    SmartCreateView(userType: .consumer)
        .environmentObject(FashionViewModel())
}
