//
//  UnifiedCreateView.swift
//  Modaics
//
//  Unified creation hub for items, events, workshops, and community posts
//

import SwiftUI
import PhotosUI

struct UnifiedCreateView: View {
    let userType: ContentView.UserType
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var selectedCreationType: CreationType = .item
    
    enum CreationType: String, CaseIterable {
        case item = "List Item"
        case event = "Create Event"
        case workshop = "Host Workshop"
        case post = "Share Post"
        
        var icon: String {
            switch self {
            case .item: return "tag.fill"
            case .event: return "calendar.badge.plus"
            case .workshop: return "hammer.fill"
            case .post: return "square.and.pencil"
            }
        }
        
        var subtitle: String {
            switch self {
            case .item: return "Sell or swap with AI detection"
            case .event: return "Pop-ups, markets, meetups"
            case .workshop: return "Classes, repairs, skills"
            case .post: return "Tips, finds, inspiration"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient - matching community page
                LinearGradient(
                    colors: [.modaicsDarkBlue, .modaicsMidBlue],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Type Selector - MOVED TO TOP
                    typeSelector
                    
                    // Header
                    header
                    
                    // Content based on selection
                    ScrollView {
                        VStack(spacing: 24) {
                            switch selectedCreationType {
                            case .item:
                                CreateItemView(userType: userType)
                                    .environmentObject(viewModel)
                            case .event:
                                CreateEventView()
                                    .environmentObject(viewModel)
                            case .workshop:
                                CreateWorkshopView()
                                    .environmentObject(viewModel)
                            case .post:
                                CreatePostView()
                                    .environmentObject(viewModel)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100) // Extra padding for tab bar
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Create")
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCotton)
                
                Text("Share with the community")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCottonLight)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Type Selector
    
    private var typeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CreationType.allCases, id: \.self) { type in
                    TypeSelectorCard(
                        type: type,
                        isSelected: selectedCreationType == type
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCreationType = type
                        }
                        HapticManager.shared.impact(.light)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(Color.modaicsDarkBlue.opacity(0.6))
    }
}

// MARK: - Type Selector Card

struct TypeSelectorCard: View {
    let type: UnifiedCreateView.CreationType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: type.icon)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(isSelected ? .modaicsChrome1 : .modaicsChrome1.opacity(0.7))
                    
                    Text(type.rawValue)
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundColor(isSelected ? .modaicsCotton : .modaicsCottonLight)
                }
                
