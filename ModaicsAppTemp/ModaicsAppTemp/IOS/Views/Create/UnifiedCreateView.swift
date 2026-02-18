//
//  UnifiedCreateView.swift
//  Modaics
//
//  Unified creation hub for items, events, workshops, and community posts
//

import SwiftUI
import PhotosUI

struct UnifiedCreateView: View {
    let userType: UserType
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
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.modaicsCotton)
                
                Text("Share with the community")
                    .font(.system(size: 14))
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
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .modaicsChrome1 : .modaicsChrome1.opacity(0.7))
                    
                    Text(type.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isSelected ? .modaicsCotton : .modaicsCottonLight)
                }
                
                Text(type.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.modaicsCottonLight)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(width: 200, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.modaicsChrome1.opacity(0.2) : Color.modaicsSurface2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
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
    let userType: UserType
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
                    HStack {
                        if isAnalyzing {
                            ProgressView()
                                .tint(.modaicsDarkBlue)
                            Text("Analyzing...")
                        } else {
                            Image(systemName: "wand.and.stars")
                            Text("Analyze with AI")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.modaicsDarkBlue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.modaicsChrome1, .modaicsChrome2],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(isAnalyzing)
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
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("List Item")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.modaicsDarkBlue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.modaicsChrome1, .modaicsChrome2],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
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
                Text("Photos")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.modaicsCotton)
                
                Spacer()
                
                // AI Status Indicator (like on Discover page)
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text(hasAnalyzed ? "Analyzed" : "AI Detection")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.modaicsCottonLight)
                }
            }
            
            if selectedImages.isEmpty {
                Button {
                    showImagePicker = true
                } label: {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.modaicsChrome1)
                        
                        Text("Add Photos")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.modaicsCotton)
                        
                        Text("AI will detect brand, color, and condition")
                            .font(.system(size: 12))
                            .foregroundColor(.modaicsCottonLight)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.modaicsDarkBlue.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                    .foregroundColor(.modaicsChrome1.opacity(0.3))
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
                                    .frame(width: 120, height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Button {
                                    selectedImages.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                        .font(.title3)
                                }
                                .padding(8)
                            }
                        }
                        
                        Button {
                            showImagePicker = true
                        } label: {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.modaicsChrome1)
                            }
                            .frame(width: 120, height: 160)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.modaicsDarkBlue.opacity(0.6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.modaicsChrome1.opacity(0.3), lineWidth: 2)
                                    )
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var formFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Item Name
            FormField(title: "Item Name", text: $itemName, placeholder: "e.g. Vintage Levi's 501")
            
            // Brand
            FormField(title: "Brand", text: $brand, placeholder: "e.g. Levi's")
            
            // Category & Size
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.modaicsCottonLight)
                    
                    Menu {
                        ForEach(Category.allCases, id: \.self) { cat in
                            Button(cat.rawValue) {
                                category = cat
                            }
                        }
                    } label: {
                        HStack {
                            Text(category.rawValue)
                                .foregroundColor(.modaicsCotton)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.modaicsCottonLight)
                        }
                        .padding()
                        .background(Color.modaicsDarkBlue.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Size")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.modaicsCottonLight)
                    
                    Menu {
                        ForEach(["XS", "S", "M", "L", "XL", "XXL"], id: \.self) { s in
                            Button(s) {
                                size = s
                            }
                        }
                    } label: {
                        HStack {
                            Text(size)
                                .foregroundColor(.modaicsCotton)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.modaicsCottonLight)
                        }
                        .padding()
                        .background(Color.modaicsDarkBlue.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            
            // Condition
            VStack(alignment: .leading, spacing: 8) {
                Text("Condition")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsCottonLight)
                
                Menu {
                    ForEach(Condition.allCases, id: \.self) { cond in
                        Button(cond.rawValue) {
                            condition = cond
                        }
                    }
                } label: {
                    HStack {
                        Text(condition.rawValue)
                            .foregroundColor(.modaicsCotton)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.modaicsCottonLight)
                    }
                    .padding()
                    .background(Color.modaicsDarkBlue.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Pricing
            HStack(spacing: 12) {
                FormField(title: "Original Price", text: $originalPrice, placeholder: "$0")
                    .keyboardType(.decimalPad)
                
                FormField(title: "List Price", text: $listingPrice, placeholder: "$0")
                    .keyboardType(.decimalPad)
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Description")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.modaicsCottonLight)
                    
                    Spacer()
                    
                    Text("Optional")
                        .font(.caption)
                        .foregroundColor(.modaicsCottonLight.opacity(0.6))
                }
                
                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .padding(12)
                    .foregroundColor(.modaicsCotton)
                    .scrollContentBackground(.hidden)
                    .background(Color.modaicsDarkBlue.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
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
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.modaicsCottonLight)
            
            TextField(placeholder, text: $text)
                .padding(14)
                .foregroundColor(.modaicsCotton)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.modaicsDarkBlue.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.modaicsChrome1.opacity(0.1), lineWidth: 1)
                        )
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
            // Section Header
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 16))
                        .foregroundColor(.modaicsChrome1)
                    
                    Text("Event Details")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.modaicsCotton)
                }
                
                Text("Create an event for the community to join")
                    .font(.system(size: 13))
                    .foregroundColor(.modaicsCottonLight)
            }
            .padding(.bottom, 4)
            
            FormField(title: "Event Name", text: $eventName, placeholder: "e.g. Fitzroy Vintage Market")
            
            // Event Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Event Type")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsCottonLight)
                
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
                    HStack {
                        Image(systemName: eventType.icon)
                            .foregroundColor(.modaicsChrome1)
                        Text(eventType.rawValue)
                            .foregroundColor(.modaicsCotton)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.modaicsCottonLight)
                    }
                    .padding()
                    .background(Color.modaicsDarkBlue.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Submit
            Button {
                createEvent()
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Create Event")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.modaicsDarkBlue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
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
            // Section Header
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.modaicsChrome1)
                    
                    Text("Workshop Details")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.modaicsCotton)
                }
                
                Text("Share your skills with the community")
                    .font(.system(size: 13))
                    .foregroundColor(.modaicsCottonLight)
            }
            .padding(.bottom, 4)
            
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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Submit
            Button {
                createWorkshop()
            } label: {
                HStack {
                    Image(systemName: "hammer.fill")
                    Text("Create Workshop")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.modaicsDarkBlue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
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
            // Section Header
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16))
                        .foregroundColor(.modaicsChrome1)
                    
                    Text("Community Post")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.modaicsCotton)
                }
                
                Text("Share tips, finds, or inspiration")
                    .font(.system(size: 13))
                    .foregroundColor(.modaicsCottonLight)
            }
            .padding(.bottom, 4)
            
            // Post Content
            VStack(alignment: .leading, spacing: 8) {
                Text("What's on your mind?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.modaicsCottonLight)
                
                TextEditor(text: $postContent)
                    .frame(minHeight: 150)
                    .padding(12)
                    .foregroundColor(.modaicsCotton)
                    .scrollContentBackground(.hidden)
                    .background(Color.modaicsDarkBlue.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Add Images
            if selectedImages.isEmpty {
                Button {
                    showImagePicker = true
                } label: {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Add Photos (Optional)")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.modaicsChrome1)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.modaicsDarkBlue.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Button {
                                    selectedImages.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .padding(4)
                            }
                        }
                        
                        Button {
                            showImagePicker = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(.modaicsChrome1)
                                .frame(width: 100, height: 100)
                                .background(Color.modaicsDarkBlue.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            
            // Submit
            Button {
                createPost()
            } label: {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("Share Post")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.modaicsDarkBlue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
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

