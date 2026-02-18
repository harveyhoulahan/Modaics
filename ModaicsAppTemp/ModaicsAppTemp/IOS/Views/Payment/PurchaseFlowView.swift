//
//  PurchaseFlowView.swift
//  ModaicsAppTemp
//
//  Complete purchase flow for item buying
//  Includes: Item preview, shipping, payment, confirmation
//

import SwiftUI
import StripePaymentSheet

struct PurchaseFlowView: View {
    let item: ItemForPurchase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    
    @StateObject private var paymentService = PaymentService.shared
    @State private var currentStep: PurchaseStep = .review
    @State private var isInternational = false
    @State private var selectedShippingAddress: ShippingAddress?
    @State private var transaction: Transaction?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showConfirmation = false
    
    enum PurchaseStep: Int, CaseIterable {
        case review = 0
        case shipping = 1
        case payment = 2
        case confirmation = 3
        
        var title: String {
            switch self {
            case .review: return "Review"
            case .shipping: return "Shipping"
            case .payment: return "Payment"
            case .confirmation: return "Confirmation"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Stepper
                StepProgressView(currentStep: currentStep.rawValue, totalSteps: 3)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                // Content based on step
                TabView(selection: $currentStep) {
                    ReviewStepView(
                        item: item,
                        isInternational: $isInternational,
                        onContinue: { currentStep = .shipping }
                    )
                    .tag(PurchaseStep.review)
                    
                    ShippingStepView(
                        selectedAddress: $selectedShippingAddress,
                        onContinue: { currentStep = .payment },
                        onBack: { currentStep = .review }
                    )
                    .tag(PurchaseStep.shipping)
                    
                    PaymentStepView(
                        item: item,
                        isInternational: isInternational,
                        shippingAddress: selectedShippingAddress,
                        onComplete: { completedTransaction in
                            self.transaction = completedTransaction
                            self.showConfirmation = true
                        },
                        onBack: { currentStep = .shipping }
                    )
                    .tag(PurchaseStep.payment)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .disabled(paymentService.isLoading)
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showConfirmation) {
                if let transaction = transaction {
                    PaymentConfirmationView(
                        transaction: transaction,
                        onDone: {
                            dismiss()
                        },
                        onViewOrder: {
                            // Navigate to order details
                        }
                    )
                }
            }
            .alert("Payment Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Review Step
struct ReviewStepView: View {
    let item: ItemForPurchase
    @Binding var isInternational: Bool
    let onContinue: () -> Void
    
    @StateObject private var paymentService = PaymentService.shared
    
    var buyerFee: Double {
        paymentService.calculateBuyerFee(amount: item.price, isInternational: isInternational)
    }
    
    var total: Double {
        item.price + buyerFee
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Item Card
                ItemPreviewCard(item: item)
                
                // International Toggle
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("International Shipping", isOn: $isInternational)
                        .font(.system(size: 16, weight: .medium))
                    
                    if isInternational {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Lower buyer fee (3%) applies to international orders")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(Color(hex: "fafafa"))
                .cornerRadius(12)
                
                // Fee Breakdown
                FeeBreakdownView(
                    itemPrice: item.price,
                    buyerFee: buyerFee,
                    total: total,
                    isInternational: isInternational
                )
                
                Spacer()
                
                // Continue Button
                PaymentButton(
                    title: "Continue to Shipping",
                    amount: total,
                    style: .primary,
                    action: onContinue
                )
            }
            .padding(20)
        }
    }
}

// MARK: - Shipping Step
struct ShippingStepView: View {
    @Binding var selectedAddress: ShippingAddress?
    let onContinue: () -> Void
    let onBack: () -> Void
    
    @State private var addresses: [ShippingAddress] = []
    @State private var showAddAddress = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Saved Addresses
                if !addresses.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Saved Addresses")
                            .font(.system(size: 17, weight: .semibold))
                        
                        ForEach(addresses, id: \.self) { address in
                            AddressCard(
                                address: address,
                                isSelected: selectedAddress?.line1 == address.line1
                            ) {
                                selectedAddress = address
                            }
                        }
                    }
                }
                
                // Add New Address Button
                Button(action: { showAddAddress = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add New Address")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "1a1a1a"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "f0f0f0"))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Navigation Buttons
                HStack(spacing: 12) {
                    Button(action: onBack) {
                        Text("Back")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Color(hex: "1a1a1a"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "f0f0f0"))
                            .cornerRadius(12)
                    }
                    
                    Button(action: onContinue) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "1a1a1a"))
                            .cornerRadius(12)
                    }
                    .disabled(selectedAddress == nil)
                    .opacity(selectedAddress == nil ? 0.5 : 1.0)
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $showAddAddress) {
            AddAddressView { newAddress in
                addresses.append(newAddress)
                selectedAddress = newAddress
                showAddAddress = false
            }
        }
        .onAppear {
            loadSavedAddresses()
        }
    }
    
    private func loadSavedAddresses() {
        // Load from UserDefaults or API
        // For demo, use empty array
        addresses = []
    }
}

// MARK: - Payment Step
struct PaymentStepView: View {
    let item: ItemForPurchase
    let isInternational: Bool
    let shippingAddress: ShippingAddress?
    let onComplete: (Transaction) -> Void
    let onBack: () -> Void
    