                Text(type.subtitle)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.modaicsCottonLight)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(width: 200, alignment: .leading)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.modaicsChrome1.opacity(0.2) : Color.modaicsSurface2)
                    .overlay(
                        Rectangle()
                            .stroke(
                                isSelected ? Color.modaicsChrome1.opacity(0.5) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Create Item View (AI-Powered)

struct CreateItemView: View {
    let userType: ContentView.UserType
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var showCamera = false
    
    // AI Analysis
    @State private var isAnalyzing = false
    @State private var hasAnalyzed = false
    
    // Form fields
    @State private var itemName = ""
    @State private var brand = ""
    @State private var category: Category = .tops
    @State private var size = "M"
    @State private var condition: Condition = .excellent
    @State private var originalPrice = ""
    @State private var listingPrice = ""
    @State private var description = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Image Upload
            imageSection
            
            // AI Analysis Button
            if !selectedImages.isEmpty && !hasAnalyzed {
                Button {
                    performAIAnalysis()
                } label: {
                    HStack(spacing: 8) {
                        if isAnalyzing {
                            ProgressView()
                                .tint(.white)
                            Text("ANALYZING...") 
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .tracking(1.2)
                        } else {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                            Text("ANALYZE WITH AI")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .tracking(1.2)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Rectangle()
                            .fill(Color.appRed)
                    )
                    .overlay(
                        Rectangle()
                            .stroke(Color.appRed.opacity(0.5), lineWidth: 1)
                    )
                }
                .disabled(isAnalyzing)
                
                // AI Info Card
                HStack(alignment: .top, spacing: 10) {
                    Rectangle()
                        .fill(Color.appRed.opacity(0.1))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(.appRed)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI AUTO-FILL")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .tracking(0.8)
                            .foregroundColor(.appTextMain)
                        
                        Text("Our AI will detect brand, category, color, and condition from your photos")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.appTextMuted)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(
                    Rectangle()
                        .fill(Color.appSurface)
                )
                .overlay(
                    Rectangle()
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            }
            
            // Form Fields
            if hasAnalyzed || !selectedImages.isEmpty {
                formFields
            }
            
            // Submit Button
            if isFormValid {
                Button {
                    createListing()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                        Text("LIST ITEM")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .tracking(1.5)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Rectangle()
                            .fill(Color.appRed)
                    )
                    .overlay(
                        Rectangle()
                            .stroke(Color.appRed.opacity(0.5), lineWidth: 1)
                    )
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(images: $selectedImages)
        }
    }
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("PHOTOS")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(.appTextMain)
                
                Spacer()
                
                // AI Status Indicator - industrial
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(hasAnalyzed ? Color.green : Color.appRed)
                        .frame(width: 6, height: 6)
                    
                    Text(hasAnalyzed ? "ANALYZED" : "AI DETECTION")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(0.5)
                        .foregroundColor(.appTextMuted)
                }
            }
            
            if selectedImages.isEmpty {
                Button {
                    showImagePicker = true
                } label: {
                    VStack(spacing: 16) {
                        Rectangle()
                            .fill(Color.appRed.opacity(0.1))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                                    .foregroundColor(.appRed)
                            )
                        
                        VStack(spacing: 6) {
                            Text("ADD PHOTOS")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .tracking(1.2)
                                .foregroundColor(.appTextMain)
                            
                            Text("AI will detect brand, color, and condition automatically")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.appTextMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(
                        Rectangle()
                            .fill(Color.appSurface)
                    )
                    .overlay(
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(.appBorder)
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
                                    .frame(width: 120, height: 160)
                                    .clipped()
                                
                                // Remove button - industrial
                                Button {
                                    selectedImages.remove(at: index)
                                } label: {
                                    Rectangle()
                                        .fill(Color.appRed)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Image(systemName: "xmark")
                                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                                .foregroundColor(.white)
                                        )
                                }
                                .padding(6)
                            }
                            .overlay(
                                Rectangle()
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                        }
                        
                        Button {
                            showImagePicker = true
                        } label: {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                                    .foregroundColor(.appTextMuted)
                            }
                            .frame(width: 120, height: 160)
                            .background(
                                Rectangle()
                                    .fill(Color.appSurface)
                            )
                            .overlay(
                                Rectangle()
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var formFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section divider
            HStack {
                Rectangle()
                    .fill(Color.appBorder)
                    .frame(height: 1)
                
                Text("DETAILS")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(.appTextMuted)
                    .padding(.horizontal, 8)
                
                Rectangle()
                    .fill(Color.appBorder)
                    .frame(height: 1)
            }
            .padding(.vertical, 8)
            
            // Item Name with counter
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("ITEM NAME")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(.appTextMuted)
                    
                    Spacer()
                    
                    Text("\(itemName.count)/50")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.appTextMuted.opacity(0.6))
                }
                
                TextField("e.g. Vintage Levi's 501 Jeans", text: $itemName)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.appTextMain)
                    .padding(14)
                    .background(
                        Rectangle()
                            .fill(Color.appSurface)
                    )
                    .overlay(
                        Rectangle()
                            .stroke(itemName.isEmpty ? Color.appBorder : Color.appRed.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Brand with icon
            VStack(alignment: .leading, spacing: 8) {
                Text("BRAND")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(0.8)
                    .foregroundColor(.appTextMuted)
                
                HStack(spacing: 10) {
                    Rectangle()
                        .fill(Color.appSurface)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(.appTextMuted)
                        )
                    
                    TextField("e.g. Levi's, Nike, Patagonia", text: $brand)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.appTextMain)
                }
                .padding(10)
                .background(
                    Rectangle()
                        .fill(Color.appSurface)
                )
                .overlay(
                    Rectangle()
                        .stroke(brand.isEmpty ? Color.appBorder : Color.appRed.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Category & Size
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CATEGORY")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(.appTextMuted)
                    
                    Menu {
                        ForEach(Category.allCases, id: \.self) { cat in
                            Button(cat.rawValue) {
                                category = cat
                            }
                        }
                    } label: {
                        HStack {
                            Text(category.rawValue.uppercased())
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.appTextMain)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.appTextMuted)
                        }
                        .padding(12)
                        .background(
                            Rectangle()
                                .fill(Color.appSurface)
                        )
                        .overlay(
                            Rectangle()
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("SIZE")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(.appTextMuted)
                    
                    Menu {
                        ForEach(["XS", "S", "M", "L", "XL", "XXL"], id: \.self) { s in
                            Button(s) {
                                size = s
                            }
                        }
                    } label: {
                        HStack {
                            Text(size)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.appTextMain)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.appTextMuted)
                        }
                        .padding(12)
                        .background(
                            Rectangle()
                                .fill(Color.appSurface)
                        )
                        .overlay(
                            Rectangle()
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                    }
                }
            }
            
            // Condition with visual indicator
            VStack(alignment: .leading, spacing: 8) {
                Text("CONDITION")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(0.8)
                    .foregroundColor(.appTextMuted)
                
                Menu {
                    ForEach(Condition.allCases, id: \.self) { cond in
                        Button(cond.rawValue) {
                            condition = cond
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        // Condition quality indicator
                        Rectangle()
                            .fill(conditionColor(condition))
                            .frame(width: 4, height: 32)
                        
                        Text(condition.rawValue.uppercased())
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.appTextMain)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.appTextMuted)
                    }
                    .padding(12)
                    .background(
                        Rectangle()
                            .fill(Color.appSurface)
                    )
                    .overlay(
                        Rectangle()
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                }
            }
            
            // Pricing with calculator icon
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ORIGINAL PRICE")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(.appTextMuted)
                    
                    HStack(spacing: 8) {
                        Text("$")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.appTextMuted)
                        
                        TextField("0", text: $originalPrice)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.appTextMain)
                            .keyboardType(.decimalPad)
                    }
                    .padding(12)
                    .background(
                        Rectangle()
                            .fill(Color.appSurface)
                    )
                    .overlay(
                        Rectangle()
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("LIST PRICE")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(.appTextMuted)
                    
                    HStack(spacing: 8) {
                        Text("$")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.appRed)
                        
                        TextField("0", text: $listingPrice)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.appTextMain)
                            .keyboardType(.decimalPad)
                    }
                    .padding(12)
                    .background(
                        Rectangle()
                            .fill(Color.appSurface)
                    )
                    .overlay(
                        Rectangle()
                            .stroke(listingPrice.isEmpty ? Color.appBorder : Color.appRed.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("DESCRIPTION")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(.appTextMuted)
                    
                    Spacer()
                    
                    Text("OPTIONAL")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(0.5)
                        .foregroundColor(.appTextMuted.opacity(0.6))
                }
                
                ZStack(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("Describe the item's features, flaws, and story...")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.appTextMuted.opacity(0.5))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: $description)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.appTextMain)
                        .frame(minHeight: 100)
                        .padding(10)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                }
                .background(
                    Rectangle()
                        .fill(Color.appSurface)
                )
                .overlay(
                    Rectangle()
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            }
        }
    }
    
    private func conditionColor(_ condition: Condition) -> Color {
        switch condition {
        case .new, .likeNew:
            return Color.green
        case .excellent, .good:
            return Color.yellow
        case .fair:
            return Color.orange
        }
    }
    
    private var isFormValid: Bool {
        !itemName.isEmpty && !brand.isEmpty && !listingPrice.isEmpty
    }
    
    private func performAIAnalysis() {
        guard let firstImage = selectedImages.first else { return }
        
        isAnalyzing = true
        
        Task {
            do {
                // Call backend AI analysis
                let analysis = try await viewModel.analyzeItemImage(firstImage)
                
                await MainActor.run {
                    // Populate fields with AI results
                    brand = analysis.likelyBrand
                    itemName = analysis.detectedItem
                    description = analysis.description
                    
                    if let cat = Category.allCases.first(where: { $0.rawValue.lowercased() == analysis.category.lowercased() }) {
                        category = cat
                    }
                    
                    if let cond = Condition.allCases.first(where: { $0.rawValue.lowercased() == analysis.estimatedCondition.lowercased() }) {
                        condition = cond
                    }
                    
                    isAnalyzing = false
                    hasAnalyzed = true
                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    print("AI Analysis error: \(error)")
                }
            }
        }
    }
    
    private func createListing() {
        let item = FashionItem(
            name: itemName,
            brand: brand,
            category: category,
            size: size,
            condition: condition,
            originalPrice: Double(originalPrice) ?? 0,
            listingPrice: Double(listingPrice) ?? 0,
            description: description,
            sustainabilityScore: SustainabilityScore(
                totalScore: 75,
                carbonFootprint: 5.0,
                waterUsage: 2000,
                isRecycled: true,
                isCertified: false,
                certifications: [],
                fibreTraceVerified: false
            ),
            location: viewModel.currentUser?.location ?? "Melbourne",
            ownerId: viewModel.currentUser?.id.uuidString ?? ""
        )
        
        viewModel.createListing(item: item, images: selectedImages)
        HapticManager.shared.success()
    }
}

