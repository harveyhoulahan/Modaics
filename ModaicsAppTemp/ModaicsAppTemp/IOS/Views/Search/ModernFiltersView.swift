//
//  ModernFiltersView.swift
//  Modaics
//
//  Redesigned filters with dark green Porsche aesthetic
//

import SwiftUI

struct ModernFiltersView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var filters: SearchFilters
    
    @State private var tempFilters: SearchFilters
    
    init(filters: Binding<SearchFilters>) {
        self._filters = filters
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark green gradient background
                LinearGradient.forestBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Price Range Section
                        priceRangeSection
                        
                        Divider()
                            .background(.luxeGold.opacity(0.2))
                        
                        // Category Section
                        categorySection
                        
                        Divider()
                            .background(.luxeGold.opacity(0.2))
                        
                        // Condition Section
                        conditionSection
                        
                        Divider()
                            .background(.luxeGold.opacity(0.2))
                        
                        // Size Section
                        sizeSection
                        
                        Divider()
                            .background(.luxeGold.opacity(0.2))
                        
                        // Sustainability Section
                        sustainabilitySection
                        
                        Divider()
                            .background(.luxeGold.opacity(0.2))
                        
                        // Marketplace Section
                        marketplaceSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Bottom Action Bar
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        ModaicsSecondaryButton("Reset", icon: "arrow.counterclockwise") {
                            tempFilters = SearchFilters()
                        }
                        .frame(maxWidth: .infinity, maxHeight: 54)
                        
                        ModaicsPrimaryButton("Apply Filters", icon: "checkmark.circle.fill") {
                            filters = tempFilters
                            dismiss()
                        }
                        .frame(maxWidth: .infinity, maxHeight: 54)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.forestDeep.opacity(0.95), .forestRich.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .overlay(
                            Rectangle()
                                .fill(.luxeGold.opacity(0.1))
                                .frame(height: 1),
                            alignment: .top
                        )
                    )
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
                    Text("Filters")
                        .font(.forestDisplay(20))
                        .foregroundStyle(.luxeGoldGradient)
                }
            }
        }
    }
    
    // MARK: - Price Range Section
    
    private var priceRangeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.luxeGold)
                Text("Price Range")
                    .font(.forestHeadline(18))
                    .foregroundColor(.sageWhite)
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Min")
                        .font(.forestCaption(14))
                        .foregroundColor(.sageMuted)
                    
                    HStack {
                        Text("$")
                            .foregroundColor(.luxeGold)
                        TextField("0", value: $tempFilters.minPrice, format: .number)
                            .keyboardType(.numberPad)
                            .foregroundColor(.sageWhite)
                    }
                    .padding()
                    .background(.forestMid.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: ForestRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: ForestRadius.medium)
                            .stroke(.luxeGold.opacity(0.2), lineWidth: 1)
                    )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Max")
                        .font(.forestCaption(14))
                        .foregroundColor(.sageMuted)
                    
                    HStack {
                        Text("$")
                            .foregroundColor(.luxeGold)
                        TextField("999", value: $tempFilters.maxPrice, format: .number)
                            .keyboardType(.numberPad)
                            .foregroundColor(.sageWhite)
                    }
                    .padding()
                    .background(.forestMid.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: ForestRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: ForestRadius.medium)
                            .stroke(.luxeGold.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            // Quick price presets
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ModaicsChip("Under $25", isSelected: tempFilters.minPrice == 0 && tempFilters.maxPrice == 25) {
                        tempFilters.minPrice = 0
                        tempFilters.maxPrice = 25
                    }
                    ModaicsChip("$25-$50", isSelected: tempFilters.minPrice == 25 && tempFilters.maxPrice == 50) {
                        tempFilters.minPrice = 25
                        tempFilters.maxPrice = 50
                    }
                    ModaicsChip("$50-$100", isSelected: tempFilters.minPrice == 50 && tempFilters.maxPrice == 100) {
                        tempFilters.minPrice = 50
                        tempFilters.maxPrice = 100
                    }
                    ModaicsChip("$100+", isSelected: tempFilters.minPrice == 100 && tempFilters.maxPrice == 999) {
                        tempFilters.minPrice = 100
                        tempFilters.maxPrice = 999
                    }
                }
            }
        }
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "tshirt.fill")
                    .foregroundColor(.luxeGold)
                Text("Category")
                    .font(.forestHeadline(18))
                    .foregroundColor(.sageWhite)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(Category.allCases, id: \.self) { category in
                    ModaicsChip(
                        category.rawValue,
                        icon: iconForCategory(category),
                        isSelected: tempFilters.selectedCategories.contains(category)
                    ) {
                        toggleCategory(category)
                    }
                }
            }
        }
    }
    
    // MARK: - Condition Section
    
    private var conditionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.luxeGold)
                Text("Condition")
                    .font(.forestHeadline(18))
                    .foregroundColor(.sageWhite)
            }
            
            VStack(spacing: 10) {
                ForEach(Condition.allCases, id: \.self) { condition in
                    Button {
                        toggleCondition(condition)
                    } label: {
                        HStack {
                            Image(systemName: tempFilters.selectedConditions.contains(condition) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(tempFilters.selectedConditions.contains(condition) ? .luxeGold : .sageMuted)
                            
                            Text(condition.rawValue)
                                .font(.forestCaption(16))
                                .foregroundColor(.sageWhite)
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            tempFilters.selectedConditions.contains(condition)
                                ? .luxeGold.opacity(0.15)
                                : .forestMid.opacity(0.6)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ForestRadius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: ForestRadius.medium)
                                .stroke(
                                    tempFilters.selectedConditions.contains(condition)
                                        ? .luxeGold.opacity(0.4)
                                        : .luxeGold.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Size Section
    
    private var sizeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "ruler.fill")
                    .foregroundColor(.luxeGold)
                Text("Size")
                    .font(.forestHeadline(18))
                    .foregroundColor(.sageWhite)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(["XXS", "XS", "S", "M", "L", "XL", "XXL", "One Size"], id: \.self) { size in
                        ModaicsChip(
                            size,
                            isSelected: tempFilters.selectedSizes.contains(size)
                        ) {
                            toggleSize(size)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Sustainability Section
    
    private var sustainabilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.emerald)
                Text("Sustainability")
                    .font(.forestHeadline(18))
                    .foregroundColor(.sageWhite)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Minimum Score")
                        .font(.forestBody(16))
                        .foregroundColor(.sageMuted)
                    
                    Spacer()
                    
                    Text("\(Int(tempFilters.minSustainabilityScore))")
                        .font(.forestHeadline(18))
                        .foregroundColor(.luxeGold)
                }
                
                Slider(value: $tempFilters.minSustainabilityScore, in: 0...100, step: 10)
                    .tint(.emerald)
                
                HStack(spacing: 8) {
                    Image(systemName: "arrow.3.trianglepath")
                        .font(.caption)
                        .foregroundColor(.emerald)
                    Text("All items are secondhand and help reduce fashion waste")
                        .font(.forestCaption(13))
                        .foregroundColor(.sageMuted)
                }
                .padding(12)
                .background(.emerald.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    // MARK: - Marketplace Section
    
    private var marketplaceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundColor(.luxeGold)
                Text("Marketplace")
                    .font(.forestHeadline(18))
                    .foregroundColor(.sageWhite)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ModaicsChip(
                        "Depop",
                        icon: "bag.fill",
                        isSelected: tempFilters.selectedMarketplaces.contains("depop")
                    ) {
                        toggleMarketplace("depop")
                    }
                    
                    ModaicsChip(
                        "Grailed",
                        icon: "bag.fill",
                        isSelected: tempFilters.selectedMarketplaces.contains("grailed")
                    ) {
                        toggleMarketplace("grailed")
                    }
                    
                    ModaicsChip(
                        "Vinted",
                        icon: "bag.fill",
                        isSelected: tempFilters.selectedMarketplaces.contains("vinted")
                    ) {
                        toggleMarketplace("vinted")
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func iconForCategory(_ category: Category) -> String {
        switch category {
        case .tops: return "tshirt.fill"
        case .bottoms: return "rectangle.fill"
        case .dresses: return "person.fill"
        case .outerwear: return "jacket.fill"
        case .shoes: return "shoe.fill"
        case .accessories: return "bag.fill"
        @unknown default: return "tshirt.fill"
        }
    }
    
    private func toggleCategory(_ category: Category) {
        if tempFilters.selectedCategories.contains(category) {
            tempFilters.selectedCategories.remove(category)
        } else {
            tempFilters.selectedCategories.insert(category)
        }
    }
    
    private func toggleCondition(_ condition: Condition) {
        if tempFilters.selectedConditions.contains(condition) {
            tempFilters.selectedConditions.remove(condition)
        } else {
            tempFilters.selectedConditions.insert(condition)
        }
    }
    
    private func toggleSize(_ size: String) {
        if tempFilters.selectedSizes.contains(size) {
            tempFilters.selectedSizes.remove(size)
        } else {
            tempFilters.selectedSizes.insert(size)
        }
    }
    
    private func toggleMarketplace(_ marketplace: String) {
        if tempFilters.selectedMarketplaces.contains(marketplace) {
            tempFilters.selectedMarketplaces.remove(marketplace)
        } else {
            tempFilters.selectedMarketplaces.insert(marketplace)
        }
    }
}

// MARK: - Search Filters Model

struct SearchFilters {
    var minPrice: Int = 0
    var maxPrice: Int = 999
    var selectedCategories: Set<Category> = []
    var selectedConditions: Set<Condition> = []
    var selectedSizes: Set<String> = []
    var minSustainabilityScore: Double = 0.0
    var selectedMarketplaces: Set<String> = []
    
    var isActive: Bool {
        minPrice > 0 || maxPrice < 999 ||
        !selectedCategories.isEmpty ||
        !selectedConditions.isEmpty ||
        !selectedSizes.isEmpty ||
        minSustainabilityScore > 0 ||
        !selectedMarketplaces.isEmpty
    }
}

#Preview {
    ModernFiltersView(filters: .constant(SearchFilters()))
}
