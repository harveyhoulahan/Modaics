//
//  TransactionHistoryView.swift
//  ModaicsAppTemp
//
//  Transaction history and wallet management
//

import SwiftUI

struct TransactionHistoryView: View {
    @StateObject private var paymentService = PaymentService.shared
    @State private var selectedFilter: TransactionFilter = .all
    @State private var searchText = ""
    @State private var showTransactionDetail: PaymentTransaction?
    @State private var isRefreshing = false
    
    enum TransactionFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case purchases = "Purchases"
        case sales = "Sales"
        case subscriptions = "Subscriptions"
        case transfers = "Transfers"
        
        var id: String { rawValue }
    }
    
    var filteredTransactions: [PaymentTransaction] {
        var transactions = paymentService.transactionHistory
        
        // Apply type filter
        switch selectedFilter {
        case .all:
            break
        case .purchases:
            transactions = transactions.filter { $0.type == .itemPurchase && $0.buyerId == getCurrentUserId() }
        case .sales:
            transactions = transactions.filter { $0.sellerId == getCurrentUserId() }
        case .subscriptions:
            transactions = transactions.filter { $0.type == .brandSubscription }
        case .transfers:
            transactions = transactions.filter { $0.type == .p2pTransfer }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            transactions = transactions.filter { transaction in
                transaction.description.localizedCaseInsensitiveContains(searchText) ||
                transaction.id.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return transactions.sorted(by: { $0.createdAt > $1.createdAt })
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Wallet Summary Card
                WalletSummaryCard(
                    totalSpent: calculateTotalSpent(),
                    totalEarned: calculateTotalEarned(),
                    pendingAmount: calculatePendingAmount()
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Filter Tabs
                FilterTabs(selectedFilter: $selectedFilter)
                    .padding(.top, 20)
                
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                // Transaction List
                List {
                    if filteredTransactions.isEmpty {
                        EmptyTransactionsView(filter: selectedFilter)
                    } else {
                        Section {
                            ForEach(filteredTransactions) { transaction in
                                TransactionRow(transaction: transaction)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        showTransactionDetail = transaction
                                    }
                            }
                        } header: {
                            Text("Recent Activity")
                                .font(.system(size: 13, weight: .semibold))
                                .textCase(.uppercase)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await loadTransactions()
                }
            }
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { /* Export statement */ }) {
                            Label("Export Statement", systemImage: "doc.text")
                        }
                        Button(action: { /* Settings */ }) {
                            Label("Payment Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(item: $showTransactionDetail) { transaction in
                TransactionDetailSheet(transaction: transaction)
            }
            .task {
                await loadTransactions()
            }
        }
    }
    
    private func loadTransactions() async {
        do {
            try await paymentService.fetchTransactionHistory()
        } catch {
            print("Failed to load transactions: \(error)")
        }
    }
    
    private func getCurrentUserId() -> String {
        // Return current user's ID from auth service
        return "current_user_id"
    }
    
    private func calculateTotalSpent() -> Double {
        paymentService.transactionHistory
            .filter { $0.buyerId == getCurrentUserId() && ($0.status == .completed || $0.status == .pending) }
            .reduce(0) { $0 + $1.amount }
    }
    
    private func calculateTotalEarned() -> Double {
        paymentService.transactionHistory
            .filter { $0.sellerId == getCurrentUserId() && $0.status == .completed }
            .reduce(0) { $0 + $1.sellerAmount }
    }
    
    private func calculatePendingAmount() -> Double {
        paymentService.transactionHistory
            .filter { $0.sellerId == getCurrentUserId() && $0.status == .pending }
            .reduce(0) { $0 + $1.sellerAmount }
    }
}

// MARK: - Wallet Summary Card
struct WalletSummaryCard: View {
    let totalSpent: Double
    let totalEarned: Double
    let pendingAmount: Double
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                SummaryItem(
                    title: "Total Spent",
                    amount: totalSpent,
                    icon: "arrow.down.circle.fill",
                    color: .red
                )
                
                Divider()
                    .frame(height: 50)
                
                SummaryItem(
                    title: "Total Earned",
                    amount: totalEarned,
                    icon: "arrow.up.circle.fill",
                    color: .green
                )
            }
            
            if pendingAmount > 0 {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("\(formatCurrency(pendingAmount)) pending")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "1a1a1a"), Color(hex: "2d2d2d")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundColor(.white)
        .cornerRadius(16)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

struct SummaryItem: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Text(formattedAmount)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

// MARK: - Filter Tabs
struct FilterTabs: View {
    @Binding var selectedFilter: TransactionHistoryView.TransactionFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TransactionHistoryView.TransactionFilter.allCases) { filter in
                    FilterTabButton(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct FilterTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "1a1a1a") : Color(hex: "f0f0f0"))
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17))
                .foregroundColor(.secondary)
            
            TextField("Search transactions", text: $text)
                .font(.system(size: 16))
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(hex: "f5f5f5"))
        .cornerRadius(10)
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    let transaction: PaymentTransaction
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(iconBackgroundColor)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transactionDescription)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(formattedDate)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedAmount)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(amountColor)
                
                StatusBadge(status: transaction.status)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var transactionDescription: String {
        if let metadata = transaction.metadata,
           let itemTitle = metadata.itemTitle {
            return itemTitle
        }
        return transaction.description
    }
    
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: transaction.createdAt, relativeTo: Date())
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = transaction.currency.uppercased()
        
        // Determine if this is incoming or outgoing
        let isIncoming = transaction.sellerId == getCurrentUserId()
        let prefix = isIncoming ? "+" : "-"
        
        let amount = isIncoming ? transaction.sellerAmount : transaction.amount
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        return "\(prefix)\(formatted)"
    }
    
    private var amountColor: Color {
        transaction.sellerId == getCurrentUserId() ? .green : .primary
    }
    
    private var iconName: String {
        switch transaction.type {
        case .itemPurchase:
            return "bag.fill"
        case .brandSubscription:
            return "star.fill"
        case .eventTicket:
            return "ticket.fill"
        case .deposit:
            return "arrow.down.circle.fill"
        case .withdrawal:
            return "arrow.up.circle.fill"
        case .refund:
            return "arrow.uturn.backward.circle.fill"
        case .p2pTransfer:
            return "person.2.fill"
        }
    }
    
    private var iconBackgroundColor: Color {
        switch transaction.type {
        case .itemPurchase:
            return .blue
        case .brandSubscription:
            return .purple
        case .eventTicket:
            return .orange
        case .deposit:
            return .green
        case .withdrawal:
            return .red
        case .refund:
            return .cyan
        case .p2pTransfer:
            return .indigo
        }
    }
    
    private func getCurrentUserId() -> String {
        return "current_user_id"
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: PaymentTransaction.TransactionStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(statusText)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
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
            return .purple
        }
    }
    
    private var statusText: String {
        switch status {
        case .completed:
            return "Completed"
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
            return "Disputed"
        }
    }
}