// MARK: - Form Field Helper

struct FormField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(0.8)
                .foregroundColor(.appTextMuted)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.appTextMain)
                .padding(14)
                .background(
                    Rectangle()
                        .fill(Color.appSurface)
                )
                .overlay(
                    Rectangle()
                        .stroke(text.isEmpty ? Color.appBorder : Color.appRed.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Create Event View

struct CreateEventView: View {
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var eventName = ""
    @State private var eventType: EventType = .popUp
    @State private var location = ""
    @State private var date = Date()
    @State private var description = ""
    @State private var capacity = "50"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header - industrial
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(Color.appRed.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(.appRed)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("EVENT DETAILS")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .tracking(1.2)
                        .foregroundColor(.appTextMain)
                    
                    Text("Create an event for the community to join")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.appTextMuted)
                }
            }
            .padding(16)
            .background(
                Rectangle()
                    .fill(Color.appSurface)
            )
            .overlay(
                Rectangle()
                    .stroke(Color.appBorder, lineWidth: 1)
            )
            
            FormField(title: "Event Name", text: $eventName, placeholder: "e.g. Fitzroy Vintage Market")
            
            // Event Type - industrial style
            VStack(alignment: .leading, spacing: 8) {
                Text("EVENT TYPE")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(0.8)
                    .foregroundColor(.appTextMuted)
                
                Menu {
                    ForEach(EventType.allCases, id: \.self) { type in
                        Button {
                            eventType = type
                        } label: {
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color.appRed.opacity(0.1))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: eventType.icon)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.appRed)
                            )
                        
                        Text(eventType.rawValue.uppercased())
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.appTextMain)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.appTextMuted)
                    }
                    .padding(12)
                    .background(
                        Rectangle()
                            .fill(Color.appSurface)
                    )
                    .overlay(
                        Rectangle()
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                }
            }
            
            FormField(title: "Location", text: $location, placeholder: "e.g. Federation Square")
            
            // Date Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Date & Time")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsCottonLight)
                
                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .padding()
                    .background(Color.modaicsDarkBlue.opacity(0.6))
                    .clipShape(Rectangle())
            }
            
            FormField(title: "Capacity", text: $capacity, placeholder: "50")
                .keyboardType(.numberPad)
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsCottonLight)
                
                TextEditor(text: $description)
                    .frame(minHeight: 120)
                    .padding(12)
                    .foregroundColor(.modaicsCotton)
                    .scrollContentBackground(.hidden)
                    .background(Color.modaicsDarkBlue.opacity(0.6))
                    .clipShape(Rectangle())
            }
            
            // Submit - industrial button
            Button {
                createEvent()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                    Text("CREATE EVENT")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .tracking(1.5)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Rectangle()
                        .fill(Color.appRed)
                )
                .overlay(
                    Rectangle()
                        .stroke(Color.appRed.opacity(0.5), lineWidth: 1)
                )
            }
            .disabled(eventName.isEmpty || location.isEmpty)
            .opacity(eventName.isEmpty || location.isEmpty ? 0.5 : 1)
        }
    }
    
    private func createEvent() {
        // TODO: Add to viewModel
        HapticManager.shared.success()
    }
}

