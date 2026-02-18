//
//  SubscriptionFlowView.swift
//  ModaicsAppTemp
//
//  Brand subscription flow for Sketchbook membership
//

import SwiftUI

struct SubscriptionFlowView: View {
    let brand: BrandForSubscription
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var paymentService = PaymentService.shared
    @State private var selectedPlan: SubscriptionPlan?
    @State private var showPaymentSheet = false
    @State private var showConfirmation = false
    @State private var subscription: UserSubscription?
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Sample plans - in production, fetch from API
    let plans: [SubscriptionPlan] = [
        SubscriptionPlan(
            id: "plan_basic",
            name: "Community",
            description: "Free access to public posts and community features",
            price: 0,
            currency: "USD",
            interval: "month",
            features: [
                "View public posts",
                "Join community discussions",
                "Basic brand updates"
            ],
            productId: "price_basic_free",
            tier: .basic
        ),
        SubscriptionPlan(
            id: "plan_pro",
            name: "Member",
            description: "Exclusive access to member-only content and events",
            price: 9.99,
            currency: "USD",
            interval: "month",
            features: [
                "Everything in Community",
                "Member-only posts",
                "Early access to events",
                "Exclusive drops",
                "Member badge"
            ],
            productId: "price_member_monthly",
            tier: .pro
        ),
        SubscriptionPlan(
            id: "plan_enterprise",
            name: "VIP",
            description: "Premium access with direct brand interaction",
            price: 29.99,
            currency: "USD",
            interval: "month",
            features: [
                "Everything in Member",
                "VIP-only events",
                "Direct messaging with brand",
                "Monthly virtual meetups",
                "Exclusive merchandise",
                "Priority customer support"
            ],
            productId: "price_vip_monthly",
            tier: .enterprise
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Brand Header
                    BrandSubscriptionHeader(brand: brand)
                    
                    // Benefits Section
                    SubscriptionBenefitsSection()
                    
                    // Plan Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Choose Your Plan")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            ForEach(plans) { plan in
                                PlanCard(
                                    plan: plan,
                                    isSelected: selectedPlan?.id == plan.id
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedPlan = plan
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Selected Plan Details
                    if let plan = selectedPlan, plan.price > 0 {
                        SelectedPlanDetailCard(plan: plan)
                            .padding(.horizontal, 20)
                    }
                    
                    // Subscribe Button
                    if let plan = selectedPlan {
                        VStack(spacing: 12) {
                            if plan.price == 0 {
                                // Free plan - just join
                                PaymentButton(
                                    title: "Join for Free",
                                    amount: 0,
                                    style: .primary,
                                    isLoading: paymentService.isLoading,
                                    action: joinFreePlan
                                )
                            } else {
                                // Paid plan
                                PaymentButton(
                                    title: "Subscribe Now",
                                    amount: plan.price,
                                    currency: plan.currency,
                                    style: .primary,
                                    isLoading: paymentService.isLoading,
                                    action: startSubscription
                                )
                                
                                // Apple Pay option
                                ApplePayButton(
                                    amount: plan.price,
                                    isLoading: paymentService.isLoading,
                                    action: startSubscriptionWithApplePay
                                )
                            }
                            
                            // Terms
                            Text("By subscribing, you agree to auto-renewal. Cancel anytime.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Subscribe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showConfirmation) {
                SubscriptionConfirmationView(
                    brand: brand,
                    plan: selectedPlan!,
                    subscription: subscription!,
                    onDone: {
                        dismiss()
                    }
                )
            }
            .alert("Subscription Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func joinFreePlan() {
        Task {
            do {
                // Join free tier directly without payment
                // Call API to create membership
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func startSubscription() {
        guard let plan = selectedPlan else { return }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        Task {
            do {
                let newSubscription = try await paymentService.subscribeToBrand(
                    brandId: brand.id,
                    plan: plan,
                    from: rootViewController
                )
                
                await MainActor.run {
                    self.subscription = newSubscription
                    self.showConfirmation = true
                }
            } catch PaymentError.cancelled {
                // User cancelled
            } catch PaymentError.subscriptionAlreadyActive {
                errorMessage = "You already have an active subscription to this brand."
                showError = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func startSubscriptionWithApplePay() {
        // Implement Apple Pay subscription flow
    }
}

// MARK: - Supporting Views

struct BrandSubscriptionHeader: View {
    let brand: BrandForSubscription
    
    var body: some View {
        VStack(spacing: 16) {
            // Brand Logo
            ZStack {
                Circle()
                    .fill(Color(hex: "f5f5f5"))
                    .frame(width: 100, height: 100)
                
                if let logoUrl = brand.logoUrl,
                   let url = URL(string: logoUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
            }
            
            VStack(spacing: 8) {
                Text(brand.name)
                    .font(.system(size: 24, weight: .bold))
                
                Text("@\(brand.username)")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                
                if let description = brand.description {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 32)
                }
                
                HStack(spacing: 20) {
                    StatView(value: "\(brand.membersCount)", label: "Members")
                    StatView(value: "\(brand.postsCount)", label: "Posts")
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct StatView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

struct SubscriptionBenefitsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Member Benefits")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    BenefitCard(
                        icon: "star.fill",
                        title: "Exclusive Content",
                        description: "Access posts only for members"
                    )
                    
                    BenefitCard(
                        icon: "ticket.fill",
                        title: "Event Access",
                        description: "Priority tickets to brand events"
                    )
                    
                    BenefitCard(
                        icon: "tag.fill",
                        title: "Special Drops",
                        description: "Early access to limited releases"
                    )
                    
                    BenefitCard(
                        icon: "person.2.fill",
                        title: "Community",
                        description: "Connect with fellow fans"
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct BenefitCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "1a1a1a"))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(width: 140, height: 120, alignment: .leading)
        .padding(16)
        .background(Color(hex: "f8f8f8"))
        .cornerRadius(16)
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(hex: "1a1a1a") : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "1a1a1a"))
                            .frame(width: 14, height: 14)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.name)
                            .font(.system(size: 17, weight: .semibold))
                        
                        if plan.price == 0 {
                            Text("FREE")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(plan.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if plan.price > 0 {
                        Text("\(plan.currency) \(String(format: "%.2f", plan.price))/\(plan.interval)")
                            .font(.system(size: 15, weight: .medium))
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(isSelected ? Color(hex: "f0f0f0") : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "1a1a1a") : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SelectedPlanDetailCard: View {
    let plan: SubscriptionPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's included in \(plan.name)")
                .font(.system(size: 17, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(plan.features, id: \.self) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                        
                        Text(feature)
                            .font(.system(size: 15))
                    }
                }
            }
        }
        .padding(20)
        .background(Color(hex: "f8f8f8"))
        .cornerRadius(16)
    }
}

struct SubscriptionConfirmationView: View {
    let brand: BrandForSubscription
    let plan: SubscriptionPlan
    let subscription: UserSubscription
    let onDone: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Success Icon
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
                        Text("Welcome to \(brand.name)!")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("You're now a \(plan.name) member")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }
                    
                    // Membership Card
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Membership")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                Text(plan.name)
                                    .font(.system(size: 20, weight: .bold))
                            }
                            
                            Spacer()
                            
                            if let logoUrl = brand.logoUrl,
                               let url = URL(string: logoUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.gray
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Renews")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Text(formattedRenewalDate)
                                    .font(.system(size: 15, weight: .medium))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Amount")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                if plan.price > 0 {
                                    Text("\(plan.currency) \(String(format: "%.2f", plan.price))/\(plan.interval)")
                                        .font(.system(size: 15, weight: .medium))
                                } else {
                                    Text("Free")
                                        .font(.system(size: 15, weight: .medium))
                                }
                            }
                        }
                    }
                    .padding(24)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "1a1a1a"), Color(hex: "2d2d2d")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .padding(.horizontal, 20)
                    
                    // Next Steps
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What's Next?")
                            .font(.system(size: 17, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 12) {
                            NextStepItem(
                                number: 1,
                                title: "Explore Member Content",
                                description: "Check out exclusive posts just for members"
                            )
                            
                            NextStepItem(
                                number: 2,
                                title: "Join the Community",
                                description: "Connect with fellow brand enthusiasts"
                            )
                            
                            NextStepItem(
                                number: 3,
                                title: "Stay Updated",
                                description: "Watch for member-only events and drops"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    Button(action: onDone) {
                        Text("Start Exploring")
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
            }
            .navigationBarHidden(true)
        }
    }
    
    private var formattedRenewalDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: subscription.currentPeriodEnd)
    }
}

struct NextStepItem: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "f0f0f0"))
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "1a1a1a"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Data Models

struct BrandForSubscription: Identifiable {
    let id: String
    let name: String
    let username: String
    let description: String?
    let logoUrl: String?
    let membersCount: Int
    let postsCount: Int
}

// MARK: - Preview
struct SubscriptionFlowView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionFlowView(brand: BrandForSubscription(
            id: "brand_123",
            name: "Eco Fashion Co",
            username: "ecofashion",
            description: "Sustainable fashion for a better tomorrow. Join our community of eco-conscious fashion lovers.",
            logoUrl: nil,
            membersCount: 1240,
            postsCount: 85
        ))
    }
}
