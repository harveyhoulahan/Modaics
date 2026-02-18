//
//  SettingsView.swift
//  Modaics
//
//  Settings with Firebase Auth integration
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showPasswordChangeSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.forestBackground
                    .ignoresSafeArea()
                
                List {
                    // Account Section
                    Section {
                        if let user = authViewModel.currentUser {
                            HStack(spacing: 16) {
                                // Profile Image
                                ZStack {
                                    Circle()
                                        .fill(.luxeGoldGradient)
                                        .frame(width: 60, height: 60)
                                    
                                    if let imageURL = user.profileImageURL {
                                        // Async image would go here
                                        Image(systemName: user.userType == .brand ? "building.2.fill" : "person.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.forestDeep)
                                    } else {
                                        Image(systemName: user.userType == .brand ? "building.2.fill" : "person.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.forestDeep)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.displayName ?? user.username ?? "User")
                                        .font(.forestHeadline(18))
                                        .foregroundColor(.sageWhite)
                                    
                                    Text(user.email)
                                        .font(.forestCaption(14))
                                        .foregroundColor(.sageMuted)
                                    
                                    HStack(spacing: 8) {
                                        if user.isEmailVerified {
                                            Label("Verified", systemImage: "checkmark.shield.fill")
                                                .font(.forestCaption(11))
                                                .foregroundColor(.emerald)
                                        } else {
                                            Label("Unverified", systemImage: "exclamationmark.shield")
                                                .font(.forestCaption(11))
                                                .foregroundColor(.orange)
                                        }
                                        
                                        Text("•")
                                            .foregroundColor(.sageMuted)
                                        
                                        Text(user.membershipTier.rawValue)
                                            .font(.forestCaption(11))
                                            .foregroundColor(.luxeGold)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    } header: {
                        Text("Account")
                            .font(.forestHeadline(14))
                            .foregroundColor(.sageMuted)
                    }
                    .listRowBackground(Color.forestMid.opacity(0.6))
                    
                    // Profile Settings
                    Section {
                        NavigationLink {
                            EditProfileView()
                        } label: {
                            SettingsRow(icon: "person.fill", title: "Edit Profile", color: .modaicsChrome1)
                        }
                        
                        NavigationLink {
                            NotificationSettingsView()
                        } label: {
                            SettingsRow(icon: "bell.fill", title: "Notifications", color: .modaicsChrome1)
                        }
                        
                        NavigationLink {
                            PrivacySettingsView()
                        } label: {
                            SettingsRow(icon: "lock.fill", title: "Privacy & Security", color: .modaicsChrome1)
                        }
                    } header: {
                        Text("Preferences")
                            .font(.forestHeadline(14))
                            .foregroundColor(.sageMuted)
                    }
                    .listRowBackground(Color.forestMid.opacity(0.6))
                    
                    // Security Section
                    Section {
                        Button {
                            showPasswordChangeSheet = true
                        } label: {
                            SettingsRow(icon: "key.fill", title: "Change Password", color: .modaicsChrome1)
                        }
                        
                        if !(authViewModel.currentUser?.isEmailVerified ?? true) {
                            Button {
                                Task {
                                    await authViewModel.sendEmailVerification()
                                }
                            } label: {
                                HStack {
                                    SettingsRow(icon: "envelope.badge.shield", title: "Verify Email", color: .orange)
                                    Spacer()
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .tint(.modaicsChrome1)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Security")
                            .font(.forestHeadline(14))
                            .foregroundColor(.sageMuted)
                    }
                    .listRowBackground(Color.forestMid.opacity(0.6))
                    
                    // Danger Zone
                    Section {
                        Button {
                            showSignOutConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.square.fill")
                                    .foregroundColor(.orange)
                                Text("Sign Out")
                                    .font(.forestBody(16))
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Button {
                            showDeleteAccountConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                                Text("Delete Account")
                                    .font(.forestBody(16))
                                    .foregroundColor(.red)
                            }
                        }
                    } header: {
                        Text("Account Actions")
                            .font(.forestHeadline(14))
                            .foregroundColor(.sageMuted)
                    }
                    .listRowBackground(Color.forestMid.opacity(0.6))
                    
                    // App Info
                    Section {
                        HStack {
                            Text("Version")
                                .font(.forestBody(16))
                                .foregroundColor(.sageWhite)
                            Spacer()
                            Text("1.0.0")
                                .font(.forestCaption(14))
                                .foregroundColor(.sageMuted)
                        }
                        
                        Link(destination: URL(string: "https://modaics.app/terms")!) {
                            SettingsRow(icon: "doc.text.fill", title: "Terms of Service", color: .sageMuted)
                        }
                        
                        Link(destination: URL(string: "https://modaics.app/privacy")!) {
                            SettingsRow(icon: "hand.raised.fill", title: "Privacy Policy", color: .sageMuted)
                        }
                    } header: {
                        Text("About")
                            .font(.forestHeadline(14))
                            .foregroundColor(.sageMuted)
                    }
                    .listRowBackground(Color.forestMid.opacity(0.6))
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.forestBody(16))
                    .foregroundColor(.modaicsChrome1)
                }
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showDeleteAccountConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // Implement account deletion
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .sheet(isPresented: $showPasswordChangeSheet) {
                ChangePasswordView()
            }
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.forestBody(16))
                .foregroundColor(.sageWhite)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.sageMuted)
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var displayName = ""
    @State private var bio = ""
    @State private var location = ""
    @State private var isSaving = false
    
    var body: some View {
        ZStack {
            LinearGradient.forestBackground
                .ignoresSafeArea()
            
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Display Name", text: $displayName)
                        .font(.forestBody(16))
                    
                    TextField("Location", text: $location)
                        .font(.forestBody(16))
                    
                    TextEditor(text: $bio)
                        .font(.forestBody(16))
                        .frame(minHeight: 100)
                }
                .listRowBackground(Color.forestMid.opacity(0.6))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .font(.forestBody(16))
                .foregroundColor(.modaicsChrome1)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    saveProfile()
                } label: {
                    if isSaving {
                        ProgressView()
                            .tint(.modaicsChrome1)
                    } else {
                        Text("Save")
                            .font(.forestBody(16))
                            .foregroundColor(.modaicsChrome1)
                    }
                }
                .disabled(isSaving)
            }
        }
        .onAppear {
            if let user = authViewModel.currentUser {
                displayName = user.displayName ?? ""
                bio = user.bio ?? ""
                location = user.location ?? ""
            }
        }
    }
    
    private func saveProfile() {
        isSaving = true
        Task {
            _ = await authViewModel.updateUserProfile(
                displayName: displayName.isEmpty ? nil : displayName,
                bio: bio.isEmpty ? nil : bio,
                location: location.isEmpty ? nil : location
            )
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - Notification Settings
struct NotificationSettingsView: View {
    @State private var pushEnabled = true
    @State private var emailEnabled = true
    @State private var marketingEnabled = false
    
    var body: some View {
        ZStack {
            LinearGradient.forestBackground
                .ignoresSafeArea()
            
            Form {
                Section(header: Text("Push Notifications")) {
                    Toggle("Enable Push Notifications", isOn: $pushEnabled)
                    Toggle("New Messages", isOn: .constant(true))
                    Toggle("Item Updates", isOn: .constant(true))
                    Toggle("Price Drops", isOn: .constant(true))
                }
                .listRowBackground(Color.forestMid.opacity(0.6))
                
                Section(header: Text("Email Notifications")) {
                    Toggle("Enable Email Notifications", isOn: $emailEnabled)
                    Toggle("Weekly Digest", isOn: .constant(true))
                    Toggle("Promotions", isOn: $marketingEnabled)
                }
                .listRowBackground(Color.forestMid.opacity(0.6))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Privacy Settings
struct PrivacySettingsView: View {
    @State private var profileVisible = true
    @State private var showActivity = true
    
    var body: some View {
        ZStack {
            LinearGradient.forestBackground
                .ignoresSafeArea()
            
            Form {
                Section(header: Text("Profile Visibility")) {
                    Toggle("Public Profile", isOn: $profileVisible)
                    Toggle("Show Activity Status", isOn: $showActivity)
                }
                .listRowBackground(Color.forestMid.opacity(0.6))
                
                Section(header: Text("Data")) {
                    Button("Download My Data") {
                        // Implement data export
                    }
                    .font(.forestBody(16))
                    .foregroundColor(.modaicsChrome1)
                    
                    Button("Clear Search History") {
                        // Implement clear history
                    }
                    .font(.forestBody(16))
                    .foregroundColor(.orange)
                }
                .listRowBackground(Color.forestMid.opacity(0.6))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Change Password View
struct ChangePasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var isChanging = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.forestBackground
                    .ignoresSafeArea()
                
                Form {
                    Section(header: Text("Current Password")) {
                        SecureField("Enter current password", text: $currentPassword)
                    }
                    .listRowBackground(Color.forestMid.opacity(0.6))
                    
                    Section(header: Text("New Password")) {
                        SecureField("Enter new password", text: $newPassword)
                        SecureField("Confirm new password", text: $confirmPassword)
                    }
                    .listRowBackground(Color.forestMid.opacity(0.6))
                    
                    Section {
                        Button {
                            changePassword()
                        } label: {
                            HStack {
                                Spacer()
                                if isChanging {
                                    ProgressView()
                                        .tint(.forestDeep)
                                } else {
                                    Text("Change Password")
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                        }
                        .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword)
                    }
                    .listRowBackground(Color.modaicsChrome1)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.forestBody(16))
                    .foregroundColor(.modaicsChrome1)
                }
            }
        }
    }
    
    private func changePassword() {
        isChanging = true
        Task {
            _ = await authViewModel.updatePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            isChanging = false
            dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