// MARK: - Create Workshop View

struct CreateWorkshopView: View {
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var workshopName = ""
    @State private var instructor = ""
    @State private var skillLevel = "Beginner"
    @State private var duration = "2 hours"
    @State private var price = ""
    @State private var description = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header - industrial
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(Color.appRed.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(.appRed)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("WORKSHOP DETAILS")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .tracking(1.2)
                        .foregroundColor(.appTextMain)
                    
                    Text("Share your skills with the community")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.appTextMuted)
                }
            }
            .padding(16)
            .background(
                Rectangle()
                    .fill(Color.appSurface)
            )
            .overlay(
                Rectangle()
                    .stroke(Color.appBorder, lineWidth: 1)
            )
            
            FormField(title: "Workshop Name", text: $workshopName, placeholder: "e.g. Visible Mending Basics")
            FormField(title: "Instructor", text: $instructor, placeholder: "Your name")
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Skill Level")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.modaicsCottonLight)
                    
                    Menu {
                        ForEach(["Beginner", "Intermediate", "Advanced"], id: \.self) { level in
                            Button(level) {
                                skillLevel = level
                            }
                        }
                    } label: {
                        HStack {
                            Text(skillLevel)
                                .foregroundColor(.modaicsCotton)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.modaicsCottonLight)
                        }
                        .padding()
                        .background(Color.modaicsDarkBlue.opacity(0.6))
                        .clipShape(Rectangle())
                    }
                }
                
                FormField(title: "Duration", text: $duration, placeholder: "2 hours")
            }
            
            FormField(title: "Price", text: $price, placeholder: "$45")
                .keyboardType(.decimalPad)
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("What You'll Teach")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsCottonLight)
                
                TextEditor(text: $description)
                    .frame(minHeight: 120)
                    .padding(12)
                    .foregroundColor(.modaicsCotton)
                    .scrollContentBackground(.hidden)
                    .background(Color.modaicsDarkBlue.opacity(0.6))
                    .clipShape(Rectangle())
            }
            
            // Submit - industrial
            Button {
                createWorkshop()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                    Text("CREATE WORKSHOP")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .tracking(1.5)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Rectangle()
                        .fill(Color.appRed)
                )
                .overlay(
                    Rectangle()
                        .stroke(Color.appRed.opacity(0.5), lineWidth: 1)
                )
            }
            .disabled(workshopName.isEmpty || instructor.isEmpty)
            .opacity(workshopName.isEmpty || instructor.isEmpty ? 0.5 : 1)
        }
    }
    
    private func createWorkshop() {
        // TODO: Add to viewModel
        HapticManager.shared.success()
    }
}

