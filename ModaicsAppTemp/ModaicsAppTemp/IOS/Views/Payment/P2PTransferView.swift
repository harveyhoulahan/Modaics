//
//  P2PTransferView.swift
//  ModaicsAppTemp
//
//  Peer-to-peer money transfer flow
//

import SwiftUI

struct P2PTransferView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var paymentService = PaymentService.shared
    
    @State private var recipient: UserForTransfer?
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var currentStep: TransferStep = .recipient
    @State private var showConfirmation = false
    @State private var transaction: Transaction?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    enum TransferStep: Int, CaseIterable {
        case recipient = 0
        case amount = 1
        case confirm = 2
        
        var title: String {
            switch self {
            case .recipient: return "Recipient"
            case .amount: return "Amount"
            case .confirm: return "Confirm"
            }
        }
    }
    
    var transferFee: Double {
        let amountValue = Double(amount) ?? 0
        return amountValue * 0.02 // 2% transfer fee
    }
    
    var totalAmount: Double {
        let amountValue = Double(amount) ?? 0
        return amountValue + transferFee
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Steps
                TransferProgressView(currentStep: currentStep)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                // Content
                TabView(selection: $currentStep) {
                    RecipientSelectionStep(
                        selectedRecipient: $recipient,
                        onContinue: { currentStep = .amount }
                    )
                    .tag(TransferStep.recipient)
                    
                    AmountEntryStep(
                        amount: $amount,
                        note: $note,
                        recipient: recipient,
                        onContinue: { currentStep = .confirm },
                        onBack: { currentStep = .recipient }
                    )
                    .tag(TransferStep.amount)
                    
                    ConfirmationStep(
                        recipient: recipient!,
                        amount: Double(amount) ?? 0,
                        fee: transferFee,
                        total: totalAmount,
                        note: note,
                        onConfirm: processTransfer,
                        onBack: { currentStep = .amount }
                    )
                    .tag(TransferStep.confirm)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Send Money")
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
                    TransferConfirmationView(
                        transaction: transaction,
                        recipient: recipient!,
                        onDone: {
                            dismiss()
                        }
                    )
                }
            }
            .alert("Transfer Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func processTransfer() {
        guard let recipient = recipient,
              let amountValue = Double(amount),
              amountValue > 0 else {
            errorMessage = "Invalid transfer details"
            showError = true
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        Task {
            do {
                let newTransaction = try await paymentService.sendP2PTransfer(
                    to: recipient.id,
                    amount: amountValue,
                    note: note.isEmpty ? nil : note,
                    from: rootViewController
                )
                
                await MainActor.run {
                    self.transaction = newTransaction
                    self.showConfirmation = true
                }
            } catch PaymentError.cancelled {
                // User cancelled
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Recipient Selection Step
struct RecipientSelectionStep: View {
    @Binding var selectedRecipient: UserForTransfer?
    let onContinue: () -> Void
    
    @State private var searchText = ""
    @State private var recentRecipients: [UserForTransfer] = []
    @State private var searchResults: [UserForTransfer] = []
    @State private var isSearching = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBar(text: $searchText)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .onChange(of: searchText) { _ in
                    performSearch()
                }
            
            ScrollView {
                VStack(spacing: 24) {
                    // Selected Recipient
                    if let recipient = selectedRecipient {
                        SelectedRecipientCard(recipient: recipient) {
                            selectedRecipient = nil
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Recent Recipients
                    if !recentRecipients.isEmpty && selectedRecipient == nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent")
                                .font(.system(size: 17, weight: .semibold))
                                .padding(.horizontal, 20)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(recentRecipients) { recipient in
                                    RecipientRow(recipient: recipient) {
                                        selectedRecipient = recipient
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Search Results
                    if !searchResults.isEmpty && selectedRecipient == nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Results")
                                .font(.system(size: 17, weight: .semibold))
                                .padding(.horizontal, 20)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(searchResults) { recipient in
                                    RecipientRow(recipient: recipient) {
                                        selectedRecipient = recipient
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    Spacer()
                    
                    // Continue Button
                    if selectedRecipient != nil {
                        PaymentButton(
                            title: "Continue",
                            amount: 0,
                            style: .primary,
                            action: onContinue
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .padding(.top, 20)
            }
        }
        .onAppear {
            loadRecentRecipients()
        }
    }
    
    private func performSearch() {
        guard searchText.count >= 2 else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        // In production: Call API to search users
        // For demo: Simulate search
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            searchResults = [
                UserForTransfer(
                    id: "user_1",
                    username: "fashionlover",
                    displayName: "Sarah Fashion",
                    avatarUrl: nil
                ),
                UserForTransfer(
                    id: "user_2",
                    username: "styleicon",
                    displayName: "Mike Style",
                    avatarUrl: nil
                )
            ].filter { $0.username.contains(searchText.lowercased()) || $0.displayName.lowercased().contains(searchText.lowercased()) }
            
            isSearching = false
        }
    }
    
    private func loadRecentRecipients() {
        // Load from UserDefaults or API
        recentRecipients = []
    }
}

// MARK: - Amount Entry Step
struct AmountEntryStep: View {
    @Binding var amount: String
    @Binding var note: String
    let recipient: UserForTransfer?
    let onContinue: () -> Void
    let onBack: () -> Void
    
    @State private var showKeypad = true
    
    var body: some View {
        VStack(spacing: 24) {
            // Recipient Info
            if let recipient = recipient {
                HStack(spacing: 12) {
                    AvatarView(url: recipient.avatarUrl, size: 50)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipient.displayName)
                            .font(.system(size: 17, weight: .semibold))
                        Text("@\(recipient.username)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            
            // Amount Display
            VStack(spacing: 8) {
                Text("Enter Amount")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Text("$")
                        .font(.system(size: 40, weight: .bold))
                    
                    Text(amount.isEmpty ? "0" : amount)
                        .font(.system(size: 60, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .foregroundColor(Color(hex: "1a1a1a"))
                
                if !amount.isEmpty, let amountValue = Double(amount), amountValue > 0 {
                    Text("+ \(String(format: "%.2f", amountValue * 0.02)) fee")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 40)
            
            // Note Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Note (Optional)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("What's this for?", text: $note)
                    .font(.system(size: 17))
                    .padding(16)
                    .background(Color(hex: "f5f5f5"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Number Pad
            NumberPad(amount: $amount)
                .frame(height: 280)
                .padding(.horizontal, 20)
            
            // Buttons
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
                .disabled(amount.isEmpty || Double(amount) == nil || Double(amount)! <= 0)
                .opacity(amount.isEmpty || Double(amount) == nil || Double(amount)! <= 0 ? 0.5 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Confirmation Step
struct ConfirmationStep: View {
    let recipient: UserForTransfer
    let amount: Double
    let fee: Double
    let total: Double
    let note: String
    let onConfirm: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Transfer Summary
                VStack(spacing: 24) {
                    // From/To
                    HStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.gray)
                                )
                            Text("You")
                                .font(.system(size: 15, weight: .medium))
                        }
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            AvatarView(url: recipient.avatarUrl, size: 60)
                            Text(recipient.displayName)
                                .font(.system(size: 15, weight: .medium))
                        }
                    }
                    
                    // Amount
                    VStack(spacing: 8) {
                        Text(paymentService.formatCurrency(amount))
                            .font(.system(size: 48, weight: .bold))
                        
                        if !note.isEmpty {
                            Text("\"\(note)\"")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .italic()
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                }
                .padding(.top, 20)
                
                // Breakdown
                VStack(spacing: 16) {
                    Text("Transfer Details")
                        .font(.system(size: 17, weight: .semibold))
                    
                    VStack(spacing: 12) {
                        FeeRow(label: "Transfer Amount", value: paymentService.formatCurrency(amount), isBold: false)
                        FeeRow(label: "Transfer Fee (2%)", value: paymentService.formatCurrency(fee), isBold: false, isFee: true)
                        
                        Divider()
                        
                        FeeRow(label: "Total", value: paymentService.formatCurrency(total), isBold: true)
                    }
                    .padding(16)
                    .background(Color(hex: "fafafa"))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                
                // Security Note
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("Secure transfer via Stripe")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    PaymentButton(
                        title: "Confirm Transfer",
                        amount: total,
                        style: .primary,
                        action: onConfirm
                    )
                    
                    Button(action: onBack) {
                        Text("Back")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    private var paymentService: PaymentService { PaymentService.shared }
}

// MARK: - Supporting Views

struct TransferProgressView: View {
    let currentStep: P2PTransferView.TransferStep
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(P2PTransferView.TransferStep.allCases, id: \.self) { step in
                HStack(spacing: 4) {
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? Color(hex: "1a1a1a") : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    if step != .confirm {
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue ? Color(hex: "1a1a1a") : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
        }
    }
}

struct SelectedRecipientCard: View {
    let recipient: UserForTransfer
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            AvatarView(url: recipient.avatarUrl, size: 56)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipient.displayName)
                    .font(.system(size: 17, weight: .semibold))
                Text("@\(recipient.username)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(hex: "f0f8ff"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

struct RecipientRow: View {
    let recipient: UserForTransfer
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                AvatarView(url: recipient.avatarUrl, size: 48)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipient.displayName)
                        .font(.system(size: 16, weight: .semibold))
                    Text("@\(recipient.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(hex: "fafafa"))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AvatarView: View {
    let url: String?
    let size: CGFloat
    
    var body: some View {
        if let url = url,
           let imageUrl = URL(string: url) {
            AsyncImage(url: imageUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundColor(.gray)
                )
        }
    }
}

struct NumberPad: View {
    @Binding var amount: String
    
    let buttons: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { button in
                        NumberPadButton(
                            title: button,
                            action: { handleInput(button) }
                        )
                    }
                }
            }
        }
    }
    
    private func handleInput(_ input: String) {
        switch input {
        case "⌫":
            if !amount.isEmpty {
                amount.removeLast()
            }
        case ".":
            if !amount.contains(".") {
                amount += input
            }
        default:
            // Limit to 2 decimal places
            if let dotIndex = amount.firstIndex(of: ".") {
                let decimals = amount[dotIndex...].count - 1
                if decimals < 2 {
                    amount += input
                }
            } else {
                amount += input
            }
        }
    }
}

struct NumberPadButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 28, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(Color(hex: "f5f5f5"))
                .foregroundColor(title == "⌫" ? .red : Color(hex: "1a1a1a"))
                .cornerRadius(12)
        }
    }
}

struct TransferConfirmationView: View {
    let transaction: Transaction
    let recipient: UserForTransfer
    let onDone: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Success Animation
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }
                .padding(.top, 40)
                
                VStack(spacing: 12) {
                    Text("Transfer Sent!")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Your money is on its way to \(recipient.displayName)")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Transfer Details
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Amount Sent")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Text(PaymentService.shared.formatCurrency(transaction.amount - transaction.platformFee))
                                .font(.system(size: 20, weight: .bold))
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("To")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            HStack(spacing: 8) {
                                AvatarView(url: recipient.avatarUrl, size: 32)
                                Text(recipient.displayName)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Transaction ID")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Text(transaction.id)
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            UIPasteboard.general.string = transaction.id
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(24)
                .background(Color(hex: "f8f8f8"))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "1a1a1a"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Data Models

struct UserForTransfer: Identifiable, Hashable {
    let id: String
    let username: String
    let displayName: String
    let avatarUrl: String?
}

// MARK: - Preview
struct P2PTransferView_Previews: PreviewProvider {
    static var previews: some View {
        P2PTransferView()
    }
}