    @StateObject private var paymentService = PaymentService.shared
    @State private var selectedMethod: PaymentMethodSelector.PaymentMethod = .card
    @State private var showError = false
    @State private var errorMessage = ""
    
    var buyerFee: Double {
        paymentService.calculateBuyerFee(amount: item.price, isInternational: isInternational)
    }
    
    var total: Double {
        item.price + buyerFee
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Order Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Order Summary")
                        .font(.system(size: 17, weight: .semibold))
                    
                    HStack {
                        Text(item.title)
                            .font(.system(size: 15))
                            .lineLimit(1)
                        Spacer()
                        Text(paymentService.formatCurrency(item.price))
                            .font(.system(size: 15))
                    }
                    
                    HStack {
                        Text("Buyer Protection Fee")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(paymentService.formatCurrency(buyerFee))
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(.system(size: 17, weight: .semibold))
                        Spacer()
                        Text(paymentService.formatCurrency(total))
                            .font(.system(size: 20, weight: .bold))
                    }
                }
                .padding(16)
                .background(Color(hex: "fafafa"))
                .cornerRadius(12)
                
                // Payment Method
                PaymentMethodSelector(
                    selectedMethod: $selectedMethod,
                    availableMethods: [.card, .applePay]
                )
                
                // Security Badge
                SecurePaymentBadge()
                
                Spacer()
                
                // Pay Button
                VStack(spacing: 12) {
                    if selectedMethod == .applePay {
                        ApplePayButton(
                            amount: total,
                            isLoading: paymentService.isLoading,
                            action: processApplePay
                        )
                    }
                    
                    PaymentButton(
                        title: "Pay Now",
                        amount: total,
                        style: .primary,
                        isLoading: paymentService.isLoading,
                        action: processPayment
                    )
                    
                    Button(action: onBack) {
                        Text("Back")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
        }
        .alert("Payment Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func processPayment() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        Task {
            do {
                let transaction = try await paymentService.presentItemPurchaseSheet(
                    from: rootViewController,
                    itemId: item.id,
                    sellerId: item.sellerId,
                    amount: item.price,
                    itemTitle: item.title,
                    isInternational: isInternational
                )
                
                await MainActor.run {
                    onComplete(transaction)
                }
            } catch PaymentError.cancelled {
                // User cancelled, no action needed
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func processApplePay() {
        // Implement Apple Pay flow
    }
}

// MARK: - Supporting Views

struct ItemPreviewCard: View {
    let item: ItemForPurchase
    
    var body: some View {
        HStack(spacing: 16) {
            // Item Image
            if let imageUrl = item.imageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 100, height: 100)
                .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "bag.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                if let brand = item.brand {
                    Text(brand)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
                
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text("Size \(item.size)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(item.condition)
                    .font(.system(size: 13))
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

struct AddressCard: View {
    let address: ShippingAddress
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(address.name)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(address.line1)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    if let line2 = address.line2 {
                        Text(line2)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(address.city), \(address.state) \(address.postalCode)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text(address.country)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color(hex: "1a1a1a"))
                }
            }
            .padding(16)
            .background(isSelected ? Color(hex: "f0f0f0") : Color(hex: "fafafa"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "1a1a1a") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StepProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                HStack(spacing: 4) {
                    Circle()
                        .fill(step <= currentStep ? Color(hex: "1a1a1a") : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    if step < totalSteps - 1 {
                        Rectangle()
                            .fill(step < currentStep ? Color(hex: "1a1a1a") : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
        }
    }
}

struct AddAddressView: View {
    let onSave: (ShippingAddress) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var line1 = ""
    @State private var line2 = ""
    @State private var city = ""
    @State private var state = ""
    @State private var postalCode = ""
    @State private var country = "US"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Contact")) {
                    TextField("Full Name", text: $name)
                }
                
                Section(header: Text("Address")) {
                    TextField("Street Address", text: $line1)
                    TextField("Apt, Suite, etc. (Optional)", text: $line2)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP Code", text: $postalCode)
                    TextField("Country", text: $country)
                }
            }
            .navigationTitle("Add Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let address = ShippingAddress(
                            name: name,
                            line1: line1,
                            line2: line2.isEmpty ? nil : line2,
                            city: city,
                            state: state,
                            postalCode: postalCode,
                            country: country
                        )
                        onSave(address)
                    }
                    .disabled(name.isEmpty || line1.isEmpty || city.isEmpty || state.isEmpty || postalCode.isEmpty)
                }
            }
        }
    }
}

// MARK: - Data Models

struct ItemForPurchase: Identifiable {
    let id: String
    let title: String
    let price: Double
    let brand: String?
    let size: String
    let condition: String
    let imageUrl: String?
    let sellerId: String
    let sellerName: String
}

// MARK: - Preview
struct PurchaseFlowView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseFlowView(item: ItemForPurchase(
            id: "item_123",
            title: "Vintage Leather Jacket",
            price: 150.00,
            brand: "Vintage Co.",
            size: "M",
            condition: "Excellent",
            imageUrl: nil,
            sellerId: "user_456",
            sellerName: "@vintage_seller"
        ))
    }
}
