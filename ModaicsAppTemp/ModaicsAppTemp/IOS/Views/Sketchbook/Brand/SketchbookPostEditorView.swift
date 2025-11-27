//
//  SketchbookPostEditorView.swift
//  ModaicsAppTemp
//
//  Post creation/editing interface for brand Sketchbook
//

import SwiftUI
import PhotosUI

struct SketchbookPostEditorView: View {
    @ObservedObject var viewModel: BrandSketchbookViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPostType: SketchbookPostType = .update
    @State private var title: String = ""
    @State private var caption: String = ""
    @State private var visibility: SketchbookVisibility = .public
    
    // Media
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var mediaUrls: [String] = []
    
    // Poll
    @State private var pollQuestion: String = ""
    @State private var pollOptions: [String] = ["", ""]
    @State private var pollDuration: Double = 7 // days
    
    // Event
    @State private var eventDate: Date = Date().addingTimeInterval(86400 * 7)
    
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.modaicsDarkBlue
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Post Type Selector
                        postTypeSelector
                        
                        // Title
                        titleSection
                        
                        // Caption/Body
                        captionSection
                        
                        // Media picker
                        if selectedPostType != .poll {
                            mediaSection
                        }
                        
                        // Post Type Specific Content
                        switch selectedPostType {
                        case .poll:
                            pollSection
                        case .event, .drop:
                            eventSection
                        default:
                            EmptyView()
                        }
                        
                        // Visibility
                        visibilitySection
                        
