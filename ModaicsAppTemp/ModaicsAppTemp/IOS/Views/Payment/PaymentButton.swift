//
//  PaymentButton.swift
//  ModaicsAppTemp
//
//  SwiftUI Payment Button Component
//  Supports: Card payments, Apple Pay, loading states
//

import SwiftUI
import StripePaymentSheet

struct PaymentButton: View {
    enum ButtonStyle {
        case primary
        case secondary
        case applePay
        case outline
    }
    
    let title: String
    let amount: Double
    let currency: String
    let style: ButtonStyle
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    init(
        title: String,
        amount: Double,
        currency: String = "USD",
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.amount = amount
        self.currency = currency
        self.style = style
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                }
                
                if style == .applePay {
                    Image(systemName: "applelogo")
                        .font(.body.weight(.semibold))
                    Text("Pay")
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                }
                
                if amount > 0 {
                    Text("•")
                        .foregroundColor(foregroundColor.opacity(0.6))
                    Text(formattedAmount)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundView)
            .foregroundColor(foregroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: style == .outline ? 2 : 0)
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [Color(hex: "1a1a1a"), Color(hex: "2d2d2d")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            Color(hex: "f5f5f5")
        case .applePay:
            Color.black
        case .outline:
            Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .applePay:
            return .white
        case .secondary:
            return Color(hex: "1a1a1a")
        case .outline:
            return Color(hex: "1a1a1a")
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .outline:
            return Color(hex: "1a1a1a")
        default:
            return .clear
        }
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

// MARK: - Apple Pay Button
struct ApplePayButton: View {
    let amount: Double
    let isLoading: Bool
    let action: () -> Void
    
    @StateObject private var paymentService = PaymentService.shared
    
    var body: some View {
        if paymentService.applePayAvailability == .available {
            Button(action: action) {
                HStack {
                    Image(systemName: "applelogo")
                        .font(.title3.weight(.semibold))
                    Text("Pay")
                        .font(.system(size: 19, weight: .semibold))
                    
                    Spacer()
                    
                    Text(formattedAmount)
                        .font(.system(size: 17, weight: .semibold))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isLoading)
        }
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

// MARK: - Payment Method Selector
struct PaymentMethodSelector: View {
    @Binding var selectedMethod: PaymentMethod
    let availableMethods: [PaymentMethod]
    
    enum PaymentMethod: String, CaseIterable, Identifiable {
        case card = "card"
        case applePay = "apple_pay"
        case savedCard = "saved_card"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .card:
                return "Credit or Debit Card"
            case .applePay:
                return "Apple Pay"
            case .savedCard:
                return "Saved Card"
            }
        }
        
        var icon: String {
            switch self {
            case .card:
                return "creditcard.fill"
            case .applePay:
                return "applelogo"
            case .savedCard:
                return "wallet.pass.fill"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Method")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(availableMethods) { method in
                    PaymentMethodRow(
                        method: method,
                        isSelected: selectedMethod == method
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedMethod = method
                        }
                    }
                }
            }
        }
    }
}

struct PaymentMethodRow: View {
    let method: PaymentMethodSelector.PaymentMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: method.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color(hex: "1a1a1a") : Color(hex: "f5f5f5"))
                    .cornerRadius(10)
                
                Text(method.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color(hex: "1a1a1a"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "fafafa"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "1a1a1a") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Fee Breakdown View
struct FeeBreakdownView: View {
    let itemPrice: Double
    let buyerFee: Double
    let total: Double
    let isInternational: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Order Summary")
                .font(.system(size: 17, weight: .semibold))
            
            VStack(spacing: 12) {
                FeeRow(label: "Item Price", amount: itemPrice, isBold: false)
                
                FeeRow(
                    label: isInternational ? "International Buyer Fee (3%)" : "Buyer Protection Fee (6%)",
                    amount: buyerFee,
                    isBold: false,
                    isFee: true
                )
                
                if isInternational {
                    HStack {
                        Image(systemName: "globe")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("International shipping discount applied")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
                
                Divider()
                
                FeeRow(label: "Total", amount: total, isBold: true)
            }
            .padding(16)
            .background(Color(hex: "fafafa"))
            .cornerRadius(12)
        }
    }
}

struct FeeRow: View {
    let label: String
    let amount: Double
    let isBold: Bool
    var isFee: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: isBold ? 17 : 15, weight: isBold ? .semibold : .regular))
                .foregroundColor(isFee ? .secondary : .primary)
            
            Spacer()
            
            Text(formattedAmount)
                .font(.system(size: isBold ? 17 : 15, weight: isBold ? .bold : .regular))
                .foregroundColor(isBold ? Color(hex: "1a1a1a") : .primary)
        }
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

// MARK: - Secure Payment Badge
struct SecurePaymentBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundColor(.green)
            
            Text("Secure payment via Stripe")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Stripe logo placeholder
            HStack(spacing: 2) {
                Circle()
                    .fill(Color(hex: "635bff"))
                    .frame(width: 8, height: 8)
                Text("Stripe")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
struct PaymentButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PaymentButton(
                title: "Buy Now",
                amount: 150.00,
                style: .primary
            ) {}
            
            PaymentButton(
                title: "Add to Cart",
                amount: 0,
                style: .secondary
            ) {}
            
            PaymentButton(
                title: "Pay",
                amount: 159.00,
                style: .applePay
            ) {}
            
            PaymentButton(
                title: "Save for Later",
                amount: 0,
                style: .outline
            ) {}
            
            FeeBreakdownView(
                itemPrice: 150.00,
                buyerFee: 9.00,
                total: 159.00,
                isInternational: false
            )
            
            SecurePaymentBadge()
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
