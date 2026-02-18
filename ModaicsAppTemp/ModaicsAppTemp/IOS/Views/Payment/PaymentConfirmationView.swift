//
//  PaymentConfirmationView.swift
//  ModaicsAppTemp
//
//  Post-payment confirmation screen with receipt details
//

import SwiftUI

struct PaymentConfirmationView: View {
    let transaction: Transaction
    let onDone: () -> Void
    let onViewOrder: (() -> Void)?
    
    @State private var showShareSheet = false
    @State private var receiptImage: UIImage?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Success Animation Header
                SuccessHeader(status: transaction.status)
                
                VStack(spacing: 24) {
                    // Amount Display
                    AmountDisplay(
                        amount: transaction.amount,
                        currency: transaction.currency,
                        status: transaction.status
                    )
                    
                    // Transaction Details Card
                    TransactionDetailsCard(transaction: transaction)
                    
                    // Item Details (if item purchase)
                    if let metadata = transaction.metadata,
                       let itemTitle = metadata.itemTitle {
                        ItemDetailsCard(
                            title: itemTitle,
                            imageUrl: metadata.itemImageUrl,
                            brandName: metadata.brandName
                        )
                    }
                    
                    // Actions
                    ActionButtons(
                        onShare: { showShareSheet = true },
                        onViewOrder: onViewOrder
                    )
                    
                    // Done Button
                    Button(action: onDone) {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "1a1a1a"))
                            .cornerRadius(12)
                    }
                }
                .padding(20)
            }
        }
        .background(Color(hex: "f8f8f8").ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            if let receiptImage = receiptImage {
                ShareSheet(activityItems: [receiptImage, "Modaics Receipt - \(transaction.id)"])
            }
        }
        .onAppear {
            generateReceiptImage()
        }
    }
    
    private func generateReceiptImage() {
        // Generate receipt image for sharing
        // Implementation would capture the view as an image
    }
}

// MARK: - Success Header
struct SuccessHeader: View {
    let status: Transaction.TransactionStatus
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor.opacity(0.1))
                .frame(width: 120, height: 120)
            
            Circle()
                .fill(backgroundColor.opacity(0.2))
                .frame(width: 90, height: 90)
            
            Image(systemName: iconName)
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(backgroundColor)
        }
        .padding(.top, 40)
        .padding(.bottom, 24)
        
        Text(titleText)
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.primary)
            .padding(.bottom, 8)
        
        Text(subtitleText)
            .font(.system(size: 15))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .completed:
            return .green
        case .pending, .processing:
            return .orange
        case .failed, .cancelled:
            return .red
        case .refunded:
            return .blue
        case .disputed:
            return .orange
        }
    }
    
    private var iconName: String {
        switch status {
        case .completed:
            return "checkmark.circle.fill"
        case .pending, .processing:
            return "clock.fill"
        case .failed:
            return "xmark.circle.fill"
        case .cancelled:
            return "xmark.circle.fill"
        case .refunded:
            return "arrow.uturn.backward.circle.fill"
        case .disputed:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var titleText: String {
        switch status {
        case .completed:
            return "Payment Successful!"
        case .pending:
            return "Payment Pending"
        case .processing:
            return "Processing..."
        case .failed:
            return "Payment Failed"
        case .cancelled:
            return "Payment Cancelled"
        case .refunded:
            return "Refund Processed"
        case .disputed:
            return "Under Review"
        }
    }
    
    private var subtitleText: String {
        switch status {
        case .completed:
            return "Your payment has been processed successfully. A receipt has been sent to your email."
        case .pending:
            return "Your payment is being processed. We'll notify you once it's complete."
        case .processing:
            return "Please wait while we process your payment..."
        case .failed:
            return "We couldn't process your payment. Please try again or use a different payment method."
        case .cancelled:
            return "Your payment was cancelled. No charges were made."
        case .refunded:
            return "Your refund has been processed. The funds will appear in your account within 5-10 business days."
        case .disputed:
            return "This transaction is under review. We'll contact you shortly with more information."
        }
    }
}

// MARK: - Amount Display
struct AmountDisplay: View {
    let amount: Double
    let currency: String
    let status: Transaction.TransactionStatus
    
    var body: some View {
        VStack(spacing: 8) {
            Text(formattedAmount)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.primary)
            
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.uppercased()
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    private var statusColor: Color {
        switch status {
        case .completed:
            return .green
        case .pending, .processing:
            return .orange
        case .failed, .cancelled:
            return .red
        case .refunded:
            return .blue
        case .disputed:
            return .orange
        }
    }
    
    private var statusText: String {
        switch status {
        case .completed:
            return "Paid"
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        case .refunded:
            return "Refunded"
        case .disputed:
            return "Under Review"
        }
    }
}

// MARK: - Transaction Details Card
struct TransactionDetailsCard: View {
    let transaction: Transaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transaction Details")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                DetailRow(label: "Transaction ID", value: transaction.id, isCopyable: true)
                DetailRow(label: "Date", value: formattedDate)
                DetailRow(label: "Payment Method", value: "•••• 4242 (Visa)")
                
                if let sellerId = transaction.sellerId {
                    DetailRow(label: "Seller", value: "@\(sellerId)")
                }
                
                Divider()
                
                DetailRow(label: "Subtotal", value: formatCurrency(transaction.sellerAmount))
                DetailRow(label: "Platform Fee", value: formatCurrency(transaction.platformFee))
                
                HStack {
                    Text("Total")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(formatCurrency(transaction.amount))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: transaction.createdAt)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = transaction.currency.uppercased()
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var isCopyable: Bool = false
    
    @State private var showCopiedToast = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            if isCopyable {
                Button(action: {
                    UIPasteboard.general.string = value
                    showCopiedToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showCopiedToast = false
                    }
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .overlay(
            Group {
                if showCopiedToast {
                    Text("Copied!")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            , alignment: .topTrailing
        )
    }
}

// MARK: - Item Details Card
struct ItemDetailsCard: View {
    let title: String
    let imageUrl: String?
    let brandName: String?
    
    var body: some View {
        HStack(spacing: 16) {
            // Item Image
            if let imageUrl = imageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 80, height: 80)
                .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "bag.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                if let brandName = brandName {
                    Text(brandName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text("Delivered by Modaics")
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

// MARK: - Action Buttons
struct ActionButtons: View {
    let onShare: () -> Void
    let onViewOrder: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onShare) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Receipt")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "1a1a1a"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "f0f0f0"))
                .cornerRadius(12)
            }
            
            if let onViewOrder = onViewOrder {
                Button(action: onViewOrder) {
                    HStack {
                        Image(systemName: "bag")
                        Text("View Order")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "1a1a1a"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "f0f0f0"))
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
struct PaymentConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentConfirmationView(
            transaction: Transaction(
                id: "txn_123456789",
                buyerId: "user_123",
                sellerId: "user_456",
                itemId: "item_789",
                amount: 159.00,
                currency: "USD",
                platformFee: 9.00,
                sellerAmount: 150.00,
                status: .completed,
                type: .itemPurchase,
                description: "Vintage Leather Jacket",
                createdAt: Date(),
                updatedAt: Date(),
                metadata: TransactionMetadata(
                    itemTitle: "Vintage Leather Jacket",
                    itemImageUrl: nil,
                    brandName: "Vintage Co.",
                    subscriptionTier: nil,
                    eventName: nil,
                    shippingAddress: nil
                )
            ),
            onDone: {},
            onViewOrder: {}
        )
    }
}