// MARK: - Create Post View

struct CreatePostView: View {
    @EnvironmentObject var viewModel: FashionViewModel
    @State private var postContent = ""
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header - industrial
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(Color.appRed.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(.appRed)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("COMMUNITY POST")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .tracking(1.2)
                        .foregroundColor(.appTextMain)
                    
                    Text("Share tips, finds, or inspiration")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.appTextMuted)
                }
            }
            .padding(16)
            .background(
                Rectangle()
                    .fill(Color.appSurface)
            )
            .overlay(
                Rectangle()
                    .stroke(Color.appBorder, lineWidth: 1)
            )
            
            // Post Content
            VStack(alignment: .leading, spacing: 8) {
                Text("WHAT'S ON YOUR MIND?")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(0.8)
                    .foregroundColor(.appTextMuted)
                
                ZStack(alignment: .topLeading) {
                    if postContent.isEmpty {
                        Text("Share your thoughts, tips, or recent finds...")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.appTextMuted.opacity(0.5))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: $postContent)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.appTextMain)
                        .frame(minHeight: 150)
                        .padding(10)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                }
                .background(
                    Rectangle()
                        .fill(Color.appSurface)
                )
                .overlay(
                    Rectangle()
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            }
            
            // Add Images - industrial
            if selectedImages.isEmpty {
                Button {
                    showImagePicker = true
                } label: {
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(Color.appSurface)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.appTextMuted)
                            )
                        
                        Text("ADD PHOTOS")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .tracking(1.0)
                            .foregroundColor(.appTextMain)
                        
                        Spacer()
                        
                        Text("OPTIONAL")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .tracking(0.5)
                            .foregroundColor(.appTextMuted.opacity(0.6))
                    }
                    .padding(14)
                    .background(
                        Rectangle()
                            .fill(Color.appSurface)
                    )
                    .overlay(
                        Rectangle()
                            .stroke(Color.appBorder, lineWidth: 1)
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
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                
                                Button {
                                    selectedImages.remove(at: index)
                                } label: {
                                    Rectangle()
                                        .fill(Color.appRed)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Image(systemName: "xmark")
                                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                                .foregroundColor(.white)
                                        )
                                }
                                .padding(4)
                            }
                            .overlay(
                                Rectangle()
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                        }
                        
                        Button {
                            showImagePicker = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(.appTextMuted)
                                .frame(width: 100, height: 100)
                                .background(
                                    Rectangle()
                                        .fill(Color.appSurface)
                                )
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.appBorder, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            
            // Submit - industrial
            Button {
                createPost()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                    Text("SHARE POST")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .tracking(1.5)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Rectangle()
                        .fill(Color.appRed)
                )
                .overlay(
                    Rectangle()
                        .stroke(Color.appRed.opacity(0.5), lineWidth: 1)
                )
            }
            .disabled(postContent.isEmpty)
            .opacity(postContent.isEmpty ? 0.5 : 1)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(images: $selectedImages)
        }
    }
    
    private func createPost() {
        // TODO: Add to viewModel
        HapticManager.shared.success()
    }
}