// MARK: - Empty State
struct EmptyTransactionsView: View {
    let filter: TransactionHistoryView.TransactionFilter
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wallet.bifold")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No \(filter.rawValue.lowercased()) transactions yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Your transaction history will appear here")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Transaction Detail Sheet
struct TransactionDetailSheet: View {
    let transaction: PaymentTransaction
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: iconName)
                            .font(.system(size: 48))
                            .foregroundColor(iconColor)
                        
                        Text(formattedAmount)
                            .font(.system(size: 36, weight: .bold))
                        
                        StatusBadge(status: transaction.status)
                            .scaleEffect(1.2)
                    }
                    .padding(.top, 20)
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailSection(title: "Transaction Details") {
                            DetailRow(label: "Transaction ID", value: transaction.id, isCopyable: true)
                            DetailRow(label: "Type", value: transaction.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                            DetailRow(label: "Date", value: fullFormattedDate)
                            DetailRow(label: "Description", value: transaction.description)
                        }
                        
                        if let sellerId = transaction.sellerId {
                            DetailSection(title: "Parties") {
                                DetailRow(label: "Seller", value: "@\(sellerId)")
                                DetailRow(label: "Buyer", value: "@\(transaction.buyerId)")
                            }
                        }
                        
                        DetailSection(title: "Amount Breakdown") {
                            DetailRow(label: "Subtotal", value: formatCurrency(transaction.sellerAmount))
                            DetailRow(label: "Platform Fee", value: formatCurrency(transaction.platformFee))
                            Divider()
                            DetailRow(label: "Total", value: formatCurrency(transaction.amount), isBold: true)
                        }
                    }
                    .padding(20)
                    .background(Color(hex: "f8f8f8"))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    
                    // Actions
                    if transaction.status == .completed {
                        Button(action: { /* Request refund */ }) {
                            Text("Request Refund")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Button(action: { /* Contact support */ }) {
                        Text("Contact Support")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "1a1a1a"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "f0f0f0"))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var iconName: String {
        switch transaction.type {
        case .itemPurchase:
            return "bag.fill"
        case .brandSubscription:
            return "star.fill"
        case .eventTicket:
            return "ticket.fill"
        case .deposit:
            return "arrow.down.circle.fill"
        case .withdrawal:
            return "arrow.up.circle.fill"
        case .refund:
            return "arrow.uturn.backward.circle.fill"
        case .p2pTransfer:
            return "person.2.fill"
        }
    }
    
    private var iconColor: Color {
        switch transaction.type {
        case .itemPurchase:
            return .blue
        case .brandSubscription:
            return .purple
        case .eventTicket:
            return .orange
        case .deposit:
            return .green
        case .withdrawal:
            return .red
        case .refund:
            return .cyan
        case .p2pTransfer:
            return .indigo
        }
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = transaction.currency.uppercased()
        
        let isIncoming = transaction.sellerId != nil
        let prefix = isIncoming ? "+" : ""
        let amount = isIncoming ? transaction.sellerAmount : transaction.amount
        
        return "\(prefix)\(formatter.string(from: NSNumber(value: amount)) ?? "\(amount)")"
    }
    
    private var fullFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
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

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            content
        }
    }
}

// MARK: - Preview
struct TransactionHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionHistoryView()
    }
}
