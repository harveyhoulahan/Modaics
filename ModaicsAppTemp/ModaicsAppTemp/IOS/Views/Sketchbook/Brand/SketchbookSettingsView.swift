//
//  SketchbookSettingsView.swift
//  ModaicsAppTemp
//
//  Settings management for brand Sketchbook
//

import SwiftUI

struct SketchbookSettingsView: View {
    let sketchbook: Sketchbook
    @ObservedObject var viewModel: BrandSketchbookViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var description: String
    @State private var accessPolicy: SketchbookAccessPolicy
    @State private var membershipRule: SketchbookMembershipRule
    @State private var minSpendAmount: String
    
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    
    init(sketchbook: Sketchbook, viewModel: BrandSketchbookViewModel) {
        self.sketchbook = sketchbook
        self.viewModel = viewModel
        _name = State(initialValue: sketchbook.title)
        _description = State(initialValue: sketchbook.description ?? "")
        _accessPolicy = State(initialValue: sketchbook.accessPolicy)
        _membershipRule = State(initialValue: sketchbook.membershipRule)
        _minSpendAmount = State(initialValue: String(Int(sketchbook.minSpendAmount ?? 0)))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.modaicsDarkBlue
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Basic Info
                        basicInfoSection
                        
                        // Access Policy
                        accessPolicySection
                        
                        // Membership Rules
                        membershipSection
                        
                        // Save Button
                        ModaicsPrimaryButton(
                            "Save Changes",
                            icon: "checkmark.circle.fill",
                            isLoading: isSubmitting
                        ) {
                            Task { await saveSettings() }
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Sketchbook Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.modaicsCotton)
                }
            }
            .alert("Settings Updated", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.modaicsCotton)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.system(size: 14))
                    .foregroundColor(.modaicsCottonLight)
                
                TextField("Sketchbook name", text: $name)
                    .foregroundColor(.modaicsCotton)
                    .padding()
                    .background(Color.modaicsSurface2)
                    .clipShape(Rectangle())
                    .overlay(
                        Rectangle()
                            .stroke(Color.modaicsChrome1.opacity(0.2), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.system(size: 14))
                    .foregroundColor(.modaicsCottonLight)
                
                ZStack(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("Describe your Sketchbook...")
                            .foregroundColor(.modaicsCottonLight.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                    }
                    
                    TextEditor(text: $description)
                        .foregroundColor(.modaicsCotton)
                        .font(.system(size: 15))
                        .scrollContentBackground(.hidden)
                        .frame(height: 100)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
                .background(Color.modaicsSurface2)
                .clipShape(Rectangle())
                .overlay(
                    Rectangle()
                        .stroke(Color.modaicsChrome1.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Access Policy Section
    
    private var accessPolicySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Access Policy")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.modaicsCotton)
            
            ForEach(SketchbookAccessPolicy.allCases, id: \.self) { policy in
                accessPolicyCard(policy: policy)
            }
        }
    }
    
    private func accessPolicyCard(policy: SketchbookAccessPolicy) -> some View {
        Button(action: { accessPolicy = policy }) {
            HStack(spacing: 16) {
                // Radio button
                Image(systemName: accessPolicy == policy ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(accessPolicy == policy ? .modaicsChrome1 : .modaicsCottonLight)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(policy.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.modaicsCotton)
                    
                    Text(policy.description)
                        .font(.system(size: 13))
                        .foregroundColor(.modaicsCottonLight)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                accessPolicy == policy
                    ? Color.modaicsChrome1.opacity(0.1)
                    : Color.modaicsSurface2
            )
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(
                        accessPolicy == policy
                            ? Color.modaicsChrome1.opacity(0.5)
                            : Color.modaicsChrome1.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
    }
    
    // MARK: - Membership Section
    
    private var membershipSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Membership Requirements")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.modaicsCotton)
            
            if accessPolicy == .membersOnly {
                ForEach(SketchbookMembershipRule.allCases, id: \.self) { rule in
                    membershipRuleCard(rule: rule)
                }
                
                if membershipRule == .minSpend {
                    minSpendField
                }
            } else {
                Text("Membership requirements only apply when Access Policy is set to Members Only")
                    .font(.system(size: 14))
                    .foregroundColor(.modaicsCottonLight)
                    .padding()
                    .background(Color.modaicsSurface2)
                    .clipShape(Rectangle())
            }
        }
    }
    
    private func membershipRuleCard(rule: SketchbookMembershipRule) -> some View {
        Button(action: { membershipRule = rule }) {
            HStack(spacing: 16) {
                // Radio button
                Image(systemName: membershipRule == rule ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(membershipRule == rule ? .modaicsChrome1 : .modaicsCottonLight)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.modaicsCotton)
                    
                    Text(rule.description)
                        .font(.system(size: 13))
                        .foregroundColor(.modaicsCottonLight)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                membershipRule == rule
                    ? Color.modaicsChrome1.opacity(0.1)
                    : Color.modaicsSurface2
            )
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(
                        membershipRule == rule
                            ? Color.modaicsChrome1.opacity(0.5)
                            : Color.modaicsChrome1.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
    }
    
    private var minSpendField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Minimum Spend Amount")
                .font(.system(size: 14))
                .foregroundColor(.modaicsCottonLight)
            
            HStack {
                Text("$")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.modaicsCotton)
                
                TextField("0", text: $minSpendAmount)
                    .keyboardType(.numberPad)
                    .foregroundColor(.modaicsCotton)
                    .font(.system(size: 18))
            }
            .padding()
            .background(Color.modaicsSurface2)
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(Color.modaicsChrome1.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Save
    
    private func saveSettings() async {
        isSubmitting = true
        defer { isSubmitting = false }
        
        let minSpend: Double? = {
            if membershipRule == .minSpend, let amount = Double(minSpendAmount), amount > 0 {
                return amount
            }
            return nil
        }()
        
        let success = await viewModel.updateSettings(
            title: name.isEmpty ? nil : name,
            description: description.isEmpty ? nil : description,
            accessPolicy: accessPolicy,
            membershipRule: membershipRule,
            minSpendAmount: minSpend
        )
        
        if success {
            showSuccessAlert = true
        }
    }
}

// MARK: - Preview
#Preview {
    SketchbookSettingsView(
        sketchbook: .sample,
        viewModel: BrandSketchbookViewModel(userId: "brand-123")
    )
}