                        // Submit Button
                        ModaicsPrimaryButton(
                            "Publish Post",
                            icon: "paperplane.fill",
                            isLoading: isSubmitting
                        ) {
                            Task { await submitPost() }
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.modaicsCotton)
                }
            }
        }
    }
    
    // MARK: - Post Type Selector
    
    private var postTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Post Type")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.modaicsCotton)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SketchbookPostType.allCases, id: \.self) { type in
                        postTypeChip(type: type)
                    }
                }
            }
        }
    }
    
    private func postTypeChip(type: SketchbookPostType) -> some View {
        Button(action: { selectedPostType = type }) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(selectedPostType == type ? .modaicsDarkBlue : .modaicsChrome1)
                
                Text(type.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selectedPostType == type ? .modaicsDarkBlue : .modaicsCotton)
            }
            .frame(width: 100, height: 80)
            .background(
                selectedPostType == type
                    ? LinearGradient(
                        colors: [.modaicsChrome1, .modaicsChrome2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.modaicsSurface2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(
                        selectedPostType == type
                            ? Color.modaicsChrome1.opacity(0.5)
                            : Color.modaicsChrome1.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Title")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.modaicsCotton)
            
            TextField("Give your post a title...", text: $title)
                .foregroundColor(.modaicsCotton)
                .font(.system(size: 15))
                .padding()
                .background(Color.modaicsSurface2)
                .clipShape(Rectangle())
                .overlay(
                    Rectangle()
                        .stroke(Color.modaicsChrome1.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Caption Section
    
    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.modaicsCotton)
            
            ZStack(alignment: .topLeading) {
                if caption.isEmpty {
                    Text("Share what you're working on...")
                        .foregroundColor(.modaicsCottonLight.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                
                TextEditor(text: $caption)
                    .foregroundColor(.modaicsCotton)
                    .font(.system(size: 15))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
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
    
    // MARK: - Media Section
    
    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Media")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.modaicsCotton)
            
            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: 5,
                matching: .images
            ) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 24))
                        .foregroundColor(.modaicsChrome1)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add Photos")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.modaicsCotton)
                        
                        Text("Up to 5 images")
                            .font(.caption)
                            .foregroundColor(.modaicsCottonLight)
                    }
                    
                    Spacer()
                    
                    if !selectedPhotos.isEmpty {
                        Text("\(selectedPhotos.count)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.modaicsChrome1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.modaicsChrome1.opacity(0.2))
                            .clipShape(Rectangle())
                    }
                }
                .padding(16)
                .background(Color.modaicsSurface2)
                .clipShape(Rectangle())
                .overlay(
                    Rectangle()
                        .stroke(Color.modaicsChrome1.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Poll Section
    
    private var pollSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Poll Details")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.modaicsCotton)
            
            // Poll Question
            VStack(alignment: .leading, spacing: 8) {
                Text("Question")
                    .font(.system(size: 14))
                    .foregroundColor(.modaicsCottonLight)
                
                TextField("What should we decide?", text: $pollQuestion)
                    .foregroundColor(.modaicsCotton)
                    .padding()
                    .background(Color.modaicsSurface2)
                    .clipShape(Rectangle())
                    .overlay(
                        Rectangle()
                            .stroke(Color.modaicsChrome1.opacity(0.2), lineWidth: 1)
                    )
            }
            
            // Poll Options
            VStack(alignment: .leading, spacing: 8) {
                Text("Options")
                    .font(.system(size: 14))
                    .foregroundColor(.modaicsCottonLight)
                
                ForEach(0..<pollOptions.count, id: \.self) { index in
                    HStack(spacing: 12) {
                        TextField("Option \(index + 1)", text: $pollOptions[index])
                            .foregroundColor(.modaicsCotton)
                            .padding()
                            .background(Color.modaicsSurface2)
                            .clipShape(Rectangle())
                            .overlay(
                                Rectangle()
                                    .stroke(Color.modaicsChrome1.opacity(0.2), lineWidth: 1)
                            )
                        
                        if pollOptions.count > 2 {
                            Button(action: { pollOptions.remove(at: index) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                            }
                        }
                    }
                }
                
                if pollOptions.count < 5 {
                    Button(action: { pollOptions.append("") }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Option")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.modaicsChrome1)
                    }
                }
            }
            
            // Poll Duration
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration: \(Int(pollDuration)) days")
                    .font(.system(size: 14))
                    .foregroundColor(.modaicsCottonLight)
                
                Slider(value: $pollDuration, in: 1...30, step: 1)
                    .tint(.modaicsChrome1)
            }
        }
    }
    
    // MARK: - Event Section
    
    private var eventSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedPostType == .event ? "Event Date" : "Drop Date")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.modaicsCotton)
            
            DatePicker(
                "",
                selection: $eventDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .tint(.modaicsChrome1)
            .padding()
            .background(Color.modaicsSurface2)
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(Color.modaicsChrome1.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Visibility Section
    
    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visibility")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.modaicsCotton)
            
            HStack(spacing: 12) {
                ForEach(SketchbookVisibility.allCases, id: \.self) { vis in
                    Button(action: { visibility = vis }) {
                        HStack(spacing: 8) {
                            Image(systemName: vis == .public ? "globe" : "lock.fill")
                            Text(vis == .public ? "Public" : "Members Only")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(visibility == vis ? .modaicsDarkBlue : .modaicsCotton)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            visibility == vis
                                ? LinearGradient(
                                    colors: [.modaicsChrome1, .modaicsChrome2],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color.modaicsSurface2],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .clipShape(Rectangle())
                        .overlay(
                            Rectangle()
                                .stroke(
                                    visibility == vis
                                        ? Color.modaicsChrome1.opacity(0.5)
                                        : Color.modaicsChrome1.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Submit
    
    private func submitPost() async {
        guard !title.isEmpty else { return }
        
        isSubmitting = true
        defer { isSubmitting = false }
        
        // TODO: Upload media to backend, get URLs
        // For now, convert selected photos to MediaAttachment objects with placeholder URLs
        let media = selectedPhotos.enumerated().map { index, _ in
            MediaAttachment(
                id: UUID(),
                type: .image,
                url: "https://placeholder.com/image\(index).jpg",
                thumbnailURL: nil
            )
        }
        
        var pollOptionsData: [PollOption]? = nil
        var pollClosesAt: Date? = nil
        if selectedPostType == .poll && !pollQuestion.isEmpty {
            let validOptions = pollOptions.filter { !$0.isEmpty }
            if validOptions.count >= 2 {
                pollOptionsData = validOptions.map { text in
                    PollOption(id: UUID().uuidString, label: text, votes: 0)
                }
                pollClosesAt = Date().addingTimeInterval(pollDuration * 86400)
            }
        }
        
        let success = await viewModel.createPost(
            type: selectedPostType,
            title: title,
            body: caption.isEmpty ? nil : caption,
            media: media,
            tags: [],
            visibility: visibility,
            pollQuestion: selectedPostType == .poll ? pollQuestion : nil,
            pollOptions: pollOptionsData,
            pollClosesAt: pollClosesAt
        )
        
        if success {
            dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    SketchbookPostEditorView(viewModel: BrandSketchbookViewModel(userId: "brand-123"))
}
